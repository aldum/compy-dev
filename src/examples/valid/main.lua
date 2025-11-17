r = user_input()

-- Checks minimum length (unicode-aware)
function min_length(n)
  return function(s)
    local l = string.ulen(s)
    if n < l then
      return true
    end
    return false, Error("too short!", l)
  end
end

-- Checks maximum length inclusive (unicode-aware)
function max_length(n)
  return function(s)
    if string.ulen(s) <= n then
      return true
    end
    return false, Error("too long!", n + 1)
  end
end

-- Verifies all characters are uppercase (clear + short)
function is_upper(s)
  local function is_up(c)
    return c == string.upper(c)
  end
  local ok, err_c = string.forall(s, is_up)
  if ok then
    return true
  end
  return false, Error("should be all uppercase", err_c)
end

-- Verifies all characters are lowercase (helper-based)
function is_lower(s)
  local ok, err_c = string.forall(s, Char.is_lower)
  if ok then
    return true
  end
  return false, Error("should be lowercase", err_c)
end

-- Checks signed integer form: optional '-' + digits
function is_number(s)
  local sign = string.usub(s, 1, 1)
  local offset = 0
  if sign == '-' then
    offset = 1
  end
  local digits = string.usub(s, 1 + offset)
  local ok, err_c = string.forall(digits, Char.is_digit)
  if ok then
    return true
  end
  return false, Error("NaN", err_c + offset)
end

-- Natural integer (>= 0). Returns true on success.
function is_natural(s)
  local is_num, err = is_number(s)
  if not is_num then
    return false, err
  end
  local n = tonumber(s)
  if n < 0 then
    return false, Error("It's negative!", 1)
  end
  return true
end

-- Demo loop: ask for input with validations; else echo
function love.update()
  if r:is_empty() then
    validated_input({
      min_length(2),
      is_lower
    })
  else
    print(r())
  end
end
