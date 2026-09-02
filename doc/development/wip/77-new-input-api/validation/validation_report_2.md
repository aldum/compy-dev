# Validation Report 2 — Feature #77 Document Chain (post-rewrite)

*Second independent review of the feature #77 chain, run against the
rewritten documents and the intended delta in
`validation/recommendations_1.md` (with `validation/changelog_1.md` as the
rewrite's self-report). Codebase claims were re-checked against `src/`.
Reviewer role only — findings, not rewrites. Authority model applied:
`input.md` is the only stakeholder-signed tier; `requirements.md` is high
local input; `decisions.md` (D-1…D-9) and the recommendations are one local
proposal; `design.md`/`spec.md`/`roadmap.md`/`summaries/` are derived.*

---

## Status: PASS WITH NOTES

The three round-1 blockers are resolved and the resolutions are faithfully
applied across the documents the recommendations named:

- **FR-8/9/10** are restored end to end (D-8, `design.md §3`, `spec.md §2`,
  `roadmap.md M7`, summaries), on a single 2D source-line coordinate space;
  `write_to_input` is back in the facade set.
- **The M2/M6 submit-path ordering** is corrected — `oneshot` now stays
  through M2–M5 and is deleted in M6, against the right file targets.
- **The `on_key_pressed` return-value contradiction** is dissolved by the
  three-tier model (sink = default of `on_key_pressed`).

Native-handler coexistence (D-9), the two-channel model (D-6 superseded), the
combo canonical form (D-3), the codebase-reference fixes (Item 8), and the
FR-11/FR-12 walkthrough (Item 9) all landed. The namespace relocation to
`compy.input.*` is clean in the derived docs.

No remaining issue drops a functional requirement, breaks a must-pass
example, or hands the implementor a contradictory *design*. What remains is
consistency residue and provenance/packaging gaps. One of them
(the `noop+log` vs `sink` default, **N1**) directly contradicts the headline
Item 3 resolution in three places and is worth a wording fix before
implementation; the rest are notes. None require a full re-validation round —
a short local cleanup pass closes them.

---

## Part A — Rewrite faithfulness (per recommendation item)

| Item | Verdict | Location / note |
|---|---|---|
| 1 — FR-8/9/10 + `write_to_input` | **APPLIED** | see below |
| 2 — `oneshot` M2→M6 | **APPLIED** | see below |
| 3 — three-tier collapse | **APPLIED (residue)** | see N1 |
| 4 — native coexistence | **APPLIED** | see below |
| 5 — `write_to_input` | **APPLIED** | folded into Item 1 |
| 6 — two channels | **APPLIED (one stale source)** | see below |
| 7 — combo canonical form | **APPLIED** | see below |
| 8 — codebase corrections | **APPLIED** | see below |
| 9 — FR-11/12 walkthrough | **APPLIED** | `design.md §7` |
| 10 — smaller drifts | **APPLIED (10.7 deviation)** | see below |
| Namespace relocation | **APPLIED (in-scope docs); two gaps** | see below |

**Item 1 — APPLIED.** `design.md §3` component table carries
`compy.input.get_cursor/set_cursor/set_text` (lines 172–174); `spec.md §2`
has the `{line, col}` `cursor` field (line 97) and full `get_cursor` /
`set_cursor` / `set_text` sections (138–162); `spec.md §5` and `design.md §6`
add `write_to_input` as a facade over `set_text` with reftable-only
`user_input()`; `roadmap.md M3` wires `write_to_input`, `M7` adds the cursor
surface plus the `keep_cursor` model fix. The 2D source-line contract is
stated uniformly, and the `set_text`/`jump_end` model wrinkle is correctly
identified (verified: `userInputModel.lua:145` calls `jump_end()`
unconditionally, after the `keep_cursor` guards at `:135,:142` — so the fix is
real and correctly scoped to M7). No over-application: no extra cursor
config beyond what FR-8/9/10 require.

**Item 2 — APPLIED.** `roadmap.md M2` drops the `oneshot` removal and states
it "continues to drive submit through M2–M5" (lines 51–53), adds the `result`
repointing setter (60–62); `M3` notes the reftable fill uses the existing
oneshot path and does not depend on `after_submit` (84–86); `M6` carries the
deletion with `userInputModel.lua` as the field home and
`userInputController.lua` as the submit-path reader (179–187). `decisions.md`
D-4 annotation matches (288–299). File targets correct against code
(`userInputModel.lua:15,49`).

**Item 3 — APPLIED, with a reintroduced default-value contradiction (N1).**
The three-tier model is in `design.md §4` (sink as default of
`on_key_pressed`, `sink` argument dropped from `dispatch()` at lines 218–221),
`spec.md §3` (default = sink; "return value is ignored" and the same-frame
suppression both removed), and both summaries. The collapse itself is faithful
and no fourth tier reappears in the dispatch sections. **But three places still
describe the pre-Item-3 `noop+log` default for the generic callback** — see N1.

**Item 4 — APPLIED.** Auto-provisioning, the legacy heuristic gate
(native handler set AND no `compy.*` surface), the visibility lifecycle-split
wrapper, and the debug diagnostics are in `design.md §2` (83–94) and `§6`
(315–324), `spec.md §6` (415–433), and D-9. The routing precondition is
factually sound (`controller.lua:75` `hook_if_differs`, `:779`
`save_user_handlers`). No over-application: the mechanism is fixed and the only
variable (wrapper body) is the visibility split, as recommended.

**Item 6 — APPLIED; one stale source doc.** `spec.md §3` removes suppression,
states the two independent channels, and adds the bare-printable-key note
(267–271); D-6 is superseded (351–371). **Residue:** `assessment.md §8`
(lines 352–362) still presents the modifier+character co-occurrence as an open
choice — "suppress one, suppress both, or emit both — is a decision that needs
to be made explicit in design." D-6's supersession made that decision (emit
both, no exclusivity); the assessment paragraph was not re-pointed at the
resolution. Low severity (assessment is a derived/input doc and this fed D-6),
but it now reads as an unresolved question that is in fact resolved. See also
architect note 5 below.

**Item 7 — APPLIED.** `spec.md §1` has the modifier-first precedence
(`ctrl, alt, shift, gui`) + triggering key, generic l/r folding, the
metatable `__newindex` normalisation, and the overloadable matcher; examples
are corrected to `"ctrl+s"`, `"alt+shift+f4"`, `"escape"` (62–67).
`design.md §4` and `roadmap.md M5` (`"ctrl+s"`, line 139) match. No stale
alphabetical/`lctrl+`-style example survives in the derived docs.
(`decisions.md:224` still shows `"lctrl+s"` in the **original** D-3 suggested
text — corrected by the appended annotation; see the decisions-body note
below. `summaries/spec.md:20` uses `lctrl+s` only as a negative example —
"`ctrl+s` not `lctrl+s`" — which is correct.)

**Item 8 — APPLIED.** `assessment.md §2` and `§8` now state `cancel()` does
not push `'userinput'` and the overlay stays on Escape (verified:
`userInputModel.lua:795–798` cancel → `handle(false)`; the `'userinput'` push
at `:812–819` is gated by `eval` + `oneshot` and is unreachable on cancel).
`oneshot` is relabelled a `UserInputModel` field in D-4 and `design.md §3`.
Every `evacuate_required` reference in the chain is gone — `stop_project_run` /
`clear_user_handlers` is used in `design.md §3`, `spec.md §3`, D-7
(`consoleController.lua:860,867` confirmed). No `evacuate_required` remains in
any chain document.

**Item 9 — APPLIED.** `design.md §7` carries the console-REPL and editor
walkthrough tables (366–387); D-7 is annotated to point there.

**Item 10 — APPLIED (10.7 deviation).** 10.1 `user_input()` reftable-only
(`spec.md §5`, `design.md §6`, summary); 10.2 full `keys_pressed` proxy as the
`on_text_entered` second arg; 10.3 `isrepeat` trailing on
`on_key_pressed`; 10.4 `compy.input.show`/`hide` exposed in M2; 10.6 the orphan
Escape opt-in remark is removed from `summaries/design.md` (confirmed gone).
**10.7 deviation:** the dead `compy.text_input` cleanup line was not added to a
roadmap docs block; `changelog_1.md` open-question 1 acknowledges this as a
deliberate scope call (a `src/` one-liner, not a chain-doc concern). Acceptable;
trivial.

**Namespace relocation — APPLIED for the in-scope docs, with two gaps.**
`design.md`, `spec.md`, `roadmap.md`, and `summaries/{design,spec,roadmap}.md`
carry no flat-`compy.X` feature-#77 straggler (grep-clean); legacy globals
(`input_text`, `input_code`, `validated_input`, `user_input`,
`write_to_input`) are not moved; `compy.keys_pressed` stays global. Two gaps:

1. **`decisions.md` was excluded from the pass** (per `changelog_1.md`), so it
   still uses flat `compy.on_key_pressed` / `compy.handlers` / `compy.get_cursor`
   etc. throughout, **except** `decisions.md:398`, which leaked a single
   `compy.input.handlers`. So `decisions.md` is internally inconsistent (one
   relocated name amid otherwise-flat names) and chain-inconsistent with the
   derived docs (which a stakeholder reads side by side). `summaries/decisions.md`
   mirrors the flat form (lines 87–91, 163). Defensible under the literal scope
   table, but it leaves the document the stakeholder actually reviews using the
   old names. Low severity; see also the Part B namespace-decision gap, which is
   the more substantive half of this.
2. The relocation is otherwise clean.

---

## Part B — Provenance integrity

- **Top-of-file status note: present.** `decisions.md:3–7` and
  `summaries/decisions.md:7–9` both state the whole file (D-1…D-9) is a local
  proposal derived from `input.md`, pending a single eventual approve/veto
  review, nothing stakeholder-signed. Correct and matches the authority model.
- **Round-1 provenance marker: present and greppable.** Six occurrences of
  `*(Origin: local design round 1, 2026-06. See …Item N.)*` (D-3, D-4, D-6,
  D-7, D-8, D-9). The delta since the prior round is auditable.
- **New architectural commitments surfaced as decisions — mostly, with one
  omission.** D-8 (cursor contract + live surface) and D-9 (native coexistence)
  are first-class new decisions; Item 3 (three-tier), Item 6 (two-channel), and
  Item 7 (combo form) are carried as D-3/D-6 annotations. **The
  `compy.input.*` sub-namespace is not surfaced as a decision anywhere in
  `decisions.md`** (grep: no `namespace` / `compy.input` decision text). It is a
  genuine architectural commitment — a new sub-namespace layout chosen by the
  architect, with a stated rationale (isolate the input surface; keep
  `compy.keys_pressed` global) — yet a stakeholder reading only `decisions.md`
  would not see it, and would see the old flat names. This is the inverse of the
  round-1 failure mode (a real choice living *only* in derived docs). Recommend
  promoting it to a decision (e.g. D-10) so the eventual review covers it. This
  is the most substantive provenance finding.
- **`requirements.md` still traces `input.md`: yes.** The file is unchanged
  this round and no downstream edit contradicts it; the FR-8/9/10 restoration
  re-closes the only place the chain had drifted from it. Minor carry-over
  (not introduced this round): FR-2's "remove/teardown" is still answered by
  `hide()` without that mapping being stated as the FR-2 answer
  (`changelog_1.md` open-question 2). Trivial.

---

## Part C — Seven dimensions

### 1. Requirements coverage

All twelve FRs trace through decisions → design → spec → roadmap. FR-8/9/10 —
the round-1 headline gap — are now carried: D-8 → `design.md §3` →
`spec.md §2` (`get_cursor`/`set_cursor`/`set_text`) → `roadmap.md M7`. FR-9 is
no longer contradicted: `configure()` keeps its text/cursor immutability, and
`set_cursor`/`set_text` are declared the explicit live-write exceptions
(`spec.md §2`, lines 129–130, 152–162). FR-5/6/7, FR-11/12, NFR-1…4 remain
covered. No requirement drops out.

### 2. Decision consistency

D-1…D-9 are reflected consistently in design/spec, with one reintroduced
contradiction:

- **N1 — `on_key_pressed`/`on_text_entered` default: `noop+log` vs `sink`.**
  Item 3/Item 6 make the *sink* the default of both channel callbacks. The
  per-callback spec sections say so (`spec.md §3`, lines 222–228 and 188–191).
  But three places still carry the old `noop+log` default:
  - `design.md §2` routing diagram, line 75:
    `compy.input.on_key_pressed [generic, overloadable, default: noop+log]`;
  - `spec.md §3` intro, line 175: "Default value for each is a no-op function
    that emits a debug log entry";
  - `summaries/spec.md`, line 98: "All callbacks default to a no-op + debug
    log entry."

  Taken literally these contradict the sink-as-default model and would have the
  implementor wire `on_key_pressed` to a no-op — under which the default text
  editing (the sink) never runs and typing into a prompt does nothing. The
  `noop+log` default is correct for the *other* callbacks
  (`before/after_submit`, `before/after_cancel`, `on_limit_reached`); the
  blanket statements over-generalise it to the two channel callbacks, whose
  default is the sink. Fix: scope the `noop+log` statement to the non-channel
  callbacks; correct line 75 and the two blanket lines to "default = sink" for
  the channel callbacks. Medium severity (contract-level, but a localised
  wording fix in three spots, not a design gap). This is the only Part A/C
  finding I would treat as more than a note.

- Minor: `design.md §3` component table calls `compy.input.on_key_pressed`
  a "Generic non-character key callback" (line 165). Under Item 6 it fires for
  *all* keypressed events (character and non-character); `spec.md §3` says so
  correctly (line 206). The design table description is stale framing from the
  pre-two-channel model. Low.

### 3. Design-to-spec completeness

Every design component has a spec contract: `show`/`hide`/`configure`/`clear`,
`get_cursor`/`set_cursor`/`set_text`, `handlers[combo]`, the channel
callbacks, the before/after chains, `on_limit_reached`, the `ProjectController`
slot, and native coexistence all have signatures, hidden-state behaviour, and
wrong-state behaviour (`spec.md §2,§3,§4,§6,§7`). The earlier "design claims a
surface the spec lacks" gap is closed. The only design↔spec mismatch is N1
(the default-value wording) and the §3-table description note above.

### 4. Spec-to-roadmap coverage

Every spec surface has a milestone home, and the previously-missing homes now
exist: `compy.input.show`/`hide` exposure is in M2 (lines 56–63); the
cursor/live-write surface and the `set_text` model fix are in M7 (196–224);
the `write_to_input` facade is in M3 (74, 83–84). Documentation and test
blocks (lines 231–256) cover the dispatch levels, lifecycle, legacy
compatibility, and the `spec.md §7` edge cases.

### 5. Roadmap ordering validity

Each milestone is testable before the next. The M2/M6 `oneshot` defect is
resolved: M2 is now genuinely "zero behaviour change" (oneshot retained), M3's
"all examples work" holds (reftable fill via the retained oneshot path, no M6
dependency), and the deletion is co-located with its replacement in M6. M7
correctly depends only on M2 (not M5/M6). Ordering claims hold.

One packaging gap (not an ordering defect): **the estimates were not redone
after the round-1 scope shifts** (architect note 2). M7 in particular grew —
it now adds `get_cursor`/`set_cursor`/`set_text` plus the `UserInputModel:set_text`
`keep_cursor` fix — yet its estimate is unchanged at 2 h / 3 h
(`roadmap.md:274,303`); M3 gained the `write_to_input` facade and M2 gained the
`result` setter and `compy.input` table creation, also at unchanged figures.
Work also moved between M2 and M6 (oneshot). The totals (41 h / 23 h PERT) are
carried over from take 1. Recommend a re-estimate, or at least a note that the
figures predate the round-1 scope changes and skew low on M7.

### 6. Factual accuracy against codebase

Re-verified the round-1 fixes against `src/`:

- `cancel()` does not push `'userinput'` — confirmed
  (`userInputModel.lua:795–798`, push gated at `:809–821`). Assessment now
  states this.
- `oneshot` is a `UserInputModel` field — confirmed
  (`userInputModel.lua:15,45–49`). D-4/`design.md §3`/M6 now say so.
- Stop-time reset is `stop_project_run` / `clear_user_handlers` — confirmed
  (`consoleController.lua:860,867`). No `evacuate_required` reference remains.
- Native slot interception via `hook_if_differs` / `save_user_handlers` —
  confirmed (`controller.lua:75,779`); D-9 describes it correctly.
- `set_text`'s unconditional `jump_end()` — confirmed
  (`userInputModel.lua:145`); the D-8/M7 model fix is correctly identified.

No remaining codebase mismatch found.

### 7. Summary fidelity

`summaries/{design,spec,roadmap,decisions,assessment,requirements}.md` each
represent their (edited) source faithfully. The orphan Escape opt-in remark is
removed from `summaries/design.md`. Two carry-throughs, not new violations:
`summaries/spec.md:98` carries the same `noop+log` blanket statement as its
source (N1 — mirrored, not introduced); `summaries/decisions.md` carries the
flat `compy.*` names of its (excluded-from-relocation) source. Neither invents
a claim absent from the source.

---

## Part D — New conflicts and open questions

**New cross-document contradiction introduced by the rewrite:** one — N1, the
`noop+log` vs `sink` default, now present in `design.md §2`, `spec.md §3`, and
`summaries/spec.md`. It is residue from the pre-Item-3 model that the dispatch
sections corrected but the diagram/intro lines did not.

**`decisions.md` body vs annotations.** The decisions file preserves each
original "Suggested decision" verbatim and appends a correcting annotation.
For D-3 this means the body still describes the rejected four-tier model
("`framework_handlers → compy.handlers → compy.on_key_pressed`, with
`UserInputController:keypressed` as the terminal sink below all three",
lines 220–221), the alphabetical/`lctrl+s` example (224), and the
`_on_key_pressed(k, pressed, isrepeat)` signature (219); the three-tier
correction, modifier-first form, and `on_key_pressed(k, keys, isrepeat)`
signature live only in the appended annotation. A reader who stops at the body
gets the superseded model. Acceptable as a decision-history style, but worth a
one-line "superseded — see annotation below" marker at each corrected body so
the reconciliation is not left to the reader. Low.

**Changelog open questions — adjudication.**
1. *Dead `compy.text_input` cleanup line not added to the roadmap* — acceptable
   to leave open. It is a `src/` one-liner already documented as a bug in
   `assessment.md`; it does not block implementation. Optionally fold into M5/M7
   docs block.
2. *FR-2 → `hide()` mapping not stated explicitly* — acceptable to leave open;
   trivial to add a sentence in `requirements`/`design` traceability, not
   blocking.

**Future-seam items correctly kept out of scope.** The overloadable matcher
(Item 7) is described as an extension seam, not built; the Discord-style
text-command-set prefix matching (Item 6) is not treated as in-scope (it is
absent from spec/roadmap, which is correct). No "future seam" item was wrongly
pulled into the build.

**Architect's already-spotted inconsistencies — status.**
1. *Flat `compy.*` in design/spec* — **resolved.** No flat feature-#77
   straggler remains in `design.md`/`spec.md`/`roadmap.md` or their summaries
   (the residue is only in `decisions.md`, which was excluded from the pass —
   see Part A namespace and Part B).
2. *Roadmap not re-estimated* — **open** (see dimension 5).
3. *`on_text_input` should follow the same principles as `keypressed`* —
   **under-emphasized.** `design.md §4` (204–206) and D-6 state the textinput
   default is the textinput sink and the channel mirrors keypressed, but only in
   a sentence each; the symmetry is not drawn out (e.g. the spec gives
   `on_key_pressed` a full tier discussion and `on_text_entered` a short
   section). Worth a short explicit "the textinput channel follows the same
   default-sink/override principle" note in `decisions.md`/`spec.md`. Low.
4. *Optional `mods` trailing string on `keypressed`/`text_input`* — **not
   reflected.** The chain passes the `keys_pressed` read-only proxy as the
   second argument (modifiers derivable from it) and trails `isrepeat`; there is
   no pre-folded `mods` string argument anywhere in decisions/design/spec. If
   the design-session intent was to add a convenience `mods` string (folded like
   the combo form) as a trailing argument to downstream handlers/callbacks — so
   a combo handler shared across combos, and the post-combo callback, can read
   the modifier context without walking the proxy — that intent is currently
   absent. Either record it as a deliberate decision (proxy is sufficient,
   `mods` not added) or add it as a tracked future seam; right now it is neither.
   Low–medium, because it is an unrecorded design-session output rather than a
   doc inconsistency.
5. *Assessment/decisions still operate the original seven blocking points* —
   **partially addressed, partially open.** The new commitments did get
   surfaced as decisions (D-8, D-9) or annotations (D-3, D-6), so round-1
   controversies are not entirely omitted. But: (a) the `decisions.md`
   "blocking decisions" prose intro (lines 9–32) still enumerates *seven*
   questions while the file now carries nine decisions — D-8/D-9 are absent from
   that list and the quick-reference is the only place they appear alongside
   D-1…D-7; (b) the namespace decision is not surfaced at all (Part B);
   (c) `assessment.md §8` still frames the co-occurrence question as open
   (Item 6 note). So the framing has not fully caught up with the round-1
   resolutions. Recommend updating the intro list to nine and adding the
   namespace decision.
6. *Spec/roadmap should flag they are derivative, pre-built assuming
   endorsement* — **not addressed.** `decisions.md` and `summaries/decisions.md`
   carry the proposal-status note, but `spec.md` and `roadmap.md` headers do not
   (verified). Per the authority model both are derived/provisional; the
   architect's suggested disclaimer (part of the proposal chain, not frozen,
   reviewable/changeable without blocking implementation — "we're a startup")
   is absent. Recommend a one-paragraph header note on each. Low–medium.

---

## Summary of actionable items

None are blocking in the round-1 sense (no dropped FR, no broken example, no
contradictory *design*). Ordered by severity; (1) is the one worth fixing
before implementation, the rest are cleanup.

1. **Resolve the `noop+log` vs `sink` default contradiction (N1).** Correct
   `design.md §2` line 75, `spec.md §3` line 175, and `summaries/spec.md`
   line 98 so the `noop+log` default is scoped to the
   submit/cancel/limit callbacks, and the two channel callbacks
   (`on_key_pressed`, `on_text_entered`) read "default = sink." Medium.
2. **Surface the `compy.input.*` namespace as a decision** (e.g. D-10) so the
   stakeholder review covers it, and reconcile `decisions.md` naming
   (the lone `compy.input.handlers` at line 398 vs the otherwise-flat names) —
   decide whether `decisions.md` adopts `compy.input.*` or states explicitly
   that it predates the relocation. Medium (provenance).
3. **Re-estimate the roadmap** (or annotate the estimates as pre-round-1),
   M7 in particular. Low–medium.
4. **Adjudicate the `mods` trailing-string idea** (architect note 4): record it
   as decided-against or as a tracked future seam. Low–medium.
5. **Add the derivative/proposal-chain disclaimer to `spec.md` and
   `roadmap.md`** headers (architect note 6). Low–medium.
6. **Minor cleanups:** update the `decisions.md` "seven" intro to nine and mark
   superseded D-3 body text; re-point `assessment.md §8` at D-6's resolution;
   fix the `design.md §3` "non-character key callback" description; draw out the
   textinput-mirrors-keypressed symmetry (architect note 3). Low.

## Recommendation

**Ready for stakeholder review, after a short local cleanup pass** (items 1–2
above, optionally 3–6). The chain is now substantively coherent and faithful to
`recommendations_1.md`; the round-1 blockers are closed and verified against the
codebase. The remaining items are wording/provenance/packaging, not design
re-decisions, and do not warrant a full re-validation round. If the cleanup
pass is run, items 1 and 2 should be in it (N1 because it contradicts a core
resolution and could mislead the implementor; the namespace decision because the
stakeholder is about to review a proposal whose final API names are not in the
decision document). A `validation/recommendations_2.md` is not warranted — the
list above is small and unambiguous — but can be produced on request.
