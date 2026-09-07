///|
fn navigation_test_runtime(viewport : Bool) -> @minimoon.PageRuntime {
  @minimoon.page(
    id="navigation_test",
    route=@minimoon.route("pages/navigation/index"),
    title="Navigation",
    capabilities=[@minimoon.MeasureNodes],
    build=page => {
      root(page, context => {
        let (revision, change) = @minimoon.create_variable(0)
        navigation_menu_provider_with_input(
          context,
          id="nav",
          input=revision,
          viewport~,
          render=(scope, revision) => {
            @minimoon.fragment([
              navigation_menu_viewport(scope, @minimoon.text("shared chrome")),
              @minimoon.button(
                event_key="revision",
                on_tap=change(value => value + 1),
                "Change input",
              ),
              navigation_menu_list(
                scope,
                ["a", "b", "disabled"].map(value => {
                  navigation_menu_item(
                    scope,
                    value~,
                    disabled=value == "disabled",
                    render=item => {
                      @minimoon.fragment([
                        navigation_menu_trigger(item, @minimoon.text(value)),
                        navigation_menu_indicator(item),
                        navigation_menu_content(item, [
                          @minimoon.text(
                            "panel-" + value + "-" + revision.to_string(),
                          ),
                          navigation_menu_link(
                            scope~,
                            target=@minimoon.route("pages/next/index"),
                            @minimoon.text("Visit"),
                          ),
                        ]),
                      ])
                    },
                  )
                }),
              ),
            ])
          },
        )
      })
    },
  ).create_runtime()
}

///|
test "navigation compound viewport handles switching stale placement and dynamic input" {
  let runtime = navigation_test_runtime(true)
  let _ = runtime.mount()
  assert_false(runtime.snapshot().contains("panel-a-"))
  let request_a = runtime.dispatch("nav/trigger/a", "{}")
  assert_true(runtime.snapshot().contains("panel-a-0"))
  assert_true(runtime.snapshot().contains("shared chrome"))
  assert_true(runtime.snapshot().contains("pages/next/index"))
  let _ = runtime.dispatch("revision", "{}")
  assert_true(runtime.snapshot().contains("panel-a-1"))
  let request_b = runtime.dispatch("nav/trigger/b", "{}")
  assert_false(runtime.snapshot().contains("panel-a-"))
  let _ = native_resolve(runtime, request_b, [
    native_rect("nav-trigger-98", 100.0, 40.0),
    native_rect("nav-viewport", 240.0, 120.0),
    native_rect("mmui-viewport", 400.0, 600.0),
  ])
  let placed = runtime.snapshot()
  assert_true(placed.contains("top:48px"))
  let _ = native_resolve(runtime, request_a, [
    native_rect("nav-trigger-97", 100.0, 200.0),
    native_rect("nav-viewport", 240.0, 120.0),
    native_rect("mmui-viewport", 400.0, 600.0),
  ])
  assert_eq(runtime.snapshot(), placed)
  let _ = runtime.dispatch("nav/trigger/disabled", "{}")
  assert_eq(runtime.snapshot(), placed)
  let _ = runtime.lifecycle("onHide", "{}")
  assert_false(runtime.snapshot().contains("panel-b-"))
  let _ = runtime.lifecycle("onShow", "{}")
  assert_false(runtime.snapshot().contains("panel-b-"))
  let _ = runtime.dispose()
}

///|
test "navigation without shared viewport measures individual content and closes on repeated tap" {
  let runtime = navigation_test_runtime(false)
  let _ = runtime.mount()
  let command = runtime.dispatch("nav/trigger/a", "{}")
  assert_true(command.contains("nav-content-97"))
  assert_false(runtime.snapshot().contains("shared chrome"))
  let _ = native_resolve(runtime, command, [
    native_rect("nav-trigger-97", 100.0, 40.0),
    native_rect("nav-content-97", 240.0, 120.0),
    native_rect("mmui-viewport", 400.0, 600.0),
  ])
  assert_true(runtime.snapshot().contains("top:48px"))
  let _ = runtime.dispatch("nav/trigger/a", "{}")
  assert_false(runtime.snapshot().contains("panel-a-"))
  let _ = runtime.dispose()
}
