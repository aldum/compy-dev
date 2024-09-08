require("util.range")

--- @class Scrollable
Scrollable = {}
Scrollable.__index = Scrollable

--- @param size_max integer
--- @param len integer
--- @return Range
function Scrollable.calculate_end_range(size_max, len)
  local L = size_max
  local clen = len
  local off = math.max(clen - L, 0)
  local si = 1
  local ei = math.min(L, clen + 1)
  return Range(si, ei):translate(off)
end

function Scrollable.to_end(size_max, len)
  local end_r = Scrollable.calculate_end_range(size_max, len)
  return end_r
end
