# life

<!-- authored By LLM; human-approved NOT YET -->

**Conway's Game of Life.** Full real-time simulation with keyboard and mouse controls, speed adjustment, and random initialization.

## Architecture

Single-file. Overrides `love.draw`, `love.update`, `love.keypressed`, `love.mousepressed`, `love.mousereleased`. Classic real-time draw mode.

## Grid

`grid[x][y]` — 2D table, 1-indexed, sized to fill the screen in 10×10 pixel cells. Each cell is 0 or 1. On each `tick()` (when accumulated time exceeds `1/speed`), a new grid is computed from neighbor counts and replaces the old one.

## Speed control

Two mechanisms:
- Keyboard `+`/`-` increment/decrement `speed` (1–99)
- Mouse gesture: `mousereleased` checks `hold_time` (how long the button was held) and `dy` (drag distance). Long press → reinitialize. Short drag up/down → change speed by the drag amount.

## Memory note

`updateGrid()` allocates a fresh `newGrid` table every tick. This is the main GC pressure point in the example. Acceptable at tick rates of ~10/s but worth noting as a teaching point about the tradeoff between clarity and allocation.

## Files

`src/examples/life/main.lua`
