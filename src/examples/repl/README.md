
# REPL

This project provides an example of the **minimum code** required for  
utilizing the builtin user input helper. It also demonstrates taking  
control of application updates by overriding `love.update`.

The project is very light on functionality: it only echoes the text  
the user enters.

---

## Using user input

Reading values from console is inherently asynchronous.  
The result is not available at the point of declaring the variable.  

Therefore the workflow has to consist of several steps:

1. **Create a handle**  
2. **Prompt the user if empty**  
3. **Read the value when available**

### Example

```lua
-- create a handle
local r = user_input()

-- custom update routine
function repl()
  if not r or r:is_empty() then
    -- prompt the user for text
    input_text()
    return
  end

  -- read the value and echo it
  local input = r()
  print(input)
end
````

Two helper functions are available:

* `input_text()` for plaintext input
* `input_code()` which only accepts syntactically valid Lua
  (Validated input is not discussed here, see the 'valid' project.)

---

## Update loop

To create interactivity, a program needs to run continuously,
waiting for input and reacting to it.

In LOVE2D this is achieved by overriding `love.update`.
By defining it, we control what happens as time passes.

```lua
function love.update()
  repl()
end
```

> Note: `love.update` can take a `dt` argument (delta time in seconds),
> but in this minimal REPL example it is not used.

---

## Summary

This project shows:

* how to hook into the user input helper
* how to separate prompting from reading values
* how to override `love.update` to create a simple REPL loop

The result is a minimal echo program:
whatever the user types gets printed back.


