--- @diagnostic disable: duplicate-set-field,lowercase-global

-- Expect global G = love.graphics and Color table to exist.

--========================
-- Screen / palette sizes
--========================
width, height = G.getDimensions()

block_w = width / 10
block_h = block_w / 2
pal_h = 2 * block_h
pal_w = 8 * block_w
sel_w = 2 * block_w

--=============
-- Tool sidebar
--=============
margin = block_h / 10
m_2 = margin * 2
m_4 = margin * 4
box_w = 1.5 * block_w
box_h = height - pal_h
marg_l = box_w - m_2
tool_h = box_h / 2
tool_midx = box_w / 2

n_t = 2
icon_h = (tool_h - m_4 - m_2) / n_t
icon_w = (box_w - m_4 - m_4)
icon_d = math.min(icon_w, icon_h)

weight_h = box_h / 2
wb_y = box_h - weight_h
weights = { 1, 2, 4, 5, 6, 9, 11, 13 }

--========
-- Canvas
--========
can_w = width - box_w
can_h = height - pal_h - 1
canvas = G.newCanvas(can_w, can_h)

--=============
-- Selections
--=============
color = 0      
bg_color = 0   
weight = 3     
tool = 1   

--========================
-- Small math/helper utils
--========================
local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function mid(a, b)
  return (a + b) / 2
end

--=================
-- Hit-test helpers
--=================
function inCanvasRange(x, y)
  local below_pal = (y < height - pal_h)
  local right_side = (x > box_w)
  return below_pal and right_side
end

function inPaletteRange(x, y)
  local in_y = (y >= height - pal_h)
  local in_x = (x >= width - pal_w and x <= width)
  return in_y and in_x
end

function inToolRange(x, y)
  return (x <= box_w and y <= tool_h)
end

function inWeightRange(x, y)
  local in_x = (x <= box_w)
  local in_y = (y < height - pal_h and y > wb_y)
  return in_x and in_y
end

--=================
-- Background layer
--=================
function drawBackground()
  G.setColor(Color[Color.black])
  G.rectangle("fill", 0, 0, width, height)
end

--=============
-- Color bar UI
--=============
local function paletteFill(x, y, w, h)
  G.rectangle("fill", x, y, w, h)
end

local function paletteLine(x, y, w, h)
  G.rectangle("line", x, y, w, h)
end

local function drawPaletteOutline(y)
  G.setColor(Color[bg_color])
  paletteFill(0, y - block_h, block_w * 2, block_h * 2)

  G.setColor(Color[Color.white])
  paletteLine(0, y - block_h, sel_w, pal_h)
  paletteLine(sel_w, y - block_h, width, pal_h)
end

local function drawSelectedColor(y)
  local bx = block_w / 2
  local by = y - (block_h / 2)
  G.setColor(Color[color])
  paletteFill(bx, by, block_w, block_h)

  local lc = Color.white + Color.bright
  if color == lc then lc = Color.black end
  G.setColor(Color[lc])
  paletteLine(bx, by, block_w, block_h)
end

local function drawColorCell(x, y, c, top)
  local yy = top and (y - block_h) or y
  local ci = top and (c + 8) or c
  G.setColor(Color[ci])
  paletteFill(x, yy, width, block_h)
  G.setColor(Color[Color.white])
  paletteLine(x, yy, width, block_h)
end

local function drawColorBoxes(y)
  for c = 0, 7 do
    local x = block_w * (c + 2)
    drawColorCell(x, y, c, false)
    drawColorCell(x, y, c, true)
  end
end

function drawColorPalette()
  local y = height - block_h
  drawPaletteOutline(y)
  drawSelectedColor(y)
  drawColorBoxes(y)
end

--=================
-- Tool icons (UI)
--=================
local function drawBrushHandle()
  G.setColor(0.6, 0.4, 0.2)
  G.rectangle("fill", -8, -80, 16, 60)
  G.setColor(0.8, 0.6, 0.4)
  G.rectangle("fill", -6, -75, 3, 50)
end

local function drawBrushFerrule()
  G.setColor(0.7, 0.7, 0.8)
  G.rectangle("fill", -10, -25, 20, 12)
  G.setColor(0.9, 0.9, 1.0)
  G.rectangle("fill", -8, -24, 3, 10)
end

local function drawBrushBristles()
  G.setColor(0.2, 0.2, 0.2)
  G.rectangle("fill", -12, -13, 24, 25)
end

local function drawBrushTip()
  local c = love.math.newBezierCurve(
    -12, 12, -15, 20, -5, 30, 0, 35,
     5, 30,  15, 20, 12, 12
  )
  local pts = c:render()
  G.polygon("fill", pts)
end

function drawBrush(cx, cy)
  G.push()
  G.translate(cx, cy)
  local s = (icon_d / 100) * 0.8
  G.scale(s, s)
  G.rotate(math.pi / 4)
  drawBrushHandle()
  drawBrushFerrule()
  drawBrushBristles()
  drawBrushTip()
  G.pop()
end

local function eraserBody()
  G.setColor(Color[Color.white])
  G.rectangle("fill", -12, -40, 24, 60)
end

local function eraserStripes()
  G.setColor(Color[Color.blue])
  G.rectangle("fill", -12, -40, 6, 60)
  G.rectangle("fill", 6, -40, 6, 60)
end

local function eraserTip()
  local w = Color.white + Color.bright
  G.setColor(Color[w])
  G.rectangle("fill", -12, 15, 24, 8)
end

local function eraserCrumbs()
  G.setColor(Color[Color.white])
  G.circle("fill", 18, 25, 2)
  G.circle("fill", 22, 30, 1.5)
  G.circle("fill", 15, 32, 1)
end

function drawEraser(cx, cy)
  G.push()
  G.translate(cx, cy)
  local s = icon_d / 100
  G.scale(s, s)
  G.rotate(math.pi / 4)
  eraserBody()
  eraserStripes()
  eraserTip()
  eraserCrumbs()
  G.pop()
end

goose = { 0.303, 0.431, 0.431 }

local tools = { drawBrush, drawEraser }

local function drawToolSlot(x, y, size, on)
  local white_b = Color.white + Color.bright
  local fill = on and Color.black or white_b
  G.setColor(Color[fill])
  G.rectangle("fill", x, y, size, size)
  G.setColor(Color[Color.black])
  G.rectangle("line", x, y, size, size)
end

function drawTools()
  local tb = icon_d
  local half = tb / 2
  for i = 1, n_t do
    local x = tool_midx - half
    local y = (i - 1) * (m_2 + tb) + m_2
    local on = (i == tool)
    drawToolSlot(x, y, tb, on)
    local draw = tools[i]
    local cx = tool_midx - m_2
    local cy = y + half + m_2
    draw(cx, cy)
  end
end

--====================
-- Weight selector UI
--====================
local function goosePoints(r, my)
  return {
    r.x2, r.y1, r.x1, r.y1, r.x1, r.y2, r.x2, r.y2,
    r.x1 + m_2, my + m_2, r.x1 + m_4, my, r.x1 + m_2, my - m_2
  }
end

local function drawGooseFill(r)
  local my = (r.y1 + r.y2) / 2
  local pts = goosePoints(r, my)
  G.setColor(goose)
  G.polygon("fill", pts)
end

local function drawGooseStroke(r)
  local my = (r.y1 + r.y2) / 2
  local pts = goosePoints(r, my)
  G.setColor(Color[Color.black])
  G.setLineWidth(2)
  G.polygon("line", pts)
  G.setLineWidth(1)
end

local function drawGoose(r)
  drawGooseFill(r)
  drawGooseStroke(r)
end

local function drawWeightRow(i, y, h, midy)
  local w = marg_l
  G.setColor(Color[Color.white + Color.bright])
  G.rectangle("fill", margin, y, w, h)

  local sel = (i == weight)
  if sel then
    local rx1 = 3 * margin
    local rx2 = 5 * margin
    local ry1 = midy - margin
    local ry2 = ry1 + m_2
    drawGoose({ x1 = rx1, y1 = ry1, x2 = rx2, y2 = ry2 })
  end

  G.setColor(Color[Color.black])
  local aw = weights[i]
  local xx = box_w / 3
  local yy = midy - (aw / 2)
  G.rectangle("fill", xx, yy, box_w / 2, aw)
end

function drawWeightSelector()
  local bx = 0
  local by = box_h - weight_h
  local bw = box_w - 1
  G.setColor(Color[Color.white + Color.bright])
  G.rectangle("line", bx, by, bw, weight_h)

  local rows = 8
  local h = (weight_h - (2 * margin)) / rows
  for i = 1, rows do
    local y = wb_y + margin + ((i - 1) * h)
    local midy = y + (h / 2)
    drawWeightRow(i, y, h, midy)
  end
end

--=========
-- Toolbox
--=========
function drawToolbox()
  G.setColor(Color[Color.white])
  G.rectangle("fill", 0, 0, box_w - 1, height - pal_h)
  G.setColor(Color[Color.white + Color.bright])
  G.rectangle("line", 0, 0, box_w - 1, box_h)
  drawTools()
  drawWeightSelector()
end

--==================
-- Paint parameters
--==================
function getWeight()
  local w = weights[weight]
  if tool == 2 then w = w * 1.5 end
  return w
end

function drawTarget()
  local x, y = love.mouse.getPosition()
  if not inCanvasRange(x, y) then return end
  local aw = getWeight()
  G.setColor(Color[Color.white])
  G.circle("line", x, y, aw)
end

--===============
-- Frame drawing
--===============
function love.draw()
  drawBackground()
  drawToolbox()
  drawColorPalette()
  G.draw(canvas, box_w, 0)
  drawTarget()
end

--================
-- State changes
--================
function setColor(x, y, btn)
  local row = math.floor((height - y) / block_h)
  local col = math.floor((x - sel_w) / block_w)
  local base = col + (8 * row)
  if btn == 1 then color = base else bg_color = base end
end

function setTool(_, y)
  local step = icon_d + m_4
  local sel = math.floor(y / step) + 1
  if sel <= n_t then tool = sel end
end

function setLineWeight(y)
  local ws = #weights
  local h = weight_h / ws
  local idx = math.floor((y - wb_y) / h) + 1
  if idx > 0 and idx <= ws then weight = idx end
end

--=====================
-- Painting operations
--=====================
local paint_state = { px = 0, y = 0, aw = 1, btn = 1 }

-- moved up: define setPaintColor before applyPaint
local function setPaintColor(btn)
  if btn == 1 and tool == 1 then
    G.setColor(Color[color]); return
  end
  G.setColor(Color[bg_color])
end

local function applyPaint()
  setPaintColor(paint_state.btn)
  G.circle(
    "fill",
    paint_state.px,
    paint_state.y,
    paint_state.aw
  )
end

function useCanvas(x, y, btn)
  local aw = getWeight()
  paint_state.px = x - box_w
  paint_state.y = y
  paint_state.aw = aw
  paint_state.btn = btn
  canvas:renderTo(applyPaint)
end

--==================
-- Input dispatchers
--==================
function point(x, y, btn)
  if inPaletteRange(x, y) then setColor(x, y, btn) end
  if inCanvasRange(x, y) then useCanvas(x, y, btn) end
  if inToolRange(x, y) then setTool(x, y) end
  if inWeightRange(x, y) then setLineWeight(y) end
end

function love.singleclick(x, y)
  point(x, y, 1)
end

function love.doubleclick(x, y)
  point(x, y, 2)
end

function love.mousemoved(x, y)
  if not inCanvasRange(x, y) then return end
  for btn = 1, 2 do
    if love.mouse.isDown(btn) then useCanvas(x, y, btn) end
  end
end

--============
-- Key input
--============
colorkeys = {
  ['1'] = 0, ['2'] = 1, ['3'] = 2, ['4'] = 3,
  ['5'] = 4, ['6'] = 5, ['7'] = 6, ['8'] = 7,
}

local function cycleTool()
  if tool >= n_t then tool = 1 else tool = tool + 1 end
end

local function shiftColor(c)
  if Key.shift() then return c + 8 end
  return c
end

function love.keypressed(k)
  if k == 'tab' then cycleTool() end
  if k == '[' and weight > 1 
   then weight = weight - 1 end
  if k == ']' and weight < #weights 
   then weight = weight + 1 end
  local c = colorkeys[k]
  if c then color = shiftColor(c) end
end
