# tixy

**Live-coded pixel grid** inspired by tixy.land. A 16×16 grid of circles whose radii and colors are driven by a user-editable formula `tixy(t, i, x, y)`.

## Architecture

Single-file (with `mathlib.lua` for extra math and `examples.lua` for preset formulas). Overrides `love.draw`, `love.update`, `love.mousepressed`.

## Live coding mechanism

The heart of the example:

```lua
function setupTixy()
  local code = "return function(t, i, x, y)\n" ..
      "  " .. body ..
      "  return r\n" ..
      "end"
  local f = loadstring(code)
  if f then
    setfenv(f, _G)
    tixy = f()
  end
end
```

`body` is a single line of Lua (e.g. `r = math.sin(t + x)`). `loadstring` compiles it wrapped in a function, `setfenv` gives it access to the global environment, and the returned closure becomes `tixy`. This is called whenever the user submits new code.

## Input pattern

Uses `input_code()` overlay — the input widget has Lua syntax highlighting and validation. The `r = user_input()` / `input_code(...)` polling pattern is identical to other examples, but the prompt is the function signature and the initial content is the current formula body.

```lua
r = user_input()
function love.update(dt)
  time = time + dt
  if r:is_empty() then
    input_code("function tixy(t, i, x, y)", string.lines(body))
  else
    local ret = r()
    body = string.unlines(ret)
    setupTixy()
  end
end
```

`write_to_input(body)` in `load_example()` pre-fills the input with the current formula when loading a preset — the user sees the formula they're about to run before submitting.

## Example cycling

`examples.lua` is a table of `{code, legend}` pairs. Left click advances, right click randomizes. `advance()` and `retreat()` call `load_example()` which calls `setupTixy()` and `write_to_input`.

## Points of attention

- `setfenv(f, _G)` gives the live code full access to the global environment. This is intentional (educational context, trusted user) but means any global can be clobbered by a formula.
- If `loadstring` fails (syntax error in `body`), `setupTixy` silently leaves the old `tixy` function in place.
- `tonumber(tixy(ts, index, x, y)) or -0.1` — graceful fallback if the formula returns nil or non-numeric.

## Files

`src/examples/tixy/` — main.lua, mathlib.lua, examples.lua
