# balloons

<!-- authored By LLM; human-approved NOT YET -->

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

Uses `compy.input.*` **(supported since 1.0.0-rc20260712)**, wrapped by `terminal.lua`'s `terminal_init()` (called once, at `ui.lua` require-time, to build `ui.terminal`). The current project-local balloons source is untracked scratch, so this narrative records the supported shape: `compy.input.show({ on_text_entered = deliver })` starts the session, and nothing else is configured: the project widget clears on submit and does nothing on Escape by default, which is exactly what a command line shown once with no re-show path needs (`../../decisions/input.md`, D-LIFECYCLE-FLAGS, *"the least-destructive basis"*). It carried an `after_submit` that cleared by hand until 2026-09-09, when the seated default made it redundant. `deliver(text)` forwards each submission to whatever handler `terminal_set_handler(handler)` last installed. It takes the text as one string (D-ONE-PAYLOAD, and D-PAYLOAD-SPLIT before it); before either, it joined the line list itself, which is what the handlers have always wanted. Live prompt changes go through `ui_draw_hint()` → `ui.terminal.write(hint)` → `terminal_write(msg)` → `compy.input.configure({ prompt = msg })` — a live reconfigure, not a new `show`.

See [Compy Input API](../../../input_api.md) for the general usage pattern. The old `user_input()`/`input_text()` polling API is **(deprecated, removed in 1.0.0-rc20260712)**.

## Points of attention

- **This project carries more input machinery than it now needs, and that is
  left as it is on purpose.** `terminal.lua` builds a small abstraction layer
  over `compy.input` — it was written against the pre-feature polling API, where
  combating that complexity in the project was the only option. The current API
  would let the same job be done in a single `on_text_entered`
  (clear / configure / deliver together), so the layer is no longer earning its
  keep. **It is not being reworked**: this feature makes focused updates and does
  not refactor projects that work. Recorded so a reader does not mistake the
  wrapper for a recommended pattern — [Compy Input API](../../../input_api.md)
  is the pattern.
- `game_state` doubles as both game FSM state and the dispatch key for `on_tick` / `on_input` maps. Adding a new game phase requires entries in both maps.
- The `hooks.update` function is a closure that holds both the state updater and the input reader — be careful if extracting these.
- `sfx.gameover()` / `sfx.correct()` etc. come from `compy.audio`.

## Files

`src/examples/balloons/` — main.lua, config.lua, challenges.lua, stats.lua, ui.lua, helpers.lua, debugfunc.lua, colors.lua, parameters.lua, tasks.lua, terminal.lua
