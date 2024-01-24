require("util.string")
require("util.key")

local get_user_input = function()
  return love.state.user_input
end

Controller = {
  _defaults = {},
  ----------------
  --  keyboard  --
  ----------------

  --- @param C ConsoleController
  set_love_keypressed = function(C)
    local function keypressed(k)
      C:keypressed(k)
    end
    Controller._defaults.keypressed = keypressed
    love.keypressed = keypressed
  end,
  --- @param C ConsoleController
  set_love_keyreleased = function(C)
    --- @diagnostic disable-next-line: duplicate-set-field
    local function keyreleased(k)
      -- Ctrl held
      if Key.ctrl() then
        if k == "escape" then
          love.event.quit()
        end
      end
      C:keyreleased(k)
    end
    Controller._defaults.keyreleased = keyreleased
    love.keyreleased = keyreleased
  end,
  --- @param C ConsoleController
  set_love_textinput = function(C)
    local function textinput(t)
      C.input:textinput(t)
    end
    Controller._defaults.textinput = textinput
    love.textinput = textinput
  end,

  -------------
  --  mouse  --
  -------------

  --- @param C ConsoleController
  set_love_mousepressed = function(C)
    local function mousepressed(x, y, button)
      C.input:mousepressed(x, y, button)
    end

    Controller._defaults.mousepressed = mousepressed
    love.mousepressed = mousepressed
  end,
  --- @param C ConsoleController
  set_love_mousereleased = function(C)
    local function mousereleased(x, y, button)
      C.input:mousereleased(x, y, button)
    end

    Controller._defaults.mousereleased = mousereleased
    love.mousereleased = mousereleased
  end,
  --- @param C ConsoleController
  set_love_mousemoved = function(C)
    local function mousemoved(x, y, dx, dy)
      C.input:mousemoved(x, y)
    end

    Controller._defaults.mousemoved = mousemoved
    love.mousemoved = mousemoved
  end,

  --------------
  --  update  --
  --------------

  --- @param C ConsoleController
  set_love_update = function(C)
    local function update(dt)
      local ddr = View.prev_draw
      local ldr = love.draw
      if ldr ~= ddr then
        local function draw()
          if ldr then ldr() end
          local user_input = get_user_input()
          if user_input then
            user_input.V:draw(user_input.C:get_input())
          end
        end
        View.prev_draw = draw
        love.draw = draw
      end
      C:pass_time(dt)
    end

    Controller._defaults.update = update
    love.update = update
  end,



  ---------------
  --  setters  --
  ---------------

  --- @param C ConsoleController
  set_default_handlers = function(C)
    Controller.set_love_keypressed(C)
    Controller.set_love_keyreleased(C)
    Controller.set_love_textinput(C)
    -- SKIPPED textedited - IME support, TODO?

    Controller.set_love_mousemoved(C)
    Controller.set_love_mousepressed(C)
    Controller.set_love_mousereleased(C)
    -- SKIPPED wheelmoved - TODO

    -- SKIPPED touchpressed  - target device doesn't support touch
    -- SKIPPED touchreleased - target device doesn't support touch
    -- SKIPPED touchmoved    - target device doesn't support touch

    -- SKIPPED joystick and gamepad support

    -- SKIPPED focus       - intented to run as kiosk app
    -- SKIPPED mousefocus  - intented to run as kiosk app
    -- SKIPPED visible     - intented to run as kiosk app

    -- SKIPPED quit        - intented to run as kiosk app - TODO
    -- SKIPPED threaderror - no threading support

    -- SKIPPED resize           - intented to run as kiosk app
    -- SKIPPED filedropped      - intented to run as kiosk app
    -- SKIPPED directorydropped - intented to run as kiosk app
    -- SKIPPED lowmemory
    -- SKIPPED displayrotated   - target device has laptop form factor

    Controller.set_love_update(C)
  end,

  --- @param C ConsoleController
  setup_callback_handlers = function(C)
    local clear_user_input = function()
      love.state.user_input = nil
    end

    --- @diagnostic disable-next-line: undefined-field
    local handlers = love.handlers

    handlers.keypressed = function(k)
      if Key.ctrl() then
        if k == "pause" then
          C:suspend_run()
        end
        if Key.shift() then
          -- Ensure the user can get back to the console
          if k == "q" then
            C:quit_project()
          end
        end
      end

      local user_input = get_user_input()
      if user_input then
        user_input.C:keypressed(k)
      else
        if love.keypressed then return love.keypressed(k) end
      end
    end

    handlers.textinput = function(t)
      local user_input = get_user_input()
      if user_input then
        user_input.C:textinput(t)
      else
        if love.textinput then return love.textinput(t) end
      end
    end

    handlers.keyreleased = function(k)
      local user_input = get_user_input()
      if user_input then
        user_input.C:keyreleased(k)
      else
        if love.keyreleased then return love.keyreleased(k) end
      end
    end

    handlers.mousepressed = function(x, y, btn)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousepressed(x, y, btn)
      else
        if love.mousepressed then return love.mousepressed(x, y, btn) end
      end
    end

    handlers.mousereleased = function(x, y, btn)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousereleased(x, y, btn)
      else
        if love.mousereleased then return love.mousereleased(x, y, btn) end
      end
    end

    handlers.mousemoved = function(x, y, dx, dy)
      local user_input = get_user_input()
      if user_input then
        user_input.C:mousemoved(x, y, dx, dy)
      else
        if love.mousemoved then return love.mousemoved(x, y, dx, dy) end
      end
    end

    handlers.userinput = function(input)
      local user_input = get_user_input()
      if user_input then
        clear_user_input()
      end
    end

    --- @diagnostic disable-next-line: undefined-field
    table.protect(love.handlers)
  end
}
