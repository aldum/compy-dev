-- terminal — a serial terminal for the micro:bit.
--
-- What the board says appears above, what you type below
-- goes to it. The board runs the Lua REPL firmware: it ends
-- its lines with CR and echoes every character it receives,
-- so what you see above is its echo followed by its answer.
--
-- Whatever is typed is sent as is; the field does not check
-- it, because what is valid is up to the board.

local utf8 = require("utf8")
local serial = compy.serial
local input = compy.input

local PROMPT = "Lua> "
local SETTLE_S = 0.2

-- The board ends a line with CR, and an echoed one with
-- CR CR LF. Whatever the mix, it means one new line.
--- @param chunk string
--- @return string
local function asLines(chunk)
  return (chunk:gsub("\r+\n", "\n"):gsub("\r", "\n"))
end

--- The board sends a few stray bytes on connect, and the
--- terminal takes UTF-8 only: utf8.codes raises on anything
--- else. Drop the offending byte and look again, the way the
--- input model sanitises what it is given.
--- @param chunk string
--- @return string
local function asText(chunk)
  local text = chunk
  local ok, bad = utf8.len(text)
  while not ok do
    text = text:sub(1, bad - 1) .. text:sub(bad + 1)
    ok, bad = utf8.len(text)
  end
  return text
end

-- A prompt arrives without a line ending and so does the
-- start of a long answer. Whole lines go out as they come;
-- what is left over waits a moment, in case the rest of the
-- line is still on its way, and then goes out too — through
-- io.write, which leaves the line open for it.
local tail = ""
local settle = 0

serial.onBytes = function(chunk)
  tail = tail .. asText(asLines(chunk))
  while true do
    local line, rest = tail:match("^([^\n]*)\n(.*)$")
    if not line then break end
    print(line)
    tail = rest
  end
  settle = SETTLE_S
end

function love.update(dt)
  if tail == "" then return end
  settle = settle - dt
  if settle <= 0 then
    io.write(tail)
    tail = ""
  end
end

serial.onConnect = function(info)
  print("[connected " .. tostring(info and info.name) .. "]")
end

serial.onDisconnect = function()
  print("[disconnected]")
end

if serial.isConnected() then
  print("[board already connected]")
else
  print("[plug the micro:bit in]")
end

-- What was typed, the way the REPL reads it: CR ends a line.
-- The prompt above was written with the line left open and
-- the typed text has just landed on it, so close it: what
-- the board says next starts on a line of its own.
--- @param text string
local function sendLine(text)
  io.write("\n")
  local cr = text:gsub("\n", "\r")
  local ok, err = serial.send(cr .. "\r")
  if not ok then
    print("[send failed: " .. tostring(err) .. "]")
  end
end

input.callbacks.after_submit = input.clear

input.show{
  prompt = PROMPT,
  highlighter = LuaHighlighter,
  on_text_entered = sendLine,
}
