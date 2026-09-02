# repl

**Minimal REPL.** Accepts text input from the user and echoes it to the terminal.

## Code

```lua
r = user_input()

function love.update()
  if r:is_empty() then
    input_text()
  else
    print(r())
  end
end
```

## Purpose

The smallest possible demonstration of the `user_input` / `input_text` polling pattern. No game logic, no drawing, no state. Useful as a reference skeleton for any project that needs live text input in an `update()` loop.

## Notes

`input_text()` is called with no arguments — no prompt, no initial text. The overlay appears with an empty input field. On submit, `r()` returns the entered string and the cycle begins again.

## Files

`src/examples/repl/main.lua`
