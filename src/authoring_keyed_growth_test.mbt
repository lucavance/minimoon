///|
test "public Val assoc page accepts batch loading appending and reloading keyed rows" {
  let definition = @minimoon.page(
    id="keyed_growth",
    route=@minimoon.route("pages/keyed_growth/index"),
    title="Keyed growth",
    build=_ => {
      let initial : Array[(String, String)] = []
      let (entries, set_entries) = @minimoon.create_variable(
        @vector.from_array(initial),
      )
      let (selected, set_selected) = @minimoon.create_variable("none")
      let rows = entries.assoc((key, input) => {
        input.map(value => {
          (
            key,
            @minimoon.button(
              event_key="pick-" + key,
              on_tap=set_selected(_ => key),
              value,
            ),
          )
        })
      })
      @minimoon.Val::view2(rows, selected, (rows, selected) => {
        @minimoon.div([
          @minimoon.button(
            event_key="load",
            on_tap=set_entries(_ => @vector.from_array([("a", "A"), ("b", "B")])),
            "Load",
          ),
          @minimoon.button(
            event_key="append",
            on_tap=set_entries(_ => {
              @vector.from_array([
                ("a", "A"),
                ("b", "B"),
                ("c", "C"),
                ("d", "D"),
              ])
            }),
            "Append",
          ),
          @minimoon.button(
            event_key="clear",
            on_tap=set_entries(_ => @vector.from_array(initial)),
            "Clear",
          ),
          @minimoon.text("selected:" + selected),
          @minimoon.keyed_fragment(
            rows.to_array().map(row => @minimoon.keyed(row.0, row.1)),
          ),
        ])
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  for event in ["load", "append", "clear", "load"] {
    let result = runtime.dispatch(event, "{}")
    assert_false(result.contains("RuntimeError"))
    if event == "clear" {
      assert_false(runtime.snapshot().contains("\"text\":\"A\""))
      assert_true(runtime.dispatch("pick-a", "{}").contains("unknown_event"))
    } else {
      assert_true(runtime.snapshot().contains("\"text\":\"A\""))
      assert_true(runtime.snapshot().contains("\"text\":\"B\""))
      let key = if event == "append" { "d" } else { "b" }
      assert_false(
        runtime.dispatch("pick-" + key, "{}").contains("RuntimeError"),
      )
      assert_true(runtime.snapshot().contains("selected:" + key))
    }
  }
  ignore(runtime.dispose())
}
