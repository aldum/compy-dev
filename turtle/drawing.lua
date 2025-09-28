local G = love.graphics

-- Colors and font are kept global for simplicity.
font = G.newFont()
bg_color = Color.black
body_color = Color.green
limb_color = body_color + Color.bright
debug_color = Color.yellow

function drawBackground(color)
  -- Pick a safe background that is not the body / limb color.
  local c = bg_color
  local not_green = color ~= body_color and color ~= limb_color
  local color_valid = Color.valid(color) and not_green
  if color_valid then
    c = color
  end
  G.setColor(Color[c])
  G.rectangle("fill", 0, 0, width, height)
end

function drawFrontLegs(x_r, y_r, leg_xr, leg_yr)
  G.setColor(Color[limb_color])
  -- left front
  G.push("all")
  G.translate(-x_r, -y_r / 2 - leg_xr)
  G.rotate(-math.pi / 4)
  G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
  G.pop()
  -- right front
  G.push("all")
  G.translate(x_r, -y_r / 2 - leg_xr)
  G.rotate(math.pi / 4)
  G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
  G.pop()
end

function drawHindLegs(x_r, y_r, leg_r, leg_yr)
  G.setColor(Color[limb_color])
  -- left hind
  G.push("all")
  G.translate(-x_r, y_r / 2 + leg_r)
  G.rotate(math.pi / 4)
  G.ellipse("fill", 0, 0, leg_r, leg_yr, 100)
  G.pop()
  -- right hind
  G.push("all")
  G.translate(x_r, y_r / 2 + leg_r)
  G.rotate(-math.pi / 4)
  G.ellipse("fill", 0, 0, leg_r, leg_yr, 100)
  G.pop()
end

function drawBody(x_r, y_r, head_r)
  -- body
  G.setColor(Color[body_color])
  G.ellipse("fill", 0, 0, x_r, y_r, 100)
  -- head (placed in turtle coordinates)
  local neck = 5
  local hy = ((0 - y_r) - head_r) + neck
  G.circle("fill", 0, hy, head_r, 100)
end

function drawTurtle(x, y)
  -- Compact param block for readability.
  local head_r = 8
  local leg_xr = 5
  local leg_yr = 10
  local x_r = 15
  local y_r = 20

  G.push("all")
  G.translate(x, y)
  drawFrontLegs(x_r, y_r, leg_xr, leg_yr)
  drawHindLegs(x_r, y_r, leg_xr, leg_yr)
  drawBody(x_r, y_r, head_r)
  G.pop()
end

function drawHelp()
  G.setColor(Color[Color.white])
  G.print("Press [I] to open console", 20, 20)
  G.print("Type: forward/back/left/right (or fd/b/l/r)", 20, 50)
end

function drawDebuginfo()
  G.setColor(Color[debug_color])
  local dt = string.format("Turtle: (%d, %d)", tx, ty)
  G.print(dt, width - 160, 20)
end

function drawPauseOverlay()
  if not is_paused then return end
  G.push("all")
  G.setColor(0, 0, 0, 0.5)
  G.rectangle("fill", 0, 0, width, height)
  G.setColor(Color[Color.white])
  G.print("PAUSED", 20, 80)
  if pause_message then
    G.print(pause_message, 20, 110)
  end
  G.pop()
end
