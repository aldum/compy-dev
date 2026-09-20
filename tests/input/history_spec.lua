--- @diagnostic disable: invisible
require("model.input.history")
local F = require('tests.helpers.input_fixture')

if not orig_print then
  --- @diagnostic disable: duplicate-set-field
  _G.orig_print = function() end
end

describe('history #history', function()
  require("util.debug")

  local history
  local t = {
    { 'close_project()' },
    { 'project("clock")' },
    { 'run("turtle")' },
  }
  local t1 = t[1]
  local ok = false
  local cur = { '' }
  setup(function()
    history = History()
  end)

  it('caps the number of entries', function()
    local h = History(10)
    for i = 1, 15 do
      h:remember({ 'entry ' .. i })
    end
    assert.are_equal(10, h:length())
    assert.same({ 'entry 6' }, h:get(1))
    assert.same({ 'entry 15' }, h:get(10))
  end)

  it('treats 0 as unlimited', function()
    local h = History(0)
    for i = 1, 15 do
      h:remember({ 'entry ' .. i })
    end
    assert.are_equal(15, h:length())
  end)

  it('defaults the limit', function()
    assert.are_equal(1000, History().limit)
  end)

  it('keeps navigation position across eviction', function()
    local h = History(100)
    for i = 1, 100 do
      h:remember({ 'e' .. i })
    end
    h:history_back({ '' })
    local at = h:get(h.index)
    h:remember({ 'typed' })
    assert.same(at, h:get(h.index))
  end)

  it('remembers', function()
    history:remember(t1)
    local h1 = { t1 }
    assert.same(h1, history:_get_entries())
    history:remember(t[2])
    history:remember(t[3])
    assert.same(t, history:_get_entries())
  end)
  it('recalls', function()
    --- go back
    assert.same(t, history:_get_entries())
    assert.same(nil, history.index)
    ok, cur = history:history_back()
    assert.same(3, history.index)
    assert.is_true(ok)
    assert.same(t[3], cur)
    ok, cur = history:history_back()
    assert.same(2, history.index)
    assert.is_true(ok)
    assert.same(t[2], cur)
    ok, cur = history:history_back()
    assert.same(1, history.index)
    assert.is_true(ok)
    assert.same(t[1], cur)
    --- bottoms out
    ok, cur = history:history_back()
    assert.same(1, history.index)
    assert.is_false(ok)

    --- now go fwd
    ok, cur = history:history_fwd()
    assert.same(2, history.index)
    assert.is_true(ok)
    assert.same(t[2], cur)
    ok, cur = history:history_fwd()
    assert.same(3, history.index)
    assert.is_true(ok)
    assert.same(t[3], cur)
    --- no more items
    ok, cur = history:history_fwd()
    assert.same(3, history.index)
    assert.is_false(ok)
    assert.same(nil, cur)
  end)
end)

-- End-to-end, the way a user reaches it: the console input is
-- single-line, so Up hits the vertical limit at once and the
-- widget reports that through on_limit_reached, which the
-- console maps to history_back
-- (doc/development/decisions/input.md, D-EDIT-CALLBACKS).
describe('console history navigation #input #history',
  function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  it('Up at the vertical limit recalls the last entry',
    function()
    F.console.model.history:remember({ 'foo' })
    F.session.press('up')
    assert.same({ 'foo' }, F.console:get_text())
  end)
end)
