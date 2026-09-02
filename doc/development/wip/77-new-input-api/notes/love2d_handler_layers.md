# Notes — LÖVE2D Handler Layers and Compy's Dispatch Model

Explains the two-level event handler architecture that
underlies all keyboard routing in Compy. Prerequisite reading
for `notes/event_delegation_chain.md`.

---

## LÖVE2D's event architecture

LÖVE2D processes input through an event queue. Each frame:

```
love.event.pump()      -- collect OS events into queue
love.event.dispatch()  -- process each queued event
```

`dispatch()` works by calling `love.handlers[eventname](args)`
for each event. `love.handlers` is a plain Lua table of
functions, one per event type. The default
`love.handlers.keypressed` is approximately:

```lua
love.handlers.keypressed = function(k, scancode, isrepeat)
  if love.keypressed then
    love.keypressed(k, scancode, isrepeat)
  end
end
```

`love.keypressed` is the conventional user-facing callback —
a game sets `function love.keypressed(k) ... end` and the
default handler calls it. The two levels are not separate
systems: `love.handlers.keypressed` is the raw dispatch entry
point; `love.keypressed` is the callback it invokes. Normally
only `love.keypressed` is touched. `love.handlers` is touched
only when pre-empting the conventional callback is necessary.

---

## What Compy does to this

Compy replaces `love.handlers.keypressed` entirely with its
own function (`controller.lua:528`). This gives the framework
first-mover advantage — it runs before any project or
ConsoleController code. Two things are done at this level:

**Global power shortcuts** (Ctrl+Q, Ctrl+T, Ctrl+Shift+R,
etc.) are intercepted unconditionally. They must work in
every application state, including when a project has
overwritten `love.keypressed` with its own handler.

**Overlay interception** — if `love.state.user_input` is set,
all keyboard events are routed exclusively to the overlay
controller and `love.keypressed` is never called.

If neither condition applies, the handler falls through to
whatever is currently in `love.keypressed`.

---

## The `love.keypressed` slot

At startup, Compy sets `love.keypressed` to
`ConsoleController:keypressed` and saves it in
`Controller._defaults.keypressed`. This is the permanent
baseline for when no project is running.

When a project runs and defines its own
`function love.keypressed(k) ... end`, `set_handlers()` wraps
it with error catching and places it in `love.keypressed`.
When the project stops, `love.keypressed` is reset to the
saved ConsoleController handler.

`love.keypressed` is therefore a slot whose occupant changes
with application state. The framework level (`love.handlers`)
is fixed; the application level (`love.keypressed`) is
variable.

---

## Routing model

Two questions determine where a keypress lands:

```
Is the overlay active?
  YES → UserInputController:keypressed (directly, exclusively)
  NO  → who occupies love.keypressed?
          ConsoleController   (no project running)
          project's handler   (project running, handler defined)
          nothing             (project running, no handler)
```

Diagram:

```
OS keypress
  │
  ▼
love.handlers.keypressed         [Compy's, fixed, always runs]
  ├─ global shortcuts             [intercepted unconditionally]
  ├─ overlay active?
  │     YES ──────────────────────────────────────────────┐
  │     NO  ↓                                             │
  └─ love.keypressed                                      │
        ├─ ConsoleController:keypressed                   │
        │     ├─ REPL: history, Enter → evaluate_input    │
        │     └─ → UserInputController:keypressed ◄───────┤
        ├─ EditorController:keypressed                    │
        │     ├─ mode shortcuts, Enter → _handle_submit   │
        │     └─ → UserInputController:keypressed ◄───────┤
        └─ project's own handler (if defined)             │
                                                          │
                         UserInputController:keypressed ◄─┘
                           [shared leaf — cursor, backspace,
                            selection, Ctrl+C/V, Shift+Enter,
                            etc. Unhandled keys drop here.]
```

`love.handlers.keypressed` is one fixed function. The routing
variation comes entirely from (a) whether the overlay is
active and (b) what currently occupies `love.keypressed`.

`UserInputController:keypressed` is the shared leaf at the
bottom of every branch. The overlay reaches it directly and
exclusively; the REPL and editor reach it by delegation after
handling their own context-specific keys first. Keys the
widget does not handle are silently discarded at this point —
there is no pass-through path. This is the gap the new API
addresses: a callback dispatch point inserted at the drop
boundary so unhandled (and handled) keys can surface to
project code.

---

## Why REPL and editor are not project-level code

Both the REPL and editor use `UserInputController` for text
editing, and both route through `love.keypressed`. This makes
them look like variants of the same kind of thing as a
running project.

The difference is the level of access. Projects receive a
sandboxed `compy` API table — they interact with the
framework through a defined surface. ConsoleController is
part of the framework itself: it calls `run_project`,
`edit`, `evaluate_input`, and other internal methods that
project code never touches.

REPL and editor are the application's own operating modes —
the state the system is in when no project is loaded.
ConsoleController is the permanent baseline handler, not a
user-level component. The shared text-editing widget
(`UserInputController`) is an implementation detail they
happen to share with the overlay; it does not make them
equivalent in any other sense.

---

## Summary

| Level | Set by | Changes when |
|---|---|---|
| `love.handlers.keypressed` | Compy framework, once at startup | Never |
| `love.keypressed` | `set_love_keypressed(CC)` at startup; `set_handlers()` when project runs | Project starts / stops |
| `love.state.user_input` | `input_text()` etc. in project env | Overlay is shown / dismissed |
