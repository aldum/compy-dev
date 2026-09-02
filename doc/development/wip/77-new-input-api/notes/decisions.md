# Notes — Decision Analysis

Analysis of the suggestions added to `summaries/decisions.md`.
Sanity checks, consistency observations, and open sub-questions
raised by each suggestion. Intended to inform finalising the
decisions before design begins.

---

## D-1 · Backward compatibility

**Suggestion:** facades over new API, deprecation warnings in
debug mode.

**Assessment:** directionally sound and consistent with the
existing `love.debug` flag pattern in the codebase. One
non-trivial constraint: the old API is polling-based (returns
a reftable) while the new API will be callback-based. A facade
is not just a rename — it has to bridge two paradigms. Each
old function would need to internally wire a submit callback
that fills a reftable, then return that reftable. Cancel
handling would also need a policy (fill with nil? stay empty
forever?).

Additionally, `user_input()` and `input_text()` are currently
two separate steps — the first creates the reftable, the
second creates the overlay using it. Facades would need to
preserve or paper over this two-step structure.

Feasible, but the facade is heavier than it looks. Worth
designing explicitly rather than treating as a trivial wrapper.
The singleton direction in D-2 may simplify this considerably.

** ARCHITECT RESPONSE 1 **

**Idea**: apps still can receive the reftable and poll it until they switch.
It just will be filled in a different way behind the curtains (question: how its done now, conceptually?)
user_input() can still create the reftable, 
and input_text() will show/decorate/configure the terminal singleton, 
and reset callbacks in a way that populates the reftable.
Both will emit tons of warnings and may break instead if 'deprecation=false' flag is set globally

** AI RESPONSE 1 **

*Response:* Currently: `user_input()` allocates a reftable and
stores it in a closure variable `input_ref`. `input_text()` then
creates the MVC triad and passes `input_ref` as the `result`
argument to `UserInputController`. On Enter, `UserInputController`
calls `res(t)` — which calls the reftable as a function, storing
the submitted value. The project polls `r:is_empty()` until that
call happens. So the reftable is already a one-shot callback cell;
the facade just makes the submit callback visible rather than
internal. The two-step structure maps cleanly onto singleton
configure+show: `user_input()` allocates the reftable,
`input_text()` configures the singleton and registers the submit
callback that fills it. Viable.

On `deprecation=false`: the semantics feel inverted — "false"
typically suppresses rather than enforces. Probably better as a
`strict_input = true` flag that opts the project into hard errors
instead of warnings, which is a more explicit choice.

** ARCHITECT RESPONSE 2 **

If you think its resolved now, write down the resolution summary, and mark chapter as [RESOLVED]
Otherwise, call out outstanding gaps and dialogue will continue

** AI RESPONSE 2 ** 

**Resolution:** The reftable facade works because the reftable
is already a one-shot callback cell — `user_input()` allocates
it, `input_text()` configures the singleton and wires a submit
callback that fills it. Cancel policy: on Escape, the reftable
simply stays empty; project code that polls `r:is_empty()`
handles this as a no-result cycle, which is the same behaviour
as today. The `strict_input = true` flag replaces `deprecation=false`
for projects that want hard errors.

No unresolved gaps remain.

## D-1 [RESOLVED]

---

## D-2 · Second setup call

**Two suggestions offered — they are competing architectures,
not alternatives within the same model.**

Suggestion 1 keeps project code as the initiator of input
sessions and adds a `force=true` escape hatch for replacement.
Suggestion 2 proposes a framework-managed singleton that
projects configure rather than create.

**On `force=true`:** a flag that changes call semantics based
on a boolean argument is the pattern `agents/rules.md`
discourages ("No C accent" — prefer explicit API over
dispatch-by-argument). More practically: if `force` triggers
destroy-and-recreate it conflicts with NFR-1; if it triggers
in-place reconfiguration it is essentially what the singleton
approach offers anyway, through a less clean surface.

**On the singleton (suggestion 2, point 3):** this is the
more significant idea and has the widest architectural reach.
If the input widget is framework-managed, the "second setup
call" problem dissolves — there is no setup call, only a
configure/show call on a widget that already exists. This also
directly satisfies NFR-1 with no special effort. The D-1
facades become thin wrappers that call configure+show rather
than create.

**Recommendation:** treat the singleton vs project-created
question as the primary axis of D-2. `force=true` should not
appear in the final API regardless of which direction is
chosen.

**Open sub-question:** if the singleton is framework-managed,
when is it created (application start vs first use) and where
does it live — inside `ConsoleController` as now, or as a
top-level framework object?

** ARCHITECT RESPONSE 1 **

**Idea**: going totally for a framework-managed singleton, 
lazy creation, never destroyed, framework level. 
User's code simply shows/decorates/reconfigures it.

** AI RESPONSE 1 **

*Response:* Agreed — this is the cleanest resolution and the
rest of the decisions flow from it naturally. Lazy creation is
the right call: no allocation cost if a project never uses input.
"Never destroyed" is already implicit in how the console's own
input widget works today.

The one structural implication worth flagging: currently
`UserInputModel`/`Controller`/`View` are owned by
`ConsoleController`. Promoting them to framework level means they
probably need to be created in `main.lua` or `love.load` and
passed in, rather than constructed inside `ConsoleController`.
That is a contained change but touches the wiring. How the
singleton is exposed to project code (via the `compy` namespace,
directly, or through the facade functions) is a design detail —
but the direction is clear.

** ARCHITECT RESPONSE 2 **

**Concern**: in new API MVC is not exposed to projects at all, but in REPL and editor it played a crucial role.
Do we have a fundamental problem here?  Requirements already mentioned the ability to reimplement REPL/editor to use new API,
but at least editor (not sure about REPL) still has lots of logic bounded to buffer, and maybe to view too.
So... we should keep the ability to setup custom MVC triade which would be wired up almost as now -- except that invocation chain will be altered plus editor/REPL will be able to better react to events flow (via handlers/callbacks which may then trigger MVC methods as they seem reasonable)? Please, analyze this aspect. 

** AI RESPONSE 2 **

*Response:* No fundamental problem. The layers need to be
distinguished clearly:

**The input widget** (UserInputModel/Controller/View) becomes the
singleton. It handles text entry, cursor, selection, history,
evaluation. Framework code (ConsoleController, EditorController)
continues to hold direct references to it — nothing prevents
that. They are framework code, not project code. What changes is
that they no longer own its creation. The editor configures the
singleton for its context (no history, LuaEditorEval, disable
selection) when it becomes active, rather than constructing a
fresh instance.

**The editor's own model** (BufferModel, blocks, semantic
analysis, buffer stack) is a completely separate layer that is
not touched by this feature. The editor uses the input widget as
a text entry strip at the bottom of the screen; the block display
above is independent. None of the editor's buffer machinery goes
near the new API.

**FR-11/FR-12 (re-implementability)** means the event API is
expressive enough that console/editor *could* be re-implemented
using it — not that they must be. In practice the console could
express its Enter→evaluate and limit→history as framework_handlers
entries. The editor could express its Ctrl+M/Ctrl+F/Escape as
handler registrations. But this migration is optional and deferred.
The handlers/callbacks topology is *additive* — framework code can
adopt it gradually.

**Settled**: no exposure of MVC to project code is needed or
appropriate. Framework code retains direct MVC access unchanged.

** ARCHITECT RESPONSE 3 **

Is it really settled ? Outline clearly the provisioning/reconfiguration path and summarize how ownership issue is resolved.
If you confirm its settled, write down the resolution and mark chapter as [RESOLVED]

** AI RESPONSE 3 **

**Provisioning and reconfiguration path:**
The singleton is created at `love.load` (or lazily on first use)
in `main.lua` and passed as a reference to `ConsoleController`
and `EditorController` at construction. Neither controller owns
it. When a project calls `input_text("prompt")`, the facade calls
`show({prompt=..., evaluator=InputEvalText})` on the singleton,
which is already allocated. On submit the framework fires the
on_submit callback (which fills the reftable in the facade path,
or calls project code directly in the new API path). On project
stop, `compy.handlers` is cleared via the same mechanism as
`evacuate_required`. The singleton itself is hidden but never
destroyed.

**Ownership resolution:** the singleton lives at framework
level; ConsoleController and EditorController hold references
to it. They configure it for their context when they become
active (e.g., the editor sets LuaEditorEval, disables history)
and restore or clear configuration when they leave. Project code
never touches the MVC triad — it goes through the `compy`
namespace API only. Framework code retains direct access,
unchanged.

## D-2 [RESOLVED]

---

## D-3 · Key event granularity

**Suggestion:** one `compy.key_combo` callback, fires only
when at least one modifier key is present.

**Gap:** the suggestion covers modifier+anything but leaves
non-character keys WITHOUT a modifier in a grey zone —
function keys, Delete, Home, End when unhandled. No key_combo
fires (no modifier), no textinput fires (no character). This
may be intentional given the target device (F-keys rarely
available on the built-in keyboard) but should be stated
explicitly rather than left implicit.

**On the preprocessing point:** "framework preprocessing
decides if API callback should be triggered" reads as: the
framework handles the key first (navigation, editing), and
only if not consumed does the callback fire. This is the
forwarding/bubbling mechanism from `notes/design.md`. The
"debug log if skipped" is useful and consistent with the
default noop + debug log pattern appearing across D-3 and D-4.

**Interaction with D-6:** together D-3 and D-6 implicitly
partition the event space:
- character input (± modifier) → `on_text_entered(text, mods)`
- modifier + non-character → `on_key_combo(keys)`
- non-modifier non-character → currently unaddressed

This partition is coherent. The third case should either get
an explicit surface or be explicitly declared out of scope.

** ARCHITECT RESPONSE 1 **

**Idea**: lets expand combo idea into all non-characters 
(modifier or not). Simply have *two* callbacks routed, hierarchically

Internally, maintain a global table of all keys, flagging those in pressed state
Than, on top of that build custom callbacks

It seems I have a proto-design below which was the primary goal of the ticket :)
```
nonempty = function(t) ... end -- equivalent of Ruby's .compact()
compy.keys_pressed = {} -- or prepopuate with all possible keys 
compy.framework_handlers = { -- non-overridable handlers for specific combos
  'escape' = ...,
  'enter' = ...,
  ['Ctrl','enter'] = ...,
}
compy.handlers = { -- overridable handlers for specific combos

}
compy.commands = {
  ['^exit',['Ctrl']] = ... -- handler for specific combination of text and non-input chars
  ['^save',] = .. -- some command
}

love.keypressed(k)
  compy.keys_pressed[k]=true -- or timestamp
  compy._on_key_pressed(k, nonempty(compy.keys_pressed))

love.keyreleased(k)
  compy.keys_pressed[k]=false
  compy._on_key_stroke(k, nonempty(compy.keys_pressed))

love.textinput(txt)
  compy._on_textinput(txt, nonempty(compy.keys_pressed))

-- new callback which exposes new key and lists already pressed
compy._on_key_pressed(k, pressed) 
  -- 1. check framework table of handlers (mapped by specific combos) -- proceed to handler if found. bubble or not depending on what handler defines
  -- 2. check project table of handlers (mapped by specific combos) -- in the same way
  -- 3. call compy.on_key_pressed(...) -- by default a noop with log, overloadable by project

compy._on_key_stroke(k, pressed)
  -- same logic as above

compy._on_textinput(txt, pressed)
  local mods = -- any noncharacter keys from pressed table 
  local proceed = compy.commands([txt,mods])() -- by default table returns noop without log that returns true
  if proceed then     -- tolerable violation of 'no-arrows-dispatching' principle
    compy.ontextinput(txt, mods) -- overloadable by project by default noop with log message
  end
end
```

** AI EVALUATION RESPONSE 1 **

*Response:* This resolves D-3's gap cleanly — non-modifier
non-character keys now have a surface via `_on_key_pressed` and
`_on_key_stroke`. A few observations:

`keys_pressed[k] = false` on release leaves dead entries that
`nonempty` has to filter. Setting to `nil` instead removes them
outright, which is cleaner and avoids the table growing
unboundedly over a long session.

The `_on_key_stroke` (keyreleased) callback is a useful
addition — it lets projects distinguish tap from hold, and means
chord-style combos (Ctrl+S press, then release in any order) can
be detected cleanly. Worth being explicit about its semantics:
it fires with the keys still pressed at release time, minus the
released key itself.

The `compy.commands` table with composite keys like
`['^exit', ['Ctrl']]`: Lua table keys use reference equality for
tables, so `['Ctrl']` as a key won't match a different `['Ctrl']`
table at lookup time. In practice this needs a string
serialisation (e.g. `'Ctrl+exit'` or a sorted join of key names)
or a lookup helper. Worth addressing in the design spec.

Three-level dispatch (framework_handlers → handlers → generic
callback) is coherent and the right shape. The ordering question
is significant: does `framework_handlers` run before or after
`handlers`? If before, projects can observe but not intercept
Escape/Enter (framework always wins). If after, projects can
intercept first, then the framework runs — closer to
`preventDefault()`. The proto-design implies framework-first but
D-4's "does not necessarily prevent framework processing" suggests
framework-always. Worth making this explicit.

** ARCHITECT RESPONSE 2 **

**Thought**: Regarding nil, I simply am not sure what would be better from GC-perspective. Small table constantly changing its shape, or big table with false/true flags switched constantly? (most of them being false thoguh). THe advantage of using 'nil' also is that we do not have to postprocess table, filtering it. Probably "nil" is clean resolution -- it addds *some* overhead on table size fluctuating, but if we keep big table -- we will anyway have more overhead on extracting pressed keys from it, unless we pass full keymap and let project code check it (which also would be dangerous because project code may decide to alter the values... hmm...)

**Remark**: on string serialization, yes -- we can order and serialize. That's what already is done in different places of codebase (I saw conventions like "C-escape" and so -- maybe even coming up from love2d)

**Question**: is actual architecture of love2d native callbacks compatible with the suggested design?

**Request**: when writing down conclusions, end up with an opinion -- is this decision/design point resolved/settled or requires further dialogue?


**AI EVALUATION RESPONSE 2**:

**On nil vs false:** `nil` is correct. Setting a table entry to
nil in Lua removes the slot cleanly — no filtering needed, no
growth over time. The GC cost of a small table gaining and losing
entries on keypressed/keyreleased events is negligible; the
keyboard's key set is bounded (~100 keys at most). The only
marginal argument for `false` was avoiding table resize, but Lua
tables don't shrink on nil assignment anyway — they just mark the
slot free for reuse. `nil` wins on cleanliness alone.

**On string serialisation:** the codebase already has conventions
like "lctrl", "escape", "up" from LÖVE2D's key name strings.
A serialisation such as sorted key names joined with `+` (e.g.
`"lctrl+s"`) is idiomatic and straightforward to implement as a
small helper. No new invention needed.

**On LÖVE2D compatibility:** fully compatible. `controller.lua`
already overrides `handlers.keypressed`, `handlers.keyreleased`,
`handlers.textinput`. The proposed dispatch (`keys_pressed` update
→ `_on_key_pressed`) slots into those handlers as an additional
step. The existing global shortcuts (Ctrl+Q, Ctrl+T etc.) become
entries in `framework_handlers` with the same effect. One useful
addition: LÖVE2D passes `isrepeat` as a third argument to
`keypressed` — worth threading through to `_on_key_pressed` for
projects that want to distinguish first press from held repeat.

**Settlement status: largely settled.** Direction, structure, and
LÖVE2D compatibility are all confirmed. The remaining open point
(exact serialisation format for combo keys) is a design-spec
detail, not a blocking decision. This section can be marked
resolved pending that detail in `api_spec.md`.a

** ARCHITECT RESPONSE 3 **

Write down a final resolution summary, marking the outstanding detail to be solved in spec level

When done and if no new concerns arise, mark the section as [RESOLVED]

** AI RESPONSE 3 **

**Resolution:** `keys_pressed` uses `nil` on release (not
`false`). Three LÖVE2D events feed the dispatch:
`love.keypressed` → `_on_key_pressed(k, pressed, isrepeat)`,
`love.keyreleased` → `_on_key_stroke(k, pressed)`,
`love.textinput` → `_on_textinput(txt, pressed)`. Three-level
dispatch per event: framework_handlers (structural, always run)
→ compy.handlers (project-registered, combo-specific) →
compy.on_key_pressed (generic overloadable callback, noop+log
by default). Project handlers run before framework handlers.
Combo keys are looked up by string-serialised sorted key names
(e.g. `"lctrl+s"`), consistent with LÖVE2D key name conventions.

**Outstanding spec detail:** exact serialisation helper and
`isrepeat` threading — both are implementation decisions for
`api_spec.md`, not blocking.

**See also:** `notes/event_routing.md` — full before/after
routing diagrams, concrete Ctrl+char example, and analysis
of the suppression mechanism (open design detail for
`design.md`).

## D-3 [RESOLVED]

---

## D-4 · Cancel notification

**Suggestion:** dedicated cancel callback; chain hierarchy
`on_keypressed` → `on_escape` → `on_cancel`.

**The chain idea is the most notable proposal across all seven
decisions.** It generalises cleanly: each level fires the next
by default, any level can be overridden to intercept. This is
the DOM-style bubbling from `notes/design.md`, applied
explicitly to the cancel path.

**Consistency question:** if `on_escape → on_cancel` is a
chain, the symmetric form would be `on_enter → on_submit`.
That would make the model uniform: a general keypressed
handler at the top, specific key handlers in the middle,
semantic handlers at the bottom. Worth considering whether
the chain is specific to cancel or is the general callback
model shape.

**Risk with `on_keypressed` at the top:** if a project
overrides it without delegating, Escape never reaches
`on_cancel` and the input area becomes undismissable. The
design needs a clear propagation convention — the return-value
approach from `notes/design.md` (true = consumed, nil/false =
propagate) is the natural answer here.

**On "does not necessarily prevent framework processing":**
this states a specific policy: the framework's teardown runs
independently of the callback chain. Worth making this
explicit in the design rather than leaving it implicit.

** ARCHITECT RESPONSE 1 **

**Idea**: see above about callbacks/handlers topology. 
Callbacks are calls bound to input events (overridable and not)
Handlers are functions bound to specific combos.
Then the whole cancel/enter thing is configurable this way, including overloadable and non-overloadable options

** AI RESPONSE 1 **

*Response:* Agreed — D-4 dissolves into the topology. The
terminology distinction is useful and worth formalising:
- **handler**: bound to a specific key combo; can block
  propagation via return value
- **callback**: bound to an event class (any keypressed, any
  text input); called after handler dispatch; overloadable

`framework_handlers.escape` and `framework_handlers.enter`
represent the non-overridable defaults (teardown, submit). The
D-4 chain `on_keypressed → on_escape → on_cancel` maps onto:
`handlers.escape` (project override, runs first) →
`framework_handlers.escape` (always runs, unless suppressed).

One thing still to resolve: can a project handler suppress
`framework_handlers`? The D-4 suggestion's "does not necessarily
prevent framework processing" implies no — the framework always
gets the last word on Escape/Enter. If that is the policy, the
return value from a project handler only controls whether the
generic callback fires, not whether the framework teardown runs.
That should be stated explicitly to avoid surprises.

** ARCHITECT RESPONSE 2 **

**Idea**: lets' formulate it this way: topology of handlers/callbacks should be designed or augmented in a way that guarantees ability to define priority of framework/project handlers/callbacks in any way that suits (not by userspace configuration but in framework implementation level -- literally by the order of calls in default callbacks, the types of events/cakkbacks defined etc -- while staying within same paradigm and its tiny implementation). (backgroudn thought: it could be even 'before_cancel'/'cancel'/'after_cancel' if and when we fill like it -- with the framework implementation of handler explicitly ordered in a way that guarantees chosen preferences but can be altered whenever they change).

** AI RESPONSE 2 **

The `before_cancel / cancel / after_cancel` framing is precisely
right and makes the propagation question from earlier moot. The
framework doesn't need a suppression protocol — it just places
its own teardown handler at `cancel`, exposes `before_cancel` for
project code that wants to run before teardown, and `after_cancel`
for cleanup after. The ordering is enforced by call order in the
framework's default implementations, not by a return-value
convention. A future change to preferences is a re-ordering of
calls, not an API change.

This pattern generalises symmetrically: `before_submit / submit /
after_submit`, `before_limit / on_limit`, and so on. The framework
owns the middle point; projects hook onto the edges. Chains of
three named points per semantic event give enough flexibility
without inventing a new abstraction.

The return-value bubbling convention is still useful for the
*generic* `on_key_pressed` callback (where the project signals
"I handled this, don't also fire the noop default"). It is not
needed for semantic events, which use the named chain instead.

**Settlement status: settled.** The before/semantic/after naming
pattern and the principle that ordering is enforced by call
sequence (not configuration) are agreed. Named chain points per
event are a design-spec detail.


** ARCHITECT RESPONSE 3 **

Summarize resolution clearly and mark section as resolved

** AI RESPONSE 3 **

**Resolution:** D-4 dissolves into the D-3 topology. For
semantic events (cancel, submit), the framework defines named
chain points: `before_cancel → cancel → after_cancel` (and
symmetrically for submit). The framework owns the middle point;
projects hook into before/after. Ordering is enforced by call
sequence in the framework's default handler implementations —
not by a return-value convention or configuration. This means
"framework always runs cancel teardown" is just a fact about
where in the chain the framework places its own handler.
Return-value propagation (true/nil) applies only to the generic
`on_key_pressed` callback, not to semantic events. Concrete
chain-point names are a spec detail.

## D-4 [RESOLVED]

---

## D-5 · Boundary definition

**Suggestion:** two callbacks, first invokes second.

**Sanity check:** `UserInputModel:is_at_limit` currently
detects the first/last LINE of the entire input, not the
first/last column of a line. There is no existing
end-of-current-line detection. Defining two levels would
require building the coarser-grained one from scratch.

For the stated use cases (console history navigation, editor
block navigation), both want the whole-input boundary — the
level that `is_at_limit` already provides. The line-level
boundary would only matter for intra-multiline navigation, and
none of the current use cases require it.

**Tentative concern:** the two-level chain may add complexity
without clear benefit for the known use cases. A single
`on_limit_reached(direction)` covering the whole-input
boundary may be sufficient. If a line-level boundary is
needed later, it can be added then. Worth confirming whether
the multiline/line-level scenario is actually anticipated
before committing to two callbacks.

The chain structure is consistent with D-4's proposal. If
both levels are adopted, naming needs to be unambiguous about
which boundary each refers to.

** ARCHITECT RESPONSE 1 **

**Idea**: this may require further elaboration but I see how this hook could be plugged into handlers/callbacks topology as a hook.
Just some callback will include check of current boundaries and emit callback 'on_limit_reached'. Also we cah decide that 'hook' is a terminological shortcut for non-blocking handler (that which will bubble up)

** AI RESPONSE 1 **

*Response:* The terminology is clean and worth keeping:
**hook** = always bubbles, non-blocking observation point.
**handler** = can block propagation.

`on_limit_reached` as a hook fits naturally: the vertical
movement logic in `UserInputController` already detects and
returns the limit signal. Instead of the console polling for
that return value, the topology fires the hook. Projects observe
it and react; the framework also observes it (for history
navigation in console mode). Neither needs to block the other.

The concern about two levels (line boundary vs input boundary)
from the earlier analysis still applies: `is_at_limit` only
covers the whole-input boundary today. For the known use cases
that is sufficient. The hook can carry a `direction` argument and
the boundary level can be a later extension if needed.

** ARCHITECT RESPONSE 2 **
On terminology -- I'd consider a 'hook' to be a syntactic sugar -- function that is wrapped up in 'return True' (to support propagation). Therefore its not another independent class of callback but rather the particular flavour of handler

On backwards-compatibility: we still can allow projects to poll this hook (supporting deprecation logic described omewhere above), but also suggest a cleaner way -- providing a custom hook triggered on pupose

Boundary direction could be an argument worth adding from the start. Adding context such as 'boudary' level should be an opportunity (we reserve position argument for that), but specifics to be figured out later. For now projects would be advised to not use it or rely on it, but future designs may account for this ability.

We also stick to KISS principle -- do not overdesign, but leave clear tiny extension points.

When answering, let me know if this feature is settled now.


** AI RESPONSE 2 **

Agreed on all points. To consolidate:

- **Hook as syntactic sugar**: hook = handler with implicit
  propagation (`return true` or equivalent). Not a separate class,
  just a naming convention for handlers that are defined to always
  bubble. `on_limit_reached` is a hook by this definition.
- **Backwards-compat polling**: projects can still observe the
  limit via the existing pattern if needed — the facade wires the
  hook to also fill a reftable if the project uses the old API.
- **Signature**: `on_limit_reached(direction)` with `direction`
  as 'up'/'down'. A reserved second positional argument for
  future boundary-level granularity — not specified, not
  documented in v1, just kept free.
- **KISS**: single whole-input boundary only. Line-level boundary
  is a later extension point if a concrete use case arises.

**Settlement status: settled.**

** ARCHITECT RESPONSE 3 **

Double-check the settlement status. 
Summarize resolution so that it could be undertood/interpreted without detailed context of the discussion above. Mark section as resolved.


** AI RESPONSE 3 **

**Resolution:** Single hook `on_limit_reached(direction)` where
direction is `'up'` or `'down'`. Covers whole-input boundary
only (matching `UserInputModel:is_at_limit`, which detects
first/last line of the entire input). A hook always propagates —
it is a handler with implicit bubble-up, so both project code
and framework code (console history navigation) can observe the
same event independently. A second positional argument is
reserved for future boundary-level granularity but undefined
and undocumented in v1. No line-level boundary this version.

## D-5 [RESOLVED]

---

## D-6 · Modifier + character key [RESOLVED]

**Suggestion:** `on_text_entered(text, modifiers)`.

**Assessment:** clean, consistent with `notes/design.md`'s
proposed callback signatures, and directly answers the
question. Combined with D-3, the policy becomes:

- modifier + character-producing key → `on_text_entered`
  with non-empty modifiers table (`on_key_combo` does not fire)
- modifier + non-character key → `on_key_combo`

Coherent and prevents double callbacks. The modifiers table
gives `on_text_entered` richer context without complicating
its signature.

No sanity concerns. This is the most straightforward of the
seven suggestions.

**Idea**: this is covered in handlers/callbacks topology above

*Response:* Correct — `_on_textinput(txt, nonempty(keys_pressed))`
delivers the modifiers table implicitly. D-6 is fully resolved.

**Note:** this routing only applies when `textinput` actually
fires. For Ctrl+character combos the OS suppresses `textinput`;
those route through `_on_key_pressed` → `compy.handlers`
instead. See `notes/event_routing.md` for the full picture
and a concrete Ctrl+C example.

---

## D-7 · Adoption scope

**User's question:** is gradual rollout architecturally sane?

**Yes.** The overlay event path in `controller.lua:625-630`
is already distinct from the console path
(`ConsoleController:keypressed`) and editor path
(`EditorController:keypressed`). Adding forwarding to the
overlay path does not touch either. Console and editor already
manage their own key events and are unaffected by changes
isolated to the overlay dispatch.

The singleton direction (D-2) reinforces this: if the input
widget is a framework object that console and editor also use
directly, the new event API is a layer that only project code
interacts with.

The D-1 facade approach also applies: `input_text()` can
resolve to the new singleton configure+show path, so existing
examples get the new implementation without knowing about it.
Old API → facades → new singleton API is a coherent migration
path.

** ARCHITECT RESPONSE 1 **

**Request**: re-evaluate once again with respect to clarifications above.
I see how resolution could be achieved or new controversies may arise but would like you to access it accurately. 

** AI RESPONSE 1 ** 

*Response:* Re-evaluated. The singleton (D-2) + event topology
(D-3) together make gradual rollout straightforwardly viable, but
with one new implication to flag.

**What is still isolated:** the new event topology
(`_on_key_pressed`, `handlers`, `framework_handlers`) only runs
for the overlay path — i.e., when a project is active and the
singleton is visible. The console and editor continue using their
existing controller paths unchanged. Nothing touches
`ConsoleController:keypressed` or `EditorController:keypressed`
in the first pass.

**New implication from the singleton direction:** currently the
input MVC triad is created inside `ConsoleController`. If the
singleton lives at framework level, it needs to be created before
`ConsoleController` — likely in `main.lua` — and passed in. The
console and editor would receive a reference to the shared widget
rather than owning it. This is a wiring change, not a behavioural
one, but it means `main.lua` grows a new top-level object. That
is a contained change with no runtime risk.

**Remaining controversy:** who owns the `compy.handlers` and
`framework_handlers` tables during console mode (no project
running)? The framework singleton exists, but there is no project
to populate `compy.handlers`. The answer is probably that those
tables are reset to defaults on project stop — which is already
how `set_user_handlers` / `evacuate_required` works for
`love.*` handlers. The same pattern applies here.

** ARCHITECT RESPONSE 2 **

I assume we can re-wire, and also let Editor/REPL to just provide their own classes for hot replacement?
(even syntax they call may stay the same)

Using new callbacks would be opt-in

Assumption about resetting handlers tables is correct -- they'd be cleared as a part of same process as now. I guess it also applies to the exit from editor

Write your conclusions and let me know if feature is settled/concerns resolved

** AI RESPONSE 2 **

Re-wiring via "hot replacement" of classes is a clean way to
frame the gradual migration path. Console and editor can, when
they choose, replace their keypressed if-chains with handler
registrations — the singleton API makes this possible without
requiring it. Syntax compatibility (same call shapes, opt-in
new callbacks) means existing code continues to work during the
transition.

Handler table reset on project stop and editor exit: confirmed
consistent with the existing `evacuate_required` / `set_user_handlers`
pattern. No new mechanism needed.

**Settlement status: settled.** The scope for this feature is
the project overlay path. Console/editor migration is opt-in and
deferred. The architecture supports both without coupling them.


** ARCHITECT RESPONSE 3 **

Summarize resolution (so that it could be understood/used without full context of dialogue above) and mark section as [RESOLVED]

** AI RESPONSE 3 **

**Resolution:** The singleton lives at framework level, created
in `main.lua` and passed by reference to `ConsoleController` and
`EditorController`. Initial scope is the project overlay path
only — the new event topology (`keys_pressed`, `handlers`,
`framework_handlers`, `_on_key_pressed` etc.) is active only
when a project is running and the singleton is visible. Console
and editor retain their existing keypressed paths unchanged.
`compy.handlers` is reset on project stop and on editor exit,
using the same mechanism as `evacuate_required`. Console/editor
migration to the handler topology is opt-in and has no timeline
in this feature. The facades (D-1) mean existing examples
continue to work without changes.

## D-7 [RESOLVED]

---

## Cross-cutting observations

**An emerging general pattern.** D-3, D-4, and D-5 all point
toward the same structure: a chain of callbacks from general
to specific, where each level calls the next by default and
any level can be overridden. If adopted, this pattern should
be named and described once as a design principle rather than
re-explained per callback. It also needs a consistent
propagation convention — return value is the cleanest option.

**Default noop + debug log.** D-3 and D-4 both propose this
as the default for overloadable callbacks. Worth adopting as
the standard for all project-facing callbacks: silent failure
is replaced by a visible hint in debug mode.

**The singleton decision (D-2) has the widest reach.** If
chosen, it simplifies D-1 (facades become configure+show
wrappers), dissolves D-2 itself, and satisfies NFR-1 directly.
Resolving this first is likely to clarify several of the
other decisions.

**D-3 leaves an unaddressed case.** Non-modifier
non-character keys are covered by neither the key_combo
suggestion (D-3) nor the text+modifiers suggestion (D-6).
Needs an explicit statement: third callback surface, or
deliberately out of scope.

** ARCHITECT RESPONSE **

I guess we resolved the latter concern now?

*Response:* Yes — the expanded proto-design in D-3 (`_on_key_pressed`
fires for all keypressed events regardless of modifier presence)
closes the gap completely. Non-modifier non-character keys now
have a surface. The original cross-cutting observation is resolved.

**Overall status across all seven decisions:**
- D-1: settled in direction (facades, reftable compat confirmed)
- D-2: settled (singleton, lazy, framework-level; MVC concern resolved)
- D-3: settled in direction (combo key serialisation = spec detail)
- D-4: settled (before/semantic/after chain pattern)
- D-5: settled (single hook, direction arg, reserved second arg)
- D-6: settled (merged into D-3 topology)
- D-7: **partially reopened** — see § D-7 reopened below

---

## D-7 reopened · FR-11/FR-12 scope

**The tension:** `requirements.md` FR-11 and FR-12 state that
the new API *should be expressive enough that the console
REPL's and editor's input handling could be re-implemented
using it*. The current D-7 suggested decision reads "event
callbacks apply to the project overlay context only; console
and editor migration is opt-in and deferred." These are in
tension depending on how FR-11/FR-12 are interpreted.

**Two readings:**

*Capability reading:* FR-11/FR-12 are expressiveness tests —
the API must support the patterns the console and editor need,
but there is no requirement to actually migrate them. Verified
by inspection: can the API express history navigation on limit?
Can it express Ctrl+M mode switch? If yes, requirements met.

*Migration reading:* FR-11/FR-12 imply eventual migration.
"Could be re-implemented" is a commitment to provide a path,
and verification requires actually walking that path at some
point. Under this reading, "opt-in, deferred" is acceptable
only if "deferred" has a concrete meaning — it belongs in a
future feature, not "never".

**What the two readings change for this feature:**

Under the capability reading, the design just needs to ensure
no API element required by the console or editor is absent.
This is a design review step, not additional implementation.

Under the migration reading, at minimum a small migration
of one context (e.g., the console's Up/Down → history
path, which is the simplest case) would serve as the
acceptance test for FR-11. The editor migration is more
complex but could be deferred to a separate feature.

**Relationship to the singleton wiring refactor:**

The singleton wiring refactor (D-2: create overlay input in
`main.lua`, pass reference to controllers) is a prerequisite
for both readings. It is small, safe, and should happen
regardless. Once done, the console and editor already hold
a reference to the shared widget — the scaffolding for
eventual migration is in place even if migration itself
is deferred.

**Proposed resolution of the reopened question:**

Adopt the capability reading for this feature: FR-11/FR-12
are verified by design review (confirming the API elements
for limit hooks, key handlers, and text callbacks cover
what the console and editor need), not by migration.
Actual migration of console/editor is a follow-on feature,
explicitly named and tracked, not "opt-in someday."

This means D-7 stays overlay-first for implementation,
but the design doc (design.md) must include a section
explicitly demonstrating that FR-11/FR-12 are satisfied
by the API surface — i.e., a walkthrough showing how the
console's history navigation and editor's mode switches
could be expressed using the new callbacks.

**Architecture analysis** (see `notes/editor_repl_input.md`):
the console and editor do not have isolated MVC triads for
input — they embed the shared input widget inside full-screen
controllers. Neither registers LÖVE2D callbacks directly;
events reach them via the dispatch chain. "Migration" means
only replacing the keypressed if-chains with handler
registrations; the underlying methods (evaluate, history nav,
load block, mode switches) are untouched. The proposed API
surface covers every key event pattern both controllers use.

**Proposed resolution (updated):** adopt the capability
reading. FR-11/FR-12 are verified by a design review
walkthrough — `design.md` should include a section showing
the console and editor key patterns expressible via the new
API (sketches are in `notes/editor_repl_input.md`). Actual
migration is a follow-on feature, explicitly named, not
"opt-in someday." D-7 stays overlay-first for this feature.

**Confirmed by re-reading `input.md`:** the raw requirement
says "an API that *allows for* an easy implementation of
interfaces similar to the console or the editor. *Ideally*,
these should also be re-implemented." The words "allows for"
and "ideally" directly confirm the capability reading. No
migration commitment exists in the stakeholder input.

The migration path is demonstrated and clear (see
`notes/editor_repl_input.md`). No blocking constraint was
found. `design.md` should include the walkthrough section
showing console/editor key patterns are expressible via the
new API — this is the verification artifact for FR-11/FR-12.

## D-7 [RESOLVED]
