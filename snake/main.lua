--- @diagnostic disable: duplicate-set-field,lowercase-global
-- Snake (Compy-friendly)
-- =========[ Gfx / sizes ]=========
local G = love and love.graphics or nil
local UNIT = 10           -- cell size in px
-- cell size in px
local CW, CH = 102, 60    -- grid in cells
-- grid in cells

love.window.setTitle("snake")

-- =========[ Flags / state ]=========
local IS_COMPY = true
local SHOW_GRID = false
local STATUS = "running"

-- =========[ Runtime vars ]=========
local snake = {}
local apple = { x = 0, y = 0 }
local move = nil
local speed = 0.25
local timer = 0
local midx, midy = 0, 0

-- =========[ Helpers ]=========
local function setup_graphics()
  if not G and love and love.graphics then
    G = love.graphics
  end
  if G then
    midx, midy = G.getDimensions()
  end
end

local function rnd(n) return math.random(n) end

local function rect_fill(x, y, w, h, r)
  G.rectangle("fill", x, y, w, h, r, r)
end

local function cell_px(c) return c * UNIT end

-- =========[ Draw pieces ]=========
local function draw_grid()
  if not SHOW_GRID then return end
  G.setColor(0.2, 0.2, 0.2)
  G.setLineWidth(0.1)
  for x = 1, CW * UNIT, UNIT do
    G.line(x, 0, x, CH * UNIT)
  end
  for y = 1, CH * UNIT, UNIT do
    G.line(0, y, CW * UNIT, y)
  end
end

local function draw_snake()
  for i, part in ipairs(snake) do
    if i == 1 then G.setColor(0, 0.4, 0, 1)
    else G.setColor(0, 0.8, 0) end
    rect_fill(cell_px(part.x), cell_px(part.y), UNIT, UNIT, 5)
  end
end

local function draw_apple()
  G.setColor(0.8, 0, 0)
  rect_fill(cell_px(apple.x), cell_px(apple.y), UNIT, UNIT, 5)
end

local function draw_gameover()
  G.setColor(1, 1, 1)
  G.setNewFont(20)
  local x = midx / 2 - 150
  local y = midy / 2
  G.printf("GAME OVER", x, y, 300, "center")
  G.printf("Press [SPACE] to restart", x, y + 26, 300, "center")
  G.printf("Press [ESC] to quit", x, y + 52, 300, "center")
end

-- =========[ Movement ]=========
local direction = {}

direction.up    = function() snake[1].y = snake[1].y - 1 end
direction.down  = function() snake[1].y = snake[1].y + 1 end
direction.left  = function() snake[1].x = snake[1].x - 1 end
direction.right = function() snake[1].x = snake[1].x + 1 end

local function turn_left()
  if move ~= direction.right then move = direction.left end
end

local function turn_right()
  if move ~= direction.left then move = direction.right end
end

local function turn_up()
  if move ~= direction.down then move = direction.up end
end

local function turn_down()
  if move ~= direction.up then move = direction.down end
end

-- =========[ Input ]=========
local function handle_heading(key)
  if key == "a" or key == "left" then turn_left() return end
  if key == "d" or key == "right" then turn_right() return end
  if key == "w" or key == "up" then turn_up() return end
  if key == "s" or key == "down" then turn_down() return end
end

local function handle_running_key(key)
  if key == "g" then SHOW_GRID = not SHOW_GRID return end
  if key == "space" then love.handlers.start() return end
  if key == "escape" then love.event.quit() return end
  handle_heading(key)
end

local function handle_gameover_key(key)
  if key == "space" then love.handlers.start() return end
  if key == "escape" then love.event.quit() return end
end

-- =========[ Collisions ]=========
local function head_hits_wall()
  if snake[1].x < 0 then return true end
  if snake[1].y < 0 then return true end
  if snake[1].x > (CW - 1) then return true end
  if snake[1].y > (CH - 1) then return true end
  return false
end

local function head_hits_body()
  for i = 2, #snake do
    if snake[1].x == snake[i].x and snake[1].y == snake[i].y then
      return true
    end
  end
  return false
end

-- =========[ Apple placement ]=========
local function build_free_map()
  local map = {}
  for j = 0, CH - 1 do
    for i = 0, CW - 1 do
      map[j * CW + i] = true
    end
  end
  for _, v in ipairs(snake) do
    map[v.y * CW + v.x] = false
  end
  return map
end

local function pick_free_cell()
  local total = CW * CH - #snake
  local k = rnd(total)
  local count = 0
  local map = build_free_map()
  for j = 0, CH - 1 do
    for i = 0, CW - 1 do
      if map[j * CW + i] then
        count = count + 1
        if count == k then return { x = i, y = j } end
      end
    end
  end
  return { x = 0, y = 0 }
end

-- =========[ Mechanics ]=========
local function advance_snake()
  local hx, hy = snake[1].x, snake[1].y
  move()
  local last = { x = hx, y = hy }
  for pos = #snake, 3, -1 do
    snake[pos] = snake[pos - 1]
  end
  if #snake > 1 then snake[2] = last end
end

local function try_eat()
  if snake[1].x ~= apple.x then return end
  if snake[1].y ~= apple.y then return end
  apple = pick_free_cell()
  table.insert(snake, {})
end

-- =========[ Lifecycle ]=========
love.handlers = {}

love.handlers.start = function()
  math.randomseed(os.time())
  setup_graphics()
  STATUS = "running"
  local sx = math.floor(CW / 2)
  local sy = math.floor(CH / 2)
  snake = {
    { x = sx,     y = sy     },
    { x = sx - 1, y = sy     },
    { x = sx - 2, y = sy     },
  }
  move = direction.right
  timer = 0
  apple = pick_free_cell()
end

-- =========[ Callbacks ]=========
love.draw = function()
  if STATUS == "running" then
    draw_grid(); draw_snake(); draw_apple()
  else
    draw_gameover()
  end
end

love.keypressed = function(key)
  if STATUS == "running" then
    handle_running_key(key)
  else
    handle_gameover_key(key)
  end
end

love.update = function(dt)
  if STATUS ~= "running" then return end
  timer = timer + dt
  if timer < speed then return end
  timer = 0
  advance_snake()
  try_eat()
  if head_hits_wall() or head_hits_body() then
    STATUS = "gameover"
  end
end

-- =========[ Bootstrap ]=========
if not IS_COMPY then
  love.load = function()
    setup_graphics()
    love.window.setMode(1024, 600)
    IS_COMPY = false
    love.handlers.start()
  end
else
  love.handlers.start()
end
