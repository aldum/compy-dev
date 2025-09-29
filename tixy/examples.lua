-- ==================[ FILE: examples.lua ]==================
-- Teaching note:
-- Each example has two short fields: code and legend.

examples = {}

local function example(code_str, legend_str)
  table.insert(
    examples,
    { code = code_str, legend = legend_str }
  )
end

example(
  "return b2n(math.random() < 0.1)",
  "for every dot return 0 or 1 \n" ..
  "to change the visibility"
)

example(
  "return math.random()",
  "use a float between 0 and 1 \n" ..
  "to define the size"
)

example(
  "return sin(t)",
  "parameter `t` is the time in seconds"
)

example(
  "return i / 256",
  "param `i` is the index of the dot (0..255)"
)

example(
  "return x / count",
  "`x` is the column index from 0 to 15"
)

example(
  "return y / count",
  "`y` is the row, also from 0 to 15"
)

example(
  "return y - 7.5",
  "positive numbers are white, negatives are red"
)

example(
  "return y - t",
  "use the time to animate values"
)

example(
  "return y - 4 * t",
  "multiply the time to change the speed"
)

example(
  "return ({1,0,-1})[i % 3 + 1]",
  "create patterns using different color"
)

example(
  "local dx=x-7.5\n" ..
  "local dy=y-6\n" ..
  "local r=sqrt(dx^2+dy^2)\n" ..
  "return sin(t-r)",
  "skip `math.` to use `sin`, `pi` etc."
)

example("return sin(y/8 + t)", "more examples ...")
example("return y - x", "simple triangle")

example(
  "local a=(y>x)\n" ..
  "local b=(14-x<y)\n" ..
  "return b2n(a and b)",
  "quarter triangle"
)

example("return i % 4 - y % 4", "pattern")

example(
  "local gx=n2b(math.fmod(x,4))\n" ..
  "local gy=n2b(math.fmod(y,4))\n" ..
  "return b2n(gx and gy)",
  "grid"
)

example(
  "return b2n(x>3 and y>3 and x<12 and y<12)",
  "square"
)

example(
  "local l=(x>t)\n" ..
  "local t0=(y>t)\n" ..
  "local r=(x<15-t)\n" ..
  "local b=(y<15-t)\n" ..
  "return -1*b2n(l and t0 and r and b)",
  "animated square"
)

example("return (y-6) * (x-6)", "mondrian squares")

example(
  "local vy=floor(y-4*t)\n" ..
  "local vx=floor(x-2-t)\n" ..
  "return vy*vx",
  "moving cross"
)

example("return band(4*t, i, x, y)", "sierpinski")

example(
  "return y==8 and band(t*10,lshift(1,x)) or 0",
  "binary clock"
)

example("return random()*2-1", "random noise")
example("return sin(i^2)", "static smooth noise")

example(
  "local p=t+i+x*y\n" ..
  "return cos(p)",
  "animated smooth noise"
)

example(
  "local a=sin(x/2)\n" ..
  "local b=sin(x-t)\n" ..
  "return a-b-y+6",
  "waves"
)

example(
  "local dx=x-8\n" ..
  "local dy=y-8\n" ..
  "local s=sin(t)*64\n" ..
  "return dx*dy-s",
  "bloop bloop bloop"
)

example(
  "local a=t%10\n" ..
  "local b=t%8\n" ..
  "local c=t%2\n" ..
  "local r=hypot(x-a,y-b)\n" ..
  "local d=r-c*9\n" ..
  "return -.4/d",
  "fireworks"
)

example("return sin(t - hypot(x, y))", "ripples")

example(
  "local k=band(y+t*9,7)\n" ..
  "local v=({5463,2194,2386})[k] or 0\n" ..
  "local m=lshift(1,x-1)\n" ..
  "return band(v,m)",
  "scrolling TIXY"
)

example("return (x-y) - sin(t) * 16", "wipe")
example("return (x-y)/24 - sin(t)", "soft wipe")
example("return sin(t*5) * tan(t*7)", "disco")

example(
  "local cx=count/2\n" ..
  "local dx=x-cx\n" ..
  "local dy=y-cx\n" ..
  "local r2=dx^2+dy^2\n" ..
  "return r2-15*cos(pi/4)",
  "日本"
)

example(
  "local dx = x - 5\n" ..
  "local dy = y - 5\n" ..
  "local r2 = dx^2 + dy^2\n" ..
  "return r2 - 99 * sin(t)",
  "create your own!"
)
