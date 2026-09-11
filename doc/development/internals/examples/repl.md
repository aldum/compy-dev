# repl

<!-- authored By LLM; human-approved NOT YET -->

**Minimal input loop.** Accepts a line from the user and **prints it straight back** to the terminal.

Despite the name, it does **not** evaluate what you type: `on_text_entered` receives the submitted
text and passes it to `print`, and the widget is provisioned with the plain-text
evaluator (`InputEvalText`, `main.lua:370`), which has no parser and executes nothing. Type `x = 2 + 3`
and you get the characters `x = 2 + 3` back, not a binding. Making it a real read-**eval**-print loop
is an open question for the examples, not a documentation gap.

For the full project-author usage guide, see [Compy Input API](../../../input_api.md).

**Why this example uses two callbacks rather than one.** Everything here would fit
in a single `on_text_entered`. The split is the idiom, not a demonstration of
variety: `on_text_entered` takes the text the user typed, and `after_submit` does
the mechanical tidying that happens to run at submit time. A project is never
obliged to use both — `valid` follows the same shape for the same reason. The
guide's *"Which one should your work go in?"* states the rule and says nothing
enforces it.

## Code

```lua
-- Continuous-session idiom (doc/input_api.md, "Submit
-- lifecycle"): consume the text in on_text_entered;
-- the widget stays shown by default now, so after_submit just clears
-- the text for the next line instead of re-showing.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
```

## Purpose

The smallest possible demonstration of the `compy.input.show`/`after_submit` continuous-session idiom **(supported since 1.0.0-rc20260712)**. No game logic, no drawing, no state, no evaluation. Useful as a reference skeleton for any project that needs live text input.

## Notes

`compy.input.show` is called with just `on_text_entered` — no label, no initial
text — so the widget appears empty. `on_text_entered` receives the submitted text as one string while the session is active; `after_submit` is a direct callback assignment that clears the next draft.

The old `user_input()`/`input_text()` poll-a-reftable pattern (`r = user_input()`, `r:is_empty()`, `r()` each `love.update()` tick) is **(deprecated, removed in 1.0.0-rc20260712)**.

## Files

`src/examples/repl/main.lua`
