///|
test "tabs choose first enabled panel and preserve forced content with semantic hiding" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      tabs(
        id="tabs",
        force_mount=true,
        list_variant=TabsLine,
        items=@minimoon.Val::constant([
          panel(
            key="locked",
            title="Locked",
            content=@minimoon.text("Locked content"),
            disabled=true,
          ),
          panel(
            key="first",
            title="First",
            content=@minimoon.text("First content"),
            icon=@minimoon.text("★"),
          ),
          panel(
            key="second",
            title="Second",
            content=@minimoon.text("Second content"),
          ),
        ]),
      )
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("tabs-tab-first")).prop("ariaSelected"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("tabs-panel-second")).prop("ariaHidden"),
    Some(Json::boolean(true)),
  )
  let identity = runtime.get(@testing.by_id("tabs-panel-first")).identity()
  let _ = runtime.tap(@testing.by_id("tabs-tab-second"))
  assert_eq(
    runtime.get(@testing.by_id("tabs-panel-first")).identity(),
    identity,
  )
  assert_eq(
    runtime.get(@testing.by_id("tabs-panel-first")).prop("ariaHidden"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("tabs-panel-second")).prop("ariaHidden"),
    Some(Json::boolean(false)),
  )
  assert_true(
    runtime.get(@testing.by_id("tabs-tab-first")).text_content().contains("★"),
  )
}

///|
test "tabs recover when dynamic selected item disappears" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let initial = [
        panel(key="a", title="A", content=@minimoon.text("A content")),
        panel(key="b", title="B", content=@minimoon.text("B content")),
      ]
      let (items, update) = @minimoon.create_variable(initial)
      let tabs = tabs(id="tabs", items~, initial_selected="b")
      tabs.map(tabs => {
        @minimoon.div([
          button(
            id="remove",
            on_tap=update(items => items.filter(item => item.key != "b")),
            "Remove B",
          ),
          tabs,
        ])
      })
    }),
  )
  let _ = runtime.tap(@testing.by_id("remove"))
  assert_true(runtime.query(@testing.by_id("tabs-panel-a")) is Some(_))
  assert_true(runtime.query(@testing.by_id("tabs-panel-b")) is None)
}

///|
test "single accordion canonicalizes keys and force mount keeps closed children" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      accordion(
        id="faq",
        force_mount=true,
        show_indicator=false,
        initial_open_keys=["a", "b", "missing"],
        items=@minimoon.Val::constant([
          panel(key="a", title="A", content=@minimoon.text("A content")),
          panel(key="b", title="B", content=@minimoon.text("B content")),
        ]),
      )
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("faq-trigger-a")).prop("ariaExpanded"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("faq-trigger-b")).prop("ariaExpanded"),
    Some(Json::boolean(false)),
  )
  assert_eq(
    runtime.get(@testing.by_id("faq-panel-b")).prop("ariaHidden"),
    Some(Json::boolean(true)),
  )
  assert_eq(runtime.get(@testing.by_id("faq-trigger-a")).text_content(), "A")
  let _ = runtime.tap(@testing.by_id("faq-trigger-b"))
  assert_eq(
    runtime.get(@testing.by_id("faq-panel-a")).prop("ariaHidden"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("faq-panel-b")).prop("ariaHidden"),
    Some(Json::boolean(false)),
  )
}

///|
test "readonly and mixed checkbox states adapt without false change callbacks" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      stack([
        checkbox(id="mixed", indeterminate=true),
        checkbox(id="locked", initially_checked=true, read_only=true),
        switch(id="readonly-switch", read_only=true),
        input_stateful(
          id="readonly-input",
          initial_value="fixed",
          options=input_options(read_only=true),
        ),
      ])
    }),
  )
  assert_true(runtime.query(@testing.by_label("Mixed selection")) is Some(_))
  let _ = runtime.change(
    @testing.by_id("mixed"),
    Json::array([Json::string("mixed")]),
  )
  assert_true(runtime.query(@testing.by_label("Mixed selection")) is None)
  assert_eq(
    runtime.get(@testing.by_id("mixed-control")).prop("checked"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.change(@testing.by_id("locked"), Json::array([]))
  let _ = runtime.change(@testing.by_id("readonly-switch"), Json::boolean(true))
  let _ = runtime.input(@testing.by_id("readonly-input"), "changed")
  assert_eq(
    runtime.get(@testing.by_id("locked-control")).prop("checked"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("readonly-switch")).prop("checked"),
    Some(Json::boolean(false)),
  )
  assert_eq(
    runtime.get(@testing.by_id("readonly-input")).prop("value"),
    Some(Json::string("fixed")),
  )
}

///|
test "focus styles use native focus and blur state" {
  let runtime = @testing.mount(
    form_test_page(_ => input_stateful(id="focused")),
  )
  let _ = runtime.focus(@testing.by_id("focused"), "", 200)
  assert_true(
    runtime.get(@testing.by_id("focused")).snapshot().contains("mmui-focused"),
  )
  let _ = runtime.blur_input(@testing.by_id("focused"), "")
  assert_false(
    runtime.get(@testing.by_id("focused")).snapshot().contains("mmui-focused"),
  )
}
