# Console Mode — Implementation Overview

Console mode is the default application state — active when no project is running and the editor is not open. It presents the user with a REPL-like interface: type Lua, press Enter, see results. It is also the lifecycle manager for projects: opening, running, suspending, stopping, and closing them.

---

## App State Machine

`love.state.app_state` drives what the application does on each frame:

| State | Meaning |
|---|---|
| `ready` | No project open, console REPL active |
| `project_open` | Project opened but not running |
| `running` | Project's main.lua is executing (handlers set) |
| `snapshot` | Transition: screenshot requested, about to suspend |
| `inspect` | Project suspended (paused); console REPL active over frozen project state |
| `editor` | Editor is open |
| `shutdown` | Quitting |

Key transitions not obvious from the state table:

| Transition | Trigger |
|---|---|
| `running → editor` | Ctrl+T (quickswitch) while running |
| `editor → running` | Ctrl+T while in editor (normal mode) |
| `editor → inspect` | `finish_edit()` when project was running before edit was opened |
| `inspect → editor` | `edit()` called while in inspect |

The full machine is diagrammed in `doc/mermaid/fsm.md` and `doc/mermaid/fsm_f.md`.

The `snapshot` state is a one-frame transition: on the next `update()` tick, LÖVE2D captures a screenshot, stores it as `View.snapshot`, and then calls `ConsoleController:suspend()` which switches to `inspect`. The snapshot is drawn as a background behind the console UI during inspect, giving the user a "freeze frame" view of where the project stopped.

---

## Three Environments

This is the most non-obvious architectural decision in the console. There are three Lua environments (tables used as `fenv`):

**`main_env`** — the live console environment. Code typed into the REPL runs here. Contains the full API: project management commands, file I/O, `compy`, `gfx`, etc. Mutated by user REPL commands.

**`base_env`** — a frozen snapshot of `project_env` at project-open time. Protected with `table.protect()` (writes are blocked). Serves as the clean baseline that `project_env` is reset to when a project is stopped without closing.

**`project_env`** — the mutable environment in which a project's code runs. Started as a clone of `base_env`, then the project's own `require`/`dofile` calls and global assignments accumulate here. Reset to `base_env` on `_reset_executor_env()`.

The reason for `base_env` vs `project_env`: restarting a project (`Ctrl+Alt+R`) should give it a clean global table, but reopening the project should not — the distinction allows "reset project state" without "close and reopen".

Sources: `prepare_env` and `prepare_project_env` (consoleController.lua:341 and 482), `_set_base_env`, `_reset_executor_env`.

---

## Console Input Evaluation

When Enter is pressed in the REPL (`ConsoleController:keypressed`, line 1009):

1. `evaluate_input()` is called
2. The input text is validated via the `Evaluator` (LuaEval — parse via metalua)
3. If parse succeeds: `codeload(code, run_env)` compiles the string into a chunk with the appropriate `fenv` (console env normally; project env during `inspect`)
4. `run_user_code(f, self)` executes the chunk inside `use_canvas` — so any `gfx.*` calls go to the virtual canvas
5. Output from `print()` goes to the terminal via the `redirect_to` mechanism (set up in `src/main.lua`)
6. On success: input is cleared. On error: error is set on the input model and displayed in the status line.

During `inspect` state, the REPL runs code in `project_env`, allowing the user to inspect and mutate the paused project's state.

---

## Project Lifecycle

### Opening a project

`open_project(name)` (consoleController.lua:782):
- Closes any currently open project first
- Calls `ProjectService:opreate(name)` which opens an existing project or creates a new one with example code
- Registers a custom `package.loader` that loads modules from the project directory (prepended to `package.loaders` so it takes priority)
- Sets state to `project_open`

The custom loader is stored in `self.loaders[name]` so it can be removed on close.

### Running a project

`run_project(name)` (line 230):
- Calls `ProjectService:run()` which loads `main.lua` via the project's filesystem mount
- Sets state to `running`
- Calls `run_user_code(f, cc, path)` which: executes the chunk in `use_canvas`, then calls `set_user_handlers(env['love'], cc)` to detect and register any `love.*` event handlers the project defined
- If the project defines no blocking handlers (`love.draw`, `love.update`), state immediately returns to `project_open`

### Stopping vs suspending vs quitting

**`stop_project_run()`**: Clears user handlers, calls `evacuate_required()` to remove project modules from `package.loaded`, restores default draw, resets overlay input. State → `project_open`. The project's global state persists in `project_env` (can be inspected at the REPL).

**`suspend_run(msg)`**: Requests a snapshot. State → `snapshot` → `inspect` on next tick. Handlers saved; default handlers restored temporarily. User can inspect and continue.

**`continue()`**: Restores project handlers from the saved copy. State → `running`.

**`quit_project()`**: Calls `stop_project_run()` + `close_project()` + resets terminal and input. The environment is wiped.

### Module isolation

`evacuate_required()` (line 844) removes all project `.lua` filenames from `package.loaded` when stopping. This ensures that `require('helpers')` in the project will reload fresh on the next run, rather than returning the cached module from the previous run. Without this, mutated module state would leak between runs.

---

## The `user_input` Overlay

Projects can request live text input mid-run. This creates a second `UserInputModel` overlaid on top of the console. Three API variants:

```lua
r = user_input()          -- bare reference, project polls r:is_empty() / r()
r = input_text("prompt")  -- text evaluator
r = input_code("prompt")  -- Lua evaluator (syntax-highlighted)
r = validated_input({validators}, "prompt")  -- custom validation
```

Implementation: calling any of these creates a new `UserInputModel` + `UserInputController` + `UserInputView` and stores the triplet in `love.state.user_input`. The event dispatch in `love.handlers.keypressed` checks this: if set, key events go to the overlay controller, not the main console input.

The return handle `r` is a `reftable` — a callable table used as a mutable reference. Call it with a value to store (`ref(val)`), call it without arguments to retrieve (`ref()`). `r:is_empty()` returns true until a value is stored. Once the user submits, `r()` returns the value and `r:is_empty()` becomes true again (oneshot semantics). `write_to_input(content)` lets the project pre-fill the input.

The same `reftable` pattern appears in the test infrastructure (`tests/testutil.lua:get_save_function`) as a general-purpose mutable reference.

This is the standard pattern for interactive games that need live input (guess, turtle, tixy, repl). Only one overlay can exist at a time (`if love.state.user_input then return end`).

Source: `prepare_project_env` (line 555–611), `love.state.user_input` handling in `controller.lua` handlers.

---

## The `compy` Namespace

Projects receive a `compy` table with:

| Field | Contents |
|---|---|
| `compy.audio` | Sound effects (`sfx.beep()`, `sfx.gameover()`, etc.) — `src/util/audio.lua` |
| `compy.terminal` | VT-100 terminal control (`gotoxy`, `clear`, `show_cursor`, `hide_cursor`) |
| `compy.graphics` | Extended graphics (`shape2d`) — `src/util/graphics/shape2d.lua` |
| `compy.fonts` | Font path constants (`mono`, `sans`, `serif`, etc.) — `src/util/namespace/fonts.lua` |
| `compy.text_input` | Alias for `input_text` (project env only) |

`compy.terminal` wraps the VT-100 terminal instance directly (the same terminal that renders the console output). Projects can use it for text-mode output within their run context.

---

## Key Files

| File | Role |
|---|---|
| `src/controller/consoleController.lua` | Everything: env setup, project lifecycle, REPL eval, overlay input API |
| `src/model/consoleModel.lua` | Model aggregate (input, editor, output canvas, project service) |
| `src/model/project/project.lua` | `ProjectService` and `Project` — open/run/close, file I/O, filesystem mount |
| `src/model/io/redirect.lua` | Redirects `print()` output to the terminal |
| `src/view/consoleView.lua` | Top-level view compositor |
| `src/util/audio.lua` | `compy.audio` sound effect library |
| `src/util/namespace/fonts.lua` | `compy.fonts` font path constants |
