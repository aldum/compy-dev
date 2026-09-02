# Notes — Unified Routing Architecture

A reformulation of the dispatch model that emerged from
mapping the current event delegation chain. Supersedes the
overlay-centric framing in D-3 and D-7 and provides a
cleaner structural basis for `design.md`.

Related: `notes/love2d_handler_layers.md`,
`notes/event_delegation_chain.md`, `notes/event_routing.md`.

---

## The core insight

The `if user_input then ... else ... end` gate in
`controller.lua` is not a designed abstraction. It is the
seam left by the overlay being added as a bolt-on to the
existing routing. It encodes a special case: when a project
has active input, route exclusively to the overlay widget and
bypass everything else.

Removing this gate and making `UserInputController` the
universal terminal sink in all branches produces a routing
model that is symmetric, has no special cases, and directly
satisfies all requirements — without adding complexity.

---

## The structural change

**Before:** two routing worlds separated by the overlay gate.

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

**After:** three symmetric branches, all terminating at the
same sink.

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
              ├─ compy.handlers[combo]  [project-registered]
              ├─ compy.on_key_pressed   [generic, noop+log]
              └─ → UserInputController:keypressed  [sink]
```

`ProjectController` is the new entity that handles the
project-running context. It follows the same three-level
dispatch pattern as the other two branches.

---

## What UserInputController becomes

In the new model, `UserInputController` is a **passive
terminal sink** — always at the bottom of every branch,
doing work proportional to its current activation state:

- **Singleton hidden** (no active input session): sink is a
  transparent no-op. Keypresses pass through handlers and
  callbacks above; the sink returns without action.
- **Singleton visible** (active input session): sink processes
  text-editing keys — backspace, cursor movement, selection,
  copy/paste, Shift+Enter. Returns a limit signal if cursor
  hits a boundary.

The routing above the sink does not change based on whether
input is active. The "overlay active?" check is gone.

---

## The singleton follows from this naturally

Because `UserInputController` is always the sink, it must be
a singleton — there is no longer a "create overlay widget,
route to it, destroy on dismiss" lifecycle. Activation is a
state change on the singleton (`show()`/`hide()`), not a
routing change. This satisfies D-2 and NFR-1 as a structural
consequence, not as a separate design effort.

---

## Why all requirements are satisfied

| Requirement | How it is met |
|---|---|
| FR-5 submit notification | `framework_handlers['enter']` fires submit callback before sink runs Enter path |
| FR-6 non-char key notification | `compy.handlers[combo]` and `compy.on_key_pressed` fire before sink; project sees every event |
| FR-7 boundary notification | Sink's limit return value fires `on_limit_reached` hook; both project and framework observe it |
| FR-1–FR-4 lifecycle | `show()`/`hide()`/`configure()` are state changes on singleton; routing unchanged |
| NFR-1 no per-session allocation | Singleton never recreated; follows structurally |
| NFR-2 event-driven model | Three-level dispatch IS the event model; no polling required |
| FR-11/FR-12 expressiveness | Console and editor already follow the same pattern; migration replaces if-chains with handler registrations |

---

## Dispatch code can be shared

Once all three branches follow `framework_handlers →
project/context handlers → generic callback → sink`, the
dispatch logic is the same function called with different
handler tables. The three contexts become three
*configurations* of one dispatch path:

```
dispatch(k, keys_pressed, framework_handlers, handlers, callback, sink)
```

ConsoleController, EditorController, and ProjectController
each call this with their own handler tables. The
implementation is written once.

---

## Relation to existing decisions

**D-2 (singleton):** unchanged in direction; now follows
structurally from the routing model rather than being a
separate design choice.

**D-3 (event topology):** correct. The three-level dispatch
described there now applies to all three contexts, not just
the overlay path. Scope expands; design intent unchanged.

**D-7 (overlay-first rollout):** the *implementation* is
still overlay-first (ProjectController is the new work;
console and editor continue with existing paths for now).
Conceptually, "overlay" as a routing concept dissolves — it
is replaced by "singleton is currently visible." The gradual
rollout path is: implement ProjectController + three-level
dispatch first; console/editor branches migrate to the same
dispatch function when ready.

---

## The bubbling mechanism — completion of the model

When the singleton is active and a project registers a
handler for a key that `UserInputController` also handles
(e.g. `compy.handlers['backspace']`), both the handler and
the sink would run by default — the handler first, then the
sink deletes a character. This may or may not be the
project's intent.

The return-value convention resolves this cleanly: a handler
that returns a truthy value signals "consumed" and the sink
does not run for that key. This is the minimal DOM-style
`preventDefault()` equivalent. It does not affect the
semantic event chains (before_submit / submit / after_submit)
which use call-order rather than return values for ordering.

For most projects and most keys, the default (sink always
runs) is correct. The consumed signal is an opt-in escape
hatch for the cases that need fine-grained control.
