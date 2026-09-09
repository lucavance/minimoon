# API ergonomics

Applications import `lampclaw/minimoon` as `@minimoon` and export one `Page`
per configured package. Business state follows Elm-style `Model` / `Msg` /
`update` / `Cmd` semantics; pages and local state machines compose through
read-only `Val` values.

The primary authoring style is an ordinary `page` builder calling ordinary
component functions. Create state with `create_*` and compose read-only values
with `Val`; use `elmish_page` when a simple page naturally has one model. No
extra component object or mandatory application-global Model is needed.

## State and emitters

A state constructor returns `(Val[Model], Emit[Msg])`. The first value is
read-only. `Emit` is a callable, stable message endpoint: `emit(message)`
creates an opaque `Cmd`, and the runtime applies that message only when the
command executes inside the owning page transaction.

```moonbit
let (model, emit) = @minimoon.create_state(
  initial_model(),
  update=(current, message, emit) => {
    match message {
      Increment => @minimoon.no_cmd({ ..current, count: current.count + 1 })
      Save => @minimoon.with_cmd(
        current,
        save(emit.map(result => Saved(result))),
      )
    }
  },
)
```

Use `no_cmd(model)`, `with_cmd(model, command)`, or
`with_cmds(model, commands)` to construct the update result. The six state
helpers cover distinct ownership needs:

- `create_pure_state` accepts a pure `(Model, Msg) -> Model` update.
- `create_state` adds commands and optional model-dependent subscriptions.
- `create_state_with_init` also schedules one commit-gated initial command.
- `create_state_with_input` initializes from a reactive input and gives each
  update and subscription the latest input value.
- `create_variable` accepts function-valued update messages.
- `create_resource` starts one load and returns `Val[Status[T]]`.

`Emit::map` contramaps child messages into a parent message without exposing
mutable state:

```moonbit
let name_changed : @minimoon.Emit[String] = emit.map(value => NameChanged(value))
```

There is no public `State`, `Transition`, mutable `Signal`, setter, or graph
cell. Keeping mutation behind commands is what lets candidate rendering and
rollback remain atomic.

For the usual one-model page, `elmish_page` constructs the state tuple and
supplies its emitter to `update`, `view`, `init`, and page-context-aware
subscriptions:

```moonbit
@minimoon.elmish_page(
  id="home",
  route=@minimoon.route("pages/home/home"),
  title="Home",
  model=initial_model(),
  update=(current, message, _emit) => match message {
    Increment => @minimoon.no_cmd({ ..current, count: current.count + 1 })
  },
  view=(current, emit) => counter_view(current, emit),
)
```

## Page input and first render

`page_with_input` separates compile preview from actual input:

```moonbit
@minimoon.page_with_input(
  id="details",
  route=@minimoon.route("pages/details/details"),
  title="Details",
  preview_input=() => "preview-id",
  decode_input=fields => match fields.get("id") {
    Some(id) if id != "" => Ok(id)
    _ => Err(@minimoon.decode_error("id is required"))
  },
  build=(_context, id) => {
    let (draft, update_draft) = @minimoon.create_variable(id)
    draft.view(value => @minimoon.input(value~, on_input=next => {
      update_draft(_ => next)
    }))
  },
)
```

Defining the page calls neither builder nor decoder. Contract inspection calls
`preview_input()` and builds a fresh disposable preview graph; it never decodes
an empty map or executes commands/subscriptions. Builders and init callbacks
must still be pure because previews evaluate initial models and views.

`Page.create_runtime(input?: Map[String, String])` and
`AppRuntime.create_page(page, input?)` return
`Result[PageRuntime, DecodeError]`. Actual input is copied and decoded before
any graph is built. The builder receives plain `Input`, without an `Eq`
constraint; initialize state directly from it. Reactive component inputs are
still `Val[Input]` and use `create_state_with_input` when they must change during
the component lifetime. There is no second input-specific Elmish constructor.

The generated host creates a runtime at `onLoad`, sends the matching input
snapshot once, then orders `onShow` and `onReady`. Load forces a complete tree
at revision 1 from an empty revision-0 boot tree. Only Ready/mount runs initial
commands and starts intervals; repeat mount is a no-op. Invalid input creates
no runtime, mismatched/repeated Load returns diagnostics, and interactions
before Load are rejected. Applications normally let the generated host own
this protocol; low-level tests must preserve the same order.

For generated-host verification of a page with required input, declare
`smokeInput` on that page's configuration entry, for example
`{ "package": "src/pages/details", "smokeInput": { "id": "test-id" } }`.
This supplies synthetic input only to automated host smoke. It is neither a
runtime default nor preview data; real navigation still has to supply valid
route parameters.

## View composition

```moonbit
model.view(current => profile_view(current, emit))

@minimoon.Val::view2(model, component_input, (current, input) => {
  profile_view(current, emit, input)
})
```

Here `component_input` is a reactive `Val[Input]`, not plain decoded route input.
`Val::map`/`view` handle one value. `Val::map2` through `map9` produce any
derived `Val`; `Val::view2` through `view9` are the corresponding
`Val[Node]` conveniences.

Reusable UI is an ordinary function returning `Val[Node]`. It may create local
state because it runs while a page graph is built:

```moonbit
fn counter(props : @minimoon.Val[Props]) -> @minimoon.Val[@minimoon.Node] {
  let (count, update_count) = @minimoon.create_variable(0)
  @minimoon.Val::view2(props, count, (props, value) => {
    @minimoon.button(
      on_tap=update_count(current => current + 1),
      event_key=props.event_key,
      props.label + value.to_string(),
    )
  })
}
```

There is no public component object. Lexical composition plus the scope created
by `assoc`, `switch`, or `enumerate` defines local ownership.

## Equality and recomputation

State models and reactive inputs require `Eq`. Emitting a transition whose
model equals the current model does not stage a graph change. A derived
`mapN`/`viewN` node recomputes only after at least one dependency reports an
unequal value; downstream nodes likewise remain unchanged when their own
`Eq`-constrained input compares equal.

Treat this as a semantic invalidation guarantee, not a promise about callback
counts or a substitute for pure render functions. Equality should represent
all data that can affect descendants. An `Eq` implementation that ignores a
render-relevant field can intentionally suppress its update; an unnecessarily
strict implementation causes extra projection work but does not change the
accepted model.

## Keyed and dynamic lifecycle

```moonbit
let rows = items.assoc_by(
  (id, item) => row(id, item),
  by=item => item.id,
)
```

Keys must be stable and unique. Reorder preserves the nested graph. Candidate
removal hides subscriptions, then disposes the scope only after commit.

| Operator | Builder input | Retention and subscriptions |
| --- | --- | --- |
| `assoc` / `assoc_by` | stable key plus live item `Val` | one scope per present key; reorder preserves it; committed removal disposes it |
| `switch` / `switch_by` | initial tagged value plus same-tag live `Val` | one active scope; a committed tag change replaces and disposes it |
| `enumerate` / `enumerate_by` | initial tagged value plus same-tag live `Val` | retains a finite scope per visited tag; inactive subscriptions pause and resume |
| `enumerate_bounded_by` | initial tagged value plus same-tag live `Val` | same behavior with a positive capacity; commit evicts the least-recent inactive scope |

All creation, visibility changes, eviction, cleanup, and rollback participate
in the candidate transaction. A rejected candidate neither publishes new init
commands nor destroys an existing scope.

The two builder values have different roles:

```moonbit
selection.enumerate_by(
  (initial, live) => {
    // Use `initial.kind` to choose local structure and initial state once.
    let (draft, update_draft) = @minimoon.create_variable(initial.text)
    @minimoon.Val::view2(live, draft, (current, draft) => {
      panel(current, draft, update_draft)
    })
  },
  by=value => value.kind,
)
```

`initial` is the snapshot that created that tag's scope. A later value with the
same tag updates `live` without rebuilding local state. A different tag follows
the retention policy in the table.

## Commands and subscriptions

`Cmd` is opaque and non-generic. Use `none`, `batch`, `delay`, `effect`,
`perform`, `attempt`, typed host functions, and callable emitters. Completion
sinks use `Emit[T]`, so `Emit::map` is the normal way to route results.
For business HTTP status checks and decoded results, import the optional
[typed HTTP package](http.md); raw `request` remains available when the
application needs the complete transport response.

```moonbit
subscriptions=(current, emit) => {
  if current.enabled {
    @minimoon.Sub::batch([
      context.on_show(emit(PageShown)),
      context.every(key="clock", interval_ms=1000, command=emit(Tick)),
    ])
  } else {
    @minimoon.Sub::none()
  }
}
```

Emitters belong to their lexical graph scope. After disposal, commands from an
old emitter are no-ops; host generation checks also reject queued callbacks
from an unloaded page.

App-owned emitters are the explicit exception to page-local addressing: they
queue messages to their application only after the sending page transaction
commits. An effect belongs to the runtime executing its command, not its result
emitter. See [shared-state ownership](shared_state.md).

## Application-aware tests

Use `@testing.mount(page, input=fields)` for a standalone page. It uses actual
input and Load/Show/Ready order, turning input/runtime diagnostics into test
errors. For shared state, `@testing.launch(application.program())` returns an
App test owner; `app.mount(page.program, input=fields)` supplies that owner's
actual dependencies to the page factory. Semantic interactions return their
immediate commands; call `runtime.quiesce()` afterward to settle ready work.
For an App-owned page this drains the App and all its mounted pages;
`app.quiesce(max_steps=1024)` is also available explicitly. It fails with
pending-owner diagnostics on a loop rather
than waiting forever. Unresolved HTTP and future timer ticks are not ready
work, so tests resolve or advance them explicitly. Page disposal leaves App
alive; App disposal releases all remaining pages. Mounting a second page does
not automatically hide the first: tests specify visibility transitions.

## Event keys

Controls generate a structural key when none is supplied. Set an explicit
`event_key`, `input_key`, or control-specific key when host tests or external
compatibility need a stable identifier. Duplicate keys reject the whole
candidate transaction.
