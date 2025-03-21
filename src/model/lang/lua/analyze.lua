require('util.tree')

--- @alias AssignmentType
--- | 'function'
--- | 'method'
--- | 'local'
--- | 'global'
--- | 'field'

--- @class Assignment
--- @field name string
--- @field line integer
--- @field type AssignmentType

--- @class SemanticInfo
--- @field assignments Assignment[]

local keywords_list = {
  "and",
  "break",
  "do",
  "else",
  "elseif",
  "end",
  "false",
  "for",
  "function",
  "if",
  "in",
  "local",
  "nil",
  "not",
  "or",
  "repeat",
  "return",
  "then",
  "true",
  "until",
  "while",
}
local keywords = {}
for _, kw in pairs(keywords_list) do
  keywords[kw] = true
end

--- @param ast AST
--- @return string?
local function get_idx_stack(ast)
  --- @return string?
  local function go(node)
    local tag = node.tag
    if tag == "Index" then
      return go(node[1]) .. '.' .. node[2][1]
    elseif tag == "Id" then
      local acc = node[1]
      return acc
    else
      return
    end
  end
  return go(ast)
end

--- @param node AST
--- @return boolean
local function is_idx_stack(node)
  local st = get_idx_stack(node)
  if st then return true end
  return false
end

local function is_ident(id)
  -- HACK:
  if type(id) ~= "string" then
    return false
  end
  return string["match"](id, "^[%a_][%w_]*$") and not keywords[id]
end

--- @param node AST
--- @return table?
local function definition_extractor(node)
  local deftags = { 'Local', 'Localrec', 'Set' }

  local function get_line_number(n)
    local li = n.lineinfo
    local li_f = type(li) == 'table' and li.first
    return type(li_f) == 'table' and li_f.line
  end
  local function get_lhs_name(n)
    return n[1]
  end

  if type(node) == 'table' and node.tag then
    local tag = node.tag
    if table.is_member(deftags, tag) then
      local ret = {}

      local lhs = node[1]
      local rhs = node[2]

      local name = ''
      --- @type AssignmentType
      local atype
      if tag == 'Set'
          and lhs[1].tag == "Index"
          and rhs[1].tag == "Function"
          and rhs[1][1][1] and rhs[1][1][1][1] == "self"
          and is_idx_stack(lhs[1][1])
          and is_ident(lhs[1][2][1])
      then
        --- block 1
        atype = 'method'
        local class = lhs[1][1][1]
        local method = lhs[1][2][1]
        name = class .. ':' .. method
      elseif tag == 'Set'
          and rhs[1].tag == "Function"
          and is_idx_stack(lhs[1])
      then
        --- block 2
        atype = 'function'
        name = get_idx_stack(lhs[1]) or ''
      elseif type(rhs[1]) == "table"
          and rhs[1].tag == 'Table'
      then
        local at
        if tag == 'Local' then
          at = 'local'
        elseif tag == 'Set' then
          at = 'global'
        end
        local tname = lhs[1][1]
        name = tname
        local rets = {
          {
            name = tname,
            line = get_line_number(lhs),
            type = at,
          }
        }
        for _, v in ipairs(rhs) do
          for _, w in ipairs(v) do
            if type(w) == 'table' and
                type(w[1]) == 'table' and w[1][1] then
              local n = w[1][1]
              if type(n) == 'string' then
                table.insert(rets, {
                  name = tname .. '.' .. n,
                  line = get_line_number(w),
                  type = 'field',
                })
              else
                --- nested table, e.g. array of structs
                --- TODO recurse nested tables
              end
            end
          end
          return rets
        end
      else
        local rets = {}
        local at, is_local, dec_only
        if tag == 'Local' then
          at = 'local'
          is_local = true
        elseif tag == 'Localrec' then
          at = 'function'
        elseif tag == 'Set' then
          at = 'global'
        end
        for i, w in ipairs(lhs) do
          local n = get_lhs_name(w)
          if is_local and not rhs[i] then
            dec_only = true
          end
          if type(n) == 'string' then
            table.insert(rets, {
              name = n,
              line = get_line_number(w),
              type = at,
              undefined = dec_only,
            })
          end
        end
        return rets
      end

      ret.name = name
      ret.line = get_line_number(node)
      ret.type = atype
      return { ret }
    end
  end
end

--- @return function
local function defmatch(name)
  --- @return boolean
  return function(c)
    return c.name == name
  end
end

--- @param ast AST
--- @return SemanticInfo
local function analyze(ast)
  local sets = table.flatten(
    Tree.preorder(ast, definition_extractor)
  )
  local assignments = {}
  local candidates = {}
  for _, v in ipairs(sets or {}) do
    if not v.undefined
    then
      local ci = table.find_by(candidates, defmatch(v.name))
      local c = candidates[ci]
      if c then
        local a = {
          name = v.name,
          line = v.line,
          type = c.type,
        }
        table.insert(assignments, a)
      else
        table.insert(assignments, v)
      end
    else
      table.insert(candidates, v)
    end
  end
  return { assignments = assignments }
end

return {
  analyze = analyze,
}
