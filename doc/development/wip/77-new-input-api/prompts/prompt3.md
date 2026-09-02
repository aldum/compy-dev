# Prompt 3 — Actualize decisions, produce design, spec, roadmap, and estimates

Read `CLAUDE.md` first (project overview, collaboration rules, and pointers to
reference material). Then read `agents/rules.md` (coding rules and tone — pay
particular attention to the tone section before writing anything analytical).

## Permissions

Write all output files to disk. You are expected to create and edit files
directly — do not just describe what the documents would contain. Any local
file operation is permitted: read, write, edit, search, grep, sed, and similar
tools. The only prohibited operations are those that modify git history:
no commits, no rebases, no amends, no force operations.

---

## Project context

**Compy** is a console-based, Lua-programmable fantasy computer for children,
built on LÖVE2D v11.5. MVC architecture, Lua 5.1/LuaJIT. The codebase is at
`src/`. Architecture and conventions are documented under `doc/development/`.

This is pre-implementation work for **Feature #77 — New Input API**. All
working documents are under `doc/development/wip/77-new-input-api/`. Read
`doc/development/overview.md` if you need orientation to the overall
architecture. Read `doc/development/internals/` for subsystem detail.

---

## What has been done

The following work is complete and recorded in notes. Read these files before
writing anything. They represent the actual final design — not earlier drafts.

### Primary source material (read first, in order)

1. `input.md` — original feature request from stakeholders
2. `requirements.md` — formalised functional and non-functional requirements
3. `assessment.md` — current architecture assessment and problem framing
4. `decisions.md` — seven blocking decisions and their proposed resolutions

   **Important:** `decisions.md` was written before the routing unification
   insight below. Some passages reference a "proto-design" (overlay-centric,
   overlay gate preserved) that was superseded. The per-decision resolutions
   (D-1 through D-7, quick reference table) are still correct in direction,
   but the architectural framing needs to be updated to reflect the final
   design.

5. `notes/solution_sketch.md` — **the primary design source**. Organised
   description of the full solution in six sections. Read this as the
   authoritative statement of what is being built.

### Supporting notes (read for detail and rationale)

- `notes/routing_unification.md` — the core architectural insight: removal
  of the overlay gate, introduction of `ProjectController`, `UserInputController`
  as universal terminal sink. Contains before/after routing diagrams.
- `notes/love2d_handler_layers.md` — LÖVE2D two-level handler architecture
  and how Compy's routing maps onto it. Contains the corrected routing diagram.
- `notes/event_delegation_chain.md` — current four-context routing chain
  with architectural evaluation.
- `notes/enter_escape_routing.md` — Enter and Escape routing across all
  contexts; includes `oneshot` flag analysis and why it is deleted in the
  new design.
- `notes/textinput_routing.md` — `love.textinput` routing, combo assembly,
  keypressed vs textinput division of labour, event taxonomy.
- `notes/design.md` — earlier ad-hoc design proposals. Treat as background
  context; the solution_sketch supersedes it.
- `notes/decisions.md` — extended rationale behind the decisions. Use for
  understanding context; do not treat as design source.

### Existing summaries (stakeholder-facing, will be updated/created)

- `summaries/requirements.md` — approved
- `summaries/assessment.md` — approved
- `summaries/decisions.md` — exists, needs updating

---

## Tasks

Execute these tasks in order. Each task produces one or more files written to
disk. Do not stop between tasks — complete all five.

---

### Task 1 — Actualize `decisions.md` and `summaries/decisions.md`

Update `decisions.md` (the detailed decisions document) to reflect the final
design as described in `notes/solution_sketch.md` and
`notes/routing_unification.md`.

Specifically:
- Replace any "proto-design" framing (overlay gate preserved, overlay-centric
  routing) with the final design (overlay gate removed, `ProjectController`
  introduced, `UserInputController` as universal sink).
- The seven decisions D-1 through D-7 and their resolutions are correct in
  direction — keep them. Update wording where it assumes the old routing model.
- Confirm that `oneshot` flag deletion is a consequence of D-2 + D-4, and
  note this explicitly.
- The per-decision detail sections lower in `decisions.md` — update any that
  refer to the old routing model. Do not change decisions that are unaffected.

Then update `summaries/decisions.md` to match. The summary is stakeholder-facing:
engineers with limited time. It should be concise, include the D-1 through D-7
quick reference table, and accurately reflect the final design framing without
requiring the reader to understand the routing internals.

---

### Task 2 — Write `design.md` and `summaries/design.md`

Write `design.md` as the primary design document for stakeholder and implementor
review. Source: `notes/solution_sketch.md` as the skeleton, enriched with detail
from the supporting notes listed above.

`design.md` must cover:

1. **Problem and scope** — one paragraph: what the feature adds and what it
   does not touch (console/editor migration is out of scope).

2. **Architectural approach** — the routing unification: removal of the overlay
   gate, introduction of `ProjectController`, `UserInputController` as universal
   terminal sink. Include the before/after routing diagram from
   `notes/routing_unification.md`.

3. **Component layout** — what each new or changed component does:
   - `keys_pressed` table (where it lives, who owns it, how it is passed downstream)
   - `UserInputController` singleton (lifecycle: created once, reconfigured via API)
   - `ProjectController` (new controller, sibling to ConsoleController/EditorController)
   - `compy` API additions (`show`, `hide`, `configure`, `compy.handlers`,
     `compy.on_key_pressed`, `compy.on_text_entered`, before/after chains)

4. **Three-level dispatch** — `framework_handlers → compy.handlers[combo] →
   compy.on_key_pressed → UserInputController sink`. Include the dispatch diagram.
   Note that the dispatch function is shared across all three controller branches
   (written once; only ProjectController uses it initially).

5. **Enter and Escape handling** — framework_handlers entries, before/after chains,
   resolution of the current Escape-does-not-dismiss limitation.

6. **Legacy API compatibility** — facade wrappers, reftable preserved, deprecation
   path.

7. **Implementation order and migration path** — confirm and state explicitly that
   the six-section order in `notes/solution_sketch.md` is implementation-dependency
   aware: each step can be tested before the next begins, and the console/editor
   migration is a clean follow-on, not a prerequisite. Validate this claim — check
   that no later step requires a later step to be partially complete.

Write `summaries/design.md` as a condensed version suitable for a stakeholder who
will spend 10–15 minutes reviewing. Include the before/after routing diagram (it is
self-explanatory) and the component table. Omit the implementation order section
(that is roadmap territory).

---

### Task 3 — Write `spec.md` and `summaries/spec.md`

Write `spec.md` as the specification document — the contract that implementation
is verified against. Stakeholders are engineers; include function names, signatures,
and data structure formats. Be precise.

`spec.md` must cover:

1. **`keys_pressed` table**
   - Format of the table (key names as strings, values as `true`)
   - How it is passed downstream (iterator or read-only proxy — specify which
     and why)
   - Combo serialisation format (e.g. `"lctrl+s"` — specify key ordering
     convention: modifiers first, main key last, alphabetical among modifiers)

2. **`UserInputController` singleton API** (the `compy` namespace surface)
   - `compy.show(config)` — what `config` accepts (prompt, validator, highlighter,
     multiline flag, etc.)
   - `compy.hide()` — behavior (does it clear content? fire cancel chain?)
   - `compy.configure(config)` — mid-session reconfiguration (which fields are
     live-updatable)
   - `compy.clear()` — clears input content without hiding
   - Access control: what happens if `show()` is called while already active

3. **Event callbacks**
   - `compy.on_text_entered(text, keys_pressed)` — when it fires, what `text`
     contains (from textinput path), what `keys_pressed` contains
   - `compy.on_key_pressed(k, keys_pressed)` — when it fires (non-character
     structural keys; NOT called for plain character keys where textinput fires)
   - `compy.handlers[combo]` — registration format, combo string format,
     return-value bubbling convention (truthy = consumed, sink does not run)
   - `before_submit(keys_pressed)`, `after_submit(result)` — signatures,
     ordering guarantees
   - `before_cancel(keys_pressed)`, `after_cancel()` — signatures, whether
     `before_cancel` can suppress the cancel

4. **`on_limit_reached(direction)`** — when it fires, what `direction` values
   are defined, second argument reserved note

5. **Legacy API compatibility**
   - Which functions are rewired as facades: `input_text()`, `input_code()`,
     `validated_input()`, `user_input()`
   - What they do internally (configure + show singleton, register reftable-fill
     submit callback)
   - Deprecation warning: when emitted, how suppressed
   - `love.state.user_input`: still set/cleared; points to singleton; nil when hidden

6. **`ProjectController`**
   - Activation: when it becomes the active controller (project running,
     app_state = `running` or `project_open`)
   - Deactivation: on project stop
   - Relationship to `love.keypressed` slot (does it replace the slot, or is
     it called from it?)

7. **Edge cases**
   - Project calls `show()` while already active: specify behavior
   - Project stops while input is active: specify what happens
     (silent hide, cancel chain, or error)
   - Evaluation failure (validator returns error): input locks until acknowledged
     (existing behavior preserved)

Write `summaries/spec.md` as a condensed version. Include all function signatures
and the callback table. Omit the edge case section (that is implementor-level
detail). Keep descriptions to one sentence per item. Stakeholders can read this
in 5 minutes and confirm the API surface is correct.

---

### Task 4 — Write `roadmap.md` and `summaries/roadmap.md`

Write `roadmap.md` as the implementation roadmap. It is scoped to this feature only.

Structure as milestones, in implementation-dependency order (matching the order
in `notes/solution_sketch.md`). For each milestone:
- Name and one-line description
- Input (what must be done before this milestone starts)
- Output (what is verified/testable at the end)
- Files created or modified (list by path)
- Risk or note (one line, if any)

Milestones:
1. `keys_pressed` table — framework-level, zero behaviour change
2. `UserInputController` singleton extraction — move construction to startup,
   zero behaviour change (verifiable by running existing tests)
3. Legacy API facade wrappers — rewire `input_text()` etc., verify all existing
   examples still work
4. `ProjectController` introduction + overlay gate removal — new controller,
   routing change, existing behaviour preserved via sink
5. Three-level dispatch in `ProjectController` — `compy.handlers`,
   `compy.on_key_pressed`, return-value bubbling
6. Before/after chains for submit and cancel — D-4, resolves Escape limitation
7. Extended singleton API — `compy.configure()`, `compy.clear()`, live
   reconfiguration of validator/highlighter

Include two separate scope items (not milestones, but effort blocks listed after
the milestones):
- **Documentation updates**: update `doc/development/internals/` for the new
  input subsystem; update `doc/development/overview.md` if architecture section
  is affected; deprecate/archive stale wip notes after release.
- **Test coverage**: busted tests for `keys_pressed` table, singleton lifecycle,
  dispatch chain (each level), legacy API compatibility, edge cases from spec §7.

Write `summaries/roadmap.md` as a one-page milestone table: name, output/
deliverable, key files touched. Omit risk notes and file lists.

---

### Task 5 — Implementation estimates

Add an `## Estimates` section to the bottom of `roadmap.md`.

Assume implementor: senior engineer, solo, full ownership of the codebase.
Familiar with Lua and LÖVE2D. Comfortable with the architecture (has read the
design and spec documents).

Provide two estimates:
- **Without LLM assistance** — traditional implementation
- **With LLM assistance** (Claude Code or equivalent for code generation,
  refactoring, test scaffolding, and doc updates)

For each milestone and effort block, give a range (optimistic–realistic) in
hours or days. Sum to a total range per estimate set.

If confident, apply a three-point PERT to the totals:
  `E = (O + 4M + P) / 6`
where O = optimistic total, M = most likely total, P = pessimistic total.
State the PERT estimate explicitly as a single number and note its confidence
basis.

Note any milestones where LLM assistance is unlikely to save significant time
(e.g. milestones that are mostly integration/wiring rather than generative work).
