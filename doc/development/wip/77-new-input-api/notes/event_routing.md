# Notes — Key Event Routing

Analysis of how keyboard events travel from OS to consumer
code, before and after the new API. Informs the D-3/D-6
routing decisions and identifies one open design detail
(suppression mechanism) to be resolved in `design.md`.

Related: `notes/decisions.md` §D-3, §D-6.

---

## LÖVE2D event taxonomy

LÖVE2D exposes two keyboard callbacks that can both fire for
the same physical gesture:

| Event | When it fires | Argument |
|---|---|---|
| `love.keypressed(k)` | Every physical key press (and repeat) | LÖVE2D key name string |
| `love.textinput(t)` | When the OS produces printable text | UTF-8 string (usually one char, can be multi-char for IME) |
| `love.keyreleased(k)` | Every physical key release | LÖVE2D key name string |

**Critical OS-level behaviour:** whether `textinput` fires
alongside `keypressed` depends on the OS and modifier state:

| Gesture | `keypressed` fires? | `textinput` fires? |
|---|---|---|
| Plain `a` | yes (`k='a'`) | yes (`t='a'`) |
| `Shift+a` | yes (`k='a'`) | yes (`t='A'`, OS handles case) |
| `Ctrl+a` | yes (`k='a'`) | **no** — Ctrl suppresses text output |
| `Ctrl+Shift+a` | yes | **no** |
| `Alt+a` | yes | platform-dependent |
| Arrow, F-key, etc. | yes | **no** — non-character key |
| IME composition | varies | yes (can be multi-char string) |

The framework does not control this split — it is an OS
decision before any Compy code runs.

---

## Current routing (before new API)

Two contexts are relevant: the project overlay (when a
project calls `input_text()`) and the REPL/editor
(ConsoleController + EditorController).

### A. Project overlay active (`user_input` is set)

The overlay behaves as a **silent singleton** already:
while `love.state.user_input` is set, any call to
`input_text()` / `input_code()` / `validated_input()` is
silently dropped — it returns `nil` and the existing overlay
is unaffected. The MVC triad is allocated once when the
first call creates the overlay; on submit, `UserInputModel`
pushes a `userinput` event which clears
`love.state.user_input`, making the triad GC-eligible. The
next `input_text()` call allocates a fresh one.

The difference from D-2's proposed singleton: the current
pattern allocates and GCs one triad per input session.
D-2 allocates once at framework startup and reconfigures
the same object on each `show()` call — eliminating the
per-session allocation entirely.

```
OS event
  │
  ▼
controller.lua : handlers.keypressed(k)
  ├─ global framework shortcuts (Ctrl+Q, Ctrl+T, etc.)
  └─ user_input.C:keypressed(k)
       └─ UserInputController:keypressed
            ├─ cursor, backspace, selection, etc.
            └─ Enter (oneshot=true path):
                 evaluator runs → if ok:
                   reftable filled
                   love.event.push('userinput')
                     → handlers.userinput
                       → love.state.user_input = nil
                 [project polls reftable; receives no key events]

OS event
  │
  ▼
controller.lua : handlers.textinput(t)
  └─ user_input.C:textinput(t)
       └─ UserInputController:textinput
            └─ UserInputModel:add_text(t)
               [project receives no text events]
```

All key and text events are consumed by the overlay.
Project code has no way to observe or intercept them — it
only sees the final submitted value via the reftable.

Note: the overlay's Enter submit path runs inside
`UserInputController:keypressed` (the `oneshot` flag).
This differs from the console REPL, where Enter is handled
in `ConsoleController:keypressed` → `evaluate_input()`.
The submit mechanisms are distinct even though both use
the same underlying widget.

### B. No overlay — project running with raw LÖVE2D callbacks

```
OS event
  │
  ▼
controller.lua : handlers.keypressed(k)
  ├─ global framework shortcuts
  └─ love.keypressed(k)           ← project's own callback if set

OS event
  │
  ▼
controller.lua : handlers.textinput(t)
  └─ love.textinput(t)            ← project's own callback if set
```

Projects can intercept keys here, but only outside of input
sessions. The two modes are mutually exclusive today.

### C. REPL / editor (no overlay, ConsoleController active)

The console REPL and the editor share **one** persistent
`UserInput` widget (`UserInputModel` / `UserInputController`
/ `UserInputView`), owned by `ConsoleModel` and borrowed by
`EditorController` when the editor is active. Neither creates
a fresh widget on activation — they reconfigure the shared
one. This is distinct from the project overlay (section A),
which allocates its own separate triad.

```
OS event
  │
  ▼
controller.lua : handlers.keypressed(k)
  ├─ global shortcuts
  └─ ConsoleController:keypressed(k)
       ├─ [if editor state] EditorController:keypressed(k)
       │    └─ mode if-chain (edit / reorder / search)
       │         └─ UserInputController:keypressed(k)
       └─ [else] console if-chain
            ├─ PageUp/Down → history nav
            ├─ Enter → evaluate_input()
            └─ UserInputController:keypressed(k)
                 └─ cursor, backspace, etc.

OS event
  │
  ▼
controller.lua : handlers.textinput(t)
  └─ ConsoleController:textinput(t)
       ├─ [Ctrl+Shift filtered out here]
       ├─ [if editor] EditorController:textinput(t)
       └─ [else] UserInputController:textinput(t)
            └─ UserInputModel:add_text(t)
```

---

## Proposed routing (after new API)

Scope: project overlay path only (D-7). Console and editor
paths are unchanged in this feature.

**What changes structurally (D-2):** the console/editor
already share one persistent input widget. The project
overlay currently creates a fresh one per call. After D-2,
all three contexts use the same framework-level singleton —
the console/editor reconfigure it when they become active,
and the project overlay configures it via `show()`/`hide()`
rather than allocating a new triad.

### Proposed routing when project overlay is active

```
OS event
  │
  ▼
controller.lua : handlers.keypressed(k, scancode, isrepeat)
  ├─ global framework shortcuts (unchanged)
  ├─ compy.keys_pressed[k] = true          ← new: track pressed set
  ├─ compy._on_key_pressed(k, keys_pressed, isrepeat)
  │    ├─ 1. framework_handlers[combo]     ← structural (escape, enter, etc.)
  │    ├─ 2. compy.handlers[combo]         ← project-registered, combo-specific
  │    └─ 3. compy.on_key_pressed(k, ks)  ← generic fallback, noop+log
  │              [see suppression note below]
  └─ UserInputController:keypressed(k)     ← text editing unchanged

OS event
  │
  ▼
controller.lua : handlers.textinput(t)
  ├─ compy._on_textinput(t, keys_pressed)  ← new
  │    └─ compy.on_text_entered(t, mods)  ← project callback, noop+log
  └─ UserInputController:textinput(t)      ← text editing unchanged

OS event
  │
  ▼
controller.lua : handlers.keyreleased(k)
  ├─ compy.keys_pressed[k] = nil           ← new: remove from pressed set
  └─ compy._on_key_stroke(k, keys_pressed) ← new: release event
       ├─ 1. framework_handlers (on release, if any)
       ├─ 2. compy.handlers[combo]
       └─ 3. compy.on_key_stroke(k, ks)   ← generic fallback, noop+log
```

`combo` is a string key derived from `keys_pressed` at the
time of the event — currently-held keys plus the trigger key,
sorted and joined (e.g. `"lctrl+s"`). Exact serialisation
format is a spec detail (see D-3 resolution).

`mods` in `on_text_entered` is the subset of `keys_pressed`
that are non-character modifier keys at the time `textinput`
fires.

### Ctrl+character routing (concrete example)

`Ctrl+C` pressed:

```
1. keypressed('lctrl'):
     keys_pressed = { lctrl = true }
     _on_key_pressed('lctrl', {lctrl=true})
     → combo = 'lctrl'; no handler registered; generic fires

2. keypressed('c'):
     keys_pressed = { lctrl = true, c = true }  [or c tracked separately]
     _on_key_pressed('c', {lctrl=true, ...})
     → combo = 'lctrl+c'
     → compy.handlers['lctrl+c'] fires if registered
     → generic on_key_pressed fires if not handled

3. textinput: does NOT fire (OS suppresses for Ctrl)
   → on_text_entered is never called
```

`Ctrl+C` is therefore handled entirely via the handler
table, not via `on_text_entered`. A project registers
`compy.handlers['lctrl+c']` to intercept it.
This is coherent: the routing decision is made by the OS
before the framework sees the event.

Contrast with `Shift+A`:

```
1. keypressed('lshift'): keys_pressed = {lshift=true}
2. keypressed('a'):      keys_pressed = {lshift=true, a=true}
     → combo 'a+lshift'; handler fires if registered
3. textinput('A'):       fires (OS applies Shift → uppercase)
     → on_text_entered('A', {lshift=true})
```

For `Shift+A` both paths fire. See suppression note below.

---

## Open design detail: suppression mechanism

The summary (`summaries/decisions.md`) states: "for plain
character keys where both events fire, the framework
suppresses the `on_key_pressed` project callback so project
code receives exactly one notification per gesture."

The mechanism for this suppression is not yet specified.
The problem: `keypressed` fires before `textinput` in the
LÖVE2D event queue, so at the time `_on_key_pressed` runs for
'a', the framework does not yet know that `textinput('a')`
will follow.

Two candidate approaches for `design.md` to choose between:

**Option A — Distinct semantics, no suppression needed.**
Define `on_key_pressed` and `on_text_entered` as covering
different concerns (physical key events vs text input) rather
than as competing notifications for the same gesture. A
project that wants to handle typed characters uses
`on_text_entered`; a project that wants physical key
awareness uses `on_key_pressed`. Both fire; neither "cancels"
the other. This matches how DOM `keydown` and `input` events
work. Double-fire is only a concern if a project
misuses both callbacks for the same purpose — a documentation
concern, not a framework concern.

**Option B — Deferred generic callback.**
`_on_key_pressed` fires framework_handlers and compy.handlers
immediately (these are combo-specific and need no
suppression). The generic `on_key_pressed` fallback is
deferred by one event-pump tick. If `textinput` fires for the
same key before the deferred callback runs, the deferred
callback is cancelled. Adds implementation complexity;
preserves the "one notification" guarantee for the generic
path.

Option A is simpler and consistent with established event
models. Option B gives the guarantee stated in the summary
but requires non-trivial deferred dispatch machinery.

**Recommendation for `design.md`:** choose Option A, update
the summary language accordingly. The D-6 note "modifier +
character-producing key → `on_text_entered`" is accurate
as a usage guideline (not a suppression rule): projects that
care about typed characters should use `on_text_entered`;
projects that care about key combos should use
`compy.handlers` or `on_key_pressed`.

---

## Mouse input (out of scope for this feature — for reference)

Mouse routing is a parallel path not covered by the diagrams
above. Brief summary for completeness:

- `love.handlers.mousereleased` implements single/double
  click detection with a 0.4s timer. Confirmed clicks fire
  `compy.singleclick(x, y)` / `compy.doubleclick(x, y)` —
  Compy-specific abstractions, not LÖVE2D events.
- Raw `love.mousepressed` / `mousereleased` / `mousemoved`
  / `wheelmoved` are also forwarded to project-defined LÖVE2D
  handlers via the standard wrap mechanism.
- When an overlay is active, the framework's mouse handlers
  call both the user handler AND the overlay controller —
  both receive mouse events (unlike key events, which are
  exclusively routed to the overlay).
- `UserInputController` handles mouse on the input widget
  for cursor placement and drag-selection. Suppressed in
  editor mode (`disable_selection = true`).

Mouse callbacks (`compy.singleclick`, `compy.doubleclick`)
are already project-facing and callback-based — they are
unaffected by this feature.
