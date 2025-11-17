-- board.lua — 2048

local Board = {}
Board.__index = Board

-- RNG: prefer love.math.random, fallback to math.random
local rnd = (love and love.math and love.math.random)
  or math.random

-- ===== Graphics shim (if love.graphics is missing) =====
local function make_gshim()
  local t = {}
  function t.setColor() end
  function t.rectangle() end
  function t.print() end
  function t.getFont() return nil end
  return t
end

local function Gfx()
  return (love and love.graphics) or make_gshim()
end

-- Center text without depending on printf
local function draw_center(s, x, y, w)
  local G = Gfx()
  local f = G.getFont and G.getFont()
  local tw = (f and f.getWidth) and f:getWidth(s) or 0
  local tx = x + (w - tw) / 2
  G.print(s, tx, y)
end

-- ===== Helpers =====
local function reverse(t)
  local out = {}
  for i = #t, 1, -1 do out[#out + 1] = t[i] end
  return out
end

-- Compress a line and merge equal neighbors once
local function slide_line(line)
  local merged, res, last = {}, {}, nil
  for _, v in ipairs(line) do
    if v ~= 0 then
      local m = last and last == v and not merged[#res]
      if m then
        res[#res] = v * 2; merged[#res] = true; last = nil
      else
        res[#res + 1] = v; merged[#res] = false; last = v
      end
    end
  end
  for i = #res + 1, #line do res[i] = 0 end
  return res
end

-- ===== Construction / state =====
function Board.new(rows, cols)
  local self = setmetatable({}, Board)
  self.rows, self.cols = rows, cols
  self._cell, self._dx, self._dy = 48, 0, 0
  self:seed()
  return self
end

function Board:clear()
  self.grid = {}
  for r = 1, self.rows do
    self.grid[r] = {}
    for c = 1, self.cols do self.grid[r][c] = 0 end
  end
end

function Board:seed()
  self:clear()
  self:add_random_tile()
  self:add_random_tile()
end

function Board:empty_cells()
  local out = {}
  for r = 1, self.rows do
    for c = 1, self.cols do
      if self.grid[r][c] == 0 then
        out[#out + 1] = { r = r, c = c }
      end
    end
  end
  return out
end

function Board:add_random_tile()
  local empty = self:empty_cells()
  if #empty == 0 then return end
  local i = rnd(1, #empty)
  local cell = empty[i]
  self.grid[cell.r][cell.c] = (rnd() < 0.9) and 2 or 4
end

-- ===== Moves (rows/cols reuse slide_line) =====
function Board:move_row_left(r)
  local row = {}
  for c = 1, self.cols do row[c] = self.grid[r][c] end
  local slid = slide_line(row)
  local moved = false
  for c = 1, self.cols do
    if self.grid[r][c] ~= slid[c] then moved = true end
    self.grid[r][c] = slid[c]
  end
  return moved
end

function Board:move_row_right(r)
  local row = {}
  for c = 1, self.cols do row[c] = self.grid[r][c] end
  local slid = reverse(slide_line(reverse(row)))
  local moved = false
  for c = 1, self.cols do
    if self.grid[r][c] ~= slid[c] then moved = true end
    self.grid[r][c] = slid[c]
  end
  return moved
end

function Board:move_col_up(c)
  local col = {}
  for r = 1, self.rows do col[r] = self.grid[r][c] end
  local slid = slide_line(col)
  local moved = false
  for r = 1, self.rows do
    if self.grid[r][c] ~= slid[r] then moved = true end
    self.grid[r][c] = slid[r]
  end
  return moved
end

function Board:move_col_down(c)
  local col = {}
  for r = 1, self.rows do col[r] = self.grid[r][c] end
  local slid = reverse(slide_line(reverse(col)))
  local moved = false
  for r = 1, self.rows do
    if self.grid[r][c] ~= slid[r] then moved = true end
    self.grid[r][c] = slid[r]
  end
  return moved
end

-- Single entry: map direction → line mover
function Board:move(dir)
  local map = {
    left  = { n = self.rows, f = self.move_row_left },
    right = { n = self.rows, f = self.move_row_right },
    up    = { n = self.cols, f = self.move_col_up },
    down  = { n = self.cols, f = self.move_col_down },
  }
  local noop = function() return false end
  local m = map[dir] or { n = 0, f = noop }
  local moved
  for i = 1, m.n do moved = m.f(self, i) or moved end
  return moved or false
end

-- ===== End conditions =====
function Board:has_empty()
  for r = 1, self.rows do
    for c = 1, self.cols do
      if self.grid[r][c] == 0 then return true end
    end
  end
  return false
end

function Board:has_merge()
  for r = 1, self.rows do
    for c = 1, self.cols do
      local v = self.grid[r][c]
      if (c < self.cols and v == self.grid[r][c + 1]) or
         (r < self.rows and v == self.grid[r + 1][c]) then
        return true
      end
    end
  end
  return false
end

function Board:isGameOver()
  return not self:has_empty() and not self:has_merge()
end

-- ===== Drawing =====
function Board:_begin_draw(x, y, cell)
  self._cell = cell or self._cell
  self._dx, self._dy = x or 0, y or 0
end

function Board:_draw_cell(r, c)
  local G, size = Gfx(), self._cell
  local x = self._dx + (c - 1) * size
  local y = self._dy + (r - 1) * size
  local val = self.grid[r][c]
  local color = (val == 0) and {0.9, 0.85, 0.7}
    or {0.9, 0.7 - (val / 2048) * 0.6, 0.3}
  G.setColor(color)
  G.rectangle("fill", x, y, size - 4, size - 4)
  if val ~= 0 then
    G.setColor(0.1, 0.1, 0.1)
    draw_center(tostring(val), x, y + size/2 - 12, size - 4)
  end
end

function Board:draw(x, y, cell)
  local G = Gfx()
  self:_begin_draw(x, y, cell)
  G.setColor(0.8, 0.7, 0.5)
  G.rectangle(
    "fill", x - 5, y - 5,
    cell * self.cols + 10, cell * self.rows + 10
  )
  for r = 1, self.rows do
    for c = 1, self.cols do self:_draw_cell(r, c) end
  end
end

_G.Board = Board
return Board
