require('util.table')

--- The env is deep-cloned before a project runs, so the
--- live serial table must reach the clone by reference or
--- the program's handlers land where nothing reads them.
--- This mirrors how the namespace serves it: an upvalue
--- behind __index, refused by __newindex.

describe('compy.serial through an env clone', function()
  local function make_ns(serial)
    local serial_surface = serial
    local ns = { terminal = {} }
    return setmetatable(ns, {
      __index = function(t, k)
        if k == 'serial' then return serial_surface end
        return rawget(t, k)
      end,
      __newindex = function(t, k, v)
        if k == 'serial' then
          error('compy.serial is not assignable', 2)
        end
        rawset(t, k, v)
      end,
    })
  end

  local live, clone

  before_each(function()
    live = { send = function() return true end }
    clone = table.clone({ compy = make_ns(live) })
  end)

  it('survives the clone by reference', function()
    assert.are.equal(live, clone.compy.serial)
  end)

  it('lands a handler on the live table', function()
    clone.compy.serial.onLine = function() end
    assert.is_function(live.onLine)
  end)

  it('refuses replacing the table itself', function()
    assert.has_error(function()
      clone.compy.serial = {}
    end)
  end)
end)
