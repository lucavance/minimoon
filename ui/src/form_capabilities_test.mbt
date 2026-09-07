///|
test "native form names and custom controlled values remain explicit" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      stack([
        textarea(id="notes", options=input_options(name="notes")),
        checkbox(id="accept", name="accept"),
        switch(id="switch", name="notifications"),
        radio_group(
          id="radio",
          name="plan",
          options=@minimoon.Val::constant([
            choice_option(key="basic", label="Basic"),
          ]),
        ),
        native_select(
          id="picker",
          name="region",
          size=Small,
          invalid=true,
          required=true,
          options=@minimoon.Val::constant([
            choice_option(key="eu", label="Europe"),
          ]),
        ),
      ])
    }),
  )
  for
    pair in [
      ("notes", "notes"),
      ("accept", "accept"),
      ("switch", "notifications"),
      ("radio", "plan"),
      ("picker", "region"),
    ] {
    assert_eq(
      runtime.get(@testing.by_id(pair.0)).prop("name"),
      Some(Json::string(pair.1)),
    )
  }
  let submission = form_test_page(_ => {
    let (submitted, update) = @minimoon.create_variable("")
    submitted.map(submitted => {
      form(
        id="native-form",
        submit_key="submit",
        values={
          "custom": Json::string("current"),
          "conflict": Json::string("explicit"),
        },
        on_submit=@minimoon.Emit(values => {
          update(_ => Json::object(values).stringify())
        }),
        [@minimoon.text(submitted)],
      )
    })
  }).create_runtime()
  let mounted = submission.mount()
  assert_false(mounted.contains("RuntimeError"))
  let submitted = submission.dispatch(
    "submit", "{\"detail\":{\"value\":{\"native\":\"typed\",\"conflict\":\"native\"}}}",
  )
  assert_true(submitted.contains("current"))
  assert_true(submitted.contains("typed"))
  assert_true(submitted.contains("explicit"))
  let _ = submission.dispose()
}

///|
test "single toggle group normalizes duplicate and foreign initial keys" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      toggle_group(
        id="single",
        initial_value=["a", "a", "missing", "b"],
        size=Small,
        variant=Outline,
        spacing=6,
        options=@minimoon.Val::constant([
          choice_option(key="a", label="A"),
          choice_option(key="b", label="B"),
        ]),
        render=(option, selected) => {
          @minimoon.text(
            option.label + (if selected { " selected" } else { "" }),
          )
        },
      )
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("single-a")).prop("ariaSelected"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("single-b")).prop("ariaSelected"),
    Some(Json::boolean(false)),
  )
  assert_true(
    runtime
    .get(@testing.by_id("single-a"))
    .text_content()
    .contains("A selected"),
  )
  let _ = runtime.tap(@testing.by_id("single-b"))
  assert_eq(
    runtime.get(@testing.by_id("single-a")).prop("ariaSelected"),
    Some(Json::boolean(false)),
  )
}

///|
test "Select externally controlled open retains custom rendering and native selection guards" {
  let runtime = @testing.mount(
    form_test_page(page => {
      root(page, context => {
        let (open, set_open) = @minimoon.create_variable(true)
        let (value, set_value) = @minimoon.create_variable("a")
        let selected = select_controlled(
          context,
          id="rich-select",
          options=@minimoon.Val::constant([
            choice_option(key="a", label="Alpha"),
            choice_option(key="b", label="Beta"),
          ]),
          value~,
          on_change=set_value.map(value => _ => value),
          open~,
          on_open_change=set_open.map(open => _ => open),
          invalid=true,
          required=true,
          render_value=(value, _) => @minimoon.text("Value: " + value),
          render_option=(option, selected) => {
            @minimoon.text(
              option.label + (if selected { " selected" } else { "" }),
            )
          },
          render_content=rows => {
            select_content([select_label("Choices"), @minimoon.fragment(rows)])
          },
        )
        selected.map(node => {
          @minimoon.div([
            button(id="external-open", on_tap=set_open(_ => true), "Open"),
            node,
          ])
        })
      })
    }),
  )
  assert_true(runtime.query(@testing.by_id("rich-select-panel")) is Some(_))
  assert_eq(
    runtime.get(@testing.by_id("rich-select-trigger")).prop("ariaInvalid"),
    Some(Json::boolean(true)),
  )
  assert_true(
    runtime
    .get(@testing.by_id("rich-select-option-a"))
    .text_content()
    .contains("Alpha selected"),
  )
  let _ = runtime.tap(@testing.by_id("rich-select-option-b"))
  assert_true(runtime.query(@testing.by_id("rich-select-panel")) is None)
  assert_eq(
    runtime.get(@testing.by_id("rich-select-trigger")).text_content(),
    "Value: b",
  )
  let _ = runtime.tap(@testing.by_id("external-open"))
  assert_true(runtime.query(@testing.by_id("rich-select-panel")) is Some(_))
}

///|
test "Select measures initial and programmatic opening and rejects disposed responses" {
  let runtime = form_test_page(page => {
    root(page, context => {
      let (open, change) = @minimoon.create_variable(true)
      select_controlled(
        context,
        id="positioned",
        open~,
        on_open_change=change.map(open => _ => open),
        options=@minimoon.Val::constant([choice_option(key="a", label="A")]),
        value=@minimoon.Val::constant("a"),
        on_change=@minimoon.Emit(_ => @minimoon.none),
      ).map(node => {
        @minimoon.div([
          button(event_key="close", on_tap=change(_ => false), "Close"),
          button(event_key="open", on_tap=change(_ => true), "Open"),
          node,
        ])
      })
    })
  }).create_runtime()
  let mounted = runtime.mount()
  assert_true(mounted.contains("InvokeCapability"))
  assert_true(mounted.contains("positioned-panel"))
  let _ = runtime.dispatch("close", "{}")
  let opened = runtime.dispatch("open", "{}")
  assert_true(opened.contains("InvokeCapability"))
  let stale = runtime.resolve_effect(
    runtime.page_id() + ":0",
    "success",
    "{\"nodes\":[]}",
  )
  assert_eq(stale, "[]")
}
