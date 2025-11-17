-- main.lua
--  Game of Life — Compy-friendly.

local G = love.graphics

-- ---------- constants ----------
local CELL      = 10
local MARGIN    = 5
local SPEED_MIN = 1
local SPEED_MAX = 99
local EPSILON   = 3
local HOLD_RST  = 1

-- ---------- local state ----------
local S = {
  inited  = false,
  w = 0, h = 0,
  gw = 0, gh = 0,
  grid = {}, next = {},
  speed = 10, t = 0,
  hold_y = nil, hold_dt = 0,
  font = nil, fh = 0
}

-- ---------- helpers ----------
local function clamp(v, lo, hi)
  if v < lo then return lo end
  if hi < v then return hi end
  return v
end

local function init_dims()
  S.w, S.h = G.getDimensions()
  S.gw = math.floor(S.w / CELL)
  S.gh = math.floor(S.h / CELL)
end

local function new_font()
  S.font = G.newFont(14)
  S.fh = S.font:getHeight()
  G.setFont(S.font)
end

local function clear_grid(dst)
  for x = 1, S.gw do
    dst[x] = dst[x] or {}
    for y = 1, S.gh do
      dst[x][y] = 0
    end
  end
end

local function init_grid()
  S.grid, S.next = {}, {}
  clear_grid(S.grid)
  clear_grid(S.next)
  for x = 1, S.gw do
    for y = 1, S.gh do
      local live = math.random() < 0.3 and 1 or 0
      S.grid[x][y] = live
    end
  end
end

local function in_bounds(x, y)
  return 1 <= x and x <= S.gw and 1 <= y and y <= S.gh
end

local function get_cell(x, y)
  if not in_bounds(x, y) then return 0 end
  return S.grid[x][y]
end

local function alive_neighbors(x, y)
  local c = 0
  for dx = -1, 1 do
    for dy = -1, 1 do
      if not (dx == 0 and dy == 0) then
        c = c + get_cell(x + dx, y + dy)
      end
    end
  end
  return c
end

local function step_grid()
  for x = 1, S.gw do
    for y = 1, S.gh do
      local n = alive_neighbors(x, y)
      local v = S.grid[x][y]
      if v == 1 then
        S.next[x][y] = (n == 2 or n == 3) and 1 or 0
      else
        S.next[x][y] = (n == 3) and 1 or 0
      end
    end
  end
  S.grid, S.next = S.next, S.grid
end

local function try_step(dt)
  S.t = S.t + dt
  local need = 1 / clamp(S.speed, SPEED_MIN, SPEED_MAX)
  if S.t >= need then
    S.t = S.t - need
    step_grid()
  end
end

local function change_speed(d)
  if not d then return end
  S.speed = clamp(S.speed + d, SPEED_MIN, SPEED_MAX)
end

local function draw_cell(x, y)
  local px = (x - 1) * CELL
  local py = (y - 1) * CELL
  G.setColor(0.9, 0.9, 0.9)
  G.rectangle("fill", px, py, CELL, CELL)
  G.setColor(0.3, 0.3, 0.3)
  G.rectangle("line", px, py, CELL, CELL)
end

local function draw_help()
  local btm = S.h - MARGIN
  local right = S.w - MARGIN
  local msg_r = "Reset: [r] key or long press"
  local msg_s = "Speed: [+]/[-] or drag up/down"
  G.print(msg_r, MARGIN, (btm - S.fh) - S.fh)
  G.print(msg_s, MARGIN, btm - S.fh)
  local label = string.format("Speed: %02d", S.speed)
  local lw = S.font:getWidth(label)
  G.print(label, right - lw, btm - S.fh)
end

-- ----------  init hook ----------
local function ensure_init()
  if S.inited then return end
  math.randomseed(os.time())
  init_dims()
  new_font()
  init_grid()
  S.inited = true
end

-- ---------- LÖVE callbacks ----------
function love.update(dt)
  ensure_init()
  if love.mouse.isDown(1) then
    S.hold_dt = S.hold_dt + dt
  end
  try_step(dt)
end

function love.draw()
  ensure_init()
  for x = 1, S.gw do
    for y = 1, S.gh do
      if S.grid[x][y] == 1 then
        draw_cell(x, y)
      end
    end
  end
  G.setColor(1, 1, 1, 0.5)
  draw_help()
end

function love.keypressed(k)
  ensure_init()
  if k == "r" then
    init_grid()
  elseif k == "-" then
    change_speed(-1)
  elseif k == "+" or k == "=" then
    change_speed(1)
  end
end

function love.mousepressed(_, y, button)
  ensure_init()
  if button == 1 then
    S.hold_y = y
    S.hold_dt = 0
  end
end

function love.mousereleased(_, y, button)
  ensure_init()
  if button ~= 1 then return end
  if S.hold_dt >= HOLD_RST then
    init_grid()
  else
    if S.hold_y then
      local dy = S.hold_y - y
      if math.abs(dy) > EPSILON then
        change_speed(dy)
      end
    end
  end
  S.hold_y = nil
  S.hold_dt = 0
end
