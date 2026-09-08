///|
test "pure input and textarea compose in a view without allocating state" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (value, update) = @minimoon.create_variable("")
      value.view(value => {
        @minimoon.div([
          input(
            id="pure-input",
            value~,
            on_input=update.map(value => _ => value),
          ),
          textarea(
            id="pure-textarea",
            value~,
            on_input=update.map(value => _ => value),
          ),
        ])
      })
    }),
  )
  for value in ["M", "Mo", "MoonBit", "月🌙"] {
    let commands = runtime.input(@testing.by_id("pure-input"), value)
    assert_false(commands.contains("RuntimeError"))
    assert_eq(
      runtime.get(@testing.by_id("pure-textarea")).prop("value"),
      Some(Json::string(value)),
    )
  }
  let commands = runtime.input(@testing.by_id("pure-textarea"), "two\nlines")
  assert_false(commands.contains("RuntimeError"))
  assert_eq(
    runtime.get(@testing.by_id("pure-input")).prop("value"),
    Some(Json::string("two\nlines")),
  )
  let _ = runtime.dispose()
}

///|
test "text field commits the last of several same-frame inputs with current validation" {
  let runtime = form_test_page(_ => {
      let (value, update) = @minimoon.create_variable("")
      let state = value.map(value => {
        field_state(
          id="batched",
          label="Name",
          error=if value.length() < 3 { "Too short" } else { "" },
        )
      })
      text_field(state, value, update.map(value => _ => value))
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let commands = runtime.dispatch_batch(
    Json::array(
      ["M", "Mo", "MoonBit"].map(value => {
        Json::object({
          "key": Json::string("batched/input"),
          "payload": Json::object({
            "detail": Json::object({ "value": Json::string(value) }),
          }),
        })
      }),
    ).stringify(),
  )
  assert_false(commands.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("\"value\":\"MoonBit\""))
  assert_true(runtime.snapshot().contains("\"ariaInvalid\":false"))
  assert_false(runtime.snapshot().contains("Too short"))
  let _ = runtime.dispose()
}

///|
test "text field dynamically binds errors options disabled and native semantics" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (value, update_value) = @minimoon.create_variable("")
      let (disabled, update_disabled) = @minimoon.create_variable(false)
      let (options, update_options) = @minimoon.create_variable(
        input_options(name="name", placeholder="Name"),
      )
      let state = @minimoon.Val::map2(value, disabled, (value, disabled) => {
        field_state(
          id="validated",
          label="Name",
          description="At least three characters",
          error=if value.length() < 3 { "Too short" } else { "" },
          required=true,
          disabled~,
        )
      })
      text_field(state, value, update_value.map(value => _ => value), options~).view(node => {
          @minimoon.div([
            node,
            button(
              id="field-lock",
              on_tap=update_disabled(_ => true),
              "Lock field",
            ),
            button(
              id="field-unlock",
              on_tap=update_disabled(_ => false),
              "Unlock field",
            ),
            button(
              id="option-lock",
              on_tap=update_options(_ => {
                input_options(name="name", placeholder="Name", disabled=true)
              }),
              "Lock options",
            ),
            button(
              id="option-readonly",
              on_tap=update_options(_ => input_options(read_only=true)),
              "Readonly",
            ),
            button(
              id="option-invalid",
              on_tap=update_options(_ => input_options(invalid=true)),
              "Invalid",
            ),
            button(
              id="option-reset",
              on_tap=update_options(_ => {
                input_options(placeholder="Changed", maxlength=24)
              }),
              "Reset options",
            ),
          ])
        },
      )
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaInvalid"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaDescribedBy"),
    Some(Json::string("validated-error")),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaLabelledBy"),
    Some(Json::string("validated-label")),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaRequired"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("name"),
    Some(Json::string("name")),
  )
  let _ = runtime.focus(@testing.by_id("validated"), "", 200)
  for value in ["M", "Mo", "Moon"] {
    assert_false(
      runtime.input(@testing.by_id("validated"), value).contains("RuntimeError"),
    )
    assert_eq(
      runtime.get(@testing.by_id("validated")).prop("value"),
      Some(Json::string(value)),
    )
    assert_true(
      runtime
      .get(@testing.by_id("validated"))
      .snapshot()
      .contains("mmui-focused"),
    )
  }
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaInvalid"),
    Some(Json::boolean(false)),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaDescribedBy"),
    Some(Json::string("validated-description")),
  )
  assert_true(runtime.query(@testing.by_id("validated-error")) is None)
  let _ = runtime.tap(@testing.by_id("field-lock"))
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("disabled"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaDisabled"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.input(@testing.by_id("validated"), "blocked")
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("value"),
    Some(Json::string("Moon")),
  )
  let _ = runtime.tap(@testing.by_id("field-unlock"))
  let _ = runtime.tap(@testing.by_id("option-lock"))
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaDisabled"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.tap(@testing.by_id("option-readonly"))
  let _ = runtime.input(@testing.by_id("validated"), "also blocked")
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("value"),
    Some(Json::string("Moon")),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("disabled"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaDisabled"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.tap(@testing.by_id("option-invalid"))
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("ariaInvalid"),
    Some(Json::boolean(true)),
  )
  assert_true(
    runtime.get(@testing.by_id("validated")).snapshot().contains("mmui-invalid"),
  )
  let _ = runtime.tap(@testing.by_id("option-reset"))
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("placeholder"),
    Some(Json::string("Changed")),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("maxlength"),
    Some(Json::number(24.0)),
  )
  assert_eq(
    runtime.get(@testing.by_id("validated")).prop("disabled"),
    Some(Json::boolean(false)),
  )
  assert_true(
    runtime.get(@testing.by_id("validated")).snapshot().contains("mmui-focused"),
  )
  let _ = runtime.input(@testing.by_id("validated"), "")
  assert_true(runtime.query(@testing.by_id("validated-error")) is Some(_))
  let _ = runtime.blur_input(@testing.by_id("validated"), "")
  assert_false(
    runtime.get(@testing.by_id("validated")).snapshot().contains("mmui-focused"),
  )
  let _ = runtime.dispose()
}

///|
test "text field composes focus blur confirm callbacks and keeps instances independent" {
  let page = form_test_page(_ => {
    let (value, update_value) = @minimoon.create_variable("")
    let (events, update_events) = @minimoon.create_variable("")
    let control = text_field(
      @minimoon.Val::constant(field_state(id="events", label="Events")),
      value,
      update_value.map(value => _ => value),
      on_focus=update_events.map(detail => {
        events => events + "focus:" + detail.value + ";"
      }),
      on_blur=update_events.map(detail => {
        events => events + "blur:" + detail.value + ";"
      }),
      on_confirm=update_events.map(value => {
        events => events + "confirm:" + value + ";"
      }),
    )
    @minimoon.Val::view2(control, events, (control, events) => {
      @minimoon.div([control, @minimoon.div(id="event-log", events)])
    })
  })
  let first = @testing.mount(page)
  let second = @testing.mount(page)
  let _ = first.focus(@testing.by_id("events"), "", 200)
  let _ = first.input(@testing.by_id("events"), "typed")
  let _ = first.confirm(@testing.by_id("events"), "typed")
  let _ = first.blur_input(@testing.by_id("events"), "typed")
  assert_eq(
    first.get(@testing.by_id("event-log")).text_content(),
    "focus:;confirm:typed;blur:typed;",
  )
  assert_false(
    first.get(@testing.by_id("events")).snapshot().contains("mmui-focused"),
  )
  assert_eq(
    second.get(@testing.by_id("events")).prop("value"),
    Some(Json::string("")),
  )
  assert_eq(second.get(@testing.by_id("event-log")).text_content(), "")
  let _ = first.dispose()
  let _ = second.dispose()
}

///|
test "stateful textarea preserves focus across input and forwards typed events" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (events, update_events) = @minimoon.create_variable("")
      let control = textarea_stateful(
        id="textarea-events",
        on_focus=update_events.map(_ => events => events + "focus;"),
        on_confirm=update_events.map(value => {
          events => events + "confirm:" + value + ";"
        }),
        on_blur=update_events.map(detail => {
          events => events + "blur:" + detail.value + ";"
        }),
      )
      @minimoon.Val::view2(control, events, (control, events) => {
        @minimoon.div([control, @minimoon.div(id="textarea-log", events)])
      })
    }),
  )
  let _ = runtime.focus(@testing.by_id("textarea-events"), "", 200)
  let _ = runtime.input(@testing.by_id("textarea-events"), "notes")
  assert_true(
    runtime
    .get(@testing.by_id("textarea-events"))
    .snapshot()
    .contains("mmui-focused"),
  )
  assert_eq(
    runtime.get(@testing.by_id("textarea-events")).prop("value"),
    Some(Json::string("notes")),
  )
  let _ = runtime.confirm(@testing.by_id("textarea-events"), "notes")
  let _ = runtime.blur_textarea(@testing.by_id("textarea-events"), "notes", 5)
  assert_false(
    runtime
    .get(@testing.by_id("textarea-events"))
    .snapshot()
    .contains("mmui-focused"),
  )
  assert_eq(
    runtime.get(@testing.by_id("textarea-log")).text_content(),
    "focus;confirm:notes;blur:notes;",
  )
  let _ = runtime.dispose()
}
