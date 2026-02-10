--- @diagnostic disable: duplicate-set-field, lowercase-global
r = user_input()

x = 0
y = 150
t = 0
l = 0

getColor = function(bonus)
  if bonus then
    return Color[Color.blue]
  end
  return Color[Color.black]
end

function love.update(dt)
  t = t + dt
  if math.floor(t) > l then
    Log.debug('circ', x, y)
    l = math.floor(t)
    gfx.setColor(getColor())
    gfx.circle('line', x, y, 25)
    if x < gfx.getWidth() then
      x = x + 25
    else
      x = 0
      y = y + 25
    end
  end
  if r:is_empty() then
    input_text()
  else
    print(r())
  end
end

function love.mousepressed()
  Log.debug('mouse')
  gfx.setColor(getColor(true))
  gfx.circle('fill', x, y, 25)
  gfx.circle('line', x, y, 25)
end
