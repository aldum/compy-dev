# sine

<!-- authored By LLM; human-approved NOT YET -->

**One-shot sine wave plot.** Draws axes and a sine curve at startup using `gfx.points`. No update loop, no input.

## Code pattern

```lua
local points = {}
for x = 0, xe do
  local v = 2 * math.pi * (x - xh) / xe
  local y = yh - math.sin(v * times) * amp
  table.insert(points, x)
  table.insert(points, y)
end
gfx.points(points)
```

Everything runs at the top level of `main.lua` — no function definitions, no handlers. This is the simplest possible example of pen-and-paper mode: code runs once, draws once, is done.

## Purpose

Demonstrates:
1. That project code executes at the top level and its output persists on the virtual canvas without any draw loop.
2. `gfx.points` for efficient point cloud rendering.
3. Basic coordinate math for a centered normalized plot.

`gfx.setColor(1, 0, 0)` and `gfx.setPointSize(2)` affect subsequent draw calls — the axes are drawn first in white with `setLineWidth(1)`, then the point color is changed to red.

## Files

`src/examples/sine/main.lua`
