///|
test "public inline runs preserve style image events and current tap handlers" {
  let runtime = @minimoon.page(
      id="inline",
      route=@minimoon.route("pages/inline/index"),
      title="Inline",
      build=_ => {
        let (phase, update) = @minimoon.create_variable(0)
        phase.view(phase => {
          @minimoon.div([
            @minimoon.inline(
              [
                @minimoon.inline_text(
                  "phase " + phase.to_string(),
                  id="run",
                  style="font-weight:700;",
                  semantics=@minimoon.semantics(
                    label="Styled run",
                    selected=phase > 0,
                  ),
                  on_tap=update(_ => phase + 1),
                  event_key="inline/tap",
                ),
                @minimoon.inline_image(
                  src="/image.svg",
                  alt="An image",
                  on_load=@minimoon.Emit(_ => update(_ => 5)),
                  load_key="inline/load",
                ),
              ],
              id="flow",
            ),
            @minimoon.span(id="legacy", "Legacy block"),
          ])
        })
      },
    )
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  defer {
    let _ = runtime.dispose()
  }
  for phase in [1, 2] {
    let commands = runtime.dispatch("inline/tap", "{}")
    assert_false(commands.contains("RuntimeError"))
    assert_true(runtime.snapshot().contains("phase " + phase.to_string()))
    assert_eq(
      reset_control_props(runtime, "run").get("style"),
      Some(Json::string("font-weight:700;")),
    )
    assert_eq(
      reset_control_node(runtime, "flow")["kind"],
      Json::string("inline"),
    )
    assert_eq(
      reset_control_node(runtime, "legacy")["kind"],
      Json::string("view"),
    )
  }
  let _ = runtime.dispatch(
    "inline/load", "{\"detail\":{\"width\":32,\"height\":32}}",
  )
  assert_true(runtime.snapshot().contains("phase 5"))
}
