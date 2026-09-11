# sapper

<!-- authored By LLM; human-approved NOT YET -->

**Minesweeper** implemented entirely in pen-and-paper mode. The board is drawn once at init and updated incrementally on each user action.

## Architecture

Single large file (~700 lines). No `love.draw` or `love.update` override. All game logic runs in the `compy.input.hooks.singleclick` / `.doubleclick` handlers and in `love.mousepressed`, which carries the modifier-held variants (see "Click handling"). The terminal output is never used.

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

`compy.input.hooks.singleclick` → flag cell. `compy.input.hooks.doubleclick` → unlock cell (or restart if game over). Both act only when **nothing is held**. `love.mousepressed` carries the modifier-held variants: Shift+press flags, Ctrl+press unlocks, each guarded as *this modifier and none of the other two*.

**Why the press path exists** (from the example's author, recorded 2026-08-10 because it is not in the code and its absence has already caused one wrong change): **on touch devices a single tap is often accidental and a double tap unreliable**, so the modifier-held *press* is the dependable route to both actions. That makes its timing the point, not an accident — it acts on any button, at press time, immediately.

**This shape looks like a cascade the framework could express, and converting it is not as simple as it looks.** The four guards do spell out what a class key already means — `combo_string` folds every held modifier, so `'shift+*'` matches Shift and nothing else — but the obvious conversion moves the modified actions onto the **derived** single-click channel, which is button 1 only, counted on release, resolved only after the double-click window, and **discarded if the pointer drifts between presses**. That is the exact mechanism the press path exists to bypass, and a finger drifts. A conversion on those lines was made and **reverted** on 2026-08-10.

A correct conversion keeps the press path and stops the derived echo, and the register records both it and the hole that remains — `technical_debt/input.md`, "sapper's modifier click path is a touch fallback, and converting it needs the platform's help".

Mine placement uses probabilistic streaming: iterate all mineable positions once, at each position place a mine with probability `mines_remaining / cells_remaining`. No shuffle needed.

## Files

`src/examples/sapper/main.lua`
