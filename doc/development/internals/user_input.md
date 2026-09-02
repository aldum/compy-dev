# User Input — Implementation Overview

Input handling in Compy has two mostly independent layers: **text/keyboard input** (the input widget shared across console, editor, and project overlays) and **mouse/pointer input** (handled partly by the framework, partly delegated to projects). This doc covers both, with mode-specific notes where the behavior differs.

---

## Text Input Widget

`UserInputModel` / `UserInputController` / `UserInputView` form a shared widget reused in three contexts: the console REPL, the editor input strip, and project-created overlays. The widget is always the same code; what differs is the evaluator attached to it and which controller handles the result.

### Data flow

```
LÖVE2D textinput event
  → love.handlers.textinput
    → ConsoleController:textinput (dispatches by app_state)
      → editor mode: EditorController:textinput
      → console/overlay mode: UserInputController:textinput
        → UserInputModel:add_text
          → updates InputText (cursor-aware string)
            → view re-renders
```

Text characters arrive via `love.textinput` (OS-processed, handles IME and layout). Raw key events for non-character keys (backspace, enter, arrows) arrive via `love.keypressed`.

### Multiline input

The input is not single-line. `Shift+Enter` inserts a newline (`line_feed()`). The cursor model tracks both line and column. Lines are stored as a `Dequeue<string>` in `InputText`. The view wraps long lines at `drawableChars` width (same wrap machinery as the editor's `VisibleContent`).

The input view height is `input_max = 14` lines. This is a display limit only — the model can hold more lines, and scrolling within the input works normally. In the editor context this becomes relevant when loading a monster block (> 16 lines): all content is in the model, but only 14 lines are visible at once. See `editor.md` — Monster Blocks for the full picture.

### Selection

Text selection works across lines. `Shift+arrow` extends selection; releasing shift releases it. `UserInputController.disable_selection` (set to `true` in editor mode's input instance) suppresses selection — the editor uses its own block-level selection model, not character-level selection in the input.

Mouse click on the input widget (translated from screen coordinates to input grid via `_translate_to_input_grid`) sets the cursor position. Drag extends selection. The coordinate translation is bottom-relative: line 0 is the bottom line of the input, which is non-obvious.

### Error state

When an error is set on the model (`set_error()`), the input is visually locked: text input and most keys are ignored until the error is cleared. Cleared by: Enter, space, or arrow keys. This is used for parse errors, runtime errors, and validation failures.

### Evaluator and validation

Each `UserInputModel` has an `Evaluator` that runs on submit:
- **Console**: `LuaEval` — metalua parse, validates Lua syntax before accepting the submit
- **Editor input (Lua file)**: `LuaEditorEval` — same as LuaEval but adds 64-char line length validator
- **Project overlays**: `InputEvalText` (plain), `InputEvalLua` (Lua syntax), or a `ValidatedTextEval` with custom validators
- **Search**: `nil` evaluator (search input is free text, no validation)

Validators run on every character (via `validation_hl` for real-time highlighting) and again on submit. A validator returns `true` or `false, Error(msg, column)`. The column is used to highlight the specific offending character.

---

## Keyboard Handling

### Dispatch chain

```
love.handlers.keypressed
  → global shortcuts (pause, quit, restart, editor-toggle) — controller.lua
    → ConsoleController:keypressed
      → if editor state: EditorController:keypressed
      → else: console key handling
        → history navigation (PageUp/Down)
        → UserInputController:keypressed (cursor, edit, submit)
        → Enter → ConsoleController:evaluate_input
```

Global shortcuts in `love.handlers.keypressed` (controller.lua:520+) are intercepted before anything reaches the controller: Ctrl+Pause suspends, Ctrl+Q quits project, Ctrl+S stops run or closes buffer, Ctrl+Shift+R resets application, Ctrl+Alt+R restarts project, Ctrl+Esc exits app.

If `love.state.user_input` is set (overlay active), key events go to the overlay controller, bypassing the main input.

### Console-specific keys

- **PageUp/PageDown**: history back/forward
- **Up/Down at input boundary**: also triggers history navigation (handled as a "limit reached" return from `UserInputController:keypressed`)
- **Enter** (no shift): submit → `evaluate_input()`
- **Ctrl+L**: clear terminal output
- **Shift+Enter**: insert newline in input (multiline expression)

### Editor-specific keys

See `editor.md` for full detail. Key differences from console mode:
- No history navigation (PageUp/Down scroll the buffer instead)
- Up/Down at input boundary moves buffer selection, not history
- Escape loads selected block text into input
- Ctrl+M / Ctrl+F switch modes

### UserInputController keypressed (shared)

`UserInputController:keypressed` handles the low-level input operations regardless of context: removers (backspace, delete, Ctrl+Y delete line), vertical cursor movement, horizontal movement (Left/Right, Home/End, Alt+Home/End for line vs field boundaries), Shift+Enter newline, Ctrl+D duplicate line, copy/cut/paste (Ctrl+C/X/V and Shift+Insert/Delete), selection management.

The `oneshot` flag on `UserInputModel` (set for project overlays) enables a submit path inside `UserInputController:keypressed` — on Enter, the evaluator runs and the result is sent to the callback. Console submission is handled separately in `ConsoleController:keypressed`, not here.

---

## Mouse Input

### Framework-level click handling

The framework implements single/double click detection in `love.handlers.mousereleased` (controller.lua:662+). On each mouse release:
1. `click_count` is incremented, `click_timer` is set to 0.4s
2. On the next `love.update()`, if `click_timer` has expired:
   - `click_count == 1`: single click confirmed — calls `compy.singleclick(x, y)` if defined
   - `click_count >= 2`: double click — calls `compy.doubleclick(x, y)` if defined
3. A drift tolerance of 2.5px is applied: if the mouse moved more than that between press and release, the click is suppressed

`compy.singleclick` and `compy.doubleclick` are looked up in `env['compy']` — the project's `compy` table. They are not LÖVE2D events; they are Compy-specific abstractions. Projects define them as `function compy.singleclick(x, y) ... end`.

The 0.4s delay means single clicks are always confirmed after a short wait — there is no "instant single click" path. This is a deliberate tradeoff for double-click detection consistency.

### Direct mouse events

`love.mousepressed`, `love.mousereleased`, `love.mousemoved`, `love.wheelmoved` are also forwarded directly to project-defined handlers via the standard LÖVE2D mechanism (projects set `love.mousepressed = function(...) end`). These go through `wrap_handler` (error catching + canvas routing) if set by the project.

The framework's own `mousepressed`/`mousereleased` handlers (in `love.handlers`) call the user handler AND the overlay controller if present — both get the event.

### Input widget mouse

`UserInputController` handles mouse events on the input widget:
- `mousepressed`: translates screen (x, y) → input grid (col, line) via `_translate_to_input_grid`. Grid is bottom-relative (y increases upward in input space). Calls `im:mouse_click(l, c)` to set cursor.
- `mousemoved`: if left button held, calls `im:mouse_drag(l, c)` to extend selection.
- `mousereleased`: calls `im:mouse_release(l, c)` then releases selection.

Mouse events on the input widget are only processed when `disable_selection` is false. In editor mode, the input widget's controller has `disable_selection = true` — mouse interaction with the input strip is suppressed, and the editor uses keyboard-only navigation.

### Touch

Touch handlers (`touchpressed`, `touchreleased`, `touchmoved`) are stubbed with `-- TODO` in `UserInputController`. The framework's `love.handlers` forwards touch events to project handlers if defined.

---

## The `user_input` Overlay — Input Perspective

When a project calls `input_text()`, `input_code()`, or `validated_input()`, a new `UserInputModel` + `UserInputController` + `UserInputView` is created and stored in `love.state.user_input`. From this point:

- **Text input** (`love.handlers.textinput`): goes to `user_input.C:textinput(t)` instead of the main controller
- **Key input** (`love.handlers.keypressed`): goes to `user_input.C:keypressed(k)`
- **The overlay view** (`user_input.V`) is drawn by the framework's `love.update` wrapping of the user draw function (appended after the user draw call)

The project polls `r:is_empty()` in `love.update`. When the user presses Enter, the evaluator runs, and if it passes, the result is stored in the `reftable` ref. On the next `update()`, `r:is_empty()` returns false, `r()` returns the value and resets to empty.

Only one overlay can exist at a time. If `love.state.user_input` is already set, subsequent calls to `input_text()` etc. return immediately.

---

## Key Files

| File | Role |
|---|---|
| `src/controller/userInputController.lua` | Keyboard, mouse, and text event handling for the input widget |
| `src/model/input/userInputModel.lua` | Input state: text, cursor, selection, history, error, evaluator |
| `src/model/input/inputText.lua` | Multiline string with cursor-aware insert/delete |
| `src/model/input/cursor.lua` | Cursor position model |
| `src/model/input/selection.lua` | Selection range model |
| `src/model/input/history.lua` | Command history (console) |
| `src/view/input/userInputView.lua` | Renders the input strip and status line |
| `src/controller/controller.lua` | Global key dispatch, click detection, user handler management |
| `src/controller/consoleController.lua` | Top-level key/text dispatch, overlay creation API |
