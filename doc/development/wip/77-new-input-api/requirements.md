# Feature #77 — New Input API: Requirements

*Normalized from stakeholder input in `input.md`
(original ticket + stakeholder clarification). Does not propose
solutions or reference implementation internals.*

---

## 1. Context and Purpose

Compy user projects currently access text input through a small
set of functions (`input_text`, `input_code`, `validated_input`,
`user_input`). These return a polled reference; the project
checks it on each update tick to detect when the user has
submitted something. There is no way to receive keyboard events
while input is active, and no way to hide or show the input
area without tearing it down entirely.

This feature defines a replacement API that addresses these
limitations. The intended users of the API are Compy project
authors — primarily students writing Lua on the Compy device.

---

## 2. Functional Requirements

### 2.1 Edit Area Setup

**FR-1** The API shall allow a project to create a text edit
area. The following parameters shall each be independently
optional:

| Parameter | Description |
|---|---|
| Initial text | Pre-fills the edit area with a given string |
| Initial cursor position | Places the cursor at a specified position within the initial text |
| Syntax highlighter | Applies highlighting as the user types |
| Input validator | Validates input per character and on submit |
| Prompt label | Displays a label alongside the edit area |

### 2.2 Edit Area Lifecycle

**FR-2** The API shall allow the project to programmatically
remove (tear down) the edit area.

**FR-3** The API shall allow the project to hide the edit area
without removing it.

**FR-4** The API shall allow the project to show a previously
hidden edit area.

### 2.3 Event Notifications

**FR-5** The API shall provide a way for the project to receive
notification when the user submits input (nominally: presses
Enter without a modifier).

**FR-6** The API shall provide a way for the project to receive
notification when a key event occurs that does not produce a
text character in the edit area. This covers at minimum:
- keys pressed together with the Ctrl modifier; and
- non-character keys such as navigation keys and function keys
  (noting the hardware constraint: built-in function keys on the
  Compy device are intercepted by the OS and may not be
  receivable — see §4).

**FR-7** The API shall provide a way for the project to receive
notification when a cursor movement is attempted beyond the
first or last valid position in the edit area (a boundary hit).

### 2.4 Programmatic Text and Cursor Control

**FR-8** The API shall allow the project to query the current
cursor position while the edit area is active.

**FR-9** The API shall allow the project to change the cursor
position programmatically while the edit area is active.

**FR-10** The API shall allow the project to change the text
content of the edit area programmatically while it is active.

### 2.5 API Expressiveness

**FR-11** The API should be expressive enough that the console
REPL's input behaviour could be re-implemented using it, without
accessing the underlying implementation directly.

**FR-12** The API should be expressive enough that the editor's
input handling could be re-implemented using it, without
accessing the underlying implementation directly.

*FR-11 and FR-12 are expressiveness targets, not a commitment
to rewrite the console or editor as part of this feature. They
function as acceptance criteria for API completeness.*

---

## 3. Non-Functional Requirements

**NFR-1 (Allocation / GC)** The API shall not require creating
a new object graph for each input session. Reusing or
reconfiguring an existing instance on repeated invocations is
the expected pattern. This applies to student-facing example
code using the API; new framework code implementing the API
should follow the same discipline.

**NFR-2 (Event-driven model)** The event notification mechanism
shall be consistent with LÖVE2D's event-driven style (callbacks
registered on an object or namespace) rather than requiring the
project to poll a reference for results.

**NFR-3 (Compy API consistency)** The API shall fit naturally
within existing Compy conventions (namespace, naming, calling
style) so that projects using it do not encounter a stylistic
discontinuity with the rest of the `compy.*` surface.

**NFR-4 (Pedagogical usability)** Simple use cases — showing an
input prompt and receiving the result via callback — shall
require minimal configuration. A student should not need to
understand framework internals to use the basic API.

---

## 4. Out of Scope

The following are not addressed by this feature:

- **Multiple simultaneous edit areas.** The single active edit
  area constraint is not relaxed; the requirements do not ask
  for more than one at a time.
- **Touch input.** Touch event handling is not mentioned and is
  separately deferred in the codebase.
- **Built-in function key support.** The Compy device's
  built-in keyboard has its top-row function keys intercepted
  by Android. FR-6 covers external keyboards; built-in function
  keys are not a supported use case.
- **Mouse interaction beyond current behaviour.** The
  requirements do not change or extend mouse handling on the
  edit area.
- **Immediate rewrite of console or editor.** FR-11/FR-12 are
  consistency tests for API design, not implementation tasks.

---

## 5. Open Questions / Deferred

The following items are not specified in the stakeholder input
and require a decision before or during design:

- **Backward compatibility — RESOLVED (clean break).** Whether
  `input_text()`, `input_code()`, `validated_input()`, and
  `user_input()` must continue to work was originally unstated.
  Stakeholders ruled on it in `input.md` (feedback round 1,
  2026-06-06): **no backward compatibility** — the legacy
  text-input functions are removed, and the existing examples
  (tixy, repl, guess, turtle, valid, balloons) that rely on them
  are migrated to the new API or excluded from the release. The
  break is bounded to text input; native keyboard handling is
  unaffected. See `decisions.md` D-1.

- **Behaviour when setup is called while already active.** The
  expected result — silently skip, replace, or error — is
  unspecified.

- **Cancel / dismiss notification.** A callback for when the
  user dismisses the edit area (nominally Escape) is not
  explicitly listed. It is coverable via FR-6 if the project
  handles Escape as a non-character key event, but a dedicated
  dismiss notification may be expected. To be confirmed.

- **Granularity of FR-6.** Whether Ctrl+key events and other
  non-character key events should trigger the same notification
  or separate ones is left to design.

- **Boundary definition in multiline input (FR-7).** In a
  multiline edit area, "boundary" may mean end-of-current-line,
  end-of-the-entire-input, or both. The distinction matters for
  how projects use the callback (e.g. block navigation in an
  editor-like interface). Clarification is needed.
