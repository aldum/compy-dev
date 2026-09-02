# Outcome — Re-evaluation Round 1 (D-1 discarded)

*Summary of what round 1 did and where the chain stands. Full conclusions:
`round1.md`. File-by-file changelog: `changes1.md`.*

---

The feedback was unambiguous, so the whole chain was updated. Conclusions are in
`reevaluations/round1.md`; the file-by-file changelog is in
`reevaluations/changes1.md`.

(On file location: prompt 8 specified `./reevaluation/changes<N>.md` (singular);
that directory does not exist, so both files live under the existing
`./reevaluations/`. N = 1 by the formula — the dir was empty — which also
matches the "feedback round 1" commit.)

## The decision

**D-1 (backward compatibility) → DISCARDED** by stakeholder consensus. It is now
ground truth in `input.md`, not a local proposal. The legacy text-input globals
(`input_text`, `input_code`, `validated_input`, `user_input`, `write_to_input`)
are **removed** — no facades, no `strict_input`, no deprecation shim, no
reftable/polling idiom. Examples migrate to `compy.input.*`.

## Why it was unambiguous (no resolution needed from the owner)

1. **What is removed is named** — D-1's scope was always exactly those five
   functions.
2. **What survives is named** — the exchange *"only text fields?" — "Only text
   fields."* bounds the break. The native `love.keypressed` coexistence path
   (**D-9**) is a *separate* surface and must survive; it is literally what makes
   "only text fields break" true. The feedback therefore **reinforces** D-9
   rather than touching it.
3. **The two loose ends are delegated by the feedback itself** — the
   convert-or-exclude call for `repl`/`guess`/`valid`/`turtle` is explicitly the
   owner's ("we can just exclude them… if we don't have the time"), and `maze`
   is not in the repo yet. Recorded as owner-discretion, not blocking.

## Notable second-order effect

Discarding compatibility **raised** the estimate, it did not lower it: the ≈ 4 h
facade layer (old M3) is replaced by a larger ≈ 8 h migration milestone (new
**M8**). Project PERT: **≈ 59 → ≈ 63 h** (no LLM), **≈ 35 → ≈ 37 h** (with LLM).
Worth flagging — "no backward compat" is the right pre-1.0 call, but it is a
one-off migration cost, not a shortcut.

## What changed

- `decisions.md` — D-1 rewritten as a stakeholder ruling; status note carves
  D-1 out as settled (D-2…D-10 still proposal); D-8/D-9/D-10 reconciled.
- `requirements.md §5` — backward-compat open question marked
  **RESOLVED (clean break)**.
- `design.md` / `spec.md` — §6/§5 retitled "Legacy API Removal"; reftable
  wording cleaned in flow diagrams and edge cases.
- `roadmap.md` — M3 **voided** (numbering kept so M4–M7 cross-references stay
  valid), **M8 added**, both estimate tables recomputed.
- All affected `summaries/*` and `README.md` mirrored.
- **Left intact:** `assessment.md` (describes today's code, factually correct),
  `notes/*` (flagged stale-on-D-1 but kept as the analysis record),
  `validation/*` (audit trail).

## Status

Remaining stakeholder action is unchanged: a single approve/veto pass over the
**D-2…D-10** proposal set (D-1 is now settled). Nothing in the update blocks
implementation starting at M1. The build plan is M1→M8 (M3 intentionally empty).

Open, owner-delegated (not blocking): the convert-or-exclude release call for
`repl`/`guess`/`valid`/`turtle`, and the arrival/migration of the out-of-repo
`maze` showcase.
