# Input validation (Compy-friendly Lua)

This project demonstrates how to **validate user input** in Lua, 
following Compy formatting rules:

* Maximum line length: 64 characters  
* Functions and tables: ≤ 14 lines  
* ≤ 4 arguments per function  
* Nesting level: ≤ 4  
* No complex inline expressions  
* Code must be clear and pedagogical  

---

## Usage

```lua
r = user_input()

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
````

Here:

* If no input is present, the program **prompts** with validation.
* Otherwise, it **prints** the entered value.

---

## Validators

### Minimum length

```lua
-- Checks that the string has more than n characters
function min_length(n)
  return function(s)
    local l = string.ulen(s)
    if n < l then
      return true
    end
    return false, Error("too short!", l)
  end
end
```

### Maximum length

```lua
-- Checks that the string is at most n characters long
function max_length(n)
  return function(s)
    if string.ulen(s) <= n then
      return true
    end
    return false, Error("too long!", n + 1)
  end
end
```

### All uppercase

```lua
-- Verifies every character is uppercase
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
```

### All lowercase

```lua
-- Verifies every character is lowercase
function is_lower(s)
  local ok, err_c = string.forall(s, Char.is_lower)
  if ok then
    return true
  end
  return false, Error("should be lowercase", err_c)
end
```

### Signed integer

```lua
-- Checks for integer with optional minus sign
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
```

### Natural number

```lua
-- Checks that the number is non-negative
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
```

---

## Helpers available

* `string.ulen(s)` — unicode length
* `string.usub(s, from, to)` — unicode substring
* `string.forall(s, f)` — apply predicate `f` to each character
* `Char.is_alpha(c)` — is letter
* `Char.is_alnum(c)` — is alphanumeric
* `Char.is_lower(c)` — is lowercase
* `Char.is_upper(c)` — is uppercase
* `Char.is_digit(c)` — is digit
* `Char.is_space(c)` — is whitespace
* `Char.is_punct(c)` — punctuation

---

## Notes

* Validations are passed **as functions**, not called immediately.
* Errors highlight the location of the problem character.
* Designed for teaching: each function is short, commented, and
  formatted for readability.

