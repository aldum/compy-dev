### Turtle

Turtle graphics game inspired by the LOGO family of languages.  
It is in a very early stage and currently offers only a few features.

#### Multiple source files

The entry point for all projects is `main.lua`.  
For simple cases that might be all you need.  
For more complex ones like this, splitting code into smaller files 
improves readability and maintainability.

Doing this is quite simple: create a new file, then include it in
`main.lua` using `require()`.

Watch out for two pitfalls:
* The file should have a `.lua` extension, but when calling `require()`
  you must omit it.
* Do not declare variables or functions as `local` if you need to use
  them from other files.

Example in `main.lua`:
```lua
require('action')
````

This imports definitions from `action.lua` so they can be used in
`main.lua`. Code is organized by theme: what the turtle can do lives in
`action.lua`, while its presentation (how it is displayed) is in
`drawing.lua`.

#### Advanced drawing

Since we control the turtle programmatically, it also makes sense to
draw it programmatically using the graphics system’s transforms.
Instead of computing coordinates for every element, we first change the
coordinate system and then draw in its terms.

A minimal example: represent the turtle as an ellipse with major radius
`y_r` and minor radius `x_r`:

```lua
local x_r = 15
local y_r = 20
function turtleA(x, y)
  G.ellipse("fill", x, y, x_r, y_r, 100)
end
function turtleB(x, y)
  G.translate(x, y)
  G.ellipse("fill", 0, 0, x_r, y_r, 100)
end
```

Both draw at `(x, y)`. The second approach translates first, then draws
at `(0, 0)`. This pays off as transforms and shapes grow, because things
can get hard to track quickly.

###### Aside: Ellipses

An ellipse is a stretched circle with two axes: major (longest through
the center) and minor (shortest through the center).
In LOVE we pass an x-radius and a y-radius.
Here we want a body longer vertically and shorter horizontally, so `y`
is major and `x` is minor.

Next, add the head, positioned relative to the body and the local origin:

```lua
G.circle("fill", 0, ((0 - y_r) - head_r) + neck, head_r, 100)
```

With the translated coordinate system we give the head position in
“turtle coordinates”.

For legs drawn at an angle, LOVE’s ellipse function cannot rotate a
shape directly, so we rotate the coordinate system first.

Condensed example:

```lua
function frontLeftLeg(x, y, x_r, y_r, leg_xr, leg_yr)
  G.setColor(Color[Color.green + Color.bright])
  -- move to turtle position
  G.translate(x, y)
  -- move to leg anchor
  G.translate(-x_r, -y_r / 2 - leg_xr)
  -- rotate 45 degrees counter-clockwise
  G.rotate(-math.pi / 4)
  G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
end
```

###### Aside: Angles

`G.rotate` takes radians. A 45° angle equals `π / 4`.
A negative value rotates counter-clockwise.

##### Pushes and pops

In the final code leg functions use only one `translate()` because they
are already relative to the turtle (we translated once at the start).
Each leg is wrapped in a `push()`/`pop()` pair to restore the previous
transform before setting up the next leg:

```lua
-- left front leg
G.push("all")
G.translate(-x_r, -y_r / 2 - leg_xr)
G.rotate(-math.pi / 4)
G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
G.pop()
-- right front leg
G.push("all")
G.translate(x_r, -y_r / 2 - leg_xr)
G.rotate(math.pi / 4)
G.ellipse("fill", 0, 0, leg_xr, leg_yr, 100)
G.pop()
```

Think of `push()`/`pop()` like parentheses: they must balance.
Drawing runs every frame; each `push` stores state.
That’s fine if we always `pop()` and free it, otherwise we run out of
memory quickly.

#### Pause state

The refactored code includes a pause system.
Use `togglePause("optional message")` to pause/unpause the game.
When paused, `love.update()` stops processing and a semi-transparent
overlay is drawn. This keeps the logic simple and easy to follow.

### User documentation

How to use:

* Press **I** to open the console.
* Type commands: `forward`, `back`, `left`, `right`
  (or the short forms `fd`, `b`, `l`, `r`).
* Press **Pause** key to toggle pause.
* Press **Space** to toggle debug view.

