require("model/consoleModel")
require("view/consoleView")
require("controller/consoleController")

require("util/debug")

local G = love.graphics
local V

local function set_print()
  local origPrint = _G.print
  _G.orig_print = origPrint
  local magicPrint = function(...)
    local arg = { ... }
    if type(arg) == 'string' then
      origPrint('s', arg)
      M.output:push({ arg })
    end
    if type(arg) == 'table' then
      -- origPrint('t', string.join(arg, '\t'))
      for _, v in ipairs(arg) do
        origPrint(v)
      end
      M.output:push(arg)
    end
  end
  _G.print = magicPrint
end

function love.load(args)
  local testrun = false
  for _, a in ipairs(args) do
    if a == '--test' then testrun = true end
  end

  local FAC = 1
  if love.hiDPI then FAC = 2 end
  local font_size = 32 * FAC
  local border = 2 * FAC

  local font_dir = "assets/fonts/"
  local font_main = love.graphics.newFont(
    font_dir .. "ubuntu_mono_bold_nerd.ttf", font_size)
  local font_title = love.graphics.newFont(
    font_dir .. "PressStart2P-Regular.ttf", font_size)
  local fh = font_main:getHeight()
  -- we use a monospace font, so the width should be the same for any input
  local fw = font_main:getWidth('█')
  local w = G.getWidth() - 2 * border
  local h = G.getHeight() + fh
  local debugheight = 6
  local debugwidth = math.floor(debugheight * (80 / 25))
  local drawableWidth = w - 2 * border
  if testrun then
    drawableWidth = debugwidth * fw
  end

  love.keyboard.setTextInput(true)
  love.keyboard.setKeyRepeat(true)
  if love.system.getOS() == 'Android' then
    love.isAndroid = true
    love.window.setMode(w, h, {
      fullscreen = true,
      fullscreentype = "exclusive",
    })
  end

  -- properties
  local baseconf = {
    font_main = font_main,
    border = border,
    fh = fh,
    fw = fw,
    fac = FAC,
    w = w,
    h = h,
    get_drawable_height = function()
      return
          h - border -- top border
          - border   -- statusline border
          - fh       -- statusline
          - border   -- statusline bottom border
          - fh       -- input line
          - border   -- bottom border
    end,
    colors = {
      border = Color[Color.black + Color.bright],
      debug = Color[Color.yellow],
      terminal = {
        fg = Color[Color.white + Color.bright],
        bg = Color[Color.blue],
      },
      input = {
        bg = Color[Color.white],
        fg = Color[Color.blue + Color.bright],
        cursor = Color[Color.white + Color.bright],
      },
      statusline = {
        fg = Color[Color.white + Color.bright],
        bg = Color[Color.black],
        indicator = Color[Color.cyan + Color.bright],
      },
    },

    debugheight = debugheight,
    debugwidth = debugwidth,
    drawableWidth = drawableWidth,
    drawableChars = math.floor(drawableWidth / fw),
    testrun = testrun,
  }

  love.state = {
    testing = false
  }
  love.window.aspect = G.getWidth() / G.getHeight()

  M = Console:new(baseconf)
  C = ConsoleController:new(M, testrun)
  V = ConsoleView:new(baseconf, C)

  set_print()

  if testrun then
    C:autotest()
  end
end

function love.textinput(t)
  C:textinput(t)
end

function love.keypressed(k)
  C:keypressed(k)
end

function love.keyreleased(k)
  local ctrl = love.keyboard.isDown("lctrl", "rctrl")
  -- Ctrl held
  if ctrl then
    if k == "escape" then
      love.event.quit()
    end
  end
end

function love.update(dt)
  C:pass_time(dt)
end

function love.draw()
  V:draw()
end
