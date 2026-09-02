# valid

**Validator showcase.** Collects user input with a combination of custom validators and prints the result.

## Architecture

Single-file. Pen-and-paper mode with `love.update` polling. No drawing, no game logic.

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
validated_input({
  min_length(2),
  is_lower
})
```

All validators in the list must pass for the input to be accepted. If any fail, the first error's column is highlighted.

## Purpose

Demonstrates the `validated_input` API and how to write validator functions with column-accurate error reporting. The validator signatures here are the reference implementation pattern for any project that needs constrained text input.

## Files

`src/examples/valid/main.lua`
