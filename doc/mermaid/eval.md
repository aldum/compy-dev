> **Historical — a design-era sketch, not a description of the current code.**
> See [`README.md`](README.md) in this directory.

### Planned refactor

```lua
--- @alias validationFilter fun(s: string): boolean, error?
--- @alias conversionFilter fun(s: string): string
--- @alias AstValidatorFilter fun(AST): boolean, error?
--- @alias AstValidatorGen fun(AST, Scope): fun(AST): boolean, error?g
```

```mermaid
classDiagram

class Parser {
  parse()
  get_error()
  chunker()
  highlighter?: fun(string) SyntaxColoring
  pprint()
  ast_to_src()
}

class Filters {
  validators: ValidatorFilter[]
  astValidators: AstValidatorFilter[]
  transformers: TransformerFilter[]
}
class Evaluator {
  label: string
  parser?: Parser
  filters?: Filters
  apply: function
}
```

|               | hl  | apply |
| :------------ | :-- | :---- |
| LuaEval       | 1   | parse |
| TextEval      | 0   | id    |
| InputEval lua | 1   | noop  |
| InputEval     | 0   | noop  |

### Current

```mermaid
classDiagram

class EvalBase {
  kind: string
  apply: function
  is_lua: boolean
  highlight: boolean

  inherit: fun(string, function, bool) EvalBase
}
TextEval --|> EvalBase
LuaEval --|> EvalBase
InputEval --|> EvalBase
```

TextEval : no validation, just return it

```mermaid
classDiagram
class EvalBase {
  kind: string
  is_lua: boolean
  highlight: boolean
  apply()
}

```
