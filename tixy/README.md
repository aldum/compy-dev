# README.md 

## tixy

Reimplementation of [tixy.land](https://tixy.land/), a javascript project.
The idea is to drive a 16×16 duotone dot matrix display by defining a function, which gets evaluated for each individual pixel and over time.

Input parameters to the function are: `t, i, x, y`, (hence the name):

* `t` – time (in seconds)
* `i` – index of the pixel (0..255)
* `x` – horizontal coordinate (column)
* `y` – vertical coordinate (row)

---

### Multiple source files

See the `turtle` project for detailed explanation.

---

### Math

`math.lua` does a couple of things:

* defines a `hypot()` function – missing from stock Lua, but used in many examples
* imports the `math` module contents into the global namespace for brevity
* imports the `bit` library **safely with `pcall`** (not every environment has it, Compy included)

```lua
local ok, bitlib = pcall(require, "bit")
if ok and bitlib then
  for k, v in pairs(bitlib) do
    _G[k] = v
  end
end
```

This way, code still runs even if bit operations are unavailable.

---

### Function body and compilation

To allow interactive code editing, we take the text from the user (or examples), and turn it into a function:

```lua
function setupTixy()
  local head = "return function(t, i, x, y)\n"
  -- FIX: normalize literal "\\n" into real newlines
  local src = tostring(body):gsub("\\n", "\n")
  local code = head .. src .. "\nend"
  local f = loadstring(code)
  if not f then return end
  setfenv(f, _G)
  tixy = f()
end
```

This ensures that examples using `\n` work correctly.
Without this, switching examples would silently fail.

---

### Boolean helpers

Lua is strict about types, so we explicitly convert:

```lua
function b2n(b)
  if b then return 1 else return 0 end
end

function n2b(n)
  if n ~= 0 then return true else return false end
end
```

---

### Math helpers

`tixy` returns a number, which controls pixel radius.
Negative numbers become red pixels; large values are clamped:

```lua
function clamp(value)
  local color = colors.pos
  local radius = (value * size) / 2
  if radius < 0 then
    radius = -radius
    color = colors.neg
  end
  if radius > size / 2 then
    radius = size / 2
  end
  return color, radius
end
```

---

### Drawing

We draw each pixel twice: once filled, once outlined.
This is a simple trick to get antialiasing (smooth edges):

```lua
function drawCircle(color, radius, x, y)
  G.setColor(color)
  local step = size + spacing
  local sx = x * step + offset
  local sy = y * step + offset
  G.circle("fill", sx, sy, radius)
  G.circle("line", sx, sy, radius)
end
```

---

### Mouse handling

We only need the button info:

```lua
function love.mousepressed(_, _, button)
  if button == 1 then
    if Key.shift() then prev_example()
    else next_example() end
  end
  if button == 2 then
    randomize()
  end
end
```

* left click → next example
* shift + left click → previous example
* right click → random example

---

### Examples file

`examples.lua` contains all the demos.
Each uses **real newlines (`\n`)**, not `\\n`.
This makes them compile directly with `loadstring`.

```lua
example(
  "local dx = x - 5\n" ..
  "local dy = y - 5\n" ..
  "local r2 = dx^2 + dy^2\n" ..
  "return r2 - 99 * sin(t)",
  "create your own!"
)


--### How to add your own example

The file `examples.lua` is where all examples live.
Each example has two fields:

1. the **code string** (what will be turned into the `tixy` function),
2. the **legend** (a short description shown on screen).

We use the helper function `example(code, legend)` to insert new ones.

#### Step 1: Write your code

The function body must be valid Lua. It receives four parameters:
`t` (time), `i` (index), `x` (column), `y` (row).

For example, let’s draw a moving vertical bar:

```lua
local code = 
  "return b2n(x == floor(t % count))"
```

This code makes all pixels in the column `t % count` visible.

#### Step 2: Add a legend

Write a short description to remind yourself what it does:

```lua
local legend = "a vertical bar moving across the screen"
```

#### Step 3: Insert into `examples.lua`

At the bottom of `examples.lua`, add:

```lua
example(
  "return b2n(x == floor(t % count))",
  "a vertical bar moving across the screen"
)
```

Make sure to use **real newlines** (`\n`) if your code has multiple lines.

#### Step 4: Test it

Restart the program.
Click through the examples with left mouse button until you see yours.
If it doesn’t show up, check for syntax errors in your code string.

---

💡 **Tips:**

* Start simple: `return x`, `return y`, `return sin(t)`.
* Try combining math: `return sin(t - hypot(x, y))`.
* Use helpers: `b2n()`, `n2b()`, and `hypot()`.
* Don’t worry if the first try fails — the editor will let you fix it quickly.

