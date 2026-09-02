# Notes — Requirements

Observations that clarify, extend, or question the formal
requirements. Not stakeholder requirements themselves.
Sources: `input.md`, intake, and review of earlier
draft documents.

---

## Product framing

Compy is positioned as a ZX Spectrum-inspired educational
platform for children. This is the lens through which the
pedagogical constraints on the API (simplicity, learnability,
not exposing framework internals) should be read.

---

## Design process intent

The stakeholder's stated approach before committing to a design:

1. Reconstruct how the existing architecture handles user input
   across modes.
2. Correlate the feature requirements against that architecture.
3. Use those inputs to produce a high-level design document,
   then plan implementation.

The requirements document and architecture assessment are
intermediate artefacts toward that design document, not
deliverables in themselves.

---

## GC / allocation emphasis

The stakeholder framed avoiding object churn as an "unspoken
project principle". The nuance beyond `agents/rules.md`:
**examples are strongly expected to follow this principle even
where older framework code does not**. New API design and any
example code using it should treat allocation-on-each-session
as a defect, not a tradeoff.

---

## Dynamic prompt update — concrete pain point

During development of the balloons example, the need arose to
change the prompt label mid-run (e.g. on a timer), but this
was not possible because the singleton guard in `input_text()`
silently drops any call made while an input is already active. Tearing
down and recreating the widget is not viable for time-driven
prompt changes.

This is a concrete motivation for FR-3/FR-4/FR-5 (hide/show/
remove) and for the persistent lifecycle direction in general.
It also implies a gap not fully covered by those requirements:
**the ability to update the prompt label of an already-active
edit area without a full teardown/recreate cycle**.

Worth raising as an explicit open question before design: does
FR-1 (setup parameters) need a corresponding "update" call that
changes only the label (and optionally other parameters) without
disrupting the current text and cursor state?

---

## Wall-hit boundary — multiline ambiguity

FR-7 (cursor reaches a positional boundary) is ambiguous for
multiline input. "Boundary" could mean: end-of-current-line,
end-of-the-entire-input, or both. This distinction matters for
how a project would use the callback — an editor-like interface
(FR-12) would need to distinguish the two to implement block
navigation correctly. Needs a decision before design.

---

## Text + modifier co-occurrence

When a text character is entered while a modifier key is held
(e.g. Ctrl+letter on some keyboards, or platform-specific
combos), it is not specified whether this should produce a
text-entered notification, a key-combo notification, both, or
neither. The answer shapes both FR-5 (submit) and FR-6
(non-character keys). Worth settling before finalising callback
signatures.
