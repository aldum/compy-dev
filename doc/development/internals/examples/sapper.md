# sapper

**Minesweeper** implemented entirely in pen-and-paper mode. The board is drawn once at init and updated incrementally on each user action.

## Architecture

Single large file (~700 lines). No `love.draw` or `love.update` override. All game logic runs in `compy.singleclick` / `compy.doubleclick` handlers and `love.mousepressed` (for modifier-key variants). The terminal output is never used.

## Draw model

Drawing is event-driven: click a cell → the cell's appearance is redrawn in place. The full board is only redrawn on `actionInit()` (new game) and mode changes. Individual cell functions (`drawCellLocked`, `drawCellFlagged`, `drawCellUnlocked`, `drawCellBlown`, `drawCellExposed`) draw directly to the virtual canvas. The status panel is redrawn on every state change via `redrawStatus`.

This is a clean illustration of pen-and-paper mode: no wasted per-frame work, canvas retains state.

## Iterator pattern

Cell traversal uses closure iterators throughout:

```lua
function all_cells()
  local row, col = 1, 0
  return function()
    col = col + 1
    if config.cols < col then col = 1; row = row + 1 end
    if config.rows < row then return nil end
    return col, row
  end
end
```

`cell_filter(iterator, predicate)` wraps any iterator with a filter. `neighbors(i,j)`, `unlockable_neighbors(i,j)`, `all_mined_cells()` are all composed from these. No intermediate tables — pure iterator chaining. Good functional Lua pattern for students.

## Click handling

`compy.singleclick` → flag cell. `compy.doubleclick` → unlock cell (or restart if game over). `love.mousepressed` → same actions when shift/ctrl held (alternative input for touch devices without double-click).

Mine placement uses probabilistic streaming: iterate all mineable positions once, at each position place a mine with probability `mines_remaining / cells_remaining`. No shuffle needed.

## Files

`src/examples/sapper/main.lua`
