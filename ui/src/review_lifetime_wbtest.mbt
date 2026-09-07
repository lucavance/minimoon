///|
#cfg(target="js")
test "externally controlled overlay transitions invalidate pending delayed open requests" {
  let runtime = advanced_native_page(context => {
    let (open, change) = @minimoon.create_variable(false)
    stack([
      overlay_provider_controlled(
        context,
        id="race",
        open~,
        on_open_change=change.map(value => _ => value),
        delay_ms=100,
        render=scope => {
          @minimoon.fragment([
            overlay_trigger(scope, "Trigger"),
            overlay_content(scope, "Content"),
          ])
        },
      ),
      @minimoon.Val::constant(
        @minimoon.button(
          event_key="external-open",
          on_tap=change(_ => true),
          "Open",
        ),
      ),
      @minimoon.Val::constant(
        @minimoon.button(
          event_key="external-close",
          on_tap=change(_ => false),
          "Close",
        ),
      ),
    ])
  })
  let _ = runtime.mount()
  let pending = runtime.dispatch("race/trigger", "{}")
  let _ = runtime.dispatch("external-open", "{}")
  let _ = runtime.dispatch("external-close", "{}")
  assert_true(native_prop(runtime, "race-surface", "style") is None)
  let _ = runtime.resolve_effect(advanced_timeout(pending), "success", "{}")
  assert_true(native_prop(runtime, "race-surface", "style") is None)
  let _ = runtime.dispose()
}
