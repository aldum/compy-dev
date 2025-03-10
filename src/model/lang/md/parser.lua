local djot = require("djot.djot")
require("model.lang.lua.syntaxHighlighter")

require("util.debug")
require("util.string")
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

local types = {
  heading     = true,
  emph        = true,
  strong      = true,
  link        = true,
  list_marker = true,
  inline      = true, -- verbatim
}

local tag_to_type = {
  str       = 'default',
  heading   = 'heading',
  emph      = 'emph',
  strong    = 'strong',
  verbatim  = 'inline',
  list_item = 'list_marker',
  link      = 'link',
  image     = 'link',
}

--- @param input str
--- @param skip_posinfo boolean?
local function parse(input, skip_posinfo)
  local text = string.unlines(input)
  local posinfo = not (skip_posinfo == true)
  return djot.parse(text, posinfo)
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
  -- Log.info(Debug.terse_ast(doc, true, 'lua'))

  local colored_tokens = SyntaxColoring()
  --- @diagnostic disable-next-line: param-type-mismatch
  local tagged = transformAST(doc)
  -- Log.warn(Debug.terse_t(tagged, nil, nil, true))

  for l, line in pairs(tagged) do
    for i, c in pairs(line) do
      local typ = tag_to_type[c]
      if typ then
        -- Log.info(l, i, c)
        colored_tokens[l][i] = typ
      else
        -- colored_tokens[l][i] = 'default'
      end
    end
  end
  -- return syntax_hl(tokenize(code))
  return colored_tokens
end

--- @param t string tag
--- @return integer?
local colorize = function(t)
  local syntax_i = require("conf.md")
  local type     = types[t]
  if type then
    return syntax_i[t]
  else
    -- Log.warn(t)
  end
end

return {
  parse        = parse,
  highlighter  = highlighter,
  transformAST = transformAST,
  colorize     = colorize,
  render_html  = djot.render_html
}
