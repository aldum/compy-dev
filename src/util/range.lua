local class = require('util.class')

--- @class Range
--- @field start integer
--- @field fin integer
---
--- @field inc fun(self, integer): boolean
--- @field translate fun(self, integer): Range
--- @field __tostring fun(self): string
Range = class.create(
--- @param s integer
--- @param e integer
  function(s, e)
    --- TODO: validate
    return {
      start = s, fin = e
    }
  end)

function Range.singleton(n)
  return Range(n, n)
end

function Range:len()
  local s = self.start
  local e = self.fin
  return e - s + 1
end

function Range:__tostring()
  local s = self.start
  local e = self.fin
  return string.format('{%d-%d}[%d]', s, e, self:len())
end

function Range:ln_label()
  local s = self.start
  local e = self.fin
  if s == e then
    return string.format('L%d', s, 1)
  else
    return string.format('L%d-%d(%d)', s, e, self:len())
  end
end

--- Determine whether `n` is in the range
--- @param n integer
--- @return boolean
function Range:inc(n)
  if type(n) ~= 'number' then return false end
  if self.start > n then return false end
  if self.fin < n then return false end
  return true
end

--- Determine the how much `n` is in outside the range
--- (signed result)
--- @param n integer
--- @return integer?
function Range:outside(n)
  if type(n) ~= 'number' then return nil end
  if self:inc(n) then
    return 0
  else
    if n < self.start then
      return n - self.start
    end
    if n > self.fin then
      return n - self.fin
    end
  end
end

--- @return integer[]
function Range:enumerate()
  local ret = {}
  for i = self.start, self.fin do
    table.insert(ret, i)
  end
  return ret
end

--- Translate functions do not modify the original

--- @param by integer
--- @return Range
function Range:translate(by)
  if type(by) == 'number' then
    return Range(self.start + by, self.fin + by)
  else
    error()
  end
end

--- @param by integer
--- @param ll integer?
--- @param ul integer?
--- @return Range
--- @return integer actual_by
function Range:translate_limit(by, ll, ul)
  if type(by) == 'number' then
    local s, e = self.start, self.fin
    --- @param limit integer?
    --- @param picker function
    local function calc_limited_by(limit, picker)
      local ret = by
      if limit then
        ret = picker(by, limit - s, limit - e)
      end
      return ret
    end

    if by < 0 then
      local down = calc_limited_by(ll, math.max)
      return self:translate(down), down
    elseif by > 0 then
      local up = calc_limited_by(ul, math.min)
      return self:translate(up), up
    end
  else
    error('invalid by')
  end
  return Range(self.start, self.fin), by
end
