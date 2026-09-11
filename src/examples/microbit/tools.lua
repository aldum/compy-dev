-- micro:bit tools. Load them into the console with
-- require("tools"); every function below becomes a command.
--
-- The board is a micro:bit with the Lua REPL firmware, on
-- USB. Everything it prints arrives through compy.serial and
-- is shown by echo(), which the console has of its own;
-- everything sent to it leaves the same way. The REPL is a
-- terminal: it ends its lines with CR, and it echoes every
-- character it receives.
--
-- Typing to the board is the "terminal" project; these are
-- the commands around it — feed it a file, run one.

local serial = compy.serial

local EXEC_PREFIX = "assert(loadstring [[\r"
local EXEC_SUFFIX = "]])()\r"
local EXEC_MARKER = "]])()"

-- send, exec --------------------------------------------------

--- A project file, ready for the REPL: CR line endings and a
--- CR at the end, so the last line is entered too
--- @param filename string
--- @return string
local function fileForBoard(filename)
  local text = assert(readfile(filename), "no " .. filename)
  local cr = text:gsub("\r\n", "\n"):gsub("\n", "\r")
  if cr:sub(-1) ~= "\r" then cr = cr .. "\r" end
  return cr
end

--- Send a project file to the board, line by line, as if
--- typed
--- @param filename string
function send(filename)
  assert(serial.send(fileForBoard(filename)))
end

--- Whether echo was showing when exec started
local showing = false

--- Stay silent until the board has echoed the marker, then
--- hand what followed, and all that comes after, back to echo
--- @param marker string
--- @return function
local function silentUntil(marker)
  local heard = ""
  return function(chunk)
    heard = heard .. chunk
    local _, at = heard:find(marker, 1, true)
    if not at then return end
    if not showing then return echo(false) end
    echo()
    serial.onBytes(heard:sub(at + 1))
  end
end

--- Run a project file on the board as one chunk, wrapped in
--- assert(loadstring [[ ... ]])(). The board echoes every byte
--- it receives; that echo is held back while the file is in
--- flight, the program's own output comes through.
--- @param filename string
function exec(filename)
  local body = fileForBoard(filename)
  local code = EXEC_PREFIX .. body .. EXEC_SUFFIX
  showing = serial.onBytes ~= nil
  serial.onBytes = silentUntil(EXEC_MARKER)
  assert(serial.send(code))
end

-- help --------------------------------------------------------

function help()
  print("micro:bit tools")
  print("  help()                    this list")
  print("  echo(on)                  board output in the")
  print("                            console; echo(false)")
  print("                            stops it, echo() resumes")
  print("  send(filename)            file to the board,")
  print("                            as typed")
  print("  exec(filename)            file to the board,")
  print("                            run as one chunk")
  print("")
  print("Write the files with edit(filename), type to the")
  print("board in the \"terminal\" project.")
end

echo()
help()
