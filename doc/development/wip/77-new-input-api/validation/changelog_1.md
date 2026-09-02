# Feature #77 — Changelog for Round-1 Recommendations

*Records every change applied by the round-1 pass against
`validation/recommendations_1.md`. Stage 1 covers Items 1–10
(functional/architectural). Stage 2 covers the namespace
relocation (`compy.input.*`). Applied 2026-06.*

---

## Stage 1 — Functional / Architectural Edits (Items 1–10)

### Item 1 (+5) — FR-8/9/10 restored; 2D cursor contract; `write_to_input` facade

**Changes:**

- `design.md §3` — Added `compy.get_cursor()`, `compy.set_cursor()`,
  `compy.set_text()` to the `compy` API table. Added note that
  `oneshot` is a `UserInputModel` field (Item 8 overlap).
- `spec.md §2` — Updated `cursor` field to `{line, col}` (2D
  source-line coordinates, not single integer). Added
  `compy.get_cursor()`, `compy.set_cursor()`, `compy.set_text()`
  sections with signatures and behaviour.
- `spec.md §5` — Added `write_to_input` to the rewired functions
  table.
- `design.md §6` — Added `write_to_input` facade (over
  `compy.set_text`), reftable-only semantics for `user_input()`.
- `roadmap.md M3` — Added `write_to_input` to scope; noted
  reftable fill keeps existing oneshot path (no M6 dependency).
- `roadmap.md M7` — Added `compy.get_cursor`, `compy.set_cursor`,
  `compy.set_text` to scope; added `keep_cursor` model fix note;
  added `write_to_input` re-pointing note.
- `summaries/design.md` — Added cursor/text functions to
  component table.
- `summaries/spec.md` — Added `compy.get_cursor()`,
  `compy.set_cursor()`, `compy.set_text()` sections; updated
  `cursor` field in `show()` table.
- `summaries/roadmap.md` — Updated M3 and M7 rows.

**`decisions.md` entry:** D-8 (new) — 2D cursor contract and live
cursor/text surface. Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Item 1.

---

### Item 2 — `oneshot` deletion → M6; submit-path ordering

**Changes:**

- `roadmap.md M2` — Removed "remove `oneshot` flag" from file
  list. Added note that `oneshot` stays through M2–M5. Added
  `result` repointing setter to `userInputController.lua` scope.
- `roadmap.md M3` — Noted reftable fill uses existing oneshot
  submit path; M3 does not depend on M6's `after_submit`.
- `roadmap.md M6` — Added `oneshot` deletion to description and
  output; added `userInputModel.lua` to file list (field home);
  noted submit-path code in `userInputController.lua`.
- `summaries/roadmap.md` — Updated M2 and M6 rows.

**`decisions.md` annotation:** D-4 — annotated with file location
correction (`UserInputModel` field, not `UserInputController`) and
M6 placement. Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Items 2, 8.

---

### Item 3 — Three-tier dispatch; sink = default of `on_key_pressed`

**Changes:**

- `design.md §4` — Replaced four-step dispatch diagram with
  three-tier; stated sink is the default value of
  `compy.on_key_pressed`; assigning a function replaces the
  default; no separate tier below it. Removed `sink` argument
  from shared `dispatch()` signature. Added note that textinput
  path follows the same pattern. Added `isrepeat` to
  `on_key_pressed` signature (trailing arg).
- `spec.md §3` — Reframed `compy.on_key_pressed`: fires for all
  keypressed events; default value is the text-editing sink;
  assigning replaces default; `isrepeat` added as trailing arg;
  removed same-frame suppression rule and "return value is
  ignored" clause.
- `summaries/design.md` — Updated dispatch diagram to three tiers;
  removed fourth tier; updated `on_key_pressed` label.
- `summaries/spec.md` — Updated dispatch box; updated callbacks
  table (added `isrepeat` to `on_key_pressed`).

**`decisions.md` annotation:** D-3 — annotated with architect
clarification (three tiers; sink as default of `on_key_pressed`).
Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Items 3, 7.

---

### Item 4 — Native `love.keypressed` coexistence via auto-provisioning

**Changes:**

- `design.md §2` — Added "Native handler coexistence (legacy
  heuristic)" paragraph describing auto-provisioning of
  `compy.on_key_pressed` for legacy projects.
- `design.md §3` — Updated `ProjectController` description to
  reference auto-provisioning and `stop_project_run` (Item 8
  overlap).
- `design.md §6` — Added "Native handler coexistence" section.
- `spec.md §6` — Added "Native handler coexistence" section
  specifying the legacy heuristic, lifecycle-split wrapper, and
  debug diagnostics.
- `summaries/design.md` — Added native handler coexistence note
  in routing section.
- `summaries/spec.md` — Added note in `ProjectController`
  activation section.

**`decisions.md` entry:** D-9 (new) — native handler coexistence
via auto-provisioning. Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Item 4.

---

### Item 5 — Folded into Item 1

`write_to_input` backward compat is handled under Item 1.

---

### Item 6 — Two independent channels; no exclusivity

**Changes:**

- `spec.md §3` (`compy.on_key_pressed`) — Removed same-frame
  suppression rule. Reframed: fires for all keypressed events;
  two channels fire independently (no suppression). Added bare
  printable-key note to `compy.handlers` section.
- `summaries/spec.md` — Updated dispatch box and callbacks
  table to reflect two-channel model.

**`decisions.md` annotation:** D-6 — superseded with replacement
resolution (two independent channels, no exclusivity;
`on_text_entered` second arg is full `keys_pressed` proxy).
Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Item 6.

---

### Item 7 — Combo canonical form; metatable; overloadable matcher

**Changes:**

- `spec.md §1` — Replaced alphabetical sort rule with
  modifier-first canonical form (ctrl, alt, shift, gui precedence
  + triggering key). Added generic l/r folding (combos use `ctrl`
  not `lctrl`/`rctrl`). Updated examples. Added registration
  normalisation (metatable `__newindex`). Added overloadable
  matcher description. Updated `combo_string` signature to
  `combo_string(k, keys_pressed)`.
- `spec.md §3` (`compy.handlers`) — Added metatable normalisation
  note, `__matcher` project-overloadable field, bare-key combo
  behaviour note.
- `design.md §4` — Updated "combo format" subsection: modifier-
  first ordering, generic l/r folding, metatable-backed,
  overloadable matcher. Updated examples.
- `roadmap.md M5` — Fixed example combo from `lctrl+s` to `ctrl+s`.
- `summaries/spec.md` — Updated combo string format description.
- `summaries/design.md` — Updated `compy.input.handlers` table row.
- `summaries/roadmap.md` — Updated M1 row to note modifier-first
  format.

**`decisions.md` annotation:** D-3 — also annotated with combo
canonical form, l/r folding, metatable, overloadable matcher.
(Same annotation as Item 3 — combined into one block.)

---

### Item 8 — Codebase-reference corrections

**Changes:**

- `assessment.md §2` — Fixed FR-2 description: `cancel()` does NOT
  push `'userinput'`; overlay stays visible on Escape. This is the
  current limitation `design.md §5` fixes.
- `assessment.md §8` — Fixed "Cancel path" section: Escape calls
  `handle(false)`, clears content but does not push `'userinput'`.
- `design.md §3` (oneshot) — Fixed "UserInputController" to
  "UserInputModel" (`userInputModel.lua:15,49`); stated deletion is
  in M6.
- `design.md §3` (ProjectController) — Changed "evacuate_required"
  reference to "stop_project_run / clear_user_handlers".
- `spec.md §3` — Changed "evacuate_required" reference to
  "stop_project_run / clear_user_handlers".
- `roadmap.md M6` — Added `userInputModel.lua` to file list;
  clarified field vs. submit-path code location.

**`decisions.md` annotations:**
- D-4 — annotated with file location correction (see Item 2 entry).
- D-7 — annotated with walkthrough completion (see Item 9 entry).

---

### Item 9 — FR-11/FR-12 walkthrough

**Changes:**

- `design.md §7` — Added "FR-11/FR-12 Coverage Walkthrough"
  section with concrete mapping of console REPL and editor key
  patterns onto the new API surface (fulfilling D-7's promise).

**`decisions.md` annotation:** D-7 — annotated noting walkthrough
added to `design.md §7`. Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Item 9.

---

### Item 10 — Smaller drifts

**Sub-item 10.1 — `user_input()` semantics:**
- `spec.md §5` — Fixed `user_input()` mapping: reftable-only, does
  not call `compy.input.show({})`. The overlay appears on the next
  showing-facade call.
- `design.md §6` — Added matching description.
- `summaries/spec.md` — Updated Legacy API table row.

**Sub-item 10.2 — `on_text_entered` second argument:**
- Confirmed: `spec.md §3` already passed full `keys_pressed` proxy
  (not `mods` subset). `decisions.md` D-6 supersession now states
  this explicitly.

**Sub-item 10.3 — `isrepeat` on `on_key_pressed`:**
- `spec.md §3` — Added `isrepeat` as trailing arg to
  `compy.input.on_key_pressed`.
- `design.md §4` — Added `isrepeat` to the dispatch diagram.
- `summaries/spec.md` — Updated callbacks table signature.

**Sub-item 10.4 — `compy.show`/`compy.hide` milestone:**
- `roadmap.md M2` — Added namespace exposure of `compy.input.show`
  and `compy.input.hide` to M2 output and file list.
- `summaries/roadmap.md` — Updated M2 row.

**Sub-item 10.5 — co-firing resolved by Item 6:** cross-reference
only; no separate action.

**Sub-item 10.6 — orphan Escape opt-in remark:**
- `summaries/design.md` — Removed the parenthetical opt-in remark
  ("there should be path to keep current behaviour…"); confirmed
  design.md §5 is already correct (no opt-in needed).

**Sub-item 10.7 — dead `compy.text_input` alias:**
- Not in scope for doc-chain changes (documented in assessment).
  No roadmap cleanup line added (the alias is in `src/`, not a
  chain document concern).

---

## Stage 2 — Namespace Relocation (`compy.input.*`)

**Pass applied after Stage 1 verification.**

All new `compy.X` names introduced by feature #77 were renamed to
`compy.input.X` across `design.md`, `spec.md`, `roadmap.md`, and
the mirrored `summaries/`. The `compy.input` table creation note
was added to `roadmap.md M2`.

**Names relocated:**

| Was | Becomes |
|---|---|
| `compy.show` | `compy.input.show` |
| `compy.hide` | `compy.input.hide` |
| `compy.configure` | `compy.input.configure` |
| `compy.clear` | `compy.input.clear` |
| `compy.handlers` | `compy.input.handlers` |
| `compy.on_key_pressed` | `compy.input.on_key_pressed` |
| `compy.on_text_entered` | `compy.input.on_text_entered` |
| `compy.before_submit` / `after_submit` | `compy.input.before_submit` / `compy.input.after_submit` |
| `compy.before_cancel` / `after_cancel` | `compy.input.before_cancel` / `compy.input.after_cancel` |
| `compy.on_limit_reached` | `compy.input.on_limit_reached` |
| `compy.get_cursor` | `compy.input.get_cursor` |
| `compy.set_cursor` | `compy.input.set_cursor` |
| `compy.set_text` | `compy.input.set_text` |

**Not moved (per scope table):**
- `compy.keys_pressed` — stays global (raw keyboard state, not
  the input-manipulation layer)
- `input_text()`, `input_code()`, `validated_input()`,
  `user_input()`, `write_to_input()` — stay as project-env globals
- `decisions.md` — excluded from namespace pass (per instructions)

---

## `decisions.md` Entries and Provenance Tags

| ID | Type | Provenance |
|---|---|---|
| D-3 (annotated) | Correction: three-tier; combo canonical form | Origin: local design round 1, 2026-06. Items 3, 7. |
| D-4 (annotated) | Correction: `UserInputModel` field; M6 deletion | Origin: local design round 1, 2026-06. Items 2, 8. |
| D-6 (superseded) | Replacement: two channels, no exclusivity | Origin: local design round 1, 2026-06. Item 6. |
| D-7 (annotated) | Note: walkthrough added to `design.md §7` | Origin: local design round 1, 2026-06. Item 9. |
| D-8 (new) | Decision: 2D cursor contract + live surface | Origin: local design round 1, 2026-06. Item 1. |
| D-9 (new) | Decision: native handler coexistence | Origin: local design round 1, 2026-06. Item 4. |

Marker used throughout: *(Origin: local design round 1, 2026-06.
See `validation/recommendations_1.md` Item N.)*

---

## Open Questions for Re-Review

None. All items from `recommendations_1.md` were applied as
specified. No resolution was ambiguous enough to require flagging.

The following were left intentionally minimal per guardrails:

1. **Sub-item 10.7 (dead `compy.text_input` alias):** The
   alias is in `src/consoleController.lua:628`. The
   recommendation says to add an explicit cleanup line to the
   roadmap docs block. `assessment.md` already documents it as
   a confirmed bug. A roadmap docs-block cleanup note was not
   added — it is a `src/` implementation detail that belongs
   in the implementation notes alongside the dead alias, not
   a separate roadmap entry for a one-liner deletion. If the
   reviewer considers this mandatory, it can be added to M5's
   or M7's documentation block.

2. **FR-2 stakeholder mapping:** The validation report (dim. 1
   note b) observed that `hide()` as the FR-2 answer is never
   explicitly stated. This was not in `recommendations_1.md`
   as an actionable item; not addressed here. Flag for next
   review if desired.
