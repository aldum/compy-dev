# Notes — love.textinput Routing and Event Taxonomy

Companion to `notes/love2d_handler_layers.md`, which covers
`keypressed` routing. Documents the parallel `textinput` path
and clarifies the distinction between OS-level input events
and widget-emitted lifecycle events.

---

## love.textinput routing

`love.textinput` follows a structurally identical path to
`love.keypressed` — same two-level split, same overlay gate,
same fallback slot.

At startup: `love.textinput` is set to
`ConsoleController:textinput` via `set_love_textinput(CC)`,
symmetric to how `love.keypressed` is wired.

```
OS produces printable text
  │
  ▼
love.handlers.textinput          [Compy's, fixed]
  ├─ overlay active?
  │     YES → user_input.C:textinput(t)   [exclusive]
  │     NO  ↓
  └─ love.textinput(t)            [the slot]
        ├─ ConsoleController:textinput
        │     ├─ [Ctrl+Shift held] → return  ← filtered here
        │     ├─ [error state] clear error, return
        │     ├─ [editor state] → EditorController:textinput
        │     └─ [else REPL]   → UserInputController:textinput
        │                           → UserInputModel:add_text(t)
        └─ project's own love.textinput (if defined)
```

The Ctrl+Shift filter sits in `ConsoleController:textinput`,
not in the widget. The widget never sees those characters.

`UserInputController:textinput` has an additional guard: if
`self.result` (the reftable reference) is nil and
`app_state == 'running'`, the character is silently dropped.
An unconfigured singleton in running mode therefore rejects
all textinput automatically.

---

## Combo assembly — framework or LÖVE2D?

LÖVE2D does not assemble combos. It fires a separate
`keypressed` event for every physical key press, regardless
of what other keys are held. Combo detection is entirely the
application's responsibility.

Currently Compy has no centralised combo assembly. Detection
is ad-hoc at the point of handling: each handler calls
`Key.ctrl()`, `Key.shift()`, etc. — thin wrappers over
`love.keyboard.isDown()` — at the moment it needs to know
modifier state. There is no "combo detected → event fired"
mechanism.

The D-3 design introduces a `keys_pressed` table maintained
by the framework — a live set of currently held key names,
updated on `keypressed` / `keyreleased`. This replaces
scattered `isDown` calls with a single authoritative table
and makes combo serialisation (`"lctrl+s"`) and lookup
possible without per-handler modifier checks.

---

## What textinput delivers

`love.textinput` delivers a UTF-8 string — what the OS
produced from a key gesture after applying layout and
modifier translation. In the common case this is one
Unicode character. In IME-based input (CJK languages), it
can be a multi-character string delivered when the user
commits a composition sequence. LÖVE2D documents this
explicitly; `UserInputModel:add_text` handles it — it splits
the incoming string on newlines via `string.lines`, so
multi-character IME output is inserted correctly.

Multi-line content (paste) does not arrive via `textinput`
at all. Ctrl+V is handled by `keypressed` →
`UserInputController`'s `paste()` inner function →
`love.system.getClipboardText()` → `model:paste(text)` →
`add_text(text)`. The clipboard string can be arbitrarily
long and multi-line; `add_text` handles it the same way it
handles IME strings. This path entirely bypasses
`love.textinput`.

One platform edge case: on web builds, the space key does
not fire `textinput` in some environments. The controller
works around this by injecting `self:textinput(' ')` directly
from `keypressed` when `_G.web` is set
(`userInputController.lua:189–191`).

---

## Division of labour: keypressed vs textinput

These two events are complementary, not competing.

`love.keypressed` handles everything structural:
backspace, delete, cursor movement (arrows, Home, End),
selection management, Shift+Enter (newline), clipboard
(Ctrl+C/X/V), and the session lifecycle keys — Enter
(submit) and Escape (cancel/reset).

`love.textinput` handles character insertion only. When the
user presses 'a', `keypressed('a')` fires and
`UserInputController:keypressed` does nothing with it —
no branch matches a plain printable character. The
character enters the model exclusively via the subsequent
`textinput('a')` event → `add_text('a')`.

Submit (Enter in the oneshot path) is handled entirely by
`keypressed`: `UserInputController:keypressed` → `submit()`
inner function → `model:evaluate()` → on success, fills the
reftable via `res(t)`. `textinput` has no path to session
end.

---

## Event taxonomy: into vs out of the widget

`UserInputController` is a consumer of OS-level events, not
a producer of application-level ones — with one exception.

| Direction | Event | Origin | Meaning |
|---|---|---|---|
| → into widget | `love.textinput(t)` | OS / LÖVE2D | OS produced printable text |
| → into widget | `love.keypressed(k)` | OS / LÖVE2D | Physical key was pressed |
| ← out of widget | `love.event.push('userinput')` | Widget (oneshot path) | Successful submit only |

`'userinput'` fires in exactly one place: `UserInputModel:handle()`,
inside `if eval then ... if ok then ... if self.oneshot`.
(`oneshot` is the flag that puts the widget in overlay mode vs.
REPL/editor mode — see `notes/enter_escape_routing.md` for a
full explanation.)
This means: non-empty input, evaluation succeeds, widget is
in oneshot mode. Cancel (Escape) calls `handle(false)`, which
skips the eval branch entirely — no event is pushed. Escape
currently resets the input content and leaves the overlay
visible; it does not dismiss it. The overlay is only ever
dismissed by successful submit.

`handlers.userinput` in `controller.lua` receives the event
and calls `clear_user_input()` — sets `love.state.user_input`
to nil. Projects cannot subscribe to this event. There is no
`compy.on_userinput` or equivalent. The reftable is the
project's only observation point.

There is no "text changed" event, no "character added"
callback, no mid-session outbound signal of any kind. The
view refreshes synchronously via `update_view()` calls after
each state change, but those are direct draw-state updates,
not observable events.

---

## The gap this identifies

Nothing flows out of the widget mid-session. This is the
absence that FR-5 and FR-6 address:

- `on_text_entered` would be the outbound mid-session
  character signal (currently nonexistent)
- `on_key_pressed` / `compy.handlers` would be the outbound
  key signal (currently nonexistent)
- `on_limit_reached` would be the outbound boundary signal
  (signal exists internally as a return value; never reaches
  project code)

Under the unified routing model (`notes/routing_unification.md`),
these signals are inserted at the `ProjectController` dispatch
layer — above the sink — so they fire before `UserInputController`
processes the event, not buried inside it.
