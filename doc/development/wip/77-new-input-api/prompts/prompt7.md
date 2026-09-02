# Prompt 7 — Third independent re-review of the chain (round 3)

Read `CLAUDE.md` first (project overview, collaboration rules, and pointers to
reference material). Then read `agents/rules.md` (coding rules and tone — pay
particular attention to the tone section before writing anything analytical:
matter-of-fact and analytic, no blame).

## Permissions

Write all output to disk. You are expected to create the report file directly —
do not just print it in conversation. Any local file operation is permitted:
read, write, edit, search, grep, sed, and similar tools (including sane and
justified cd-with-output-redirect). The only prohibited operations are those
that modify git history: no commits, no rebases, no amends, no force operations,
no direct tampering with the .git directory.

Write the re-review report to:
`doc/development/wip/77-new-input-api/validation/validation_report_3.md`

---

## Purpose

This is the **third** independent review of the feature #77 document chain. The
history so far:

1. **Review round 1** (`validation/validation_report_1.md`) returned FAIL on
   completeness and cross-document consistency grounds (FR-8/9/10 dropped, a
   submit-path ordering defect, a dispatch-contract contradiction, and more).
2. **Local design round 1** resolved those into
   `validation/recommendations_1.md`; the chain was rewritten to apply them
   (`validation/changelog_1.md`).
3. **Review round 2** (`validation/validation_report_2.md`) returned **PASS WITH
   NOTES**: the round-1 blockers were closed and faithfully applied; what
   remained was consistency residue and provenance/packaging gaps.
4. **Local design round 2** distilled those into
   `validation/recommendations_2.md` (six items) and applied them
   (`validation/changelog_2.md`).

Your job is to independently re-validate the chain **as it now stands after
round 2**. This is expected to be a **lighter** review than round 2 — the chain
already passed with notes, and round 2 was a targeted cleanup, not a rewrite.
The bar is: did the round-2 cleanup land faithfully, without regressions and
without introducing new contradictions, and is the chain now ready for
stakeholder review?

You are a reviewer, not a co-author. Do not rewrite the chain documents — report
findings. Be specific: cite document, section, and the exact claim or gap.

---

## Project context

**Compy** is a console-based, Lua-programmable fantasy computer for children,
built on LÖVE2D v11.5. MVC, Lua 5.1/LuaJIT. Code is at `src/`. Architecture docs
under `doc/development/`. Feature #77 adds a callback-based event API to the
project input overlay. All working documents are under
`doc/development/wip/77-new-input-api/`.

---

## Authority model (you must apply it when judging)

Unchanged across rounds. Only `input.md` carries stakeholder authority. **No
stakeholder sign-off has ever happened on anything downstream of it** —
`requirements.md`, all of `decisions.md` (now D-1…D-10), and both rounds of
resolutions are a single **local proposal** awaiting one eventual stakeholder
approve/veto review. Judge "correctness" against the right tier.

- **Stakeholder ground truth:** `input.md` — may not be overruled.
- **High human input (local, traces `input.md`):** `requirements.md`. Treat its
  FR/NFR as the working definition of what the feature must do, but also check it
  still faithfully traces `input.md`. (It was not edited in rounds 1 or 2.)
- **Local proposal:** `decisions.md` end to end (D-1…D-10, both rounds) plus
  everything in `recommendations_1.md` and `recommendations_2.md`. Provisional.
  Do not treat earlier decisions as a higher tier than later ones — same tier,
  different dates.
- **Derived:** `design.md`, `spec.md`, `roadmap.md`, `assessment.md`,
  `summaries/`. Must be consistent with the tiers above and with each other.

The authority model gates on *whether a human actually decided*, not on which
file a line sits in.

---

## Inputs

Read these before reviewing the chain:

| File | Role |
|---|---|
| `validation/validation_report_2.md` | The second review. Its "Summary of actionable items" is what round 2 set out to fix. The chain it reviewed was already PASS WITH NOTES. |
| `validation/recommendations_2.md` | The agreed round-2 resolutions (the intended delta). **The spec the round-2 edits were executed against.** Six items. |
| `validation/changelog_2.md` | The round-2 rewrite's self-report: what changed where, the new/annotated decisions, and its own open questions. |

For continuity (reference, not the primary delta this round):
`validation/recommendations_1.md`, `validation/changelog_1.md`,
`validation/validation_report_1.md`.

Then read the chain in order: `input.md` → `requirements.md` → `assessment.md`
→ `decisions.md` → `design.md` → `spec.md` → `roadmap.md`, plus `summaries/*.md`.

## Supporting material (verify codebase claims; not design authority)

- `notes/routing_unification.md`, `notes/love2d_handler_layers.md`,
  `notes/event_delegation_chain.md`, `notes/enter_escape_routing.md`,
  `notes/textinput_routing.md`, `notes/solution_sketch.md`.
- Source files for factual checks (the round-1/2 fixes depend on these):
  - `src/controller/controller.lua` — global handler, overlay gate, lifecycle,
    `love.keypressed` slot / `hook_if_differs` / `save_user_handlers`.
  - `src/controller/consoleController.lua` — REPL/editor routing, input entry
    points, `stop_project_run`/`clear_user_handlers`, `write_to_input`.
  - `src/controller/userInputController.lua` — widget keypressed/textinput,
    submit/cancel, `oneshot` read.
  - `src/model/input/userInputModel.lua` — evaluate/handle/cancel, `oneshot`
    field, cursor methods, `set_text`/`keep_cursor`/`jump_end`, `is_at_limit`.

---

## What to validate

### Part A — Faithfulness of the round-2 edits (primary this round)

For each of the **six** items in `recommendations_2.md`:

1. **Default contradiction (N1).** Is the `noop+log`-vs-`sink` default fixed
   everywhere it appeared — `design.md §2` diagram, `spec.md §3` intro,
   `summaries/spec.md`? Do the two channel callbacks (`on_key_pressed`,
   `on_text_entered`) now consistently read "default = sink", and do the
   submit/cancel/limit callbacks still read "default = noop+log"? Any place
   still conflating the two?
2. **Namespace surfaced as a decision + `decisions.md` naming.** Is there a new
   **D-10** (namespace isolation under `compy.input.*`) in `decisions.md` and its
   summary, with provenance? Were the new-API names in `decisions.md` /
   `summaries/decisions.md` relocated to `compy.input.*` consistently (no flat
   straggler, no double `compy.input.input`), with `compy.keys_pressed` and the
   legacy globals left alone?
3. **Roadmap re-estimate.** Is the estimate now a genuine three-point PERT
   (Optimistic, Most-likely, Pessimistic; PERT = (O+4M+P)/6), not a two-point
   table whose "PERT" collapsed to the most-likely? Recompute a couple of rows
   and the totals — do they check out? Is the internal estimate-revision history
   gone (validation rounds are not stakeholder-facing)? Does `summaries/roadmap.md`
   match the full roadmap's figures?
4. **`mods` modifier-string.** Is it recorded as a **future seam, not built in
   v1**, for both channels (under `decisions.md` D-6 and `spec.md §3`), and
   flagged as an open question rather than silently built or silently dropped?
   Confirm no `mods` argument was actually added to any signature.
5. **Disclaimers.** Do `spec.md` and `roadmap.md` now carry a
   derived/proposal-chain status note (pre-built assuming endorsement; not
   frozen; reviewable without blocking implementation)?
6. **Minor cleanups.** decisions intro reconciled to the D-1…D-10 set; D-3 (and
   D-6) body marked as superseded-in-part where the body predates the round-1
   annotation; `assessment.md §8` co-occurrence re-pointed at D-6;
   `design.md §3` table wording for `on_key_pressed`; textinput-mirrors-keypressed
   symmetry made explicit in design/spec/decisions.

Per-item verdict: APPLIED / PARTIAL / MISSING / OVER-APPLIED, with the exact
location. Watch specifically for **over-application** — round 2 was a cleanup;
no new dispatch tier, callback, config field, or abstraction should have
appeared. (The `mods` string in particular must be a *seam note*, not new API.)

### Part B — No regression of the round-1 resolutions

Round 2 edited several documents that round 1 had already fixed. Confirm nothing
regressed:

- FR-8/9/10 still carried end to end (D-8, `design §3`, `spec §2`, `roadmap M7`).
- The three-tier model intact (sink = default of `on_key_pressed`; no fourth
  tier reappeared via the §3 default-wording edits).
- M2/M6 `oneshot` ordering intact; `oneshot` still a `UserInputModel` field.
- Native coexistence (D-9), two-channel model (D-6), combo canonical form (D-3),
  `write_to_input` facade, the FR-11/12 walkthrough — all still present and
  consistent after the round-2 edits.
- The `compy.input.*` relocation is still complete in `design/spec/roadmap` and
  their summaries (the round-2 `decisions.md` relocation did not desync them).

### Part C — Provenance and traceability

- Does `decisions.md` (and its summary) still carry the top-of-file local-proposal
  status note, and is the D-1…D-10 set internally consistent (quick-reference
  table, per-decision detail, and the intro count all agreeing)?
- Are round-2 changes tagged with a consistent, greppable round-2 provenance
  marker (distinct from the round-1 marker), so the round-2 delta is auditable?
- Is D-10's provenance honest (the namespace choice originated in round 1's
  recommendations and is *recorded* as a decision in round 2)?
- Does `requirements.md` still faithfully trace `input.md` (unedited; confirm no
  downstream change silently contradicts it)?

### Part D — Seven dimensions (spot re-run, not full)

The chain passed these in round 2; re-run only where round 2 touched them, and
flag anything that drifted:

1. **Requirements coverage** — still all FR/NFR traced; FR-8/9/10 intact.
2. **Decision consistency** — D-10 reflected consistently; no decision (old or
   new) silently contradicted by a derived doc; the default-wording fix did not
   create a new mismatch.
3. **Design-to-spec completeness** — channel-callback defaults and the
   textinput/keypressed symmetry now read the same in design and spec.
4. **Spec-to-roadmap coverage** — every surface still has a milestone home;
   estimates cover the actual scope.
5. **Roadmap ordering validity** — unchanged by round 2; confirm the re-estimate
   did not perturb milestone dependencies or the M2/M6 ordering.
6. **Factual accuracy against codebase** — re-spot-check the load-bearing facts:
   `cancel()` does not push `'userinput'`; `oneshot` is a `UserInputModel` field;
   stop-time reset is `stop_project_run`/`clear_user_handlers`; native slot
   interception via `hook_if_differs`; `set_text`'s unconditional `jump_end()`
   (the M7 model fix). Flag any mismatch.
7. **Summary fidelity** — each `summaries/*.md` still faithfully represents its
   (now round-2-edited) source; the default-wording, D-10 row, and estimate
   figures match between summary and source.

### Part E — Adjudicate the carried-forward open questions

`changelog_2.md` carries two open questions. For each, state whether leaving it
open is acceptable for stakeholder review, or whether it blocks:

1. **The `mods` trailing modifier-string** — recorded as a seam, not built.
   Acceptable to defer, or should it be in-scope? (Note the stakeholder input
   in `input.md` and FR-5/FR-6 — does anything there require it?)
2. **The `decisions.md` relocation reversing round 1's narrow exclusion** —
   acceptable as the resolution to the round-2 split finding, or does it
   reintroduce a problem?

Also check: are there any *new* cross-document contradictions introduced by the
round-2 edits that `recommendations_2.md` did not anticipate?

---

## Output format

Produce a structured report at the path above. Suggested structure:

```
# Validation Report 3 — Feature #77 Document Chain (post round-2 cleanup)

## Status: PASS / PASS WITH NOTES / FAIL

## Part A — Round-2 faithfulness (per item 1..6: APPLIED/PARTIAL/MISSING/OVER-APPLIED, location, note)
## Part B — No regression of round-1 resolutions
## Part C — Provenance and traceability
## Part D — Seven dimensions (spot re-run)
## Part E — Carried-forward open questions (adjudication) + any new conflicts
## Summary of actionable items
## Recommendation
```

Distinguish severity clearly: a regressed FR or a new cross-document
contradiction is blocking; a stale figure in one summary is a note. If the chain
is now coherent, faithful, and free of regressions, say so plainly — **PASS** (or
PASS WITH NOTES if trivial residue remains) is the expected outcome for a
successful cleanup round. Reserve FAIL for a genuine regression or a new blocking
contradiction.

If new blocking issues exist, a `validation/recommendations_3.md` may be
warranted; recommend it but do not write it unless asked. The recommendation
line should be one of: **Ready for stakeholder review** / **Needs another local
pass** / **Needs codebase check**.

Be specific. "Item 2 applied" is not useful. "Item 2 applied: D-10 present in
`decisions.md` (per-decision detail + quick-reference row) and
`summaries/decisions.md`; `decisions.md` relocated to `compy.input.*` with no
flat straggler (grep-clean) and `compy.keys_pressed` preserved" is useful.
