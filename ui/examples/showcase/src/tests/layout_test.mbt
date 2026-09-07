///|
test "layout showcase exposes compound navigation carousel and independent sidebar controls" {
  let runtime = @testing.mount(@layout.program())
  assert_eq(
    runtime.get(@testing.by_id("layout-carousel-swiper")).prop("vertical"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("layout-carousel-swiper")).prop("circular"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.tap(@testing.by_event_key("layout-carousel/previous"))
  assert_eq(
    runtime.get(@testing.by_id("layout-carousel-status")).text_content(),
    "Slide 3 / 3",
  )
  let _ = runtime.tap(@testing.by_event_key("layout-carousel/next"))
  assert_eq(
    runtime.get(@testing.by_id("layout-carousel-status")).text_content(),
    "Slide 1 / 3",
  )
  let _ = runtime.tap(
    @testing.by_event_key("layout-navigation/trigger/explore"),
  )
  assert_true(
    runtime
    .get(@testing.by_id("layout-navigation-viewport"))
    .text_content()
    .contains("Explore components"),
  )
  assert_true(
    runtime
    .get(@testing.by_id("layout-navigation-viewport"))
    .text_content()
    .contains("Shared viewport footer"),
  )
  let _ = runtime.tap(@testing.by_event_key("layout-navigation/trigger/learn"))
  assert_true(
    runtime
    .get(@testing.by_id("layout-navigation-viewport"))
    .text_content()
    .contains("Composition and feedback"),
  )
  let _ = runtime.tap(@testing.by_event_key("layout-navigation/dismiss"))
  assert_true(
    runtime.query(@testing.by_id("layout-navigation-viewport")) is None,
  )
  let _ = runtime.input(@testing.by_id("layout-sidebar-query"), "minimoon")
  let _ = runtime.tap(@testing.by_event_key("layout-sidebar/toggle"))
  assert_true(
    runtime
    .get(@testing.by_id("layout-sidebar-status"))
    .text_content()
    .contains("Collapsed: true"),
  )
  assert_true(
    runtime.query(@testing.by_event_key("layout-sidebar-home/help")) is Some(_),
  )
  let _ = runtime.tap(@testing.by_event_key("layout-sidebar-home/help"))
  assert_true(
    runtime.query(@testing.by_id("layout-sidebar-home-tooltip")) is Some(_),
  )
  let _ = runtime.tap(
    @testing.by_event_key("layout-sidebar-home/tooltip-close"),
  )
  let _ = runtime.tap(@testing.by_event_key("layout-sidebar/mobile-toggle"))
  assert_true(
    runtime
    .get(@testing.by_id("layout-sidebar-status"))
    .text_content()
    .contains("Collapsed: true · mobile: true"),
  )
  assert_true(runtime.query(@testing.by_id("layout-sidebar-mobile")) is Some(_))
  let _ = runtime.tap(@testing.by_event_key("layout-sidebar/mobile-close"))
  assert_true(runtime.query(@testing.by_id("layout-sidebar-mobile")) is None)
  let _ = runtime.tap(@testing.by_event_key("layout-sidebar/toggle"))
  assert_eq(
    runtime.get(@testing.by_id("layout-sidebar-query")).prop("value"),
    Some(Json::string("minimoon")),
  )
  assert_true(
    runtime.query(@testing.by_event_key("layout-sidebar/rail/touchstart"))
    is Some(_),
  )
  let _ = runtime.dispose()
}
