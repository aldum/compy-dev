## Reference Material

**Do not load these files proactively** — read on demand only.

- `doc/development/conventions/code.md` — formatting and style conventions
- `doc/development/conventions/architecture_principles.md` — design philosophy
- `doc/development/conventions/git.md` — commit message conventions
- `doc/development/overview.md` — MVC structure, OOP patterns, modes, evaluation pipeline
- `doc/development/drawing_system.md` — virtual canvas, pen-and-paper vs real-time draw
- `doc/development/internals/` — console, editor, user input, examples (detailed subsystem docs)

## What This Is

**Compy** is a console-based, Lua-programmable fantasy computer for children, built on the [LÖVE2D](https://love2d.org) framework (v11.5). MVC architecture, classes as Lua globals, Lua 5.1/LuaJIT. Runs as an IDE, a project player, or a test harness. See `doc/development/overview.md` for architecture details.

## Commands

### Running

```sh
love src                  # IDE mode
love src test [--auto] [--size] [--draw]   # test mode
love src play <proj>      # run a project or .compy zip
love src harmony          # screenshot testing mode
```

### Tests

```sh
busted tests              # run all
busted tests --tags <tag> # by tag (common: ast, src, parser, analyzer)
just ut <TAG>             # run once for one tag
just ut_all               # run all once
just unit_test            # all, with nodemon auto-reload
just unit_test_tag <TAG>  # one tag, auto-reload
```

### Development

```sh
just dev          # run app with auto-reload on .lua changes
just dev-atest    # run app with --auto test on each change
```

### Packaging & Setup

```sh
just package              # dist/game.love
just package-js           # web version via love.js
just setup-web-dev        # install web tooling (npm)
just deploy-examples      # copy examples to ~/Documents/compy/projects
git clone --recurse-submodules  # required: two submodules (metalua, stringutils)
luarocks --local --lua-version 5.1 install busted luautf8 luafilesystem
```

### Environment Variables

| Variable | Effect |
|---|---|
| `DEBUG=1` | Debug mode (extra keybindings, draw overlays) |
| `HIDPI=true` | Double-scale display |
| `COMPY_PROF=1` | Enable profiler |
| `COMPY_WRAP=<n>` | Override drawable char width (debug mode) |
| `COMPY_LINES=<n>` | Override visible line count (debug mode) |

### Pre-commit Hook

`just setup-hooks` installs a hook that runs `busted tests` before every commit.
