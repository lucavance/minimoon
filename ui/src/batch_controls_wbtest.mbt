///|
fn control_batch(keys : Array[String]) -> String {
  Json::array(
    keys.map(key => {
      Json::object({ "key": Json::string(key), "payload": Json::empty_object() })
    }),
  ).stringify()
}

///|
test "multiple combobox applies both option toggles from one decoded batch" {
  let runtime = advanced_native_page(context => {
    combobox_provider(
      context,
      id="batched-combo",
      options=@minimoon.Val::constant([
        choice_option(key="a", label="A"),
        choice_option(key="b", label="B"),
      ]),
      initial=combobox_state(open=true),
      multiple=true,
    )
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    control_batch(["batched-combo/option/a", "batched-combo/option/b"]),
  )
  assert_true(runtime.snapshot().contains("batched-combo/remove/a"))
  assert_true(runtime.snapshot().contains("batched-combo/remove/b"))
  let _ = runtime.dispose()
}

///|
test "multiple accordion applies both panel toggles from one decoded batch" {
  let runtime = advanced_native_page(_ => {
    accordion(
      id="batched-accordion",
      multiple=true,
      items=@minimoon.Val::constant([
        panel(key="a", title="A", content=@minimoon.text("panel-A")),
        panel(key="b", title="B", content=@minimoon.text("panel-B")),
      ]),
    )
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    control_batch(["batched-accordion/a", "batched-accordion/b"]),
  )
  assert_true(runtime.snapshot().contains("panel-A"))
  assert_true(runtime.snapshot().contains("panel-B"))
  let _ = runtime.dispose()
}

///|
test "carousel advances twice for two next actions in one decoded batch" {
  let runtime = carousel_test_runtime(false, Horizontal)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(control_batch(["slides/next", "slides/next"]))
  assert_true(runtime.snapshot().contains("state:2:3:0"))
  let _ = runtime.dispose()
}

///|
test "simple carousel also advances both relative steps in one decoded batch" {
  let runtime = advanced_native_page(_ => {
    carousel(
      id="simple-batch",
      items=@minimoon.Val::constant([
        panel(key="a", title="A", content=@minimoon.text("A")),
        panel(key="b", title="B", content=@minimoon.text("B")),
        panel(key="c", title="C", content=@minimoon.text("C")),
      ]),
    )
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    control_batch(["simple-batch/next", "simple-batch/next"]),
  )
  assert_eq(
    native_prop(runtime, "simple-batch-swiper", "current"),
    Some(Json::number(2.0)),
  )
  let _ = runtime.dispose()
}

///|
test "navigation duplicate trigger taps in one decoded batch close the same item" {
  let runtime = navigation_test_runtime(true)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    control_batch(["nav/trigger/a", "nav/trigger/a"]),
  )
  assert_false(runtime.snapshot().contains("panel-a-"))
  let _ = runtime.dispatch_batch(
    control_batch(["nav/trigger/a", "nav/trigger/b"]),
  )
  assert_false(runtime.snapshot().contains("panel-a-"))
  assert_true(runtime.snapshot().contains("panel-b-"))
  let _ = runtime.dispose()
}

///|
test "sidebar duplicate and mixed toggle requests use current independent fields in a batch" {
  let runtime = sidebar_test_runtime(SidebarLeft, SidebarIcon)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    control_batch([
      "side/toggle", "side/toggle", "side/mobile-toggle", "side/mobile-toggle",
    ]),
  )
  assert_true(runtime.snapshot().contains("state:false:false:256:0"))
  let _ = runtime.dispatch_batch(
    control_batch(["side/toggle", "side/mobile-toggle"]),
  )
  assert_true(runtime.snapshot().contains("state:true:true:256:0"))
  let _ = runtime.dispose()
}
