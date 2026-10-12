--- @class LineReader
--- @field new function
--- @field feed function
--- @field reset function
LineReader = {}
LineReader.__index = LineReader

local DEFAULT_MAX = 256
local OVERLONG = 'overlong line dropped'

--- @param max_len integer?
--- @return LineReader
function LineReader.new(max_len)
  local self = setmetatable({}, LineReader)
  self.max_len = max_len or DEFAULT_MAX
  self.buf = ''
  self.skipping = false
  return self
end

--- Split off one line if the buffer holds a terminator
--- @return string?
function LineReader:take()
  local nl = string.find(self.buf, '\n', 1, true)
  if not nl then return nil end
  local line = string.sub(self.buf, 1, nl - 1)
  self.buf = string.sub(self.buf, nl + 1)
  if string.sub(line, -1) == '\r' then
    return string.sub(line, 1, -2)
  end
  return line
end

--- Add bytes, return whatever lines they completed.
--- A line over max_len is dropped, not buffered.
--- @param chunk string
--- @return string[] lines
--- @return string? err
function LineReader:feed(chunk)
  local lines = {}
  local err
  self.buf = self.buf .. chunk
  while true do
    local line = self:take()
    if not line then break end
    if self.skipping then
      self.skipping = false
      err = OVERLONG
    elseif #line > self.max_len then
      err = OVERLONG
    else
      lines[#lines + 1] = line
    end
  end
  if not self.skipping and #self.buf > self.max_len then
    self.buf = ''
    self.skipping = true
  end
  return lines, err
end

--- Drop partial input, on detach
function LineReader:reset()
  self.buf = ''
  self.skipping = false
end
