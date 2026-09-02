# Notes — Current Event Delegation Chain

Documents how keyboard events travel from LÖVE2D to their
final handler across all four input contexts. Companion to
`notes/event_routing.md` (which focuses on before/after
comparison for the new API) and `notes/context_differences.md`
(which focuses on widget configuration per context).

---

## The four contexts

The four contexts are mutually exclusive by `app_state`:

| Context | app_state | Who owns keypressed |
|---|---|---|
| REPL | `ready` | ConsoleController → UserInputController |
| Editor | `editor` | ConsoleController → EditorController → UserInputController |
| Project, no overlay | `running` / `project_open` | Project's own `love.keypressed` |
| Project, overlay active | `running` / `project_open` | Overlay's UserInputController (exclusive) |

---

## Two routing levels

There are two distinct levels of handler in LÖVE2D:

- **`love.handlers.keypressed`** — low-level, set once in
  `controller.lua` at startup for all project-running states.
  Intercepts power shortcuts (Ctrl+Q, Ctrl+T, etc.) before
  anything else, then routes to overlay or project.

- **`love.keypressed`** — higher-level callback, set via
  `Controller.set_love_keypressed(CC)` at startup to
  `ConsoleController:keypressed`. Projects can overwrite this
  with their own handler; `controller.lua` saves the original
  in `Controller._defaults` and restores it on project
  teardown.

When a project is running and no overlay is active, the
project's `love.keypressed` is called from inside
`love.handlers.keypressed` after the power shortcuts have
been checked.

---

## REPL context

```
LÖVE2D keypressed
  → love.keypressed = ConsoleController:keypressed
      ├─ [error state] intercept space/enter/arrows → clear_error; return
      ├─ PageUp/Down → history_back / history_fwd
      ├─ UserInputController:keypressed(k)
      │    handles: backspace, delete, Ctrl+Y, arrows, Home/End,
      │    Shift+Enter (newline), Ctrl+D (dup line), Ctrl+C/X/V,
      │    selection; returns a "limit" signal if cursor hits
      │    top/bottom boundary of the input
      ├─ limit + Up/Down → history nav
      ├─ Enter (no Shift) → evaluate_input()
      └─ Ctrl+L → clear output

LÖVE2D textinput
  → love.textinput = ConsoleController:textinput
      → UserInputController:textinput
           → UserInputModel:add_text(t)
```

Combos are not dispatched via a table. ConsoleController uses
explicit `if Key.ctrl() and k == "l"` checks. UserInputController
runs first; ConsoleController handles submit and navigation
after.

---

## Editor context

```
LÖVE2D keypressed
  → ConsoleController:keypressed
      → [app_state == 'editor'] EditorController:keypressed
            ├─ mode dispatch (edit / reorder / search)
            ├─ mode-specific shortcuts: Esc (load block),
            │  Ctrl+M (reorder mode), Ctrl+F (search mode),
            │  Ctrl+O (follow require), etc.
            ├─ Enter → EditorController:_handle_submit
            │    pretty-print → re-chunk → oversize check
            │    → replace buffer block → auto-save
            └─ (text-editing keys delegated)
                 → UserInputController:keypressed

LÖVE2D textinput
  → ConsoleController:textinput
      → [app_state == 'editor'] EditorController:textinput
           → UserInputController:textinput
                → UserInputModel:add_text(t)
```

EditorController is a thick handler — every keystroke passes
through it. It runs its own if-chains first, then delegates
text-editing keys (backspace, cursor movement, per-character
input) to UserInputController. The editor does not receive
"full strings"; characters arrive one at a time via
`textinput`. Submit (Enter) is caught by EditorController
before reaching UserInputController.

---

## Project, no overlay

```
LÖVE2D keypressed
  → love.handlers.keypressed (controller.lua)
      ├─ power shortcuts (Ctrl+Q/T/S, Ctrl+Shift+R, etc.)
      └─ love.keypressed(k)   ← project's own handler, if set

LÖVE2D textinput
  → love.handlers.textinput (controller.lua)
      └─ love.textinput(t)    ← project's own handler, if set
```

The project receives raw LÖVE2D key names and must manage
modifier state itself (e.g. `love.keyboard.isDown('lctrl')`).
No input widget, no combo dispatch, no structured submit path.

---

## Project, overlay active

Activating the overlay (`love.state.user_input` non-nil)
redirects routing at the framework level — before the project
sees anything:

```
LÖVE2D keypressed
  → love.handlers.keypressed (controller.lua)
      ├─ power shortcuts (always intercepted)
      └─ [user_input set] user_input.C:keypressed(k)  ← EXCLUSIVE
         [no user_input]  love.keypressed(k)           ← project

LÖVE2D textinput
  → love.handlers.textinput
      ├─ [user_input set] user_input.C:textinput(t)   ← EXCLUSIVE
      └─ [no user_input]  love.textinput(t)            ← project

LÖVE2D keyreleased  — same split
```

The overlay's UserInputController handles everything. Enter
is handled by the `oneshot` path inside
`UserInputController:keypressed`: evaluator runs → reftable
filled → `love.event.push('userinput')` → overlay cleared.

**Mouse is different.** Both the overlay controller and the
project's mouse handlers receive mouse events — mouse is not
exclusively routed to the overlay.

---

## Submit paths, compared

| Context | Enter reaches | What happens |
|---|---|---|
| REPL | ConsoleController:evaluate_input | Metalua parse, execute, output |
| Editor | EditorController:_handle_submit | Pretty-print, re-chunk, replace block, save |
| Overlay (oneshot) | UserInputController:keypressed | Evaluator runs, reftable filled, overlay cleared |
| Project, no overlay | Project's own love.keypressed | Whatever the project does |

---

## Architectural evaluation

### What holds up

The two-level handler split (`love.handlers` vs `love.keypressed`)
is a genuine seam with clear responsibilities: the framework
level owns global power shortcuts and overlay routing; the
project level owns everything application-specific. The
`app_state` machine enforces mutual exclusivity of contexts,
so the conditional branches throughout the dispatch chain map
onto real operating mode boundaries rather than ad-hoc
conditions. And `UserInputController` / `UserInputModel` as a
shared widget is a sound unifying idea — one text-editing
implementation regardless of who is using it.

### Where complexity has accumulated

`ConsoleController:keypressed` has taken on several
responsibilities over time: it is the REPL's own input
handler, the router to the editor, and the historical home for
logic that did not obviously belong elsewhere. The coupling
between ConsoleController and EditorController is tight —
ConsoleController owns the input widget, EditorController
borrows it, and both consult `app_state` to switch behaviour.

The combo-handling in both controllers is expressed as
explicit `if Key.ctrl()` chains spread across multiple files.
`agents/rules.md` identifies this as a known accumulated
pattern ("dispatch tables beat if-chains") and flags new code
as the place to correct it — the existing if-chains are a
legacy of the system's organic growth.

### Relevance to this feature

This complexity is concentrated in the REPL and editor paths,
which D-7 explicitly deferred. The overlay routing path — the
part being redesigned here — is the more self-contained of
the four: a straightforward if/else gate that hands off
exclusively to the overlay controller. The new API adds a
callback layer inside that controller; it is additive, not
a restructure of the delegation chain.

The accumulated complexity in ConsoleController and
EditorController is the natural target of the follow-on
migration (named in D-7). When the REPL and editor adopt
the new API, replacing the if-chains with handler
registrations becomes the organic outcome of that migration
rather than a separate refactor effort. No action is needed
in the current feature scope.
