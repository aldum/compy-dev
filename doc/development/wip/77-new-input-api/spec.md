# Feature #77 — API Specification

*Contract that implementation is verified against.
Audience: implementors. Includes function signatures,
data structure formats, and edge case behaviour.*

*Design context: `design.md`. Stakeholder summary: `summaries/spec.md`.*

> **Status — derived proposal document.** This spec is a derived
> part of the feature-#77 proposal chain, pre-built on the
> assumption the design (`decisions.md` → `design.md`) is endorsed
> rather than vetoed. Its detail is not frozen: stakeholders may
> review or change parts without blocking implementation — there is
> no requirement to freeze the spec before work starts.

---

## 1. `keys_pressed` Table

### Format

A plain Lua table mapping LÖVE2D key name strings to `true`:

```lua
-- example: lctrl and s held simultaneously
{ ['lctrl'] = true, ['s'] = true }
```

Key names are LÖVE2D canonical names: `"lctrl"`, `"rctrl"`,
`"lshift"`, `"rshift"`, `"lalt"`, `"ralt"`, `"return"`,
`"escape"`, `"backspace"`, `"up"`, `"down"`, `"left"`,
`"right"`, `"f1"`–`"f12"`, printable key names (`"a"`–`"z"`,
`"0"`–`"9"`, `"space"`, etc.).

### Ownership and passing

The table is owned by `Controller` (global controller,
`controller.lua`). It is updated unconditionally on every
`love.handlers.keypressed` (add key) and
`love.handlers.keyreleased` (remove key) call, before any
downstream handler runs.

Downstream consumers — `ProjectController` and the project
callbacks — receive the table as a **read-only proxy**: an
iterator-only wrapper. Direct indexing on the proxy is not
supported; consumers iterate with `for k in pairs(proxy) do`.
This prevents project code from tampering with the live
modifier state.

The proxy is passed as the second argument to every
`keypressed` and `textinput` callback downstream:

```lua
ProjectController:keypressed(k, keys_pressed, isrepeat)
ProjectController:textinput(t, keys_pressed)
```

### Combo serialisation

A combo string is built by `combo_string(k, keys_pressed)`,
which takes the **triggering key** `k` and the held-key set.
It prepends any held command-modifiers in fixed precedence
order — `ctrl`, `alt`, `shift`, `gui` — then appends `k`.
Modifier names are **generic** (l/r folded): the combo uses
`ctrl` (not `lctrl`/`rctrl`), `alt` (not `lalt`/`ralt`), etc.
The `keys_pressed` table retains precise LÖVE key names; only
combo serialisation folds to generic names.

```lua
-- lctrl held, s triggers: "ctrl+s"
-- lalt and lshift held, f4 triggers: "alt+shift+f4"
-- escape alone: "escape"
-- s alone (bare key): "s"
```

Ordering is modifier-first by fixed precedence, then the
triggering key. A bare key (no modifiers held) produces just
the key name. `combo_string` is used at every dispatch point.

**Registration normalisation.** `compy.input.handlers` is
metatable-backed: `__newindex` normalises the assigned key to
canonical form on assignment, so `compy.input.handlers['Ctrl+S'] = fn`
is stored as `compy.input.handlers['ctrl+s']` and fires correctly.
Dispatch uses an **overloadable exact-match matcher** by default
(O(1) table lookup); the matcher function is project-overloadable
for future glob/prefix extensions.

---

## 2. `UserInputController` Singleton API

All interaction goes through the `compy` namespace. Project
code never holds a direct reference to the controller object.

### `compy.input.show(config)`

Activates the singleton with the given configuration.
`config` is an optional table; all fields are optional:

| Field | Type | Description |
|---|---|---|
| `prompt` | string | Label displayed beside the input area |
| `text` | string | Initial text content; cursor placed at end |
| `cursor` | `{line, col}` | Initial cursor position; 1-based source-line coordinates; applied after `text`; `line` defaults to 1 (single-line callers may pass just `{1, col}` or `{col}`) |
| `highlighter` | function | Syntax highlighter: `fn(text) → highlighted_text` |
| `validator` | function | Per-submit validator: `fn(text) → ok, err_msg` |
| `multiline` | boolean | Allow Shift+Enter newlines (default false) |

Calling `show()` while the singleton is already visible:
the singleton is reconfigured in-place with the new config.
No error is raised; no cancel chain fires; content is
replaced if `text` is provided, preserved otherwise.

`love.state.user_input` is set to the singleton instance
on `show()`.

### `compy.input.hide()`

Deactivates the singleton without firing the cancel chain.
Input content is preserved (subsequent `show()` will
display it unless `text` is provided). `love.state.user_input`
is set to `nil`. Project code uses `hide()` for programmatic
lifecycle management; the user-facing dismiss path is Escape
(which fires the cancel chain).

### `compy.input.configure(config)`

Live-updates the singleton's configuration while it is
active. Accepts the same fields as `show()`. Only the
provided fields are updated; unspecified fields are
unchanged. Safe to call when hidden (takes effect on next
`show()`).

Live-updatable fields: `prompt`, `highlighter`, `validator`.
Fields `text` and `cursor` are accepted but have no effect
when called on an already-active session (use `compy.input.clear()`
and `compy.input.show()` to reset content).

### `compy.input.clear()`

Clears the text content of the active input session without
hiding the singleton. Cursor resets to position 1. Does not
fire any callback. No-op if the singleton is hidden.

### `compy.input.get_cursor()`

Returns the current cursor position as two values `line, col`
(1-based source-line coordinates, not wrapped/apparent lines).
Returns `nil` when the singleton is hidden. Read-only; use
`compy.input.set_cursor` to change position.

### `compy.input.set_cursor(line, col)`

Sets the cursor to `(line, col)` — 1-based source-line
coordinates. The model clamps the values to the valid range.
No-op when the singleton is hidden. Single-line callers
always pass `line = 1`.

### `compy.input.set_text(text [, keep_cursor])`

Replaces the full text content of the active input session.
This is the **live-write surface** and the explicit exception
to `compy.input.configure()`'s text-immutability rule. If
`keep_cursor` is true, the cursor position is preserved (the
model's `set_text` skips the unconditional `jump_end()` when
`keep_cursor` is set). If omitted or false, the cursor moves
to the end of the new text. No-op when hidden. Triggers a
view update.

### Access control

No access control is enforced in this version. A project
calling `show()` while another subsystem is using the
singleton will reconfigure it. This is a known future
concern; it is not in scope for this feature.

---

## 3. Event Callbacks

All callbacks are fields on the `compy.input` table. The
submit/cancel/limit callbacks (`before_submit`, `after_submit`,
`before_cancel`, `after_cancel`, `on_limit_reached`) default to
a no-op function that emits a debug log entry. The two **channel
callbacks** (`on_key_pressed`, `on_text_entered`) are different:
their default value is the text-editing sink, not a no-op (see
each section below). Project code assigns replacement functions:

```lua
compy.input.on_text_entered = function(text, keys)
  -- ...
end
```

All callbacks are reset to their defaults when the project
stops, via `stop_project_run` / `clear_user_handlers`
(`consoleController.lua:860–868`).

### `compy.input.on_text_entered(text, keys_pressed)`

Fires when `love.textinput` delivers a character event and
the singleton is active.

- `text`: UTF-8 string delivered by the OS (one character in
  the common case; may be multiple characters from IME input).
- `keys_pressed`: read-only proxy of currently-held keys at
  the time the `keypressed` event that preceded this
  `textinput` fired. Non-character keys in this set are the
  implicit modifier context (e.g. if `"lctrl"` is in the set,
  the user pressed Ctrl+something that produced a character).

**Default value:** the textinput sink
(`UserInputController:textinput`). This mirrors `on_key_pressed`
exactly — the channel's default *is* the sink, and assigning a
function replaces it. The two channels follow the same
default-sink/override principle; the only difference is that the
textinput channel has no combo tier above it.

Does not fire for Ctrl+V paste (handled entirely via
`keypressed` → clipboard path).

*Future seam (not built in v1): a pre-folded `mods` string — the
generic l/r-folded modifier descriptor, like the combo form —
could be passed as a trailing argument to this and the other
downstream handlers, as a convenience over reading modifiers off
the `keys_pressed` proxy. v1 ships the proxy only; the `mods`
string is a candidate addition (see `decisions.md` D-6).*

### `compy.input.on_key_pressed(k, keys_pressed, isrepeat)`

Fires for every `love.keypressed` event while the singleton
is active — both character-producing and non-character keys.
This is the **keypressed channel**; the textinput channel is
`compy.input.on_text_entered` and is independent. Both channels
may fire for a single user gesture (a character key visits
both); there is no suppression. The expected division of
labour: command detection → combos / `on_key_pressed`;
text capture → `on_text_entered`.

- `k`: LÖVE2D key name string.
- `keys_pressed`: read-only proxy of currently-held keys.
- `isrepeat` (trailing arg): `true` if this is a key-repeat
  event, `false` otherwise. Passed last so the common
  `fn(k, keys)` signature remains clean for callers that do
  not need it.

**Default value:** the text-editing sink
(`UserInputController:keypressed`). Assigning a function to
`compy.input.on_key_pressed` replaces the default entirely. There
is no separate sink tier below it — the sink *is* the
default. If the default is replaced, `on_limit_reached` no
longer fires (it originates in the keypressed sink); the
project has taken over key handling.

To intercept specific key combinations before the sink, use
`compy.input.handlers[combo]` and return truthy.

### `compy.input.handlers[combo]`

A metatable-backed table mapping combo strings to handler
functions. Project code registers directly:

```lua
compy.input.handlers['ctrl+l'] = function(k, keys)
  clear_screen()
  return true  -- consumed; sink does not run
end
```

Handler signature: `fn(k, keys_pressed) → truthy|nil`

- `k`: the key name that triggered the dispatch.
- `keys_pressed`: read-only proxy.
- Return truthy to consume (stop the chain; sink does not run).
- Return nil or nothing to let the chain continue.

**Normalisation on assignment.** `compy.input.handlers` uses a
metatable: `__newindex` normalises the key to canonical form
(modifier-first, generic l/r folding) before storing it, so
`compy.input.handlers['Ctrl+S'] = fn` and `compy.input.handlers['ctrl+s'] = fn`
produce the same entry and fire correctly.

Dispatch uses `combo_string(k, keys_pressed)` to build the
current combo at event time, then passes it through the
**overloadable matcher** (default: exact canonical match).
The matcher is project-overloadable via
`compy.input.handlers.__matcher = fn` for future glob/prefix needs.

The same key in different modifier states produces different
combos: `"s"` and `"ctrl+s"` are distinct entries.

**Bare printable-key combos** (e.g. `handlers['s']`) do fire
on `keypressed`, alongside `on_text_entered`. The expected
convention is to reserve combos for command modifiers
(`ctrl`, `alt`, `gui`). Both channels fire by design; project
code picks the channel it needs.

### `compy.input.before_submit(keys_pressed)`

Fires before the framework evaluates the input. `keys_pressed`
is the read-only proxy at the time Enter was pressed.

Cannot suppress submit. Return value is ignored. Use for
pre-submit side effects (e.g. logging, visual feedback).

### `compy.input.after_submit(result)`

Fires after the framework has evaluated the input and pushed
`'userinput'`. `result` is the evaluated text string.

Fires only on successful evaluation. Does not fire if the
validator rejected the input (input stays locked with error
display until the user acknowledges and corrects it).

### `compy.input.before_cancel(keys_pressed)`

Fires before the framework dismisses the singleton via
Escape. `keys_pressed` is the read-only proxy at dismiss
time.

Cannot suppress cancel. Return value is ignored. Use for
pre-cancel side effects.

### `compy.input.after_cancel()`

Fires after the framework has dismissed the singleton
(`love.state.user_input` set to nil, content cleared).
No arguments.

---

## 4. `on_limit_reached(direction)`

```lua
compy.input.on_limit_reached = function(direction, _reserved)
  -- direction: 'up' or 'down'
end
```

Fires when the cursor attempts to move past the first or
last valid position in the input area (a whole-input
boundary, consistent with the existing `UserInputModel:is_at_limit`
implementation).

- `direction`: `'up'` when the cursor tries to move past
  the first line; `'down'` when it tries to move past the
  last line.
- Second argument `_reserved`: undefined in v1; reserved for
  future boundary-level granularity (e.g. line-level vs.
  input-level). Do not use.

The callback always propagates — both project code and
framework code observe the same boundary event independently.
Return value is ignored.

---

## 5. Legacy API Removal

D-1 was discarded by stakeholders (`input.md`, feedback round 1):
no backward compatibility. The legacy text-input globals are
**removed** from the project environment — not wrapped as facades:

| Removed function | Replacement |
|---|---|
| `user_input()` | None — the reftable / `is_empty()` polling idiom is gone. Submit is observed via `compy.input.after_submit(result)`. |
| `input_text(prompt, init)` | `compy.input.show({ prompt = prompt, text = init, validator = InputEvalText })` + `compy.input.after_submit` |
| `input_code(prompt, init)` | `compy.input.show({ prompt = prompt, text = init, highlighter = lua_hl, validator = InputEvalLua })` + `compy.input.after_submit` |
| `validated_input(fn, prompt)` | `compy.input.show({ prompt = prompt, validator = ValidatedTextEval(fn) })` + `compy.input.after_submit` |
| `write_to_input(content)` | `compy.input.set_text(content)` |

There is no deprecation shim and no `strict_input` flag — the
functions simply no longer exist. The in-repo examples that used
them are migrated to the patterns above (roadmap M8). The break
is bounded to text input; native `love.keypressed`/`textinput`
handling is unaffected (§6).

### `love.state.user_input`

Set and cleared by the singleton's `show()`/`hide()` methods,
exactly as for any new-API caller. Points to the singleton
instance when active; set to `nil` when hidden. There is no
separate legacy code path that touches it. Framework code that
checks `love.state.user_input` for nil-ness continues to work.

---

## 6. `ProjectController`

### Activation

`ProjectController` becomes the occupant of `love.keypressed`
when `app_state` transitions to `'running'` or
`'project_open'`. This is the same slot mechanism used by
`ConsoleController`; `set_handlers()` places
`ProjectController:keypressed` in `love.keypressed` when a
project starts.

### Deactivation

On project stop, `love.keypressed` is restored to
`ConsoleController:keypressed` (the permanent baseline),
exactly as it is today. `compy.input.handlers` and all project
callbacks (`on_key_pressed`, `on_text_entered`, etc.) are
reset to their defaults.

### Relationship to `love.keypressed` slot

`ProjectController:keypressed` IS the `love.keypressed`
occupant during project execution. It is not called from
within `love.handlers.keypressed` by special case — the
overlay gate is removed. The framework's
`love.handlers.keypressed` dispatches to whatever is in
`love.keypressed`, which is `ProjectController:keypressed`
while a project runs.

### Native handler coexistence

Projects that define `love.keypressed`/`love.textinput`
natively (captured by the existing `save_user_handlers` path)
AND set none of the `compy.*` input surfaces are treated as
**legacy** by `ProjectController`. At load time,
`ProjectController` auto-provisions `compy.input.on_key_pressed` as
a lifecycle-split wrapper:

- **Singleton visible:** routes to the text-editing sink.
- **Singleton hidden:** routes to the project's saved native
  handler.

This reproduces today's gated behaviour with zero project
changes. Projects that set any `compy.*` surface explicitly
are new-style; the heuristic never engages. In debug mode,
the wrapper logs which branch it chose. The auto-provisioned
wrapper is cleared on project stop (via `stop_project_run` /
`clear_user_handlers`).

---

## 7. Edge Cases

### `show()` while already active

Behaviour: reconfigures in-place. Content replaced if `text`
is specified; otherwise preserved. No cancel chain fires.
No error. This is the intended API for dynamic prompt
changes (FR-3/FR-4).

### Project stops while input is active

Behaviour: silent hide. The singleton's `hide()` is called
as part of project teardown. No cancel chain fires.
`love.state.user_input` is set to nil. Callbacks are reset.
The project has already stopped and cannot observe any
teardown event.

### Evaluation failure (validator rejects input)

Behaviour: existing behaviour preserved. The singleton
displays the error highlight; input is locked. The user
must acknowledge the error (Enter, Space, or arrows) before
further editing is possible. `after_submit` does not fire.
`before_submit` has already fired. No cancel is triggered.
The session remains active until the user either corrects
and re-submits, or presses Escape.
