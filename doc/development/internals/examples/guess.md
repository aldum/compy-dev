# guess

**Number guessing game** with per-character input validation.

## Architecture

Single-file. Uses pen-and-paper mode with `love.update` polling the `user_input` handle. No `love.draw` override — output goes to the terminal via `print()`.

## Input pattern

```lua
r = user_input()

function love.update()
  if r:is_empty() then
    validated_input({ is_natural }, "Guess a number:")
  else
    local n = tonumber(r())
    check(n)
  end
end
```

This is the canonical `validated_input` pattern: poll `r:is_empty()`, show the input overlay when nothing is pending, consume and process when something arrives. The `validated_input` call only fires if there's currently no active overlay (the framework guards against double-activation).

## Validator

`is_natural` validates that the input is a string of digit characters using `string.forall(digits, Char.is_digit)`. Returns an `Error` object with a column position on failure — the framework uses this to highlight the offending character in the input widget.

Note: `is_natural` is defined twice in the file (the second definition overwrites the first). The second version uses `Char.is_digit` from the framework's string utilities; the first used `tonumber`. This is organic evolution — the first definition is dead code.

## Files

`src/examples/guess/main.lua`
