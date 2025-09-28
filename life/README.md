Life

This is a simple Game of Life implementation — the best-known zero-player computer game.
The field is a 2D grid where each cell is either alive (1) or dead (0).
Given an initial state and a few rules, we simulate the evolution of the cells.

Screen size

Unlike earlier demos where we only needed the center, here the whole game depends on how many pixels we have.
local G = love.graphics
local CELL = 10

local S = { w = 0, h = 0, gw = 0, gh = 0 }

local function init_dims()
  S.w, S.h = G.getDimensions()
  S.gw = math.floor(S.w / CELL)
  S.gh = math.floor(S.h / CELL)
end


getDimensions() returns the screen width/height. We divide by CELL to get a grid size in cells.

Setup

At startup, we generate a random initial pattern. All state is local, stored in S
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
      S.grid[x][y] = (math.random() < 0.3) and 1 or 0
    end
  end
end


Simulation

On each step we apply Conway’s rules:

A live cell with fewer than 2 live neighbours dies.

A live cell with 2 or 3 live neighbours lives on.

A live cell with more than 3 live neighbours dies.

A dead cell with exactly 3 live neighbours becomes alive.
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


We don’t update every update() call, because frame rates differ between devices.
Instead we keep a simple timer and step the grid at a controlled pace:
local SPEED_MIN, SPEED_MAX = 1, 99
local function clamp(v, lo, hi)
  if v < lo then return lo end
  if hi < v then return hi end
  return v
end

-- S.speed = steps per second; S.t = accumulator
local function try_step(dt)
  S.t = S.t + dt
  local need = 1 / clamp(S.speed, SPEED_MIN, SPEED_MAX)
  if S.t >= need then
    S.t = S.t - need
    step_grid()
  end
end


Controls

This is a zero-player game, but we still want to reset the board and tweak the simulation speed.
local function change_speed(d)
  if not d then return end
  S.speed = clamp(S.speed + d, SPEED_MIN, SPEED_MAX)
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


Touch

Modern devices are often touch-only. LOVE2D helps by emitting mouse events for taps, so single-touch support is straightforward.

Reset (long press)

We record how long the press lasted in update() and trigger a reset when it exceeds a threshold.
local HOLD_RST = 1 -- seconds

function love.update(dt)
  ensure_init()
  if love.mouse.isDown(1) then
    S.hold_dt = S.hold_dt + dt
  end
  try_step(dt)
end


On release we either reset or interpret the gesture for speed control:
local EPSILON = 3 -- pixels

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
        change_speed(dy) -- drag up = faster, down = slower
      end
    end
  end
  S.hold_y = nil
  S.hold_dt = 0
end


Help text

We draw a small overlay near the bottom edge. Font and sizes are kept in S.
local MARGIN = 5

local function draw_help()
  local bottom = S.h - MARGIN
  local right  = S.w - MARGIN
  local reset_msg = "Reset: [r] key or long press"
  local speed_msg = "Speed: [+]/[-] or drag up/down"
  G.print(reset_msg, MARGIN, (bottom - S.fh) - S.fh)
  G.print(speed_msg, MARGIN, bottom - S.fh)
  local label = string.format("Speed: %02d", S.speed)
  local lw = S.font:getWidth(label)
  G.print(label, right - lw, bottom - S.fh)
end

