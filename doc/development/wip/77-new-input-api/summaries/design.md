# Feature #77 — Design Summary

*Condensed version of `design.md` for stakeholder review.
Allow 10–15 minutes. The routing diagrams are self-explanatory;
the component table is the quickest entry point.*

---

## What this feature adds

A persistent, callback-driven input widget for Compy projects:
one configurable edit area with `show`/`hide`/`configure`
lifecycle, event callbacks for submit, cancel, key combos,
text input, and cursor boundary hits, and programmatic cursor
and content access. The legacy text-input functions
(`input_text()` etc.) are **removed** — no backward compatibility
(D-1 discarded, stakeholders round 1); the examples that used
them migrate to the new API. Console and editor migration is
a separate follow-on.

---

## Architectural change — routing unification

**Before:** an "overlay gate" in the framework's keyboard
dispatcher routes all key events exclusively to the input
widget when it is active. Project code is unreachable.

```
love.handlers.keypressed
  ├─ global shortcuts
  ├─ overlay active?
  │     YES → UserInputController:keypressed  [exclusive]
  │     NO  ↓
  └─ love.keypressed
        ├─ ConsoleController → ... → UserInputController
        ├─ EditorController  → ... → UserInputController
        └─ project's own love.keypressed  [or nothing]
```

**After:** the gate is removed. `ProjectController` (new) is
a first-class sibling to the other controllers. All branches
terminate at the same sink. Routing does not change based on
whether the input widget is visible.

```
love.handlers.keypressed
  ├─ global shortcuts
  └─ love.keypressed
        ├─ ConsoleController:keypressed
        │     ├─ framework_handlers (Enter, history, etc.)
        │     ├─ console-registered handlers / callbacks
        │     └─ → UserInputController:keypressed  [sink]
        ├─ EditorController:keypressed
        │     ├─ framework_handlers (Enter, Esc, Ctrl+M, etc.)
        │     ├─ editor-registered handlers / callbacks
        │     └─ → UserInputController:keypressed  [sink]
        └─ ProjectController:keypressed  [new]
              ├─ framework_handlers (Enter, Escape, etc.)
              ├─ compy.input.handlers[combo]  [project-registered]
              ├─ compy.input.on_key_pressed   [generic; default: sink]
              └─ → UserInputController:keypressed  [sink]
```

The singleton (`UserInputController`) follows structurally:
because it is always the sink, its lifecycle is a state
change (`show()`/`hide()`), not a routing change.

**Native handler coexistence.** Projects that define native
`love.keypressed` (without any `compy.*` surfaces) are handled
transparently via the *legacy heuristic*: `ProjectController`
auto-provisions `compy.input.on_key_pressed` as a lifecycle-split
wrapper (routes to sink when visible; to native handler when
hidden), reproducing today's gated behaviour with zero example
changes.

---

## Components

| Component | Role |
|---|---|
| `keys_pressed` table | Live set of held key names; updated on every keypressed/keyreleased; combo serialisation foundation |
| `UserInputController` singleton | Created once at startup; reconfigured per session via `compy.*` API; text-editing sink |
| `ProjectController` | New controller; owns keypressed/textinput for project-running context; implements three-level dispatch |
| `compy.input.show(config)` | Activate singleton with config (prompt, text, cursor `{line,col}`, highlighter, validator, multiline) |
| `compy.input.hide()` | Deactivate silently |
| `compy.input.configure(config)` | Live-update config fields mid-session |
| `compy.input.clear()` | Clear content without hiding |
| `compy.input.get_cursor()` | Read cursor position while active; returns `line, col` (2D, 1-based source-line) |
| `compy.input.set_cursor(line, col)` | Set cursor position while active |
| `compy.input.set_text(text [, keep_cursor])` | Replace text content while active (live write) |
| `compy.input.handlers[combo]` | Project-registered per-combo handlers; metatable-normalised; `"ctrl+s"` format |
| `compy.input.on_key_pressed` | Generic keypressed callback (default value is the text-editing sink) |
| `compy.input.on_text_entered` | Character input callback (default value is the textinput sink) |
| `compy.input.before_submit` / `after_submit` | Hooks around framework's evaluate step |
| `compy.input.before_cancel` / `after_cancel` | Hooks around framework's dismiss step |
| `compy.input.on_limit_reached` | Cursor hit input boundary |
| Legacy text-input globals | **Removed** — `input_text()`, `input_code()`, `validated_input()`, `user_input()`, `write_to_input()` no longer exist (D-1 discarded); examples migrate to `compy.input.*`. Native `love.keypressed` coexistence (D-9) is retained |

---

## Three-level dispatch

```
framework_handlers[combo]        Enter, Escape — non-overridable
  ↓ (if not consumed)
compy.input.handlers[combo]            project per-combo handlers (metatable-normalised)
  ↓ (if not consumed)
compy.input.on_key_pressed(k, keys, isrepeat)  generic callback;
                                 default value = text-editing sink.
                                 Assigning a function replaces the default.
```

`compy.input.handlers` entries return truthy to consume (stop the
chain). `compy.input.on_key_pressed`'s default *is* the sink — there
is no separate fourth tier. Before/after chains for submit/cancel
use call-order, not return values.

Both LÖVE channels fire independently (no suppression):
- keypressed → three-tier dispatch → `compy.input.on_key_pressed`
- textinput → `compy.input.on_text_entered`

---

## Escape fix

Current: Escape clears input content but does not dismiss
the overlay. New: `framework_handlers['escape']` fires the
cancel chain and dismisses unconditionally. Project code
observes via `before_cancel` / `after_cancel`.
