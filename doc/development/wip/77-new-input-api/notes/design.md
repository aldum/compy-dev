# Notes — Design Ideas

Ad-hoc design proposals extracted from earlier draft documents.
These are not decisions — they are candidate ideas to consider
during design. Sources: old `assessment.md` and
`feature_correlation.md`.

---

## Event propagation: return-value bubbling

Proposal: unhandled key events should propagate by a
return-value convention similar to DOM event handling. The
callback returns `true` to signal the event was handled
(suppress default behaviour); returning `false` or `nil`
allows the event to propagate to the framework's default
LÖVE2D handlers.

This gives projects precise control without requiring the
framework to enumerate every possible key in advance.

---

## Callback signatures (candidate names)

Proposed from earlier work:

| Callback | Signature | Trigger |
|---|---|---|
| `on_text_entered` | `(text, modifiers)` | User submits input |
| `on_key_combo` | `(keys_list)` | At least one modifier key held |
| `on_limit_reached` | `(direction)` | Cursor at boundary, movement attempted |
| `on_cancel` | `(modifiers)` | Edit area dismissed (Escape) |

`modifiers` would be a table such as `{ ctrl = true }`.
`direction` would be `'up'` / `'down'` or equivalent.
`keys_list` would be the full set of pressed keys.

These names and signatures are proposals, not decisions.
The co-occurrence question (text + modifier simultaneously —
see `notes/requirements.md`) should be resolved before
finalising.

---

## Dual registration pattern

Proposal: allow two equivalent ways to register callbacks —
whichever fits the project's style:

1. **Per-call closure table** — pass a table of callbacks to
   the setup call. Scoped to that input session.
2. **Global project hooks** — set fields on a shared namespace
   (e.g. `compy.on_text_entered = function(...) end`). Applies
   to any active input.

The two would share the same callback names. Global hooks are
more convenient for simple projects; per-call tables are safer
when a project manages multiple interaction modes.

---

## Persistent lifecycle API

Proposal: rather than allocating a new MVC triad on each
`input_text()` call, treat the widget as persistent and expose
state-mutation methods:

- `show()` — make the edit area visible
- `hide()` — hide it without discarding content
- `alter()` — update configuration (prompt, text, cursor, etc.)
  without full teardown

`enable()` / `disable()` were also proposed — possibly for
suppressing input while keeping the widget visible.

This directly addresses NFR-1 (allocation / GC) and the
dynamic-update pain point (see `notes/requirements.md`).

---

## Sensible defaults: unregistered callbacks fall back gracefully

Proposal: if no callback is registered for a given event (e.g.
`on_text_entered` not set), the input widget should behave as it
currently does — i.e. standard Console/REPL submission. This
means the new API is additive: a project that registers no
callbacks gets existing behaviour for free, and opts into new
behaviour only where it registers handlers.

Implication: the default behaviour must be encoded somewhere
(either as built-in fallback logic in the framework, or as a
default callback table applied when none is supplied). Worth
deciding early, as it affects how the API interacts with the
console and editor when they are eventually re-implemented on
top of it.

---

## Backward-compatibility shims

Proposal: keep the existing `input_text()`, `input_code()`,
`validated_input()`, and `user_input()` working by delegating
to the new API internally. Emit a deprecation notice in debug
mode. This avoids breaking existing examples while steering new
code toward the new API.

Whether this is the right tradeoff (vs a clean break) is an
open question noted in `requirements.md §5`.
