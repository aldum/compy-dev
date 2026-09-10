# Commit Message Conventions

<!-- authored By LLM; human-approved NOT YET -->

This project follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). The primary motivation is **automatic semantic versioning** — commit types signal the severity of a change, not just its category.

## Types

| Type | Meaning | Semver impact |
|---|---|---|
| `feat` | New feature or capability | minor |
| `fix` | Bug fix | patch |
| `refactor` | Code restructuring with no expected behavior change | none |
| `style` | Cosmetic changes only: whitespace, formatting, comments | none |
| `test` | Changes touching test code only | none |
| `chore` | Project tooling, build system, scripts — not source code | none |
| `docs` | Documentation only | none |

## Common Misreadings

**`style` does not mean CSS or UI styling.** It means cosmetic source changes — whitespace, indentation, comment wording — with zero semantic effect. This is a frequent misunderstanding in frontend projects; it does not apply here.

**`chore` does not mean "small annoying task."** It means housekeeping at the project level: changes to the build system, helper scripts, CI config, tooling. If code or tests changed, it is not a chore.

**`refactor` carries an implicit promise.** It says: behavior is not expected to change. Accidents happen, but the intent must be genuine — if you know the behavior is changing, it is a `fix` or `feat`.

## Scope

Scope (the part in parentheses: `feat(editor): ...`) follows project-specific conventions that are local to this project. These have not yet been formally documented. When in doubt, omit scope rather than guess.

## Breaking Changes

A `!` suffix or `BREAKING CHANGE:` footer signals a breaking change regardless of type (e.g. `feat!:`, `refactor!:`). This triggers a major version bump.

## Reference

Full spec: https://www.conventionalcommits.org/en/v1.0.0/
