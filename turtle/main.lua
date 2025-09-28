--- @diagnostic disable: duplicate-set-field,lowercase-global
-- Entry point: wires input, drawing, and update loop.

require("action")
require("drawing")

width, height = love.graphics.getDimensions()
midx, midy = width / 2, height / 2
incr = 10

tx, ty = midx, midy
debug = false
is_paused = false
pause_message = nil

-- Console input handle
local r = user_input()

-- Evaluate one console command against the actions map.
function eval(input)
  local f = actions[input]
  if f then f() end
end

function love.draw()
  G.setFont(font)
  drawBackground()
  drawHelp()
  drawTurtle(tx, ty)
  if debug then drawDebuginfo() end
  drawPauseOverlay()
end

function love.keypressed(key)
  -- Shift+R to reset turtle to center.
  if love.keyboard.isDown("lshift", "rshift") then
    if key == "r" then tx, ty = midx, midy end
  end
  if key == "space" then
    debug = not debug
  end
  if key == "pause" then
    togglePause("toggled by keyboard")
  end
end

function love.keyreleased(key)
  -- Open console with a title
  if key == "i" then
    r = input_text("TURTLE")
  end
  -- Ctrl+Esc to quit
  if love.keyboard.isDown("lctrl", "rctrl") then
    if key == "escape" then love.event.quit() end
  end
end

function love.update()
  -- Early exit when paused: no state changes.
  if is_paused then return end

  -- Tiny example of dynamic debug color.
  if ty > midy then debug_color = Color.red end

  -- Pull and run queued console command.
  if not r:is_empty() then
    eval(r())
  end
end
