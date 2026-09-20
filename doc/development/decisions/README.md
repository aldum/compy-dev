# Architectural Decisions

Per-subsystem records of *why* a subsystem is shaped the way it is — the durable
rationale behind its structure, not a walkthrough of how it works today.

This directory is deliberately distinct from its two neighbours:

- **`../internals/*`** — *how it works*: routing, dispatch, the mechanism behind each
  guarantee. Read those to understand the running system.
- **`../conventions/*`** — *house rules*: the coding and architecture principles every
  subsystem obeys.
- **`decisions/*` (here)** — *why this shape*: the load-bearing choices, the alternatives
  they were chosen over, and the constraints that made them the right call. When a reader
  asks "why is it built like this rather than the obvious other way", this is the answer.

Each doc is ADR-flavoured: it states decisions and their rationale, cross-references the
matching `internals/*` doc for mechanism rather than duplicating it, and lets the code win
on any point of fact. Open questions and accepted shortcuts live in the technical-debt
register (`../technical_debt/README.md`), not here — a decision doc records what was settled.

## Docs in this directory

| Doc | Subsystem |
|---|---|
| [`input.md`](input.md) | Keyboard/text input routing, the dispatch chain, and the project-facing input widget |
