# MiniApp authoring example

The two-page starter is the default no-App starting shape. Its page packages
export `program() -> Page` and need no shared application dependencies:

- `templates/starter/src/pages/home/page.mbt`
- `templates/starter/src/pages/details/page.mbt`

The maintained real-host Conformance application adds Showcase, Home, Lab, and
Details pages. Together they exercise page input, local state, keyed components,
typed host results, lifecycle, navigation, incremental patches, controls,
scrolling, and same-route instance isolation. Its `src/app` package also shows
optional typed application state shared by Home and Details: those pages use
`program(deps : @application.Deps) -> Page`. See the
[shared-state guide](shared_state.md) for the App factory, bindings, and lifetimes.

A small no-App stateful page follows this shape:

```moonbit
pub enum Msg { Increment }

fn app(context : @minimoon.PageContext) -> @minimoon.Val[@minimoon.Node] {
  let (count, emit) = @minimoon.create_state(
    0,
    update=(current, _message, _emit) => @minimoon.no_cmd(current + 1),
    subscriptions=(_current, emit) => {
      context.on_show(emit(Increment))
    },
  )
  count.view(value => {
    @minimoon.button(
      on_tap=emit(Increment),
      event_key="increment",
      value.to_string(),
    )
  })
}

pub fn program() -> @minimoon.Page {
  @minimoon.page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    build=app,
  )
}
```

Typed host work composes through the same emitter:

```moonbit
LoginRequested => @minimoon.with_cmd(
  current,
  @minimoon.login(emit.map(result => LoginFinished(result))),
)
```

The generated page contains no handwritten JavaScript. The resident runtime
owns state and event decoding; the host scheduler forwards ordered entries,
acknowledged renders, capability results, subscriptions, snapshots, and
disposal.
