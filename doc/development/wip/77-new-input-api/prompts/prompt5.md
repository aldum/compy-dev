# Prompt 5 — Apply the round-1 recommendations to the document chain

Read `CLAUDE.md` first (project overview, collaboration rules, and pointers to
reference material). Then read `agents/rules.md` (coding rules and tone — pay
particular attention to the tone section: matter-of-fact and analytic, no
blame, no salesmanship, before writing anything).

## Permissions

Write all output to disk. You are expected to edit the chain documents
directly. Any local file operation is permitted: read, write, edit, search,
grep, sed, and similar tools including cd with output redirection (if used for the stated purpose). 
The only prohibited operations are those that modify
git history: no commits, no rebases, no amends, no force operations, no touching .git directory directly.

---

## Purpose

The feature #77 document chain was independently reviewed (result: FAIL — not
because the direction is wrong, but because of completeness and cross-document
consistency gaps). A round of local design discussion then resolved every
actionable item from that review. Your job is to **apply those resolutions to
the chain**, faithfully and completely, so the chain becomes internally
consistent and ready for a second independent review.

You are an executor here, not a co-designer. The resolutions are already
decided. Do not re-litigate them, and do not invent new structure. Where a
resolution is ambiguous to you, prefer the simpler reading and record the
ambiguity in an open-questions appendix (see Output) — do **not** resolve it by
adding machinery.

---

## Project context

**Compy** is a console-based, Lua-programmable fantasy computer for children,
built on LÖVE2D v11.5. MVC, Lua 5.1/LuaJIT. Code is at `src/`. Architecture
docs are under `doc/development/`. Feature #77 adds a callback-based event API
to the project input overlay. All working documents are under
`doc/development/wip/77-new-input-api/`.

---

## Your two inputs (read these first, in full)

| File | What it is | How to treat it |
|---|---|---|
| `validation/recommendations_1.md` | The **executable spec** for this task. Ten resolved items, each with grounding, the concrete change, and downward-doc targets. | **Authoritative for this task.** Apply it. |
| `validation/validation_report_1.md` | The independent review that produced the items. Explains *why* each change is needed and cites exact locations. | Reference / rationale. Use it to locate things and to understand intent. |

`recommendations_1.md` opens with a **"Document authority model"** section.
Read it carefully — it governs which documents you may freely rewrite and which
you must not.

---

## The authority model (governs every edit you make)

Only one document carries stakeholder authority. Everything downstream is a
**local proposal** derived from it, awaiting a single eventual stakeholder
approve/veto review. So there is no "human-approved" tier below `input.md` to
protect — the tiers below rank *depth of human input within the local
proposal*, not approval status.

**Never edit (stakeholder ground truth):**
- `input.md` — the only document with stakeholder authority.

**Do not edit (high human input; recommendations require no change here):**
- `requirements.md` — locally formalised FR/NFR, closely tracing `input.md`.
  Not stakeholder-signed, but high-authority within the local proposal. The
  recommendations confirm no edits are needed (the 2D cursor contract is
  consistent with its generic "cursor position" wording). Leave it unless an
  item explicitly requires a change — none do.

**Edit freely (derived):**
- `design.md`, `spec.md`, `roadmap.md`, `assessment.md`, and everything in
  `summaries/`. These were generated downward and inherit the gaps the review
  found. Bring them in line with `recommendations_1.md`.

**Edit with provenance tagging (`decisions.md` and `summaries/decisions.md`):**
- `decisions.md` is a *local* artifact end to end: D-1…D-7 came from an earlier
  local design round, and the round-1 resolutions are a second local round.
  Neither has stakeholder sign-off; the whole file is a proposal awaiting one
  eventual approve/veto. So you are **not** promoting local resolutions into a
  "human-approved" tier (there is none below `input.md`). What matters is
  **traceability** — mark which round each new or changed decision came from —
  see next section.

---

## How to handle `decisions.md` (provenance rules)

The goal: incorporate the round-1 resolutions that constitute **genuine new
conflict points or new architectural commitments** back into `decisions.md`
(and its summary), with clear **traceability** of which round each change came
from. The whole file is a local proposal — you are not misrepresenting
authority by recording them, only keeping the delta auditable.

0. **Add a status note at the top of `decisions.md`** (and its summary) stating
   that the entire file is a *local design proposal* derived from `input.md`,
   pending a single eventual stakeholder approve/veto review — no entry here has
   been stakeholder-signed.
1. **New commitments → new decision entries.** Give them fresh IDs continuing
   the existing sequence (the file currently runs D-1…D-7, so start at D-8).
   Use the same entry shape as the existing decisions (Question / Context /
   Affects / Source / decision).
2. **Corrections to existing decisions → annotate in place.** Where round 1
   corrected or superseded an existing decision (e.g. D-3 dispatch tiers, D-4
   `oneshot`/submit prose, D-6 character/key channels), edit the entry and add
   a short provenance note on the change.
3. **Tag every round-1-originated change** with a clear, consistent marker, for
   example: *"(Origin: local design round 1, 2026-06. See
   `validation/recommendations_1.md` Item N.)"* Use the same marker text
   everywhere so a reader (and the next reviewer) can grep it. (You need not
   retro-tag D-1…D-7; the top-of-file status note covers their local origin.)
4. **Only promote the genuine decisions.** Pure downward-doc reconciliations
   (e.g. fixing a combo example, fixing a file-path reference, renaming an
   argument) do **not** need a decisions.md entry — just fix them in
   design/spec/roadmap. Use judgement: if it resolves a contradiction or makes
   a new architectural choice, it belongs in decisions.md with provenance; if
   it is mechanical alignment, it does not.

Candidates that likely warrant a decisions.md entry or annotation (confirm
against `recommendations_1.md`; this list is guidance, not a mandate):
- **Item 3** — three-tier dispatch; the sink is the *default value* of
  `compy.on_key_pressed`, not a separate level (corrects D-3 / supersedes the
  four-tier elaboration).
- **Item 4** — native `love.keypressed`/`textinput` coexistence via transparent
  auto-provisioning, gated by a legacy heuristic with transition diagnostics
  (genuinely new; the chain never decided this).
- **Item 6** — two independent channels, no exclusivity; the "no double
  callback" suggestion in D-6 is dropped (note: D-6 was only a *"Suggested
  decision"* and was auto-generated filler never given design attention in the
  prior round — weaker even than the other local D's — so dropping it is
  striking filler, not overturning a considered decision; say so).
- **Item 7** — canonical combo form (modifier-first, generic l/r folding),
  metatable-normalised registration, overloadable matcher (extends D-3's terse
  "combo lookup by serialised key names").
- **Item 1** — restored FR-8/9/10 and the 2D `(line, col)` cursor contract
  (new explicit commitment; previously dropped by a derivation error).
- **Item 2** — `oneshot` deletion belongs with M6 framework-owned submit
  (corrects D-4 prose and the roadmap; mostly a sequencing fix, but the D-4
  prose correction is worth annotating).

---

## What to do, item by item

For each of the ten items in `recommendations_1.md`, apply the resolution to
**every** document it names under its "Downward-doc updates" / "Roadmap
placement" / "Status" subsections, plus any summary that mirrors that content.
The recommendations already tell you the targets per item; follow them. Below
is the cross-cutting target matrix so nothing is missed.

| Item | Primary targets | Also update |
|---|---|---|
| 1 (+5) — FR-8/9/10, 2D cursor, `write_to_input` facade | `design.md §3` (component table), `spec.md §2/§5`, `roadmap.md M3/M7` | `summaries/design.md`, `summaries/spec.md`, `summaries/roadmap.md`; `decisions.md` (new entry, provenance) |
| 2 — `oneshot` deletion → M6; submit ordering | `roadmap.md` M2/M3/M6 (+ file lists) | `summaries/roadmap.md`; `decisions.md` D-4 prose (annotate) |
| 3 — three-tier dispatch; sink = default callback | `design.md §4`, `spec.md §3` | `summaries/design.md`, `summaries/spec.md`; `decisions.md` D-3 (annotate) |
| 4 — native handler coexistence (auto-provision + heuristic) | `design.md §2/§3/§6`, `spec.md §6` | `summaries/design.md`, `summaries/spec.md`; `decisions.md` (new entry, provenance) |
| 6 — two channels, no exclusivity | `spec.md §3`, `decisions.md` D-6 (supersede) | `summaries/spec.md`, `summaries/decisions.md` |
| 7 — combo canonical form, metatable, matcher | `spec.md §1/§3`, `design.md §4`, `roadmap.md M1/M5` | `summaries/*` as mirrored; `decisions.md` D-3 (annotate/extend) |
| 8 — codebase-reference fixes | `assessment.md §2/§8`, `design.md §3`, `spec.md §3/§6`, `decisions.md` D-4/D-7 (factual prose), `roadmap.md` M2 file target | `summaries/assessment.md`, `summaries/decisions.md` |
| 9 — D-7 FR-11/FR-12 walkthrough | `design.md §7` (add the walkthrough) | `summaries/design.md` if it asserts coverage |
| 10 — smaller drifts (`user_input()`, `on_text_entered` arg, `isrepeat`, `compy.show/hide` milestone, Escape opt-in drop, dead alias) | `spec.md §3/§5/§7`, `roadmap.md M2/M3`, `summaries/design.md` (remove orphan Escape remark) | mirrored summaries |

When an item folds another (e.g. Item 5 folds into Item 1; Item 10.5 folds into
Item 6), do not duplicate — apply once and cross-reference.

The above is **Stage 1** — the functional / architectural edits (Items 1–10).

---

## Stage 2 — Namespace relocation (`compy.input.*`) — separate pass

`recommendations_1.md` has a section **"Namespace isolation — relocate the new
API under `compy.input.*`"**. Apply it as a **distinct pass, after Stage 1
is complete and internally consistent** — do not interleave it with the Stage 1
edits.

- It is a mechanical rename/reparent: every *new* `compy.X` name introduced by
  feature #77 (including the Item 1 cursor/text functions) becomes
  `compy.input.X`, across `design.md`, `spec.md`, `roadmap.md`, and the
  mirrored summaries. No behavioural change, no signature change.
- **Do not move** the legacy global facades (`input_text()`, `input_code()`,
  `validated_input()`, `user_input()`, `write_to_input()`) — they stay as
  project-env globals; only their internal calls now target `compy.input.*`.
- **`keys_pressed` proxy:** keep it global (`compy.keys_pressed`), **not**
  under `compy.input` — decided; it is raw keyboard state (physical reality),
  not the input-manipulation layer. Do not reparent it.
- Follow the scope table and mechanics in that recommendation section exactly.
  Do not rename anything it does not list.

Record this pass as its own row in the changelog, separate from the Item 1–10
rows, so the relocation can be reviewed independently of the behavioural edits.

---

## Hard guardrails (read before editing)

1. **`recommendations_1.md` wins.** Where it and an existing chain document
   disagree, change the document. Do not preserve the old text as an
   alternative.
2. **Do not add structure beyond the recommendations.** No new dispatch tiers,
   no new callbacks, no new abstractions, no new config fields. The last
   iteration failed partly because a redundant fourth dispatch tier was
   invented; do not repeat that pattern. Three tiers, sink as the default of
   `on_key_pressed` — exactly as Item 3 states.
3. **Keep it pedagogically simple (NFR-4).** The project-facing API is a plain
   table and a few callbacks. Don't introduce machinery a student couldn't
   read. Honour `agents/rules.md` (store functions, not string tags; modest
   line/function sizes when you show code).
4. **Code snippets in docs:** keep them illustrative and consistent with the
   resolutions. You are editing *documents*, not `src/`. Do not modify files
   under `src/` (the model fix in Item 1 is described in the spec/roadmap as
   work to be done; do not perform it here).
5. **Propagate, then cross-check.** After applying all items, do a consistency
   pass: every changed contract must read the same way in `design.md`,
   `spec.md`, `roadmap.md`, and the corresponding `summaries/`. Combo examples,
   callback signatures (`on_key_pressed(k, keys, isrepeat)`,
   `on_text_entered(text, keys)`), the three-tier model, and the cursor
   coordinate space must match across all of them.
6. **When unsure, flag — never invent.** If a resolution is ambiguous or you
   find a new conflict the recommendations did not anticipate, leave the
   simpler reading in place and record the question in the open-questions
   appendix. Do not design your way out of it.

---

## Output

1. **The edited chain** — `design.md`, `spec.md`, `roadmap.md`,
   `assessment.md`, `decisions.md`, and the mirrored `summaries/*.md`, all
   brought into line with `recommendations_1.md` and internally consistent.
2. **A changelog** at `validation/changelog_1.md` with:
   - one row per recommendation item: what changed, in which files;
   - the list of new/annotated `decisions.md` entries and their provenance tag;
   - an explicit "**Open questions for re-review**" section listing anything you
     flagged rather than resolved (per guardrail 6), each with the document
     location and why you left it open.
3. Do **not** edit `input.md` or `requirements.md`. Do **not** edit
   `validation/recommendations_1.md` or `validation/validation_report_1.md`
   (they are the inputs of record).

Be specific and faithful. The success criterion is that an independent
reviewer, reading the rewritten chain against `recommendations_1.md`, finds
every item applied, no item over-applied (no invented structure), and no
remaining cross-document contradiction.
