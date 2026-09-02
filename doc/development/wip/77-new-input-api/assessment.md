# Feature #77 — Architecture Assessment

Maps each requirement in `requirements.md` to the current
architecture. For each: what exists, what is missing, and
what the reuse potential is. Does not propose solutions.

References are to source files under `src/`. Line numbers are
approximate and may drift as the code evolves.

---

## 1. Edit Area Setup (FR-1)

FR-1 requires a single setup call accepting optional initial
text, cursor position, highlighter, validator, and prompt label.

**Current entry points** (`consoleController.lua:582–611`):

| Function | Evaluator | Prompt | Init text | Cursor | Highlighter | Validator |
|---|---|---|---|---|---|---|
| `user_input()` | none | — | — | — | — | — |
| `input_text(p, i)` | `InputEvalText` | ✓ | ✓ | — | — | — |
| `input_code(p, i)` | `InputEvalLua` | ✓ | ✓ | — | Lua | — |
| `validated_input(f, p)` | `ValidatedTextEval` | ✓ | — | — | — | ✓ |

- **Initial text**: supported via `ui_model:set_text(init)`
  (`consoleController.lua:570`). Sets content; cursor lands at
  end of text (`userInputModel.lua:120`).

- **Initial cursor position**: not supported. No API parameter
  or post-creation call to place the cursor at an arbitrary
  position on setup. `UserInputModel:move_cursor(y, x)` exists
  internally (`userInputModel.lua:506`) but is not exposed.

- **Highlighter**: not a parameter. Highlight is determined by
  the evaluator chosen at call time: `InputEvalLua` implies
  Lua highlighting; `InputEvalText` implies none. No path to
  supply a custom highlighter via the project API.

- **Validator**: supported only via the separate
  `validated_input()` function — a different entry point, not
  a parameter to a unified call. No way to combine a custom
  validator with `input_code`'s Lua highlighter.

- **Prompt label**: supported via the `prompt` argument
  present in all functions except `user_input()`.

**Gap**: the parameter space is fragmented across four entry
points with overlapping but non-composable capabilities. A
single configurable entry point does not exist.

**Reuse**: `UserInputModel`, `UserInputController`,
`UserInputView`, and the evaluator types are all reusable.
The model constructor accepts a `cfg` table and an evaluator;
the wiring is straightforward.

---

## 2. Edit Area Lifecycle (FR-2, FR-3, FR-4)

**FR-2 — Programmatic removal**: not exposed to projects.
On **submit**, `UserInputModel:handle()` evaluates the input;
when successful with `oneshot` set, it pushes a LÖVE2D
`'userinput'` event (`userInputModel.lua:819`), which
`handlers.userinput` in `controller.lua:709–713` handles by
setting `love.state.user_input = nil`. **Cancel**
(`cancel()`) calls `handle(false)` (`userInputModel.lua:795–798`);
in the `eval == false` branch the code sets `ok = true` and does
**not** push `'userinput'` — it only clears content via `reset()`.
The overlay stays visible on Escape; there is no function in the
project environment that triggers removal directly.

**FR-3, FR-4 — Hide / show**: no mechanism exists. The overlay
view is rendered unconditionally whenever `love.state.user_input`
is set; there is no visibility flag on the model or view.
`UserInputModel` has a `visible` field (`userInputModel.lua:21`)
but this refers to the `VisibleContent` scroll/wrap state, not
display visibility.

**Gap**: the entire lifecycle is either user-driven (submit,
cancel) or implicit (singleton guard). No project-callable
path for remove, hide, or show.

**Reuse**: `love.state.user_input` as the on/off signal is a
natural extension point. A visibility flag on `UserInputModel`
and a conditional in `UserInputView:draw` would be the minimal
surface, but the design decision belongs to `design.md`.

---

## 3. Event Notifications (FR-5, FR-6, FR-7)

### FR-5 — Submit notification

**Current**: polling. `UserInputController:keypressed` stores
the submitted value in the reftable via `res(t)`
(`userInputController.lua:353`) when the oneshot evaluator
succeeds. The project calls `r:is_empty()` in `love.update`
to detect completion. This is the canonical pattern across all
current examples.

**Gap**: no callback is invoked on submit. The reftable is
the only result delivery mechanism.

**Reuse**: the oneshot submit path in `UserInputController`
(`userInputController.lua:344–359`) is the right place to
invoke a callback; the evaluator pipeline it calls is reusable.

### FR-6 — Non-character key notification

This is the primary architectural gap. The dispatch chain in
`controller.lua:625–630` routes all `keypressed` events to
`user_input.C:keypressed(k)` when an overlay is active. The
project's own `love.keypressed` handler is unreachable while
an overlay exists:

```
handlers.keypressed
  → if user_input: user_input.C:keypressed(k)   -- return discarded
  → else: love.keypressed(k)                     -- project never reached
```

`UserInputController:keypressed` has no forwarding mechanism.
All keys it handles are consumed; keys it does not explicitly
handle are also silently dropped (the function returns `ret`
which is only set for vertical movement — all other keys
return `nil` with no forwarding). `textinput` has the same
structure (`controller.lua:633–640`): overlay active means
the project's `love.textinput` is never called.

**Gap**: total. No key event reaches project code while an
overlay is active. There is no opt-in or opt-out path.

**Reuse**: `UserInputController:keypressed` already computes
which keys it handles vs. which it ignores. The logical
forwarding point exists; it needs a mechanism to deliver
unhandled events outward.

### FR-7 — Boundary notification

Partial internally. The chain is:

1. `UserInputModel:cursor_vertical_move(dir)` returns a
   boolean `limit` when movement is blocked at a boundary
   (`userInputModel.lua:585`).
2. `UserInputController:keypressed` captures this in `ret`
   via the `vertical()` inner function and returns it
   (`userInputController.lua:252–258`, `388`).
3. `ConsoleController:keypressed` uses this return value for
   history navigation (`consoleController.lua:1000–1007`).
4. For project overlays: `controller.lua:627` calls
   `user_input.C:keypressed(k)` and discards the return value.
   The limit signal never reaches the project.

`UserInputModel:is_at_limit(dir)` is also available as a direct
query (`userInputModel.lua:558–570`) and is used by
`EditorController` via polling (`editorController.lua:511–514`).

**Gap**: the mechanism exists and works within the framework.
It does not reach project code because the overlay dispatch
discards the return value, and projects have no reference to
the model to poll it themselves.

---

## 4. Programmatic Text and Cursor Control (FR-8, FR-9, FR-10)

**FR-10 — Change text**: partially supported.
`write_to_input(content)` (`consoleController.lua:599–605`)
calls `ui_model:set_text(content)` and `ui_con:update_view()`
while the overlay is active. This is the only project-facing
write API for a live overlay. It replaces the full text
content; it does not preserve cursor position or allow partial
updates. It does not allow changing the prompt label or any
other setup parameter.

**FR-8 — Query cursor position**: not exposed to projects.
`UserInputModel:get_cursor_pos()` returns `(line, col)` and
is used throughout the model and controllers internally.
Projects receive only the reftable reference and have no
handle on the model.

**FR-9 — Set cursor position**: not exposed to projects.
`UserInputModel:move_cursor(y, x)` (`userInputModel.lua:506`)
and `set_cursor(c)` (`userInputModel.lua:499`) exist and are
used internally (error highlighting, editor load). Not
reachable from project code.

**Gap for FR-8/FR-9**: the model API is complete; exposure is
the only missing piece. The project currently holds only the
reftable; a handle on the model (or a wrapper over it) is
needed.

---

## 5. API Expressiveness (FR-11, FR-12)

These are consistency targets: the API should be expressive
enough to re-implement the console REPL and the editor's
input handling without accessing internals.

**Console REPL** requires: submit on Enter (FR-5), history
navigation on Up/Down at boundary (FR-7), Ctrl+L clear terminal
(FR-6), error display (already in model). Currently the console
does all this by holding a direct reference to `UserInputModel`
and `UserInputController` — it is not using the project overlay
path. The overlay path is a subset that lacks FR-6 and FR-7
forwarding.

**Editor input** requires: load block text into input (FR-10),
submit block on Enter (FR-5), Escape to load (FR-6), Up/Down
at boundary for block navigation (FR-7), Ctrl+M / Ctrl+F mode
switches (FR-6), cursor position management (FR-8, FR-9). The
editor currently bypasses the project overlay API entirely,
holding direct references to the MVC objects it creates.

**Gap**: FR-6 and FR-7 forwarding are the blockers for both
re-implementability targets. Without them, projects cannot
react to the key events that drive both the console's history
navigation and the editor's mode switches and block navigation.

---

## 6. Non-Functional Requirements

### NFR-1 — Allocation / GC

Every call to `input_text()`, `input_code()`, or
`validated_input()` allocates a new `UserInputModel`,
`UserInputController`, `UserInputView`, `VisibleContent`,
and a `History` dequeue. `user_input()` allocates a new
reftable. For the REPL pattern used in all current examples,
this runs on every Enter press.

The relevant source is `consoleController.lua:563–580`: the
`input()` local function always constructs fresh instances.
There is no reuse path.

**Gap**: the allocation-per-session pattern is structural, not
incidental. Addressing NFR-1 requires a lifecycle redesign,
not a localised fix.

### NFR-2 — Event-driven model

**Gap**: entirely absent. The project API is polling-only.
The reftable / `is_empty()` pattern is the canonical idiom
(present in repl, tixy, guess, turtle, valid, balloons).
No callback registration mechanism exists anywhere in the
project-facing API surface.

### NFR-3 — Compy API consistency

Partial. `compy.text_input` is assigned in
`consoleController.lua:628`, but the other functions
(`input_code`, `validated_input`, `user_input`,
`write_to_input`) are plain globals in the project
environment, not under `compy.*`. The `compy.text_input`
assignment on line 628 references a bare `input_text`
identifier (`compy_namespace.text_input = input_text`) which
has no local or global definition in scope — it assigns `nil`.
`compy.text_input` is documented in `console.md` but has never
functioned; no example or test calls it.

**Gap**: the input API is not consistently namespaced. A new
API placed fully under `compy.*` would resolve this.

### NFR-4 — Pedagogical usability

The polling pattern is not opaque — students following the
game loop understand it — but it requires non-trivial
boilerplate. The canonical idiom across all examples is:

```lua
r = user_input()
function love.update()
  if r:is_empty() then
    input_text("prompt")
  end
end
```

This pattern re-creates the overlay on every frame until the
user submits, which also conflicts with NFR-1. A callback
model should reduce both the boilerplate and the allocation.

---

## 7. Summary

### By component

| Component | Status | Action needed |
|---|---|---|
| `UserInputModel` | Solid — text, cursor, history, evaluator, error all present | Expose cursor query/set to callers; add visibility flag |
| `UserInputController` | Handles all editing operations correctly | Add event forwarding for unhandled keys; expose limit signal |
| `UserInputView` | Renders correctly | Add conditional on visibility flag |
| Project overlay API (`input_text` et al.) | Fragmented, polling-only, allocates per call | Replace entry points; add callback registration; lifecycle redesign |
| `love.state.user_input` dispatch | Routes events correctly to overlay | Overlay keypressed return value is discarded — needs threading through |
| Evaluator types | Reusable as-is | No change needed |
| `write_to_input` | Live text update works | Extend to cover other mutable parameters |

### By requirement

| Req | Current state | Gap size |
|---|---|---|
| FR-1 | Fragmented across 4 functions; cursor pos and custom highlighter absent | Medium |
| FR-2 | Not exposed to projects | Small — needs a project-callable remove path |
| FR-3/FR-4 | No hide/show mechanism | Small — needs visibility flag + show/hide calls |
| FR-5 | Polling only | Medium — reftable delivery replaced by callback |
| FR-6 | Total absence — all keys consumed, no forwarding | Large — cross-cutting, affects dispatch chain |
| FR-7 | Signal exists internally, discarded at overlay dispatch | Small — needs threading through the dispatch |
| FR-8/FR-9 | Model API complete, not exposed | Small — needs a project handle on the model |
| FR-10 | Text content update works; other params not updatable | Small |
| FR-11/FR-12 | Blocked by FR-6 and FR-7 gaps | Follows from those |
| NFR-1 | Structural allocation per session | Large — requires lifecycle redesign |
| NFR-2 | No callback mechanism anywhere | Large — follows from FR-5/FR-6/FR-7 |
| NFR-3 | Partially namespaced | Small — namespace cleanup |
| NFR-4 | Boilerplate-heavy; conflicts with NFR-1 | Follows from NFR-2 |

---

## 8. Constraints and Risks

**Singleton constraint**: only one overlay can exist at a time
(`consoleController.lua:564–566`). FR-3/FR-4 (hide/show) work
within this constraint; the design does not need to lift it.

**Convention adoption scope**: `UserInputController` is shared
across three contexts — console REPL, editor input strip, and
project overlay. Any change to its event handling or return
values affects all three. Changes intended for the project
overlay path must be compatible with or explicitly isolated
from the console and editor paths. See `notes/concerns.md`.

**Editor coordinate ambiguity (FR-7)**: the editor's
`is_at_limit` check operates in wrapped/apparent line
coordinates, not source line coordinates. A general-purpose
boundary callback would need a defined coordinate space. The
console and project overlay contexts do not have this
ambiguity. See `notes/concerns.md`.

**Cancel path**: Escape causes `UserInputModel:cancel()` to
call `handle(false)` (`userInputModel.lua:795–798`), which
clears input content via `reset()` but does **not** push
`'userinput'` — the overlay remains visible. This is exactly
the current limitation that `design.md §5` is built to fix
("Escape clears input content but does not dismiss the
overlay"). In the new model, `framework_handlers['escape']`
in `ProjectController` owns cancel and pushes `'userinput'`
unconditionally, resolving the limitation.

**Text character + modifier co-occurrence**: LÖVE2D delivers
a held-modifier gesture as two separate events — `keypressed`
for the key and `textinput` for any character it produces.
When a modifier is held and a character-producing key is
pressed, both events fire. Under the current overlay dispatch,
both are consumed by `UserInputController`. Under a callback
model, the same gesture could trigger both a text-entered
notification and a key-combo notification, producing a
confusing double callback. Defining the expected behaviour for
this case — suppress one, suppress both, or emit both — is a
decision that needs to be made explicit in design.

This was resolved by `decisions.md` D-6 (superseded in round 1):
both channels fire independently, mirroring raw LÖVE — no
suppression, no classification. There is no double *insertion*
because the keypressed sink ignores plain character keys
(insertion is the textinput sink's job). A project that handles
both channels does so by explicit choice. This paragraph records
the original gap; D-6 carries the settled resolution.

**`write_to_input` scope**: the function closes over
`ui_model` from the enclosing `prepare_project_env` call
(`consoleController.lua:555`). It can reach the model of the
current overlay only because both are in the same closure
scope. A redesigned API that moves away from closure-scoped
state will need to replicate or replace this access path.
