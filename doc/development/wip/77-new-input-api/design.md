# Feature #77 — Design

*Primary design document for stakeholder and implementor
review. Sources: `notes/solution_sketch.md` and supporting
notes. Implementation spec is in `spec.md`.*

---

## 1. Problem and Scope

Feature #77 adds a persistent, callback-driven input widget
to the `compy` project API: one configurable edit area with
lifecycle control (`show`/`hide`/`configure`), event callbacks
for submit, cancel, key events, text input, and cursor
boundary hits, and programmatic cursor and content access.
The console REPL and editor are not migrated within this
feature; their migration to the same API is a named follow-on.
Touch input, multiple simultaneous edit areas, and changes
to the editor's internal block navigation are out of scope.

---

## 2. Architectural Approach — Routing Unification

### The current model

The dispatcher in `love.handlers.keypressed` (`controller.lua`)
routes all key events exclusively to the overlay widget when
`love.state.user_input` is set, bypassing the project's own
handlers entirely. Project code is unreachable while any
input prompt is on screen.

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

The `if user_input then` gate is not a designed abstraction;
it is a seam left by the overlay being added as a bolt-on to
the existing routing. It encodes a special case with no
natural extension point for callbacks.

### The new model

The gate is removed. `ProjectController` — a new controller,
sibling to `ConsoleController` and `EditorController` — owns
all input handling for the project-running context.
`UserInputController` becomes the universal terminal sink at
the bottom of every branch, doing work proportional to its
activation state (transparent no-op when hidden, text-editing
operations when visible).

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
              ├─ compy.input.on_key_pressed   [generic, overloadable, default: sink]
              └─ → UserInputController:keypressed  [sink]
```

Routing does not change based on whether the singleton is
visible. "Overlay active?" is gone as a routing condition;
widget visibility is a state on the singleton, not a gate.

**Native handler coexistence (legacy heuristic).** Projects
that define native `love.keypressed` (captured by the existing
`save_user_handlers` path) but set none of the new `compy.*`
surfaces are treated as legacy. `ProjectController` detects
this at load time and **auto-provisions `compy.input.on_key_pressed`**
as a lifecycle-split wrapper: when the singleton is visible, the
wrapper routes to the text-editing sink; when hidden, it routes
to the project's native handler. This reproduces today's gated
behaviour with zero project changes. Projects that set any
`compy.*` surface are new-style and the heuristic never applies.
In debug mode the wrapper logs its routing decision (transition
diagnostics). See §6 for the full spec.

The singleton follows structurally: because `UserInputController`
is always the sink, there is no "create overlay, route to it,
destroy on dismiss" lifecycle. `show()`/`hide()` are state
changes on the singleton, not routing changes.

---

## 3. Component Layout

### `keys_pressed` table

Maintained by `Controller` (the global controller in
`controller.lua`). Updated unconditionally on every
`love.handlers.keypressed` and `love.handlers.keyreleased`
call — a live set of currently-held key names.

Passed as a secondary argument to every `keypressed` and
`textinput` callback flowing downstream. Downstream consumers
receive a read-only proxy (iterator only), not the table
directly, to prevent tampering. Replaces the ad-hoc
`Key.ctrl()` / `Key.shift()` calls scattered across handlers.
Makes combo serialisation (`"ctrl+s"`) deterministic without
per-handler modifier checks.

### `UserInputController` singleton

Created once at framework startup (lazily; no allocation
until first use). Never destroyed. Activation state changes
via `show()`/`hide()` — no routing changes required.
`love.state.user_input` is set to the singleton on `show()`
and to `nil` on `hide()`, preserving the existing rendering
gate in `UserInputView` without code changes.

Projects and the REPL/editor interact with it only through
the `compy` namespace API. No direct references to the
controller object from project code.

The `oneshot` flag (a `UserInputModel` field, `userInputModel.lua:15,49`)
is deleted in M6, once both its jobs are covered: activation by
`show()`/`hide()` and submit by `framework_handlers['return']` in
`ProjectController`. Until M6 it stays and continues to drive
submit exactly as today. At M6, deletion touches `userInputModel.lua`
(field removal) and `userInputController.lua` (submit-path code
that reads `self.model.oneshot`).

### `ProjectController`

New controller, a sibling to `ConsoleController` and
`EditorController`. Active when `app_state = 'running'` or
`'project_open'`. Owns `keypressed` and `textinput` handling
for all project states, whether or not the singleton is
currently visible.

Implements the three-level dispatch (§4). On project stop,
resets `compy.input.handlers` and all project callbacks via
`stop_project_run` / `clear_user_handlers`
(`consoleController.lua:860–868`). Also auto-provisions
`compy.input.on_key_pressed` for legacy projects via the heuristic
described in §2 and §6.

### `compy` API additions

| Name | Kind | Description |
|---|---|---|
| `compy.input.show(config)` | function | Activate singleton with given config |
| `compy.input.hide()` | function | Deactivate singleton silently |
| `compy.input.configure(config)` | function | Live-update config fields |
| `compy.input.clear()` | function | Clear input content without hiding |
| `compy.input.handlers` | table | Project-registered combo → function map |
| `compy.input.on_key_pressed` | callback | Generic keypressed callback (fires for all keys; default = sink) |
| `compy.input.on_text_entered` | callback | Character input callback (default = textinput sink) |
| `compy.input.before_submit` | callback | Hook before framework evaluates |
| `compy.input.after_submit` | callback | Hook after evaluation (receives the result) |
| `compy.input.before_cancel` | callback | Hook before framework dismisses |
| `compy.input.after_cancel` | callback | Hook after dismissal |
| `compy.input.on_limit_reached` | callback | Cursor hit input boundary |
| `compy.input.get_cursor()` | function | Query cursor position while active; returns `line, col` (2D, 1-based source-line); returns `nil` when hidden |
| `compy.input.set_cursor(line, col)` | function | Set cursor position while active; no-op when hidden |
| `compy.input.set_text(text [, keep_cursor])` | function | Replace text content while active (live write; exception to `configure()` text-immutability) |

---

## 4. Three-Level Dispatch

`ProjectController:keypressed` implements three tiers:

```
framework_handlers[combo]        non-overridable structural keys:
  |                              Enter, Escape live here.
  ↓ (if not consumed)
compy.input.handlers[combo]            project-registered per-combo
  |                              handlers; return truthy to consume
  ↓ (if not consumed)
compy.input.on_key_pressed(k, keys, isrepeat)  generic catchall callback.
                                 Default value is the text-editing
                                 sink (UserInputController:keypressed).
                                 Assigning a function replaces the
                                 default; no tier exists below it.
```

`compy.input.handlers` entries return truthy to consume (stop the
chain; sink does not run). `compy.input.on_key_pressed` has no
separate tier below it — its default value *is* the sink.
A project that overrides `compy.input.on_key_pressed` replaces the
default entirely. Note: if the default is replaced,
`on_limit_reached` no longer fires (it originates in the
keypressed sink); the spec notes this.

The textinput path follows the **same principle** as keypressed,
not a different one: `compy.input.on_text_entered`'s default value
is the textinput sink (`UserInputController:textinput`), and
assigning a function replaces it exactly as overriding
`on_key_pressed` replaces the keypressed sink. The only structural
difference is that the textinput channel has no combo tier above
it (characters are not combos); the default-sink/override
semantics are identical.

The before/after submit/cancel chains (§5) use call-order,
not return values, for ordering; they are not subject to the
"consumed" mechanism.

### Shared dispatch function

All three controller branches eventually will share one dispatch
implementation written once. `ProjectController` uses it first;
`ConsoleController` and `EditorController` migrate to it when ready.

```lua
dispatch(k, keys_pressed,
  framework_handlers, handlers, callback)
```

The `callback` argument defaults to the text-editing sink; when
a project assigns `compy.input.on_key_pressed`, that function becomes
the `callback`.

### `compy.input.handlers` combo format

Combo strings use **modifier-first** ordering by fixed
precedence (`ctrl`, `alt`, `shift`, `gui`) followed by the
triggering key, joined with `+`. Modifier names are
**generic** (l/r folded): `ctrl` not `lctrl`/`rctrl`, so
registering `"ctrl+s"` catches either control key. The
`keys_pressed` table retains precise LÖVE key names; only combo
serialisation folds. Examples: `"ctrl+s"`, `"alt+shift+f4"`,
`"escape"`.

`compy.input.handlers` is **metatable-backed**: `__newindex`
normalises the registered key to canonical form on assignment
(`compy.input.handlers['Ctrl+S'] = fn` is stored as
`compy.input.handlers['ctrl+s']`). Dispatch uses an **overloadable
matcher** with an exact canonical match default (O(1)); the
matcher is the marked extension seam for future glob/prefix
matching and is project-overloadable.

---

## 5. Enter and Escape Handling

Both keys are `framework_handlers` entries in
`ProjectController` — non-overridable from project space
but extensible via named callback chains.

**Enter:**

```
framework_handlers['return']:
  before_submit(keys_pressed)
  → submit: model:evaluate() → push 'userinput'
  → after_submit(result)
```

Shift+Enter passes through to the sink and inserts a
newline (existing behaviour preserved).

**Escape:**

```
framework_handlers['escape']:
  before_cancel(keys_pressed)
  → cancel: model:cancel() → push 'userinput' → hide singleton
  → after_cancel()
```

This resolves the current limitation where Escape clears
input content but does not dismiss the overlay. In the new
model, the framework's `cancel` step pushes `'userinput'`
unconditionally; `after_cancel` gives the project an
observation point.

---

## 6. Legacy API Removal

The legacy text-input globals — `input_text()`, `input_code()`,
`validated_input()`, `user_input()`, and `write_to_input()` —
are **removed**, not wrapped as facades (D-1 discarded by
stakeholders; see `input.md` round 1 and `decisions.md` D-1).
There is no backward-compatibility layer, no deprecation shim,
and no `strict_input` flag. The reftable / `is_empty()` polling
idiom is removed with them; the new API is callback-based
(`after_submit(result)` is the submit observation point that
replaces the polled reftable).

The in-repo examples that use these functions are migrated to
`compy.input.*` (roadmap M8). `write_to_input`'s one consumer
(`tixy`) moves to `compy.input.set_text`. Because migration needs
the full `compy.input.*` surface (config with validator/highlighter,
the callback chain, `set_text`/cursor), removal and migration
land together as the last milestone, after M7.

`love.state.user_input` is set on `compy.input.show()` and cleared
on `compy.input.hide()`, exactly as for any new-API caller — there
is no separate legacy path setting it.

The break is bounded to text input. Native keyboard handling is
a separate surface and is unaffected — see below.

### Native handler coexistence

Projects that define native `love.keypressed`/`textinput`
(without any `compy.*` surfaces) are handled transparently:
`ProjectController` auto-provisions `compy.input.on_key_pressed` as
a lifecycle-split wrapper. When the singleton is visible, the
wrapper routes to the text-editing sink; when hidden, it routes
to the project's native handler. This reproduces today's gated
behaviour with zero example changes. See §2 for the full
heuristic and transition diagnostics description.

---

## 7. Implementation Order and Migration Path

The six sections of `notes/solution_sketch.md` are listed
in implementation-dependency order. Each section can be
completed and verified before the next begins:

| Step | What it delivers | Test before next step |
|---|---|---|
| 1. `keys_pressed` table | Live modifier state; combo serialisation | No behaviour change; existing tests pass |
| 2. Singleton extraction | Widget created at startup | Existing tests pass; no allocation change visible |
| 3. ProjectController + gate removal | New routing; existing behaviour preserved via sink | Overlay input works as before; project key events now routable |
| 4. Three-level dispatch | `compy.input.handlers`, `compy.input.on_key_pressed` | Handler registration and bubbling work |
| 5. Before/after chains | Submit/cancel callbacks; Escape dismisses | Named hooks fire; Escape limitation resolved |
| 6. Legacy removal + example migration | Legacy text-input globals deleted; examples on the new API | Priority examples (tixy, balloons) run; legacy globals gone |

Steps 1→2 are behaviour-neutral infrastructure. Step 3 (the
gate removal) needs only Step 2. Steps 4 and 5 each build on
Step 3 independently. Step 6 (legacy removal + migration) comes
last, because migrating the examples needs the full new surface
(callbacks from Steps 4–5 and the cursor/`set_text` surface).
The legacy text-input globals are not built as facades at any
step — they are simply removed once the examples no longer need
them (D-1 discarded; see §6). Note: the roadmap milestones
(`roadmap.md`) keep the cursor/`set_text` surface as a separate
M7 and the legacy removal as M8, so the milestone numbering is
M1–M8; these six implementation steps are the coarser
dependency grouping.

The console and editor migration (Step 6 of the
`solution_sketch.md` description) is a clean follow-on:
it replaces if-chains in `ConsoleController` and
`EditorController` with handler registrations; the
underlying methods (`evaluate_input`, `_handle_submit`,
history navigation, mode switches) are unchanged. No step
of the current feature scope requires the console or editor
to be migrated, and no step of the migration requires the
current feature to be partially complete.

### FR-11/FR-12 Coverage Walkthrough

The following maps the console REPL and editor key patterns
onto the new API, fulfilling D-7's walkthrough promise
(full analysis in `notes/editor_repl_input.md`).

**Console REPL (FR-11):**

| Action | Maps to |
|---|---|
| Enter → evaluate and submit | `framework_handlers['return']` (evaluate + push `'userinput'` + `after_submit`) |
| Up/Down at history boundary | limit signal from sink → `compy.input.on_limit_reached(direction)` → history navigation handler |
| Ctrl+L clear terminal | `compy.input.handlers['ctrl+l'] = function() clear_terminal() return true end` |
| Error display | sink (unchanged — model handles it internally) |
| Escape → clear input line | on migration, `ConsoleController` registers `framework_handlers['escape']` = clear-line; `ProjectController`'s dismiss-Escape is per-controller and never clobbers it |

**Editor input (FR-12):**

| Action | Maps to |
|---|---|
| Enter → submit block | `framework_handlers['return']` |
| Escape → load / cancel edit | `framework_handlers['escape']` + `before_cancel` |
| Up/Down at boundary → block navigation | `compy.input.on_limit_reached(direction)` |
| Ctrl+M / Ctrl+F mode switches | `compy.input.handlers['ctrl+m']` / `compy.input.handlers['ctrl+f']` |
| Load block text into input | `compy.input.set_text(block_text)` (FR-10 surface, D-8) |
| Read cursor position | `compy.input.get_cursor()` → `line, col` (FR-8 surface, D-8) |
| Set cursor position | `compy.input.set_cursor(line, col)` (FR-9 surface, D-8) |

The mapping is mechanical: if-chains become handler
registrations; underlying model methods are unchanged.
FR-12 requires the D-8 cursor surface (`compy.input.get_cursor` /
`compy.input.set_cursor`); without it, programmatic cursor
management is not expressible via the public API.
