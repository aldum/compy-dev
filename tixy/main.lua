--- @diagnostic disable: duplicate-set-field,lowercase-global
-- Title: TIXY viewer (Compy-friendly)

local G = love.graphics
math.randomseed(os.time())

cw, ch = G.getDimensions()
midx = cw / 2

require("math")
require("examples")

-- =========[ Layout / grid ]=========
size = 28
spacing = 3
offset = size + 4
count = 16
ex_idx = 1

-- =========[ Colors ]=========
local colors = {
  bg = Color[Color.black],
  pos = Color[Color.white + Color.bright],
  neg = Color[Color.red + Color.bright],
  text = Color[Color.white],
  help = Color.with_alpha(Color[Color.white], 0.5)
}

-- =========[ Help text ]=========
local help_lines = {
  "Hint:",
  "left click for next example",
  "shift + left click to go back",
  "right click for a random one"
}

help = table.concat(help_lines, "\n")
showHelp = true

-- =========[ Example source / legend ]=========
body = ""
legend = ""
local time = 0

local function load_example(ex)
  if type(ex) ~= "table" then return end
  body = ex.code
  legend = ex.legend
  setupTixy()
  write_to_input(body)
end

local function next_example()
  local e = examples[ex_idx]
  load_example(e)
  if ex_idx < #examples then
    ex_idx = ex_idx + 1
    time = 0
  end
end

local function prev_example()
  if ex_idx <= 1 then return end
  local e = examples[ex_idx]
  load_example(e)
  ex_idx = ex_idx - 1
  time = 0
end

local function pick_random(t)
  if type(t) ~= "table" then return end
  local n = #t
  local r = math.random(n)
  return t[r], r
end

local function randomize()
  local e, i = pick_random(examples)
  if not e then return end
  load_example(e)
  ex_idx = i + 1
end

function b2n(b)
  if b then
    return 1
  else
    return 0
  end
end

function n2b(n)
  if n ~= 0 then
    return true
  else
    return false
  end
end


function tixy(_, _, _, _) return 0.1 end

-- FIX: normalize newlines before loadstring
function setupTixy()
  local head = "return function(t, i, x, y)\n"
  local src = tostring(body):gsub("\\n", "\n")
  local code = head .. src .. "\nend"
  local f = loadstring(code)
  if not f then return end
  setfenv(f, _G)
  tixy = f()
end

-- =========[ Drawing ]=========
local function drawBackground()
  G.setColor(colors.bg)
  G.rectangle("fill", 0, 0, cw, ch)
end

local function drawCircle(color, r, cx, cy)
  G.setColor(color)
  local step = size + spacing
  local sx = cx * step + offset
  local sy = cy * step + offset
  G.circle("fill", sx, sy, r)
  G.circle("line", sx, sy, r)
end

local function clamp(value)
  local color = colors.pos
  local radius = (value * size) / 2
  if radius < 0 then
    radius = -radius
    color = colors.neg
  end
  if radius > size / 2 then radius = size / 2 end
  return color, radius
end

local function drawCell(ts, idx, x, y)
  local v = tonumber(tixy(ts, idx, x, y)) or -0.1
  local color, radius = clamp(v)
  drawCircle(color, radius, x, y)
end

local function drawOutput()
  local idx = 0
  local ts = time
  for y = 0, count - 1 do
    for x = 0, count - 1 do
      drawCell(ts, idx, x, y)
      idx = idx + 1
    end
  end
end

local function drawText()
  G.setColor(colors.text)
  local sof = (size / 2) + offset
  local hof = sof / 2
  local w = midx - sof
  G.printf(legend, midx + hof, sof, w)
  if not showHelp then return end
  G.setColor(colors.help)
  G.setFont(font)
  G.printf(help, midx + hof, ch - (5 * sof), w)
end

function love.draw()
  drawBackground()
  drawOutput()
  drawText()
end

-- =========[ Live code input ]=========
r = user_input()

function love.update(dt)
  time = time + dt
  if r:is_empty() then
    input_code(
      "function tixy(t, i, x, y)",
      string.lines(body)
    )
    return
  end
  local ret = r()
  body = string.unlines(ret)
  setupTixy()
  legend = ""
end

-- =========[ Mouse controls ]=========
function love.mousepressed(_, _, button)
  if button == 1 then
    if Key.shift() then prev_example() else next_example() end
  end
  if button == 2 then randomize() end
end

next_example()
