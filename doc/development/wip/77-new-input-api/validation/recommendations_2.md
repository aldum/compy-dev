# Feature #77 — Recommendations (round 2)

*Input for the second fix iteration of the document chain. Distils the
actionable items from `validation/validation_report_2.md` into concrete
resolutions, with severity and per-document targets. The report returned
**PASS WITH NOTES**: the round-1 blockers are closed and faithfully applied;
what remains is consistency residue and provenance/packaging gaps. None drop a
requirement or break an example. This round closes them.*

*Numbering is this round's own (Item 1…6); it does not continue
`recommendations_1.md`'s.*

---

## Document authority model (unchanged from round 1)

`input.md` is the only stakeholder-signed document. `requirements.md` is high
local input and **is not edited** this round (no item requires it). Everything
else — `assessment.md`, `decisions.md`, `design.md`, `spec.md`, `roadmap.md`,
and the `summaries/` — is derived/local and edited freely, with `decisions.md`
edited under the provenance rules (new commitments get fresh IDs continuing the
sequence; corrections annotated in place; every change tagged with a greppable
round-2 origin marker).

Round-2 provenance marker: *(Origin: local design round 2, 2026-06. See
`validation/recommendations_2.md` Item N.)*

---

## Item 1 — Resolve the `noop+log` vs `sink` default contradiction

**Report finding:** N1 / dimension 2. **Severity:** medium — it contradicts the
headline Item-3 (round 1) resolution and, taken literally, would have the
implementor wire the default `on_key_pressed` to a no-op, under which default
text editing (the sink) never runs. **Effort:** trivial (three wording fixes).

### Root cause

Item 3 (round 1) made the *sink* the default value of the two channel
callbacks (`on_key_pressed`, `on_text_entered`). The per-callback spec sections
say so. But three places still carry the pre-Item-3 `noop+log` default — a
residue the dispatch sections corrected but these did not:

- `design.md §2` routing diagram, line ~75:
  `compy.input.on_key_pressed [generic, overloadable, default: noop+log]`;
- `spec.md §3` intro: "Default value for each is a no-op function that emits a
  debug log entry";
- `summaries/spec.md`: "All callbacks default to a no-op + debug log entry."

The `noop+log` default is correct for the **other** callbacks
(`before/after_submit`, `before/after_cancel`, `on_limit_reached`); it is wrong
for the two channel callbacks, whose default is the sink.

### Resolution

Scope the `noop+log` statement to the non-channel callbacks. State the channel
callbacks' default as the sink everywhere:

- `design.md §2` diagram: change the `on_key_pressed` annotation from
  `default: noop+log` to `default: sink`.
- `spec.md §3` intro: reword to "The submit/cancel/limit callbacks default to a
  no-op that emits a debug log entry; the two channel callbacks
  (`on_key_pressed`, `on_text_entered`) default to the text-editing sink (see
  each section below)."
- `summaries/spec.md`: same scoping ("submit/cancel/limit callbacks default to
  no-op + debug log; the two channel callbacks default to the sink").

No decision; this is mechanical alignment to Item 3 (round 1). No
`decisions.md` entry.

---

## Item 2 — Surface the `compy.input.*` namespace as a decision; make `decisions.md` naming consistent

**Report finding:** Part B (provenance) + Part A (namespace). **Severity:**
medium (provenance) — a real architectural commitment is invisible in the one
document the stakeholder reviews, and `decisions.md` carries the old flat names
(plus a single leaked `compy.input.handlers` at line ~398), splitting the chain.
**Effort:** low.

### Root cause

The `compy.input.*` sub-namespace was an architect decision recorded in
`recommendations_1.md` ("Namespace isolation") and applied to the derived docs,
but `decisions.md` was excluded from that pass. So `decisions.md` still speaks
flat `compy.on_key_pressed` / `compy.handlers` / `compy.get_cursor` etc., while
`design.md`/`spec.md`/`roadmap.md`/their summaries say `compy.input.*` — and the
namespace choice itself appears in no decision the stakeholder review covers.

### Resolution

1. **Add `D-10` to `decisions.md` and its summary** — namespace isolation under
   `compy.input.*`. Use the standard entry shape (Question / Context / Affects /
   Source / Decision). State: the new callback/lifecycle/accessor surface lives
   under `compy.input.*`; `compy.keys_pressed` stays global (raw keyboard state,
   not the input-manipulation layer); legacy globals are unchanged. Source:
   `recommendations_1.md` "Namespace isolation". Tag origin: the decision
   originated in round 1's namespace pass and is **recorded** as a decision in
   round 2 — make that explicit in the marker.
2. **Relocate the new-API names in `decisions.md` and `summaries/decisions.md`
   to `compy.input.*`**, so the whole chain is consistent and the leaked line is
   no longer an outlier. Do **not** relocate `compy.keys_pressed` or the legacy
   globals (same scope table as round 1). This reverses round 1's narrow
   exclusion of `decisions.md` from the namespace pass — note it in the
   changelog.

This is the cleanest reading: it removes the split entirely rather than
papering over it, and the relocation is mechanical (names only, no substance
change to any decision).

---

## Item 3 — Re-estimate the roadmap for round-1 scope

**Report finding:** dimension 5 + architect note 2. **Severity:** low–medium
(planning accuracy). **Effort:** low.

### Root cause

The estimate table is carried over from take 1 (41 h / 23 h PERT) and was not
revised after round 1 shifted scope: M7 grew (added `get_cursor`/`set_cursor`/
`set_text` plus the `UserInputModel:set_text` `keep_cursor` model fix), M3
gained the `write_to_input` facade, M2 gained the `result` repointing setter and
`compy.input` table creation, work moved from M2 to M6 (the `oneshot` deletion),
and the testable surface grew (cursor, native coexistence, two-channel).

### Resolution

Revise the `## Estimates` section, label it "revised 2026-06 for round-1
scope," and bump the affected lines. Suggested figures (Optimistic / Realistic):

**Without LLM** — M1 2/3, M2 3/6, M3 2/4, M4 4/8, M5 3/5, **M6 4/7**
(oneshot deletion + submit reownership added), **M7 3/6** (cursor surface +
model fix added), Docs 4/8, **Tests 7/11** (cursor, native coexistence,
two-channel cases). Totals 32 / 58; PERT (O=32, M=45, P=58) ≈ **45 h**.

**With LLM** — M1 1/2, M2 2/4, M3 1/2, M4 3/5, M5 2/3, **M6 2/5**, **M7 2/4**,
Docs 2/3, **Tests 4/6**. Totals 19 / 34; PERT (O=19, M=26, P=34) ≈ **26 h**.

Keep the confidence note (M4 the main integration uncertainty) and add that the
round-1 scope additions land mostly in M6, M7, and test coverage. No
`decisions.md` entry (estimates are not decisions).

---

## Item 4 — Adjudicate the optional `mods` modifier-string idea

**Report finding:** architect note 4. **Severity:** low–medium (an unrecorded
design-session output, not a doc inconsistency). **Effort:** low (a tracked
note) — **unless** the architect wants it built, which is a scope decision.

### The idea (architect note)

Augment both the `keypressed` and `textinput` paths with an optional `mods`
string — a pre-folded modifier descriptor (the same generic l/r folding as the
combo form) — passed as a trailing argument to downstream handlers and
callbacks. Rationale: a handler attached to several combos may need to know
which modifiers fired; and the generic callback (which runs after combo
handlers) often needs that context too. The current chain passes the
`keys_pressed` read-only proxy (modifiers are derivable from it) but no
pre-folded `mods` string.

### Resolution (conservative; flag for confirmation)

Do **not** invent the `mods` argument across every handler signature in this
pass — that is new API surface and the executor role is not to add structure
the recommendations did not decide. Instead:

- **Record it as a future seam, not built in v1**, paired with the existing
  not-built seams (overloadable matcher expansion; Discord-style text-command-set
  prefix matching). Place a one-paragraph note in `decisions.md` (under D-6, the
  channel-model decision, since that is where the second-argument representation
  lives) and a short "future extension" mention in `spec.md §3`. State the v1
  representation is the `keys_pressed` proxy; the pre-folded `mods` convenience
  string is a candidate addition.
- **Flag it as an open question** in the changelog for the architect to confirm:
  build the `mods` trailing string in-scope, or leave it as a tracked seam? If
  in-scope, it is a `recommendations_3` item (it touches every downstream
  signature: `on_key_pressed`, `on_text_entered`, `handlers[combo]` entries,
  `ProjectController:keypressed`/`:textinput`).

This keeps the idea auditable without silently expanding the API or silently
dropping it.

---

## Item 5 — Add the derivative/proposal-chain disclaimer to `spec.md` and `roadmap.md`

**Report finding:** architect note 6. **Severity:** low–medium. **Effort:**
trivial.

`decisions.md` and `summaries/decisions.md` carry the proposal-status note;
`spec.md` and `roadmap.md` do not. Per the authority model both are
derived/provisional. Add a one-paragraph header note to each:

- They are derived documents in the feature-#77 proposal chain, pre-built on the
  assumption the design is endorsed (not vetoed).
- Detail here is not frozen: stakeholders may review or change parts without
  blocking implementation — there is no requirement to freeze the spec before
  work starts.

No `decisions.md` entry (a documentation-status note, not a decision).

---

## Item 6 — Minor consistency cleanups

**Severity:** low. Mechanical alignment; no `decisions.md` entries beyond the
in-place edits noted.

1. **`decisions.md` "seven" intro → reconcile with the actual count.** The
   "blocking decisions" intro enumerates seven questions while the file now
   carries D-1…D-10. Update the prose to note that round 1 added D-8 (cursor
   restoration) and D-9 (native coexistence), and round 2 records D-10
   (namespace), while the original seven remain the core stakeholder-review
   focus. Add a short "superseded — see annotation below" lead-in on the D-3
   and D-6 **body** text (whose original suggested-decision prose describes the
   pre-round-1 model, corrected only by the appended annotation), so a reader
   does not take the body as current.

2. **`assessment.md §8` co-occurrence → re-point at the resolution.** The
   "Text character + modifier co-occurrence" paragraph still frames the case as
   an open design decision. Add a closing sentence noting it was resolved by
   D-6's round-1 supersession (both channels fire independently; no exclusivity)
   so the paragraph no longer reads as unresolved.

3. **`design.md §3` component-table wording.** `compy.input.on_key_pressed` is
   described as "Generic non-character key callback" — stale framing from the
   pre-two-channel model. Change to "Generic keypressed callback (fires for all
   keys; default = sink)," consistent with `spec.md §3`.

4. **Emphasize the textinput-mirrors-keypressed symmetry (architect note 3).**
   The chain states the textinput channel's default is the textinput sink but
   does not draw out that `on_text_entered` processing follows the same
   default-sink/override principle as `on_key_pressed`. Strengthen the one-line
   note in `decisions.md` D-6, `design.md §4`, and `spec.md §3` so the symmetry
   is explicit rather than implied.

---

## Summary of targets

| Item | Decision entry | Primary doc targets |
|---|---|---|
| 1 — default contradiction | none | `design.md §2`, `spec.md §3`, `summaries/spec.md` |
| 2 — namespace decision + naming | **D-10 (new)** | `decisions.md`, `summaries/decisions.md` (add D-10; relocate names) |
| 3 — re-estimate | none | `roadmap.md` Estimates |
| 4 — `mods` seam | D-6 note (future seam) | `decisions.md` D-6, `spec.md §3`; **open question** |
| 5 — disclaimer | none | `spec.md` header, `roadmap.md` header |
| 6 — cleanups | D-3/D-6 body markers (in place) | `decisions.md`, `assessment.md §8`, `design.md §3`, `spec.md §3`, `summaries/*` as mirrored |

Stage note: there is no separate namespace pass this round — Item 2 *is* the
remaining namespace work, scoped to `decisions.md`/its summary only.

---

## Status

Ready to apply. Items 1, 3, 5, 6 are mechanical alignment. Item 2 adds one
traceable decision (D-10) and a names-only relocation. Item 4 is recorded as a
future seam and **flagged for architect confirmation** rather than built — the
only open question this round carries forward.
