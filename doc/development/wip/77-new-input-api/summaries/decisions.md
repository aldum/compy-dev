# Feature #77 — Design Direction and Decisions

*Summary of `decisions.md`. Full question context, rationale,
and decision dialogue are in that document and in
`notes/decisions.md`.*

> **Status:** A local design proposal derived from `input.md`,
> pending a single eventual stakeholder approve/veto review — with
> one exception: **D-1 has been ruled on** (`input.md`, feedback
> round 1: **DISCARDED**, no backward compatibility). D-1 below is
> stakeholder ground truth; D-2…D-10 are still proposal.

---

## The blocking decisions

Seven questions arose from requirements analysis and
architecture assessment that require stakeholder consensus
before design and implementation can proceed:

1. Must existing input functions still work after the new
   API is introduced?
2. What happens when a project tries to configure input
   while it is already active?
3. How should different kinds of key events (modifier combos,
   navigation keys, function keys) reach project code?
4. Should cancel and submit be dedicated named events, and
   how does the framework's own teardown relate to project
   callbacks?
5. In a multiline input area, what exactly constitutes the
   cursor hitting a boundary?
6. When a character key is pressed while a modifier is held,
   should the project receive one event or two?
7. Should the new event mechanism apply to all input
   contexts at once, or the project overlay first?

Three further architectural decisions were recorded during the
local design rounds: **D-8** (cursor restoration + 2D contract)
and **D-9** (native handler coexistence) from round 1, and
**D-10** (namespace isolation under `compy.input.*`) from round 2.
They are not new stakeholder questions but genuine decisions —
listed in the glance table below with provenance.

---

## Proposed resolution

A design approach has been developed that addresses all
seven questions coherently. It is summarised below and
detailed in `decisions.md`.

**Fast-track path:** if the direction is acceptable, work
proceeds to `design.md` and the full implementation plan.

**Veto path:** if any aspect is problematic, the relevant
decision(s) are re-opened. Because the decisions form a
coherent set, a veto of one may affect others — the detail
document tracks these dependencies.

---

### The architectural basis

The structural change that makes all three improvements
possible is routing unification. The
`if user_input then ... else ... end` gate in
`love.handlers.keypressed` (`controller.lua`) is removed.
A new `ProjectController` — a sibling to `ConsoleController`
and `EditorController` — takes ownership of all input
handling for the project-running context. `UserInputController`
becomes the universal terminal sink at the bottom of every
branch: always present, never a routing destination. See
`notes/routing_unification.md` for the before/after diagram.

---

### The solution in three questions

**Is there one input widget or many?**
One. The widget is created once at application startup and
never destroyed. Projects call `show()`, `hide()`, and
`configure()` on it. Reuse across sessions — not recreation
— is the structural default.

**How does project code receive input events?**
Through a callback chain attached to `ProjectController`'s
dispatch. When the user types, the framework fires:
`on_text_entered` for character input, `on_key_pressed`
for non-character keys and modifier combos, named chain
points (`before_submit`, `before_cancel`) for session-level
events. The framework always runs its own structural
behaviour; project code extends it.

**How are key events not swallowed?**
`ProjectController` implements a three-level dispatch:
`framework_handlers → compy.input.handlers[combo] → compy.input.on_key_pressed`.
The text-editing sink is the **default value** of
`compy.input.on_key_pressed` — not a separate fourth tier.
`compy.input.handlers` returns truthy to consume; overriding
`compy.input.on_key_pressed` replaces the default sink entirely.
Both LÖVE channels (keypressed and textinput) fire
independently — no suppression.

---

### Terminology

**Project overlay** — the input area a running project
creates by calling `input_text()`, `input_code()`, or
similar. Distinct from the console REPL's own input and the
editor's input strip, which are separate instances not
affected by these changes. Under the new architecture the
"overlay gate" is removed; visibility is a state on the
singleton, not a routing condition.

**Persistent input widget** — the proposed lifecycle: one
widget object, created at startup, reconfigured per session.

**Event callbacks** — the proposed notification model:
project code registers functions the framework calls when
events occur, replacing the current pattern of polling a
reference variable on every frame.

---

### The direction

The design addresses the approved requirements through
three connected changes.

**The input widget becomes persistent** (FR-1–FR-4, NFR-1).
Instead of being created on each `input_text()` call and
discarded after submission, the widget is created once at
startup and reused. Projects call `show`, `hide`, and
`configure` on it. Eliminates per-session allocation.
The wiring change is a contained refactor verifiable by
existing tests.

**Keyboard events now reach project code** while a prompt
is active (FR-5–FR-7, NFR-2). Currently they are silently
consumed. `ProjectController`'s three-level dispatch
ensures all keys pass through project-registered handlers
and callbacks before reaching the text-editing sink.
Submit and cancel have named before/after callback points;
the framework always runs its structural behaviour and
projects extend it.

**Legacy text-input API removed** (D-1 — **discarded** by
stakeholders, round 1). `input_text()`, `input_code()`,
`validated_input()`, `user_input()`, and `write_to_input()`
are removed, not kept as facades; the reftable / polling idiom
goes with them. The examples that used them are migrated to the
`compy.input.*` callback API (priority: `tixy`, `balloons`),
others converted or excluded from the release at the owner's
call. The break is bounded to text input — native keyboard
handling (D-9) is unaffected.

**Console and editor migration path.** The new API is
expressive enough to re-implement both (FR-11/FR-12). The
migration is mechanical — if-chains become handler
registrations; underlying methods unchanged. Each
controller's migration is a named follow-on feature.

---

### Resolutions at a glance

| | Decision | Resolution |
|---|---|---|
| D-1 | Backward compat | **Discarded** (stakeholders, round 1): no backward compat. Legacy text-input globals removed; examples migrated (`tixy`/`balloons` priority) or excluded. D-9 native coexistence unaffected. |
| D-2 | Second setup call | Dissolved — singleton accepts configure/show, no create call |
| D-3 | Key event coverage | Three-tier dispatch; sink = default of `on_key_pressed`; modifier-first generic-folded combo format; metatable-normalised; overloadable matcher |
| D-4 | Cancel/submit | Named chains `before_X → X → after_X`; framework owns middle; `oneshot` is `UserInputModel` field, deleted in M6 |
| D-5 | Cursor boundary | Single `on_limit_reached(direction)` hook; whole-input boundary |
| D-6 | Modifier + character | Superseded (round 1): two independent channels, no exclusivity; `on_text_entered(text, keys_pressed)` |
| D-7 | Rollout scope | ProjectController first; FR-11/FR-12 walkthrough added to `design.md §7` |
| D-8 | Cursor contract + live surface | 2D `(line, col)` source-line coords; `compy.input.get_cursor`, `compy.input.set_cursor`, `compy.input.set_text`; `set_text` supersedes the removed `write_to_input` |
| D-9 | Native handler coexistence | Auto-provisioning via legacy heuristic; lifecycle-split wrapper; transition diagnostics |
| D-10 | Namespace isolation | New surface under `compy.input.*`; `compy.keys_pressed` stays global; legacy text-input globals removed (D-1 discarded) |
