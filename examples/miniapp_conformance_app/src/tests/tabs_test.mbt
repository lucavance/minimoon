///|
test "all routes have one clear responsibility and no duplicated control panels" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let home = app.mount(@showcase.program)
  let interaction = app.mount(@interaction.program)
  let platform = app.mount(@platform.program)
  let application = app.mount(@application_page.program)
  let lifecycle = app.mount(@request_lifecycle.program)
  let lab = app.mount(@runtime_lab.program)
  let editor = app.mount(@draft_editor.program, input={ "from": "test" })
  for
    entry in [
      (home, "showcase-transaction"),
      (interaction, "interaction-native"),
      (platform, "platform-http"),
      (application, "application-controls"),
      (lifecycle, "page-request-probe"),
      (lab, "dynamic-lab"),
      (editor, "draft-editor"),
    ] {
    assert_true(entry.0.query(@testing.by_section(entry.1)) is Some(_))
  }
  for page in [home, interaction, platform, lifecycle, lab, editor] {
    assert_true(page.query(@testing.by_section("application-controls")) is None)
  }
  for page in [home, interaction, application, lifecycle, lab, editor] {
    assert_true(page.query(@testing.by_section("platform-http")) is None)
  }
  for page in [home, platform, application, lifecycle, lab, editor] {
    assert_true(page.query(@testing.by_section("composed-controls")) is None)
  }
  assert_true(
    editor.query(@testing.by_section("application-observer")) is Some(_),
  )
  assert_true(
    lifecycle.query(@testing.by_section("application-request-probe")) is Some(_),
  )
  assert_true(lifecycle.query(@testing.by_event_key("shared/inc")) is None)
  assert_true(editor.query(@testing.by_event_key("shared/load")) is None)
  assert_true(interaction.query(@testing.by_section("dynamic-lab")) is None)
  assert_true(
    interaction.query(@testing.by_event_key("interaction/toggle-probes"))
    is None,
  )
}

///|
test "App controller and editor observer share values but retain independent local state" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let controller = app.mount(@application_page.program)
  let editor = app.mount(@draft_editor.program, input={ "from": "application" })
  let platform = app.mount(@platform.program)
  let lifecycle = app.mount(@request_lifecycle.program, input={
    "name": "Probe",
  })
  ignore(
    platform.input(
      @testing.by_event_key("platform/storage-input"),
      "Stored text",
    ),
  )
  ignore(
    editor.input(
      @testing.by_event_key("draft_editor/draft-title"),
      "Local draft",
    ),
  )
  ignore(controller.tap(@testing.by_event_key("shared/inc")))
  app.quiesce()
  for page in [controller, editor] {
    assert_true(page.snapshot().contains("Application shared count: 1"))
  }
  ignore(editor.lifecycle("onHide"))
  ignore(controller.tap(@testing.by_event_key("shared/inc")))
  app.quiesce()
  ignore(editor.lifecycle("onShow"))
  app.quiesce()
  assert_true(editor.snapshot().contains("Application shared count: 2"))
  assert_true(editor.snapshot().contains("Local draft"))
  assert_false(controller.snapshot().contains("Local draft"))
  assert_true(platform.snapshot().contains("Stored text"))
  assert_true(lifecycle.snapshot().contains("页内标记：Probe"))
  assert_false(lifecycle.snapshot().contains("Stored text"))
  ignore(controller.dispose())
  ignore(editor.tap(@testing.by_event_key("shared/inc")))
  app.quiesce()
  assert_true(editor.snapshot().contains("Application shared count: 3"))
}

///|
test "only platform toggles HTTP details while retaining its storage input" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let platform = app.mount(@platform.program)
  let detail = @testing.by_section("http-response-detail")
  assert_true(platform.query(detail) is None)
  ignore(
    platform.input(
      @testing.by_event_key("platform/storage-input"),
      "Retained draft",
    ),
  )
  ignore(platform.tap(@testing.by_event_key("platform/toggle-response")))
  assert_true(platform.query(detail) is Some(_))
  ignore(platform.tap(@testing.by_event_key("platform/toggle-response")))
  assert_true(platform.query(detail) is None)
  assert_true(platform.snapshot().contains("Retained draft"))
}

///|
test "interaction owns native controls and independent local component scopes" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let tab = app.mount(@interaction.program)
  let probe = app.mount(@runtime_lab.program, input={ "instance": "isolated" })
  let note = @testing.by_event_key("$component:toggle-card:cards:primary/note")
  ignore(tab.input(note, "Tab component draft"))
  assert_true(tab.snapshot().contains("Tab component draft"))
  assert_false(probe.snapshot().contains("Tab component draft"))
  ignore(tab.input(@testing.by_event_key("interaction/name"), "Native text"))
  ignore(
    tab.change(
      @testing.by_event_key("controls/checked"),
      ["typed", "scoped"].to_json(),
    ),
  )
  ignore(
    tab.change(@testing.by_event_key("controls/radio"), Json::string("miniapp")),
  )
  assert_true(tab.snapshot().contains("选择：typed, scoped · miniapp"))
  ignore(tab.lifecycle("onHide"))
  ignore(tab.lifecycle("onShow"))
  assert_true(tab.snapshot().contains("Native text"))
  assert_true(tab.snapshot().contains("Tab component draft"))
  ignore(probe.dispose())
  assert_true(tab.snapshot().contains("Tab component draft"))
}

///|
test "homepage uses Tab shortcuts and only feature pages link to their deeper workflow" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let page = app.mount(@showcase.program)
  for name in ["interaction", "platform", "application"] {
    let command = page.tap(@testing.by_event_key("showcase/tab-" + name))
    assert_true(command.contains("SwitchTab"))
    assert_true(command.contains("/pages/" + name + "/" + name))
    assert_false(command.contains("?"))
  }
  let application = app.mount(@application_page.program)
  let editor = application.tap(@testing.by_event_key("application/open-editor"))
  assert_true(
    editor.contains("/pages/draft_editor/draft_editor?from=application"),
  )
  let lifecycle = application.tap(
    @testing.by_event_key("application/open-request-lifecycle"),
  )
  assert_true(
    lifecycle.contains(
      "/pages/request_lifecycle/request_lifecycle?name=Application",
    ),
  )
}

///|
fn layout(
  width : Double,
  height : Double,
  status : Double,
) -> @minimoon.PageLayout {
  {
    window: Some({
      window_width: width,
      window_height: height,
      screen_width: width,
      screen_height: height,
      screen_top: 0.0,
      status_bar_height: status,
      safe_area: None,
    }),
    menu_button: Some({
      left: width - 100.0,
      top: status + 4.0,
      width: 88.0,
      height: 32.0,
    }),
  }
}

///|
test "actual layout and resize update the shell without resetting native input identity" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let page = app.mount(@platform.program, layout=layout(390.0, 760.0, 47.0))
  let input = @testing.by_event_key("platform/storage-input")
  ignore(page.input(input, "Retained through resize"))
  let identity = page.get(input).identity()
  assert_true(page.snapshot().contains("height:760px"))
  let command = page.update_layout(layout(760.0, 390.0, 24.0))
  assert_false(command.contains("RuntimeError"))
  page.quiesce()
  assert_true(page.snapshot().contains("height:390px"))
  assert_eq(page.get(input).identity(), identity)
  assert_eq(
    page.get(input).prop("value"),
    Some(Json::string("Retained through resize")),
  )
  assert_true(page.snapshot().contains("height:68px"))
}
