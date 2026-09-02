# Feature #77 — Implementation Roadmap

*Scoped to this feature only. Milestones in
implementation-dependency order, matching the section
order in `notes/solution_sketch.md`. Estimates are in
the `## Estimates` section at the bottom.*

> **Status — derived proposal document.** This roadmap is a derived
> part of the feature-#77 proposal chain, pre-built on the
> assumption the design is endorsed rather than vetoed. Milestone
> boundaries and estimates are provisional: stakeholders may review
> or adjust parts without blocking implementation — there is no
> requirement to freeze the plan before work starts.

---

## Milestones

---

### M1 — `keys_pressed` table

**Description:** Framework-level live set of currently-held
key names. Zero behaviour change.

**Input:** Nothing. This milestone has no dependencies and
can begin immediately.

**Output:** `Controller.keys_pressed` is maintained
correctly. Combo serialisation helper (`combo_string`)
exists and is tested. All existing tests continue to pass.
No behavioural change observable in any app mode.

**Files created or modified:**
- `src/controller.lua` — add `keys_pressed` table
  maintenance in `love.handlers.keypressed` and
  `love.handlers.keyreleased`; add `combo_string` helper

**Risk:** None. Purely additive; existing handlers are
unchanged.

---

### M2 — `UserInputController` singleton extraction

**Description:** Move widget construction from inside
`ConsoleController` to framework startup. Widget created
once, never destroyed. Zero behaviour change.

**Input:** M1 complete (keys_pressed table exists).

**Output:** `UserInputController` is instantiated once at
startup (lazily). The widget is no longer created on each
input call. `compy.input.show()` and `compy.input.hide()` are
available on the namespace (required before later milestones
use them). Existing examples still work at this point (the
legacy globals are untouched until M8); allocation-per-session
is gone. Existing tests pass. The `oneshot` flag is **not**
removed in this milestone — it continues to drive submit
through M2–M5.

**Files created or modified:**
- `src/main.lua` — create singleton instance at startup
- `src/consoleController.lua` — remove per-call
  construction; wire to singleton
- `src/userInputController.lua` — `show()`/`hide()` state
  change methods added
- `src/compy_namespace.lua` (or equivalent) — create the
  `compy.input` table once at namespace setup; mount
  `compy.input.show` and `compy.input.hide` on it

**Risk:** Care needed to preserve `love.state.user_input`
set/clear behaviour. Existing tests exercise this path;
run all before and after.

---

### M3 — *(removed — superseded by stakeholder feedback round 1)*

The original M3 built backward-compatible facade wrappers for
the legacy text-input functions. **D-1 was discarded by
stakeholders** (`input.md`, feedback round 1, 2026-06-06): no
backward compatibility is maintained, so no facades are built.
The legacy text-input globals are instead **removed**, and the
examples are migrated to the new API — see **M8** (the work
moves to the end of the plan because migrating the examples
needs the full `compy.input.*` surface).

The milestone numbering M4–M7 is kept unchanged to preserve the
many cross-references to those numbers elsewhere in the chain;
this slot is intentionally empty.

---

### M4 — `ProjectController` introduction and overlay gate removal

**Description:** New controller for the project-running
context. The `if user_input then` gate in `controller.lua`
is removed. Routing becomes symmetric.

**Input:** M2 complete (singleton stable). The removed M3 was
never a functional dependency of this milestone.

**Output:** `ProjectController:keypressed` and
`:textinput` occupy `love.keypressed` and `love.textinput`
when a project runs. Overlay input works as before (via
the sink). Project key events are no longer silently dropped
while the singleton is active. Existing tests pass.

**Files created or modified:**
- `src/projectController.lua` — new file; implements
  `ProjectController` class with `keypressed`, `textinput`,
  `keyreleased` methods; basic sink delegation only (M5
  adds the full dispatch)
- `src/controller.lua` — remove overlay gate; wire
  ProjectController into `set_handlers()` / `love.keypressed`
  slot for project-running states

**Risk:** Largest integration step. The overlay gate
removal touches the main dispatch path. Run full test suite
and manually verify all four app modes (REPL, editor,
project with overlay, project without overlay) before
marking complete.

---

### M5 — Three-level dispatch in `ProjectController`

**Description:** `compy.input.handlers`, `compy.input.on_key_pressed`,
and return-value bubbling implemented in
`ProjectController:keypressed`.

**Input:** M4 complete (ProjectController exists; sink
delegation works).

**Output:** `compy.input.handlers['ctrl+s'] = fn` works.
`compy.input.on_key_pressed` fires for unregistered keys.
Returning truthy from a handler prevents the sink from
running. The shared `dispatch()` function is written and
used by ProjectController.

**Files created or modified:**
- `src/projectController.lua` — add three-level dispatch;
  add `dispatch()` function (shared; ConsoleController and
  EditorController will migrate to it later)
- `src/compy_namespace.lua` (or equivalent) — expose
  `compy.input.handlers` table; expose `compy.input.on_key_pressed`
  and `compy.input.on_text_entered` callback slots

**Risk:** Combo serialisation must match registration format
exactly. Test with multi-modifier combos and with a handler
that returns truthy to verify chain stops.

---

### M6 — Before/after chains for submit and cancel

**Description:** `before_submit`, `after_submit`,
`before_cancel`, `after_cancel` hooks. Escape dismisses
the overlay (current limitation resolved). `on_limit_reached`
fires. `framework_handlers['return']` takes ownership of
submit. **`oneshot` flag deleted** (both its jobs are now
covered — activation by `show()`/`hide()` from M2, submit by
`framework_handlers['return']` here).

**Input:** M4 complete (M5 is independent of M6).

**Output:** All six named hooks fire at correct points.
Escape dismisses the overlay and fires `before_cancel` /
`after_cancel`. Submit fires `before_submit` / `after_submit`
with correct arguments. `on_limit_reached('up'/'down')`
fires when cursor hits boundary. The `oneshot` flag is gone.

**Files created or modified:**
- `src/projectController.lua` — add `framework_handlers`
  table; add `'return'` and `'escape'` entries with
  before/after chain logic
- `src/userInputController.lua` — expose limit signal to
  caller; remove submit-path code that reads `model.oneshot`
- `src/userInputModel.lua` — remove `oneshot` field
  (lines ~15, ~49); this is the field's home (the submit-path
  code that reads it is in `userInputController.lua`)

**Risk:** Escape dismiss: ensure `push('userinput')` fires
in the cancel path (it currently fires only on successful
submit with `oneshot`).

---

### M7 — Extended singleton API

**Description:** `compy.input.configure()`, `compy.input.clear()`,
`compy.input.get_cursor()`, `compy.input.set_cursor()`, and
`compy.input.set_text()` implemented. Live reconfiguration of
validator and highlighter works. Cursor and text can be
programmatically read and written while active (FR-8/9/10).

**Input:** M2 complete. M5/M6 are not required (this is an
API surface extension, not a dispatch change).

**Output:** `compy.input.configure({prompt='new prompt'})` updates
the displayed prompt without tearing down the session.
`compy.input.clear()` resets content and cursor. `compy.input.get_cursor()`
returns `line, col`; `compy.input.set_cursor(line, col)` moves the
cursor. `compy.input.set_text(text [, keep_cursor])` replaces live
content. All work while the singleton is active and when hidden.
`compy.input.set_text` is the live-write surface that replaces the
removed `write_to_input` (see M8).

**Files created or modified:**
- `src/userInputController.lua` — add `configure()`,
  `clear()`, `get_cursor()`, `set_cursor()`, `set_text()`
  methods; fix `UserInputModel:set_text` to honour
  `keep_cursor` (skip unconditional `jump_end()`)
- `src/compy_namespace.lua` — expose `compy.input.configure`,
  `compy.input.clear`, `compy.input.get_cursor`, `compy.input.set_cursor`,
  `compy.input.set_text`

**Risk:** None. Additive; no routing changes.

---

### M8 — Legacy text-input removal and example migration

**Description:** Remove the legacy text-input globals and migrate
the in-repo examples that use them to the `compy.input.*` callback
API. D-1 discarded — no backward compatibility (`input.md`,
feedback round 1).

**Input:** M6 and M7 complete. This milestone needs the **full**
`compy.input.*` surface — `show()` with `validator`/`highlighter`
config (M2 + M7), the submit/cancel callbacks (M6), and
`set_text`/cursor (M7) — because migrating the examples depends
on all of it. It is therefore the last milestone.

**Output:**
- `input_text()`, `input_code()`, `validated_input()`,
  `user_input()`, and `write_to_input()` are removed from the
  project environment. `love.state.user_input` is driven solely
  by `compy.input.show()`/`hide()`.
- **Priority examples migrated (release-blocking):** `tixy`
  (uses `input_code` + `write_to_input` + `user_input`) and
  `balloons` (uses `input_text` + `user_input`). `maze` is named
  by stakeholders as a showcase but is not in this repo; it is
  migrated on arrival (out of current repo scope).
- **Convert-or-exclude (owner's release call, per `input.md`):**
  `repl`, `guess`, `valid` (trivial REPL conversions) and
  `turtle` (its `input_text` use migrates; its native
  `love.keypressed` movement keeps working under D-9). Any not
  converted in time are excluded from the next release rather
  than blocking it.
- **Unaffected:** examples that use only native
  `love.keypressed`/`love.textinput` (`pong`, `life`, `paint`,
  `sapper`, `sine`, `clock`, `drawdebug`) — D-9 coexistence
  applies; "only text fields" break.

**Files created or modified:**
- `src/consoleController.lua` — remove the five legacy entry
  points (`user_input`, `input_text`, `input_code`,
  `validated_input`, `write_to_input`)
- `src/examples/tixy/`, `src/examples/balloons/` — migrate to
  `compy.input.*` (priority); `src/examples/{repl,guess,valid,turtle}/`
  — migrate or mark excluded

**Risk:** The examples are the only consumers, so the blast
radius is contained. There is a window (M3-slot onward) where
the text-input examples do not run on the in-development build;
this is internal and acceptable (the work is unreleased and old
releases remain available — `input.md`). The reftable / polling
idiom disappears from the example corpus.

---

## Additional Scope

### Documentation updates

- Update `doc/development/internals/` input subsystem docs
  to reflect the new singleton lifecycle, routing model, and
  API surface.
- Update `doc/development/overview.md` architecture section
  if the controller listing or app_state machine description
  needs to account for `ProjectController`.
- Archive or annotate stale wip notes after release
  (primarily `notes/design.md`, `notes/plan.md`).

### Test coverage

Busted tests for:
- `keys_pressed` table: key add/remove, combo serialisation,
  multi-modifier ordering
- Singleton lifecycle: show/hide state, configure fields,
  clear, show-while-active reconfiguration
- Dispatch chain (each level): handler registration,
  return-value bubbling, default callback fires when no
  handler matches
- Example migration (M8): the priority examples (`tixy`,
  `balloons`) run on the `compy.input.*` callback API; the legacy
  globals are gone (calling `input_text` etc. is now a `nil`
  call); native-handler examples still work via D-9
- Edge cases from `spec.md §7`: stop-while-active, show
  while active, evaluation failure locking behaviour

---

## Estimates

*Implementor assumed: senior engineer, solo. Familiar with Lua
and LÖVE2D. Has read the design and spec documents. Three-point
estimates per line; PERT = (O + 4M + P) / 6, where O = optimistic,
M = most-likely, P = pessimistic. Hours.*

### Without LLM assistance

| Item | O | M | P | PERT |
|---|---|---|---|---|
| M1 `keys_pressed` table | 2 | 3 | 4 | 3.0 |
| M2 Singleton extraction | 3 | 6 | 9 | 6.0 |
| M4 ProjectController + gate removal | 4 | 8 | 14 | 8.3 |
| M5 Three-level dispatch | 3 | 5 | 8 | 5.2 |
| M6 Before/after chains (+ `oneshot` deletion) | 4 | 7 | 11 | 7.2 |
| M7 Extended API (+ cursor surface, model fix) | 3 | 6 | 9 | 6.0 |
| M8 Legacy removal + example migration | 4 | 8 | 14 | 8.3 |
| Documentation updates | 4 | 8 | 12 | 8.0 |
| Test coverage | 7 | 11 | 16 | 11.2 |
| **Total** | **34** | **62** | **97** | **≈ 63 h** |

Project PERT (O=34, M=62, P=97): `(34 + 4×62 + 97) / 6 ≈ 63 h`.

Note: discarding backward compatibility (D-1) *raised* the
estimate. The old M3 facade layer (≈ 4 h) is gone, but M8 —
removing the legacy globals and migrating the examples — is
larger (≈ 8 h), because rewriting the example corpus is more
work than wrapping the old calls. The net is +≈ 4 h vs. the
facade plan.

Confidence: moderate. M4 (gate removal, central dispatch path)
remains the widest pessimistic tail; M8 is the next-widest, as
the per-example migration effort and the convert-or-exclude
release decision both vary with the owner's call.

### With LLM assistance

LLM helps most with boilerplate wiring (M1, M7), example
rewriting (M8), new-file scaffolding (M5), test scaffolding, and
doc updates. It saves
least on M2 (cross-component refactor verified by hand), M4
(integration; the engineer must trace the dispatch paths), and M6
(ordering semantics).

| Item | O | M | P | PERT | LLM value |
|---|---|---|---|---|---|
| M1 `keys_pressed` table | 1 | 2 | 3 | 2.0 | High |
| M2 Singleton extraction | 2 | 4 | 6 | 4.0 | Low |
| M4 ProjectController + gate removal | 3 | 5 | 9 | 5.3 | Medium |
| M5 Three-level dispatch | 2 | 3 | 5 | 3.2 | High |
| M6 Before/after chains (+ `oneshot` deletion) | 2 | 5 | 8 | 5.0 | Low–medium |
| M7 Extended API (+ cursor surface, model fix) | 2 | 4 | 6 | 4.0 | High |
| M8 Legacy removal + example migration | 2 | 4 | 8 | 4.3 | High |
| Documentation updates | 2 | 3 | 5 | 3.2 | High |
| Test coverage | 4 | 6 | 9 | 6.2 | High |
| **Total** | **20** | **36** | **59** | **≈ 37 h** |

Project PERT (O=20, M=36, P=59): `(20 + 4×36 + 59) / 6 ≈ 37 h`.

Confidence: moderate. The saving is largest for well-specified
generative work (M1, M5, M7, M8, tests, docs) — rewriting the
small example files to the new API is exactly the kind of
mechanical edit an LLM does well, so M8's LLM value is High. The
integration milestones (M2, M4) are serial and verification-heavy,
so LLM code generation speeds them up but the manual verification
cost is largely fixed.
