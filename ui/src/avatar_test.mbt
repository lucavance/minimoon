///|
test "avatar status tracks loading loaded error and isolates old source events" {
  let runtime = form_test_page(_ => {
      let (source, update_source) = @minimoon.create_variable("first.png")
      let (status, update_status) = @minimoon.create_variable("initial")
      let avatar = avatar_with_fallback(
        id="photo",
        src=source,
        on_status_change=update_status.map(status => {
          _ => {
            match status {
              AvatarLoading => "loading"
              AvatarLoaded => "loaded"
              AvatarError => "error"
            }
          }
        }),
        "Fallback",
      )
      @minimoon.Val::view2(avatar, status, (avatar, status) => {
        @minimoon.div([
          avatar,
          @minimoon.p("status:" + status),
          button(
            event_key="next-photo",
            on_tap=update_source(_ => "second.png"),
            "Next",
          ),
        ])
      })
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  assert_true(runtime.snapshot().contains("status:loading"))
  let _ = runtime.dispatch(
    "photo/image/first.png/load", "{\"detail\":{\"width\":20,\"height\":20}}",
  )
  assert_true(runtime.snapshot().contains("status:loaded"))
  assert_false(runtime.snapshot().contains("Fallback"))
  let _ = runtime.dispatch("next-photo", "{}")
  assert_true(runtime.snapshot().contains("status:loading"))
  assert_true(runtime.snapshot().contains("Fallback"))
  let _ = runtime.dispatch(
    "photo/image/first.png/error", "{\"detail\":{\"errMsg\":\"late\"}}",
  )
  assert_true(runtime.snapshot().contains("status:loading"))
  let _ = runtime.dispatch(
    "photo/image/second.png/error", "{\"detail\":{\"errMsg\":\"missing\"}}",
  )
  assert_true(runtime.snapshot().contains("status:error"))
  assert_true(runtime.snapshot().contains("Fallback"))
}
