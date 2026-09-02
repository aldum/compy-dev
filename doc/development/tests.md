# Test Suite Review

Assessment of `tests/` relative to the codebase and the knowledge base under `doc/development/`. Organised into: relevant infrastructure, coverage map, gaps.

---

## Test Infrastructure Worth Knowing

**`EditorSession`** (`tests/helpers/editor_session.lua`) — A keystroke-driven test harness for the editor. Drives `EditorController` via simulated key events. Key methods: `open(src, nb)` asserts block count on open; `select_block(n)` navigates to block n; `select_and_open_block(n)` selects and presses Escape (asserts `buffer.loaded == n`); `submit(newtext)` alters input and sends Return; `assert_cursor_at(line, col)` checks cursor position and visibility in the input's scroll range. The comment in `select_block` notes it works reliably only before the input multiline buffer is activated (before Escape is pressed) — a known limitation tracked in issue #117.

**`mock.lua`** — `mock_love(t)` injects a minimal `love` global. `mock.keystroke(keystr, press)` parses strings like `"C-return"`, `"S-escape"`, `"M-up"` (prefixes: `C`=Ctrl, `S`=Shift, `M`=Alt) into modifier state + key call. Primary driver for all editor and input tests.

**`testutil.lua`** — Shared constants: `wrap=64` (screen width, matching the code convention line limit), `LINES=16` (buffer display height), `SCROLL_BY=8`. `get_save_function(init)` returns a save callback paired with a `reftable` handle — the same callable-table-as-mutable-reference pattern used by `user_input()` handles in project code.

---

## Coverage Map

### Well covered

| Area | Spec files |
|---|---|
| Utilities | `util/string_spec`, `table_spec`, `dequeue_spec`, `range_spec`, `tree_spec`, `class_spec`, `wrap_spec`, `termcolor_spec`, `debug_spec`, `fs_spec`, `mock_spec` |
| Interpreter pipeline | `parser_spec`, `chunker_spec`, `analyzer_spec` (incl. `ast_to_src`), `ast_spec`, `eval_spec`, `error_spec`, `markdown_spec` |
| Editor model + view | `buffer_spec`, `chunker_spec`, `editor_spec`, `visible_content_spec`, `visible_structured_content_spec` |
| Input widget | `input_text_spec`, `cursor_spec`, `history_spec`, `input_spec`, `user_input_model_spec`, `user_input_view_spec` |

`analyzer_spec.lua` tests `parser.ast_to_src` — the pretty-printer central to the editor submit pipeline. It is the primary executable specification for that function's formatting behaviour.

### Not covered

| Area | Notes |
|---|---|
| `ConsoleController` | Deeply coupled to LÖVE2D runtime state; exercised by harmony integration tests instead |
| `Controller.lua` | Click detection timer, handler registration, draw override detection |
| `ProjectService` | File I/O, project open/create, filesystem mount |
| `SearchModel` / `SearchController` | No tests |
| Drawing system | Depends on LÖVE2D graphics context |
| Views (rendering) | Expected; view testing requires LÖVE2D |
| `user_input` overlay API | `input_text()` / `validated_input()` / `user_input()` project-facing path |

---

## Gaps — Areas Worth Filling

**SearchModel** is the one covered subsystem without tests that doesn't require a graphics context. The narrowing logic (`Search:narrow` with case-insensitive substring match) and selection scroll could be unit-tested similarly to `history_spec`.

**Tag organisation** — `.busted` excludes `delay`-tagged tests by default. Tags in active use: `#parser`, `#chunk`, `#analyzer`, `#ast`, `#src`, `#editor`, `#input`, `#markdown`, `#visible`. No tests currently use the `delay` tag, so the exclude is defensive rather than active.
