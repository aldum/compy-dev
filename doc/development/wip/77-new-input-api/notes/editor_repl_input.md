# Notes — Editor and REPL Input Architecture

Analysis supporting the FR-11/FR-12 capability question
and the D-7 rollout scope decision. Covers what the
console REPL and editor currently do with input, and
what "migration to the new callbacks/handlers topology"
would actually mean for each.

---

## Current structure

Neither the console REPL nor the editor has an isolated
MVC triad for the input strip. Both embed the shared input
widget — `UserInputModel` / `UserInputController` /
`UserInputView` — as one component inside a larger
full-screen controller.

**ConsoleController** manages: the REPL input strip,
terminal output, project lifecycle, code evaluation, and
the `user_input` overlay API. It holds a reference to
`UserInputModel` (its own input, not the overlay) and
calls `UserInputController:keypressed(k)` as part of its
own key handling.

**EditorController** manages: the input strip at the
bottom, the block buffer display above it, buffer
navigation, the submit pipeline, mode state (edit /
reorder / search), and the buffer stack. It likewise holds
a reference to the shared input widget.

Neither controller registers `love.keypressed` directly.
Key events arrive via the dispatch chain:

```
controller.lua handlers.keypressed
  → global shortcuts (Ctrl+Q, Ctrl+T, etc.)
  → ConsoleController:keypressed(k)
    → if editor state: EditorController:keypressed(k)
    → else: console key logic
```

---

## What the controllers do in their keypressed handlers

### ConsoleController:keypressed

- Clear error state on certain keys
- `PageUp` / `PageDown` → `input:history_back/fwd()`
- Delegate editing to `UserInputController:keypressed(k)`
  - If it returns a limit signal: `Up/Down` → history nav
- `Enter` (no shift, no error) → `evaluate_input()`
- `Ctrl+L` → clear terminal (not currently implemented
  as a hotkey in the source but the pattern is established)

The if-chain here is the dispatch logic. The methods it
calls (`history_back`, `evaluate_input`, etc.) are defined
elsewhere and have nothing to do with key dispatch.

### EditorController:keypressed

Dispatches to mode-specific handlers:
- **Edit mode**: `Escape` → load selected block into input;
  `Enter` → `_handle_submit`; `Ctrl+Enter` → insert;
  `Ctrl+M` → reorder mode; `Ctrl+F` → search mode;
  `Ctrl+S` → close buffer; `Ctrl+O` → follow require;
  `Up/Down` at input limit → block navigation;
  all other keys → `UserInputController:keypressed(k)`
- **Reorder mode**: navigation + `Enter` → confirm move;
  `Escape` → cancel reorder
- **Search mode**: input + `Enter` → jump to definition;
  `Escape` → exit search

Again the if-chain is dispatch only. The methods called
(`_handle_submit`, `buf:move`, `enter_reorder_mode`, etc.)
are defined on the controller and buffer model.

---

## What migration to the new topology would mean

The migration target is precisely the if-chains in both
`keypressed` methods — and only those. Everything the
methods call stays exactly as-is.

**Console migration sketch:**

```lua
-- framework_handlers already cover Enter and Escape.
-- These replace the manual checks in ConsoleController:keypressed:
compy.handlers['pageup']   = function() input:history_back() end
compy.handlers['pagedown'] = function() input:history_fwd() end
-- limit hook replaces the `if limit then` check:
compy.on_limit_reached = function(dir)
  if dir == 'up' then input:history_back()
  else input:history_fwd() end
end
-- before_submit replaces the Enter → evaluate path:
compy.before_submit = function(text)
  cc:evaluate_input(text)
end
```

**Editor migration sketch:**

```lua
compy.handlers['escape']   = function() cc:load_block() end
compy.handlers['lctrl+m']  = function() cc:enter_reorder() end
compy.handlers['lctrl+f']  = function() cc:enter_search() end
compy.handlers['lctrl+s']  = function() cc:close_buffer() end
compy.on_limit_reached     = function(dir) cc:navigate_block(dir) end
compy.before_submit        = function(text) cc:handle_submit(text) end
```

In both cases: the controller's keypressed method shrinks
to handler registrations; the underlying methods are
unchanged. The editor's buffer model, submit pipeline,
semantic analysis, and buffer stack are entirely
unaffected.

---

## FR-11/FR-12 capability assessment

FR-11 (REPL re-implementability): the API needs
`on_limit_reached` hook, `before_submit` callback, and
handler registration for PageUp/PageDown. All are present
in the proposed design.

FR-12 (editor re-implementability): the API needs
`on_limit_reached`, `before_submit`, `before_cancel`
(for load-on-Escape), and handler registration for
Ctrl+M, Ctrl+F, Ctrl+S, Ctrl+O. All are present or
derivable from the three-level dispatch.

**Conclusion:** the capability reading of FR-11/FR-12 is
satisfiable by the proposed API surface. No actual
migration is required to verify this — a design review
walkthrough (showing the sketches above compile against
the API spec) is sufficient.

---

## Effort estimate for actual migration (informational)

Should migration ever be chosen as a follow-on feature:

- Console migration: small. One method replaced by ~5
  handler registrations. Low risk, easily tested.
- Editor migration: medium. `EditorController:keypressed`
  has ~80 lines across three mode branches. Replacing
  with handler registrations is mechanical but requires
  care around mode state (reorder/search modes affect
  which handlers are active — would need show/hide of
  handler sets on mode transition).

Neither migration changes the buffer model, submit
pipeline, or view code.
