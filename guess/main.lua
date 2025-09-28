-- main.lua
-- Guess-the-number: clear, didactic, Compy-friendly.

local MAX_NUM = 100

-- Local state, no globals.
local S = {
  input = user_input(),
  target = 0
}

local function say(msg)
  print(msg)
end

local function init_game()
  say("Welcome to the guessing game!")
  math.randomseed(os.time())
  S.target = math.random(MAX_NUM)
end

-- Accepts a string; returns (ok, n or err_msg)
local function parse_positive_int(s)
  local n = tonumber(s)
  if not n then
    return false, "Not a number"
  end
  if n <= 0 then
    return false, "Not a positive number"
  end
  if math.floor(n) ~= n then
    return false, "Not an integer"
  end
  return true, n
end

local function check_guess(n)
  if not n then
    return
  end
  if S.target < n then
    say("The number is lower")
  elseif n < S.target then
    say("The number is higher")
  else
    say("Correct!")
    say("")
    init_game()
  end
end

function love.update()
  if S.input:is_empty() then
    validated_input({ parse_positive_int }, "Guess a number:")
  else
    local s = S.input()
    local ok, val_or_err = parse_positive_int(s)
    if ok then
      check_guess(val_or_err)
    else
      say(val_or_err)
    end
  end
end

init_game()
