///|
fn select_tap_key(value : Json, id : String) -> String? {
  if value is Object(fields) {
    if fields.get("props") is Some(Object(props)) &&
      props.get("id") == Some(Json::string(id)) &&
      fields.get("events") is Some(Object(events)) &&
      events.get("tap") is Some(String(key)) {
      return Some(key)
    }
    if fields.get("tree") is Some(tree) {
      return select_tap_key(tree, id)
    }
    if fields.get("children") is Some(Array(children)) {
      for child in children {
        if select_tap_key(child, id) is Some(key) {
          return Some(key)
        }
      }
    }
  }
  None
}

///|
test "Select ignores a second predecoded choice after the first closes the surface" {
  let runtime = advanced_native_page(context => {
    let (value, update_value) = @minimoon.create_variable("")
    let (calls, update_calls) = @minimoon.create_variable(0)
    let selected = select_controlled(
      context,
      id="closing-select",
      options=@minimoon.Val::constant([
        choice_option(key="a", label="A"),
        choice_option(key="b", label="B"),
      ]),
      value~,
      initially_open=true,
      on_change=@minimoon.Emit(next => {
        @minimoon.batch([
          update_value(_ => next),
          update_calls(count => count + 1),
        ])
      }),
    )
    @minimoon.Val::view3(selected, value, calls, (selected, value, calls) => {
      @minimoon.div([
        selected,
        @minimoon.text("chosen:" + value + ":" + calls.to_string()),
      ])
    })
  })
  let _ = runtime.mount()
  let tree = native_json(runtime.snapshot())
  let first = select_tap_key(tree, "closing-select-option-a").unwrap()
  let second = select_tap_key(tree, "closing-select-option-b").unwrap()
  let result = runtime.dispatch_batch(control_batch([first, second]))
  assert_false(result.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("chosen:a:1"))
  assert_true(native_prop(runtime, "closing-select-panel", "id") is None)
  let _ = runtime.dispose()
}
