# Compy — Coding Rules

Audience: LLM assistant. Apply when writing, reviewing, or analysing code in this repo.
Source: compiled from [`doc/development/conventions/code.md`](../doc/development/conventions/code.md) and [`doc/development/conventions/architecture_principles.md`](../doc/development/conventions/architecture_principles.md).

---

## Architecture analysis

When broad picture required (not a focused check of specific behaviour):
  Use `./doc/development/*` as the initial source of syntetic pre-extracted knowledge prior to direct codebase inspection (assume minor mistakes though)

Load those as needed for the current task, not everything upfront.

Mapping of reference docs:
./doc/development/overview.md -- bird-eye overview of the architecture
`./doc/development/conventions/*` -- fundamental dev-facing rules
./doc/development/conventions/architecture_principles.md -- fundamental conventions and constraints applying to the whole project
./doc/development/conventions/code.md -- code style
./doc/development/conventions/git.md -- conventional commits usage
`./doc/development/internals/*` -- current implementation essentials, derived from codebase isnpection -- currently cover editor, console, examples
./doc/development/internals/user_input.md -- cross-component usage of user input in different modes
./doc/development/drawing_system.md -- unobvious wiring of drawing system, enabling paper-and-pen vs realtime drawing modes

Some (not all) essential excerpts from these docs are inlined below (they may be sufficient in many contexts)

## Hard Limits (coding)

| Constraint | Limit |
|---|---|
| Line length | 64 chars |
| Function body | 14 lines |
| Parameters | 4 |
| Nesting depth | 4 |

When a limit is approached, redesign — don't raise the limit.

---

## Formatting (editor-enforced)

- Metalua auto-prettyprints; don't fight it. Published examples must be idempotent under the built-in editor.
- `end` closes on the same line as the last statement in its block.
- Empty table: `{ }` (spaces inside braces).
- Table/array literals: one element per line.
- Comments: own line only, never inline.
- At most one blank line between non-blank lines.

---

## Scope & Naming

- Locals scoped to the smallest enclosing block. No variable outlives its purpose.
- Extract compound conditions to named locals — name the intent, not the mechanics:
  ```lua
  local done = count >= max or timed_out
  if done then ... end
  ```
- Standard aliases at module top: `local gfx = love.graphics`, `local sfx = compy.audio`.

---

## Design

**File = console equivalence.** Code in a `.lua` file and the same code typed into the Compy REPL must behave identically. No load-order side effects; no implicit global state that the REPL wouldn't have.

**Prefer functional style.** Closures, iterators, and immutable-by-convention data are preferred. They compose cleanly and stay readable.

**Avoid deep OOP.** Inheritance chains, manager-of-manager classes, and factory abstractions are anti-patterns here. If a student with six months of experience couldn't follow the call graph, it's too abstract.

**No C accent.** Don't use string/integer tags as surrogate function pointers dispatched via if-chains. Store and pass the function itself.
```lua
-- wrong
local dir = 'up'
if dir == 'up' then go_up() elseif dir == 'down' then go_down() end

-- right
local dir = go_up
dir()
```
Same applies to dispatch tables: `actions[key]()` beats `if key == 'x' then ... end`. The framework has accumulated some of this; new code and all examples must not.

**Pedagogical test.** Before adding an abstraction: *could a motivated student understand and modify this?* If not, look for a simpler path.

---

## Tone in Analytic Notes and Specs

Tech debt and internal inconsistencies are expected in any system that evolved organically under real constraints. Treat them as such — not as failures to highlight, but as context to note.

When writing analysis, specs, or review notes:
- State what is, no blame tone. "This module has accumulated several responsibilities" not "this is bad/wrong"".
- Flag debt matter-of-factly without judgement: "likely a historic tradeoff", "has known complexity here", "worth revisiting when X", "may prevent future Y unless resolved".
- The audience is the same people who built the system. They are senior, aware of the tradeoffs, and acting in good faith. They do not need to be told something is "wrong" — they need a clear picture of what is and what the options are.
- That said, no unsolicited flattery or patronism, no false reassurance. Collegial, humble, accurate and direct is the target register.

---

## Summaries for Stakeholders

When writing a stakeholder-facing summary or "in brief" section:

- **Mirror the stakeholders' own tone and everyday vocabulary** from the source input — their words ("get rid of the legacy API", "only text fields", "before 1.0", "showcase", "trivial to convert"), not internal jargon (milestone IDs, "PERT", "reftable", "facade", "sink"). Spell a term or figure out only the first time it is genuinely unavoidable.
- **Keep it short without losing meaning.** A summary is a statement, not a dialogue — no second-person address.
- **Do not re-explain stakeholders' own requests back to them in the same words.** They already know what they asked for. In a feedback-check context, answer what they actually want to know: whether any architectural regression resulted, whether price / risk / order changed, and what the new plan is — and point them to the updated `roadmap.md` / `summaries/roadmap.md`, which is where they will look.
- **Read whether they are confirming or exploring.** Judge the register of the ask first: are they *assuming* something and looking to have it confirmed or disproved, or are they *unsure* and want more information? When they are clearly assuming (a leading question, a stated presumption), frame a matching finding as a confirmation ("Confirmed: …", "as expected") rather than presenting it as a surprise — and disprove just as directly when the assumption is wrong. When they are genuinely unsure, lead with the information plainly.

---

## Commit Messages

Conventional Commits, driven by semver semantics. Full guide: `doc/development/conventions/git.md`.

| Type | When |
|---|---|
| `feat` | New capability |
| `fix` | Bug fix |
| `refactor` | Restructuring, no behavior change intended |
| `style` | Cosmetic source changes only (whitespace, comments) — **not** CSS |
| `test` | Test code only |
| `chore` | Build system, scripts, tooling — **not** "small annoying task" |
| `docs` | Documentation only |

Breaking change: append `!` to type (`feat!:`) or add `BREAKING CHANGE:` footer.
Scope: project-specific, not yet formally documented — omit rather than guess.

---

## Memory / GC

- Avoid allocation in hot paths (`update`, `draw`). Reuse tables and values where the pattern is clear.
- **Mandatory in student-facing examples.** Encouraged in new framework code. Existing framework code may have known debt here and there — just don't add more.
- Prefer iterators over intermediate tables. Prefer preallocated buffers over per-frame construction.
