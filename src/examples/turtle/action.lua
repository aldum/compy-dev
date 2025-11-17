--- @diagnostic disable: duplicate-set-field,lowercase-global
-- Simple movement and pause actions for the turtle.
-- Uses globals: tx, ty, incr, is_paused, pause_message.

function moveForward(d)
  ty = ty - (d or incr)
end

function moveBack(d)
  ty = ty + (d or incr)
end

function moveLeft(d)
  tx = tx - (d or (2 * incr))
end

function moveRight(d)
  tx = tx + (d or (2 * incr))
end

function togglePause(msg)
  -- Toggle pause state and remember the message.
  is_paused = not is_paused
  pause_message = msg or "user paused the game"
end

actions = {
  forward = moveForward,
  fd = moveForward,
  back = moveBack,
  b = moveBack,
  left = moveLeft,
  l = moveLeft,
  right = moveRight,
  r = moveRight,
  pause = togglePause
}
