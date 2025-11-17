
-- main.lua — Compy-style glue (global Board, no setMode)

local G = love and love.graphics or nil

-- Load board; board.lua sets _G.Board
require("board")

-- Create game board (rows, cols)
board = Board.new(4, 4)

-- Keyboard input: arrows/WASD, R restart, Esc quit
function love.keypressed(key)
  local map = {
    left="left", right="right", up="up", down="down",
    a="left", d="right", w="up", s="down",
  }
  if key == "escape" and love and love.event and love.event.quit then
    love.event.quit()
    return
  end
  local dir = map[key]
  if dir then
    if board:move(dir) then board:add_random_tile() end
  elseif key == "r" then
    board:seed()
  end
end

-- Draw board and a tiny HUD
function love.draw()
  if not G then return end
  board:draw(40, 80, 80)
  G.setColor(0.2, 0.2, 0.2)
  G.print("ESC quit | R restart", 110, 30)
  if board:isGameOver() then
    G.setColor(1, 0, 0)
    G.print("GAME OVER!", 140, 440, 0, 2, 2)
  end
end
