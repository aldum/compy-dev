# Re-evaluation Round 1 — Stakeholder feedback: D-1 discarded

*Date: 2026-06-06. Input: `input.md` "FEEDBACK AFTER FIRST ITERATION",
commit `de5d781` ("stakeholders feedback round 1"). This re-evaluation
answers prompt 8: can the chain be updated unambiguously, without further
direction?*

---

## The feedback, in one line

**D-1 (backward compatibility) is DISCARDED by stakeholder consensus.** No
backward compatibility is to be maintained for the input API. Get rid of the
legacy API; migrate the examples; pre-1.0, so a clean break is acceptable.

This is now **stakeholder ground truth** (it lives in `input.md`), not a local
proposal. It overrides the previous "Suggested decision" for D-1 (keep
backward-compatible facades).

## Verdict

**Yes — the chain can be updated unambiguously, and it has been** (changelog:
`changes1.md`). Two follow-on points are *explicitly delegated to the owner by
the feedback itself*, so they are recorded as such rather than treated as
blocking questions for me to resolve. No item required guessing.

## Why it is unambiguous

The feedback is a clean discard of one decision, with the blast radius bounded
by the stakeholders in the same conversation. Three things pin it down:

1. **What is removed is named.** D-1's scope was always exactly the four
   text-input functions (`input_text`, `input_code`, `validated_input`,
   `user_input`) plus `write_to_input`. "Get rid of the legacy API" maps
   directly onto removing those five globals and the reftable/polling idiom
   that goes with them. No facade layer, no `strict_input` flag, no deprecation
   shim — those existed only to *support* backward compat, which is now gone.

2. **What is *not* removed is named too.** The exchange
   *"This won't break all keyboard input, only text fields? — Only text fields."*
   bounds the break to text input. The native `love.keypressed`/`textinput`
   coexistence path (D-9) is a **separate** surface; it must survive, because if
   it didn't, *all* keyboard input for games would break, contradicting "only
   text fields." So the feedback does not merely leave D-9 alone — it
   **reinforces** it. D-9 is what makes the stakeholders' own guarantee true.

3. **Migration scope is given, with the discretion explicitly delegated.**
   - Priority (release-pressured): `maze`, `balloons`, and `tixy` (the showcase
     set the owner named). `maze` is not in this repo yet; `balloons` and `tixy`
     are.
   - "For all the other examples, we can just exclude them from the next
     release, if we don't have the time to convert them." → the convert-or-
     exclude call for `repl`, `guess`, `valid`, `turtle` is **the owner's, at
     release time** — not a question I need to settle. Recorded as such.

## Grounding against the codebase

In-repo examples using the legacy text-input functions (these are the ones the
removal affects):

| Example | Uses | Disposition under M8 |
|---|---|---|
| `tixy` | `input_code`, `write_to_input`, `user_input` | **Priority** — migrate |
| `balloons` | `input_text`, `user_input` | **Priority** — migrate |
| `repl` | `input_text`, `user_input` | Convert (trivial) or exclude |
| `guess` | `validated_input`, `user_input` | Convert (trivial) or exclude |
| `valid` | `validated_input`, `user_input` | Convert or exclude |
| `turtle` | `input_text`, `user_input`, **+ native `love.keypressed`** | Text-input use migrates; movement keys keep working via D-9 |

Examples using only native `love.keypressed`/`love.textinput` —
`pong`, `life`, `paint`, `sapper`, `sine`, `clock`, `drawdebug` — are
**unaffected** (D-9 coexistence; "only text fields" break). `maze` is named by
the stakeholders but is not in the repo; it is migrated on arrival.

## The one judgment call, and why it needs no resolution

Removing the legacy functions and migrating examples are not independent: you
cannot rewrite the examples to the new API until that API exists in full
(config with validator/highlighter, the submit/cancel callbacks, `set_text`
and the cursor surface). So the removal+migration work **must** come after the
last API milestone. The roadmap therefore puts it in a new final **M8**, after
M7. The only thing left "open" is whether to leave the text-input examples
non-running on the in-development build *earlier* than M8 — and that has no
bearing on the deliverable (the end state is identical, the work is unreleased,
and old releases remain available per `input.md`). So no stakeholder decision
is needed; the dependency order forces the outcome.

## Notable second-order effect

Discarding backward compatibility **increased** the effort estimate, it did not
reduce it. The ≈ 4 h facade layer (old M3) is replaced by a larger ≈ 8 h M8
(removing the globals + rewriting the example corpus). Project PERT moves from
≈ 59 h → **≈ 63 h** without LLM assistance, and ≈ 35 h → **≈ 37 h** with. This
is worth surfacing to stakeholders: "no backward compat" is the right call for
a clean pre-1.0 API, but it is not a shortcut — it trades a small compat shim
for a larger one-off migration.

## Authority-tier shift

D-1 has moved from *local proposal* to *stakeholder-decided*. The status notes
on `decisions.md` and `summaries/decisions.md` now carve D-1 out as ground
truth; D-2…D-10 remain a local proposal awaiting the single approve/veto review.
`requirements.md §5`'s "backward compatibility" open question is marked
**RESOLVED (clean break)**.

## What was changed

See `changes1.md` for the file-by-file changelog. In short: `decisions.md` (D-1
rewritten as a stakeholder ruling; D-8/D-9/D-10 reconciled), `requirements.md`
(§5 resolved), `design.md` (§6 "Legacy API Removal"; §5/§7 reftable wording),
`spec.md` (§5 "Legacy API Removal"; §1/§3/§7 reftable wording), `roadmap.md`
(M3 voided, M8 added, estimates recomputed), all affected `summaries/*`, and
`README.md`.

## Not touched (deliberately)

- `assessment.md` — describes the *current* architecture and the gaps; its
  reftable/polling references are factual descriptions of today's code and
  remain correct. It takes no backward-compat stance, so nothing to change.
- `notes/*` — supporting analysis (reference, not chain authority). They still
  describe the facade approach and are now **stale on D-1**; flagged here rather
  than rewritten, since they are the historical record of the analysis. Re-sync
  on request: `notes/decisions.md` (D-1 section), `notes/solution_sketch.md`
  (§2a "Legacy API compatibility"), `notes/design.md` ("Backward-compatibility
  shims").
- `validation/*` — historical review artifacts; left as the audit trail.

## Where we are

The chain is internally consistent again and reflects the stakeholders' D-1
ruling end to end. Remaining stakeholder action is unchanged from before: a
single approve/veto pass over the **D-2…D-10** proposal set (D-1 is now
settled). The build plan is M1→M8; nothing in the update blocks implementation
from starting on M1.

Open, owner-delegated (not blocking): the convert-or-exclude release call for
`repl`/`guess`/`valid`/`turtle`, and the arrival/migration of the out-of-repo
`maze` showcase.
