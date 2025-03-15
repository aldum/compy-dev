local ct = require("conf.md")
require("model.lang.highlight")
require("util.string")

local add_paths = {
  'lib/' .. 'djot' .. '/?.lua',
  'lib/?.lua',
}
if love and not TESTING then
  local love_paths = string.join(add_paths, ';')
  love.filesystem.setRequirePath(
    love.filesystem.getRequirePath() .. love_paths)
else
  local lib_paths = string.join(add_paths, ';src/')
  package.path = lib_paths .. ';' .. package.path
end
local djot = require("djot.djot")

require("util.debug")
require("util.dequeue")

--- @alias MdTagType
--- | 'heading'
--- | 'list'
--- | 'list_item'
--- | 'block_attributes'
--- | 'attributes'
--- | 'footnote'
--- | 'note_label'
--- | 'table'
--- | 'row'
--- | 'image'
--- | 'link'

--- @alias MdTokenType
--- | 'header'
--- | 'link'
--- | 'bold'
--- | 'italic'
--- | 'list'
--- | 'hr'
--- | 'code'

--- There's no proper namespacing on the type annotation level,
--- hence restating the djot AST type
--- @class mdAST
--- @field tag string
--- @field s? string
--- @field children mdAST[]
--- @field pos? string[]

local tag_to_type = {
  str        = 'default',
  heading    = 'heading',
  emph       = 'emph',
  strong     = 'strong',
  verbatim   = 'code',
  code_block = 'code',
  list_item  = 'list_marker',
  link       = 'link',
  image      = 'link',
}

local function logwarn(wt)
  Log.debug(Debug.terse_ast(wt, true))
end
--- @param input str
--- @param skip_posinfo boolean?
--- @return AST -- djot AST, distinct from metalua
local function parse(input, skip_posinfo)
  local text = string.unlines(input)
  local posinfo = not (skip_posinfo == true)
  return djot.parse(text, posinfo, logwarn)
end

--- courtesy of Claude
--- @param node mdAST
--- @param result? table
local function transformAST(node, result)
  result = result or {}

  -- Log.info(Debug.terse_t(node, nil, nil, true))
  -- Log.debug("Processing node with tag: " .. (node.tag or "nil"))

  if node.pos then
    local text = node.s
    local startPos, endPos = node.pos[1], node.pos[2]

    local startLine, startChar = startPos:match("(%d+):(%d+):")
    local endLine, endChar = endPos:match("(%d+):(%d+):")
    startLine, startChar = tonumber(startLine), tonumber(startChar)
    endLine, endChar = tonumber(endLine), tonumber(endChar)

    -- Log.debug("\tPosition info found: "
    --   .. startLine .. ':' .. startChar .. " to "
    --   .. endLine .. ':' .. endChar
    -- )

    for line = startLine, endLine do
      result[line] = result[line] or {}

      local lineStartChar = (line == startLine) and startChar or 1
      local lineEndChar =
          (line == endLine)
          and endChar
          or string.ulen(text or ' ')

      for char = lineStartChar, lineEndChar do
        result[line][char] = node.tag
      end
    end
  end

  if node.children then
    for _, child in ipairs(node.children) do
      transformAST(child, result)
    end
  end

  -- Log.debug(Debug.terse_t(result, nil, nil, true))

  return result
end

--- Highlight string array
--- @param input str
--- @return SyntaxColoring
local highlighter = function(input)
  local doc = parse(input)

  local colored_tokens = SyntaxColoring()
  --- @diagnostic disable-next-line: param-type-mismatch
  local tagged = transformAST(doc)

  for l, line in pairs(tagged) do
    for i, c in pairs(line) do
      local typ = tag_to_type[c]
      if typ then
        colored_tokens[l][i] = ct[typ]
      end
    end
  end
  return colored_tokens
end

return {
  parse        = parse,
  highlighter  = highlighter,
  transformAST = transformAST,
  render_html  = djot.render_html
}
