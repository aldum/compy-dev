-- Regression guard: a project supplies a highlighter that
-- returns nil for some input, and the render path indexes a
-- nil field — "attempt to index upvalue hl (a nil value)".
-- The field went dead mid-session; the acceptance criterion
-- is that it does not.
--
-- The model builds a highlight by two paths, and each had
-- the same hole: with a Lua parser (the console's REPL) and
-- without one (a plain-text widget). Only the second is
-- reachable from a project — `compy.input` is built on the
-- parser-less evaluator — so the parser cases below are
-- stated at the model, where no project-facing path exists
-- to state them at.
--
-- The crash itself happened inside the real draw, which
-- this suite cannot run (see technical_debt/input.md, "The
-- widget-handle shape test exercises a stub"). These cases
-- reach the last point before it: the highlight the view
-- indexes.

require("model.input.userInputModel")
require("model.interpreter.eval.evaluator")
require("util.string.string")

local F = require('tests.helpers.input_fixture')

if not orig_print then
  _G.orig_print = function() end
end

describe("highlight nil-index regression #input", function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- What a project can actually do, driven through the
  -- public surface it does it with.
  describe('a project keeps typing', function()

    local function type_and_read(highlighter)
      local input = F.activate_project()
      input.show({ text = 'a', highlighter = highlighter })
      F.session.type('b')
      return F.widget.model:get_input().highlight
    end

    it('with a highlighter that returns nil', function()
      local h = type_and_read(function() return nil end)
      assert.same({ 'ab' }, F.widget:get_text())
      assert.has_no.errors(function()
        return h.hl[1] and h.hl[1][1]
      end)
    end)

    it('with no highlighter at all', function()
      local h = type_and_read(nil)
      assert.same({ 'ab' }, F.widget:get_text())
      assert.has_no.errors(function()
        return h.hl[1] and h.hl[1][1]
      end)
    end)
  end)

  -- The parser path, which serves the console's Lua REPL. No
  -- project reaches it, so it is asserted where it lives.
  describe('the parser path', function()

    local mockConf = {
      view = { drawableChars = 64, lines = 16, input_max = 14 },
    }

    local function assert_indexable(model)
      local h = model:get_input().highlight
      assert.is_table(h.hl, '.hl is a table, never nil')
    end

    it('a parser with a highlighter returning nil', function()
      local ev = LuaEval()
      ev.highlighter = function() return nil end
      local m = UserInputModel(mockConf, ev)
      m:set_text({ 'return 1' })
      assert_indexable(m)
    end)

    -- Empty and non-empty are the model's own split: a fresh
    -- model holds no text, and the highlight is memoised on
    -- first query.
    it('a parser over empty text', function()
      assert_indexable(UserInputModel(mockConf, InputEvalLua))
    end)

    it('a parser over non-empty text', function()
      local m = UserInputModel(mockConf, InputEvalLua)
      m:set_text({ 'return 1' })
      assert_indexable(m)
    end)
  end)
end)
