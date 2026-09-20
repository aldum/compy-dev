-- Keypress-level driver. Every emitter fires a REAL event
-- through the production gateway (love.handlers.*), never
-- straight to a controller, so a test walks the path a
-- keystroke takes from LÖVE.

require('controller.controller')

local mock = require('tests.mock')

-- One emitter per gateway entry: the controllable stand-in for
-- the events hardware would raise. `handlers` is the live
-- table, so combo drivers (tests.mock.keystroke) can hold
-- modifiers and call .keypressed directly.
local function emitters()
  local h = love.handlers
  return {
    press         = function(k)
      mock.hold(k); h.keypressed(k, '', false)
    end,
    repeat_press  = function(k)
      mock.hold(k); h.keypressed(k, '', true)
    end,
    release       = function(k)
      mock.unhold(k); h.keyreleased(k, '')
    end,
    type          = function(t) h.textinput(t) end,
    mousepressed  = function(...) h.mousepressed(...) end,
    mousereleased = function(...) h.mousereleased(...) end,
    mousemoved    = function(...) h.mousemoved(...) end,
    wheelmoved    = function(...) h.wheelmoved(...) end,
    touchpressed  = function(...) h.touchpressed(...) end,
    handlers      = h,
  }
end

-- Run the production wiring (the `setup_callback_handlers` call
-- main.lua makes) onto a fresh love.handlers, and return the
-- emitters. Call AFTER mock.mock_love() and the view.view stub.
--- @param CC ConsoleController?  read for cfg + shortcuts; the
--- default lets a bare driver stand up without one
local function new(CC)
  love.handlers = { }
  Controller.setup_callback_handlers(
    CC or { cfg = { mode = 'dev' } }
  )
  return emitters()
end

return { new = new }
