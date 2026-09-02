# Validation Report — Feature #77 Document Chain

*Independent review of the feature #77 document chain
(`input.md` → `requirements.md` → `assessment.md` →
`decisions.md` → `design.md` → `spec.md` → `roadmap.md`) and the
`summaries/`. Claims about current behaviour were checked against
`src/`. Reviewer role only — findings, not rewrites.*

*Convention note: the seven decisions are labelled D-1…D-7 in the
prose of `decisions.md` but never numbered inline (only in the
"Quick reference" table). References below use that table's
numbering.*

---

## Status: FAIL

The chain is coherent on its central idea (routing unification +
persistent singleton + callbacks) and most requirements are
carried through cleanly. Three classes of issue need resolution
before implementation, because they would either drop a stated
requirement, break a listed must-pass example, or hand the
implementor contradictory contracts:

1. **FR-8, FR-9, FR-10 (cursor query, cursor set, live text
   change) drop out of the chain** after `assessment.md`. They
   have no API surface in `spec.md` and no roadmap home; FR-9 is
   actively contradicted by the `configure()` contract.
2. **Roadmap ordering strands the submit path.** M2 deletes the
   `oneshot` flag (which currently drives submit + the
   `'userinput'` push) while the replacement
   (`framework_handlers['return']`) does not arrive until M6 —
   so submit is broken across M2–M5, contradicting M2's
   "zero behaviour change" and M3's "all examples work".
3. **`compy.on_key_pressed` has two contradictory contracts.**
   `decisions.md` and `design.md` make it a consuming dispatch
   level; `spec.md §3` says its return value is ignored.

"FAIL" here means "do not start coding against this yet," not
"the direction is wrong." The architecture is sound; the gaps are
in completeness and cross-document consistency, which is expected
for a draft that (per the commit log) has not yet been
cross-checked.

---

## Findings by dimension

### 1. Requirements coverage

| Req | decisions | design | spec | roadmap | Status |
|---|---|---|---|---|---|
| FR-1 setup (text/cursor/highlighter/validator/prompt) | D-2 | §3 `compy.show` | §2 config table | M2/M3 | **Covered** (see note a) |
| FR-2 remove/teardown | D-2 (implicit) | §1 `hide` | §2 `hide()` | M2 | **Covered, reframed** (note b) |
| FR-3 hide | D-2 | §3 | §2 `hide()` | M2 | **Covered** (note c) |
| FR-4 show | D-2 | §3 | §2 `show()` | M2 | **Covered** (note c) |
| FR-5 submit notification | D-4 | §5 | §3 `before/after_submit` | M6 | **Covered** |
| FR-6 non-char key notification | D-3 | §4 | §3 | M5 | **Covered** (see dim. 2 contradiction) |
| FR-7 boundary notification | D-5 | §3 table | §4 `on_limit_reached` | M6 | **Covered** (note d) |
| FR-8 query cursor while active | — | §1 prose only | **absent** | **absent** | **GAP** |
| FR-9 set cursor while active | — | §1 prose only | **contradicted** | **absent** | **GAP** |
| FR-10 change text while active | — | §3 `clear` only | **no live-write** | **absent** | **GAP** |
| FR-11 REPL re-implementable | D-7 | §7 (asserted) | §6 | follow-on | **Asserted, not shown** (note e) |
| FR-12 editor re-implementable | D-7 | §7 (asserted) | §6 | follow-on | **Asserted, not shown** (note e) |
| NFR-1 no per-session alloc | D-2 | §2/§3 singleton | §2 | M2 | **Covered** |
| NFR-2 event-driven | D-3/D-4 | §4/§5 | §3 | M5/M6 | **Covered** |
| NFR-3 compy namespace consistency | D-3 | §3 | §2/§5 | M5/M7 | **Covered** (note f) |
| NFR-4 pedagogical simplicity | — | §1 | — | — | **Covered implicitly** |

**GAP — FR-8 (query cursor position while active).** Listed in
`requirements.md §2.4`; `assessment.md §4` confirms the model API
(`UserInputModel:get_cursor_pos`) is complete and "exposure is
the only missing piece"; `design.md §1` states the feature adds
"programmatic cursor and content access." But no `compy.*`
function to read the cursor appears in `design.md §3`'s component
table or in `spec.md §2`. `notes/solution_sketch.md §2` listed a
`read()` call in the intended API surface; it was not carried into
`design.md` or `spec.md`. No roadmap milestone delivers it.

**GAP — FR-9 (set cursor position while active).** Same drop as
FR-8, and additionally **contradicted**: `spec.md §2`
(`compy.configure`) states "Fields `text` and `cursor` are
accepted but have no effect when called on an already-active
session," and `compy.clear()` only resets the cursor to position
1. So the spec's only cursor controls are (a) initial position at
`show()` and (b) reset-to-1 at `clear()`. FR-9 asks to *change*
the cursor position while the area is active; the spec explicitly
forecloses it. `UserInputModel:move_cursor(y, x)` /
`set_cursor(c)` exist (`userInputModel.lua:499,506`) but remain
unexposed.

**GAP — FR-10 (change text content while active).** The current
mechanism is `write_to_input(content)`
(`consoleController.lua:599–605`), which `assessment.md §4` names
as the FR-10 path. In the new chain:
- `compy.configure` ignores `text` while active (`spec.md §2`);
- `compy.clear` only empties content (`spec.md §2`);
- `compy.show` replaces content but is the activation call, not a
  live-write;
- there is no `compy.set_text` / live-write function anywhere in
  `design.md` or `spec.md`.

So no path changes text on an already-active session. This also
intersects backward compatibility — see dim. 6, `write_to_input`.

Notes:
- (a) FR-1 "initial cursor position" is delivered only as the
  `cursor` field at `show()` time (`spec.md §2`), which is correct
  for FR-1; it is FR-9's *while-active* change that is missing.
- (b) FR-2 asks for programmatic *removal*. The singleton design
  has no teardown by construction; `hide()` is the
  project-observable equivalent. This is a reasonable resolution
  but is never stated as the FR-2 answer — worth making explicit
  so a stakeholder reading FR-2 ("remove") finds the mapping.
- (c) FR-3/FR-4 are covered behaviourally, but the *exposure* of
  `compy.show`/`compy.hide` on the namespace has no explicit
  roadmap milestone — see dim. 4.
- (d) `design.md` proper is thin on FR-7: `on_limit_reached`
  appears in the §3 component table but the limit-signal plumbing
  (sink return → hook) lives in `notes/routing_unification.md`,
  not the design body.
- (e) See dim. 2, D-7.
- (f) The existing dead `compy.text_input` alias (see dim. 6) has
  no explicit cleanup line in the roadmap; minor.

### 2. Decision consistency

- **D-1 (backward compat)** — Reflected in `design.md §6` and
  `spec.md §5` (facade wrappers, reftable fill, `strict_input`
  future flag). Consistent across documents. One omission:
  `write_to_input` is not in the facade list (dim. 6).
- **D-2 (second setup / singleton)** — Reflected consistently:
  `design.md §2/§3`, `spec.md §7` ("`show()` while already active
  → reconfigures in-place, no cancel chain"). Consistent.
- **D-3 (key event coverage)** — Three-level dispatch carried
  into `design.md §4` and `spec.md §3`. **Inconsistency:** the
  combo-string examples violate the stated sort rule (see dim. 3),
  and the `on_key_pressed` return-value contract contradicts D-4
  (next item). Minor signature drift: D-3 specifies
  `_on_key_pressed(k, pressed, isrepeat)`; `spec.md §3`
  `compy.on_key_pressed(k, keys_pressed)` drops `isrepeat`
  (it survives only on `ProjectController:keypressed` in
  `spec.md §1`).
- **D-4 (cancel/submit chains; oneshot deletion)** —
  **Contradiction with `spec.md`.** D-4 (`decisions.md:250–251`)
  states "The generic `compy.on_key_pressed` uses return-value
  propagation (true = consumed, nil = bubble)." `design.md §4`
  agrees: "At every level, a handler returning a truthy value
  signals 'consumed' and stops the chain." But `spec.md §3`
  (`compy.on_key_pressed`) states: "Return value is ignored. To
  prevent the sink from processing a key, register it in
  `compy.handlers` and return truthy." These cannot both hold:
  either `on_key_pressed` is a consuming dispatch level (D-4 /
  design) or it is a passive notifier (spec). Also: the oneshot
  deletion is tied by D-4 to the framework owning submit via
  `framework_handlers['return']` — which the roadmap schedules in
  M6, while it deletes the flag in M2 (see dim. 5).
- **D-5 (boundary)** — `on_limit_reached(direction)`,
  whole-input boundary, reserved 2nd arg: consistent across
  `design.md §3`, `spec.md §4`. Matches code
  (`UserInputModel:is_at_limit`, `userInputModel.lua:558–570`).
- **D-6 (modifier + character)** — Carried into `spec.md §3`.
  **Minor inconsistency:** D-6 says project code receives
  `on_text_entered(text, mods)` where `mods` is "the implicit
  modifiers table" (non-character keys only); `spec.md §3` passes
  the full `keys_pressed` read-only proxy, not a filtered
  modifier subset. Also the suppression mechanism is declared but
  not specified — see dim. 3.
- **D-7 (rollout scope)** — Reflected in `design.md §7`,
  `spec.md §6`. **Unmet promise:** D-7 states "`design.md` will
  include a walkthrough confirming the API surface covers both
  cases [console + editor]." `design.md §7` asserts the migration
  is mechanical ("if-chains become handler registrations") but
  contains no actual walkthrough mapping the console's
  history-nav / `Ctrl+L` and the editor's `Ctrl+M`/`Ctrl+F` mode
  switches onto the new API. The promised FR-11/FR-12 evidence is
  asserted, not shown (the analysis is gestured at in
  `notes/editor_repl_input.md`, but D-7 located it in
  `design.md`).

### 3. Design-to-spec completeness

- **`design.md §1` over-claims relative to `spec.md`.** Design
  scope says the feature adds "programmatic cursor and content
  access." The spec provides neither a cursor accessor/mutator nor
  a live-text mutator (FR-8/9/10, dim. 1). Either design scope
  should be narrowed or the spec should add the surface.
- **`compy.show`/`compy.hide` lack edge-case specification on a
  point design raises.** `design.md §3` notes "No access control
  is enforced"; `spec.md §2` repeats it. Fine. But the
  interaction with a project's *own* `love.keypressed`/`textinput`
  (see dim. 6) is described in neither — a real design element
  (the `love.keypressed` slot, `controller.lua:73–107`) with no
  spec contract.
- **Combo serialisation: examples contradict the stated rule.**
  `spec.md §1` states "Sorting is alphabetical on the raw LÖVE2D
  key name strings … all held keys are sorted together." The
  worked examples violate this:
  - `"lalt+lshift+f4"` (`spec.md §1`, `design.md §4`) —
    alphabetical order of {`f4`,`lalt`,`lshift`} is
    `"f4+lalt+lshift"` (`f` < `l`).
  - `compy.handlers['lctrl+l']` (`spec.md §3`) — alphabetical
    order of {`l`,`lctrl`} is `"l+lctrl"` (`"l"` is a prefix of
    `"lctrl"`, so it sorts first).
  Only `"lctrl+s"` happens to match. An implementor who registers
  combos following the documented (modifier-first) examples will
  produce keys the serialiser never generates, so those handlers
  silently never fire. Resolve by either defining a
  modifier-priority ordering (matching the natural examples) or
  fixing the examples to be truly alphabetical.
- **`on_key_pressed` suppression mechanism declared but not
  specified.** `spec.md §3` / `decisions.md` D-6 require:
  suppress `on_key_pressed` for a key that is "followed by a
  `textinput` event in the same frame." LÖVE delivers
  `keypressed` *before* `textinput`, so at `keypressed` dispatch
  time the framework cannot yet know whether a character will
  follow. The spec says "This suppression logic is a spec detail"
  but does not say *how* the lookahead/deferral works. This is the
  load-bearing mechanism for D-6's "no double callback" guarantee
  and the hardest part of the feature; leaving it unspecified
  pushes a non-trivial design decision onto the implementor.
- **`compy.handlers[combo]` can still co-fire with
  `on_text_entered` for character combos.** The D-6 "exactly one
  notification per gesture" guarantee covers `on_key_pressed` vs
  `on_text_entered` only. `compy.handlers[combo]` is dispatched at
  `keypressed` time regardless of whether a character follows, so
  e.g. `Shift`+letter (a capital character) can match a registered
  combo handler *and* fire `on_text_entered`. Either intended or
  an unaddressed corner; `spec.md` should state which.
- **`compy.before_submit` argument inconsistency.** `design.md §5`
  shows `before_submit(keys_pressed)` and `spec.md §3` agrees, but
  the summary callback table lists no arg surprises — fine. No
  finding beyond noting the arg is documented.

### 4. Spec-to-roadmap coverage

- **GAP — `compy.show` / `compy.hide` exposure has no milestone.**
  These are the primary entry points (`design.md §3`,
  `spec.md §2`). Roadmap milestones expose specific surfaces on
  the namespace: M5 exposes `compy.handlers`,
  `compy.on_key_pressed`, `compy.on_text_entered`; M7 exposes
  `compy.configure`, `compy.clear`. M2 adds `show()`/`hide()`
  *methods on the controller*, not `compy.show`/`compy.hide` on
  the project namespace. No milestone's file list exposes
  `compy.show`/`compy.hide`. (M3 facades call them internally,
  which assumes they already exist — see dim. 5.)
- **GAP — FR-8/9/10 surface (cursor get/set, live text) has no
  milestone**, consistent with their absence from the spec
  (dim. 1).
- **`compy.before_submit`/`after_submit`/`before_cancel`/
  `after_cancel` / `on_limit_reached`** — delivered by M6.
  Covered.
- **Edge cases (`spec.md §7`)** — the test-coverage block
  enumerates "stop-while-active, show while active, evaluation
  failure" — matches `spec.md §7`. Covered.
- **Documentation block** — names `internals/`, `overview.md`,
  and stale-note archival. Adequate, though it does not call out
  updating `internals/console.md` (which documents the reftable /
  `write_to_input` semantics that this feature changes) or
  `internals/examples/tixy.md` (documents `write_to_input`).

### 5. Roadmap ordering validity

- **Ordering defect — `oneshot` deletion (M2) strands submit
  until M6.** `roadmap.md` M2 lists
  "`src/userInputController.lua` — remove `oneshot` flag" and
  claims "Zero behaviour change." In the current code the oneshot
  flag is what gates the submit path (`userInputController.lua:346`
  `… and input.oneshot then`) and what triggers the `'userinput'`
  push (`userInputModel.lua:812–819`). Its replacement —
  `framework_handlers['return']` in `ProjectController` owning
  submit — is delivered in **M6** (`roadmap.md` M6;
  `design.md §5`; `decisions.md` D-4). Therefore:
  - M2 cannot both delete `oneshot` and be "zero behaviour
    change"; deleting it removes submit + the `'userinput'` push.
  - M3 (legacy facades) claims "all existing examples work," but
    examples that submit on Enter (repl, guess, tixy) have no
    working submit path between M2 and M6.
  - `decisions.md` D-4 itself ties the deletion to D-4's
    framework-owned submit ("deleted as a consequence of D-2
    combined with D-4"), i.e. it logically belongs with M6, not
    M2.
  Recommended: keep `oneshot` until the M6 submit ownership lands,
  or move the submit-via-`framework_handlers` step earlier.
- **M3 depends on M6's `after_submit`.** `spec.md §5` defines each
  legacy wrapper as "Registers a `compy.after_submit` callback
  that fills the reftable." `after_submit` is delivered in M6. M3
  is scheduled before M4–M6. So M3 as specified depends on a
  later milestone's hook. (If M3 instead keeps the existing
  reftable-fill path in `UserInputController:keypressed`, that
  path is exactly the `oneshot` submit path M2 removes — same
  knot as above.)
- **M2 "depends on M1" is a sequencing choice, not a real
  dependency.** Singleton extraction (M2) does not use the
  `keys_pressed` table (M1). Harmless (linear order is safe) but
  the stated dependency overstates coupling; `design.md §7`'s
  "linear from 1 through 4" is conservative rather than necessary
  for the 1→2 edge.
- M4→M5, M4→M6 (M6 independent of M5), M2→M7: these ordering
  claims hold.

### 6. Factual accuracy against codebase

| # | Claim | Verdict | Note |
|---|---|---|---|
| 1 | Overlay gate `if user_input then … else … end` exists at the described location in `controller.lua` | **CONFIRMED** | `controller.lua:625–630`, inside `handlers.keypressed` (= `love.handlers.keypressed`, assigned from `love.handlers` at line 526). |
| 2 | `UserInputController:keypressed` is the shared sink for REPL/editor and overlay branches | **CONFIRMED** | Same method, branches on `app_state == 'editor'` (`userInputController.lua:362`); called by `ConsoleController` via `self.input:keypressed` (`consoleController.lua:1000`) and by the overlay via `user_input.C:keypressed` (`controller.lua:627`). |
| 3 | `oneshot` flag controls the submit path in `UserInputController` | **CONFIRMED (gate) / MISMATCH (location)** | The flag does gate submit (`userInputController.lua:346`), but it is a field of **`UserInputModel`** (`userInputModel.lua:15,49`), read as `self.model.oneshot`/`input.oneshot`. `design.md §3`, `decisions.md` D-4, and `roadmap.md` M2 all call it "the `oneshot` flag on `UserInputController`" and M2 places its removal in `userInputController.lua`; the field actually lives in `userInputModel.lua`. |
| 4 | `love.state.user_input` is set by the project input functions and read by the overlay gate | **CONFIRMED, with nuance** | Set by the internal `input()` (`consoleController.lua:576`), called by `input_text`/`input_code`/`validated_input`; read at the gate (`controller.lua:625`); cleared by `handlers.userinput` (`controller.lua:709–713`). Nuance: **`user_input()` itself does not set it** — it only allocates the reftable (`consoleController.lua:582–585`). This matters for spec §5 (next finding). |
| 5 | `ConsoleController` is wired into `love.keypressed` at startup | **CONFIRMED** | `set_love_keypressed` sets `love.keypressed` to a closure calling `CC:keypressed(k)` (`controller.lua:161–191`), invoked via `set_default_handlers`. |
| 6 | The before/after chain mechanism does not yet exist (new addition, not a refactor) | **CONFIRMED** | No `before_*`/`after_*` hooks anywhere in the controllers/model; submit/cancel run framework logic directly. |

Additional factual issues found while verifying:

- **MISMATCH — `assessment.md §2` and `§8`: "cancel pushes
  `'userinput'`."** `assessment.md §2` (FR-2) states "on submit
  or cancel, `UserInputModel:handle()` / `cancel()` pushes a
  LÖVE2D `'userinput'` event (`userInputModel.lua:819`)," and
  `§8` ("Cancel path") repeats that Escape's `cancel()` pushes
  `'userinput'` and clears the overlay. The code shows otherwise:
  `cancel()` calls `handle(false)` (`userInputModel.lua:795–798`);
  in `handle`, the `'userinput'` push is reached only on the
  `eval == true` *and* `self.oneshot` *and* success path
  (`userInputModel.lua:809–821`). With `eval == false` the code
  takes the `else ok = true` branch and **does not push**. So
  Escape clears content (via `reset()`) but does **not** dismiss
  the overlay. This is, in fact, exactly the "current limitation"
  `design.md §5` is built to fix ("Escape clears input content but
  does not dismiss the overlay") — i.e. `assessment.md` contradicts
  the premise the design correctly relies on. The design is right;
  the assessment statement is the error.

- **MISMATCH — `spec.md §5`: `user_input()` ≡ `compy.show({})`.**
  The legacy table maps `user_input()` to "`compy.show({})`;
  returns reftable." Current `user_input()` does **not** display
  an input area — it only creates the reftable
  (`consoleController.lua:582–585`); the overlay appears on a
  later `input_text()`/`input_code()`/`validated_input()` call
  (the canonical pattern in `assessment.md §6` / NFR-4). If the
  facade makes `user_input()` call `compy.show({})`, it will pop
  an empty input area immediately — a behaviour change from
  today's "allocate reftable, show nothing." Worth either
  preserving current semantics (reftable-only) or flagging the
  change explicitly.

- **GAP — project-owned `love.keypressed`/`love.textinput` vs.
  `ProjectController` slot ownership.** `spec.md §6` states
  "`ProjectController:keypressed` IS the `love.keypressed`
  occupant during project execution." Today, a project's own
  `function love.keypressed` is installed into that exact slot via
  `set_user_handlers`/`hook_if_differs` (`controller.lua:73–107`),
  and several shipped examples rely on it — `pong/main.lua:315`,
  `life/main.lua:109`, `paint/main.lua:387`,
  `turtle/main.lua:35` (turtle uses native `love.keypressed`
  *and* `input_text`). The chain does not say how a project's
  native `love.keypressed`/`textinput` is invoked once
  `ProjectController` owns the slot: `compy.on_key_pressed`
  defaults to "noop + log" (`spec.md §3`), so unless
  `ProjectController` calls the saved user handler, these
  examples' keyboard input would stop working. This is a
  backward-compatibility surface as real as the `input_text`
  facade, but D-1 and `design.md §6` scope backward compat to the
  four input functions only.

- **MISMATCH — `write_to_input` omitted from backward compat,
  but a listed must-pass example uses it.** `assessment.md §4`
  names `write_to_input` (`consoleController.lua:599–605`) as the
  FR-10 mechanism. It is used by `tixy` (`examples/tixy/main.lua:39`,
  `vadexamples/tixy/main.lua:50`) and documented
  (`internals/console.md`, `internals/examples/tixy.md`). The
  backward-compat facade lists (`design.md §6`, `spec.md §5`) and
  the M3 milestone cover only `input_text`/`input_code`/
  `validated_input`/`user_input`. `write_to_input` appears nowhere
  in `decisions.md`/`design.md`/`spec.md`/`roadmap.md`, yet M3
  asserts "all existing examples (… tixy …) work." Either add
  `write_to_input` to the facade set (it is also the natural
  FR-10 live-write surface) or document its removal.

- **CONFIRMED — dead `compy.text_input` alias.** `assessment.md`
  NFR-3 and `summaries/assessment.md` claim
  `compy_namespace.text_input = input_text`
  (`consoleController.lua:628`) assigns `nil` because the bare
  `input_text` identifier is not in scope (the function is
  `project_env.input_text`, a table field, not a local/global).
  Verified: there is no `local input_text` and no global; the
  assignment is `nil`. The assessment's claim is accurate.

- **Loose reference — "resets … via the same mechanism as
  `evacuate_required`."** `design.md §3`, `spec.md §3`/§6, and
  `decisions.md` D-7 say `compy.handlers`/callbacks reset on
  project stop "via the same mechanism as `evacuate_required`."
  `ConsoleController:evacuate_required` (`consoleController.lua:844–858`)
  unloads the project's `.lua` modules from `package.loaded`; it
  does not reset handlers or callbacks. The actual stop-time reset
  happens in `stop_project_run` (`consoleController.lua:860–868`:
  `clear_user_handlers()`, `love.state.user_input = nil`, …). The
  cited function is the wrong reference for what the docs describe.

### 7. Summary fidelity

- **`summaries/requirements.md`** — Faithful. Mentions cursor
  read/set and text replacement (FR-8/9/10), consistent with the
  source. No invented claims. (Note: these summarised requirements
  are the very ones that later drop out of design/spec — a
  fidelity-clean summary of a requirement that the downstream
  chain fails to deliver.)
- **`summaries/assessment.md`** — Faithful to `assessment.md`,
  including the confirmed `compy.text_input` bug and the balloons
  limitation. It does **not** repeat the assessment's
  cancel-pushes-`'userinput'` error (dim. 6), so the summary is
  actually cleaner than its source on that point — no fidelity
  violation, but note the source error is not propagated.
- **`summaries/decisions.md`** — Faithful; the at-a-glance table
  matches `decisions.md`'s. It carries the same `on_key_pressed`
  return-value model as D-4, so it inherits (does not introduce)
  the contradiction with `spec.md` (dim. 2).
- **`summaries/design.md`** — One **added claim not in the
  source**: the closing parenthetical "(remark: there should be
  path to keep current behaviour, opt-in -- possible with new
  architecture but not specified now)" on the Escape fix. This
  opt-in-to-preserve-current-Escape idea does not appear in
  `design.md` or `spec.md`. It reads as an editorial margin note
  and is a useful flag, but per the fidelity criterion it is
  content present in the summary and absent from the full
  document. Recommend promoting it into `design.md`/`spec.md` as a
  real open item or removing it from the summary.
- **`summaries/spec.md`** — Faithful to `spec.md`, including the
  `user_input() ≡ compy.show({})` mapping (so it inherits that
  factual issue, dim. 6) and the `on_text_entered(text,
  keys_pressed)` signature. Its three-level-dispatch box says
  "Return truthy at any level to consume," which matches
  `design.md` but contradicts `spec.md §3`'s "Return value is
  ignored" for `on_key_pressed` — i.e. the summary mirrors the
  source spec's own internal inconsistency rather than introducing
  a new one.
- **`summaries/roadmap.md`** — Faithful; milestone table and
  estimate figures match `roadmap.md`.

---

## Summary of actionable items

Ordered roughly by blocking severity.

1. **Restore FR-8/FR-9/FR-10 to the design and spec, or
   explicitly de-scope them.** Add `compy.*` surface for cursor
   query, cursor set (while active), and live text write — or
   record a decision dropping them and update `requirements.md`
   /traceability accordingly. As written they are required,
   acknowledged in assessment, claimed in `design.md §1` scope,
   and then absent from `spec.md`/`roadmap.md`; FR-9 is actively
   contradicted by `compy.configure`'s contract. (dims. 1, 3, 4)

2. **Fix the M2/M6 submit-path ordering.** Keep `oneshot` (or its
   submit/`'userinput'`-push behaviour) until
   `framework_handlers['return']` lands, so submit and the legacy
   reftable fill keep working across M2–M5. Reconcile with M2's
   "zero behaviour change" and M3's "all examples work," and with
   D-4 tying the deletion to framework-owned submit. (dims. 2, 5)

3. **Resolve the `compy.on_key_pressed` return-value
   contradiction.** Decide whether it is a consuming dispatch
   level (D-4 / `design.md §4`) or a passive notifier whose return
   is ignored (`spec.md §3`), and make all three documents agree.
   (dim. 2)

4. **Specify how a project's native `love.keypressed`/
   `love.textinput` interacts with `ProjectController` owning the
   slot.** Shipped examples (pong, life, paint, turtle) rely on
   native handlers. Define whether `ProjectController` invokes the
   saved user handler, or document the migration to
   `compy.on_key_pressed` as a backward-compat break. (dim. 6)

5. **Add `write_to_input` to the backward-compat facade set (or
   document its removal).** `tixy` — listed as a must-pass example
   in M3 — depends on it; it is also the natural FR-10 live-write
   surface. (dims. 1, 6)

6. **Specify the `on_key_pressed` suppression mechanism.** Define
   how the framework distinguishes character-producing keypresses
   (suppress) from non-character ones (emit), given LÖVE delivers
   `keypressed` before `textinput`. This is D-6's load-bearing
   guarantee and is currently deferred without a mechanism.
   (dim. 3)

7. **Fix the combo-string examples to match the alphabetical sort
   rule, or define modifier-priority ordering.** `"lalt+lshift+f4"`
   and `compy.handlers['lctrl+l']` do not match the
   alphabetical-sort serialiser the spec describes; handlers
   registered per the examples would never fire. (dim. 3)

8. **Correct the codebase-reference errors so the assessment
   matches the design's premise:** `cancel()` does not push
   `'userinput'` (Escape does not dismiss today — which is the
   point of the feature); the `oneshot` flag is a `UserInputModel`
   field, not a `UserInputController` one (update D-4, `design.md
   §3`, and M2's file target); and the stop-time reset is
   `stop_project_run`/`clear_user_handlers`, not
   `evacuate_required`. (dims. 2, 6)

9. **Deliver the D-7 FR-11/FR-12 walkthrough promised for
   `design.md`,** or relocate the promise to
   `notes/editor_repl_input.md` and have D-7 cite it there.
   (dim. 2)

10. **Reconcile the smaller drifts:** `user_input() ≡
    compy.show({})` (current `user_input()` shows nothing);
    `on_text_entered` second arg (`mods` subset per D-6 vs full
    `keys_pressed` proxy per spec); `isrepeat` presence on
    `on_key_pressed`; `compy.handlers[combo]` co-firing with
    `on_text_entered` for character combos; exposure milestones
    for `compy.show`/`compy.hide`; and the
    `summaries/design.md` Escape opt-in remark not present in the
    source. (dims. 1, 2, 3, 4, 7)
