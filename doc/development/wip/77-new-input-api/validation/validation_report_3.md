# Validation Report 3 — Feature #77 Document Chain (post round-2 cleanup)

*Third independent review of the feature #77 chain, run against the
documents as they stand after local design round 2. The intended delta is
`validation/recommendations_2.md` (six items); `validation/changelog_2.md`
is the round-2 self-report; `validation/validation_report_2.md` was the
PASS-WITH-NOTES review round 2 set out to close. Codebase claims re-checked
against `src/`. Reviewer role only — findings, not rewrites. Authority model
applied: `input.md` is the only stakeholder-signed tier; `requirements.md` is
high local input (unedited); `decisions.md` (D-1…D-10) and both recommendation
rounds are one local proposal; `design.md`/`spec.md`/`roadmap.md`/`summaries/`
are derived.*

---

## Status: PASS WITH NOTES

Round 2 was a targeted cleanup of a chain already at PASS WITH NOTES, and it
landed that way. All six `recommendations_2.md` items are applied; the round-1
resolutions are intact; the load-bearing codebase facts still hold. No
functional requirement regressed, no example broke, and no new blocking
cross-document contradiction was introduced. The headline N1 default
contradiction — the one item report 2 flagged as worth fixing before
implementation — is closed in all three places it appeared.

Two items of residue remain, both notes, neither blocking:

- The top-of-file **status-note parenthetical still reads "(D-1…D-9)"** in
  `decisions.md:3` and `summaries/decisions.md:7`, although the file now
  carries D-10 (the narrative intro *was* updated; only the header
  parenthetical was missed). A two-character staleness, internal to the
  decisions doc.
- The **in-file round-2 provenance marker is thin** — exactly one greppable
  `local design round 2` occurrence (`decisions.md:395`), versus six for
  round 1. The full round-2 delta is auditable via `changelog_2.md`, but the
  in-document marker is sparser than the round-1 marker it is meant to mirror.

Both are sub-trivial wording fixes that can be folded into any later edit;
neither warrants a re-validation round.

---

## Part A — Round-2 faithfulness

### Item 1 — Default contradiction (N1) · **APPLIED**

The `noop+log`-vs-`sink` default is fixed in all three named places and reads
consistently across the chain:

- `design.md §2` routing diagram (line 75):
  `compy.input.on_key_pressed [generic, overloadable, default: sink]` — the
  `noop+log` annotation is gone.
- `spec.md §3` intro (lines 182–187): scoped correctly —
  "The submit/cancel/limit callbacks (`before_submit`, `after_submit`,
  `before_cancel`, `after_cancel`, `on_limit_reached`) default to a no-op
  function that emits a debug log entry. The two **channel callbacks**
  (`on_key_pressed`, `on_text_entered`) … default value is the text-editing
  sink."
- `summaries/spec.md` (lines 98–100): same scoping.

The two channel callbacks read **default = sink** everywhere they are
described: `design.md §3` table (165–166), `design.md §4` (189–211),
`spec.md §3` per-callback sections (212–217 `on_text_entered`, 247–253
`on_key_pressed`), `summaries/spec.md` (90, 99–100). The
submit/cancel/limit callbacks read **default = noop+log** (`spec.md §3` 183–184,
`summaries/spec.md` 98). A grep for `noop+log` / blanket "no-op default" turns
up only the two correctly-scoped statements — no surviving conflation. No
over-application (no new tier or callback introduced by the wording change).

### Item 2 — Namespace surfaced as D-10 + `decisions.md` naming · **APPLIED**

- **D-10 present** in `decisions.md` as a full per-decision entry
  (562–609: Question / Context / Affects / Source / Decision) and a
  quick-reference row (line 154), and in `summaries/decisions.md` as the
  glance row (172) plus the intro note (35–40).
- **Relocation grep-clean.** No flat feature-#77 straggler
  (`compy.on_key_pressed` / `compy.handlers` / `compy.get_cursor` / `compy.show`
  …) remains in `decisions.md` or `summaries/decisions.md`; the round-1 leaked
  `compy.input.handlers` outlier is no longer an outlier (the whole file now
  speaks `compy.input.*`). No double `compy.input.input`.
- **`compy.keys_pressed` left global** (D-10, 593–596; no
  `compy.input.keys_pressed` leak anywhere). **Legacy globals unchanged**
  (D-10, 597–600: `input_text`/`input_code`/`validated_input`/`user_input`/
  `write_to_input` stay flat, only their internal call targets move).

### Item 3 — Roadmap re-estimate (3-point PERT) · **APPLIED**

`roadmap.md §Estimates` (275–315) is now a genuine three-point table —
Optimistic / Most-likely / Pessimistic with a per-row and project
PERT = (O+4M+P)/6. Recomputed spot rows check out:

- Without LLM: M4 (4,8,14) → (4+32+14)/6 = **8.3** ✓; M6 (4,7,11) →
  (4+28+11)/6 = **7.2** ✓; Tests (7,11,16) → (7+44+16)/6 = **11.2** ✓.
  Totals O=32 / M=58 / P=89; project PERT (32+232+89)/6 = 58.8 ≈ **59 h** ✓.
- With LLM: totals O=19 / M=34 / P=54; project PERT (19+136+54)/6 = 34.8 ≈
  **35 h** ✓.

The internal estimate-revision history narrative is gone (grep for
take-1/revised/round-1-scope is clean). `summaries/roadmap.md` matches
(≈ 59 h / ≈ 35 h, with the three-point-PERT note, line 38).

*Note (not a defect):* the headline figure differs from `recommendations_2.md`
Item 3's suggested ≈ 45 h / ≈ 26 h. The executor read recommendations_2's
two-point "Optimistic 32 / Realistic 58" as Optimistic + **Most-likely**, then
added a pessimistic tail (P=89), rather than treating 58 as the pessimistic
bound the way recommendations_2 had. That shifts the most-likely from 45 → 58
and the PERT from 45 → 59. This is a defensible, methodology-correct reading —
and it is exactly the "genuine three-point PERT, not a two-point table whose
PERT collapsed to the most-likely" the prompt asked for. Roadmap and summary
agree on the new figure, so the chain is internally consistent; the deviation
is from the recommendation's *number*, not from its *intent*.

### Item 4 — `mods` modifier-string · **APPLIED** (recorded as seam, not built)

- `decisions.md` D-6 (395–408): round-2-marked "Future seam — `mods` string
  (not built in v1)" note; states v1 ships the `keys_pressed` proxy only,
  pairs the `mods` string with the matcher / text-command-set seams, and
  **flags it for architect confirmation**.
- `spec.md §3` (222–227): matching italic "Future seam (not built in v1)" note
  under `on_text_entered`, cross-referencing D-6.

Confirmed **no `mods` argument was added to any live signature.** Every `mods`
token in the chain is either the superseded D-6 original-body text
(`decisions.md:361`, the historical `on_text_entered(text, mods)` that is
explicitly marked superseded) or a seam/clarification note (`decisions.md`
385/396/398/404, `spec.md` 222/226). Live signatures remain
`on_key_pressed(k, keys, isrepeat)` and `on_text_entered(text, keys_pressed)`.
No over-application.

### Item 5 — Disclaimers · **APPLIED**

- `spec.md` header (9–14): "Status — derived proposal document … pre-built on
  the assumption the design … is endorsed … detail is not frozen … no
  requirement to freeze the spec before work starts."
- `roadmap.md` header (8–13): matching note, explicitly extending the
  not-frozen clause to milestone boundaries and estimates.

### Item 6 — Minor cleanups · **APPLIED** (one residual sub-point — see note)

- **6.1 intro count.** Narrative intro reconciled to the D-1…D-10 set
  (`decisions.md` 34–43 and `summaries/decisions.md` 35–40: "Seven questions …
  Three further commitments … D-8, D-9 from round 1, D-10 from round 2 … not
  new stakeholder questions"). D-3 body carries the superseded-in-part lead-in
  (`decisions.md` 229–231); D-6 body already carried "Suggested decision
  (original)" + "Superseded" (356, 366) and is reinforced by the round-2
  channel-symmetry note.
  **Residual:** the *status-note parenthetical* at `decisions.md:3` and
  `summaries/decisions.md:7` still reads "(D-1…D-9)". The intro prose caught up
  to D-10; this one header line did not. Note-level (see Part C).
- **6.2 assessment §8.** Re-pointed at the resolution: `assessment.md` 364–370
  adds the closing paragraph noting the co-occurrence was resolved by D-6's
  round-1 supersession (both channels fire independently; no exclusivity; "this
  paragraph records the original gap; D-6 carries the settled resolution").
  The paragraph no longer reads as open.
- **6.3 design §3 table wording.** `compy.input.on_key_pressed` is now
  "Generic keypressed callback (fires for all keys; default = sink)"
  (`design.md:165`); `on_text_entered` row notes "default = textinput sink"
  (166). The stale "non-character key callback" framing is gone.
- **6.4 textinput-mirrors-keypressed symmetry.** Made explicit in
  `design.md §4` (204–211), `spec.md §3` (212–217, "This mirrors
  `on_key_pressed` exactly … the same default-sink/override principle … the
  only difference is that the textinput channel has no combo tier above it"),
  and `decisions.md` D-6 "Channel symmetry" paragraph (387–393).

**Over-application sweep (whole round):** no new dispatch tier, callback, config
field, or abstraction appeared. The three-tier model is unchanged; the `mods`
idea is a seam note only; the namespace relocation is names-only. Clean.

---

## Part B — No regression of round-1 resolutions

| Round-1 resolution | Status | Evidence |
|---|---|---|
| FR-8/9/10 carried end to end | **Intact** | D-8 (decisions 463–510); `design.md §3` table 172–174 + §7 walkthrough 389–391; `spec.md §2` 145–168; `roadmap.md M7` 204–230 |
| Three-tier model; no fourth tier | **Intact** | `design.md §4` 178–211 (sink = default of `on_key_pressed`, no tier below); `summaries/decisions.md` 93–98. §3 default-wording edit did not reintroduce a sink tier |
| M2/M6 `oneshot` ordering; field on `UserInputModel` | **Intact** | `roadmap.md M2` 59 ("oneshot … continues to drive submit through M2–M5"), `M6` 174/191–194 (deletion in `userInputModel.lua` + `userInputController.lua`); D-4 302–313 |
| Native coexistence (D-9) | **Intact** | D-9 514–558; `design.md §2/§6` 83–94/320–329; `spec.md §6` 440–458 |
| Two-channel model (D-6) | **Intact** | D-6 366–393; `spec.md §3` 229–296 |
| Combo canonical form (D-3) | **Intact** | D-3 246–263; `design.md §4` 233–249; `spec.md §1` 58–87; `roadmap.md M5` 146 |
| `write_to_input` facade | **Intact** | `design.md §6` 307–309; `spec.md §5` 373; `roadmap.md M3` 89–91 |
| FR-11/FR-12 walkthrough | **Intact** | `design.md §7` 365–397 |
| `compy.input.*` relocation in derived docs + summaries | **Intact (now also in `decisions.md`)** | grep-clean across `design/spec/roadmap` and all summaries; the round-2 `decisions.md` relocation did not desync them — it *removed* the last desync |

Codebase facts (Part D dim. 6) all re-verified below; none regressed.

---

## Part C — Provenance and traceability

- **Local-proposal status note: present, count stale.** `decisions.md` 3–7 and
  `summaries/decisions.md` 7–9 both carry the "entire document is a local
  proposal derived from `input.md`, pending one approve/veto review" note —
  correct against the authority model. **But both still parenthesise the set as
  "(D-1…D-9)"** while the file carries D-1…D-10. The D-1…D-10 set is otherwise
  internally consistent: quick-reference table (decisions 145–154) lists D-1…D-10,
  per-decision detail runs through D-10 (562), and the narrative intro names
  D-8/D-9/D-10 (39). Only the header parenthetical lags. Note-level.
- **Round-2 marker present but thin.** Exactly one greppable
  `local design round 2, 2026-06` occurrence (`decisions.md:395`, the D-6
  `mods` future-seam note). The round-1 marker has six (`decisions.md`
  246/301/365/457/509 + the D-10 hybrid at 606). Other round-2 edits — the D-3
  superseded-in-part body lead-in, the intro D-10 reconciliation, the
  names-only relocation — carry no in-file round-2 tag. The full round-2 delta
  is auditable through `changelog_2.md` (which tabulates D-10 / D-6 / D-3 with
  round-2 provenance), so traceability is not lost, but the in-document marker
  is less greppable than its round-1 counterpart. Note-level.
- **D-10 provenance honest.** D-10's marker (606–609) reads "Origin: local
  design round 1 namespace pass, 2026-06; recorded as a decision in round 2.
  See `validation/recommendations_2.md` Item 2 and `validation/
  recommendations_1.md` 'Namespace isolation'." This correctly attributes the
  *choice* to round 1 and the *recording* to round 2 — exactly the honest
  framing the prompt asked for, and the reason its marker is the round-1/round-2
  hybrid rather than a plain round-2 tag.
- **`requirements.md` still traces `input.md`.** Unedited this round; no
  downstream change contradicts it. FR-8/9/10 remain carried (the round-1
  restoration holds); FR-5/6 remain satisfied by the proxy-based modifier
  context, which the `mods` deferral does not disturb (see Part E).

---

## Part D — Seven dimensions (spot re-run)

1. **Requirements coverage — pass.** All twelve FR + four NFR still trace
   decisions → design → spec → roadmap. FR-8/9/10 intact (Part B).
2. **Decision consistency — pass.** D-10 reflected consistently (decisions,
   summary, and all derived docs read `compy.input.*`). The N1 default-wording
   fix did not create a new mismatch — both channel callbacks now read
   default=sink in design and spec, the submit/cancel/limit set reads noop+log.
   No old or new decision is silently contradicted by a derived doc.
3. **Design-to-spec completeness — pass.** Channel-callback defaults and the
   textinput/keypressed symmetry now read the same in `design.md §4` and
   `spec.md §3`. The §3 component-table description (`on_key_pressed` = "fires
   for all keys; default = sink") matches the spec body — the round-2 stale-framing
   note from report 2 is closed.
4. **Spec-to-roadmap coverage — pass.** Every surface still has a milestone
   home; the re-estimate covers the actual round-1 scope (M6 oneshot, M7 cursor
   + model fix, M3 `write_to_input`, larger test surface are reflected in the
   most-likely/pessimistic figures and the row labels).
5. **Roadmap ordering validity — pass.** The re-estimate perturbed only the
   numbers; the milestone Input/Output dependencies are unchanged. M6 Input
   still "M4 complete (M5 is independent of M6)"; M7 Input still "M2 complete.
   M5/M6 not required." M2/M6 oneshot ordering intact.
6. **Factual accuracy against codebase — pass.** Re-spot-checked:
   - `cancel()` does **not** push `'userinput'` — confirmed.
     `userInputModel.lua:795–798` (`cancel` → `handle(false)` → `reset`); the
     `'userinput'` push at `:812–819` is gated by `if eval` **and**
     `if self.oneshot`, both false on cancel, so it is unreachable.
   - `oneshot` is a **`UserInputModel`** field — confirmed
     (`userInputModel.lua:15` @field, `:45–49` constructor param/store).
   - Stop-time reset is `stop_project_run` / `clear_user_handlers` — confirmed
     (`consoleController.lua:860`, `:867`). Chain's "860–868" citation accurate.
   - Native slot interception via `hook_if_differs` / `save_user_handlers` —
     confirmed (`controller.lua:75`, `:779`).
   - `set_text`'s unconditional `jump_end()` (the M7 model fix) — confirmed.
     `userInputModel.lua:128–146`: the `keep_cursor` guards at `:135` and
     `:142` already gate the view/cursor updates, but `:145 self:jump_end()` is
     **outside** both guards, so the cursor jumps to end even when
     `keep_cursor` is true. The D-8/M7 "skip the unconditional `jump_end()`
     when `keep_cursor`" fix is correctly identified and correctly scoped.
   No codebase mismatch found.
7. **Summary fidelity — pass (with the one mirrored count-staleness).**
   `summaries/spec.md` mirrors the corrected default scoping (98–100);
   `summaries/decisions.md` carries the D-10 glance row (172), the intro note
   (35–40), and the full `compy.input.*` naming; `summaries/roadmap.md` carries
   the ≈ 59 h / ≈ 35 h three-point figures (38). The only summary residue is the
   "(D-1…D-9)" status parenthetical at `summaries/decisions.md:7`, mirrored from
   its source — not an invented claim.

---

## Part E — Carried-forward open questions (adjudication) + new conflicts

**1. `mods` trailing modifier-string — acceptable to defer.** Nothing in
`input.md` or FR-5/FR-6 requires a *pre-folded* modifier string. The owner
clarification asks for "callbacks for keys pressed together with the Ctrl key"
and FR-6 asks for notification of non-character / modifier-combo key events; the
chain satisfies that by delivering the full `keys_pressed` read-only proxy as
the second argument to both channel callbacks and to combo handlers, from which
modifier state is directly readable. `mods` is a convenience over that proxy,
not a capability gap. Recording it as a flagged future seam (D-6 + `spec.md §3`)
is the correct disposition: it is neither silently built nor silently dropped,
and the architect has an explicit confirm/decline point. **Not blocking.**

**2. `decisions.md` relocation reversing round-1's narrow exclusion —
acceptable; it resolves the finding rather than reintroducing one.** Round 1
deliberately left `decisions.md` flat; report 2 then flagged the resulting split
(flat `decisions.md` vs `compy.input.*` derived docs, plus the single leaked
`compy.input.handlers`) as a real inconsistency in the one document the
stakeholder reviews. Round 2's relocation removes that split entirely and pairs
it with D-10 so the namespace choice is itself on the record. The relocation is
names-only, and the two things that must *not* move (`compy.keys_pressed`, the
legacy globals) correctly did not. This is the cleanest available resolution;
it does not reintroduce a problem. **Not blocking.**

**New cross-document contradictions introduced by round 2:** none of
consequence. The two residues — the "(D-1…D-9)" status parenthetical and the
estimate headline that differs from recommendations_2's suggested number — are,
respectively, an internal-count staleness and a justified methodology-driven
deviation that is internally consistent across roadmap and summary. Neither is a
contradiction between documents about the *design*; both are notes.

---

## Summary of actionable items

All notes; none blocking. (No dropped FR, no broken example, no contradictory
design, no codebase mismatch.)

1. **Update the status-note parenthetical from "(D-1…D-9)" to "(D-1…D-10)"** in
   `decisions.md:3` and `summaries/decisions.md:7`. The narrative intro already
   reconciled to ten; only this header line lags. Two-character fix. Note.
2. **Optionally thicken the in-file round-2 marker.** The round-2 delta is
   fully auditable via `changelog_2.md`, but only one in-document
   `local design round 2` tag exists (the `mods` seam). Tagging the D-3
   superseded-in-part lead-in and the intro D-10 reconciliation would make the
   round-2 delta as greppable in-place as the round-1 delta. Note (optional).

## Recommendation

**Ready for stakeholder review.** The round-2 cleanup landed faithfully across
all six items, the round-1 resolutions are intact, the headline N1 default
contradiction is closed everywhere, and the load-bearing codebase facts all
re-verify. What remains is two sub-trivial wording notes (the D-10 count in one
header line, and round-2 marker thinness) — neither alters the design, drops a
requirement, or misleads the implementor, and neither warrants another local
pass. They can be folded into any later edit. A `validation/recommendations_3.md`
is **not** warranted.
