---
description: Front matter every doc under doc/ carries — what the fields mean, what they replace, and how provenance is recorded
status: active
audience: developer
authored: llm
reviewed: none
---

# Documentation Conventions

Owner ruling, 2026-07-31. Before it, provenance lived in an HTML comment
(`<!-- authored By LLM; human-approved NOT YET -->`) carried by 58 files, while
one file carried YAML front matter and the three most load-bearing documents
carried neither. This replaces both with one block.

## The block

Every document under `doc/` opens with YAML front matter — the
Jekyll/Hugo/Obsidian convention, which is what the block above is; there is no
governing standard beyond it, so these fields are ours:

```yaml
---
description: one line, what the document is for
status: active | draft | superseded
audience: developer | project author | stakeholder
authored: llm | human | mixed
reviewed: none | <name>, <YYYY-MM-DD>
---
```

- **description** — one line. It is what a reader sees in an index or a search
  result, so write what the document is *for*, not what it is called.
- **status** — `superseded` documents keep a pointer to their successor in the
  body, they are not deleted.
- **audience** — who it is written for. `project author` means someone writing
  a project that runs inside Compy; `stakeholder` means someone reviewing what
  was built without reading the code.
- **authored** — who wrote the prose. `mixed` is honest and common.
- **reviewed** — `none` until a human has actually read it end to end, then the
  reviewer and the date. This is the field the old comment's
  "human-approved NOT YET" was carrying; it is not a formality, and it does not
  update itself.

## Rules

- The block is the **only** place provenance is recorded. Do not re-add the
  HTML comment.
- `reviewed:` is changed by the reviewer, not by the author and not by an
  agent — an agent may add the field with `none`, never fill it in.
- A renamed heading breaks every citation pointing at it. When you rename one,
  grep `src/`, `tests/` and `doc/` for the old anchor and repoint it in the
  same commit.
- Cite canonical docs (`doc/…`), never a feature's ephemeral working tree
  (`doc/development/wip/…`), and cite a **named section** rather than a
  paragraph number.
- **An ephemeral *id* is a citation too** (owner ruling, 2026-09-03). A bare
  `FIX-02-05` or `BUG-01-11` is not a path, but it resolves only inside the
  working tree that names it, so it dangles the day that tree is deleted — the
  same failure as a `wip/` link, with nothing to grep for. A persistent document
  says **what was decided or done and when**; the sprint id that carried it
  belongs in the working tree, or spelled out (*"the pass that base-checked the
  retired entries, 2026-09-02"*) where the reader needs the referent.
- **`agents/` is mostly ephemeral, and the split does not follow file
  boundaries** (owner ruling, 2026-09-03, refined the same day). The rule chain is
  a **working surface that is not promoted upstream**, so it may cite `wip/`
  freely. It does not leave whole: **generic rules survive** — commenting, the
  coding guide, documentation formatting — while **workflow, boot pointers and
  operational limits (the git rules) do not**, being local to how this repository
  is worked. One file can hold both.
  So a citation from `doc/` into `agents/…` is unsafe by default, and the safe
  form costs nothing: **name the rule and state what it says** (*"a decision does
  not argue with a version that never released"*) rather than pointing at a path.
  A citation written that way survives whichever side of the split its target
  lands on.

## Vocabulary: synonyms inside one context are prose, not drift (owner ruling, 2026-09-05)

**Two words are a defect when they can be confused, not when they differ.** Where a set of words
is used in **one context**, cannot refer to anything else inside it, and does not appear outside
it, they are **contextual synonyms** — and they are left alone. Collapsing them onto a single
token buys no clarity, because nothing was ambiguous; what it costs is readability, since a
passage repeating one token reads as mechanical and monotonous.

**The worked case.** *Chain*, *the walk* and *tier* all name the input subsystem's dispatch
sequence — the structure, the traversal of it, and a position within it. A sweep was scoped to
collapse them and was **ruled not a defect and closed unswept**: the three appear only where
dispatch is being described, nothing else there could be meant, and the prose is better for the
variation. **The set is four wide, not three** — *tier* is redundant with *consumer*,
*participant* and *component* besides, measured 2026-09-05 and ruled the same way. A four-way
contextual synonym set is still not drift, and the count is stated here so a later pass does not
re-derive the question from a fresh grep and reach a different answer than the ruling did.

**The boundary, because the opposite rule is real and sits one line away.** A sweep **is** owed
when the same word carries **two senses**, or when a word has been **ruled** to belong to one
thing and prose uses it for another. `hook` / `callback` / `handler` are the counter-case: they
are not synonyms at all — the decisions ledger assigns each to a different owner of the name, so
calling a `love.*` function a *callback* collides with the widget's own `callbacks` table. So is
a name used for two referents, which is what put *prompt* out of use for the input widget while
it kept its meaning as the label.

**The test to apply, in one question: can a reader land on this word and reach the wrong
referent?** If yes, it is a sweep. If the only cost is repetition, leave it.

## Vocabulary: "de-facto behaviour" has a boundary (owner ruling, 2026-08-11)

**"De-facto behaviour" names what preceded a feature and is being canonicalised by it.** It must
**never** describe behaviour the feature itself introduced.

A *decision* is a choice made during a feature's design or development. Behaviour that predates
the feature and is merely being written down is **documentation of de-facto behaviour** — it may
well deserve a place in an internals guide, and it does **not** deserve a ledger entry, because
nothing was decided.

**Why the rule is written down rather than assumed.** The confusion is characteristic of an
assistant reading the current tree: a shape that has been in the code for twenty minutes reads
exactly like a shape that has been there for a year, and calling the former *de-facto* turns a
choice the team made — and could revisit — into an inherited fact nobody owns. The test is
mechanical and cheap: **compare against the pre-feature base.** If the behaviour is there, it is
de-facto; if it arrived with the work, it is a decision, however obvious it now looks.
