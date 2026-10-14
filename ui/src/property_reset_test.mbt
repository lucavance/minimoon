///|
test "controlled UI text clears and accepts input after dynamic re-enabling" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (locked, unlock) = @minimoon.create_variable(true)
      let (text, edit) = @minimoon.create_variable("old")
      @minimoon.Val::view2(locked, text, (locked, text) => {
        let options = @minimoon_ui.input_options(
          disabled=locked,
          placeholder=if locked { "old hint" } else { "" },
          password=locked,
          selection_start?=if locked { Some(0) } else { None },
          selection_end?=if locked { Some(0) } else { None },
        )
        let on_input = edit.map(text => _ => text)
        let input = @minimoon.keyed(
          "input",
          @minimoon_ui.input(id="input", value=text, on_input~, options~),
        )
        let textarea = @minimoon.keyed(
          "textarea",
          @minimoon_ui.textarea(id="textarea", value=text, on_input~, options~),
        )
        @minimoon.div([
          @minimoon.button(
            id="reset",
            on_tap=@minimoon.batch([unlock(_ => false), edit(_ => "")]),
            "Reset",
          ),
          @minimoon.keyed_fragment(
            if locked {
              [input, textarea]
            } else {
              [textarea, input]
            },
          ),
        ])
      })
    }),
  )
  defer {
    let _ = runtime.dispose()
  }
  for id in ["input", "textarea"] {
    let _ = runtime.input(@testing.by_id(id), "blocked")
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("value"),
      Some(Json::string("old")),
    )
  }
  let before = runtime.get(@testing.by_id("input"))
  let _ = runtime.tap(@testing.by_id("reset"))
  let after = runtime.get(@testing.by_id("input"))
  assert_eq(after.identity(), before.identity())
  assert_eq(after.event("input"), before.event("input"))
  for name in ["selectionStart", "selectionEnd", "placeholder"] {
    assert_eq(after.prop(name), None)
  }
  assert_eq(after.prop("password"), Some(Json::boolean(false)))
  for id in ["input", "textarea"] {
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("disabled"),
      Some(Json::boolean(false)),
    )
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("value"),
      Some(Json::string("")),
    )
  }
  for id in ["input", "textarea"] {
    let _ = runtime.input(@testing.by_id(id), "重新输入")
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("value"),
      Some(Json::string("重新输入")),
    )
    let _ = runtime.input(@testing.by_id(id), "")
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("value"),
      Some(Json::string("")),
    )
  }
}

///|
test "controlled UI checkbox and switch reset false and remain interactive" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (checked, update) = @minimoon.create_variable(true)
      let on_change = update.map(checked => _ => checked)
      @minimoon_ui.stack([
        @minimoon.Val::constant(
          @minimoon.button(id="reset", on_tap=update(_ => false), "Reset"),
        ),
        @minimoon_ui.checkbox_controlled(id="checkbox", checked~, on_change~),
        @minimoon_ui.switch_controlled(id="switch", checked~, on_change~),
      ])
    }),
  )
  defer {
    let _ = runtime.dispose()
  }
  for id in ["checkbox-control", "switch"] {
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("checked"),
      Some(Json::boolean(true)),
    )
  }
  let _ = runtime.tap(@testing.by_id("reset"))
  for id in ["checkbox-control", "switch"] {
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("checked"),
      Some(Json::boolean(false)),
    )
  }
  let _ = runtime.change(
    @testing.by_id("checkbox"),
    Json::array([Json::string("checkbox")]),
  )
  for id in ["checkbox-control", "switch"] {
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("checked"),
      Some(Json::boolean(true)),
    )
  }
  let _ = runtime.change(@testing.by_id("switch"), Json::boolean(false))
  for id in ["checkbox-control", "switch"] {
    assert_eq(
      runtime.get(@testing.by_id(id)).prop("checked"),
      Some(Json::boolean(false)),
    )
  }
}
