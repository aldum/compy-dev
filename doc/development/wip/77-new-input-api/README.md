# Feature #77 — New Input API

**TL;DR:** a callback-based input API for projects, replacing the polling
functions (`input_text`, `input_code`, `validated_input`, `user_input`). It
turned out to touch keyboard routing across the whole app, not just the REPL —
so it got a proper upfront analysis instead of a dive-in. **Complex, but
solvable**, and pre-planned so building can start on a green light. Per
stakeholder feedback (round 1), the legacy text-input functions are **removed**
— no backward compatibility; the examples that used them migrate to the new
API, others can be excluded from the release. The break is bounded to text
input: native keyboard handling is unchanged, and old releases remain
available.

## Start here

Read the **`summaries/`** folder — that's the whole feature at stakeholder
altitude, ~30 min total. The one that needs your call is
**`summaries/decisions.md`**.

| # | Summary | What it answers |
|---|---|---|
| 1 | `summaries/requirements.md` | What was asked for |
| 2 | `summaries/assessment.md` | What the code does today |
| 3 | `summaries/decisions.md` ⭐ | The calls awaiting approve / veto |
| 4 | `summaries/design.md` | How it works |
| 5 | `summaries/spec.md` | The API contract |
| 6 | `summaries/roadmap.md` | Build plan + effort (~37–63 h) |

## If you want to dig

- **Full docs** — same names in this folder (`decisions.md`, `design.md`, …),
  for when a summary isn't enough.
- **`input.md`** — your ticket + clarification, verbatim.
- **`notes/`** — supporting codebase analysis.
- **`validation/`** — the review rounds and their fixes.
