# Notes — Concerns and Risks

Technical concerns and risks identified during review of the
existing architecture and earlier draft documents. Not yet
triaged — some may be resolved by the design, others may need
explicit decisions.

---

## Primary gap: keypressed events are fully consumed

`UserInputController:keypressed` currently handles all key
events it receives and returns nothing to indicate whether an
event was consumed or passed through. The calling context
(console or project) has no mechanism to receive key events
that the widget did not handle.

This is the root technical blocker for FR-6 (non-character key
notifications) and for the editor re-implementability target
(FR-12). Any solution must decide where the forwarding
responsibility lives and whether it is opt-in or always-on.

Source: `src/controller/userInputController.lua`;
confirmed in old `assessment.md §3`.

---

## Singleton lifecycle: no mid-session update path

The current `love.state.user_input` guard (`if ... then return
end`) means a second call to any input-creation function while
one is already active silently does nothing. There is no
supported path for:
- changing the prompt label
- swapping the highlighter or validator
- resetting content and cursor to new values

without first tearing down the widget. This is a concrete
limitation (see also `notes/requirements.md` — balloons pain
point) that the persistent lifecycle design idea directly
addresses.

---

## Wall-hit in editor context: line numbers diverge

The editor works in two coordinate systems: source line numbers
(as stored in the file) and apparent/wrapped line numbers (what
the view renders). These diverge whenever any block has lines
longer than the screen width.

`EditorController` checks `inputView:is_at_limit('up'/'down')`
against the wrapped/apparent coordinate system, not the source
one. A general-purpose wall-hit callback (FR-7) would need to
clarify which coordinate system its direction applies to — or
the callback would need to fire in terms meaningful to the
consumer, which may differ between console and editor contexts.

The old `assessment.md` flagged this as a reason to be cautious
about any speculations in the editor direction for this
callback.

---

## Intercepted callbacks: no consolidated list

`controller.lua` intercepts a set of LÖVE2D event callbacks
before they reach project handlers or `UserInputController`.
The full list is not documented in one place, making it hard to
reason about what a project can and cannot intercept without
reviewing the file in full.

This is a documentation gap, not a blocker, but it is worth
addressing before finalising the new API's event model —
knowing exactly which events are intercepted helps ensure
nothing is silently swallowed.

Reference: `src/controller/controller.lua:520+` for the global
shortcut intercepts; `love.state.user_input` check in the
keypressed handler for the overlay intercept.

---

## Convention adoption scope: all three contexts or one?

Any mechanism that allows key events to propagate out of
`UserInputController` implies a convention that every consuming
context must implement: `ConsoleController`, `EditorController`,
and the project overlay path would all need to handle (or
explicitly ignore) forwarded events in a consistent way.

This is not a change to one class — it is a cross-cutting
convention commitment. If only one context is updated initially,
the API would behave differently depending on which context the
widget is running in, which breaks the consistency goal
(FR-11/FR-12). Worth flagging as a scope risk: the work may be
wider than it first appears.

---

## Text + modifier co-occurrence: undefined behaviour

The requirements and current architecture do not define what
happens when a text character arrives simultaneously with a
modifier key held. LÖVE2D delivers these as separate events
(`love.textinput` for the character, `love.keypressed` for the
key), but from the project's perspective the user made one
gesture.

If the new API emits both a text-entered notification and a
key-combo notification for the same gesture, a project could
receive confusing double callbacks. If it emits neither (because
both paths reject it), a gesture is silently dropped. This
needs an explicit policy decision.
