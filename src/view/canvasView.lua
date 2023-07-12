local G = love.graphics

CanvasView = {}

function CanvasView:new(cfg)
  local cv = {
    cfg = cfg,
  }
  setmetatable(cv, self)
  self.__index = self

  return cv
end

function CanvasView:draw(output)
  local b = self.cfg.border
  local N = self.cfg.linesN
  local function write_line(l, text)
    if l < 0 or l > N then return end
    local cx = b + 1
    local lineOffset = (l - 1) * self.cfg.fh
    local cy = b + 1 + lineOffset
    G.setColor(self.cfg.colors.fg)
    G.print(text or '', cx, cy)
  end

  local offset = 0
  if #output > N then
    offset = #output - N
  end
  for i = 1, #output do
    write_line(i, output[i + offset])
  end
end
