# Feature #77 — What Was Asked For

*Summary of `requirements.md`. Read that document for the full
numbered list, non-functional requirements, out-of-scope items,
and open questions.*

---

## The problem

The current input API is polling-based and fragmented. Projects
must repeatedly check a reference variable to detect user input,
cannot react to keyboard events while an input prompt is on
screen, and have no way to show or hide the prompt without
tearing it down entirely. This makes certain interaction
patterns (hotkeys during input, dynamic prompts, text
adventures) awkward or impossible.

## What was requested

**A configurable input area.** One setup call that accepts
optional initial text, cursor position, syntax highlighter,
validator, and prompt label — rather than several separate
functions with overlapping but non-composable capabilities.

**Event notifications instead of polling.** Callbacks for:
- the user submitting input (pressing Enter);
- key events that don't produce text — Ctrl combinations,
  navigation keys, function keys (external keyboard only);
- the cursor hitting the start or end boundary of the input
  area.

**Programmatic control.** While an input area is active, the
project should be able to read and set the cursor position and
replace the text content.

**Lifecycle control.** Explicit calls to hide and show the
input area without losing its state, and to remove it
programmatically rather than relying solely on user action.

**Consistency.** The API should be expressive enough that the
console REPL and the editor could each be re-implemented using
it. This is a design completeness target, not a commitment to
rewrite them immediately.

## Key constraints

The implementation must not allocate a new object graph on each
input session — the current pattern of creating and discarding
objects on every interaction is a known concern. Simple use
cases should remain simple; a student should not need to
understand framework internals to show a prompt and receive a
result.

## What is not in scope

Multiple simultaneous input areas, touch input, and changes to
the editor's internal block navigation are not part of this
feature.

## Decisions still needed

Seven questions must be answered before design can begin —
covering backward compatibility, lifecycle behaviour, callback
shape, and implementation scope. They are tracked with full
context in `decisions.md`.
