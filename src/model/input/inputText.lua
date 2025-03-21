require("model.input.cursor")

local class = require('util.class')
require("util.dequeue")

--- @class InputText: Dequeue
--- @field new function
--- @field traverse function
InputText = class.create()

--- @param values string[]?
--- @return InputText
function InputText.new(values)
  --- @type InputText
  --- @diagnostic disable-next-line: assign-type-mismatch
  local self = Dequeue.typed('string', values)
  if not values or values == '' or
      (type(values) == "table" and #values == 0)
  then
    self:append('')
  end

  setmetatable(self, {
    __index = function(t, k)
      local value = InputText[k] or Dequeue[k]
      return value
    end
  })

  return self
end

--- Traverses text between two cursor positions
--- from and to are required to be in order at this point
---@param from    Cursor
---@param to      Cursor
---@param options table
---@return table  traversed
function InputText:traverse(from, to, options)
  local ls = from.l
  local le = to.l
  -- cursor position is +1 off
  local cs = from.c
  local ce = to.c - 1
  local lines = string.lines(self)

  local ret = Dequeue.typed('string')
  local defaults = {
    delete = false,
  }
  local opts = (function()
    if not options then
      return defaults
    else
      return {
        delete = options.delete,
      }
    end
  end)()

  if ls == le then
    if ce > cs then
      local l = lines[ls]
      local pre, mid, post = string.splice(l, cs - 1, ce)
      ret:append(mid)
      if opts.delete then
        self:update(pre .. post, ls)
      end
    else
      ret:append('')
    end
  else
    local l1 = lines[ls]
    local ll = lines[le]
    local fls, fle = string.split_at(l1, cs)
    ret:append(fle)
    -- intermediate lines
    for i = ls + 1, le - 1 do
      ret:append(lines[i])
    end
    -- last line
    local lls, lle = string.split_at(ll, ce + 1)
    ret:append(lls)
    if opts.delete then
      self:update(fls .. lle, ls)
      for i = le, ls + 1, -1 do
        self:remove(i)
      end
    end
  end

  return ret
end

--- @return boolean
function InputText:is_empty()
  return not string.is_non_empty_string_array(self:items())
end
