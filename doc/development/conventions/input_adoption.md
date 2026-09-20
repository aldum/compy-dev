---
description: Question-and-action checklist for adopting the input API — applied to the examples, written to be reused for the console and editor
status: active
audience: developer
authored: llm
reviewed: none
---

# Adopting the input API — a review checklist

Operational form of **D-USAGE-SHAPE** (`../decisions/input.md`), which states *why*; this states
*what to do*. Written as **question → action** so it can be applied to code without reading the
reasoning first, and so it survives being handed to someone who has not.

Its first use was the example corpus. It is written to be **reused when the console and the editor
are evaluated**, so each rule is marked:

- **[universal]** — true of any code that reads input, framework included;
- **[project surface]** — depends on `compy.input`, so framework-side code must translate the
  intent rather than copy the instruction.

The project-facing version of the same material is `doc/input_api.md`,
"Choosing the mechanism: transitions, state, and what not to build".

---

**Q1 [universal] — Does it keep its own copy of held state?** A boolean mirroring a key, a table
of keys currently down, a `*_was_down` companion.
→ **Delete it; ask at the point of use.** A mirror has no reconciliation path: focus loss, a
missed release or an unexpected event order leaves it lying and nothing corrects it. If a project
has a real reason to keep one, that is a decision it states, not a default (D-USAGE-SHAPE.5).

**Q2 [universal] — Does it re-implement the left/right fold?** `isDown('lshift','rshift')`,
`is_shift_down()`, `modHeld(a, b)` — any helper meaning "either of the pair".
→ **Call `Key.shift()` / `Key.ctrl()` / `Key.alt()`.** The fold ships already, and a local copy
also hard-codes *which keys are modifiers* — a set that has changed once (D-THREE-MODS).

**Q3 [universal] — Does one expression mix `Key.*` with raw `love.keyboard.isDown`?**
→ **Route both through `Key`**: the folded accessors for a modifier, `Key.any_pressed(k)` for any
other key. Two spellings of one question in one line read as two mechanisms.

**Q4 [universal] — Does it answer *"did this just happen"* by polling plus edge detection?** A
per-frame poll with a previous-value companion, deriving a transition.
→ **That is an event.** Use the channel — a hook, or a shortcut if it names a combo. The poll and
its companion both go. Watch for one behaviour change: a bare-key binding matches only when no
modifier is held, where the poll fired regardless.

**Q5 [universal] — Does it answer *"is this held right now"*?** A key cap to light, a modifier
gating a drag, a paddle key.
→ **Poll, and leave it alone.** This is the correct shape, not a rung to climb (D-USAGE-SHAPE.4).

**Q6 [universal] — Does it open a state on one channel and close it on the mirrored one with the
same combo?**
→ **Antipattern; replace it** (D-USAGE-SHAPE.2). Poll the condition instead, or restructure so the
ending does not depend on a matching event. Note that a modifier's own release has no bindable
combo, so sometimes the closing half cannot be written at all.

**Q7 [universal] — Is physical keyboard state consulted deep inside logic?**
→ **Lift it.** Read the keyboard early — top of the handler, shortcut or `update` — into names
carrying domain meaning, then run the logic on those. Keeps the non-deterministic input visible in
one place instead of scattered through deterministic code.

**Q8 [project surface] — Does one hook demultiplex several orthogonal combos by hand?**
→ **Split into shortcuts, one per combo.** That is what they are for: decomposition, not
capability (D-USAGE-SHAPE.1).
→ **But a key-to-MEANING table is not this** (owner, 2026-08-13). A lookup that turns a key name
into a domain action — `PLAN_ACTS[k]`, `SYSTEM_KEYS[k]`, a menu's `key == k` scan — is **early
translation from keyboard coordinates into game semantics**, which is what Q7 asks for. It is
already decoupled from the triggering event, and that is the desired end state, not an
antipattern. Q8 is about **combos** demultiplexed by hand, not about every table keyed by a key
name. Two further reasons such a table usually should not become shortcuts: shortcuts are
**project-global** while these tables are typically **mode- or screen-scoped**, and the table is
often **data-driven** (built from level data), which no per-combo registration can express.

**Q9 [project surface] — Is a binding on the release channel?**
→ **Legitimate if it is a choice** (D-USAGE-SHAPE.3) — it sidesteps key repeat with no filtering.
Two cautions: `fn.ignore_repeat` does the same job on the press channel, and a *modified* combo
can be missed on release when a modifier comes up first, so prefer release for bare keys.

**Q10 [project surface] — Does it re-implement *"this modifier and none of the others"*?**
→ **For a binding, use the class key** (`'shift+*'`) — it means exactly that, folded over every
modifier the framework knows. **For a query**, spell the exclusion out and accept that it
hard-codes the modifier set; a query primitive that would delegate it is proposed but not built
(`../technical_debt/input.md`).

**Q11 [project surface] — Does the project keep a captured `love.*` handler on a channel where
it also registers shortcuts?**
→ **Declare it as `compy.input.hooks.<event>` instead** (owner ruling, 2026-08-13). The framework
seeds a captured `love.*` handler as the hook automatically, so both spellings *work* — but they
do not read the same. A reader of `function love.keypressed(k)` reasonably believes they are
looking at a native callback that receives every event; once a shortcut exists on that channel,
they are not — the shortcut runs first and can consume the event before the handler sees it.
Spelling it `hooks.keypressed` puts the handler on the same surface as the thing that guards it,
where the relationship is visible. **The condition is per channel:** a `textinput` shortcut says
nothing about a `mousepressed` callback, and a project with no shortcuts on a channel may keep
its captured callback there.

---

## Rules of restraint

These are not optional, and each was bought with a mistake.

- **Behaviour-preserving, or recorded and deferred.** If a conversion is not obviously
  behaviour-preserving it is not sweep work: record it with its reasoning and leave it to a step
  that can rule on it.
- **A deviation is stated in the workspace** — in a document or a comment — not only in a commit
  message. A commit message is not part of what a reader has open.
- **Purpose beats shape.** Code whose *shape* matches an antipattern may exist for a reason nobody
  wrote down. Ask the author before converting: one example's press-time modifier path looked
  exactly like a hand-rolled cascade and was a deliberate touch-device fallback.
- **Code that demonstrates a path is not a candidate for converting off it.** One example
  deliberately keeps its handlers on the captured `love.*` path because it is the only place that
  path is visible.
- **A narrowing is a change.** Binding what a poll used to answer generally — a bare key, an
  exclusive class — silently stops firing in cases that used to work, and it is invisible in the
  diff that introduces it. Say it, or do not do it.
