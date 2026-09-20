> **Historical — a design-era sketch, not a description of the current code.**
> See [`README.md`](README.md) in this directory.

### Planned refactor

```mermaid
classDiagram

class InputModel {
  oneshot: boolean
  entered: InputText
  evaluator: EvalBase
  type: InputType
  cursor: Cursor
  wrapped_text: WrappedText
  wrapped_error: string[]
  selection: InputSelection
  cfg: Config
  custom_status: CustomStatus?

  history?: HistoryModel
}

```

Interpreter is out, instead create a History triplet and have
one optionally in the input. If present, invoke.
Evaluation is tightly coupled with the input, no sense having
it separately. Non-validated inputs still can be made with an
'all goes' eval.
