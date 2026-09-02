# Analysis and Design Plan — Feature #77

Sequence of document artifacts from raw stakeholder input to
implementation. Each artifact is traceable to the previous.
Notes under `notes/` may inform any stage but are not canonical
— they are architect observations, intake context, and working
ideas. Distinguish them clearly from stakeholder input when
drawing on them.

---

## Artifact sequence

### 0. `input.md` ✅
Verbatim stakeholder input — original ticket and stakeholder
clarification. Canonical and immutable. All architect
observations, intake notes, and derivative context live under
`notes/`, not here.

### 1. `requirements.md` ✅
Stakeholder needs normalised and numbered, derived from
`input.md`. Source of truth for what is asked. Do not add
derived or assumed requirements without explicit stakeholder
confirmation.

### 2. `assessment.md` ← in progress
Maps each FR/NFR to the current architecture. For every
requirement: what exists, what is missing, what would need to
change. Does not propose solutions. Every finding cites a
specific FR/NFR by number.

### 3. `decisions.md`
Blocking questions that must be answered before design can
begin. Initially scaffolded from open questions in
`requirements.md §5` and decision points flagged in
`assessment.md §8`. Extended by processing new input through
`notes/` and incorporating it here.

Each entry has a question, context, what it affects, its
source, and a **Decision:** field to be filled in by
stakeholders or contributors with the authority and context
to answer it. `design.md` cannot proceed until all decisions
are settled.

### 4. `design.md`
Architecture proposal. For every gap in the assessment: a
design decision with rationale and alternatives considered.
Every decision cites both the assessment gap it resolves and
the entry in `decisions.md` that authorized the direction.

### 5. `api_spec.md`
The precise public contract: function names, signatures,
callback semantics, lifecycle rules, short usage examples.
No implementation detail — what a project author reads and
what tests verify against. Every API element is annotated with
the FR(s) it satisfies and the design decision that shaped it.

### 6. `implementation_plan.md`
Ordered tasks derived from the API spec and design, with
inter-task dependencies and rough effort estimates. Every task
cites the API element or design decision it implements.
Estimates are deferred to this stage — they are only reliable
once the API surface and design decisions are settled.

---

## Stakeholder summaries

Each completed artifact has a companion summary in
`summaries/` — a short, high-level brief intended for
stakeholders who want the essentials without reading the full
document. Summaries are named after their source artifact.

| Summary | Source |
|---|---|
| `summaries/requirements.md` | `requirements.md` |
| `summaries/assessment.md` | `assessment.md` |
| `summaries/decisions.md` | `decisions.md` |

Summaries for `design.md`, `api_spec.md`, and
`implementation_plan.md` should be added as each is completed.

---

## Traceability chain

```
input.md  (immutable stakeholder input)
  └── requirements.md  (normalised FR/NFR)
        └── assessment.md   (each finding cites FR/NFR)
              └── decisions.md  (each entry cites assessment gap or FR)
                    └── design.md  (each decision cites decisions.md entry)
                          └── api_spec.md  (each element cites FR + decision)
                                └── implementation_plan.md  (each task cites element)
```

---

## Notes feeding into each artifact

| Notes file | Feeds into |
|---|---|
| `notes/requirements.md` | open questions in `design.md` |
| `notes/concerns.md` | `assessment.md`, `design.md` |
| `notes/design.md` | `design.md`, `api_spec.md` |
