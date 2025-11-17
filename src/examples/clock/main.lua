-- main.lua
-- Simple digital clock with small, readable helpers.
-- Goals: clear names, short lines, low nesting, no globals.

local G = love.graphics

-- Constants for clarity.
local TICKS       = 60       -- "seconds" per minute
local HOURS_IN_T  = TICKS * TICKS
local DAY_HOURS   = 24
local MAX_COLORS  = 7
local FONT_SIZE   = 144

-- Canvas geometry.
local W, H = G.getDimensions()
local MID_X = W / 2
local MID_Y = H / 2

-- Local state container.
local S = {
  t = 0,        -- time accumulator
  color = 1,    -- foreground palette index
  bg = 1,       -- background palette index
  font = G.newFont(FONT_SIZE)
}

-- Utilities kept tiny and didactic.
local function pad2(i)
  return string.format("%02d", i)
end

local function cycle(i)
  if i > MAX_COLORS then
    return 1
  end
  return i + 1
end

local function is_shift()
  return love.keyboard.isDown("lshift", "rshift")
end

-- Set "wall-clock" into S.t using os.date.
local function set_time_now()
  local tm = os.date("*t")
  local h = tm.hour
  local m = tm.min
  local s = tm.sec
  S.t = s + TICKS * m + HOURS_IN_T * h
end

set_time_now()

-- Build HH:MM:SS string from S.t using simple steps.
local function make_timestamp(tt)
  local hours_raw = math.floor(tt / HOURS_IN_T)
  local hours = math.fmod(hours_raw, DAY_HOURS)

  local mins_raw = math.floor(tt / TICKS)
  local minutes = math.fmod(mins_raw, TICKS)

  local seconds = math.fmod(math.floor(tt), TICKS)

  local hh = pad2(hours)
  local mm = pad2(minutes)
  local ss = pad2(seconds)

  return string.format("%s:%s:%s", hh, mm, ss)
end

-- Handle color cycling on space; Shift+Space flips background.
local function on_color_key()
  if is_shift() then
    S.bg = cycle(S.bg)
  else
    S.color = cycle(S.color)
  end
end

-- LÖVE callbacks kept flat and short.
function love.update(dt)
  S.t = S.t + dt
end

function love.draw()
  -- Color table `Color` is assumed provided by the runtime.
  G.setColor(Color[S.color + Color.bright])
  G.setBackgroundColor(Color[S.bg])
  G.setFont(S.font)

  local text = make_timestamp(S.t)
  local off_x = S.font:getWidth(text) / 2
  local off_y = S.font:getHeight() / 2

  G.print(text, MID_X - off_x, MID_Y - off_y)
end

function love.keyreleased(k)
  if k == "space" then
    on_color_key()
  elseif k == "r" and is_shift() then
    set_time_now()
  elseif k == "p" then
    -- `pause` is assumed provided by the host environment.
    pause("STOP THE CLOCKS!")
  end
end
