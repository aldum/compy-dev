# Prompt 4 — Independent chain validation

Read `CLAUDE.md` first (project overview, collaboration rules, and pointers to
reference material). Then read `agents/rules.md` (coding rules and tone — pay
particular attention to the tone section before writing anything analytical).

## Permissions

Write all output to disk. You are expected to create files directly — do not
just print the validation report in conversation. Any local file operation is
permitted: read, write, edit, search, grep, sed, and similar tools. The only
prohibited operations are those that modify git history: no commits, no
rebases, no amends, no force operations.

Write the validation report to:
`doc/development/wip/77-new-input-api/validation_report.md`

---

## Purpose

Perform an independent review of the full feature #77 document chain —
from the original feature request through to the implementation roadmap.
The goal is to surface any gaps, contradictions, or unsupported claims
before stakeholder review and before implementation begins.

You are a reviewer, not a co-author. Do not rewrite documents — report
findings only. Be specific: cite document name, section, and the exact
claim or gap.

---

## Project context

**Compy** is a console-based, Lua-programmable fantasy computer for children,
built on LÖVE2D v11.5. MVC architecture, Lua 5.1/LuaJIT. The codebase is at
`src/`. Architecture documentation is under `doc/development/`.

Feature #77 adds a callback-based event API to the project input overlay.
All working documents are under `doc/development/wip/77-new-input-api/`.

---

## The document chain

Read these documents in order. Each builds on the previous.

| # | File | Role |
|---|---|---|
| 1 | `input.md` | Original stakeholder feature request |
| 2 | `requirements.md` | Formalised FR and NFR derived from input |
| 3 | `assessment.md` | Current architecture assessment; problem framing |
| 4 | `decisions.md` | Seven blocking decisions and their resolutions |
| 5 | `design.md` | Architectural design: components, routing, API surface |
| 6 | `spec.md` | Specification: precise contracts, signatures, edge cases |
| 7 | `roadmap.md` | Milestones, effort blocks, estimates |

Summaries (`summaries/*.md`) are condensed versions of the above. Validate
that each summary accurately represents its source — no claims present in
the summary that are absent or contradicted in the full document.

---

## Supporting material

Use these to verify factual claims about the current codebase. Do not treat
them as design authority — they are observations about the current state.

- `notes/routing_unification.md` — routing before/after diagrams
- `notes/love2d_handler_layers.md` — LÖVE2D handler architecture
- `notes/event_delegation_chain.md` — current four-context routing
- `notes/enter_escape_routing.md` — Enter/Escape behavior across contexts
- `notes/textinput_routing.md` — textinput path, combo assembly, event taxonomy
- `notes/solution_sketch.md` — design source that informed design.md

If a claim in the chain documents can be verified against the codebase,
do so. Relevant source files:
- `src/controller/controller.lua` — global handler, overlay gate, lifecycle
- `src/controller/consoleController.lua` — REPL and editor routing
- `src/controller/userInputController.lua` — widget keypressed/textinput
- `src/controller/editorController.lua` — editor mode dispatch, passthrough
- `src/model/input/userInputModel.lua` — evaluate, handle, oneshot, cancel

---

## What to validate

Check each of the following dimensions. Report findings per dimension.

### 1. Requirements coverage

For every functional requirement (FR-1 through FR-N) and non-functional
requirement (NFR-1 through NFR-N) in `requirements.md`:
- Is it addressed by at least one decision in `decisions.md`?
- Is the addressing decision carried through into `design.md`?
- Is the design point covered in `spec.md`?
- Is implementation of that spec point present in at least one `roadmap.md`
  milestone?

Flag any requirement that drops out at any step.

### 2. Decision consistency

For each decision D-1 through D-7 in `decisions.md`:
- Is the stated resolution actually reflected in `design.md`?
- Is the resolution carried through consistently into `spec.md`?
- Does any later document contradict or silently override a decision?

Flag any decision whose resolution is asserted but not implemented in
the downstream documents.

### 3. Design-to-spec completeness

For every component and API surface described in `design.md`:
- Does `spec.md` provide a precise contract for it?
- Are signatures complete (parameter names, types, return values)?
- Are edge cases covered (what happens when called in wrong state,
  with missing arguments, or during a conflicting operation)?

Flag any design element that has no corresponding spec entry, or any
spec entry that references a component not described in design.

### 4. Spec-to-roadmap coverage

For every spec item (API function, callback, data structure, edge case):
- Is there a roadmap milestone that delivers it?
- Is documentation for it included in the documentation effort block?
- Is a test for it (or a test category covering it) in the test effort block?

Flag any spec item with no roadmap home.

### 5. Roadmap ordering validity

The milestones in `roadmap.md` claim to be implementation-dependency aware —
each milestone is testable independently before the next begins.
- Verify this claim for each consecutive milestone pair.
- Identify any milestone that implicitly depends on a later milestone.

### 6. Factual accuracy against codebase

Check the following specific claims against the source files listed above:
- The overlay gate (`if user_input then ... else ... end`) exists in
  `controller.lua` at the described location.
- `UserInputController:keypressed` is the shared sink for both REPL/editor
  branches and the overlay branch.
- `oneshot` flag controls the submit path in `UserInputController`.
- `love.state.user_input` is currently set by the project input functions
  and read by the overlay gate.
- `ConsoleController` is wired into `love.keypressed` at startup.
- The before/after chain mechanism does not yet exist in the codebase
  (i.e. it is a new addition, not a refactor of existing chains).

Report any claim that does not match observed code.

### 7. Summary fidelity

For each summary in `summaries/`:
- Does it accurately represent the full document it summarises?
- Does it contain any claim not present in the full document?
- Does it omit anything that a stakeholder would consider a decision-relevant
  fact (vs. implementation detail)?

---

## Output format

Produce a structured validation report. Use this structure:

```
# Validation Report — Feature #77 Document Chain

## Status: PASS / PASS WITH NOTES / FAIL

## Findings by dimension

### 1. Requirements coverage
[table or list: each FR/NFR, status (covered / gap), note]

### 2. Decision consistency
[list: each decision, status, note if issue found]

### 3. Design-to-spec completeness
[list: gaps found, or PASS]

### 4. Spec-to-roadmap coverage
[list: gaps found, or PASS]

### 5. Roadmap ordering validity
[list: dependency issues found, or PASS]

### 6. Factual accuracy
[list: each checked claim, CONFIRMED / MISMATCH, note if mismatch]

### 7. Summary fidelity
[list: per summary, status, note if issue found]

## Summary of actionable items
[numbered list of issues that must be resolved before implementation]
```

Be specific. "Gap found" is not useful. "FR-6 (non-character key notification)
is addressed by D-3 in decisions.md and present in design.md §4, but
spec.md §3 does not specify what `k` contains when a function key is pressed"
is useful.
