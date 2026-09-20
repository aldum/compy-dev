# valid

<!-- authored By LLM; human-approved NOT YET -->

**Validator showcase.** Collects user input with a combination of custom validators and prints the result.

## Architecture

Single-file. No drawing, no game logic, no `love.update`/`love.draw` override — driven entirely by the `compy.input.*` callback API **(supported since 1.0.0-rc20260712)**.

## Validators defined

| Validator | Rule |
|---|---|
| `min_length(n)` | Input must be longer than n characters |
| `max_length(n)` | Input must be at most n characters |
| `is_upper(s)` | All characters must be uppercase |
| `is_lower(s)` | All characters must be lowercase (uses `string.forall` + `Char.is_lower`) |
| `is_number(s)` | Must be a valid integer (handles leading `-`) |
| `is_natural(s)` | Must be a non-negative integer |

Each returns `true` on success or `false, Error("message", column)` on failure. The `Error` column is used by the framework to highlight the specific offending character in the input widget.

## Active validators

```lua
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  validator = LineValidators({
    min_length(2),
    is_lower
  }),
  on_text_entered = function(text) print(text) end,
}
```

Validation is wired via `LineValidators({...})` **(supported since 1.0.0-rc20260712)** — the same validator-list shape the old `validated_input` took. All validators in the list must pass for every submitted line to be accepted. `after_submit` is a direct field write that clears the next draft; see [Compy Input API](../../../input_api.md).

## Purpose

Demonstrates `LineValidators` and how to write validator functions with column-accurate error reporting. The validator signatures here are the reference implementation pattern for any project that needs constrained text input. The old `validated_input(...)` polling API is **(deprecated, removed in 1.0.0-rc20260712)**.

## Files

`src/examples/valid/main.lua`
