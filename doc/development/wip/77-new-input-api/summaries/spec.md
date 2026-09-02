# Feature #77 — API Specification Summary

*Condensed version of `spec.md`. One sentence per item.
Includes all function signatures and callback table.
Edge cases are in `spec.md`.*

---

## `keys_pressed` table

Format: `{ ['lctrl'] = true, ['s'] = true }` — LÖVE2D key
names as keys, `true` as values.

Passed downstream as a **read-only proxy** (iterate with
`for k in pairs(proxy) do`; direct indexing not supported).

**Combo string format:** modifier-first by fixed precedence
(ctrl, alt, shift, gui) then the triggering key, joined with
`+`. Modifier names are generic (l/r folded): `"ctrl+s"` not
`"lctrl+s"`. Bare-key combos: just the key name (`"escape"`).

---

## `compy.input.show(config)`

Activates the singleton; all `config` fields are optional.

| Field | Type | Default |
|---|---|---|
| `prompt` | string | nil |
| `text` | string | nil (empty input) |
| `cursor` | `{line, col}` | end of `text` |
| `highlighter` | function | nil |
| `validator` | function | nil (accept all) |
| `multiline` | boolean | false |

Calling `show()` while already active reconfigures in-place
without triggering the cancel chain.

---

## `compy.input.hide()`

Deactivates silently — no cancel chain, content preserved,
`love.state.user_input` set to nil.

---

## `compy.input.configure(config)`

Live-updates `prompt`, `highlighter`, or `validator`
mid-session; other fields accepted but no-op while active.

---

## `compy.input.clear()`

Clears content and resets cursor to position 1; no-op if
hidden.

---

## `compy.input.get_cursor()`

Returns `line, col` (2D, 1-based source-line coordinates).
Returns `nil` when hidden.

---

## `compy.input.set_cursor(line, col)`

Sets cursor to `(line, col)`; clamps to valid range; no-op
when hidden.

---

## `compy.input.set_text(text [, keep_cursor])`

Replaces text content while active (live write; exception to
`configure()` text-immutability). Preserves cursor if
`keep_cursor` is true. No-op when hidden.

---

## Callbacks

| Callback | Signature | When |
|---|---|---|
| `compy.input.on_text_entered` | `fn(text, keys_pressed)` | textinput path; character delivered by OS |
| `compy.input.on_key_pressed` | `fn(k, keys_pressed, isrepeat)` | All keypressed events; default = text-editing sink; assigning replaces sink |
| `compy.input.handlers[combo]` | `fn(k, keys_pressed) → truthy\|nil` | Combo match (metatable-normalised); return truthy to consume chain |
| `compy.input.before_submit` | `fn(keys_pressed)` | Before framework evaluates; cannot suppress |
| `compy.input.after_submit` | `fn(result)` | After evaluation succeeds (receives the result) |
| `compy.input.before_cancel` | `fn(keys_pressed)` | Before framework dismisses (Escape); cannot suppress |
| `compy.input.after_cancel` | `fn()` | After singleton dismissed |
| `compy.input.on_limit_reached` | `fn(direction, _reserved)` | Cursor hit whole-input boundary; direction = `'up'` or `'down'` |

The submit/cancel/limit callbacks default to a no-op + debug
log entry; the two channel callbacks (`on_key_pressed`,
`on_text_entered`) default to the text-editing sink.
All are reset to defaults when the project stops.

---

## Three-level dispatch (inside `ProjectController:keypressed`)

```
framework_handlers[combo]   → compy.input.handlers[combo]
  → compy.input.on_key_pressed    (default = sink; replacing it removes the sink)
```

`compy.input.handlers` returns truthy to consume. `compy.input.on_key_pressed`
has no tier below it — its default is the sink. Both LÖVE
channels fire independently (keypressed and textinput); no
suppression.

---

## Legacy API — removed

D-1 discarded (stakeholders, round 1): no backward compatibility.
The legacy text-input globals are **removed**, not wrapped:

| Removed function | Replacement |
|---|---|
| `user_input()` | None — reftable / `is_empty()` polling gone; use `compy.input.after_submit(result)` |
| `input_text(p, i)` | `compy.input.show({ prompt, text, validator = InputEvalText })` + `after_submit` |
| `input_code(p, i)` | `compy.input.show({ prompt, text, highlighter = lua_hl, validator = InputEvalLua })` + `after_submit` |
| `validated_input(fn, p)` | `compy.input.show({ prompt, validator = ValidatedTextEval(fn) })` + `after_submit` |
| `write_to_input(content)` | `compy.input.set_text(content)` |

No deprecation shim, no `strict_input` flag — the functions are
gone. Examples migrate (roadmap M8). The break is text-input only;
native keyboard handling is unaffected.

`love.state.user_input`: set on `show()`, nil on `hide()`; points
to the singleton (not a fresh object).

---

## `ProjectController` activation

Active when `app_state = 'running'` or `'project_open'`;
`ProjectController:keypressed` occupies the `love.keypressed`
slot. Deactivated on project stop; callbacks and
`compy.input.handlers` reset via `stop_project_run` /
`clear_user_handlers`. Projects using native `love.keypressed`
(without `compy.input.*` surfaces) get auto-provisioned lifecycle-
split wrapper (legacy heuristic — see `spec.md §6`).
