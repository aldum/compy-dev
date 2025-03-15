local sect =
[[### Section 1

`asd
bfg`

### Section 2

para
  ]]
local list = [[ ### List
* `inline`
* **bold**
* __bold__
* *italic*
* _italic_
* 3^4^
* H~2~O
]]

local link = [[
Link: [LÖVE2D](https://love2d.org) framework.
![search](./doc/interface/search.apng)
]]

local fst  = [[
A console-based Lua-programmable computer for children based on
the [LÖVE2D][löve2d] framework.
]]

local tmd  = [[
# Compy
]] .. fst .. [[
## Principles

- Command-line based UI
- Full control over each pixel of the display
- Ability to easily reset to initial state
- Impossible to damage with non-violent interaction
- Syntactic mistakes caught early, not accepted on input
- Possibility to test/try parts of program separately
- Share software in source package form
- Minimize frustration
  ]]

local refs = [[

[löve2d]: https://love2d.org

]]
local fmd  = tmd .. [[
### Projects

A _project_ is a folder in the application's storage which
contains at least a `main.lua` file. Projects can be loaded and
ran. At any time, pressing <kbd>Ctrl-Shift-Q</kbd> quits and
returns to the console

- `list_projects()`

  List available projects.

#### Searching

Definitions can be searched with <kbd>Ctrl-F</kbd>. Pressing
this combination switches to search mode, in which the
definitions are listed, and there's a highlight, which can be
moved as usual. Hitting <kbd>Enter ⏎</kbd> returns to editing,
highlighting the selected definition. To exit search mode
without moving, press <kbd>Esc</kbd>.

![search](./doc/interface/search.apng)

#### UTF-8

* авл ждл

]]
    .. list ..
    refs

local code = [[
text:

```lua
local function pad(i)

end
function getTimestamp()
end
```
]]

return {
  sect,
  list,
  fmd,
  link,
  fst .. refs,
  code,
}
