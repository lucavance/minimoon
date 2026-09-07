///|
test "message scroller custom controls preserve guarded jump behavior and can be hidden" {
  for show_buttons in [true, false] {
    let runtime = advanced_native_page(context => {
      message_scroller(
        context,
        id="custom-messages",
        items=@minimoon.Val::constant([
          message_item(key="a", content=@minimoon.text("Message")),
        ]),
        initially_at_end=false,
        show_buttons~,
        render_button=(direction, command, disabled) => {
          @minimoon.button_children(
            id=if direction == ScrollStart {
              "history-control"
            } else {
              "latest-control"
            },
            event_key=if direction == ScrollStart {
              "custom-start"
            } else {
              "custom-end"
            },
            on_tap=command,
            disabled~,
            [
              @minimoon.text(
                if direction == ScrollStart {
                  "History"
                } else {
                  "Newest"
                },
              ),
              @minimoon.text(" rich"),
            ],
          )
        },
      )
    })
    let initial = runtime.mount()
    let _ = native_resolve(runtime, initial, [
      native_rect("custom-messages-viewport", 300.0, 200.0),
      native_rect("custom-messages-content", 300.0, 600.0),
    ])
    if show_buttons {
      assert_eq(
        native_prop(runtime, "history-control", "disabled"),
        Some(Json::boolean(true)),
      )
      assert_eq(
        native_prop(runtime, "latest-control", "disabled"),
        Some(Json::boolean(false)),
      )
      let _ = runtime.dispatch("custom-end", "{}")
      assert_eq(
        native_prop(runtime, "custom-messages-viewport", "scrollTop"),
        Some(Json::number(400.0)),
      )
      assert_eq(
        native_prop(runtime, "latest-control", "disabled"),
        Some(Json::boolean(true)),
      )
      let _ = runtime.dispatch("custom-start", "{}")
      assert_eq(
        native_prop(runtime, "custom-messages-viewport", "scrollTop"),
        Some(Json::number(0.0)),
      )
    } else {
      assert_true(native_prop(runtime, "history-control", "disabled") is None)
      assert_true(native_prop(runtime, "latest-control", "disabled") is None)
    }
    let _ = runtime.dispose()
  }
}
