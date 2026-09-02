# Check 1 — Validation of the round-1 re-evaluation

## Change in brief — stakeholder Q&A

*Plain-language read on the round-1 change and whether it is safe to proceed.
The two cosmetic doc fixes this review raised were applied at the owner's
explicit request (2026-06-06) — see "Summary of actionable items", now resolved.*

**1. Any architectural regression from applying the decision?**
Confirmed — none. The feature itself is unchanged (same callback API), the
native keyboard path still stands, so only text fields are affected, and nothing
new was invented to work around the removal. The architecture holds; only the
plan moved.

**2. Does the price, risk, or order change?**
As expected, only the plan shifts, not the design:
- **Price:** up a little — ≈ 59 → ≈ 63 h (≈ 35 → ≈ 37 h with LLM). Rewriting the
  examples costs a bit more than the throwaway wrappers it replaces. Figures
  checked against `changes1.md`.
- **Order:** as presumed — the wrapper step is gone; the new API is built first
  and the examples are ported at the very end, once it exists.
- **Risk:** the example rewrite lands late, so an API gap would show up late —
  but it's bounded. The pessimistic estimate already allows for it, a stubborn
  example can be left out of the release rather than block it, and the API was
  already shown able to rebuild the console and editor, so the rewrites should
  be mechanical. Testing isn't deferred: every step is checked as it lands, and
  a budgeted test workstream (≈ 11 h, ≈ 6 h with LLM) now covers the rewrite too.

**3. What's the new plan?**
Build the new API first, then a final step that removes the old calls and ports
the examples — `tixy` and `balloons` for the release, the rest convert or leave
out if there's no time. Nothing breaks in the meantime: the old examples keep
running until that last step. The updated build plan and the ≈ 63 h / ≈ 37 h
estimates are in `summaries/roadmap.md`.

---

*Validates the round-1 re-evaluation (D-1 discarded) recorded in
`reevaluations/{outcome1,round1,changes1}.md` against the committed chain.
Re-evaluation commit: `c94fb57` ("reevaluation round1 …"). Evidence taken from
`git show c94fb57`, the live docs, and the `src/examples/` tree. Tone per
`agents/rules.md`: matter-of-fact, no blame — this is a faithful, well-scoped
cleanup; the two minor doc nits found were fixed this pass.*

## Status: PASS (the two notes below were fixed this pass)

The ruling (D-1 DISCARDED) is applied end to end. The five legacy globals are
removed (not wrapped) everywhere it matters; no `strict_input`, deprecation, or
project-facing reftable/polling idiom survives in the live chain; D-9 is intact
and reinforced; milestone numbering and cross-references resolve; both estimate
tables recompute exactly to the printed `≈ 63 h` / `≈ 37 h`. The two NOTE-level
items found (a stale D-8 glance-table cell in `summaries/decisions.md` and a
loose M8 dependency header in `roadmap.md`) were corrected this pass at the
owner's request; details below.

---

## Part A — Edit faithfulness (per `changes1.md` item)

**`decisions.md`** — all six claimed edits APPLIED:
- Top status note carves out D-1 as stakeholder-decided ground truth, D-2…D-10
  proposal — APPLIED (lines 3–11).
- "Approach in brief" point 3 retitled to "The legacy text-input API is
  removed", removal + migration + text-input-only scope — APPLIED (lines 134–149).
- Quick-ref table: D-1 → "Discarded …", D-8 → "`set_text` supersedes the removed
  `write_to_input`", D-10 → "removed" — APPLIED (lines 153, 160, 163).
- D-1 per-decision detail replaced "Suggested decision (keep facades)" with the
  stakeholder ruling (five globals removed, reftable/polling gone, M8 migration,
  text-input-only scope, D-9 separate) — APPLIED (lines 192–217).
- D-8 detail: `write_to_input` removed not facade; `tixy`→`set_text`; cursor
  surface M7, removal+migration M8 — APPLIED (lines 529–546).
- D-9 detail: clarified D-9 is a *separate* surface, retained, keeps "only text
  fields break" true; "Affects" updated — APPLIED (lines 562–575).
- D-10 detail: "Unchanged — legacy globals" → "Removed — legacy text-input
  globals"; no legacy call-target left — APPLIED (lines 640–650).

**`requirements.md §5`** — "Backward compatibility" bullet marked **RESOLVED
(clean break)**, cites `input.md` round 1, bounded to text input, pointer to
D-1 — APPLIED (lines 150–159).

**`design.md`** — all claimed edits APPLIED: §3 `after_submit` row "after
evaluation (receives the result)" (165); §5 Enter flow drops "fill reftable"
(261); §6 retitled "Legacy API Removal", facade/deprecation/`strict_input` text
replaced with removal + migration, `love.state.user_input` plainly set/cleared,
**Native handler coexistence subsection kept** (285–331); §7 implementation-order
table drops "Legacy facades", adds "Legacy removal + example migration" last,
renumbers steps and notes the M1–M8 mapping (334–356); §7 FR-11 Enter row
"evaluate + push + `after_submit`" (375). OVER-APPLICATION check: no new API
surface, dispatch tier, or callback invented — the §7 step renumber (old step 3
removed → six steps) is a description change, explicitly reconciled with the
roadmap's M1–M8 numbering in the same paragraph. Clean.

**`spec.md`** — all claimed edits APPLIED: §1 drops "legacy wrappers" from
`keys_pressed` consumers (43); §3 `after_submit` drops "filled the reftable"
(305–310); §5 retitled "Legacy API Removal", rewired-functions table → removed →
replacement table, deprecation/`strict_input` subsections gone,
`love.state.user_input` note kept without "transition" framing (357–387); §7
edge case drops the "reftable … stays empty" line (450–451).

**`roadmap.md`** — all claimed edits APPLIED (detail in Part C): M2 setter line
removed (66–69); M3 voided with numbering kept (78–93); M4 input "M3" → "M2"
(101); M6 reftable lines removed (163–164, 184); M7 `write_to_input` clause
removed, `set_text` supersedes note added (205–208); M8 added (223–270);
Test-coverage bullet → "Example migration (M8)" (294–300); both estimate tables
recomputed with M3 dropped / M8 added + the "raised the estimate" note.

**`summaries/decisions.md`** — status note + "Legacy text-input API removed"
paragraph + D-1/D-10 glance rows APPLIED (lines 7–11, 148–155, 169, 179).
**PARTIAL:** `changes1.md` claims only "D-1 and D-10 rows updated" for the
glance table — and indeed the **D-8 glance row (line 177) was left untouched**
and still reads "`write_to_input` facade", while the full `decisions.md` D-8 row
(line 160) was updated to "`set_text` supersedes the removed `write_to_input`".
So the changelog is internally honest, but the omission leaves the summary's
glance table inconsistent with its source. See Note 1.

**`summaries/design.md`** — "what this adds" facade sentence → removal +
migration; components row "Legacy wrappers … facades" → "Legacy text-input
globals … removed; examples migrate; D-9 retained" — APPLIED (lines 12–18, 99).

**`summaries/spec.md`** — "Legacy API" → "Legacy API — removed" with removed →
replacement table, no deprecation/`strict_input`; `after_submit` row "receives
the result" — APPLIED (lines 93, 119–134).

**`summaries/roadmap.md`** — M3 row *(removed)*, M8 row added, Test-coverage row
updated, totals `≈ 63 h` / `≈ 37 h` + "raised the total" note — APPLIED.

**`README.md`** — TL;DR "Old functions keep working" → removal + migration +
text-input-only scope; effort "(~35–59 h)" → "(~37–63 h)" — APPLIED.

**Not-changed set honoured.** `assessment.md` untouched (not in the commit);
its reftable references describe *today's* code and are correct, not stragglers.
`notes/*` and `validation/*` untouched — historical record, as stated.

---

## Part B — Cross-document consistency

- **D-1 ruling reads the same everywhere.** "Discarded — no backward
  compatibility; five globals removed; `tixy`/`balloons` priority migration;
  others convert-or-exclude at the owner's call; text-input-only; D-9 separate"
  appears consistently in `input.md`, `requirements.md §5`, `decisions.md` D-1,
  `design.md §6`, `spec.md §5`, `roadmap.md M8`, and all four summaries.
- **Removed-functions table matches** between `spec.md §5` and
  `summaries/spec.md` (same five functions, same replacements, both note
  "no `strict_input`").
- **Milestone table matches** between `roadmap.md` and `summaries/roadmap.md`
  (M1, M2, M3 *(removed)*, M4, M5, M6, M7, M8).
- **Estimate figures match** across `roadmap.md`, `summaries/roadmap.md`
  (`≈ 63 h` / `≈ 37 h`) and `README.md` (`~37–63 h`).
- **Milestone numbering / dangling refs.** Every `Mx` reference in the live
  chain resolves (counts: M1×8, M2×16, M3×7, M4×12, M5×11, M6×16, M7×14,
  M8×24). All seven `M3` mentions describe it as removed/voided/historical
  ("the original M3 built facade wrappers", "the removed M3 was never a
  dependency", "old M3 facade layer"); there is **no live reference to M3
  facades as if they still exist**. M4's dependency was corrected to "M2
  complete", consistent with the void.
- **D-8 / D-10 reconciled with the discard.** D-8 prose, D-10 prose, and the
  D-10 "Affects" line all now state the globals are removed and that no legacy
  call-target remains — they no longer contradict the discard.
- **Stragglers (negation contexts are correct, not findings).** Every surviving
  "facade"/`strict_input`/deprecation/reftable mention in the live chain is
  either a negation ("not wrapped as facades", "no `strict_input` flag", "the
  reftable / polling idiom is gone"), a description of the voided M3, or the D-9
  lifecycle-split *wrapper* (a different surface). The lone exception is Note 1.

### Note 1 (the only consistency defect)
`summaries/decisions.md:177`, D-8 glance row, still ends "`write_to_input`
facade". Its own full doc (`decisions.md:160`) reads "`set_text` supersedes the
removed `write_to_input`". A reader skimming only the summary glance table sees
a "facade" that the discard removed. Severity **NOTE** (a stale wording cell in
one summary; the D-1 row directly above it and the D-8 prose are both correct).
**Fixed this pass** (owner request): the cell now reads "`set_text` supersedes
the removed `write_to_input`", matching the full doc.

---

## Part C — Roadmap consistency and ordering

**Dependency order — walks clean.**
- M1 — Input: nothing. ✓
- M2 — Input: M1 (keys_pressed exists). ✓
- M3 — void (no Input line; explained empty slot). ✓
- M4 — Input: M2 (was "M3 complete"; corrected, with an explicit note that the
  removed M3 was never a functional dependency). ✓
- M5 — Input: M4. ✓
- M6 — Input: M4 (M5 independent). ✓
- M7 — Input: M2 (M5/M6 not required — additive surface extension). ✓
- M8 — Input: M7, body enumerating M2 + M6 + M7. ✓ (see ordering note below)

**M8 ordering is correct and cannot be pulled earlier.** M8 needs the
submit/cancel callbacks (M6) and `set_text`/cursor (M7); the later of those two
prerequisites is M7 (M2-rooted) alongside M6 (M4-rooted), so M8 must follow
*both* M6 and M7. Placing it last satisfies that. It could not be ordered
earlier without losing a dependency. **Minor wording note (NOTE):** M8's
one-line header says "Input: M7 complete", but M7 itself does *not* depend on M6
(M7 needs only M2). So "M7 complete" does not transitively guarantee M6 is done
— the genuine dependency set is M2 + M6 + M7, which the M8 body correctly spells
out. Because M8 is the final milestone in a linear M1→M8 build, M6 is always
complete by then in practice, so this is a precision nit in the header, not an
ordering break. **Fixed this pass**: the header now reads "Input: M6 and M7
complete."

**Migration scope is grounded** (re-verified against the tree):
`grep -rln -E 'input_text|input_code|validated_input|user_input|write_to_input'
src/examples/` returns exactly six examples with text-input use —
`tixy`, `balloons`, `repl`, `valid`, `turtle`, `guess`. This matches the
roadmap/round1 classification:
- **Priority:** `tixy` (`input_code` + `write_to_input` + `user_input`),
  `balloons` (`input_text` + `user_input`) — confirmed per-function. ✓
- **Convert-or-exclude:** `repl`, `guess`, `valid` (trivial), `turtle`. ✓
- **`turtle` is the mixed case** — confirmed it has `love.keypressed`
  (`src/examples/turtle/main.lua:35`) alongside `input_text`/`user_input`; the
  roadmap correctly says the text-input use migrates while movement keys keep
  working under D-9. ✓
- **`maze`** named by stakeholders but **not in the repo** — confirmed absent;
  correctly marked "migrate on arrival". ✓
- **Unaffected (native-only):** `pong`, `life`, `paint`, `sapper`, `sine`,
  `clock`, `drawdebug` — confirmed **none** call any of the five functions. ✓
  No example is mis-classified.

**No regression of earlier roadmap invariants.**
- M2 still "zero behaviour change" (singleton created once; existing examples
  and tests pass; `oneshot` explicitly stays through M2–M5). ✓
- `oneshot` deletion still in **M6** (`roadmap.md` M6 output + `userInputModel.lua`
  file list; mirrored in `summaries/roadmap.md`), not earlier. ✓
- M7 still carries the cursor/`set_text` surface **and** the
  `UserInputModel:set_text` `keep_cursor` model fix ("skip unconditional
  `jump_end()`", `roadmap.md:213–214`). ✓
- D-9 (native coexistence) retained as a separate surface in `design.md`
  ("Native handler coexistence" subsection) and `spec.md §6`; reinforced, not
  weakened, in `decisions.md` D-9. ✓

---

## Part D — Estimates, recomputed from scratch

Recomputed every row as `PERT = (O + 4M + P) / 6`, summed O/M/P independently,
and recomputed the project-level PERT. No anchoring on prior figures.

### Without LLM
| Row | O | M | P | PERT (recomputed) | Printed |
|---|---|---|---|---|---|
| M1 | 2 | 3 | 4 | 3.00 | 3.0 ✓ |
| M2 | 3 | 6 | 9 | 6.00 | 6.0 ✓ |
| M4 | 4 | 8 | 14 | 8.33 | 8.3 ✓ |
| M5 | 3 | 5 | 8 | 5.17 | 5.2 ✓ |
| M6 | 4 | 7 | 11 | 7.17 | 7.2 ✓ |
| M7 | 3 | 6 | 9 | 6.00 | 6.0 ✓ |
| M8 | 4 | 8 | 14 | 8.33 | 8.3 ✓ |
| Documentation | 4 | 8 | 12 | 8.00 | 8.0 ✓ |
| Test coverage | 7 | 11 | 16 | 11.17 | 11.2 ✓ |

Column sums: O = 34, M = 62, P = 97 — match the printed totals row.
Project PERT = (34 + 4×62 + 97) / 6 = 379/6 = **63.17 h → ≈ 63 h** (matches).
Sum of per-row PERTs = 63.2 h (consistent).

### With LLM
| Row | O | M | P | PERT (recomputed) | Printed |
|---|---|---|---|---|---|
| M1 | 1 | 2 | 3 | 2.00 | 2.0 ✓ |
| M2 | 2 | 4 | 6 | 4.00 | 4.0 ✓ |
| M4 | 3 | 5 | 9 | 5.33 | 5.3 ✓ |
| M5 | 2 | 3 | 5 | 3.17 | 3.2 ✓ |
| M6 | 2 | 5 | 8 | 5.00 | 5.0 ✓ |
| M7 | 2 | 4 | 6 | 4.00 | 4.0 ✓ |
| M8 | 2 | 4 | 8 | 4.33 | 4.3 ✓ |
| Documentation | 2 | 3 | 5 | 3.17 | 3.2 ✓ |
| Test coverage | 4 | 6 | 9 | 6.17 | 6.2 ✓ |

Column sums: O = 20, M = 36, P = 59 — match the printed totals row.
Project PERT = (20 + 4×36 + 59) / 6 = 223/6 = **37.17 h → ≈ 37 h** (matches).
Sum of per-row PERTs = 37.2 h (consistent).

**Coverage.** Both tables carry exactly the active milestones (M1, M2, M4, M5,
M6, M7, M8) plus Documentation and Test coverage — nine rows each. **M3 has no
row** in either table (correct — it is void). Nothing double-counted or missing.

**Cross-doc agreement.** `roadmap.md` prints `≈ 63 h` / `≈ 37 h`;
`summaries/roadmap.md` prints `≈ 63 h` / `≈ 37 h`; `README.md` prints
`~37–63 h`. No full-vs-summary mismatch.

**Plausibility, fresh.** The new **M8** (O/M/P 4/8/14, PERT 8.3 h without LLM)
is the only genuinely new estimate this round. Its scope is: delete five
functions from `consoleController.lua` (cheap) plus migrate the example corpus
(the bulk). Six in-repo examples touch the API; two are release-blocking
(`tixy`, `balloons`), four are convert-or-exclude. A most-likely of 8 h for
rewriting roughly six small pedagogical files to the callback API, plus removal
and re-testing, is reasonable; the pessimistic 14 h covers the awkward cases
(`tixy`'s `write_to_input`→`set_text` live-write, `turtle`'s native/text-input
mix). If anything the pessimistic tail is slightly conservative, because the
convert-or-exclude option caps the downside — a stubborn example can be excluded
from the release rather than fought — but 14 h is defensible and the spread is
sane. The M8 = 8.3 h ≈ old-M3 + 4 h delta claimed in the "raised the estimate"
note is internally consistent (old M3 facade was 4.0 h; net +4.3 h before
rounding). With-LLM M8 at 4.3 h (High value) is well-judged: mechanical
small-file rewrites are exactly where LLM assistance pays off. No row reads as
implausible for the scope it now describes.

---

## Summary of actionable items (severity-ranked)

| # | Severity | Location | Item | Status |
|---|---|---|---|---|
| 1 | NOTE | `summaries/decisions.md:177` | D-8 glance-table row read "`write_to_input` facade"; full `decisions.md:160` reads "`set_text` supersedes the removed `write_to_input`". | **FIXED** — cell synced to "`set_text` supersedes the removed `write_to_input`" (owner request, 2026-06-06). |
| 2 | NOTE (optional) | `roadmap.md:230` | M8 header "Input: M7 complete" understated the dependency set (M7 does not require M6, but M8 needs M6's callbacks). Body was already correct. | **FIXED** — header now reads "Input: M6 and M7 complete." (owner request, 2026-06-06). No ordering change — M8 is still the final milestone. |

No blockers: no surviving project-facing facade/`strict_input`/deprecation
plan, no weakened D-9, no broken milestone dependency, no mis-classified
example, no estimate that fails to add up.

## Recommendation

**Ready for stakeholder review.** The substantive re-evaluation landed
faithfully and the chain is internally consistent; the two NOTE-level doc nits
have been corrected this pass (owner request), so no local follow-up remains.
The only open items are the pre-existing owner-delegated calls already recorded
in the chain (convert-or-exclude for `repl`/`guess`/`valid`/`turtle`, and the
out-of-repo `maze`), plus the standing approve/veto pass over the D-2…D-10
proposal set.
