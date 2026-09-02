# Prompt 10 — Handover / context (awaiting stakeholder feedback, round 2)

This file is a **handover context**, not yet an actionable task. It carries the
process rules and the current state of feature #77 so a fresh agent can pick up
the moment the next stakeholder feedback lands. The owner will **augment this
file** with the verbatim feedback and the concrete task when it arrives (look
for the marker at the bottom). Until then, treat everything here as orientation.

---

## Read first (orientation)

1. `CLAUDE.md` — project overview and collaboration rules (points to the two
   files below).
2. `agents/rules.md` — coding rules and **tone**. Read the tone section before
   writing anything analytical: matter-of-fact and analytic, no blame; the
   audience is the senior people who built the system. It also carries the
   **Summaries for Stakeholders** rules (mirror their words, no internal jargon,
   no second person, and do not re-explain their own requests back to them) —
   apply those to any "in brief" / summary section.
3. `agents/architecture_assistance.md` — the assistant role and its limits.
4. The document chain under `doc/development/wip/77-new-input-api/` (see the
   authority model below for what each file is and how much weight it carries).

## Collaboration rules (the process)

- Role: assistant to a senior architect — analysis, inspection, suggestions by
  default. **Reviewer, not co-author**: do not rewrite the chain unless the
  owner explicitly asks for edits. When edits are requested, the owner reviews
  all changes and handles commits/stashes.
- **Git:** read-only operations (`git show`/`diff`/`log`) are expected and
  encouraged. No operations that modify history — no commits, rebases, amends,
  force operations, or `.git` tampering. Staging only on explicit confirmation.
- **Local file operations are permitted** (read, write, edit, grep, sed, and
  similar, including a justified `cd`-with-output-redirect). Write outputs **to
  disk** — create the report/file directly, do not just print it in
  conversation.
- No GitHub interaction, no agent/subagent spawning.

## Naming / numbering rule (carried across prompts)

In a signature `$dirname/$filename<N>.md`, N for a round is in principle
`echo $(( $(ls "${dirname}/${filename}*.md" | wc -l) + 1 ))`. **The raw count
under-counts when there is a numbering gap** (e.g. `prompts/` has no
`prompt1`/`prompt2`, so the count gives 8 while the highest file is `prompt9`).
When that happens, infer the logic and use the next sequential number, not the
raw count — this file is `prompt10.md` for that reason. The same applies to the
round/validation artifacts: the next re-evaluation round is `round2.md` /
`changes2.md` / `outcome2.md`, and the next validation is `check2.md`.

---

## The document chain and the authority model

Authority gates on *whether a human actually decided*, not on which file a line
sits in.

- **Stakeholder ground truth:** `input.md` only — may not be overruled. It now
  contains two settled things: the original ticket/clarification, and **feedback
  round 1** (the "FEEDBACK AFTER FIRST ITERATION" section).
- **D-1 is settled: DISCARDED.** Stakeholder consensus in `input.md` round 1 —
  no backward compatibility. The five legacy text-input globals (`input_text`,
  `input_code`, `validated_input`, `user_input`, `write_to_input`) are
  **removed**, not wrapped; examples migrate to `compy.input.*`. This outranks
  everything downstream.
- **D-9 is a separate surface and is retained.** The native
  `love.keypressed`/`textinput` coexistence path is what keeps the stakeholders'
  "only text fields break" guarantee true. It is not part of the D-1 discard.
- **Still a local proposal:** `decisions.md` D-2…D-10 — awaiting a single
  eventual stakeholder approve/veto pass. Provisional; same tier regardless of
  the round each was added in.
- **High human input (local, traces `input.md`):** `requirements.md`. Its §5
  backward-compat question is now marked RESOLVED (clean break).
- **Derived:** `design.md`, `spec.md`, `roadmap.md`, `assessment.md`,
  `summaries/*`, `README.md` — must stay consistent with the tiers above and
  with each other. Note: `assessment.md` describes *today's* code, so its
  reftable/polling references are factual, not stragglers.

---

## History so far (timeline)

1. **Initial analysis chain** — three independent validation rounds
   (`validation/validation_report_{1,2,3}.md`) and two local design rounds
   (`validation/recommendations_{1,2}.md` + `changelog_{1,2}.md`). Ended **PASS
   WITH NOTES**, ready for stakeholder review.
2. **Feedback round 1** (`input.md` "FEEDBACK AFTER FIRST ITERATION"; commit
   `de5d781`): **D-1 DISCARDED** — no backward compatibility; remove the legacy
   API, migrate the examples.
3. **Re-evaluation round 1** (commit `c94fb57`): the chain was edited end to end
   to apply the discard. Recorded in `reevaluations/round1.md` (reasoning),
   `reevaluations/changes1.md` (file-by-file changelog), `reevaluations/outcome1.md`
   (summary). M3 was voided (numbering kept), M8 (legacy removal + example
   migration) was added, both estimate tables recomputed.
4. **Check 1** (`reevaluations/check1.md`): independent validation of the
   re-evaluation → **PASS**. Edit faithfulness, cross-document consistency,
   roadmap ordering, and the estimates (recomputed from scratch: ≈ 63 h without
   LLM / ≈ 37 h with) all checked out. Two NOTE-level doc nits were found and
   **fixed in the same pass at the owner's request** (a stale D-8 glance-table
   cell in `summaries/decisions.md`; a loose M8 dependency header in
   `roadmap.md`). Recommendation: **Ready for stakeholder review.**

---

## Where we are now

- The chain is internally consistent and reflects the D-1 discard end to end.
- The build plan is **M1 → M8** (M3 is intentionally void; numbering preserved
  so M4–M7 cross-references stay valid).
- **Awaiting the next round of stakeholder feedback.** The standing open item is
  the single **approve/veto pass over the D-2…D-10 proposal set** (D-1 is now
  settled). Owner-delegated and non-blocking: the convert-or-exclude call for
  `repl`/`guess`/`valid`/`turtle`, and the arrival/migration of the out-of-repo
  `maze` showcase.
- Nothing in the current state blocks implementation starting at M1.

---

## When feedback arrives (anticipated task shape — owner to confirm/replace)

The pattern in this project (see `prompt7.md`/`prompt9.md`) has been: given new
stakeholder feedback, determine whether the chain can be updated **unambiguously
without owner resolution**; if yes, apply it and record the work; if not,
surface the specific decisions needed rather than guessing. Concretely, the
likely next steps are:

1. Read `input.md` (the new feedback) and the commit that introduced it.
2. Judge each change against the authority tier it touches (a `D-2…D-10`
   approve/veto is a *settling* of the local proposal; a brand-new constraint is
   ground truth that may cascade).
3. If unambiguous: apply it across the chain and write `reevaluations/round2.md`
   (reasoning + judgment calls), `reevaluations/changes2.md` (file-by-file
   changelog), and `reevaluations/outcome2.md` (summary). Keep milestone
   numbering stable; void rather than renumber if something is dropped.
4. Follow with an independent validation pass (`reevaluations/check2.md`) on the
   same bar used for `check1.md`: edit faithfulness, cross-document consistency,
   roadmap ordering, and estimates recomputed from scratch.
5. Report where things stand.

<!-- ───────────────────────────────────────────────────────────────────── -->
<!-- OWNER: paste the round-2 stakeholder feedback (verbatim) and the        -->
<!-- concrete task below this line. Until then, this file is context only.   -->
<!-- ───────────────────────────────────────────────────────────────────── -->
