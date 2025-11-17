

local r = user_input()

function love.update()
  -- If there is no user text, ask for input
  if not r or r:is_empty() then
    input_text()
    return
  end

  -- Avoid complex inline expressions: read then print
  local value = r()
  print(value)
end
