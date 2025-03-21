--- @module 'djot'
--- Parse and render djot light markup format. See https://djot.net.
---
--- @usage
--- local djot = require("djot")
--- local input = "This is *djot*"
--- local doc = djot.parse(input)
--- -- render as HTML:
--- print(djot.render_html(doc))
---
--- -- render as AST:
--- print(djot.render_ast_pretty(doc))
---
--- -- or in JSON:
--- print(djot.render_ast_json(doc))
---
--- -- alter the AST with a filter:
--- local src = "return { str = function(e) e.text = e.text:upper() end }"
--- -- subordinate modules like filter can be accessed as fields
--- -- and are lazily loaded.
--- local filter = djot.filter.load_filter(src)
--- djot.filter.apply_filter(doc, filter)
---
--- -- streaming parser:
--- for startpos, endpos, annotation in djot.parse_events("*hello there*") do
---   print(startpos, endpos, annotation)
--- end

local unpack = unpack or table.unpack
local Parser = require("djot.djot.block").Parser
local ast = require("djot.djot.ast")
local html = require("djot.djot.html")
local json = require("djot.djot.json")
local filter = require("djot.djot.filter")

--- @class StringHandle
local StringHandle = {}

--- @return (StringHandle)
function StringHandle:new()
  local buffer = {}
  setmetatable(buffer, StringHandle)
  StringHandle.__index = StringHandle
  return buffer
end

--- @param s (string)
function StringHandle:write(s)
  self[#self + 1] = s
end

--- @return (string)
function StringHandle:flush()
  return table.concat(self)
end

--- Parse a djot text and construct an abstract syntax tree (AST)
--- representing the document.
--- @param input (string) input string
--- @param sourcepos (boolean?) if true, source positions are included in the AST
--- @param warn (function?) function that processes a warning, accepting a warning
--- object with `pos` and `message` fields.
--- @return (AST)
local function parse(input, sourcepos, warn)
  local parser = Parser:new(input, warn)
  return ast.to_ast(parser, sourcepos or false)
end

--- Parses a djot text and returns an iterator over events, consisting
--- of a start position (bytes), and an position (bytes), and an
--- annotation.
--- @param input (string) input string
--- @param warn (function) function that processes a warning, accepting a warning
--- object with `pos` and `message` fields.
--- @return (fun(): integer, integer, string) it an iterator over events.
---
---     for startpos, endpos, annotation in djot.parse_events("hello *world") do
---     ...
---     end
local function parse_events(input, warn)
  return Parser:new(input, warn):events()
end

--- Render a document's AST in human-readable form.
--- @param doc (AST) the AST
--- @return (string) rendered AST
local function render_ast_pretty(doc)
  local handle = StringHandle:new()
  ast.render(doc, handle)
  return handle:flush()
end

--- Render a document's AST in JSON.
--- @param doc (AST) the AST
--- @return (string) rendered AST (JSON string)
local function render_ast_json(doc)
  return json.encode(doc) .. "\n"
end

--- Render a document as HTML.
--- @param doc (AST) the AST
--- @return (string) rendered document (HTML string)
local function render_html(doc)
  local handle = StringHandle:new()
  local renderer = html.Renderer:new()
  renderer:render(doc, handle)
  return handle:flush()
end

--- Render an event as a JSON array.
--- @param startpos (integer) starting byte position
--- @param endpos (integer) ending byte position
--- @param annotation (string) annotation of event
--- @return (string) rendered event (JSON string)
local function render_event(startpos, endpos, annotation)
  return string.format("[%q,%d,%d]", annotation, startpos, endpos)
end

--- Parse a document and render as a JSON array of events.
--- @param input (string) the djot document
--- @param warn (function) function that emits warnings, taking as argumnet
--- an object with fields 'message' and 'pos'
--- @return (string) rendered events (JSON string)
local function parse_and_render_events(input, warn)
  local handle = StringHandle:new()
  local idx = 0
  for startpos, endpos, annotation in parse_events(input, warn) do
    idx = idx + 1
    if idx == 1 then
      handle:write("[")
    else
      handle:write(",")
    end
    handle:write(render_event(startpos, endpos, annotation) .. "\n")
  end
  handle:write("]\n")
  return handle:flush()
end

--- djot version (string)
local version = "0.2.1"

--- @export
local G = {
  parse = parse,
  parse_events = parse_events,
  parse_and_render_events = parse_and_render_events,
  render_html = render_html,
  render_ast_pretty = render_ast_pretty,
  render_ast_json = render_ast_json,
  render_event = render_event,
  version = version
}

-- Lazily load submodules, e.g. djot.filter
setmetatable(G, {
  __index = function(t, name)
    local mod = require("djot.djot" .. name)
    rawset(t, name, mod)
    return t[name]
  end
})

return G
