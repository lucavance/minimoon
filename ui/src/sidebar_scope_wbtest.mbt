///|
fn sidebar_test_runtime(
  side : SidebarSide,
  collapsible : SidebarCollapsible,
) -> @minimoon.PageRuntime {
  let runtime = @minimoon.page(
      id="sidebar_test",
      route=@minimoon.route("pages/sidebar/index"),
      title="Sidebar",
      capabilities=[@minimoon.MeasureNodes],
      build=page => {
        root(page, context => {
          let (revision, change) = @minimoon.create_variable(0)
          sidebar_provider_with_input(context, id="side", input=revision, render=(
            scope,
            revision,
          ) => {
            @minimoon.fragment([
              @minimoon.text(
                "state:" +
                sidebar_is_collapsed(scope).to_string() +
                ":" +
                sidebar_is_mobile_open(scope).to_string() +
                ":" +
                sidebar_width(scope).to_string() +
                ":" +
                revision.to_string(),
              ),
              @minimoon.button(
                event_key="revision",
                on_tap=change(value => value + 1),
                "Change input",
              ),
              sidebar_trigger(scope, @minimoon.text("Toggle")),
              sidebar_trigger(scope, mobile=true, @minimoon.text("Mobile")),
              sidebar_surface(scope, side~, collapsible~, render=surface => {
                @minimoon.fragment([
                  sidebar_header(@minimoon.text("Header")),
                  sidebar_group([
                    sidebar_group_label(surface, @minimoon.text("Group label")),
                    sidebar_group_content(
                      sidebar_menu(
                        sidebar_menu_item([
                          sidebar_menu_button_with_tooltip(
                            surface,
                            id="helpful",
                            tooltip="Helpful action",
                            icon=@minimoon.text("H"),
                            @minimoon.text("Expanded action"),
                          ),
                          sidebar_menu_badge(
                            surface,
                            @minimoon.text("Badge content"),
                          ),
                          sidebar_menu_sub(
                            surface,
                            sidebar_menu_sub_item(
                              sidebar_menu_sub_button(
                                surface,
                                @minimoon.text("Nested entry"),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                  sidebar_footer(@minimoon.text("Footer")),
                  sidebar_rail(surface, min_width=200.0, max_width=300.0),
                ])
              }),
              sidebar_surface(scope, mobile=true, side~, render=surface => {
                sidebar_menu_button(
                  surface,
                  target=@minimoon.route("pages/next/index"),
                  event_key="mobile-link",
                  @minimoon.text("Mobile content"),
                )
              }),
              sidebar_inset(@minimoon.text("Inset content")),
            ])
          })
        })
      },
    )
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  runtime
}

///|
test "sidebar preserves independent collapse and mobile state across dynamic input" {
  let runtime = sidebar_test_runtime(SidebarLeft, SidebarIcon)
  let _ = runtime.mount()
  assert_true(runtime.snapshot().contains("state:false:false:256:0"))
  assert_true(runtime.snapshot().contains("Nested entry"))
  assert_false(runtime.snapshot().contains("helpful/help"))
  let _ = runtime.dispatch("side/toggle", "{}")
  assert_true(runtime.snapshot().contains("state:true:false:256:0"))
  assert_true(runtime.snapshot().contains("width:48px"))
  assert_false(runtime.snapshot().contains("Group label"))
  assert_false(runtime.snapshot().contains("Nested entry"))
  assert_false(runtime.snapshot().contains("Badge content"))
  assert_true(runtime.snapshot().contains("helpful/help"))
  let _ = runtime.dispatch("revision", "{}")
  assert_true(runtime.snapshot().contains("state:true:false:256:1"))
  let _ = runtime.dispatch("side/mobile-toggle", "{}")
  assert_true(runtime.snapshot().contains("state:true:true:256:1"))
  assert_true(runtime.snapshot().contains("Mobile content"))
  let _ = runtime.dispatch("mobile-link", "{}")
  assert_true(runtime.snapshot().contains("state:true:false:256:1"))
  assert_false(runtime.snapshot().contains("Mobile content"))
  let _ = runtime.dispose()
}

///|
test "sidebar rail clamps both sides tracks pointer and restores on cancel or hide" {
  for side in [SidebarLeft, SidebarRight] {
    let runtime = sidebar_test_runtime(side, SidebarIcon)
    let _ = runtime.mount()
    let x = if side == SidebarLeft { 200.0 } else { 0.0 }
    let _ = runtime.dispatch(
      "side/rail/touchstart",
      native_touch(100.0, 0.0, 0.0),
    )
    let _ = runtime.dispatch(
      "side/rail/touchmove",
      native_touch(x, 0.0, 100.0, pointer=2),
    )
    assert_true(runtime.snapshot().contains("state:false:false:256:0"))
    let _ = runtime.dispatch("side/rail/touchmove", native_touch(x, 0.0, 100.0))
    assert_true(runtime.snapshot().contains("state:false:false:300:0"))
    let _ = runtime.dispatch(
      "side/rail/touchcancel",
      native_touch(x, 0.0, 101.0, pointer=2),
    )
    assert_true(runtime.snapshot().contains("state:false:false:300:0"))
    let _ = runtime.dispatch(
      "side/rail/touchcancel",
      native_touch(x, 0.0, 102.0),
    )
    assert_true(runtime.snapshot().contains("state:false:false:256:0"))
    let _ = runtime.dispatch(
      "side/rail/touchstart",
      native_touch(100.0, 0.0, 200.0),
    )
    let _ = runtime.dispatch("side/rail/touchmove", native_touch(x, 0.0, 300.0))
    let _ = runtime.lifecycle("onHide", "{}")
    assert_true(runtime.snapshot().contains("state:false:false:256:0"))
    let _ = runtime.lifecycle("onShow", "{}")
    let _ = runtime.dispatch(
      "side/rail/touchstart",
      native_touch(100.0, 0.0, 400.0),
    )
    let _ = runtime.dispatch("side/rail/touchend", native_touch(x, 0.0, 500.0))
    assert_true(runtime.snapshot().contains("state:false:false:300:0"))
    let _ = runtime.dispatch("side/rail/tap", "{}")
    assert_true(runtime.snapshot().contains("state:false:false:300:0"))
    let _ = runtime.dispatch("side/rail/tap", "{}")
    assert_true(runtime.snapshot().contains("state:true:false:300:0"))
    let _ = runtime.dispose()
  }
}

///|
test "sidebar tooltip is icon-only measured and invalidates stale replies" {
  let runtime = sidebar_test_runtime(SidebarLeft, SidebarIcon)
  let _ = runtime.mount()
  let _ = runtime.dispatch("side/toggle", "{}")
  let request = runtime.dispatch("helpful/help", "{}")
  assert_true(runtime.snapshot().contains("mmui-sidebar-tooltip"))
  let _ = native_resolve(runtime, request, [
    native_rect("helpful", 48.0, 44.0),
    native_rect("helpful-tooltip", 120.0, 40.0),
    native_rect("mmui-viewport", 400.0, 600.0),
  ])
  assert_true(runtime.snapshot().contains("left:52px"))
  let stale = runtime.dispatch("helpful/help", "{}")
  let _ = runtime.dispatch("side/toggle", "{}")
  assert_false(runtime.snapshot().contains("mmui-sidebar-tooltip"))
  let before = runtime.snapshot()
  let _ = native_resolve(runtime, stale, [
    native_rect("helpful", 48.0, 44.0),
    native_rect("helpful-tooltip", 120.0, 40.0),
    native_rect("mmui-viewport", 400.0, 600.0),
  ])
  assert_eq(runtime.snapshot(), before)
  let _ = runtime.dispose()
  for collapsible in [SidebarFixed, SidebarOffcanvas] {
    let runtime = sidebar_test_runtime(SidebarRight, collapsible)
    let _ = runtime.mount()
    let _ = runtime.dispatch("side/toggle", "{}")
    assert_false(runtime.snapshot().contains("helpful/help"))
    if collapsible == SidebarFixed {
      assert_true(runtime.snapshot().contains("Expanded action"))
    } else {
      assert_false(runtime.snapshot().contains("Expanded action"))
    }
    let _ = runtime.dispose()
  }
}
