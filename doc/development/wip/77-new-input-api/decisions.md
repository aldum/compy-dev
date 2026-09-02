# Feature #77 — Blocking Decisions

> **Status — local design proposal, with one stakeholder ruling.** This
> document is a local design proposal derived from `input.md`, with one
> exception: **D-1 has been ruled on by stakeholders** (consensus in
> `input.md`, feedback round 1, 2026-06-06: **DISCARDED** — no backward
> compatibility). D-1's resolution below is therefore stakeholder ground
> truth, not a proposal. The remaining entries (D-2…D-10) are still a local
> proposal awaiting a single eventual approve/veto review against `input.md`;
> none of those is stakeholder-approved.

## The blocking decisions

Seven questions were identified during requirements analysis
and architecture assessment that require stakeholders consensus
— they involve tradeoffs with broad impact across the codebase, 
existing examples, and future API ergonomics.

1. **Backward compatibility** — must the existing input
   functions continue to work after the new API is introduced?
2. **Second setup call** — what happens when a project tries
   to configure input while it is already active?
3. **Key event coverage** — how should different kinds of
   non-text key events (modifier combos, plain navigation
   keys, function keys) be surfaced to project code?
4. **Cancel and submit notifications** — should these be
   dedicated named events, and how does the framework's own
   teardown relate to project callbacks?
5. **Cursor boundary definition** — in a multiline input
   area, what exactly constitutes hitting a wall?
6. **Modifier + character co-occurrence** — when a
   character key is pressed with a modifier held, one event
   or two?
7. **Rollout scope** — does the new event topology apply to
   all input contexts at once, or the project overlay first?

These seven remain the core of the stakeholder review. Three
further commitments were added during the local design rounds and
are recorded here for completeness and traceability: **D-8**
(cursor restoration + 2D contract) and **D-9** (native handler
coexistence) from round 1, and **D-10** (namespace isolation under
`compy.input.*`) from round 2. They are not new stakeholder
questions — D-8 restores a dropped requirement, D-9 closes a
backward-compat surface, D-10 is a packaging choice — but each is
a genuine architectural decision and is listed below with its
provenance.

---

## Proposed resolution

A design approach (described below) has been developed 
that resolves all seven decisions coherently. Full rationale is in `notes/decisions.md`.

**Stakeholders:** if the direction is acceptable, work
proceeds to `design.md` and the full implementation plan
(fast-track). If any aspect is problematic, the relevant
decision(s) are re-opened for re-settlement.

---

### Terminology

**Project overlay** — the input area a running project
creates by calling `input_text()`, `input_code()`, or
similar. It appears over the project's running display and
is stored in `love.state.user_input`. It is distinct from
the console REPL's own input strip and the editor's input
strip, which are separate persistent instances that are not
affected by the changes described below.

**Persistent input widget** — the lifecycle model proposed
for the overlay: one object, created once at startup, reused
across all sessions rather than created and discarded on
each call.

**Event callbacks** — the notification model: project code
registers functions that the framework calls when specific
events occur, replacing the current pattern of polling a
reference variable on every frame.

---

### The approach in brief

The structural basis is routing unification. The
`if user_input then ... else ... end` gate in
`love.handlers.keypressed` (`controller.lua`) is removed.
A new `ProjectController` — a sibling to `ConsoleController`
and `EditorController` — takes ownership of all input
handling for the project-running context. `UserInputController`
becomes the universal terminal sink at the bottom of every
branch: always present, never a routing destination.
This structural change is what makes the three improvements
below possible without special cases. See
`notes/routing_unification.md` for the full before/after
diagram and rationale.

The design addresses the requirements in `requirements.md`
through three connected changes:

**1. The overlay input widget becomes persistent** (addresses
FR-1, FR-2, FR-3, FR-4, NFR-1). Instead of being created
on each `input_text()` call and discarded after submission,
the widget is created once when the application starts and
reused. Projects call `show`, `hide`, and `configure` on it
rather than creating it. This eliminates the per-session
allocation identified in NFR-1, and makes dynamic prompt
changes (such as updating a label mid-run) straightforward.

The wiring change that implements this — moving construction
from inside `ConsoleController` to `main.lua` — is a
contained refactor with no behaviour change. It can be done
and verified independently before the rest of the work.

**2. Keyboard events reach project code while a prompt is
active** (addresses FR-5, FR-6, FR-7, NFR-2). Currently,
all key events are consumed by the overlay with no
notification to the project. The new API exposes three
surfaces: a table of currently-held keys (so modifier state
is always available), project-registered handlers for
specific key combinations, and overloadable callbacks for
key events and text input. All three receive the same
live key state, so modifier context is implicit rather than
requiring a separate event.

Submit and cancel are named callback points with a
before/after structure: project code can run before the
framework's own teardown, or after it, without being able
to accidentally suppress it. The framework always runs its
own structural behaviour (evaluate on Enter, close on
Escape); projects extend rather than replace it.

**3. The legacy text-input API is removed** (addresses D-1,
**discarded** by stakeholders — see `input.md` round 1).
`input_text()`, `input_code()`, `validated_input()`,
`user_input()`, and `write_to_input()` are removed, not kept
as facades. The reftable / `is_empty()` polling pattern goes
with them. The in-repo examples that use these functions are
migrated to the `compy.input.*` callback API (priority:
`tixy`, `balloons`; the rest convert-or-exclude per the owner's
release call). This is scope **3** of the design; it does not
affect the native-handler coexistence path (D-9), which is a
separate surface and is retained — only text-input examples are
affected ("only text fields", per `input.md`).

---

### Quick reference

| | Decision | Resolution |
|---|---|---|
| D-1 | Backward compat | **Discarded** (stakeholder consensus, `input.md` round 1): no backward compatibility. Legacy text-input globals removed; examples migrated (`tixy`/`balloons` priority) or excluded from the release. D-9 native coexistence is unaffected. |
| D-2 | Second setup call | Dissolved — singleton accepts configure/show, no create |
| D-3 | Key event coverage | Three-tier dispatch; sink is default of `on_key_pressed`; modifier-first generic-folded combo format; metatable-normalised registration; overloadable matcher |
| D-4 | Cancel/submit | Named chains: `before_X → X → after_X`; framework owns middle; `oneshot` is `UserInputModel` field, deleted in M6 |
| D-5 | Boundary | `on_limit_reached(direction)` hook; whole-input boundary; second arg reserved |
| D-6 | Modifier + character | Superseded (round 1): two independent channels, no exclusivity; `on_text_entered(text, keys_pressed)` |
| D-7 | Rollout scope | Overlay context first; FR-11/FR-12 walkthrough added to `design.md §7` |
| D-8 | Cursor contract + live surface | 2D `(line, col)` source-line coords; `compy.input.get_cursor`, `compy.input.set_cursor`, `compy.input.set_text`; `set_text` supersedes the removed `write_to_input` |
| D-9 | Native handler coexistence | Auto-provisioning via legacy heuristic; lifecycle-split wrapper; transition diagnostics |
| D-10 | Namespace isolation | New feature-#77 surface lives under `compy.input.*`; `compy.keys_pressed` stays global; legacy text-input globals removed (D-1 discarded) |

---

## Per-decision detail

### D-1 · Backward compatibility

**Question:** Must the existing functions `input_text()`,
`input_code()`, `validated_input()`, and `user_input()` continue
to work after the new API is introduced?

**Context:** Every current example (repl, tixy, guess, turtle,
valid, balloons) uses these functions with the polling pattern.
A clean break simplifies the new API design but requires
updating all examples. Keeping them as shims allows gradual
migration but adds a maintenance surface.

**Affects:** Overall API shape, whether examples need
updating, implementation scope.

**Source:** `requirements.md §5`; **resolved by `input.md`
feedback round 1 (2026-06-06).**

**Stakeholder decision: DISCARDED — no backward compatibility.**
The project is pre-1.0; all software that uses the input API is
known and must be updated anyway (and benefits from doing so).
Keeping the legacy functions in a release would defeat the
purpose of shipping the new API. Consensus reached among three
stakeholders (full dialogue in `input.md`).

Consequences:

- `input_text()`, `input_code()`, `validated_input()`,
  `user_input()`, and `write_to_input()` are **removed** from
  the project environment — no facades, no deprecation shims,
  no `strict_input` flag. The reftable / `is_empty()` polling
  idiom is removed with them.
- The in-repo examples that use these functions are migrated to
  the `compy.input.*` callback API (see roadmap **M8**). Migration
  priority is the showcase set the owner named: `tixy` and
  `balloons` (and `maze`, not yet in the repo). The remaining
  text-input examples (`repl`, `guess`, `valid`, `turtle`) are
  converted if time allows, otherwise excluded from the next
  release — the owner's call at release time, not a blocker.
- **Scope is text input only.** The native `love.keypressed` /
  `love.textinput` coexistence path (D-9) is a separate surface
  and is **retained** — games that drive their own keyboard
  handling keep working. Per the stakeholder exchange, removing
  the legacy API "won't break all keyboard input, only text
  fields". Old releases remain available, so the existing
  experience is not deleted while migration proceeds.

*(Stakeholder feedback, round 1, 2026-06-06. The earlier
"Suggested decision" — keep backward-compatible facades — is
superseded by this ruling.)*

---

### D-2 · Second setup call while input is active

**Question:** What should happen when a setup call is made
while an input area is already active?

**Context:** The current behaviour is a silent no-op (the
singleton guard returns immediately). This was a concrete
limitation — changing a prompt label mid-run was not possible.
Options include: silent skip (current), replace the active
configuration in-place, or treat it as an error.

**Affects:** Lifecycle design, FR-1 (setup), FR-3/FR-4
(hide/show).

**Source:** `requirements.md §5`, `assessment.md §2`

**Suggested decision:** Dissolved by the singleton design.
There is no "setup call while active" because there is no
setup call — only configure/show on a persistent widget.
Projects that want to change the prompt label or evaluator
mid-run call a reconfigure method directly. The silent-skip
guard is removed.

---

### D-3 · Key event coverage

**Question:** Should Ctrl+key combinations and other
non-character keys (navigation keys, function keys) produce
the same notification or separate ones?

**Context:** These are gesturally different — Ctrl+key is
typically a command; navigation keys are movement. A single
surface is simpler; separate surfaces let callers express
intent more clearly. The gap in the current architecture is
that all key events are consumed by the overlay controller
with no forwarding to project code.

**Affects:** FR-6 callback design, API surface size.

**Source:** `requirements.md §5`

**Suggested decision (original — superseded in part; see the
round-1 annotation below for the current three-tier model, combo
form, and signature):** All key events are covered through a
unified `_on_key_pressed(k, pressed, isrepeat)` dispatch
where `pressed` is the current `compy.keys_pressed` set.
Three dispatch levels inside `ProjectController:keypressed`:
framework_handlers → compy.input.handlers → `compy.input.on_key_pressed`,
with `UserInputController:keypressed` as the terminal sink
below all three. Combo registration uses serialised sorted
key names (e.g. `"lctrl+s"`) consistent with LÖVE2D
conventions. Modifier+character events go through
`_on_textinput`, not keypressed — no overlap. The same
dispatch function is shared across all three controller
branches (written once; `ProjectController` uses it first;
`ConsoleController` and `EditorController` migrate when
ready). Specific serialisation format is a spec detail.

*(Origin: local design round 1, 2026-06. See
`validation/recommendations_1.md` Items 3, 7.)* Architect
clarification: the three dispatch levels stand, but the
text-editing sink is the **default value** of
`compy.input.on_key_pressed`, not a fourth separate tier. A project
that overrides `compy.input.on_key_pressed` replaces the default
sink entirely; there is no tier below it to fall through to.
The combo serialisation rule is corrected from alphabetical to
**modifier-first by fixed precedence** (ctrl, alt, shift, gui)
then the triggering key, with **generic l/r folding** (combos
use `ctrl`, not `lctrl`/`rctrl`; the `keys_pressed` table
retains precise LÖVE names). `compy.input.handlers` is
metatable-backed: `__newindex` normalises the registered key to
canonical form on assignment. Dispatch uses an overloadable
exact-match default matcher; the matcher is the marked
extension seam for future glob/prefix matching. Signature:
`on_key_pressed(k, keys, isrepeat)` — `isrepeat` as trailing
arg so the common `(k, keys)` form stays clean.

---

### D-4 · Cancel and submit notifications

**Question:** Should the API provide dedicated callbacks for
when the user dismisses the input (Escape) or submits (Enter),
and how does the framework's own teardown relate to project
callbacks?

**Context:** Escape and Enter currently trigger framework
behaviour (teardown, evaluate) with no notification to project
code. A dedicated callback is more explicit but the framework
must continue to run its structural logic regardless of what
project code does.

**Affects:** FR-5, FR-6, API surface size, lifecycle semantics.

**Source:** `requirements.md §5`

**Suggested decision:** Cancel and submit each have named
chain points: `before_cancel → cancel → after_cancel` and
`before_submit → submit → after_submit`. The framework owns
the middle point (teardown on cancel, evaluate+store on
submit) and always runs it. Projects hook into before or
after. Ordering is enforced by call sequence in the
framework's default implementations. The generic
`compy.input.on_key_pressed` uses return-value propagation (true =
consumed, nil = bubble) for the non-semantic case.

The `oneshot` flag is deleted as a consequence of D-2 combined
with D-4. Previously, `oneshot` encoded two signals: "widget is
the active overlay" and "widget owns submit." Both are replaced:
`show()`/`hide()` on the singleton carry the activation signal;
`framework_handlers['return']` in `ProjectController` owns
submit. The flag has nothing left to do.

*(Origin: local design round 1, 2026-06. See
`validation/recommendations_1.md` Items 2, 8.)* Corrections:
(1) `oneshot` is a field of **`UserInputModel`**
(`userInputModel.lua:15,49`), not `UserInputController`;
`UserInputController` only reads `self.model.oneshot`. The
deletion file target is `userInputModel.lua` (field removal) and
`userInputController.lua` (submit-path code that reads it).
(2) The deletion is moved to **M6**, not M2. `oneshot` currently
drives both submit gating and the `'userinput'` push; its
replacement (`framework_handlers['return']` in `ProjectController`)
arrives only in M6. Deleting it in M2 would strand submit across
M2–M5, contradicting M2's "zero behaviour change" claim. Until M6,
`oneshot` stays and continues to drive submit exactly as today.

---

### D-5 · Cursor boundary definition

**Question:** In a multiline input area, what constitutes a
cursor boundary — end of current line, end of entire input,
or both?

**Context:** In a single-line context these are equivalent.
In multiline, the distinction matters for editor-like
navigation. The existing internal `is_at_limit` operates at
the whole-input level (first/last line of the buffer).

**Affects:** FR-7 semantics, FR-12 (editor re-implementability).

**Source:** `requirements.md §5`, `assessment.md §3`

**Suggested decision:** Single `on_limit_reached(direction)`
hook where direction is `'up'` or `'down'`. Covers
whole-input boundary only, consistent with the existing
`is_at_limit` implementation. A hook always propagates —
both project code and framework code observe the same event
independently. Second positional argument reserved for
future boundary-level granularity, undefined in v1.

---

### D-6 · Text character + modifier co-occurrence

**Question:** When a character-producing key is pressed while
a modifier is held, should the API emit a text-entered
notification, a key-combo notification, both, or neither?

**Context:** LÖVE2D delivers these as two separate events.
Without an explicit policy a callback-based API could fire
two notifications for a single user gesture.

**Affects:** FR-5 and FR-6 callback model.

**Source:** `assessment.md §8`, `notes/concerns.md`

**Suggested decision (original):** When `love.textinput` fires,
the framework calls `_on_textinput(text, pressed)` where
`pressed` is the current `compy.keys_pressed` set.
Non-character keys in `pressed` constitute the implicit
modifiers table, reaching project code as
`on_text_entered(text, mods)`. The framework suppresses
`on_key_pressed` for keys followed by a `textinput` in the
same frame — "exactly one notification per gesture."

*(Origin: local design round 1, 2026-06. See
`validation/recommendations_1.md` Item 6.)* **Superseded.**
D-6 was a "Suggested decision" that was never discussed or
signed off (its closing line delegated the mechanism to the
spec, where it became an impossible same-frame lookahead). The
"no double callback" guarantee is dropped — it is grounded in
neither `requirements.md` nor the current implementation.

**Replacement resolution:** both LÖVE channels fire
independently, mirroring raw LÖVE semantics:

- `keypressed` channel → three-tier dispatch → `compy.input.on_key_pressed` (default: text-editing keypressed sink)
- `textinput` channel → `compy.input.on_text_entered` (default: text-editing textinput sink)

No suppression, no classification. A character-producing keypress
visits both channels; there is no double-*insertion* because the
keypressed sink ignores plain character keys (insertion is the
textinput sink's job). Projects that handle both channels do so
by explicit choice — plain LÖVE semantics. The `on_text_entered`
second argument is the full `keys_pressed` read-only proxy
(consistent with `on_key_pressed`), not a filtered `mods` subset.

**Channel symmetry.** The two channels are deliberately symmetric:
`on_text_entered`'s default value is the textinput sink exactly as
`on_key_pressed`'s default is the keypressed sink, and overriding
either replaces its sink. Textinput processing follows the same
default-sink/override principle as keypressed; the only structural
difference is that the textinput channel has no combo tier above
it (characters are not combos).

*(Origin: local design round 2, 2026-06. See
`validation/recommendations_2.md` Item 4.)* **Future seam — `mods`
string (not built in v1).** A design-session idea proposed
augmenting both channels with an optional pre-folded `mods` string
— the generic l/r-folded modifier descriptor (like the combo
form) — passed as a trailing argument to downstream
handlers/callbacks, as a convenience for handlers shared across
several combos and for the generic callback that runs after combo
handlers. v1 ships the `keys_pressed` proxy only (modifiers are
derivable from it); the `mods` string is recorded as a candidate
addition, paired with the overloadable-matcher and
text-command-set seams (Items 6/7, round 1). It is **flagged for
architect confirmation** (build in-scope vs. leave as a seam) —
see the changelog's open questions; it is not built here.

---

### D-7 · Rollout scope

**Question:** Should the new event topology apply to all
three input contexts (console REPL, editor, project overlay)
at once, or to the project overlay first?

**Context:** The overlay context is where the current gap
is most acute — project code cannot receive key events at
all while the overlay is active. The console and editor
already handle their own events through direct controller
paths. The question is whether to migrate all three at once
or stage the work.

**Affects:** Implementation scope, FR-11/FR-12.

**Source:** `assessment.md §8`, `notes/concerns.md`

**Suggested decision:** The new routing model applies to the
project-running context first. The `if user_input then` gate
in `controller.lua` is removed. `ProjectController` (new)
becomes the occupant of `love.keypressed` when a project is
running — exactly as `ConsoleController` is when no project
runs. The singleton wiring refactor (moving construction to
`main.lua`) is the first step. `compy.input.handlers` resets on project stop via
`stop_project_run` / `clear_user_handlers`
(`consoleController.lua:860–868`).
The conceptual shift: "overlay" as a routing concept dissolves
— it is replaced by "singleton is currently visible."

`ConsoleController` and `EditorController` retain their
existing key handling paths for now.

FR-11/FR-12 are satisfied when the API can express the key
patterns the console and editor use — they do not require
migration within this feature. The migration path is clear
and has been analysed: both controllers' key dispatch
consists of if-chains that map directly onto handler
registrations, with no changes to the underlying methods
(evaluate, history navigation, block navigation, mode
switches). No blocking constraint exists. `design.md` will
include a walkthrough confirming the API surface covers
both cases. Actual migration of the console and editor is
a named follow-on feature. Full analysis in
`notes/editor_repl_input.md`.

*(Origin: local design round 1, 2026-06. See
`validation/recommendations_1.md` Item 9.)* The promised
FR-11/FR-12 walkthrough has been added to `design.md §7`.

---

### D-8 · 2D cursor contract and live cursor/text surface

**Question:** What coordinate space does the cursor API use,
and how are FR-8, FR-9, FR-10 exposed?

**Context:** `requirements.md` FR-8/9/10 require programmatic
cursor query, cursor set, and live text change while active.
These silently fell out of the chain after `assessment.md` — a
derivation error, not a deliberate de-scope. The model already
has `get_cursor_pos()`, `move_cursor(y, x)`, and `set_text()`;
exposure is the only missing piece. A coordinate decision is
needed: `spec.md §2` used a single integer ("1-based column in
line 1"), which only works single-line and contradicts the
`multiline` flag.

**Affects:** FR-8/9/10 API surface, `compy.input.show()` `cursor`
field, roadmap M7.

**Source:** `requirements.md §2.4`, `assessment.md §4`.

**Decision:** Coordinate model: **2D `(line, col)`, 1-based,
source-line coordinates** (not wrapped/apparent lines). The
model cursor is already 2D; this is a direct restoration.
Single-line callers ignore `line` (always 1). The `cursor`
field at `compy.input.show()` accepts `{line, col}` (or two separate
fields); FR-7/8/9 are all settled on this one coordinate space.

New project-facing functions delegating to the singleton:

| Function | Maps to | Behaviour |
|---|---|---|
| `compy.input.get_cursor()` | `model:get_cursor_pos()` | Returns `line, col`; returns `nil` when hidden |
| `compy.input.set_cursor(line, col)` | `model:move_cursor(line, col)` | Clamps to valid range; no-op when hidden |
| `compy.input.set_text(text [, keep_cursor])` | `model:set_text(...)` + `update_view` | Live write; explicit exception to `configure()` text-immutability |

`write_to_input` is **removed** with the rest of the legacy
text-input globals (D-1 discarded). The example that used it
(`tixy`) migrates to `compy.input.set_text` directly; there is no
`write_to_input` facade. `compy.input.set_text` is the live-write
surface that supersedes it.

Model fix required: `UserInputModel:set_text` must honour
`keep_cursor` (skip the unconditional `jump_end()` when
`keep_cursor` is true). Roadmap: the full
`compy.input.set_text`/`compy.input.get_cursor`/`compy.input.set_cursor`
surface goes in M7; the legacy-global removal and example
migration happen in M8.

*(Updated by stakeholder feedback, round 1, 2026-06-06: the
`write_to_input` facade is dropped — see D-1.)*

*(Origin: local design round 1, 2026-06. See
`validation/recommendations_1.md` Item 1.)*

---

### D-9 · Native `love.keypressed`/`textinput` coexistence via auto-provisioning

**Question:** How do projects that define `love.keypressed`
natively interact with `ProjectController` owning the slot?
Shipped examples (pong, life, paint, turtle) rely on native
handlers; without a solution they break when `ProjectController`
takes the slot.

**Context:** The routing layer already transparently intercepts
native LÖVE handlers via `save_user_handlers` /
`hook_if_differs` (`controller.lua:73–107`). Projects never
*actually* bind `love.*`; the framework captures and re-routes
them. D-1 was about the four text-input functions; native
handler coexistence is a **separate** surface. With D-1 now
discarded (no backward compatibility for the text-input API),
D-9 is what keeps the stakeholders' "only text fields break"
guarantee true: games that drive their own keyboard handling
continue to work unchanged. D-9 therefore stands on its own and
is **retained** independently of D-1's removal.

**Affects:** native-handler coexistence (independent of the
discarded D-1 text-input surface), `ProjectController` startup,
FR-6.

**Source:** `validation/recommendations_1.md` Item 4.

**Decision:** When a project is loaded, `ProjectController`
inspects what it defined. **Legacy heuristic (the gate):** if the
project has native `love.keypressed`/`textinput` (captured by
`save_user_handlers`) AND has set none of the new `compy.*` surfaces
(`compy.input.on_key_pressed`, `compy.input.handlers`, `compy.input.on_text_entered`),
`ProjectController` auto-provisions `compy.input.on_key_pressed` on the
project's behalf as a **lifecycle-split wrapper**:

- **Singleton visible** → run the text-editing sink (text editing wins).
- **Singleton hidden** → run the project's native handler (game keys).

This reproduces today's gated behaviour exactly, with zero changes to
existing examples. Projects that set any `compy.*` surface explicitly
are new-style: they take control via Item 3 override semantics and the
heuristic never applies. In debug mode, the wrapper logs which branch
it chose on each invocation (transition diagnostics — nudges toward
explicit `compy.*` use). The auto-provisioned wrapper is cleared on
project stop alongside all other `compy.*` callbacks.

The same generalises to `love.textinput` → `compy.input.on_text_entered`
and `love.keyreleased`.

*(Origin: local design round 1, 2026-06. See
`validation/recommendations_1.md` Item 4.)*

---

### D-10 · Namespace isolation under `compy.input.*`

**Question:** Where does the new feature-#77 surface live on the
project-facing namespace — flat on `compy.*`, or under a dedicated
sub-namespace?

**Context:** `compy.*` is the whole project-facing API and will
accumulate many unrelated callbacks, variables, and objects.
Flat-mounting the input surface there crowds the namespace and
blurs concerns. The decision was made (and applied to the derived
docs) in round 1, but was not recorded as a decision — it lived
only in `recommendations_1.md`'s namespace section and in the
edited `design.md`/`spec.md`/`roadmap.md`. Recording it here makes
it visible to the eventual stakeholder review.

**Affects:** every new feature-#77 name; NFR-3 (namespace
consistency). (The legacy globals that this decision originally
left flat are now removed entirely — D-1 discarded — so there is
no longer a legacy call-target to consider.)

**Source:** `validation/recommendations_1.md` "Namespace
isolation"; surfaced as a decision per
`validation/recommendations_2.md` Item 2.

**Decision:** The new callback / lifecycle / accessor surface lives
under a dedicated sub-namespace **`compy.input.*`**, not flat on
`compy.*`. This isolates the feature's surface, keeps `compy.*`
structured, and leaves room for sibling sub-namespaces later.

- **Moves under `compy.input.*`:** `show`, `hide`, `configure`,
  `clear`, `handlers`, `on_key_pressed`, `on_text_entered`,
  `before_submit`/`after_submit`, `before_cancel`/`after_cancel`,
  `on_limit_reached`, `get_cursor`, `set_cursor`, `set_text`.
- **Stays global — `compy.keys_pressed`:** it is raw keyboard
  state (physical reality), not the input-manipulation layer
  (interpretation). Keeping it out of `compy.input.*` makes that
  boundary explicit at the namespace level.
- **Removed — legacy text-input globals:** `input_text()`,
  `input_code()`, `validated_input()`, `user_input()`, and
  `write_to_input()` are removed, not kept (D-1 discarded —
  stakeholder feedback round 1). There is no legacy surface left to
  re-point; the new API lives entirely under `compy.input.*`.

The `compy.input` table is created once at namespace setup;
reset-on-stop clears `compy.input.handlers` and the `compy.input.*`
callbacks together.

*(Origin: local design round 1 namespace pass, 2026-06; recorded
as a decision in round 2. See `validation/recommendations_2.md`
Item 2 and `validation/recommendations_1.md` "Namespace
isolation".)*
