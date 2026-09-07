///|
fn advanced_native_page(
  build : (UiContext) -> @minimoon.Val[@minimoon.Node],
) -> @minimoon.PageRuntime {
  @minimoon.page(
    id="advanced",
    route=@minimoon.route("pages/advanced/index"),
    title="Advanced",
    capabilities=[@minimoon.MeasureNodes],
    build=page => root(page, build),
  ).create_runtime()
}

///|
#cfg(target="js")
fn advanced_timeout(commands : String) -> String {
  guard native_json(commands) is Array(commands) else {
    abort("expected commands")
  }
  for command in commands {
    if command is Object(fields) &&
      fields.get("capability") is Some(String("minimoon.timeout")) &&
      fields.get("request_id") is Some(String(id)) {
      return id
    }
  }
  abort("missing delay")
}

///|
#cfg(target="js")
test "touch preview delays opening and closing and rejects hidden pending timers" {
  let runtime = advanced_native_page(context => {
    overlay_provider(
      context,
      id="delayed",
      kind=PreviewSurface,
      delay_ms=120,
      close_delay_ms=80,
      render=scope => {
        @minimoon.fragment([
          overlay_trigger(scope, "Preview"),
          overlay_content(scope, [
            overlay_title(scope, "Preview"),
            overlay_arrow(),
          ]),
        ])
      },
    )
  })
  let _ = runtime.mount()
  let pending = runtime.dispatch("delayed/trigger", "{}")
  assert_true(pending.contains("120"))
  assert_true(native_prop(runtime, "delayed-surface", "style") is None)
  let _ = runtime.resolve_effect(advanced_timeout(pending), "success", "{}")
  assert_true(native_prop(runtime, "delayed-surface", "style") is Some(_))
  let closing = runtime.dispatch("delayed/close", "{}")
  assert_true(closing.contains("80"))
  assert_true(native_prop(runtime, "delayed-surface", "style") is Some(_))
  let _ = runtime.resolve_effect(advanced_timeout(closing), "success", "{}")
  assert_true(native_prop(runtime, "delayed-surface", "style") is None)
  let hidden = runtime.dispatch("delayed/trigger", "{}")
  let _ = runtime.lifecycle("onHide", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.resolve_effect(advanced_timeout(hidden), "success", "{}")
  assert_true(native_prop(runtime, "delayed-surface", "style") is None)
  let _ = runtime.dispose()
}

///|
test "floating measures initially and programmatically open surfaces and discards closed scope replies" {
  let runtime = advanced_native_page(context => {
    let (open, emit) = @minimoon.create_variable(true)
    stack([
      overlay_controlled(
        context,
        id="measured",
        title="Measured",
        trigger_label="Trigger",
        content=@minimoon.Val::constant(@minimoon.text("Content")),
        open~,
        on_change=emit.map(value => _ => value),
        kind=PopoverSurface,
      ),
      @minimoon.Val::constant(
        @minimoon.button(
          event_key="external-open",
          on_tap=emit(_ => true),
          "Open externally",
        ),
      ),
    ])
  })
  let initial = runtime.mount()
  let _ = native_resolve(runtime, initial, [
    native_rect("measured-trigger", 80.0, 30.0),
    native_rect("measured-surface", 100.0, 60.0),
    native_rect("mmui-viewport", 320.0, 640.0),
  ])
  assert_true(
    native_prop(runtime, "measured-surface", "style")
    .unwrap()
    .stringify()
    .contains("top:38px"),
  )
  let _ = runtime.dispatch("measured/close", "{}")
  let pending = runtime.dispatch("external-open", "{}")
  let _ = runtime.dispatch("measured/close", "{}")
  let reopened = runtime.dispatch("external-open", "{}")
  let snapshot = runtime.snapshot()
  let _ = native_resolve(runtime, pending, [
    native_rect("measured-trigger", 80.0, 99.0),
    native_rect("measured-surface", 100.0, 60.0),
    native_rect("mmui-viewport", 320.0, 640.0),
  ])
  assert_eq(runtime.snapshot(), snapshot)
  let _ = native_resolve(runtime, reopened, [
    native_rect("measured-trigger", 80.0, 40.0),
    native_rect("measured-surface", 100.0, 60.0),
    native_rect("mmui-viewport", 320.0, 640.0),
  ])
  assert_true(
    native_prop(runtime, "measured-surface", "style")
    .unwrap()
    .stringify()
    .contains("top:48px"),
  )
  let _ = runtime.lifecycle("onHide", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  assert_true(native_prop(runtime, "measured-surface", "style") is None)
  let _ = runtime.dispose()
}

///|
test "toast swipe guards pointer identity pauses countdown and clears on hide" {
  let runtime = advanced_native_page(context => {
    stack([
      @minimoon.Val::constant(
        @minimoon.button(
          event_key="notify",
          on_tap=toast(
            context,
            toast_notice(id="swipe", title="Swipe", duration_ms=500),
          ),
          "Notify",
        ),
      ),
      toaster(context, position=ToastTopCenter),
    ])
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch("notify", "{}")
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchstart",
    native_touch(0.0, 0.0, 0.0),
  )
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchmove",
    native_touch(80.0, 0.0, 10.0),
  )
  assert_true(runtime.snapshot().contains("translateX(80px)"))
  let snapshot = runtime.snapshot()
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchcancel",
    native_touch(80.0, 0.0, 11.0, pointer=2),
  )
  assert_eq(runtime.snapshot(), snapshot)
  let _ = runtime.subscription("mmui-toast-clock", "{}")
  let _ = runtime.subscription("mmui-toast-clock", "{}")
  assert_true(native_prop(runtime, "swipe", "style") is Some(_))
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchcancel",
    native_touch(80.0, 0.0, 20.0),
  )
  assert_false(runtime.snapshot().contains("translateX(80px)"))
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchstart",
    native_touch(0.0, 0.0, 30.0),
  )
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchend",
    native_touch(80.0, 2.0, 40.0),
  )
  assert_true(native_prop(runtime, "swipe", "style") is None)
  let _ = runtime.dispatch("notify", "{}")
  let _ = runtime.dispatch(
    "toast/swipe/swipe/touchstart",
    native_touch(0.0, 0.0, 50.0),
  )
  let _ = runtime.lifecycle("onHide", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.subscription("mmui-toast-clock", "{}")
  let _ = runtime.subscription("mmui-toast-clock", "{}")
  assert_true(native_prop(runtime, "swipe", "style") is None)
  let _ = runtime.dispose()
}
