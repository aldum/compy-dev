# turtle

**Turtle graphics interpreter** driven by typed commands and keyboard input.

## Architecture

Multi-file: `main.lua` (main loop, input wiring), `action.lua` (command table), `drawing.lua` (rendering: background, turtle icon, trail, debug overlay).

Overrides `love.draw`, `love.update`, `love.keypressed`, `love.keyreleased`.

## Input pattern

Dual input: typed commands via `input_text()` overlay, and direct keyboard actions.

```lua
local r = user_input()

function love.update()
  if not r:is_empty() then
    eval(r())
  end
end
```

`eval(input)` looks up `actions[input]` and calls the function if found. Actions are defined in `action.lua` as a table mapping strings to closures. Typed input is thus a command dispatcher.

`love.keyreleased`: `i` key opens the input overlay interactively (`r = input_text("TURTLE")`), overwriting the existing `r` reference. `shift+r` resets turtle position.

## Drawing

`drawing.lua` contains `drawBackground()` (clears to dark), `drawTurtle(tx, ty)` (draws a triangle pointing in the turtle's current direction), `drawHelp()`, and `drawDebuginfo()`. The turtle trail is drawn to the virtual canvas via `gfx.*` calls in the action functions — so trails persist across frames without a redraw loop.

## Points of attention

- The `r` variable (user_input handle) is reassigned inside `love.keyreleased` (`r = input_text("TURTLE")`). This means after pressing `i`, the old handle is abandoned and a new overlay is created. The polling in `love.update` starts consuming the new handle. This pattern works but relies on the variable being captured by reference in the update closure — which it is, since both closures close over the upvalue `r`.
- `debug_color` is set in `love.update` based on turtle position — this modifies a global used by `drawDebuginfo`. The debug overlay is toggled by `space`.

## Files

`src/examples/turtle/` — main.lua, action.lua, drawing.lua
