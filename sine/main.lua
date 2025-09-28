-- Sinusoid with cross axes (Compy formatting)

local G = love.graphics

-- Draw horizontal and vertical axes
local function draw_axes(cx, cy, w, h)
  G.setColor(1, 1, 1, 0.5)
  G.setLineWidth(1)
  G.line(cx, 0, cx, h)
  G.line(0, cy, w, cy)
end

-- Build points for sine wave
local function build_points(cx, cy, w, amp)
  local pts = {}
  local tau = 2 * math.pi
  local cycles = 2
  for x = 0, w do
    local dx = x - cx
    local v = tau * dx / w
    local s = math.sin(v * cycles)
    local y = cy - s * amp
    pts[#pts + 1] = x
    pts[#pts + 1] = y
  end
  return pts
end

-- Draw the points in red
local function draw_points(pts)
  G.setColor(1, 0, 0)
  G.setPointSize(2)
  G.points(pts)
end

-- Main entry
function love.draw()
  local w = G.getWidth()
  local h = G.getHeight()
  local cx = w / 2
  local cy = h / 2
  draw_axes(cx, cy, w, h)
  local pts = build_points(cx, cy, w, 100)
  draw_points(pts)
end
