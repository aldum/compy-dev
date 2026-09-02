# Prompt 9 — Validate the round-1 re-evaluation (D-1 discarded)

Read `CLAUDE.md` first (project overview, collaboration rules, pointers to
reference material), then `agents/rules.md` — pay particular attention to the
**tone** section before writing anything analytical: matter-of-fact and
analytic, no blame, the audience are the senior people who built the system.

## Naming rule (carried from prompt 8)

In a signature `$dirname/$filename<N>.md`, N for a round is, in principle,
`echo $(( $(ls "${dirname}/${filename}*.md" | wc -l) + 1 ))`. **The file count
under-counts when there is a numbering gap** (e.g. `prompts/` has no
`prompt2.md`, so the count gives 8 while the highest file is `prompt8.md`). When
that happens, infer the logic and use the next sequential number, not the raw
count. This prompt is `prompt9.md` for that reason. Your output file is fixed
below regardless: `reevaluations/check1.md`.

## Permissions

Write all output to disk — create the report file directly, do not just print it
in conversation. Any local file operation is permitted: read, write, edit,
search, grep, sed, and similar (including a justified `cd`-with-output-redirect).
The only prohibited operations are those that modify git history: no commits, no
rebases, no amends, no force operations, no `.git` tampering. Read-only git
(`git show`, `git diff`, `git log`) is expected and encouraged.

---

## Where we are

This is feature #77 (a callback-based input API for the project overlay). The
document chain lives under `doc/development/wip/77-new-input-api/` and had
already passed three internal validation rounds (`validation/`) plus two local
design rounds before being shown to stakeholders.

Stakeholders then gave **feedback round 1** (verbatim in `input.md`, section
"FEEDBACK AFTER FIRST ITERATION"; the originating commit was
"stakeholders feedback round 1"). The single ruling: **D-1 (backward
compatibility) is DISCARDED** — no backward compatibility, get rid of the legacy
text-input API, migrate the examples (pre-1.0, clean break acceptable).

A predecessor agent then re-evaluated and **edited the whole chain** to apply
that ruling. Its work is recorded under `reevaluations/`:

| File | Role |
|---|---|
| `reevaluations/outcome1.md` | Short "where we are" summary — **read this first.** |
| `reevaluations/round1.md` | The predecessor's reasoning: why the cascade was judged unambiguous, the codebase grounding, the one judgment call. |
| `reevaluations/changes1.md` | File-by-file changelog of every edit made. **This is the claimed delta — your job is to verify it landed faithfully.** |

By the time you run, **those edits are committed.** Identify the commit (most
recent on the branch; `git log --oneline -5`, look for the round-1 re-evaluation
commit) and use `git show <commit>` / `git diff` to see exactly what changed.
Treat `changes1.md` as the *claim* and the commit as the *evidence* — confirm
they match.

## The decision you are validating against (the bar)

- **D-1 = DISCARDED** is now **stakeholder ground truth** (it lives in
  `input.md`). It outranks everything downstream. The five legacy globals
  (`input_text`, `input_code`, `validated_input`, `user_input`,
  `write_to_input`) must be **removed**, not wrapped — no facades, no
  `strict_input`, no deprecation shim, no reftable/polling idiom surviving in
  the project-facing API.
- **Scope is text input only.** The native `love.keypressed`/`textinput`
  coexistence path (**D-9**) is a *separate* surface and must be **retained** —
  it is what keeps the stakeholders' own "only text fields break" guarantee
  true. If you find D-9 weakened or removed, that is a regression.
- **D-2…D-10 remain a local proposal** awaiting one approve/veto review; D-1 is
  the only stakeholder-settled entry. Judge "correctness" against the right
  tier (the authority model is spelled out in `prompt7.md` if you want the
  longer form).

You are a **reviewer, not a co-author.** Do not rewrite the chain. Report
findings — cite document, section, and the exact claim or gap. If you find
blocking issues, you may *recommend* a `reevaluations/recommendations1.md` but
do not write it unless asked.

---

## What to validate

### Part A — Faithfulness of the round-1 re-evaluation edits

Take each entry in `changes1.md` and confirm it is actually present in the
committed docs, correct, and complete. Per item: APPLIED / PARTIAL / MISSING /
OVER-APPLIED, with the exact location. Watch specifically for:

- **Stragglers** — any surviving mention of a facade, `strict_input`,
  deprecation warning, or a project-facing reftable/`is_empty()` polling idiom
  in the *live* chain (`decisions.md`, `requirements.md`, `assessment.md`,
  `design.md`, `spec.md`, `roadmap.md`, `summaries/*`, `README.md`). Grep is
  your friend. Note: `assessment.md` legitimately describes *today's* code and
  may mention the reftable factually — that is correct, not a straggler. Tell
  the two cases apart.
- **Over-application** — the edit should remove a backward-compat layer and add
  one migration milestone. It should **not** have invented new API surface, new
  dispatch tiers, or new callbacks. D-9 must still be intact.
- **Authority-tier honesty** — does `decisions.md` (and its summary) now mark
  D-1 as stakeholder-settled while keeping D-2…D-10 as proposal? Is
  `requirements.md §5` marked resolved (clean break)?

### Part B — Cross-document consistency

Read the chain in order — `input.md` → `requirements.md` → `assessment.md` →
`decisions.md` → `design.md` → `spec.md` → `roadmap.md`, plus `summaries/*` —
and confirm the D-1 ruling reads the same everywhere, with no contradiction
introduced. In particular:

- Each `summaries/*.md` still faithfully represents its (now-edited) source —
  the D-1 row, the removed-functions table, the milestone table, and the
  estimate figures must match between summary and full doc.
- No dangling cross-reference. The predecessor kept milestone numbering M4–M7
  stable and **voided M3** (left it as an empty, explained slot) so the many
  "M6 deletes `oneshot`", "M7 cursor surface", etc. references stay valid, and
  added **M8** for the removal + migration. Confirm there is no live reference
  to "M3 facades" as if it still exists, and that every `Mx` reference resolves.
- D-8 (`write_to_input` was a facade) and D-10 ("legacy globals unchanged")
  both depended on D-1 — confirm they were reconciled, not left contradicting
  the discard.

### Part C — Roadmap: consistency and ordering (look here hardest)

This is the milestone that changed the most; scrutinise it.

- **Dependency order.** Walk the `Input:`/dependency line of every milestone
  (M1, M2, M4, M5, M6, M7, M8 — M3 is intentionally void). Confirm each
  milestone's stated inputs actually exist by then, and that **M8 (legacy
  removal + example migration) genuinely depends on the full `compy.input.*`
  surface** — i.e. it must come after M7, because you cannot migrate the
  examples to `show()`-with-validator/highlighter, the submit/cancel callbacks,
  and `set_text`/cursor until those exist. If M8 could be ordered earlier
  without breaking, say so; if it is mis-ordered, flag it.
- **Migration scope is grounded.** The predecessor checked which in-repo
  examples use the legacy functions. Re-verify against the actual tree
  (`grep -rln -E 'input_text|input_code|validated_input|user_input|write_to_input' src/examples/`).
  Confirm: priority = `tixy`, `balloons` (and `maze`, which is **not** in the
  repo); convert-or-exclude = `repl`, `guess`, `valid`, `turtle`;
  native-only/unaffected = `pong`, `life`, `paint`, `sapper`, `sine`, `clock`,
  `drawdebug`. Flag any example that is mis-classified (e.g. one that actually
  has a text field but was listed as unaffected, or vice-versa). `turtle` is the
  interesting one — it mixes a text input with native `love.keypressed`.
- **No regression of earlier roadmap invariants.** M2 must still be genuine
  "zero behaviour change"; the `oneshot` deletion must still be M6 (not earlier);
  the M7 cursor/`set_text` surface and the `UserInputModel:set_text`
  `keep_cursor` model fix must still be present.

### Part D — Re-check the estimates FROM SCRATCH

Do **not** validate the estimate *diff*, and do **not** anchor on any historical
figure (the old ≈ 59/≈ 35, or the predecessor's stated ≈ 63/≈ 37). Ignore those.
Independently form a view of the **current** plan and check the numbers as they
now stand:

1. **PERT arithmetic.** For every row in both tables (Without LLM, With LLM),
   recompute `PERT = (O + 4M + P) / 6` and confirm the per-row value. Then sum
   O, M, P independently and confirm the totals row and the project-level
   `(O + 4×M + P)/6`. Report any cell that does not check out.
2. **Coverage.** Does every milestone (M1, M2, M4, M5, M6, M7, M8) plus the
   Documentation and Test-coverage lines have an estimate row in both tables? Is
   anything double-counted or missing? (M3 is void — it should have **no** row.)
3. **Plausibility, fresh.** Independently judge whether the O/M/P spreads are
   sane for the scope each milestone now describes — especially **M8**, whose
   scope (remove five globals + migrate the example corpus) is new this round.
   You may agree, or argue a row is optimistic/pessimistic; either way, justify
   it from the milestone's described work, not from the prior estimate.
4. State the totals you arrive at and whether they match what the roadmap and
   `summaries/roadmap.md` currently print. A mismatch between the full roadmap
   and its summary is a finding.

---

## Output

Write your report to `reevaluations/check1.md`. Suggested structure:

```
# Check 1 — Validation of the round-1 re-evaluation

## Status: PASS / PASS WITH NOTES / FAIL

## Part A — Edit faithfulness (per changes1.md item: APPLIED/PARTIAL/MISSING/OVER-APPLIED + location)
## Part B — Cross-document consistency
## Part C — Roadmap consistency and ordering
## Part D — Estimates, recomputed from scratch (per-row PERT, totals, coverage, plausibility)
## Summary of actionable items (severity-ranked)
## Recommendation
```

Distinguish severity: a surviving facade/str__input straggler in a stakeholder-
facing doc, a weakened D-9, a broken milestone dependency, or a wrong total is a
**blocker**; a stale figure in one summary or a wording nit is a **note**. If the
re-evaluation landed cleanly, say so plainly — **PASS** (or PASS WITH NOTES) is
the expected and fine outcome for a faithful, well-scoped cleanup. Reserve FAIL
for a real regression, a broken cross-reference that misleads, or an estimate
that does not add up.

The recommendation line should be one of: **Ready for stakeholder review** /
**Needs another local pass** / **Needs codebase check**.

Be specific. "Roadmap is consistent" is not useful. "M8 input correctly lists M7
as a dependency; verified the example-migration scope against `src/examples/`
(6 text-input examples, `turtle` mixed); Without-LLM total recomputes to 63.2 h,
matching the printed ≈ 63 h and `summaries/roadmap.md`" is useful.
