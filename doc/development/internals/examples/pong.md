# pong

**Full Pong game** with two AI difficulty levels, two-player keyboard mode, fixed-timestep physics, and mouse control for the player paddle.

## Architecture

Multi-file: `main.lua` (game logic, rendering, input), `strategy.lua` (AI behaviors), `constants.lua` (game parameters).

Overrides `love.draw`, `love.update`, `love.keypressed`, `love.mousemoved`, `love.resize`.

## Virtual resolution

Game logic runs in a 640×480 virtual space. A `love.math.newTransform` (`view_tf`) scales from virtual to screen coordinates. `love.draw` applies the transform with `gfx.applyTransform(view_tf)`, so all draw calls use virtual coordinates internally. `love.resize` rebuilds the transform. This decouples physics from screen resolution.

## Fixed timestep

`USE_FIXED = true` enables fixed-timestep update via `update_fixed()`:

```lua
acc = acc + rdt
while FIXED_DT <= acc and steps < MAX_STEPS do
  step_game(FIXED_DT)
  acc = acc - FIXED_DT
  steps = steps + 1
end
```

`MAX_STEPS = 5` caps the catch-up loop so a single slow frame doesn't spiral. This is the standard fixed-timestep pattern; the example demonstrates it explicitly as a teaching artifact.

## Strategy pattern

`S.strategy.fn` holds the active AI function. Three strategies in `strategy.lua`: `easy` (slower tracking), `hard` (full speed), `manual` (second-player keyboard). Swapped at the start screen. The function signature `strategy.fn(S, dt)` receives the full game state — strategies have full read/write access, so the easy/hard split is purely in `move_paddle` call parameters, not state access.

## State machine

`S.state` (`"start"`, `"play"`, `"gameover"`) drives `key_actions` dispatch:

```lua
key_actions = { start = {...}, play = {...}, gameover = {...} }
function love.keypressed(k)
  local group = key_actions[S.state]
  if group and group[k] then group[k]() end
end
```

Clean dispatch without conditionals. Escape → quit is added to all states via a loop.

## Mouse control

`love.mouse.setRelativeMode(true)` during play — mouse is captured and `dy` accumulates to move the paddle. This avoids absolute positioning, which is non-trivial with variable-resolution scaling.

## Points of attention

- `gfx.newText` objects are cached in `texts` and reused — avoids per-frame text object allocation.
- `build_center_canvas()` draws the center dividing line to a dedicated canvas once; re-drawn only on `love.resize`. Good GC pattern.
- `do_init()` is deferred to the first `update()` call (via `ensure_init()`) because some LÖVE2D state (font, canvas) may not be ready at module load time in all contexts.

## Files

`src/examples/pong/` — main.lua, strategy.lua, constants.lua
