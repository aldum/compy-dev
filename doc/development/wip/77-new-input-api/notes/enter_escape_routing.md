# Notes — Enter and Escape Routing

How the two primary session-control keys travel through the
system across all four input contexts. Companion to
`notes/event_delegation_chain.md` and
`notes/textinput_routing.md`.

---

## Prerequisite: the `oneshot` flag

`UserInputController` (the shared text-editing widget) has two
operating modes controlled by a `oneshot` flag:

- **`oneshot = false`** (REPL, editor): the widget handles
  text editing — backspace, cursor, selection, copy/paste,
  Shift+Enter for newlines — but does **not** own submit. When
  Enter is pressed, the widget's `submit()` inner function
  checks `oneshot` and returns immediately without action. The
  controller above (ConsoleController for REPL,
  EditorController for editor) is responsible for handling
  Enter its own way after the widget returns.

- **`oneshot = true`** (project overlay): the widget owns the
  full session lifecycle. Enter triggers `submit()` →
  `model:evaluate()` → on success, fills the reftable and
  pushes `'userinput'` to dismiss the overlay. The widget is
  the terminal; there is no controller above it in this branch.

The flag is set when the project calls `input_text()` (or
equivalent) to show the overlay. REPL and editor never set it.
This is why `submit()` appears to "do nothing" in REPL/editor
traces — it genuinely no-ops by design.

### `oneshot` under the new architecture

`oneshot` is a tactical flag, not a permanent design element.
It exists because one widget was asked to serve two
incompatible roles with no shared dispatch layer between them.

In the new architecture, `UserInputController` is
unconditionally passive — always a sink, never a session owner.
Submit is always handled above it in `framework_handlers`:

- ConsoleController's `framework_handlers['return']` →
  `evaluate_input()`
- EditorController's `framework_handlers['return']` →
  `_handle_submit()`
- ProjectController's `framework_handlers['return']` → submit
  callback (FR-5) + push `'userinput'`

The widget no longer checks whether it owns submit, because it
never does. The `submit()` inner function that `oneshot`
controls goes away. The overlay lifecycle that `oneshot=true`
was encoding is now encoded in ProjectController's handler
table, where it belongs. The singleton's `show()`/`hide()`
replaces the other signal `oneshot` was carrying ("this widget
is currently in active use by a project").

`oneshot` is not migrated or generalised — it is deleted. The
architectural split (controller owns submit, widget owns
text-editing) dissolves the problem it was solving.

---

A second prerequisite: `EditorController:_normal_mode_keys`
uses a `passthrough` flag (default true). Any handler that
fully claims a key calls `block_input()`, setting
`passthrough = false`. At the end of the function,
`if passthrough then input:keypressed(k) end` decides
whether the key also reaches `UserInputController:keypressed`.
This is how EditorController and UserInputController
cooperate without explicit coordination.

---

## Enter

### REPL (app_state = `ready`)

```
keypressed('return')
  → ConsoleController:keypressed
      → UserInputController:keypressed
           submit() inner fn: oneshot=false → does nothing
           newline(): Shift+Enter → inserts line feed
      → [after UserInputController returns]
      → ConsoleController: if not Shift and is_enter(k)
           → evaluate_input()
```

Plain Enter submits (evaluate_input). Shift+Enter inserts a
newline in the multiline input. The split is clean: the
widget handles the newline insertion; the console handles
the submit.

### Editor — normal mode (app_state = `editor`)

```
keypressed('return')
  → ConsoleController → EditorController:keypressed
       → _normal_mode_keys(k)
            newline(): Shift/Ctrl+Enter on empty input
              → buf:insert_newline() + block_input()
              [passthrough blocked; UserInputController not called]
            submit(): plain Enter (no Ctrl/Shift/Alt)
              → _handle_submit(replace)
              [block_input NOT called; passthrough stays true]
            → [passthrough=true] input:keypressed(k)
                 UserInputController: editor branch
                   submit(): oneshot=false → does nothing
```

Plain Enter: EditorController calls `_handle_submit(replace)`
(pretty-print pipeline, replaces selected block, auto-save).
UserInputController's submit() also runs but is a no-op
(oneshot=false). Ctrl+Enter: `_handle_submit(add)` (inserts
before selection). Shift/Ctrl+Enter on empty input: inserts
an empty block directly in the buffer, bypasses the input
entirely.

### Editor — reorder mode

Enter: `_reorg(true)` — confirms the block move, returns to
edit mode.

### Editor — search mode

Enter: confirms the highlighted search result, scrolls to
the block, returns to edit mode.

### Overlay (oneshot = true)

```
keypressed('return')
  → UserInputController:keypressed  [direct, overlay active]
       newline(): Shift+Enter → inserts line feed
       submit(): not Shift, is_enter, oneshot=true
         if empty → return (no-op)
         model:evaluate()
           → if ok:
               UserInputModel:handle pushes 'userinput' event
               res(t) fills reftable
           → if fail:
               model:set_error(err)
               input locked until Enter/space/arrows
```

Plain Enter submits. On success the reftable is filled and
`'userinput'` is pushed, clearing the overlay on the next
event dispatch. On evaluation failure the input locks with
an error highlight — no dismiss, no retry prompt. Shift+Enter
inserts a newline for multiline input.

### Project running, no overlay

Project's own `love.keypressed` handler. No framework
involvement beyond global power shortcuts.

---

## Escape

### REPL (app_state = `ready`)

```
keypressed('escape')
  → ConsoleController:keypressed
      → UserInputController:keypressed
           else-branch (non-editor): cancel() fires
             model:cancel() → handle(false) + reset()
             → input content cleared
```

Escape clears the input content. No session lifecycle effect
(no overlay exists in REPL mode). `handle(false)` does not
push `'userinput'`.

### Editor — normal mode

```
keypressed('escape')
  → EditorController:_normal_mode_keys
       load(): Escape (no Ctrl, no Shift)
         → load_selection()
           → input:set_text(selected_block_text)
           [block_input NOT called; passthrough stays true]
       → [passthrough=true] input:keypressed('escape')
            UserInputController: app_state='editor' branch
              cancel() is NOT in the editor branch → not called
```

Escape loads the selected block's text into the input strip.
`UserInputController:keypressed` runs (passthrough=true) but
its editor branch deliberately omits `cancel()` — the input
content is preserved. Shift+Escape performs an additive load
(inserts block text at cursor rather than replacing).

This is the key EditorController/UserInputController
cooperation point: Escape's meaning is redefined by the
editor without needing to explicitly suppress the widget's
cancel path — the editor-branch omission does it implicitly.

### Editor — reorder mode

Escape: `_reorg(false)` — cancels the pending move, restores
state, returns to edit mode.

### Editor — search mode

Escape: `set_mode('edit')`, clears the search filter.

### Overlay (oneshot = true)

```
keypressed('escape')
  → UserInputController:keypressed  [direct, overlay active]
       else-branch: cancel() fires
         model:cancel() → handle(false) + reset()
         → input content cleared
         → 'userinput' NOT pushed
         → love.state.user_input unchanged
```

Escape clears the input content but **does not dismiss the
overlay**. The overlay remains visible with an empty input
strip. `'userinput'` is never pushed from `handle(false)`.
The project's polling loop continues; the project has no
notification that Escape was pressed.

This is a known limitation of the current design. Under the
new API, Escape would fire `before_cancel → cancel →
after_cancel` (D-4), and the framework's `cancel` handler
would push `'userinput'` to dismiss the overlay.

### Project running, no overlay

Project's own `love.keypressed` handler.

---

## Global override: Ctrl+Escape

`love.handlers.keyreleased` (controller.lua:642–646) checks
Ctrl+Escape on key **release** and calls `love.event.quit()`
unconditionally. This fires regardless of app_state, overlay
state, or any other context. It is the application exit
shortcut and cannot be intercepted by project or framework
code.

---

## Summary table

| Key | REPL | Editor (normal) | Overlay | Project |
|---|---|---|---|---|
| Enter | evaluate_input | _handle_submit (replace) | submit + dismiss | project |
| Shift+Enter | newline | empty-block insert (or newline if non-empty) | newline | project |
| Ctrl+Enter | — | _handle_submit (add/insert) | — | project |
| Escape | clear input | load selected block | clear input only | project |
| Shift+Escape | — | additive load | — | project |
| Ctrl+Escape (release) | quit app | quit app | quit app | quit app |
