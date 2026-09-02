# Drawing System

## Two Modes

User projects can draw in one of two ways, selected by whether `love.draw` is overridden.

### Pen-and-paper mode (default)

Project code calls `gfx.*` primitives imperatively — in response to events (clicks, input) or at startup. There is no per-frame redraw loop. The framework composites everything on each frame regardless, but the virtual canvas only changes when the project explicitly draws to it, so unchanged content persists for free.

**Example:** `src/examples/sapper` — all drawing happens in click handlers (`drawCellLocked`, `drawCellFlagged`, etc.). The board is drawn once at setup and partially updated on each user action.

### Real-time draw mode

Project sets `love.draw` directly. The framework detects this on the next `update()` tick, wraps the user draw in `gfx.push/pop` + error handling, and appends the UI overlay (user input widget if active). The framework console UI is bypassed.

**Example:** `src/examples/balloons` — sets `love.draw = hooks["draw"]` and `love.update = hook("update")` in `game_init()`.

---

## How It Works

### Virtual canvas

`CanvasModel` holds a `love.Canvas` (`model.output.canvas`) that serves as the drawing surface for all user project code. It is composited over the terminal by `CanvasView:draw()` during the framework's render pass (`src/view/canvas/canvasView.lua`).

### `use_canvas(f)` — `src/controller/consoleController.lua:1159`

```lua
function ConsoleController:use_canvas(f)
  gfx.setCanvas({ canvas, stencil = true })
  local r = f()
  gfx.setCanvas()
  return r
end
```

All user event handlers are wrapped in `wrap_handler` (`consoleController.lua:202`), which calls `use_canvas` internally. User `love.update` is also run inside `use_canvas` (see `controller.lua`, `set_love_update`). This means any `gfx.*` calls in event handlers or update automatically go to the virtual canvas, not the screen.

### User `love.draw` detection — `src/controller/controller.lua`, `set_love_update`

On each frame's `update()`, the framework compares `love.draw` against its last known value (`View.prev_draw`). If they differ, it replaces `love.draw` with a wrapper:

```lua
local draw = function()
  gfx.push('all')
  wrap(ldr, CC)        -- user draw, error-handled
  gfx.pop()
  -- append UI overlay if user input widget is active
  local ui = get_user_input()
  if ui then ui.V:draw() end
end
love.draw = draw
View.prev_draw = draw
```

The framework console UI is not drawn in this path; only the user draw and the optional UI overlay.

### Framework's default `love.draw` — `src/view/view.lua`, `src/controller/controller.lua:set_love_draw`

Calls `View.draw(CC, CV)` which renders: background → terminal → virtual canvas, in blend-mode layers. The virtual canvas is drawn with `gfx.draw(canvas)` as a single texture blit per frame.

---

## Summary

| | Pen-and-paper | Real-time |
|---|---|---|
| Draw trigger | Event / explicit call | Every frame (`love.draw`) |
| Draws to | Virtual canvas (via `use_canvas`) | Screen directly (framework wraps it) |
| Framework UI | Composited on top | Bypassed; UI overlay appended separately |
| GC / CPU cost | Low — canvas persists | Per-frame cost, project's responsibility |
| Suitable for | Board games, static visuals | Animations, physics, continuous updates |
