# Feature #77 — New Input API: Session Prompt

Read `CLAUDE.md` first (project overview, collaboration rules, and pointers to reference material). Then read `agents/rules.md` (coding rules and tone — pay particular attention to the tone section before writing anything analytical).

---

## Current Status

**Ready for plan step 4 — `design.md`. Awaiting stakeholder review of `summaries/decisions.md`.**

The full artifact sequence and traceability plan is in
`notes/plan.md`. To resume: read this file, check
`notes/plan.md` for the step sequence, then proceed from the
step marked current above.

Completed: `requirements.md` (approved), `input.md`,
`assessment.md` (approved), `decisions.md` (all seven settled,
proposed resolutions filled), `summaries/decisions.md` (ready
for stakeholder review), and all files under `notes/`.

The old `feature_correlation.md` in this directory has been
drained into `notes/` and can be ignored.

---

## Background

This is a feature design session for **feature #77: new input API**. The work lives under `doc/development/wip/77-new-input-api/`.

Key files in this directory:

- `input.md` — verbatim stakeholder input (original ticket + stakeholder clarification). Canonical and immutable. Any architect observations or intake notes live under `notes/`, not here.
- `requirements.md` — normalized requirements document derived from `input.md`.
- `assessment.md` — architecture assessment mapping requirements to current code.
- `notes/` — architect notes, design ideas, concerns, and the analysis plan. See `notes/plan.md` for the full artifact sequence.
- `summaries/` — short stakeholder-facing briefs for each completed artifact.
- `feature_correlation.md` — early draft, drained into `notes/`. Can be ignored.

---

## Architecture Context

Before doing any of the tasks below, read the following — do not re-derive from source code what is already documented:

- `doc/development/overview.md` — MVC structure, entry points, application modes
- `doc/development/internals/console.md` — project lifecycle, environments, `user_input` overlay API, `reftable` pattern
- `doc/development/internals/user_input.md` — the shared input widget, keyboard/mouse dispatch, text flow
- `doc/development/internals/editor.md` — editor input handling (relevant because the new API should ideally be expressive enough to reimplement the editor's input behaviour)

---

## Task 1 — `requirements.md`

Produce a new `requirements.md` in this directory as a proper normalized requirements document — the kind a business analyst would write. Source material is `input.md`; keep that file as-is.

The document should:
- List discrete, unambiguous requirements — not implementation decisions
- Distinguish functional requirements from non-functional ones (GC/allocation behaviour, consistency with existing Compy idioms, pedagogical considerations for student-facing examples)
- Note explicitly what is out of scope or deferred
- Stand alone without requiring the reader to have read the raw source

Do not propose solutions or reference implementation internals. **Stop after producing `requirements.md` and wait for the user to review it before proceeding.**

---

## Task 2 — `assessment.md` (only after Task 1 is approved)

Replace the existing `assessment.md` with a proper architecture assessment. It should:
- Map each requirement from `requirements.md` to the relevant parts of the current architecture, with file/function references
- Identify what can be reused, what needs extension, and what needs replacement
- Identify constraints and risks — including GC/allocation implications and the singleton nature of the current input overlay
- Not propose a solution — only characterise the gap between requirements and current state

Use the existing `assessment.md` as a source of hints for gap identification, but rewrite from scratch using the architecture docs as the primary knowledge base. The inline questions and remarks in the old doc signal real uncertainties — address them with facts from the codebase rather than inheriting the speculation.

**Stop after producing `assessment.md` and wait for the user to review it before proceeding.**
