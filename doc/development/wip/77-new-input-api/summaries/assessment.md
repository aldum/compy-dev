# Feature #77 — What the Architecture Can and Cannot Do Today

*Summary of `assessment.md`. Read that document for per-
requirement analysis, file and function references, and the
full reuse/extend/replace breakdown.*

---

## What already exists and is reusable

The core input widget — text editing, cursor movement,
selection, history, syntax highlighting, validation, error
display — is solid and can be kept largely as-is. The
underlying model knows how to detect cursor boundaries; the
view renders correctly; the evaluator pipeline is clean.
Roughly half the work for this feature is already done at
the component level.

## What is missing

**Keyboard events don't reach projects while a prompt is
active.** This is the largest gap. When a project shows an
input prompt, all keyboard events are routed to the prompt
widget and the project's own key handler is bypassed
entirely. There is currently no way for a project to respond
to Ctrl shortcuts, navigation keys, or any other key while
input is on screen. Fixing this touches the event routing
layer shared across all application modes.

**No callbacks — only polling.** The project receives a
reference object and must check it on every frame to detect
when the user has submitted something. There is no mechanism
to register a callback for any event: submit, key press, or
cursor boundary. The entire examples library is built on
the polling pattern.

**No lifecycle control.** The prompt cannot be hidden,
shown, or removed by project code — only by user action
(Enter or Escape). Showing a prompt and then wanting to
change it requires tearing it down and recreating it, which
is what causes the limitation seen in the balloons example.

**Cursor and prompt are not accessible from project code.**
The cursor position can be read and set internally, but
projects have no handle on these. Text content can be
replaced via `write_to_input()`, but the prompt label and
other setup parameters cannot be changed on a live prompt.

## What needs to change

Two things require structural work rather than localised
additions: the event routing (so key events can reach
project code while a prompt is active) and the object
lifecycle (so the prompt widget is created once and
reconfigured rather than discarded and recreated on each
use). Everything else — callbacks, cursor access, hide/show,
programmatic removal — is relatively contained once those
two are resolved.

## Known risks

The input widget is shared across three contexts: the
console REPL, the editor, and project overlays. Changes to
how it routes events will need to be compatible with all
three, or explicitly isolated to the overlay path. This is
the main scope risk: what looks like a project API change
has framework-wide reach.

A second risk is an edge case without a defined policy: when
a character-producing key is pressed while a modifier is held,
the underlying framework fires two separate events. A
callback-based API could end up delivering two notifications
for what the user experienced as a single gesture. This needs
an explicit decision before the callback model can be designed.

A minor but confirmed issue: `compy.text_input`, documented
as an alias for `input_text`, has never functioned due to
a stale reference in the setup code. No current code relies
on it, so it can be replaced cleanly in the new design.

## Overall picture

The feature is achievable largely by building on what exists.
The core widget needs no major surgery. The work is
concentrated in two areas — event routing and lifecycle
redesign — with the rest following from those decisions.
