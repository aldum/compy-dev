--- Example text: {
--- 'ABBA',
--- 'EDDA AC/DC',
--- }
--- Assume a wrap width of 5, wrapped text comes out to: {
--- 'ABBA',
--- 'EDDA ',
--- 'AC/DC',
--- }
--- @alias WrapForward table<integer, integer[]>
--- Mapping from original line numbers to wrapped line numbers.
--- e.g. {1: {1], 2: {2}, 3: {3, 4}}
--- @alias WrapReverse integer[]
--- Inverse mapping from apparent line number to original
--- Key is line number in wrapped, value is line number in
--- unwrapped original, e.g. {1: 1, 2: 2, 3: 2} means two
--- lines of text were broken up into three, because the second
--- exceeded the width limit

--- @class WrappedText
--- @field text string[]
--- @field wrap_w integer
--- @field wrap_forward WrapForward
--- @field wrap_reverse WrapReverse
--- @field n_breaks integer
---
--- @field wrap function
--- @field get_text function
--- @field get_line function
--- @field get_n_lines function
WrappedText = {}
WrappedText.__index = WrappedText

setmetatable(WrappedText, {
  __call = function(cls, ...)
    return cls.new(...)
  end,
})

--- @param w integer
--- @param text string[]?
--- @return WrappedText
function WrappedText.new(w, text)
  local self = setmetatable({}, WrappedText)
  self:_init(w, text)

  return self
end

--- @protected
--- @param w integer
--- @param text string[]?
function WrappedText:_init(w, text)
  self.text = {}
  self.wrap_w = w
  self.wrap_forward = {}
  self.wrap_reverse = {}
  self.n_breaks = 0
  if text then
    self:wrap(text)
  end
end

--- @param text string[]
function WrappedText:wrap(text)
  local w = self.wrap_w
  local display = {}
  local wrap_forward = {}
  local wrap_reverse = {}
  local breaks = 0
  local revi = 1
  if text then
    for i, l in ipairs(text) do
      local n = math.floor(string.ulen(l) / w)
      -- remember how many apparent lines will be overall
      local ap = n + 1
      local fwd = {}
      for _ = 1, ap do
        wrap_reverse[revi] = i
        table.insert(fwd, revi)
        revi = revi + 1
      end
      wrap_forward[i] = fwd
      breaks = breaks + n
      local lines = string.wrap_at(l, w)
      for _, tl in ipairs(lines) do
        table.insert(display, tl)
      end
    end
  end
  self.text = display
  self.wrap_forward = wrap_forward
  self.wrap_reverse = wrap_reverse
  self.n_breaks = breaks
end

--- @return string[]
function WrappedText:get_text()
  return self.text
end

--- @param l integer
function WrappedText:get_line(l)
  return self.text[l]
end

--- @return integer
function WrappedText:get_n_lines()
  return #(self.text)
end