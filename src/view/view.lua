local gfx = love.graphics

local FPSfont = gfx.newFont("assets/fonts/fraps.otf", 24)

View = {
  --- @type love.Image?
  snapshot = nil,
  prev_draw = nil,
  main_draw = nil,
  end_draw = nil,
  --- @param C ConsoleController
  --- @param CV ConsoleView
  draw = function(C, CV)
    gfx.push('all')
    local terminal = C:get_terminal()
    local canvas = C:get_canvas()
    local input = C.input:get_input()
    CV:draw(terminal, canvas, input, View.snapshot)
    gfx.pop()
  end,

  clear_snapshot = function()
    View.snapshot = nil
  end,

  drawFPS = function()
    local pr = love.PROFILE
    if type(pr) ~= 'table' then return end
    if love.PROFILE.fpsc == 'off' then return end

    local fps = tostring(love.timer.getFPS())
    local w = FPSfont:getWidth(fps)
    local x
    if love.PROFILE.fpsc == 'T_L' then
      x = 10
    elseif love.PROFILE.fpsc == 'T_R' then
      x = gfx.getWidth() - 10 - w
    end
    gfx.push('all')
    gfx.setColor(Color[Color.yellow])
    gfx.setFont(FPSfont)
    gfx.print(fps, x, 10)
    gfx.pop()
  end
}

--- @class ViewBase
--- @field cfg ViewConfig
--- @field draw function
