///|
fn edge_test_runtime(
  side : Side,
  area : Int32,
  overlay : Bool,
) -> @minimoon.PageRuntime {
  let runtime = @minimoon.page(
      id="edge",
      route=@minimoon.route("pages/edge/index"),
      title="Edge",
      capabilities=[@minimoon.MeasureNodes],
      build=page => {
        root(page, context => {
          let (state, update) = @minimoon.create_variable((true, 0))
          let drawer = drawer_controlled(
            context,
            id="edge",
            title="Edge",
            trigger_label="Open",
            content=@minimoon.Val::constant(@minimoon.text("Content")),
            open=state.map(value => value.0),
            on_change=update.map(open => current => (open, current.1 + 1)),
            side~,
            swipe_area=area,
            close_on_overlay=overlay,
          )
          @minimoon.Val::view2(drawer, state, (drawer, state) => {
            @minimoon.div([
              drawer,
              @minimoon.input(
                id="changes",
                value=state.1.to_string(),
                on_input=@minimoon.Emit(_ => @minimoon.none),
              ),
            ])
          })
        })
      },
    )
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  runtime
}

///|
test "drawer exterior edge locks direction dismisses once and ignores late events on every side" {
  for side in [Top, Right, Bottom, Left] {
    let runtime = edge_test_runtime(side, 32, true)
    defer {
      let _ = runtime.dispose()
    }
    assert_true(native_prop(runtime, "edge-swipe-edge", "style") is Some(_))
    let sign = if side == Left || side == Top { -1.0 } else { 1.0 }
    let x = 100.0 +
      (if side == Left || side == Right { sign * 120.0 } else { 0.0 })
    let y = 100.0 +
      (if side == Top || side == Bottom { sign * 120.0 } else { 0.0 })
    let pending = runtime.dispatch(
      "edge/edge/touchstart",
      native_touch(100.0, 100.0, 0.0),
    )
    let _ = runtime.dispatch(
      "edge/edge/touchmove",
      native_touch(x, y, 100.0, pointer=2),
    )
    let _ = runtime.dispatch("edge/edge/touchend", native_touch(x, y, 500.0))
    assert_eq(native_prop(runtime, "changes", "value"), Some(Json::string("0")))
    let _ = native_resolve(runtime, pending, [
      native_rect("edge-surface", 240.0, 400.0),
    ])
    assert_eq(native_prop(runtime, "changes", "value"), Some(Json::string("1")))
    assert_true(native_prop(runtime, "edge-swipe-edge", "style") is None)
    let _ = runtime.dispatch("edge/edge/touchend", native_touch(x, y, 600.0))
    assert_eq(native_prop(runtime, "changes", "value"), Some(Json::string("1")))
  }
}

///|
test "edge cross-axis wrong direction cancel hide and overlay tap policy" {
  for overlay in [true, false] {
    let runtime = edge_test_runtime(Bottom, 32, overlay)
    defer {
      let _ = runtime.dispose()
    }
    for point in [(120.0, 100.0), (100.0, 80.0)] {
      let pending = runtime.dispatch(
        "edge/edge/touchstart",
        native_touch(100.0, 100.0, 0.0),
      )
      let _ = runtime.dispatch(
        "edge/edge/touchmove",
        native_touch(point.0, point.1, 20.0),
      )
      let _ = runtime.dispatch(
        "edge/edge/touchend",
        native_touch(point.0, point.1, 30.0),
      )
      let _ = native_resolve(runtime, pending, [
        native_rect("edge-surface", 240.0, 400.0),
      ])
      assert_eq(
        native_prop(runtime, "changes", "value"),
        Some(Json::string("0")),
      )
    }
    let pending = runtime.dispatch(
      "edge/edge/touchstart",
      native_touch(100.0, 100.0, 0.0),
    )
    let _ = runtime.dispatch(
      "edge/edge/touchcancel",
      native_touch(100.0, 100.0, 1.0),
    )
    let _ = native_resolve(runtime, pending, [
      native_rect("edge-surface", 240.0, 400.0),
    ])
    let pending = runtime.dispatch(
      "edge/edge/touchstart",
      native_touch(100.0, 100.0, 0.0),
    )
    let _ = runtime.lifecycle("onHide", "{}")
    let _ = runtime.lifecycle("onShow", "{}")
    let _ = native_resolve(runtime, pending, [
      native_rect("edge-surface", 240.0, 400.0),
    ])
    assert_eq(native_prop(runtime, "changes", "value"), Some(Json::string("0")))
    let pending = runtime.dispatch(
      "edge/edge/touchstart",
      native_touch(100.0, 100.0, 0.0),
    )
    let _ = runtime.dispatch(
      "edge/edge/touchend",
      native_touch(100.0, 100.0, 50.0),
    )
    let _ = native_resolve(runtime, pending, [
      native_rect("edge-surface", 240.0, 400.0),
    ])
    assert_eq(
      native_prop(runtime, "changes", "value"),
      Some(Json::string(if overlay { "1" } else { "0" })),
    )
  }
  let runtime = edge_test_runtime(Bottom, 0, true)
  defer {
    let _ = runtime.dispose()
  }
  assert_true(native_prop(runtime, "edge-swipe-edge", "style") is None)
}
