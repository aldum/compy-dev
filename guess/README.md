Guess (Compy-style)

A tiny “guess the number” game that demonstrates clear naming,
small functions, and predictable formatting so the built-in
editor won’t touch it.



What the game does

The program picks a hidden number between 1 and MAX_NUM.

You enter guesses; the game says higher / lower.

On a correct guess, it starts a new round automatically.

Controls & I/O

Input is read via the provided user_input()/validated_input(...).

All messages are printed with print(...).

No extra keys required.

Note: the host environment is expected to provide
user_input() and validated_input(...).

Initialization

We seed the random generator once (for variety across runs) and start
a new round. Both steps live in small helpers so they’re easy to reuse.

local MAX_NUM = 100

local S = {
  input = user_input(),
  target = 0
}

local function init_game()
  print("Welcome to the guessing game!")
  math.randomseed(os.time())
  S.target = math.random(MAX_NUM)
end

init_game()

Input & validation

Validation is explicit and didactic: parse, range-check, integer-check.
No dense one-liners, no magic.
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


Game loop

Short and flat: read input, validate, compare, and either hint or reset.
local function check_guess(n)
  if not n then
    return
  end
  if S.target < n then
    print("The number is lower")
  elseif n < S.target then
    print("The number is higher")
  else
    print("Correct!")
    print("")
    init_game()
  end
end

function love.update()
  if S.input:is_empty() then
    validated_input({ parse_positive_int }, "Guess a number:")
  else
    local s = S.input()
    local ok, v = parse_positive_int(s)
    if ok then
      check_guess(v)
    else
      print(v) -- error message
    end
  end
end

