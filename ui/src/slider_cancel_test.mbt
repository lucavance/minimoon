///|
fn slider_cancel_event(active : Array[Int], changed : Array[Int]) -> String {
  fn point(identifier : Int) -> Json {
    Json::object({
      "identifier": Json::number(identifier.to_double()),
      "clientX": Json::number(60.0),
      "clientY": Json::number(0.0),
      "pageX": Json::number(60.0),
      "pageY": Json::number(0.0),
    })
  }
  Json::object({
    "timeStamp": Json::number(20.0),
    "touches": Json::array(active.map(point)),
    "changedTouches": Json::array(changed.map(point)),
  }).stringify()
}

///|
fn slider_cancel_runtime(commits : Array[Array[Int]]) -> @minimoon.PageRuntime {
  let runtime = form_test_page(page => {
      @minimoon_ui.root(page, context => {
        @minimoon_ui.slider_values(
          context,
          id="range",
          default_values=[20, 80],
          spec=@headless.slider_spec(step=5, min_steps_between=2),
          on_value_commit=@minimoon.Emit(values => {
            commits.push(values.copy())
            @minimoon.none
          }),
        )
      })
    })
    .create_runtime()
    .unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.lifecycle("onShow", "{}"))
  ignore(runtime.mount())
  runtime
}

///|
test "slider ignores secondary and empty touch cancellations and commits the active pointer" {
  let commits : Array[Array[Int]] = []
  let runtime = slider_cancel_runtime(commits)
  defer ignore(runtime.dispose())
  ignore(
    runtime.dispatch("range/gesture/touchstart", slider_touch(7, 20.0, 0.0)),
  )
  ignore(
    runtime.resolve_effect(
      runtime.page_id() + ":0",
      "success",
      slider_measurement("range-track"),
    ),
  )
  ignore(
    runtime.dispatch("range/gesture/touchmove", slider_touch(7, 60.0, 0.0)),
  )
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":60"))
  let before = runtime.snapshot()
  for changed in [[8], []] {
    assert_eq(
      runtime.dispatch(
        "range/gesture/touchcancel",
        slider_cancel_event([7], changed),
      ),
      "[]",
    )
    assert_eq(runtime.snapshot(), before)
  }
  ignore(
    runtime.dispatch("range/gesture/touchmove", slider_touch(7, 65.0, 0.0)),
  )
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":65"))
  ignore(
    runtime.dispatch(
      "range/gesture/touchend",
      slider_touch(7, 70.0, 0.0, ended=true),
    ),
  )
  assert_eq(commits, [[70, 80]])
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":70"))
}

///|
test "slider pending measurement survives secondary cancel and owning cancel restores once" {
  let commits : Array[Array[Int]] = []
  let runtime = slider_cancel_runtime(commits)
  defer ignore(runtime.dispose())
  assert_eq(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([], [7])),
    "[]",
  )
  ignore(
    runtime.dispatch("range/gesture/touchstart", slider_touch(7, 40.0, 0.0)),
  )
  assert_eq(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([7], [8])),
    "[]",
  )
  ignore(
    runtime.resolve_effect(
      runtime.page_id() + ":0",
      "success",
      slider_measurement("range-track"),
    ),
  )
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":40"))
  let canceled = runtime.dispatch(
    "range/gesture/touchcancel",
    slider_cancel_event([], [8, 7]),
  )
  assert_true(canceled.contains("\"ariaValueNow\":20"))
  let before = runtime.snapshot()
  assert_eq(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([], [7])),
    "[]",
  )
  assert_eq(
    runtime.dispatch("range/gesture/touchmove", slider_touch(7, 70.0, 0.0)),
    "[]",
  )
  assert_eq(runtime.snapshot(), before)
  assert_eq(commits, [])
}

///|
test "slider ignores a canceled pointer's late measurement during a new drag" {
  let commits : Array[Array[Int]] = []
  let runtime = slider_cancel_runtime(commits)
  defer ignore(runtime.dispose())
  ignore(
    runtime.dispatch("range/gesture/touchstart", slider_touch(7, 40.0, 0.0)),
  )
  ignore(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([], [7])),
  )
  ignore(
    runtime.dispatch("range/gesture/touchstart", slider_touch(8, 50.0, 0.0)),
  )
  let before = runtime.snapshot()
  assert_eq(
    runtime.resolve_effect(
      runtime.page_id() + ":0",
      "success",
      slider_measurement("range-track"),
    ),
    "[]",
  )
  assert_eq(runtime.snapshot(), before)
  ignore(
    runtime.resolve_effect(
      runtime.page_id() + ":1",
      "success",
      slider_measurement("range-track"),
    ),
  )
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":50"))
  ignore(runtime.lifecycle("onHide", "{}"))
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":20"))
  assert_eq(commits, [])
}

///|
test "controlled slider cancellation emits once and leaves external values authoritative" {
  let changes : Array[Array[Int]] = []
  let commits : Array[Array[Int]] = []
  let runtime = form_test_page(page => {
      @minimoon_ui.root(page, context => {
        let (values, update) = @minimoon.create_variable([20, 80])
        let slider = @minimoon_ui.slider_values_controlled(
          context,
          id="range",
          values~,
          on_change=@minimoon.Emit(values => {
            changes.push(values.copy())
            @minimoon.none
          }),
          on_commit=@minimoon.Emit(values => {
            commits.push(values.copy())
            @minimoon.none
          }),
          spec=@headless.slider_spec(step=5, min_steps_between=2),
        )
        slider.map(node => {
          @minimoon.div([
            node,
            @minimoon_ui.button(
              event_key="external-values",
              on_tap=update(_ => [35, 90]),
              "External values",
            ),
          ])
        })
      })
    })
    .create_runtime()
    .unwrap()
  defer ignore(runtime.dispose())
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.lifecycle("onShow", "{}"))
  ignore(runtime.mount())
  ignore(
    runtime.dispatch("range/gesture/touchstart", slider_touch(7, 40.0, 0.0)),
  )
  ignore(
    runtime.resolve_effect(
      runtime.page_id() + ":0",
      "success",
      slider_measurement("range-track"),
    ),
  )
  assert_eq(changes, [[40, 80]])
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":20"))
  ignore(runtime.dispatch("external-values", "{}"))
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":35"))
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":90"))
  assert_eq(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([7], [8])),
    "[]",
  )
  assert_eq(changes, [[40, 80]])
  ignore(
    runtime.dispatch("range/gesture/touchmove", slider_touch(7, 65.0, 0.0)),
  )
  assert_eq(changes, [[40, 80], [65, 90]])
  ignore(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([], [7])),
  )
  assert_eq(changes, [[40, 80], [65, 90], [20, 80]])
  assert_eq(commits, [])
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":35"))
  assert_true(runtime.snapshot().contains("\"ariaValueNow\":90"))
  let before = runtime.snapshot()
  assert_eq(
    runtime.dispatch("range/gesture/touchcancel", slider_cancel_event([], [7])),
    "[]",
  )
  assert_eq(changes, [[40, 80], [65, 90], [20, 80]])
  assert_eq(commits, [])
  assert_eq(runtime.snapshot(), before)
}
