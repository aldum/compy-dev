### Clock

Clock (Compy-style)

A tiny digital clock that demonstrates clear naming,
short functions, and predictable formatting so the built-in
editor won’t change a thing.

This version removes globals, avoids complex inline math, and keeps
nesting shallow. It’s meant as a didactic example you can copy and
extend.

How it works

We read the current time once and store it in a local state table.

Each frame, we add dt to the accumulator.

We derive HH:MM:SS via simple, readable steps (no dense one-liners).

We draw the timestamp centered on screen using a fixed font size.

Controls

Space — cycle foreground color.

Shift + Space — cycle background color.

Shift + R — reset to the current system time.

P — pause hook (provided by the host runtime).

Note: Color[...], Color.bright, and pause(...) are assumed to be
provided by the host environment.

Style guide we follow (Compy)

Max line length: 64 characters.

Max function length: 14 lines.

Max args per function: 4.

Max nesting depth: 4.

Avoid complex inline expressions: compute in steps.

No magic numbers: name constants.

Prefer local state: no globals, no lint suppressions.

Comments: brief and didactic (explain “why”, not “what”).

Key ideas, by example:
Centered draw with local state
-- Colors, background, and font come from local state S.
local text = make_timestamp(S.t)
local off_x = S.font:getWidth(text) / 2
local off_y = S.font:getHeight() / 2
G.print(text, MID_X - off_x, MID_Y - off_y)

Why this is “Compy-clean”:

 - short lines (≤ 64 chars);

 - no nested calls inside print;

 - variables have clear roles (off_x, off_y);

 - state is local (S.font, S.t)

 Time math in small steps:
 local function make_timestamp(tt)
  local hours_raw = math.floor(tt / HOURS_IN_T)
  local hours = math.fmod(hours_raw, DAY_HOURS)

  local mins_raw = math.floor(tt / TICKS)
  local minutes = math.fmod(mins_raw, TICKS)

  local seconds = math.fmod(math.floor(tt), TICKS)

  local hh = string.format("%02d", hours)
  local mm = string.format("%02d", minutes)
  local ss = string.format("%02d", seconds)

  return string.format("%s:%s:%s", hh, mm, ss)
end


No dense one-liners, no hidden precedence: everything reads like a recipe.