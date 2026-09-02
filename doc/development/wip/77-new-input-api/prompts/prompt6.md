# Prompt 6 — Independent re-review of the altered chain

Read `CLAUDE.md` first (project overview, collaboration rules, and pointers to
reference material). Then read `agents/rules.md` (coding rules and tone — pay
particular attention to the tone section before writing anything analytical:
matter-of-fact and analytic, no blame).

## Permissions

Write all output to disk. You are expected to create the report file directly —
do not just print it in conversation. Any local file operation is permitted:
read, write, edit, search, grep, sed, and similar tools (including sane and justified cd-with-output-redirect). 
The only prohibited
operations are those that modify git history: no commits, no rebases, no
amends, no force operations, no direct tampering with .git directory.

Write the re-review report to:
`doc/development/wip/77-new-input-api/validation/validation_report_2.md`

---

## Purpose

This is the **second** independent review of the feature #77 document chain.
The first review (`validation/validation_report_1.md`) returned FAIL on
completeness and cross-document consistency grounds. Since then two things
happened:

1. **A local design round** (architect + assistant, **no stakeholder
   involvement**) resolved all ten actionable items. Its output is
   `validation/recommendations_1.md` — the agreed resolutions, with grounding
   and per-document targets.
2. **The chain was rewritten** to apply those resolutions (per `prompt5.md`),
   producing edited `design.md`, `spec.md`, `roadmap.md`, `assessment.md`,
   `decisions.md`, the `summaries/`, and a `validation/changelog_1.md`.

Your job is to independently re-validate the rewritten chain. Unlike the first
review, you are now checking a chain that was deliberately altered against a
known set of intended changes — so the review has both the original
dimensions **and** a delta/faithfulness dimension.

You are a reviewer, not a co-author. Do not rewrite the chain documents —
report findings. Be specific: cite document, section, and the exact claim or
gap.

---

## Project context

**Compy** is a console-based, Lua-programmable fantasy computer for children,
built on LÖVE2D v11.5. MVC, Lua 5.1/LuaJIT. Code is at `src/`. Architecture
docs under `doc/development/`. Feature #77 adds a callback-based event API to
the project input overlay. All working documents are under
`doc/development/wip/77-new-input-api/`.

---

## Authority model (you must apply it when judging)

Only `input.md` carries stakeholder authority. **No stakeholder sign-off has
ever happened on anything downstream of it** — `requirements.md`, all of
`decisions.md` (D-1…D-7 came from an earlier local round), and this round's
resolutions are all part of a single **local proposal** awaiting one eventual
stakeholder approve/veto review. When you judge whether something is "correct,"
judge against the right tier.

- **Stakeholder ground truth:** `input.md` — the only document the proposal
  must serve and may not overrule.
- **High human input (local, traces `input.md`):** `requirements.md`. Treat its
  FR/NFR as the working definition of what the feature must do, but remember it
  is not itself stakeholder-signed — so also check it still faithfully traces
  `input.md`.
- **Local proposal:** `decisions.md` end to end (both the earlier round's
  D-1…D-7 and this round's additions), plus everything in
  `validation/recommendations_1.md`. Provisional, pending the eventual review.
  Do **not** treat D-1…D-7 as a higher tier than the round-1 additions — they
  are the same tier, just earlier.
- **Derived:** `design.md`, `spec.md`, `roadmap.md`, `assessment.md`,
  `summaries/`. Must be consistent with the tiers above and with each other.

The authority model gates on *whether a human actually decided*, not on which
file a line sits in. (Example from round 1: D-6's "no double callback" lived in
`decisions.md` but was only a "Suggested decision" / auto-generated filler — so
it was treated as droppable, not as a considered decision.)

---

## Inputs

Read these before reviewing the chain:

| File | Role |
|---|---|
| `validation/validation_report_1.md` | The first review. The ten actionable items and their original locations. |
| `validation/recommendations_1.md` | The agreed resolutions (the intended delta). **The spec the rewrite was executed against.** |
| `validation/changelog_1.md` | The rewrite's self-report: what changed where, new/annotated decisions, and the rewrite's own open-questions. |

Then read the rewritten chain in order: `input.md` → `requirements.md` →
`assessment.md` → `decisions.md` → `design.md` → `spec.md` → `roadmap.md`, plus
`summaries/*.md`.

## Supporting material (verify codebase claims; not design authority)

- `notes/routing_unification.md`, `notes/love2d_handler_layers.md`,
  `notes/event_delegation_chain.md`, `notes/enter_escape_routing.md`,
  `notes/textinput_routing.md`, `notes/solution_sketch.md`.
- Source files for factual checks:
  - `src/controller/controller.lua` — global handler, overlay gate, lifecycle,
    `love.keypressed` slot / `hook_if_differs` / `save_user_handlers`.
  - `src/controller/consoleController.lua` — REPL/editor routing, input entry
    points, `stop_project_run`/`evacuate_required`, `write_to_input`.
  - `src/controller/userInputController.lua` — widget keypressed/textinput,
    submit/cancel, `oneshot` read.
  - `src/controller/editorController.lua` — editor mode dispatch, Escape.
  - `src/model/input/userInputModel.lua` — evaluate/handle/cancel, `oneshot`
    field, cursor methods (`get_cursor_pos`, `move_cursor`, `set_cursor`,
    `set_text`/`keep_cursor`), `is_at_limit`.

---

## What to validate

### Part A — Faithfulness of the rewrite (new this round)

For each of the ten items in `recommendations_1.md`:
- **Applied?** Is the resolution actually present in every document the item
  named (design/spec/roadmap/decisions/summaries as applicable)?
- **Applied correctly?** Does it match the resolution as written, including the
  grounding constraints (e.g. 2D source-line cursor; sink as the *default* of
  `on_key_pressed`; legacy heuristic gating the wrapper split; modifier-first
  generic-folded combos; two independent channels with no exclusivity;
  `on_key_pressed(k, keys, isrepeat)`; Escape opt-in dropped)?
- **Over-applied?** Did the rewrite add structure, tiers, callbacks, config
  fields, or abstractions **beyond** the recommendation? (The round-1 failure
  mode was an invented fourth dispatch tier — check specifically that nothing
  analogous reappeared.)

Produce a per-item verdict: APPLIED / PARTIAL / MISSING / OVER-APPLIED, with
the exact location.

**Plus the namespace relocation (Stage 2).** `recommendations_1.md` has a
separate "Namespace isolation — relocate the new API under `compy.input.*`"
section. Check that it was applied as a clean pass:
- every *new* feature-#77 `compy.X` name (including the Item 1 cursor/text
  functions) now reads `compy.input.X` consistently across `design.md`,
  `spec.md`, `roadmap.md`, and the summaries — no stragglers left as flat
  `compy.X`;
- the legacy globals (`input_text`, `input_code`, `validated_input`,
  `user_input`, `write_to_input`) were **not** moved;
- `keys_pressed` was left global (`compy.keys_pressed`), not reparented under
  `compy.input` (it is raw keyboard state, not the input-manipulation layer);
- nothing *outside* the recommendation's scope table was renamed.
Verdict: APPLIED / PARTIAL / MISSING / OVER-APPLIED, with locations.

### Part B — Provenance and traceability (new this round)

- Does `decisions.md` (and its summary) carry a top-of-file status note stating
  the whole file is a local proposal derived from `input.md`, pending one
  eventual stakeholder approve/veto — i.e. nothing here is stakeholder-signed?
- Are this round's new/changed decisions tagged with a consistent,
  greppable round-1 provenance marker, so the delta since the prior round is
  auditable?
- Are genuinely new architectural commitments (e.g. Item 4 native-handler
  coexistence; Item 6 channel model; Item 1 restored FR-8/9/10; Item 7 combo
  canonical form) surfaced as decisions, not buried only in derived docs — so
  the eventual stakeholder review can focus on the real choices?
- Does `requirements.md` still faithfully trace `input.md` (it was not edited
  this round; confirm no downstream change silently contradicts it)?

### Part C — The original seven dimensions (re-run against the new chain)

Re-check, because the documents changed:

1. **Requirements coverage** — every FR/NFR traced
   decisions→design→spec→roadmap. Confirm FR-8/9/10 are now carried through
   (they were the headline gap). Flag any requirement that still drops out.
2. **Decision consistency** — each decision (now including any new D-8…D-N)
   reflected consistently in design/spec; no later doc silently contradicts it.
3. **Design-to-spec completeness** — every design component has a precise spec
   contract (signatures, return values, wrong-state/edge behaviour).
4. **Spec-to-roadmap coverage** — every spec item has a milestone home, plus
   documentation and test coverage. Confirm the previously-missing homes now
   exist (`compy.show`/`hide` exposure; cursor/live-write surface;
   `write_to_input` facade).
5. **Roadmap ordering validity** — each milestone testable before the next.
   Confirm the M2/M6 `oneshot`/submit ordering defect is resolved and M2's
   "zero behaviour change" / M3's "all examples work" now hold.
6. **Factual accuracy against codebase** — re-verify the round-1 fixes landed
   factually: `cancel()` does not push `'userinput'` today (Escape doesn't
   dismiss); `oneshot` is a `UserInputModel` field; stop-time reset is
   `stop_project_run`/`clear_user_handlers`, not `evacuate_required`; native
   `love.keypressed` slot interception (`hook_if_differs`) is described
   correctly. Flag any remaining mismatch.
7. **Summary fidelity** — each `summaries/*.md` faithfully represents its
   (now edited) source; no claim present in a summary but absent/contradicted
   in the full document; confirm the orphan Escape opt-in remark was removed
   from `summaries/design.md`.

### Part D — New conflicts and residue

- Did applying the resolutions introduce any **new** cross-document
  contradiction the recommendations didn't foresee?
- Adjudicate the rewrite's own open-questions list (in `changelog_1.md`): for
  each, is leaving it open acceptable, or does it block implementation?
- Are there any items the recommendations marked "future seam / not built"
  (e.g. overloadable matcher expansion, text-command-set prefix matching) that
  the rewrite wrongly treated as in-scope, or that need a tracked note?

---

## Already spotted inconsistencies

These are manual notes from the architect after review of summaries 
after validation/correction round 1 was finished.

1. Spec and design used `compy.*` instead of `compy.input.*` in few places 
   (when speaking of handlers and new API);
     it was fixed manually in summaries but not propagated back to full variants of docs
2. Roadmap was rewritten/adjusted but apparently not reestimated since take 1 -- 
   need reestimation
3. Across decisions/design its not emphasized sufficiently that processing of `on_text_input` 
   is supposed to follow exactly same principles as with `keypressed`
4. During design sessions there was an idea to augment both `keypressed` and `text_input` 
    with optional `mods` string that tells consumers which modifiers were pressed currently,
    and is passed as a trailing optional argument to all downstream handlers, callbacks etc.
    (rationale: even key combos handlers may need this information (e.g. if same handler 
                is attached to multiple combos it needs to understand the context); 
                let alone callback which fires after combo handlers are processed -- 
                it often may need to know the context; )
    But it seems that this idea was not reflected in decisions/design (or at least
5. Its suspicious that assessment and decisions still operate same seven 'blocking points' 
   which were recognized initially before validation session 1:
    -- either initial analysis was good enough, 
       or controversies and resolutions discovered during validation round 1 are minor enough 
          to not be promoted to decision points for review/endorsement/veto by stakeholders
       or such controvercies and resolutions were simply omitted from documentation update plan by mistake
6. In spec and roadmap its worth mentioning they are derivative documents pre-built in assumption 
    for the scenario when proposed design is endorced, not vetoed. 
    Also, spec may include explicit disclaimer that it's a part of proposal chain,
    not every detail is set in stone, and it's part *could* be reviewed or changed by stakeholders 
    without blocking implementation (no requirement to fully freeze it before work starts, we're startup)

---

## Output format

Produce a structured report at the path given above. Use this structure:

```
# Validation Report 2 — Feature #77 Document Chain (post-rewrite)

## Status: PASS / PASS WITH NOTES / FAIL

## Part A — Rewrite faithfulness (per recommendation item)
[Item 1..10: APPLIED / PARTIAL / MISSING / OVER-APPLIED, location, note]

## Part B — Provenance integrity
[findings]

## Part C — Seven dimensions
### 1. Requirements coverage
### 2. Decision consistency
### 3. Design-to-spec completeness
### 4. Spec-to-roadmap coverage
### 5. Roadmap ordering validity
### 6. Factual accuracy
### 7. Summary fidelity

## Part D — New conflicts and open questions
[findings + adjudication of the changelog's open questions]

## Summary of actionable items
[numbered; if any remain, they block implementation]

## Recommendation
[Ready for stakeholder review / Needs another local pass / Needs codebase check]
```

Distinguish severity clearly: a missing FR is blocking; a stale combo example
in one summary is a note. If the chain is now coherent and faithful, say so
plainly — "PASS WITH NOTES" is a valid and likely outcome if only minor
residue remains. If new blocking issues exist, a `validation/recommendations_2.md`
may be warranted; recommend it but do not write it unless asked.

Be specific. "Item 4 applied" is not useful. "Item 4 applied in `design.md §2`
and `spec.md §6`; the legacy heuristic gate is described, but
`summaries/design.md` still shows the old unconditional `ProjectController`
slot ownership without the auto-provisioning note" is useful.
