# Feature #77 — Changelog for Round-2 Recommendations

*Records every change applied against `validation/recommendations_2.md`
(itself derived from `validation/validation_report_2.md`, which returned
PASS WITH NOTES). Round 2 closes consistency residue and provenance/packaging
gaps; no round-1 blocker reopened. Applied 2026-06.*

---

## Item 1 — `noop+log` vs `sink` default contradiction

**Changes:**

- `design.md §2` — routing diagram: `compy.input.on_key_pressed`
  annotation changed from `default: noop+log` to `default: sink`.
- `spec.md §3` — intro reworded: the submit/cancel/limit callbacks default to
  a no-op + debug log; the two channel callbacks (`on_key_pressed`,
  `on_text_entered`) default to the text-editing sink.
- `summaries/spec.md` — callbacks note rescoped to match.

**`decisions.md` entry:** none (mechanical alignment to D-3 / Item 3 round 1).

---

## Item 2 — Namespace surfaced as a decision; `decisions.md` naming made consistent

**Changes:**

- `decisions.md` — added **D-10** (namespace isolation under `compy.input.*`):
  full per-decision entry (Question / Context / Affects / Source / Decision)
  plus a quick-reference row; updated the "blocking decisions" intro to note
  D-8/D-9 (round 1) and D-10 (round 2) as recorded-but-not-new-question
  decisions.
- `decisions.md` + `summaries/decisions.md` — relocated all new feature-#77
  API names from flat `compy.X` to `compy.input.X` (names only, no substance
  change), via a targeted rename. `compy.keys_pressed` and the legacy globals
  were not touched. This **reverses round 1's narrow exclusion of
  `decisions.md` from the namespace pass** (which had left the file flat with a
  single leaked `compy.input.handlers`); the chain now reads `compy.input.*`
  uniformly.
- `summaries/decisions.md` — added the D-10 glance row and the intro note.

**`decisions.md` entry:** D-10 (new). Origin: local design round 1 namespace
pass, 2026-06; recorded as a decision in round 2.

---

## Item 3 — Roadmap re-estimate (proper 3-point PERT)

**Changes:**

- `roadmap.md §Estimates` — replaced the two-point tables (Optimistic /
  Realistic, where "PERT" collapsed to the most-likely because only two points
  were supplied) with **genuine three-point estimates** per line: Optimistic,
  Most-likely, Pessimistic, plus a per-row and project PERT = (O + 4M + P) / 6.
  Scope updates from round 1 are reflected in the most-likely/pessimistic
  figures (M6 `oneshot` deletion, M7 cursor surface + model fix, M3
  `write_to_input`, M2 `result` setter + `compy.input` table, larger test
  surface). New project PERT: **≈ 59 h** without LLM (O=32, M=58, P=89),
  **≈ 35 h** with LLM (O=19, M=34, P=54). The internal estimate-revision
  history narrative was removed (validation rounds are not stakeholder-facing).
- `summaries/roadmap.md` — "Estimates at a glance" updated to ≈ 59 h / ≈ 35 h
  with a note that the figures are three-point PERT.

**`decisions.md` entry:** none (estimates are not decisions).

---

## Item 4 — `mods` modifier-string idea adjudicated (future seam)

**Changes:**

- `decisions.md` D-6 — added a "Channel symmetry" paragraph and a round-2
  "Future seam — `mods` string (not built in v1)" note: v1 ships the
  `keys_pressed` proxy only; the pre-folded `mods` string is recorded as a
  candidate addition paired with the matcher / text-command-set seams, and
  **flagged for architect confirmation** (build in-scope vs. leave as a seam).
- `spec.md §3` — added a matching "Future seam" italic note under
  `on_text_entered`.

**`decisions.md` entry:** D-6 annotated (round-2 origin marker). Not built;
see Open Questions.

---

## Item 5 — Derivative/proposal-chain disclaimers

**Changes:**

- `spec.md` — added a "Status — derived proposal document" header note
  (pre-built assuming endorsement; detail not frozen; reviewable without
  blocking implementation).
- `roadmap.md` — added the matching header note (milestone boundaries and
  estimates provisional).

**`decisions.md` entry:** none (documentation-status note).

---

## Item 6 — Minor consistency cleanups

**6.1 — decisions intro count + body markers:**
- `decisions.md` — intro reconciled with the actual D-1…D-10 set (see Item 2).
- `decisions.md` D-3 — added a "(original — superseded in part; see the round-1
  annotation below…)" lead-in on the suggested-decision body, so the
  four-tier/alphabetical/`_on_key_pressed` body text is not read as current.
- `decisions.md` D-6 — the body already carried "Suggested decision
  (original)" + "Superseded"; reinforced by the Item-4 channel-symmetry note.

**6.2 — assessment §8 co-occurrence re-pointed:**
- `assessment.md §8` — added a closing paragraph noting the modifier+character
  co-occurrence was resolved by D-6's round-1 supersession (both channels fire
  independently; no exclusivity); the paragraph now records the original gap
  rather than reading as unresolved.

**6.3 — design §3 table wording:**
- `design.md §3` — `compy.input.on_key_pressed` description changed from
  "Generic non-character key callback" to "Generic keypressed callback (fires
  for all keys; default = sink)"; `on_text_entered` row notes "default =
  textinput sink".

**6.4 — textinput-mirrors-keypressed symmetry:**
- `design.md §4` — expanded the one-line textinput note into an explicit
  same-principle statement (default-sink/override identical; the only
  difference is no combo tier).
- `spec.md §3` — added a "Default value: the textinput sink" block to the
  `on_text_entered` section, mirroring `on_key_pressed`.
- `decisions.md` D-6 — "Channel symmetry" paragraph (see Item 4).

---

## `decisions.md` Entries and Provenance Tags (round 2)

| ID | Type | Provenance |
|---|---|---|
| D-10 (new) | Decision: namespace isolation under `compy.input.*` | Origin: local design round 1 namespace pass, 2026-06; recorded as a decision in round 2. Item 2. |
| D-6 (annotated) | Note: channel symmetry; `mods` string future seam | Origin: local design round 2, 2026-06. Item 4. |
| D-3 (annotated) | Marker: original body superseded in part | Round 2 editorial; no new decision. Item 6.1. |

Round-2 marker used: *(Origin: local design round 2, 2026-06. See
`validation/recommendations_2.md` Item N.)*

---

## Open Questions for Re-Review

1. **`mods` trailing modifier-string (Item 4) — architect decision needed.**
   Recorded as a future seam in `decisions.md` D-6 and `spec.md §3`, **not
   built**. The design-session idea was to pass a pre-folded generic
   modifier descriptor as a trailing argument to every downstream
   handler/callback (`on_key_pressed`, `on_text_entered`, `handlers[combo]`
   entries, `ProjectController:keypressed`/`:textinput`). v1 ships the
   `keys_pressed` proxy only (modifiers derivable from it). Left open because
   building it expands every downstream signature — that is new API surface, a
   scope decision for the architect, not an executor alignment. If wanted
   in-scope, it is a `recommendations_3` item; if not, the seam note stands.

2. **`decisions.md` relocation reverses a round-1 scoping choice (Item 2) —
   confirm acceptable.** Round 1 deliberately excluded `decisions.md` from the
   `compy.input.*` pass; round 2 relocated it for chain-wide consistency and
   recorded the namespace as D-10. If the intent was to keep `decisions.md` in
   pre-relocation terms, this is reversible — but the report flagged the split
   (flat `decisions.md` vs `compy.input.*` derived docs) as a finding, so
   relocation is the resolution that removes it.

No other item was left open; Items 1, 3, 5, and 6 are mechanical alignment
with no ambiguity.
