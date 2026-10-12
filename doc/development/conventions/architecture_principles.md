# Architecture Principles

<!-- authored By LLM; human-approved NOT YET -->

Compy is an educational artifact as much as a software project. Its architecture reflects that: the goal is to model good habits for students, not to maximize abstraction or minimize developer friction.

---

## Transparency

**Code in a file and code typed into the console must have the same effect.**

This is not just a technical constraint — it is the foundational design principle. It means modules must not rely on load-order side effects, implicit global state should be minimal, and the runtime environment seen by student code should feel like a natural extension of the REPL they work in daily.

A corollary: if a piece of code can only be understood in the context of its call stack, its class hierarchy, or its module graph, it is already too complex.

---

## Cognitive Budget

The structural limits in the code conventions (64-char lines, 14-line functions, 4 parameters, 4 nesting levels) are not style preferences — they are a budget. They exist to keep code within the working memory of a child reading it. This applies doubly to student-facing examples.

When a piece of code is approaching a limit, the right response is usually to rethink the design, not to raise the limit.

---

## Scope Discipline

Locals belong to the smallest block that needs them. No variable should outlive its purpose. This reduces cognitive load (fewer names in scope at any point) and avoids subtle bugs from state leaking across logical boundaries.

Extract compound conditions to named locals — this is not just style, it is a form of inline documentation that names the *intent* of a test.

---

## Prefer Functional Style

Lightweight closures, Lua iterators, and immutable-by-convention data structures are preferred over stateful objects wherever readability is not harmed. Closures are cheap, local, and self-documenting in Lua. Iterators compose cleanly. Immutable data is easy to reason about.

Deeply layered OOP — inheritance chains, manager classes, factory-of-factory patterns — is an anti-pattern here. It hides behavior, inflates the call graph, and produces code that is hard for a student (or a teacher) to follow. Our metric is not "is this extensible?" but "can someone who has been programming for six months read this?"

---

## Write Lua, Not C with Lua Syntax

A recurring C habit is using a string or integer tag as a surrogate function pointer, then dispatching on it with an if-chain:

```lua
-- C-accented Lua
local dir = 'up'
if dir == 'up' then go_up()
elseif dir == 'down' then go_down() end
```

In Lua, functions are values. The tag and the if-chain are unnecessary:

```lua
-- idiomatic Lua
local dir = go_up
dir()
```

The same applies to dispatch tables: rather than a string key checked at call time, store the function directly and call it. The result is shorter, has no conditional, and makes the intent structurally visible rather than textually described.

This matters especially in student-facing code. Students learning Lua should build Lua intuitions — treating functions as first-class values, not as something to be named with a string and dispatched manually. The C habit, once acquired, is hard to unlearn and tends to produce code that is both more verbose and harder to reason about than the idiomatic alternative.

The framework has accumulated some of this pattern in places (it is organic code); new code and all examples should avoid it.

---

## Memory Consciousness

Avoid unnecessary allocation. In a GC-managed runtime on modest hardware, object churn adds up — in tight loops especially. Prefer reusing tables and values over creating new ones when the logic permits.

This principle is **mandatory in student-facing examples** (which students read, copy, and run on real hardware) and **encouraged in new framework code**. The organically grown parts of the framework are not always clean on this front; that is acceptable technical debt, not a license to add more.

Concrete habits: avoid allocating in `update`/`draw` hot paths; prefer iterators over intermediate tables; reuse preallocated buffers where the pattern is clear.

---

## A Namespace Hands Out Live Tables by Reference, Never by Value

**If a project must reach a platform table that is still alive, expose it through the namespace's
metatable — resolved on access behind an up-value — rather than storing it as a plain field.**

The reason is the sandbox. A project's environment is a **deep clone**, taken before the run
(`../internals/project_sandbox_env.md`). A live table stored as a field is therefore copied along
with everything else, and the two sides then drift apart in the quietest way available: the program
assigns its handlers into *its* copy, the framework's dispatcher reads *the original*, and **neither
side raises**. Nothing is `nil`, nothing is out of range, nothing is logged — the handlers simply
never run. This has cost an hour of on-device debugging at least once, and it gives a debugger
nothing to grab.

The practice, then, is two habits together: resolve the table through `__index` on access, and
refuse assignment to the table itself, so a project cannot swap the surface out from under the
resolution. `compy.input` is built that way (its identities are frozen — `decisions/input.md`,
D-FROZEN-SHELL); the `serial` surface was later built the same way, assignment guard included (reported
by its author — that surface is not in this repository).

Two notes on why this is worth stating rather than leaving to be rediscovered:

- **It is not enforced by anything.** No test catches it, because a unit test holds *one* table and
  sees no divergence; the failure needs the clone to exist, which means it needs a real project run.
- **The framework has already met it from the other direction.** A project reading
  `love.state.user_input` always sees `nil` — the framework writes the real global and the project
  reads its copy — which is why `compy.input.is_shown()` exists at all (`decisions/input.md`,
  D-ONE-STATE-ASK). Same hazard, opposite direction.

It is a **suggested practice, not a ruling**: a table that is genuinely a snapshot may be handed
over by value quite correctly. The question to ask of any new namespace member is simply *"does
anyone write to this after the run starts?"* — and if the answer is yes, it goes behind `__index`.

---

## The Pedagogical Test

Before introducing a new abstraction, pattern, or dependency, ask: *would a motivated student be able to understand and modify this?* If the honest answer is no, look for a simpler approach.

The project is not a software factory. It is a teaching instrument that also happens to run.
