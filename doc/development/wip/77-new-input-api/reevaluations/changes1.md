# Changelog — Re-evaluation Round 1 (D-1 discarded)

*Applies the `input.md` round-1 stakeholder feedback across the chain.
Provenance marker used in-place: "stakeholder feedback, round 1, 2026-06-06".
Conclusions: `round1.md`.*

> **Note on file location.** Prompt 8 specified `./reevaluation/changes<N>.md`
> (singular). That directory does not exist; `./reevaluations/` (plural) does
> and holds `round1.md`. Both files are kept together here. N = 1 (the
> `reevaluations/` formula count was 0 → 1; also the "feedback round 1" commit).

---

## decisions.md

- **Top status note** — carved out D-1 as stakeholder-decided (DISCARDED)
  ground truth; D-2…D-10 remain local proposal.
- **"The approach in brief" point 3** — retitled from "Existing API continues
  to work" to "The legacy text-input API is removed"; rewrote to describe
  removal + example migration + the text-input-only scope (D-9 unaffected).
- **Quick-reference table** — D-1 row rewritten to "Discarded … legacy globals
  removed; examples migrated/excluded; D-9 unaffected"; D-8 row's
  "`write_to_input` facade" → "`set_text` supersedes the removed
  `write_to_input`"; D-10 row "legacy globals unchanged" → "removed".
- **D-1 per-decision detail** — replaced the "Suggested decision" (keep
  facades) with the stakeholder ruling: removal of the five globals and the
  reftable/polling idiom; example migration (priority `tixy`/`balloons`/`maze`;
  rest convert-or-exclude at owner's call); text-input-only scope; pointer to
  roadmap M8 and to D-9.
- **D-8 detail** — `write_to_input` is removed, not a facade; `tixy` migrates to
  `compy.input.set_text`; dropped the "facade wiring in M3" line; the
  cursor/`set_text` surface stays M7, removal+migration is M8.
- **D-9 detail** — clarified that D-9 is a surface *separate* from the discarded
  D-1, and is retained; it is what keeps the "only text fields break" guarantee
  true. Updated "Affects" accordingly.
- **D-10 detail** — "Unchanged — legacy globals" bullet → "Removed — legacy
  text-input globals"; "Affects" line note that there is no legacy call-target
  left.

## requirements.md

- **§5 Open Questions** — "Backward compatibility" bullet marked
  **RESOLVED (clean break)**, citing the `input.md` round-1 ruling; bounded to
  text input; pointer to `decisions.md` D-1.

## design.md

- **§3 component table** — `after_submit` description "after evaluation and
  reftable fill" → "after evaluation (receives the result)".
- **§5 Enter** — submit step "evaluate → fill reftable → push 'userinput'" →
  "evaluate → push 'userinput'".
- **§6** — retitled "Legacy API Compatibility" → "Legacy API Removal"; replaced
  the facade table / deprecation / `strict_input` text with the removal +
  migration description; `love.state.user_input` now plainly set/cleared by
  show/hide (no "transition" framing). Kept the "Native handler coexistence"
  subsection (D-9).
- **§7** — implementation-order table: removed the "Legacy facades" step;
  added "Legacy removal + example migration" as the last step; rewrote the
  dependency paragraph and noted the M1–M8 milestone numbering.
- **§7 FR-11 walkthrough** — Enter row "evaluate + fill reftable + push" →
  "evaluate + push + `after_submit`".

## spec.md

- **§1** — "legacy wrappers" dropped from the list of `keys_pressed` downstream
  consumers.
- **§3 after_submit** — removed "filled the reftable" wording.
- **§5** — retitled "Legacy API Compatibility" → "Legacy API Removal"; replaced
  the rewired-functions table with a removed-function → replacement table;
  removed the deprecation-warning and `strict_input` subsections; kept the
  `love.state.user_input` note (now without "transition" framing).
- **§7 edge cases** — removed "The reftable (if a legacy wrapper was used)
  stays empty."

## roadmap.md

- **M2** — removed the `result`-repointing setter (facade-only) from the file
  list and the "before M3 facades" phrasing; clarified examples still work at
  M2 because legacy removal is deferred to M8.
- **M3** — **voided**: replaced the facade-wrapper milestone with a note that it
  is superseded by the feedback (no facades); work moved to M8; numbering kept
  to preserve cross-references.
- **M4** — input dependency corrected from "M3 complete" to "M2 complete".
- **M6** — removed the "reftable fill moves onto `after_submit`" line and the
  "Legacy `after_submit` callback fills the reftable" output/risk lines.
- **M7** — removed the "`write_to_input` re-pointed to `set_text`" clause; noted
  `set_text` supersedes the removed `write_to_input` (see M8).
- **M8 (new)** — "Legacy text-input removal and example migration": removes the
  five globals; migrates priority examples (`tixy`, `balloons`; `maze` on
  arrival); convert-or-exclude for `repl`/`guess`/`valid`/`turtle`;
  native-handler examples unaffected (D-9). Depends on M7 (needs the full
  surface).
- **Additional scope / Test coverage** — "Legacy API compatibility" test bullet
  → "Example migration (M8)" bullet.
- **Estimates** — both tables: dropped the M3 row, added the M8 row, recomputed:
  - Without LLM: O/M/P 34/62/97, **PERT ≈ 63 h** (was 59).
  - With LLM: O/M/P 20/36/59, **PERT ≈ 37 h** (was 35).
  - Added a note that discarding D-1 *raised* the estimate (M8 > old M3).

## summaries/decisions.md

- Status note carved out D-1 (DISCARDED) as ground truth.
- "Existing API continues to work (D-1)" paragraph → "Legacy text-input API
  removed (D-1 discarded)".
- Glance table: D-1 and D-10 rows updated (mirroring `decisions.md`).

## summaries/design.md

- "What this feature adds" — facade-wrapper sentence → legacy removal +
  migration sentence.
- Components table — "Legacy wrappers … rewired as facades" row → "Legacy
  text-input globals … removed; examples migrate; D-9 retained".

## summaries/spec.md

- "Legacy API" section → "Legacy API — removed": removed-function → replacement
  table; no deprecation/`strict_input`.
- Callbacks table — `after_submit` "reftable is filled" → "receives the result".

## summaries/roadmap.md

- Milestone table: M3 row marked *(removed)*; added M8 row.
- Test-coverage row updated (M8 example migration instead of legacy compat).
- "Estimates at a glance" totals: **≈ 63 h / ≈ 37 h**; added the
  "discarding D-1 raised the total" note.

## README.md

- TL;DR — "Old functions keep working; nothing existing breaks" replaced with
  the removal + migration + text-input-only-scope summary.
- Summary table — effort "(~35–59 h)" → "(~37–63 h)".

## Not changed (intentional)

- `assessment.md` — current-state/gap analysis; its reftable references
  describe today's code and stay accurate.
- `notes/*` — supporting analysis, now stale on D-1; flagged in `round1.md`,
  not rewritten (historical record).
- `validation/*` — audit trail of prior review rounds; left intact.
