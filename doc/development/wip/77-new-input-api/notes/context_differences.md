# Notes — REPL, Editor, and Overlay: Context Differences

Comparison of the three contexts that use the input widget.
Informs the D-2 singleton design and the reconfiguration
logic that `design.md` will need to specify.

---

## Current ownership model

The REPL and editor already share one persistent widget
(`ConsoleModel.input`). The project overlay is the outlier:
`input_text()` / `input_code()` / `validated_input()` create
a separate fresh triad per call, stored in
`love.state.user_input`. This separation is pragmatic
(simpler to add as a feature on top of the existing console
input) rather than a principled design choice.

---

## Widget configuration per context

The three contexts are mutually exclusive (`app_state`
enforces this), so sharing one widget is safe — the
differences are all runtime-configurable properties on
the model:

| Property | REPL | Editor | Project overlay |
|---|---|---|---|
| Evaluator | `LuaEval` | `LuaEditorEval` | `InputEvalText`, `InputEvalLua`, or `ValidatedTextEval` |
| `oneshot` flag | false | false | true |
| History | enabled | disabled | disabled |
| Selection | enabled | disabled | enabled |
| Submit path | `ConsoleController:keypressed` → `evaluate_input()` | `EditorController:keypressed` → `_handle_submit()` | `UserInputController:keypressed` (oneshot path) |

The `oneshot` flag is the most behaviourally significant
difference: it moves the Enter submit path from the
enclosing controller into `UserInputController:keypressed`
itself, and on success pushes a `userinput` event to clear
the overlay.

`LuaEditorEval` adds a 64-character line length validator
on top of `LuaEval` — enforces the code convention live
as the user types.

---

## Implication for D-2 singleton

Under the singleton design, each context switch requires an
explicit reconfiguration call (evaluator, oneshot, history,
selection). Today these are set at construction time. Moving
to runtime configuration is a contained change — all
properties are already mutable fields on the model.

The REPL → editor transition already implicitly does this
(the editor borrows the console's widget and sets
`disable_selection = true`). The singleton makes this
pattern explicit and extends it to the overlay context.
