# Solution Sketch — Feature #77 New Input API

High-level description of the proposed implementation approach.
This feeds into `design.md`. References to D-1 through D-7
are the decisions documented in `summaries/decisions.md`.

---

## 1. `keys_pressed` table (framework level)

`Controller` (the global controller in `controller.lua`)
maintains a `keys_pressed` table — a live set of currently
held key names, updated unconditionally on every
`love.handlers.keypressed` and `love.handlers.keyreleased`
call. This is a framework-level change invisible to project
code.

The table is read-only from the outside: downstream consumers
receive an iterator, not a direct reference, to prevent
tampering. It is passed as a secondary argument to every
`keypressed` and `textinput` callback flowing downstream.

Primary purpose: unified combo recognition. Replaces the
current ad-hoc pattern where each handler calls
`Key.ctrl()` / `Key.shift()` (thin wrappers over
`love.keyboard.isDown()`) at the point of handling. With the
table, any handler can serialise the current combo as a string
(e.g. `"lctrl+s"`) and look it up in a handler table without
per-handler modifier checks. This is the foundation for D-3's
three-level dispatch.

---

## 2. `UserInputController` as a framework singleton (D-2)

`UserInputController` becomes a singleton provisioned at
framework startup — created once [lazily], never destroyed,
reconfigured per context. Projects and the REPL/editor never
hold a direct reference to the object. All interaction goes
through explicit API functions in the `compy` namespace:
`show()`, `hide()`, `alter_prompt()`, `clear()`, `read()`, and
so on.

The reconfiguration surface is expanded beyond the current
prompt-only capability: validator, highlighter, and other
per-session settings are also configurable via the API.

Access control (preventing one subsystem from reconfiguring
an input session owned by another) is a future concern, not
in scope for this feature.

### 2a. Legacy API compatibility (D-1)

Existing project-level functions — `input_text()`,
`input_code()`, and related — are rewired as facade wrappers
that call the new singleton API internally. Projects that use
the legacy polling pattern (`if not r:is_empty()...`)
continue to work: the legacy wrapper implicitly registers a
submit callback that fills the reftable, preserving the
polling observation point.

`love.state.user_input` continues to be set and cleared by
the singleton's `show()`/`hide()` methods. During the
transition it points to the singleton instance rather than a
freshly created object; it is set to nil on hide to keep the
overlay routing gate functional (see §3 below for how that
gate is ultimately removed).

Deprecation warnings are emitted inside the legacy wrappers
in debug mode (D-1). A future flag will make legacy calls
hard-fail unless an opt-out configuration is set, providing
a clean, gradual deprecation path.

---

## 3. Routing unification: `ProjectController` (D-7)

The `if user_input then ... else ... end` gate in
`love.handlers.keypressed` (`controller.lua`) is removed.
Instead, the handler routes unconditionally to whichever
controller is currently active — `ConsoleController`,
`EditorController`, or the new `ProjectController` — exactly
as it does for the existing non-overlay contexts.

`ProjectController` is a new controller, a sibling to
`ConsoleController` and `EditorController`, responsible for
the project-running context. It owns keypressed and textinput
handling for all project states, whether or not the singleton
input widget is currently visible.

`UserInputController` is no longer a routing destination in
the overlay gate. It becomes the universal terminal sink at
the bottom of every branch (see `notes/routing_unification.md`
for the full diagram and rationale).

---

## 4. Three-level dispatch inside `ProjectController` (D-3)

`ProjectController:keypressed` implements the three-level
dispatch:

```
framework_handlers[combo]      — non-overridable; Enter, Escape,
  |                              and other structural keys live here
  ↓ (if not consumed)
compy.handlers[combo]          — project-registered per-combo handlers
  |
  ↓ (if not consumed)
compy.on_key_pressed(k, keys)  — generic fallback callback (default: noop + log)
  |
  ↓ (if not consumed)
UserInputController:keypressed — universal sink; text-editing operations
```

The implementation does not have to be a literal if-else chain — fallback
lookup tables or equivalent are fine. Invocation of
`UserInputController:keypressed` could also be the default value of
`compy.on_key_pressed` rather than a hardcoded final step.

At every level, a handler returning a truthy value signals
"consumed" and stops the chain. This is the return-value
bubbling mechanism (DOM `preventDefault()` equivalent) — an
opt-in escape hatch; the default (sink always runs) is correct
for the majority of keys and projects.

`compy.handlers` is the project-registered handler table: a
mapping from serialised combo strings to functions. The
`keys_pressed` table from §1 makes combo serialisation
deterministic at every dispatch point.

The same dispatch function is shared across all three
controller branches:

```lua
dispatch(k, keys_pressed, framework_handlers, handlers, callback, sink)
```

Alternatively, this could be an inheritable method on a base controller
class, reducing the argument surface.

ConsoleController, EditorController, and ProjectController each call it
with their own handler tables; the implementation is written once
(D-7 migration path). Initially only ProjectController uses it —
ConsoleController and EditorController migrate when ready.

---

## 5. Enter and Escape as `framework_handlers` entries (D-4)

Enter and Escape are handled at the `framework_handlers` level
inside `ProjectController` — non-overridable from project
space, but extensible via named callback chains (D-4):

```
before_submit → submit (framework) → after_submit
before_cancel → cancel (framework) → after_cancel
```

The framework owns the middle step (evaluate input, fill
reftable, push `'userinput'`, dismiss). Project code extends
it via the before/after hooks; by default all four hooks are
noops with a debug log entry.

This also resolves the current Escape limitation (overlay
clears content but does not dismiss): with `cancel` as an
explicit `framework_handlers` entry, the framework's cancel
step dismisses the overlay unconditionally; `after_cancel`
gives the project an observation point.

The `oneshot` flag on `UserInputController` is deleted as a
consequence: submit is always the framework_handlers entry's
responsibility, never the sink's. See
`notes/enter_escape_routing.md` for the full analysis.

---

## 6. Migration path for ConsoleController and EditorController

After `ProjectController` and the three-level dispatch are
validated, `ConsoleController` and `EditorController` can be
migrated to the same dispatch function incrementally (D-7).

Migration for each is mechanical: the existing if-chains
(sequences of `if Key.ctrl() and k == 'x' then ...`) become
handler registrations in their respective `framework_handlers`
tables; the underlying handler methods are unchanged. Both
controllers already terminate at `UserInputController` as the
sink, so the structural change is at the dispatch layer only.

Each controller's migration is a named follow-on feature, not
in scope for this one.
