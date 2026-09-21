///|
priv enum TestingMessage {
  Increment
  Rename(String)
}

///|
test "normalized-tree tests query and drive the public page runtime" {
  let page = @minimoon.page(
    id="testing_counter",
    route=@minimoon.route("pages/testing-counter/testing-counter"),
    title="Testing counter",
    build=_ => {
      let (model, emit) = @minimoon.create_state((0, "moon"), update=(
        model,
        message,
        _,
      ) => {
        match message {
          Increment => @minimoon.no_cmd((model.0 + 1, model.1))
          Rename(name) => @minimoon.no_cmd((model.0, name))
        }
      })
      model.view(model => {
        @minimoon.div(data_section="testing-root", [
          @minimoon.div(data_section="testing-controls", [
            @minimoon.button(
              id="increment",
              event_key="increment",
              on_tap=emit(Increment),
              semantics=@minimoon.semantics(label="Increment count"),
              model.0.to_string(),
            ),
            @minimoon.input(
              id="name",
              value=model.1,
              event_key="rename",
              on_input=emit.map(value => Rename(value)),
              semantics=@minimoon.semantics(label="Name"),
            ),
          ]),
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  assert_eq(runtime.query_all(@testing.by_kind("button")).length(), 1)
  assert_eq(runtime.get(@testing.by_section("testing-root")).kind(), "view")
  let root = runtime.within(@testing.by_section("testing-root"))
  let controls = root.within(@testing.by_section("testing-controls"))
  assert_eq(root.query_all(@testing.by_kind("button")).length(), 1)
  assert_eq(
    controls.get(@testing.by_label("Increment count")).text_content(),
    "0",
  )
  assert_eq(runtime.get(@testing.by_id("increment")).text_content(), "0")
  let _ = controls.tap(@testing.by_label("Increment count"))
  assert_eq(controls.get(@testing.by_id("increment")).text_content(), "1")
  let _ = runtime.input(@testing.by_id("name"), "minimoon")
  assert_true(
    controls.get(@testing.by_id("name")).prop("value") ==
    Some(Json::string("minimoon")),
  )
  assert_true(root.query(@testing.by_label("Missing")) is None)
  let _ = runtime.dispose()
}

///|
priv enum DriverMessage {
  DriverTap
  DriverInput(String)
  DriverChange(Bool)
  DriverConfirm(String)
  DriverFocus(@minimoon.FocusDetail)
  DriverInputBlur(@minimoon.InputBlurDetail)
  DriverTextareaBlur(@minimoon.TextareaBlurDetail)
  DriverScroll(@minimoon.ScrollDetail)
  DriverUpper
  DriverLower
  DriverSwiper(Int)
}

///|
fn driver_page(id : String) -> @minimoon.Page {
  @minimoon.page(
    id~,
    route=@minimoon.route("pages/" + id + "/" + id),
    title="Semantic drivers",
    build=_ => {
      let (status, emit) = @minimoon.create_state("ready", update=(
        current,
        message,
        _,
      ) => {
        let next = match message {
          DriverTap => "tap"
          DriverInput(value) => "input:" + value
          DriverChange(value) => "change:" + value.to_string()
          DriverConfirm(value) => "confirm:" + value
          DriverFocus(detail) =>
            "focus:" + detail.value + ":" + detail.height.to_string()
          DriverInputBlur(detail) => "input-blur:" + detail.value
          DriverTextareaBlur(detail) =>
            "textarea-blur:" + detail.value + ":" + detail.cursor.to_string()
          DriverScroll(detail) =>
            "scroll:" +
            detail.scroll_left.to_string() +
            ":" +
            detail.scroll_top.to_string() +
            ":" +
            detail.scroll_height.to_string() +
            ":" +
            detail.scroll_width.to_string() +
            ":" +
            detail.delta_x.to_string() +
            ":" +
            detail.delta_y.to_string()
          DriverUpper => "upper"
          DriverLower => "lower"
          DriverSwiper(value) => "swiper:" + value.to_string()
        }
        @minimoon.no_cmd(if next == current { current } else { next })
      })
      status.view(current => {
        @minimoon.div(data_section="driver-root", [
          @minimoon.button(
            id="driver-tap",
            on_tap=emit(DriverTap),
            semantics=@minimoon.semantics(
              role=@minimoon.ButtonRole,
              label="Driver tap",
            ),
            "Tap",
          ),
          @minimoon.input(
            id="driver-input",
            value="",
            on_input=emit.map(value => DriverInput(value)),
            on_confirm=emit.map(value => DriverConfirm(value)),
            on_focus=emit.map(value => DriverFocus(value)),
            on_blur=emit.map(value => DriverInputBlur(value)),
            semantics=@minimoon.semantics(label="Driver input"),
          ),
          @minimoon.textarea(
            id="driver-textarea",
            value="",
            on_input=emit.map(value => DriverInput(value)),
            on_blur=emit.map(value => DriverTextareaBlur(value)),
            semantics=@minimoon.semantics(label="Driver textarea"),
          ),
          @minimoon.switch(
            id="driver-switch",
            checked=false,
            on_change=emit.map(value => DriverChange(value)),
            semantics=@minimoon.semantics(label="Driver switch"),
          ),
          @minimoon.swiper(
            id="driver-swiper",
            on_change=emit.map(value => DriverSwiper(value)),
            [
              @minimoon.swiper_item(@minimoon.text("First")),
              @minimoon.swiper_item(@minimoon.text("Second")),
            ],
          ),
          @minimoon.scroll_view(
            id="driver-scroll",
            on_scroll=emit.map(value => DriverScroll(value)),
            on_upper=emit(DriverUpper),
            on_lower=emit(DriverLower),
            [@minimoon.text("Scrollable")],
          ),
          @minimoon.p(id="driver-status", current),
        ])
      })
    },
  )
}

///|
fn assert_driver_status(
  runtime : @testing.TestRuntime,
  expected : String,
) -> Unit raise {
  assert_eq(
    runtime.get(@testing.by_id("driver-status")).text_content(),
    expected,
  )
}

///|
test "runtime semantic drivers produce native MiniApp payload shapes" {
  let runtime = @testing.mount(driver_page("runtime_drivers"))
  let _ = runtime.tap(@testing.by_label("Driver tap"))
  assert_driver_status(runtime, "tap")
  let _ = runtime.input(@testing.by_label("Driver input"), "MoonBit")
  assert_driver_status(runtime, "input:MoonBit")
  let _ = runtime.change(
    @testing.by_label("Driver switch"),
    Json::boolean(true),
  )
  assert_driver_status(runtime, "change:true")
  let _ = runtime.confirm(@testing.by_label("Driver input"), "confirmed")
  assert_driver_status(runtime, "confirm:confirmed")
  let _ = runtime.focus(@testing.by_label("Driver input"), "focused", 40)
  assert_driver_status(runtime, "focus:focused:40")
  let _ = runtime.blur_input(@testing.by_label("Driver input"), "blurred")
  assert_driver_status(runtime, "input-blur:blurred")
  let _ = runtime.blur_textarea(
    @testing.by_label("Driver textarea"),
    "notes",
    5,
  )
  assert_driver_status(runtime, "textarea-blur:notes:5")
  let _ = runtime.scroll(
    @testing.by_id("driver-scroll"),
    scroll_left=1.25,
    scroll_top=42.5,
    scroll_height=300.75,
    scroll_width=100.125,
    delta_x=-0.5,
    delta_y=5.25,
  )
  assert_driver_status(runtime, "scroll:1.25:42.5:300.75:100.125:-0.5:5.25")
  let _ = runtime.upper(@testing.by_id("driver-scroll"))
  assert_driver_status(runtime, "upper")
  let _ = runtime.lower(@testing.by_id("driver-scroll"))
  assert_driver_status(runtime, "lower")
  let _ = runtime.change(
    @testing.by_id("driver-swiper"),
    Json::number(1.0, repr="1"),
  )
  assert_driver_status(runtime, "swiper:1")
  let _ = runtime.dispose()
}

///|
fn assert_scope_status(
  scope : @testing.TestScope,
  expected : String,
) -> Unit raise {
  assert_eq(scope.get(@testing.by_id("driver-status")).text_content(), expected)
}

///|
test "scoped semantic drivers re-resolve the latest subtree" {
  let runtime = @testing.mount(driver_page("scope_drivers"))
  let scope = runtime.within(@testing.by_section("driver-root"))
  assert_eq(scope.query_all(@testing.by_role("button")).length(), 1)
  assert_true(scope.query(@testing.by_text("Tap")) is Some(_))
  let _ = scope.tap(@testing.by_label("Driver tap"))
  assert_scope_status(scope, "tap")
  let _ = scope.input(@testing.by_label("Driver input"), "MoonBit")
  assert_scope_status(scope, "input:MoonBit")
  let _ = scope.change(@testing.by_label("Driver switch"), Json::boolean(true))
  assert_scope_status(scope, "change:true")
  let _ = scope.confirm(@testing.by_label("Driver input"), "confirmed")
  assert_scope_status(scope, "confirm:confirmed")
  let _ = scope.focus(@testing.by_label("Driver input"), "focused", 40)
  assert_scope_status(scope, "focus:focused:40")
  let _ = scope.blur_input(@testing.by_label("Driver input"), "blurred")
  assert_scope_status(scope, "input-blur:blurred")
  let _ = scope.blur_textarea(@testing.by_label("Driver textarea"), "notes", 5)
  assert_scope_status(scope, "textarea-blur:notes:5")
  let _ = scope.scroll(
    @testing.by_id("driver-scroll"),
    scroll_left=1.25,
    scroll_top=42.5,
    scroll_height=300.75,
    scroll_width=100.125,
    delta_x=-0.5,
    delta_y=5.25,
  )
  assert_scope_status(scope, "scroll:1.25:42.5:300.75:100.125:-0.5:5.25")
  let _ = scope.upper(@testing.by_id("driver-scroll"))
  assert_scope_status(scope, "upper")
  let _ = scope.lower(@testing.by_id("driver-scroll"))
  assert_scope_status(scope, "lower")
  let _ = scope.change(
    @testing.by_id("driver-swiper"),
    Json::number(1.0, repr="1"),
  )
  assert_scope_status(scope, "swiper:1")
  let _ = runtime.dispose()
}

///|
test "query_all reports ambiguous selectors without aborting" {
  let page = @minimoon.page(
    id="testing_ambiguity",
    route=@minimoon.route("pages/testing-ambiguity/testing-ambiguity"),
    title="Testing ambiguity",
    build=_ => {
      @minimoon.Val::constant(
        @minimoon.div([
          @minimoon.button(
            on_tap=@minimoon.none,
            semantics=@minimoon.semantics(label="Duplicate"),
            "first",
          ),
          @minimoon.button(
            on_tap=@minimoon.none,
            semantics=@minimoon.semantics(label="Duplicate"),
            "second",
          ),
        ]),
      )
    },
  )
  let runtime = @testing.mount(page)
  assert_eq(runtime.query_all(@testing.by_label("Duplicate")).length(), 2)
  assert_true(runtime.query(@testing.by_label("Duplicate")) is Some(_))
  let _ = runtime.dispose()
}

///|
test "panic get rejects a missing selector" {
  let page = @minimoon.page(
    id="testing_missing",
    route=@minimoon.route("pages/testing-missing/testing-missing"),
    title="Testing missing",
    build=_ => @minimoon.Val::constant(@minimoon.div([@minimoon.nothing()])),
  )
  let runtime = @testing.mount(page)
  let _ = runtime.get(@testing.by_label("Missing"))
}

///|
test "panic event driver rejects an ambiguous selector" {
  let page = @minimoon.page(
    id="testing_ambiguous_event",
    route=@minimoon.route(
      "pages/testing-ambiguous-event/testing-ambiguous-event",
    ),
    title="Testing ambiguous event",
    build=_ => {
      @minimoon.Val::constant(
        @minimoon.div([
          @minimoon.button(
            on_tap=@minimoon.none,
            semantics=@minimoon.semantics(label="Duplicate"),
            "first",
          ),
          @minimoon.button(
            on_tap=@minimoon.none,
            semantics=@minimoon.semantics(label="Duplicate"),
            "second",
          ),
        ]),
      )
    },
  )
  let runtime = @testing.mount(page)
  let _ = runtime.tap(@testing.by_label("Duplicate"))
}
