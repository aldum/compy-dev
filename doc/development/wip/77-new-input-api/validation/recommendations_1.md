# Feature #77 — Recommendations (round 1)

*Input for the next iteration of the document chain. Distils the
actionable items from `validation/validation_report_1.md` into
concrete resolutions, with severity and effort estimates. Built
incrementally, one item at a time; items not yet discussed are
marked TBD.*

*Numbering follows the report's "Summary of actionable items".*

---

## Document authority model

Not all documents in the chain carry equal weight. Resolutions
below are anchored to the authoritative tier and propagated
downward.

**Stakeholder ground truth:** `input.md` is the *only* document
with stakeholder authority. Everything else in the chain —
`requirements.md` included, and all of `decisions.md` (D-1…D-7 came
from an earlier local round) — is a **local proposal** derived from
`input.md`, awaiting a single eventual stakeholder approve/veto
review. The tiers below therefore rank *depth of human input within
the local proposal*, not approval status. (Rationale for this
workflow: it is better to present a worked solution for approval —
with full right of veto and review — than a pile of open questions
that force the stakeholder to re-derive the context.)

**Authoritative (heavy human input):** `requirements.md`,
`decisions.md`, `design.md`, and the design source notes
(`notes/decisions.md`, `notes/solution_sketch.md` and supporting notes).

**Derived / less authoritative (largely generated downward):**
`assessment.md`, `spec.md`, `roadmap.md`, and the `summaries/`.
These were produced from the tier above and inherit its gaps.

**Known origin of the FR-8/9/10 drop:** `decisions.md`
deliberately addressed only the *contradictory* points surfaced by
`assessment.md`. `design.md` then took its starting point from
`decisions.md` rather than from the full `requirements.md`, so the
non-contradictory FRs (cursor query/set, live text) silently fell
out — a derivation error, not a deliberate de-scope.

**Working rule for these recommendations:** where a resolution
follows directly from `requirements.md` + `decisions.md` +
the design sketch, treat it as settled and recommend updating the
downward docs (`spec.md`, `roadmap.md`, and the design body where
it only needs *completing*, not re-deciding) to match.

---

## Item 1 — Restore FR-8 / FR-9 / FR-10 to design and spec

**Report dimensions:** 1 (coverage), 3 (design→spec), 4
(spec→roadmap). **Also folds in report item 5** (`write_to_input`
backward compat), since the same live-write surface resolves both.

### Severity

High by *impact* — three of twelve functional requirements
(query cursor, set cursor while active, change text while active)
drop out of the chain after `assessment.md`, and FR-9 is actively
contradicted by `compy.configure`'s "no effect while active"
clause.

Low–medium by *resolution effort* — the capability is additive,
decoupled, and M7-class (depends only on the singleton from M2;
touches none of the routing/submit work in M4–M6).

**Grounding:** this is a direct restoration from `requirements.md`
(FR-8/9/10 are explicit), not a new design choice. `design.md §1`
already states the feature adds "programmatic cursor and content
access" — so the design *body* only needs **completing** (add the
entries to the §3 component table), and the downward docs
(`spec.md §2/§5`, `roadmap.md M3/M7`) need to be brought into
line. The drop was the derivation error described above.

### Verdict: mostly mechanical, with one real decision

The plumbing is straightforward. The model already has every
operation needed:

- `UserInputModel:get_cursor_pos()` → `(line, col)` — FR-8
- `UserInputModel:move_cursor(y, x)` / `set_cursor(c)` — FR-9
- `UserInputModel:set_text(text, keep_cursor)` — FR-10

Exposing them as `compy.*` functions that delegate to the
singleton is the same pattern as `compy.configure` / `compy.clear`
(M7). `write_to_input` becomes a thin facade over the live-write
method, exactly like the other four legacy facades.

What is **not** purely mechanical:

1. **Cursor coordinate contract — RESOLVED: 2D `(line, col)`.**
   The model cursor is already 2D (`get_cursor_pos` →
   `(line, col)`, `move_cursor(y, x)`). `spec.md §2`'s single
   integer ("1-based column in line 1") was filler in a downward
   doc; it only works single-line and contradicts the supported
   `multiline` flag, and is not grounded in `requirements.md`
   (FR-1/8/9 say "cursor position" generically). Adopt 2D,
   1-based, **source-line** coordinates and apply uniformly to:
   the `show()` initial `cursor` field, the FR-8 query return, and
   the FR-9 setter. Settle FR-7/8/9 on this one coordinate space.

2. **Live-write vs. `configure()` immutability — needs a stated
   rule.** `configure()` deliberately ignores `text` while active.
   FR-10 needs a live text change. The live-write path must be
   declared the explicit exception, so the two contracts don't
   read as contradictory.

3. **Model wrinkle — light touch to `userInputModel.lua`.**
   `set_text(text, keep_cursor)` calls `jump_end()`
   unconditionally (`userInputModel.lua:128–146`), so it does not
   actually preserve the cursor even when `keep_cursor` is true.
   Honouring FR-9 + FR-10 together requires either fixing
   `set_text` to respect `keep_cursor`, or having the facade
   sequence `set_text` then `set_cursor`.

### Recommended resolution

**Coordinate model (settled): 2D `(line, col)`, 1-based,
source-line coordinates** (not wrapped/apparent lines). Rationale:
it matches the model, covers `multiline`, and aligns with the FR-7
boundary which already operates on whole-input source lines
(`is_at_limit`). Settling FR-7/8/9 on one coordinate space avoids
re-litigating the ambiguity flagged in `assessment.md §8`.
Single-line callers ignore `line` (always 1), so the simple case
stays simple (NFR-4).

**New `compy.*` surface (delegating to the singleton):**

| Function | Maps to | Notes |
|---|---|---|
| `compy.get_cursor()` | `model:get_cursor_pos()` | returns `line, col`; returns `nil` when hidden |
| `compy.set_cursor(line, col)` | `model:move_cursor(line, col)` | clamps to valid range (model already clamps); no-op when hidden |
| `compy.set_text(text [, keep_cursor])` | `model:set_text(...)` + `update_view` | live write; the explicit exception to `configure()` text-immutability |

- Update `spec.md §2`'s `show()` `cursor` field to the 2D form
  (accept `{line, col}` or two fields), consistent with
  `set_cursor`.
- `compy.set_cursor` / `compy.get_cursor`: define hidden-state
  behaviour following the existing pattern (`configure` is safe
  when hidden; `clear` is a no-op when hidden).

**`write_to_input` (report item 5):** rewire as a facade over
`compy.set_text`, preserving today's semantics — replace full
content, no-op when no session active. Add it to the legacy
facade list in `design.md §6` / `spec.md §5` and to M3's scope so
the `tixy` example (which depends on it) keeps working.

**Model fix:** make `UserInputModel:set_text` honour
`keep_cursor` (skip the unconditional `jump_end()` when
`keep_cursor` is true). Small, and it makes `set_text` +
`set_cursor` composition predictable.

### Roadmap placement

Folds into **M7** (extended singleton API) — it is the same class
of additive, post-singleton surface as `configure`/`clear`. Add
the cursor + live-write functions and the `write_to_input` facade
there. The only earlier dependency is M2 (singleton exists). No
interaction with M4–M6.

Exception: the `write_to_input` *facade wiring* belongs in **M3**
(legacy facades) so examples stay green from M3 onward; if M3
predates the M7 live-write method, M3 can keep the current
`set_text` call directly and be re-pointed at `compy.set_text`
when M7 lands.

### Status

Resolved. Coordinate model settled (2D source-line). No open
stakeholder question remains for item 1; the cursor/text surface
is a grounded restoration plus downward-doc updates. The D-5 /
FR-7 boundary should be confirmed against the same coordinate
space when that item is revisited.

---

## Item 2 — M2/M6 submit-path ordering (`oneshot` deletion)

**Report dimensions:** 2 (decision consistency), 5 (roadmap
ordering). **Severity:** high if implemented as written (breaks
submit, and every Enter-to-submit example, across M2–M5);
resolution effort low — a roadmap re-sequence, no design change.

### Root cause

A downward-doc error. `roadmap.md` M2 places the `oneshot`
deletion in the singleton-extraction milestone and labels M2
"zero behaviour change." But `oneshot` currently does two jobs:

- gates submit in the sink (`userInputController.lua:346`,
  `… and input.oneshot then`), and
- triggers the `'userinput'` push that clears the overlay
  (`userInputModel.lua:812–819`).

Its replacement — `framework_handlers['return']` in
`ProjectController` owning submit — arrives in **M6**. Deleting
`oneshot` in M2 therefore strands submit through M2–M5, and the
"zero behaviour change" claim is self-contradictory.

### Grounding

The authoritative tier already locates the deletion correctly.
`decisions.md` D-4: `oneshot` "is deleted as a consequence of D-2
combined with D-4." `design.md §3`: it has "nothing left to do"
only once **both** jobs are covered — activation by
`show()`/`hide()` (available M2) **and** submit by
`framework_handlers['return']` (available M6). Both hold only at
M6. So the roadmap is wrong, not the design.

### Recommended resolution (roadmap re-sequence)

Keep `oneshot` through M2–M5; delete it in M6.

- **M2 (singleton extraction):** drop the "remove `oneshot` flag"
  line. M2 moves construction to startup and adds
  `show()`/`hide()` state. `oneshot` stays and keeps driving
  submit exactly as today — which makes M2's "zero behaviour
  change" claim actually true.
- **M3 (legacy facades):** the reftable fill continues via the
  existing oneshot submit path (sink `submit()` → `res(t)`), so
  M3 does **not** depend on `after_submit` (M6). Examples stay
  green. (Resolves the M3→M6 backward dependency noted in the
  report.)
- **M4 (ProjectController + gate removal):** sink delegation
  reaches `UserInputController:keypressed`, whose `submit()` still
  honours `oneshot`. Submit keeps working through M4 and M5.
- **M6 (before/after chains):** introduce
  `framework_handlers['return']` owning submit, move the reftable
  fill onto the `after_submit` callback, **then** delete
  `oneshot`. At this point both its jobs are covered.

### Coupled corrections (from report items 7-? / item 8)

- **File target:** when `oneshot` is deleted (now M6), the *field*
  lives in `userInputModel.lua` (`:15`, `:49`), not
  `userInputController.lua`. The submit-path *code* that reads it
  is in `userInputController.lua`. Update M6's file list
  accordingly; fix the same mislocation in `design.md §3` and
  `decisions.md` D-4 prose ("the `oneshot` flag on
  `UserInputController`").
- **Singleton `result` repointing (inherent to M2/M3, flag it):**
  with one persistent controller, `result` (the reftable) must be
  re-pointed per session. Today it is fixed at construction
  (`UserInputController(ui_model, input_ref, true)`). The
  singleton needs a setter (or `show()` carries it) so each
  facade call wires the current reftable. Not an ordering issue,
  but it must be in M2/M3 scope or the facade reftable fill has
  nowhere to write.

### Status

Recommendation ready; grounded in D-4 / `design.md §3`. Pure
downward-doc (roadmap) adjustment plus the file-target/`result`
corrections. No stakeholder decision required.

## Item 3 — Dispatch model: collapse the redundant fourth tier

**Report dimensions:** 2 (decision consistency), 3 (design→spec).
**Severity:** medium (contradictory contract handed to the
implementor); resolution effort low — simplifies the model.

### Architect clarification (high authority)

The four-tier chain in `design.md §4`
(`framework_handlers → compy.handlers → compy.on_key_pressed →
sink`) is redundant. The intended model has **three** tiers, with
the text-editing sink folded into the third as its default:

> Two alternative APIs for project space: register **combos** for
> quick / early-catching handling; use the **callback** for more
> complicated catchall logic that simple combo matching can't
> express. Sinking input to `UserInputModel` was always meant to
> be the *default* value of the catchall callback — not a separate
> processing level — which the project may override with its own
> callback if needed.

This is already foreshadowed in `notes/solution_sketch.md §4`
("Invocation of `UserInputController:keypressed` could also be the
default value of `compy.on_key_pressed` rather than a hardcoded
final step"). `design.md §4` elaborated it into a literal fourth
step; that was over-elaboration, not intent. Treat this clause as
high-authority input correcting `design.md`.

### The three-tier model

`ProjectController:keypressed`:

1. **`framework_handlers[combo]`** — structural, framework-owned
   (Enter, Escape). Not project-overridable.
2. **`compy.handlers[combo]`** — project per-combo registration.
   Return truthy → consume (stop). Return nil/nothing → fall
   through to tier 3.
3. **`compy.on_key_pressed(k, keys)`** — generic project callback.
   **Its default value is the text-editing sink**
   (`UserInputController:keypressed`). A project needing catchall
   logic overrides it; overriding *replaces* the default sink.

Resulting ergonomics:
- *Hotkey while still editing text* (the common case): register
  `compy.handlers['lctrl+l']`, return truthy. Every other key
  falls through to tier 3's default → normal text editing.
- *Full custom key handling*: override `compy.on_key_pressed`.

### How this resolves the contradiction

The report flagged that `design.md §4` made `on_key_pressed` a
consuming level while `spec.md §3` said its return is ignored.
Under the three-tier model the conflict dissolves: there is no
tier below `on_key_pressed` to consume, because the sink *is* its
default. The consume/return-value mechanism applies only to tier 2
(`compy.handlers`): truthy consumes, nil falls through — which is
exactly what `spec.md §3`'s handler signature already says. So
`spec.md`'s combo contract is correct; only its framing of
`on_key_pressed` as a passive level sitting before a separate sink
is wrong.

### Downward-doc updates

- **`design.md §4`** — replace the four-step diagram with the
  three-tier model; state that the sink is the default of
  `compy.on_key_pressed`.
- **`spec.md §3`** — reframe `compy.on_key_pressed`: default value
  is the sink; assigning a function replaces it; there is no
  separate sink tier. Drop "return value is ignored" (it implied a
  fourth tier). Keep the `compy.handlers` truthy/nil consume
  semantics as-is.
- **Shared dispatch signature** — simplify
  `dispatch(k, keys, framework_handlers, handlers, callback, sink)`
  to drop the separate `sink` argument; `callback` defaults to the
  sink (`design.md §4`, `notes/solution_sketch.md §4`,
  `notes/routing_unification.md`).
- **`summaries/design.md`, `summaries/spec.md`** — update the
  dispatch boxes to three tiers.

### Symmetry and consequences (note for the spec rewrite)

- The same pattern applies to the **textinput** path:
  `compy.on_text_entered`'s default is the textinput sink
  (`UserInputController:textinput`); overriding replaces it.
- **`on_limit_reached` (FR-7):** the limit signal originates in
  the sink. If a project overrides `on_key_pressed` (replacing the
  sink), `on_limit_reached` no longer fires — acceptable, since
  that project has taken over key handling, but the spec should
  state it rather than promise unconditional propagation.

### Status

Resolved by architect clarification. Three-tier model is
authoritative; downward docs (`design.md §4`, `spec.md §3`,
summaries) to be corrected to match. No further decision required.

## Item 4 — Native `love.keypressed` under `ProjectController`

**Report dimension:** 6 (backward compat / routing). **Severity:**
high — shipped examples (pong, life, paint, turtle) rely on native
`love.keypressed`; left unspecified, they break when
`ProjectController` takes the slot. **Effort:** medium.

### Confirmed precondition: the routing level is already universal

Project handlers are never bound to the real LÖVE callbacks. LÖVE
calls `love.handlers.keypressed`, which Compy replaces with its own
dispatcher (`controller.lua:528`) and protects
(`table.protect(love.handlers)`, `controller.lua:769`). A project's
`function love.keypressed` is captured (`save_user_handlers`) and
installed into the `love.keypressed` **slot**
(`hook_if_differs`: `love[key] = CC:wrap_handler(...)`,
`controller.lua:81`), which the dispatcher conditionally calls. The
project *thinks* it overrides `love.*`; a transparent interception
level always sits above it. Same structure for `textinput`,
`keyreleased`, mouse and touch events.

### Resolution: controller auto-provisions the callback (architect intent)

When a project registers, `ProjectController` inspects what it
defined and **auto-provisions `compy.on_key_pressed` on the
project's behalf**, wrapping the function the project believes is
bound to `love.keypressed`. The project keeps writing idiomatic
LÖVE; the controller routes it through the universal three-tier
dispatch (Item 3). This is unification done on the framework side —
no project migration. It generalises to `textinput` →
`on_text_entered`, and to `keyreleased`.

This supersedes the report's framing of Options A/B as a
project-facing choice: the *mechanism* is fixed (transparent
auto-provisioning). The only remaining decision is the **body of
the auto-provisioned legacy wrapper**.

### The wrapper body: lifecycle split, applied by heuristic only

The visible/hidden split must **not** be a rule project code has to
know — that would be an implicit footgun. Instead it is an
auto-detected behaviour that engages *only* for code the framework
recognises as legacy, and the framework announces the choice it
made.

**Legacy heuristic (the gate).** A project is treated as legacy
when it defined native `love.keypressed`/`textinput` (captured by
the existing `save_user_handlers` path) **and** set none of the
relevant new surfaces (`compy.on_key_pressed`, `compy.handlers`,
`compy.on_text_entered`). Only then is the lifecycle-split wrapper
auto-provisioned. If the project sets any relevant `compy.*`
surface, it is new-style: it takes explicit control (Item 3
override semantics) and the split never applies, so no implicit
rule is ever imposed on code that opted in.

**The auto-provisioned legacy wrapper** branches on singleton
visibility:

- **singleton visible** → run the sink (text editing wins);
- **singleton hidden** → run the project's native handler (game
  keys).

This reproduces today's gated behaviour exactly (game keys live
when no prompt; text editing when a prompt is up) with zero
example changes — a legacy handler is never fed backspace/arrows
during a text prompt.

**Transition-period diagnostics.** In debug mode the wrapper logs,
on each branch, which way it routed (sink vs native handler) and
that this was a *heuristic* decision — so the choice is observable
and developers are nudged toward the explicit `compy.*` surfaces.
Reuses the existing "default callback = noop + debug log"
convention (`spec.md §3`). The heuristic and its logging are a
transition aid; they can be retired once migration is complete.

### Notes / consequences

- **Reset on stop:** the auto-provisioned wrapper is cleared on
  project stop alongside `compy.handlers`/callbacks (see Item 8 —
  this is `stop_project_run`/`clear_user_handlers`, not
  `evacuate_required`).
- **Scope of the chain edits:** `design.md` and `spec.md §6`
  currently say only "`ProjectController:keypressed` IS the
  `love.keypressed` occupant" — add the auto-provisioning rule, the
  legacy heuristic (gate), the lifecycle-split wrapper, and the
  transition diagnostics so native-handler coexistence is
  specified, not implied.

### Status

Settled. Mechanism: transparent auto-provisioning. Application:
gated by the legacy heuristic, so projects never need to know the
visible/hidden rule. Wrapper body: visibility lifecycle split.
Transition: debug logging on both branches flagging the heuristic.
Needs new spec/design text (the chain never covered this).

## Item 5 — `write_to_input` backward compat

Folded into Item 1 (same live-write surface). See above.

## Item 6 — Two independent channels, no exclusivity

**Report dimension:** 3 (design→spec completeness). **Severity:**
the report rated this medium because D-6's "one notification per
gesture" guarantee was specified as an impossible same-frame
lookahead. **Resolution: drop the guarantee.** It is grounded in
neither the requirements nor the current implementation. **Effort:**
low (a deletion, plus a re-decision of D-6 — see authority flag).

### Grounding: "exactly one per gesture" is not load-bearing

- **`requirements.md`** — FR-5/FR-6 require only that submit and
  non-character-key notifications *exist*. Nothing asks them to be
  mutually exclusive with text entry.
- **`decisions.md` D-6** is a *"Suggested decision"*, and its
  closing line explicitly delegates the mechanism downward — "This
  suppression logic is a spec detail for `api_spec.md`." So the
  "exactly one notification per gesture" outcome never lived in the
  authoritative tier as a hard commitment; it was a soft suggestion
  whose load-bearing part was pushed into the non-authoritative
  spec, where it became the impossible same-frame lookahead the
  report flagged.
- **Current implementation** has no suppression anywhere. LÖVE
  fires `keypressed` and `textinput` as two independent events; the
  sink already consumes them on two independent channels
  (`keypressed` → structural ops only; `textinput` → insertion). A
  plain `'a'` keypress does nothing in the sink
  (`userInputController.lua:187–389`) and is inserted via the
  textinput path.

So the either/or was a tidiness preference introduced (softly) at
the decision layer, not a requirement — and the device's real
behaviour already runs both channels side by side.

### Resolution: mirror LÖVE — serve both, let the project choose

Fire both channels independently; no suppression, no
classification, no lookahead:

- **keypressed channel** → `framework_handlers[combo]` →
  `compy.handlers[combo]` → `compy.on_key_pressed`
  (default = the *keypressed* sink).
- **textinput channel** → `compy.on_text_entered`
  (default = the *textinput* sink).

A character-producing keypress visits both channels exactly as in
raw LÖVE. The expected (not enforced) division of labour:

- command detection → combos / `on_key_pressed`;
- text capture → `on_text_entered`, which in ~90% of cases is left
  at its default and simply sinks into the UIC.

### Why there is no double-insertion

Under the three-tier model (Item 3), `on_key_pressed`'s default is
the *keypressed* sink, which ignores plain character keys —
insertion is the *textinput* sink's job. So even though
`on_key_pressed` fires for `'a'`, the character is inserted exactly
once, via the textinput path. A project sees a "double" callback
only if it deliberately handles both channels — which is plain LÖVE
semantics and its own choice.

### What this dissolves

- **Report Item 6** ("specify the suppression mechanism") — no
  mechanism is needed; the hardest, impossible-as-written part of
  the feature is *removed*, not solved.
- **Dim-3 co-firing finding** (Shift+S matching a combo *and*
  firing `on_text_entered`) — no longer a defect; both fire by
  design, the project picks the channel.
- **IME / dead-key worry** largely evaporates: `textinput`
  delivers LÖVE-composed characters to `on_text_entered`;
  `keypressed` delivers raw keys to `on_key_pressed`. There is no
  classifier to fool. The only residue (a project using
  `on_key_pressed` for commands may observe raw composition
  keypresses) is native LÖVE behaviour, not a Compy limitation.

### Consequence to document (not enforce)

`compy.handlers` entries for bare printable keys (e.g.
`handlers['s']` with no Ctrl/Alt) **do** fire on `keypressed`,
alongside text entry. That is allowed and predictable; the guidance
is to reserve combos for command modifiers (ctrl/alt/gui). State
the behaviour in the spec; do not suppress it.

### Future extension point (assumed, not built)

**Text command-sets, Discord-style.** A project-registered table of
text-prefix → handler, matched on entered/submitted text by the
*same* overloadable-matcher principle as key-combos (Item 7),
except matching by **string prefix** instead of combo equality.
Lives in the input controller's textinput/submit path. Mark it in
code as an expansion seam paired with Item 7's matcher; not
enforced now.

### Downward-doc updates

- `spec.md §3` — remove the same-frame suppression rule entirely;
  document the two independent channels and each channel's
  default-sink behaviour; state the bare-printable-key combo
  behaviour; drop the "exactly one per gesture" promise.
- `decisions.md` D-6 — supersede: replace the suppression note with
  "both events surface on their own channels; no exclusivity; the
  project chooses which to use." (Authoritative-doc edit — see
  flag.)

### Not a re-decision — striking unapproved filler

Although D-6 lives in `decisions.md`, the "no double callback"
outcome is not human-approved input: it was raised during the
analysis/design session as a *"Suggested decision"* and never
discussed or signed off. The authority model is about whether a
human actually decided, not which file a line sits in — so D-6's
suggestion has no more standing than any other derived text.
Removing it is striking unapproved filler, not overturning a
decision; edit `decisions.md` D-6 freely on the next pass.

Grounding for dropping it: `requirements.md` is concerned with the
*absence* of callbacks, never their duplication. Where duplication
actually matters, project code handles it trivially (e.g. an
internal guard/semaphore variable). And the new rule matches both
LÖVE and the current implementation.

### Status

Reframed per architect input: no exclusivity; two independent
channels mirroring LÖVE; suppression/classification dropped.
Resolves the report's Item 6 and the co-firing finding by
construction. The D-6 edit needs no special sign-off (unapproved
suggestion). Text-command-set prefix matching recorded as a future
seam paired with Item 7's matcher.

## Item 7 — Combo serialisation, registration, and matching

**Report dimension:** 3 (design→spec; internal inconsistency).
**Severity:** medium (handlers registered per the documented
examples would never fire). **Effort:** low–medium.

### The defect

`spec.md §1` states combos are "all held keys sorted
alphabetically," but every example is modifier-first
(`"lctrl+s"`, `"lalt+lshift+f4"`, `"lctrl+l"`). Alphabetical would
produce `"f4+lalt+lshift"` / `"l+lctrl"`, so the example
registrations never match what the serialiser emits.

### Canonical form (settled)

- **Order:** modifier-first by fixed precedence
  (`ctrl, alt, shift, gui`), then the action key. Matches human
  convention and the examples' intent. Not alphabetical.
- **L/R folding:** combo strings use **generic** modifier names
  (`ctrl`, not `lctrl`/`rctrl`), so a project registers `"ctrl+s"`
  once and catches either side. The `keys_pressed` table keeps the
  precise LÖVE names; only the *combo serialisation* folds l/r.
- **Build rule:** `current_combo` = held command-modifiers (in
  precedence order) + the triggering key `k`, not "everything
  currently held" — avoids noise from an extra non-modifier key
  held during fast typing. (Bare-key combos are allowed and fire on
  the keypressed channel — see Item 6; the build rule simply
  prepends whatever command-modifiers are held to the triggering
  key.)

### Mechanism (settled)

- **Singleton held-state in `controller.lua`** with a precomputed
  `current_combo` string, refreshed on every key down/up. Cost
  lands on key events only (not per frame), so the string build is
  GC-safe.
- **Order is derived from a static precedence list (or a sorted
  array), never from `pairs()`.** Lua hash tables have no
  guaranteed iteration order; iterating the held *set* directly
  would give an unstable string. Iterate a canonical ordered list
  and append the keys currently held.
- **`compy.handlers` is metatable-backed.** `__newindex(t, combo,
  fn)` normalises the registered combo to canonical form and
  stores it (`rawset` into the internal table). Registration is
  the conversion seam; the project still writes
  `compy.handlers['Ctrl+S'] = fn` and it reads naturally.
- **Dispatch goes through an overloadable matcher**, not a
  hardcoded lookup. Default matcher: exact canonical match
  (effectively `handlers[current_combo]`, O(1)). The matcher is
  the marked expansion point (comment in code) for future
  glob / prefix / regex matching, and is **project-overloadable**
  so richer matching can be tested and rolled out gradually
  without changing the framework default or breaking existing
  handlers.

### Design rationale

KISS with clean expansion points: exact matching now, but behind a
swappable matcher function rather than an inlined table read, and
behind a metatable that owns normalisation. No predicate
machinery is built until prefix/glob matching is actually needed —
at which point only the matcher (and optionally per-entry compiled
predicates) changes. Aligns with the house rules ("store the
function, not a string tag"; avoid abstraction a student couldn't
follow — the project-facing surface stays a plain table).

### Downward-doc updates

- `spec.md §1` — replace the alphabetical rule with the canonical
  form above; fix all combo examples; document generic l/r
  folding and the `combo_string(k, keys)` build rule.
- `spec.md §3` / `design.md §4` — note `compy.handlers` is
  metatable-normalised on assignment and dispatched via an
  overloadable matcher (default exact).
- Mark the matcher as the expansion seam in code (comment).

### Status

Settled: modifier-first generic-folded canonical form;
metatable-normalised registration; overloadable matcher with
exact-match default. No open decision.

## Item 8 — Codebase-reference corrections in the chain

**Report dimensions:** 2, 6. **Severity:** low individually, but
they propagate into wrong implementation assumptions. **Effort:**
trivial (text fixes). No decisions; apply on the next pass.

1. **`cancel()` does not push `'userinput'`; Escape does not
   dismiss the overlay today.** `assessment.md §2` and `§8` state
   cancel pushes `'userinput'` and clears the overlay. Code:
   `cancel()` → `handle(false)` (`userInputModel.lua:795–798`),
   and the `'userinput'` push is reached only on the
   `eval == true` + `oneshot` + success path (`:809–821`); the
   `eval == false` branch sets `ok = true` and does not push. So
   Escape clears content via `reset()` but leaves the overlay up —
   which is exactly the limitation `design.md §5` is built to fix.
   The design is right; fix the assessment.

2. **`oneshot` is a `UserInputModel` field, not a
   `UserInputController` one.** `userInputModel.lua:15,49`;
   `UserInputController` only reads `self.model.oneshot`. Fix the
   wording in `design.md §3` and `decisions.md` D-4, and the file
   target in the roadmap (deletion lands in M6 per Item 2, in
   `userInputModel.lua`; the submit-path code that reads it is in
   `userInputController.lua`).

3. **Stop-time reset is `stop_project_run` /
   `clear_user_handlers`, not `evacuate_required`.**
   `evacuate_required` (`consoleController.lua:844–858`) only
   unloads project `.lua` modules from `package.loaded`. The
   handler/state reset is in `stop_project_run`
   (`consoleController.lua:860–868`). Fix the "same mechanism as
   `evacuate_required`" references in `design.md §3`,
   `spec.md §3`/`§6`, and `decisions.md` D-7.

---

## Item 9 — Deliver the D-7 FR-11/FR-12 walkthrough

**Report dimension:** 2 (unmet promise). **Severity:** medium —
FR-11/FR-12 are the API-completeness acceptance criteria; they are
currently asserted, not demonstrated. **Effort:** low (a short
mapping, no code).

`decisions.md` D-7 promised `design.md` would "include a
walkthrough confirming the API surface covers both cases"
(console + editor). `design.md §7` only asserts the migration is
mechanical. Add the concrete mapping (it doubles as a design-time
test that the Item 3 tiers + `framework_handlers` actually cover
the cases):

- **Console REPL:** Enter → `framework_handlers['return']`
  (submit); Up/Down at history boundary → limit signal →
  `on_limit_reached` / handler; Ctrl+L clear terminal →
  `compy.handlers['ctrl+l']`; error display → sink (unchanged).
- **Editor:** Enter → submit block; Escape → load →
  `framework_handlers['escape']` + `before_cancel`; Up/Down at
  boundary → block nav via `on_limit_reached`; Ctrl+M / Ctrl+F
  mode switches → `compy.handlers['ctrl+m'/'ctrl+f']`; cursor
  get/set → the FR-8/9 surface (restored in Item 1 — note the
  cross-dependency: without Item 1, FR-12 is not expressible).

Placement: put the walkthrough in `design.md` (where D-7 located
it) or in `notes/editor_repl_input.md` with D-7 re-pointed there.
Either satisfies the promise; `design.md` is the literal fix.

---

## Item 10 — Smaller drifts

**Severity:** low. Mostly downward-doc corrections; all sub-items
now settled.

1. **`user_input()` ≠ `compy.show({})`.** Current `user_input()`
   only allocates and returns the reftable
   (`consoleController.lua:582–585`); it shows nothing — the
   overlay appears on a later `input_text()`/etc. **Resolution:**
   the `user_input()` facade stays reftable-only (no `show`); the
   showing facades wire that reftable into the singleton's
   `result` on `show()` (the repointing from Item 2). Fix the
   `spec.md §5` mapping.

2. **`on_text_entered` second argument.** D-6 says the project
   receives a `mods` subset (non-character keys only); `spec.md §3`
   passes the full `keys_pressed` proxy. **Resolution:** pass the
   `keys_pressed` proxy uniformly (consistent with
   `on_key_pressed`); reword D-6. Projects read modifiers off the
   proxy. Simpler, one representation.

3. **`isrepeat` on `on_key_pressed` (settled).** D-3 lists
   `_on_key_pressed(k, pressed, isrepeat)`; `spec.md §3` drops it
   from `on_key_pressed` (keeps it on `ProjectController:keypressed`).
   **Resolution: thread it through, as the trailing arg —
   `on_key_pressed(k, keys, isrepeat)`.** Grounding: `isrepeat` is
   read **nowhere** in the codebase (no controller, no console/
   editor, no example uses it). So rather than mirror LÖVE's native
   `(key, scancode, isrepeat)` order — which would put the
   never-used `isrepeat` ahead of the always-useful `keys` proxy —
   keep the common `(k, keys)` signature clean and trail `isrepeat`
   last. The cross-layer argument reorder is a deliberate, documented
   deviation (normal between framework levels); cheap to provide,
   available if held-key behaviour is ever wanted. Apply the same
   "useful args first, rarely-used native trailer last" ordering to
   `on_text_entered` and to `ProjectController:keypressed` for
   consistency.

4. **`compy.show` / `compy.hide` exposure milestone.** No roadmap
   milestone exposes them on the namespace, yet the M3 facades
   call `compy.show`. **Resolution:** expose `compy.show`/
   `compy.hide` in M2/M3 (they must exist before the facades use
   them); add to the milestone file lists.

5. **`compy.handlers` / `on_text_entered` co-firing** — resolved
   by Item 6's classification (Shift+letter is a character; combos
   stay silent). Cross-reference; no separate action.

6. **`summaries/design.md` Escape opt-in remark (settled — drop
   it).** The summary carries a parenthetical — "there should be
   path to keep current behaviour, opt-in … not specified now" —
   absent from `design.md`. **Resolution: drop the opt-in; remove
   the orphan remark from the summary; add nothing deferred to
   `design.md`.** Grounding (bug-vs-feature test against the code):

   - **Editor** owns Escape itself (`editorController.lua:441,486`
     mode exits / load); the sink's `cancel()` is not even invoked
     in the editor branch (`userInputController.lua:362` skips it).
     Nothing here depends on the sink's Escape.
   - **REPL** — the only `input:cancel()` is the programmatic
     terminal-test path (`consoleController.lua:967`), not a user
     Escape. User Escape at the REPL clears the current input line;
     the prompt staying up is the REPL being persistent, not an
     overlay being kept open.
   - **Project overlay** (this feature's scope) — Escape clears
     content and leaves the prompt up. That is exactly the
     limitation `design.md §5` fixes, and nothing relies on it:
     projects cannot dismiss prompts at all today.

   So within #77's scope the current Escape behaviour is a **bug**,
   relied on by nothing → drop it; the new dismiss-on-Escape is the
   fix, and opt-in/opt-out does not apply (opt-in is wrong for a
   bug; opt-out would only matter if it were a relied-upon feature,
   which it is not).

   **Carry-forward (not an Escape opt-in):** the REPL's "Escape
   clears the input line" is a genuine behaviour, but it belongs to
   the console-migration follow-on (D-7), where the migrated
   `ConsoleController` registers its own `framework_handlers['escape']`
   = clear-line. `framework_handlers` are per-controller, so
   `ProjectController`'s dismiss-Escape never clobbers it — nothing
   is lost. Fold this into Item 9's walkthrough rather than tracking
   it as an Escape opt-in.

7. **Dead `compy.text_input` alias.** `consoleController.lua:628`
   assigns `nil` (bare `input_text` not in scope). The new API
   replaces it; add an explicit cleanup line to the roadmap docs
   block so it isn't left dangling.

---

## Namespace isolation — relocate the new API under `compy.input.*`

*Cross-cutting and **orthogonal to Items 1–10**. This is a pure
relocation / naming concern, not a functional or architectural
change. Apply it as a **separate pass** (ideally last, after the
behavioural edits are in and verified), so it does not tangle with
the substance of the items above.*

### Decision (architect)

The new callback / lifecycle / accessor surface lives under a
dedicated sub-namespace **`compy.input.*`**, not flat on
`compy.*`.

Rationale: `compy.*` is the whole project-facing API and will
accumulate many unrelated callbacks, variables, and objects serving
different classes of purpose. Flat-mounting the input surface there
crowds the namespace and blurs concerns. A sub-namespace isolates
this feature's surface, keeps `compy.*` structured, and leaves room
for sibling sub-namespaces later. (`input` was chosen over the
earlier `terminal` working label: this surface is the interpretive
input-manipulation layer, and `compy.input.*` contrasts cleanly
with the raw `compy.keys_pressed` keyboard state — see *what does
NOT move* below.)

### Scope — what moves

Every *new* `compy.*` name introduced by feature #77 (including the
ones restored in Item 1) moves under `compy.input.*`:

| Was (in the chain as written) | Becomes |
|---|---|
| `compy.show` | `compy.input.show` |
| `compy.hide` | `compy.input.hide` |
| `compy.configure` | `compy.input.configure` |
| `compy.clear` | `compy.input.clear` |
| `compy.handlers` | `compy.input.handlers` |
| `compy.on_key_pressed` | `compy.input.on_key_pressed` |
| `compy.on_text_entered` | `compy.input.on_text_entered` |
| `compy.before_submit` / `after_submit` | `compy.input.before_submit` / `after_submit` |
| `compy.before_cancel` / `after_cancel` | `compy.input.before_cancel` / `after_cancel` |
| `compy.on_limit_reached` | `compy.input.on_limit_reached` |
| `compy.get_cursor` / `set_cursor` / `set_text` (Item 1) | `compy.input.get_cursor` / `set_cursor` / `set_text` |

### Scope — what does NOT move

- **Legacy global facades** — `input_text()`, `input_code()`,
  `validated_input()`, `user_input()`, `write_to_input()` — stay
  exactly where they are (project-env globals), unchanged. They are
  the backward-compat surface (D-1). Internally they call the
  relocated `compy.input.*` functions, but their own names and
  call sites do not change.
- **`keys_pressed` proxy** — stays global as `compy.keys_pressed`,
  **not** under `compy.input` (decided). It belongs to the
  keyboard-state mapping — physical reality — not the
  input-manipulation layer — interpretation. Keeping it out of
  `compy.input.*` makes that boundary explicit at the namespace
  level.

### Mechanics

- Pure rename/reparent in the docs: `compy.X` → `compy.input.X`
  across `design.md`, `spec.md`, `roadmap.md`, and the mirrored
  summaries. No behavioural change, no signature change.
- The roadmap milestones that "expose `compy.*` names on the
  namespace" (M2/M3 show/hide; M5 handlers/callbacks; M7
  configure/clear + cursor) now mount them on `compy.input.*`;
  add a one-line note that the `compy.input` table is created
  once at namespace setup and the names are mounted on it.
- Reset-on-stop (Item 8 / `stop_project_run`) clears
  `compy.input.handlers` and the `compy.input.*` callbacks
  together (implementation note, not a doc-pass action).

### Why a separate pass

It is mechanical and global; folding it into the Item 1–10 edits
would make both harder to review. Do the functional edits first,
verify, then run the relocation as a single find-and-reparent pass.
The two are independently checkable.

### Status

Decided (architect): isolate the new surface under `compy.input.*`;
`compy.keys_pressed` stays global. Mechanical relocation,
orthogonal to Items 1–10. No open sub-points.
