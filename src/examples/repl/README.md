### REPL

This project provides example of the minimum code required for utilizing the builtin user input helper. It also demonstrates taking control of application updates by overriding `love.update`.
The project is very light on functionality, only echoing the text the user enters.

#### Using user input

The process of reading values from console has a necessarily asynchronous nature to it. The result can not be available at the point of declaring the variable that holds it.
Hence, it has to consist of multiple steps: first, we create a handle; then initiate the prompt, and only when the user is finished, can we read the data supplied.

How this translates into code:

```lua
-- create a handle
r = user_input()

-- if it doesn't hold a value currently, prompt the user
function repl()
  if r:is_empty() then
    input_text()
  else
    -- read the value
    local input = r()
  end
end
```

There are two options available:
* `input_text()` for plaintext
* `input_code()` which only accepts syntactically valid lua
(Validated input is not discussed here, see the 'valid' project)

#### Update

To create interactivity, a program needs to run continuously, waiting for input and reacting to it.
In LOVE2D, this is achieved by overriding various handlers, the first of which is `update()`.
By defining `love.update()`, we can control what happens when time passes:

```lua
function love.update(dt)
  repl()
end
```
The parameter `dt` is the (fractional) number of seconds passed since the last run of the function.
