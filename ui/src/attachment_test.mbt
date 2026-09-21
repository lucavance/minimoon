///|
test "attachment states and typed sizes map to native semantics and styles" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      @minimoon.Val::constant(
        @minimoon.div([
          @minimoon_ui.attachment(
            id="upload",
            state=AttachmentUploading,
            size=AttachmentXs,
            orientation=Vertical,
            [
              @minimoon_ui.attachment_media(
                id="icon",
                variant=IconMedia,
                content=@minimoon.text("File"),
              ),
              @minimoon_ui.attachment_content([
                @minimoon_ui.attachment_title("Upload"),
                @minimoon_ui.attachment_description("Working"),
              ]),
            ],
          ),
          @minimoon_ui.attachment(id="error", state=AttachmentError, [
            @minimoon_ui.attachment_media(
              src="/assets/mmui/check-dark.svg",
              error=true,
            ),
            @minimoon_ui.attachment_title("Failed"),
          ]),
          @minimoon_ui.attachment(
            id="processing",
            state=AttachmentProcessing,
            @minimoon_ui.attachment_title("Processing"),
          ),
          @minimoon_ui.attachment(
            id="idle",
            state=AttachmentIdle,
            @minimoon_ui.attachment_title("Ready"),
          ),
          @minimoon_ui.attachment(
            id="done",
            state=AttachmentDone,
            @minimoon_ui.attachment_title("Complete"),
          ),
        ]),
      )
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("upload")).prop("ariaBusy"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("processing")).prop("ariaBusy"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    runtime.get(@testing.by_id("done")).prop("ariaBusy"),
    Some(Json::boolean(false)),
  )
  assert_eq(
    runtime.get(@testing.by_id("error")).prop("ariaInvalid"),
    Some(Json::boolean(true)),
  )
  assert_true(
    runtime
    .get(@testing.by_id("upload"))
    .snapshot()
    .contains("mmui-attachment-xs"),
  )
  assert_eq(runtime.get(@testing.by_id("icon")).text_content(), "File")
}

///|
test "attachment rich action guards disabled activation and navigation" {
  let runtime = @testing.mount(
    form_test_page(_ => {
      let (count, update) = @minimoon.create_variable(0)
      count.map(count => {
        @minimoon_ui.attachment([
          @minimoon_ui.attachment_action(
            id="active",
            label="Retry",
            content=@minimoon.text("Retry " + count.to_string()),
            on_tap=update(count => count + 1),
          ),
          @minimoon_ui.attachment_action(
            id="disabled",
            label="Remove",
            disabled=true,
            on_tap=update(count => count + 1),
          ),
          @minimoon_ui.attachment_trigger_link(
            id="link",
            target=@minimoon.route("pages/files/files"),
            disabled=true,
            "File",
          ),
        ])
      })
    }),
  )
  let _ = runtime.tap(@testing.by_id("active"))
  let _ = runtime.tap(@testing.by_id("disabled"))
  assert_eq(runtime.get(@testing.by_id("active")).text_content(), "Retry 1")
  assert_eq(
    runtime.get(@testing.by_id("link")).prop("ariaDisabled"),
    Some(Json::boolean(true)),
  )
  assert_true(runtime.get(@testing.by_id("link")).event("tap") is None)
}
