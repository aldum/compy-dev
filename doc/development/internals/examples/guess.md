# guess

<!-- authored By LLM; human-approved NOT YET -->

**Number guessing game** with per-character input validation.

## Architecture

Single-file. No `love.update`/`love.draw` override — output goes to the terminal via `print()`; input is driven entirely by the `compy.input.*` callback API **(supported since 1.0.0-rc20260712)**.

## Input pattern

```lua
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

init()

compy.input.show{
  prompt = "Guess a number:",
  validator = LineValidators({ is_natural }),
  on_text_entered = function(text) check(tonumber(text)) end,
}
```

This is the continuous-session idiom (see [Compy Input API](../../../input_api.md)): `compy.input.show{}` activates the widget once; `on_text_entered` receives the submitted text as one string while the session is active — as does every other content-bearing callback (D-ONE-PAYLOAD, which retired the split that gave `after_submit` the lines). The next draft is cleared by the widget's own `clear_on_submit`, seated for every project widget; the hand-written `after_submit` that did it was dropped on 2026-09-09. `LineValidators({ is_natural })` adapts the existing line rule to the widget validator.

The old `r = user_input()` / `validated_input(...)` polling pattern is **(deprecated, removed in 1.0.0-rc20260712)**.

## Validator

`is_natural` validates that the input is a string of digit characters using `string.forall(digits, Char.is_digit)`. Returns an `Error` object with a column position on failure — the framework uses this to highlight the offending character in the input widget.


## Files

`src/examples/guess/main.lua`
