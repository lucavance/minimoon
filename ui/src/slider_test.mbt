///|
fn slider_touch(
  identifier : Int,
  x : Double,
  y : Double,
  ended? : Bool = false,
) -> String {
  let point = Json::object({
    "identifier": Json::number(identifier.to_double()),
    "clientX": Json::number(x),
    "clientY": Json::number(y),
    "pageX": Json::number(x),
    "pageY": Json::number(y),
  })
  Json::object({
    "timeStamp": Json::number(10.25),
    "touches": Json::array(if ended { [] } else { [point] }),
    "changedTouches": Json::array([point]),
  }).stringify()
}

///|
fn slider_measurement(id : String) -> String {
  Json::object({
    "nodes": Json::array([
      Json::object({
        "id": Json::string(id),
        "left": Json::number(0.0),
        "top": Json::number(0.0),
        "right": Json::number(100.0),
        "bottom": Json::number(100.0),
        "width": Json::number(100.0),
        "height": Json::number(100.0),
      }),
    ]),
  }).stringify()
}

///|
test "range slider measures track, preserves thumb ordering and rolls back canceled gesture" {
  let runtime = form_test_page(page => {
    root(page, context => {
      slider_values(
        context,
        id="range",
        default_values=[20, 80],
        spec=@headless.slider_spec(step=5, min_steps_between=2),
      )
    })
  }).create_runtime()
  let _ = runtime.mount()
  let started = runtime.dispatch(
    "range/gesture/touchstart",
    slider_touch(7, 20.0, 0.0),
  )
  assert_true(started.contains("InvokeCapability"))
  let measured = runtime.resolve_effect(
    runtime.page_id() + ":0",
    "success",
    slider_measurement("range-track"),
  )
  assert_false(measured.contains("RuntimeError"))
  let moved = runtime.dispatch(
    "range/gesture/touchmove",
    slider_touch(7, 99.0, 0.0),
  )
  assert_true(moved.contains("70"))
  let ignored = runtime.dispatch(
    "range/gesture/touchmove",
    slider_touch(8, 0.0, 0.0),
  )
  assert_eq(ignored, "[]")
  let canceled = runtime.dispatch(
    "range/gesture/touchcancel",
    slider_touch(7, 99.0, 0.0, ended=true),
  )
  assert_true(canceled.contains("20"))
  let _ = runtime.dispose()
}

///|
test "pending measurement cannot revive a hidden slider gesture" {
  let runtime = form_test_page(page => {
    root(page, context => {
      slider_values(
        context,
        id="range",
        default_values=[20, 80],
        direction=@theme.Rtl,
      )
    })
  }).create_runtime()
  let _ = runtime.mount()
  let _ = runtime.dispatch(
    "range/gesture/touchstart",
    slider_touch(7, 20.0, 0.0),
  )
  let _ = runtime.lifecycle("onHide", "{}")
  let result = runtime.resolve_effect(
    runtime.page_id() + ":0",
    "success",
    slider_measurement("range-track"),
  )
  assert_false(result.contains("ariaValueNow"))
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.dispose()
}

///|
test "vertical slider commits the touch end position including release before measurement" {
  let runtime = form_test_page(page => {
    root(page, context => {
      slider_values(
        context,
        id="vertical",
        default_values=[20, 80],
        orientation=Vertical,
      )
    })
  }).create_runtime()
  let _ = runtime.mount()
  let _ = runtime.dispatch(
    "vertical/gesture/touchstart",
    slider_touch(2, 0.0, 70.0),
  )
  let _ = runtime.dispatch(
    "vertical/gesture/touchend",
    slider_touch(2, 0.0, 50.0, ended=true),
  )
  let result = runtime.resolve_effect(
    runtime.page_id() + ":0",
    "success",
    slider_measurement("vertical-track"),
  )
  assert_true(result.contains("50"))
  let after_end = runtime.dispatch(
    "vertical/gesture/touchmove",
    slider_touch(2, 0.0, 0.0),
  )
  assert_eq(after_end, "[]")
}
