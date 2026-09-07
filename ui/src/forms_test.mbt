///|
fn form_test_page(
  build : (@minimoon.PageContext) -> @minimoon.Val[@minimoon.Node],
) -> @minimoon.Page {
  @minimoon.page(
    id="ui_forms",
    route=@minimoon.route("pages/ui_forms/ui_forms"),
    title="UI forms",
    capabilities=[@minimoon.MeasureNodes],
    build~,
  )
}

///|
test "native text inputs own values and preserve typed options" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      stack([
        input(
          id="name",
          options=input_options(placeholder="Name", maxlength=12),
        ),
        textarea(id="notes", initial_value="Initial"),
        input(
          id="disabled",
          initial_value="Locked",
          options=input_options(disabled=true),
        ),
      ])
    }),
  )
  let _ = runtime.input(@testing.by_id("name"), "MoonBit")
  let _ = runtime.input(@testing.by_id("notes"), "Updated")
  let _ = runtime.input(@testing.by_id("disabled"), "Changed")
  assert_eq(
    runtime.get(@testing.by_id("name")).prop("value"),
    Some(Json::string("MoonBit")),
  )
  assert_eq(
    runtime.get(@testing.by_id("notes")).prop("value"),
    Some(Json::string("Updated")),
  )
  assert_eq(
    runtime.get(@testing.by_id("disabled")).prop("value"),
    Some(Json::string("Locked")),
  )
  let _ = runtime.dispose()
}

///|
test "checkbox and switch state is independent and disabled callbacks are inert" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      stack([
        checkbox(id="accept", label="Accept"),
        switch(id="enabled"),
        switch(id="locked", disabled=true),
      ])
    }),
  )
  let _ = runtime.change(
    @testing.by_id("accept"),
    Json::array([Json::string("accept")]),
  )
  let _ = runtime.change(@testing.by_id("enabled"), Json::boolean(true))
  let _ = runtime.change(@testing.by_id("locked"), Json::boolean(true))
  assert_eq(
    runtime.get(@testing.by_id("accept-control")).prop("checked"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("enabled")).prop("checked"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("locked")).prop("checked"),
    Some(Json::boolean(false)),
  )
}

///|
test "radio and native select validate selected keys and filtered native indices" {
  let options = @minimoon.Val::constant([
    choice_option(key="one", label="One"),
    choice_option(key="locked", label="Locked", disabled=true),
    choice_option(key="three", label="Three"),
  ])
  let runtime = @testing.mount(
    form_test_page(_ => {
      stack([
        radio_group(id="radio", options~, initial_value="one"),
        native_select(id="picker", options~, initial_value="one"),
      ])
    }),
  )
  let _ = runtime.change(@testing.by_id("radio"), Json::string("locked"))
  assert_eq(
    runtime.get(@testing.by_id("radio-one")).prop("checked"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.change(@testing.by_id("radio"), Json::string("three"))
  assert_eq(
    runtime.get(@testing.by_id("radio-three")).prop("checked"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.change(@testing.by_id("picker"), Json::number(1.0))
  assert_true(
    runtime.get(@testing.by_id("picker")).text_content().contains("Three"),
  )
  let _ = runtime.change(@testing.by_id("picker"), Json::number(99.0))
  assert_true(
    runtime.get(@testing.by_id("picker")).text_content().contains("Three"),
  )
}

///|
test "toggle groups support multiple independent selections and disabled items" {
  let options = @minimoon.Val::constant([
    choice_option(key="bold", label="Bold"),
    choice_option(key="italic", label="Italic"),
    choice_option(key="locked", label="Locked", disabled=true),
  ])
  let runtime = @testing.mount(
    form_test_page(_ => toggle_group(id="format", options~, multiple=true)),
  )
  let _ = runtime.tap(@testing.by_id("format-bold"))
  let _ = runtime.tap(@testing.by_id("format-italic"))
  let _ = runtime.tap(@testing.by_id("format-locked"))
  assert_eq(
    runtime.get(@testing.by_id("format-bold")).prop("ariaSelected"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("format-italic")).prop("ariaSelected"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("format-locked")).prop("ariaSelected"),
    Some(Json::boolean(false)),
  )
  let _ = runtime.tap(@testing.by_id("format-bold"))
  assert_eq(
    runtime.get(@testing.by_id("format-bold")).prop("ariaSelected"),
    Some(Json::boolean(false)),
  )
}

///|
test "OTP paste normalizes numeric values and Unicode slots without key simulation" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      stack([
        input_otp(id="numeric", length=4),
        input_otp(id="unicode", length=3, numeric=false),
      ])
    }),
  )
  let _ = runtime.input(@testing.by_id("numeric-input"), "12 3x456")
  let _ = runtime.input(@testing.by_id("unicode-input"), "月🌙位好")
  assert_eq(
    runtime.get(@testing.by_id("numeric-input")).prop("value"),
    Some(Json::string("1234")),
  )
  assert_eq(
    runtime.get(@testing.by_id("unicode-input")).prop("value"),
    Some(Json::string("月🌙位")),
  )
  assert_eq(
    runtime.query_all(@testing.by_section("mmui-input-otp-slot")).length(),
    7,
  )
}

///|
test "form field labels and errors stay linked to the native control" {
  let field = field_state(
    id="email",
    label="Email",
    description="Your address",
    error="Required",
    required=true,
  )
  let runtime = @testing.mount(
    form_test_page(_ => {
      @minimoon.Val::constant(
        form_field(
          field,
          @minimoon.input(
            id="email",
            value="",
            on_input=@minimoon.Emit(_ => @minimoon.none),
            semantics=field.semantics(),
          ),
        ),
      )
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("email")).prop("ariaInvalid"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("email")).prop("ariaDescribedBy"),
    Some(Json::string("email-error")),
  )
  assert_true(
    runtime
    .get(@testing.by_id("email-error"))
    .text_content()
    .contains("Required"),
  )
  assert_true(
    runtime
    .get(@testing.by_id("email-label"))
    .text_content()
    .contains("Email *"),
  )
}

///|
test "select layer uses a native list, rejects disabled options and closes on hide" {
  let options = @minimoon.Val::constant([
    choice_option(key="one", label="One"),
    choice_option(key="locked", label="Locked", disabled=true),
    choice_option(key="three", label="Three", group="Other"),
  ])
  let runtime = @testing.mount(
    form_test_page(page => {
      root(page, context => {
        select(context, id="select", options~, initial_value="one")
      })
    }),
  )
  let _ = runtime.tap(@testing.by_id("select-trigger"))
  assert_true(runtime.query(@testing.by_id("select-panel")) is Some(_))
  let _ = runtime.tap(@testing.by_id("select-option-locked"))
  assert_true(
    runtime.get(@testing.by_id("select-trigger")).text_content().contains("One"),
  )
  let _ = runtime.tap(@testing.by_id("select-option-three"))
  assert_true(runtime.query(@testing.by_id("select-panel")) is None)
  assert_true(
    runtime
    .get(@testing.by_id("select-trigger"))
    .text_content()
    .contains("Three"),
  )
  let _ = runtime.tap(@testing.by_id("select-trigger"))
  let _ = runtime.lifecycle("onHide")
  let _ = runtime.lifecycle("onShow")
  assert_true(runtime.query(@testing.by_id("select-panel")) is None)
}

///|
test "native single slider commits through typed change and disabled slider stays fixed" {
  let runtime = @testing.mount(
    form_test_page(page => {
      root(page, context => {
        stack([
          slider(context, id="volume", default_value=25),
          slider(context, id="locked", default_value=10, disabled=true),
        ])
      })
    }),
  )
  let _ = runtime.change(@testing.by_id("volume"), Json::number(75.0))
  let _ = runtime.change(@testing.by_id("locked"), Json::number(90.0))
  assert_eq(
    runtime.get(@testing.by_id("volume")).prop("value"),
    Some(Json::number(75.0)),
  )
  assert_eq(
    runtime.get(@testing.by_id("locked")).prop("value"),
    Some(Json::number(10.0)),
  )
}

///|
test "foundation variants render rich content and preserve disabled actions" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (count, update) = @minimoon.create_variable(0)
      count.map(count => {
        card([
          card_header(card_title("Title")),
          card_content([
            alert(variant=Destructive, alert_description("Warning")),
            badge("Badge"),
            kbd("⌘ K"),
            button(id="rich", on_tap=update(value => value + 1), [
              @minimoon.text("Count"),
              @minimoon.text(count.to_string()),
            ]),
            button(
              id="locked",
              disabled=true,
              on_tap=update(value => value + 1),
              "Locked",
            ),
            skeleton(),
            spinner(),
          ]),
        ])
      })
    }),
  )
  let _ = runtime.tap(@testing.by_id("rich"))
  let _ = runtime.tap(@testing.by_id("locked"))
  assert_true(runtime.get(@testing.by_id("rich")).text_content().contains("1"))
  assert_eq(runtime.query_all(@testing.by_role("alert")).length(), 1)
  assert_eq(runtime.query_all(@testing.by_role("status")).length(), 1)
}
