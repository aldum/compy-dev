# balloons

**Real-time typing game.** Balloons carrying words fall from the top of the screen; the player types the words to pop them before they reach the bottom.

## Architecture

Multi-file project (`config`, `challenges`, `stats`, `ui`, `helpers`). `main.lua` is thin orchestration — it wires together `love.draw` and `love.update` via hook tables.

```lua
hooks.draw = game_state_router(ui_renderers)
love.draw = hooks["draw"]
love.update = hook("update")
```

The state router pattern (`game_state_router`) dispatches draw/update calls to different handlers depending on `game_state` (`"loaded"`, `"active"`, `"finished"`). This avoids conditionals inside the per-frame functions themselves.

## Input

Uses `user_input()` overlay. On each `update()`, if no pending input, `ui_read_input(input_handler)` is called which calls `input_text()` to show the overlay. When the user submits, the result is routed to `game_validate_input` which checks it against the active challenge.

## Points of attention

- `game_state` doubles as both game FSM state and the dispatch key for `on_tick` / `on_input` maps. Adding a new game phase requires entries in both maps.
- The `hooks.update` function is a closure that holds both the state updater and the input reader — be careful if extracting these.
- `sfx.gameover()` / `sfx.correct()` etc. come from `compy.audio`.

## Files

`src/examples/balloons/` — main.lua, config.lua, challenges.lua, stats.lua, ui.lua, helpers.lua, debugfunc.lua, colors.lua, parameters.lua, tasks.lua, terminal.lua
