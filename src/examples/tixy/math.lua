-- ====================[ FILE: math.lua ]====================
--- @diagnostic disable: duplicate-set-field,lowercase-global
-- Import math namespace into globals for short, readable code.

for k, v in pairs(math) do
  _G[k] = v
end

-- Pythagorean helper.
function hypot(a, b)
  return sqrt(a ^ 2 + b ^ 2)
end

-- Bit ops, if available. Safe with pcall.
local ok, bitlib = pcall(require, "bit")
if ok and bitlib then
  for k, v in pairs(bitlib) do
    _G[k] = v
  end
end
