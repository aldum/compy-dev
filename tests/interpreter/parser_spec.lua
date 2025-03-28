local parser = require("model.lang.lua.parser")('metalua')
local term = require("util.termcolor")
require("util.color")
require("util.debug")

local inputs = require("tests.interpreter.parser_inputs")

if not orig_print then
  _G.orig_print = print
end

-- when testing with Lua5.3
if not _G.unpack then
  _G.unpack = table.unpack
end

local parser_debug = os.getenv("PARSER_DEBUG")
local highlighter_debug = os.getenv("HL_DEBUG")

describe('parse #parser', function()
  -- print(Debug.print_t(parser))
  for i, input in ipairs(inputs) do
    local tag = 'input #' .. i
    it('parses ' .. tag, function()
      local ok, r = parser.parse(input.code)
      local l, c, err
      if not ok then
        --- @type Error
        local p_err = r
        if highlighter_debug then
          Log.error(Debug.terse_t(r, nil, nil, true))
        end
        if input.error then
          local el = input.error.l
          local ec = input.error.c
          assert.are_equal(el, p_err.l)
          assert.are_equal(ec, p_err.c)
        end
      end
      if parser_debug then
        if not ok then
          print(tag, string.join(input.code, '⏎ '))
          local error = string.format("%s:%s | %s",
            l or '', c or '', err or '')
          if string.is_non_empty_string(err) then
            term.print_c(Color.red, error)
          end
          for ln, line in pairs(input.code) do
            if ln == l then
              if c == 1 then
                term.print_c(Color.magenta, line)
              else
                local ll = string.ulen(line)
                for ch = 1, ll do
                  if ch <= c then
                    term.print_c(Color.white,
                      string.usub(line, ch, ch), true)
                  else
                    term.print_c(Color.magenta,
                      string.usub(line, ch, ch), true)
                  end
                end
                print()
                for _ = 1, c do io.write(' ') end
              end
              term.print_c(Color.red, '^')
            elseif l and ln > l then
              term.print_c(Color.magenta, line)
            else
              term.print_c(Color.white, line)
            end
          end
          print()
        else
          print(tag, string.join(input.code, '⏎ '))
          local pp = parser.pprint(input.code)
          if string.is_non_empty_string_array(pp) then
            term.print_c(Color.green, string.unlines(pp or ''))
          end
        end
      end
      assert.are_equal(input.compiles, ok)
    end)
  end
end)

describe('highlight #parser', function()
  for i, input in ipairs(inputs) do
    local tag = 'input #' .. i
    it('parses ' .. tag, function()
      local hl = parser.highlighter(input.code)
      -- print(Debug.text_table(input.code, true))
      if highlighter_debug then
        for l, line in ipairs(input.code) do
          local rowc = hl[l] or {}
          for j = 1, #line do
            local c = rowc[j]
            term.print_c(c, string.sub(line, j, j), true)
          end
          print()
        end
        print(term.reset)
      end
    end)
  end
end)
