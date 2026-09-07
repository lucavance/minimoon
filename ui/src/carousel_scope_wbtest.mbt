///|
fn carousel_test_runtime(
  circular : Bool,
  orientation : Orientation,
) -> @minimoon.PageRuntime {
  @minimoon.page(
    id="carousel_test",
    route=@minimoon.route("pages/carousel/index"),
    title="Carousel",
    build=_ => {
      let (count, change_count) = @minimoon.create_variable(3)
      let (revision, change_revision) = @minimoon.create_variable(0)
      carousel_provider_with_input(
        id="slides",
        count~,
        input=revision,
        circular~,
        orientation~,
        render=(scope, revision) => {
          let items : Array[Panel] = []
          for index in 0..<carousel_slide_count(scope) {
            items.push(
              panel(
                key=index.to_string(),
                title="Slide",
                content=@minimoon.text("Slide " + index.to_string()),
              ),
            )
          }
          @minimoon.fragment([
            @minimoon.text(
              "state:" +
              carousel_active_index(scope).to_string() +
              ":" +
              carousel_slide_count(scope).to_string() +
              ":" +
              revision.to_string(),
            ),
            @minimoon.text(
              "directions:" +
              carousel_can_previous(scope).to_string() +
              ":" +
              carousel_can_next(scope).to_string(),
            ),
            @minimoon.text("loop:" + carousel_is_looping(scope).to_string()),
            @minimoon.text(
              "vertical:" +
              (carousel_orientation(scope) == Vertical).to_string(),
            ),
            @minimoon.button(
              event_key="shrink",
              on_tap=change_count(_ => 1),
              "Shrink",
            ),
            @minimoon.button(
              event_key="grow",
              on_tap=change_count(_ => 3),
              "Grow",
            ),
            @minimoon.button(
              event_key="empty",
              on_tap=change_count(_ => 0),
              "Empty",
            ),
            @minimoon.button(
              event_key="revision",
              on_tap=change_revision(value => value + 1),
              "Revise",
            ),
            carousel_items(scope, items~),
            carousel_previous(scope, @minimoon.text("Custom previous")),
            carousel_next(scope, @minimoon.text("Custom next")),
          ])
        },
      )
    },
  ).create_runtime()
}

///|
test "carousel compound native swipe controlled actions and dynamic count stay synchronized" {
  let runtime = carousel_test_runtime(false, Vertical)
  let _ = runtime.mount()
  assert_true(runtime.snapshot().contains("state:0:3:0"))
  assert_true(runtime.snapshot().contains("directions:false:true"))
  assert_eq(
    native_prop(runtime, "slides-swiper", "vertical"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.dispatch("slides/previous", "{}")
  assert_true(runtime.snapshot().contains("state:0:3:0"))
  let _ = runtime.dispatch("slides/change", "{\"detail\":{\"current\":2}}")
  assert_true(runtime.snapshot().contains("state:2:3:0"))
  assert_true(runtime.snapshot().contains("directions:true:false"))
  let _ = runtime.dispatch("revision", "{}")
  assert_true(runtime.snapshot().contains("state:2:3:1"))
  let _ = runtime.dispatch("shrink", "{}")
  assert_true(runtime.snapshot().contains("state:0:1:1"))
  assert_true(runtime.snapshot().contains("directions:false:false"))
  let _ = runtime.dispatch("grow", "{}")
  assert_true(runtime.snapshot().contains("state:0:3:1"))
  let _ = runtime.dispatch("slides/next", "{}")
  assert_true(runtime.snapshot().contains("state:1:3:1"))
  let _ = runtime.dispatch("empty", "{}")
  assert_true(runtime.snapshot().contains("state:0:0:1"))
  assert_true(runtime.snapshot().contains("directions:false:false"))
  let _ = runtime.dispose()
}

///|
test "carousel loop wraps both edges using native horizontal content" {
  let runtime = carousel_test_runtime(true, Horizontal)
  let _ = runtime.mount()
  assert_eq(
    native_prop(runtime, "slides-swiper", "circular"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    native_prop(runtime, "slides-swiper", "vertical"),
    Some(Json::boolean(false)),
  )
  let _ = runtime.dispatch("slides/previous", "{}")
  assert_true(runtime.snapshot().contains("state:2:3:0"))
  let _ = runtime.dispatch("slides/next", "{}")
  assert_true(runtime.snapshot().contains("state:0:3:0"))
  assert_true(runtime.snapshot().contains("directions:true:true"))
  let _ = runtime.dispose()
}
