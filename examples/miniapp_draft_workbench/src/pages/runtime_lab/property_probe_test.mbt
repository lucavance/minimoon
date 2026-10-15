///|
test "host property probe resets omits and restores through keyed structural changes" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let runtime = app.mount(deps => @runtime_lab.program(deps))
  let input = @testing.by_id("property-probe-input")
  let identity = runtime.get(input).identity()
  assert_eq(runtime.get(input).prop("value"), Some(Json::string("populated")))
  for phase in 1..<=3 {
    let commands = runtime.tap(@testing.by_event_key("property-probe/next"))
    assert_false(commands.contains("ReplaceViewTree"))
    assert_eq(runtime.get(input).identity(), identity)
    let restored = phase == 3
    assert_eq(
      runtime.get(input).prop("disabled"),
      Some(Json::boolean(restored)),
    )
    assert_eq(
      runtime.get(input).prop("value"),
      Some(Json::string(if restored { "restored" } else { "" })),
    )
    for id in ["property-probe-switch", "property-probe-checkbox"] {
      assert_eq(
        runtime.get(@testing.by_id(id)).prop("checked"),
        Some(Json::boolean(restored)),
      )
    }
    assert_eq(
      runtime.get(input).prop("maxlength"),
      if phase == 2 {
        None
      } else {
        Some(Json::number(if restored { 24 } else { 0 }))
      },
    )
    assert_eq(
      runtime.get(input).prop("selectionStart"),
      if phase == 2 {
        None
      } else {
        Some(Json::number(0))
      },
    )
    if phase == 2 {
      for value in ["中文🌙", ""] {
        let _ = runtime.input(input, value)
        assert_eq(runtime.get(input).prop("value"), Some(Json::string(value)))
      }
    }
  }
}
