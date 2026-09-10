///|
test "nine routes separate business from technical laboratories" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let home = app.mount(@showcase.program)
  let drafts = app.mount(@application_page.program)
  let online = app.mount(@online.program)
  let more = app.mount(@more.program)
  let interaction = app.mount(@interaction.program)
  let platform = app.mount(@platform.program)
  let lifecycle = app.mount(@request_lifecycle.program)
  let lab = app.mount(@runtime_lab.program)
  let editor = app.mount(@draft_editor.program, input={ "from": "test" })
  for
    (page, section) in [
      (home, "workbench-overview"),
      (drafts, "saved-drafts"),
      (online, "work-echo"),
      (more, "work-laboratory"),
      (interaction, "interaction-native"),
      (platform, "platform-http"),
      (lifecycle, "application-controls"),
      (lab, "dynamic-lab"),
      (editor, "draft-editor"),
    ] {
    assert_true(page.query(@testing.by_section(section)) is Some(_))
  }
  for page in [home, drafts, online, more, editor] {
    assert_true(page.query(@testing.by_event_key("shared/inc")) is None)
    assert_true(page.query(@testing.by_section("platform-http")) is None)
    assert_true(page.query(@testing.by_section("composed-controls")) is None)
  }
}

///|
test "editor buffer is App-owned and business Tabs catch up after being hidden" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let home = app.mount(@showcase.program)
  let online = app.mount(@online.program)
  let editor = app.mount(@draft_editor.program, input={ "from": "test" })
  ignore(home.lifecycle("onHide"))
  ignore(
    editor.input(
      @testing.by_event_key("draft_editor/draft-title"),
      "Retained idea",
    ),
  )
  app.quiesce()
  assert_true(online.snapshot().contains("Retained idea"))
  ignore(editor.dispose())
  ignore(home.lifecycle("onShow"))
  app.quiesce()
  assert_true(home.snapshot().contains("Retained idea"))
  let reopened = app.mount(@draft_editor.program, input={ "from": "test" })
  assert_true(reopened.snapshot().contains("Retained idea"))
}

///|
test "confirmation is scrolled into view and cancelling leaves the draft untouched" {
  let runtime = @application.program().create_runtime()
  defer ignore(runtime.dispose())
  let deps = runtime.deps()
  let page = runtime.create_page(@application_page.program(deps)).unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  guard @json.parse(runtime.lifecycle("onLaunch", "{}")) is Array(commands) else {
    fail("missing App launch")
  }
  let mut loaded = false
  for command in commands {
    if command is Object(fields) &&
      fields.get("capability") == Some(Json::string("wx.getStorage")) &&
      fields.get("request_id") is Some(String(id)) {
      ignore(
        runtime.resolve_effect(
          id, "failure", "{\"error\":\"getStorage:fail data not found\"}",
        ),
      )
      loaded = true
    }
  }
  assert_true(loaded)
  ignore(runtime.dispatch((deps.send)(@application.Title("retained"))))
  ignore(runtime.dispatch((deps.send)(@application.Choose(@application.New))))
  ignore(page.flush())
  assert_true(page.snapshot().contains("work-confirmation"))
  assert_true(
    page.snapshot().contains("\"scrollIntoView\":\"work-confirmation\""),
  )
  ignore(runtime.dispatch((deps.send)(@application.Cancel)))
  ignore(page.flush())
  assert_false(page.snapshot().contains("work-confirmation"))
  let editor = runtime
    .create_page(@draft_editor.program(deps), input={ "from": "test" })
    .unwrap()
  ignore(editor.lifecycle("onLoad", "{\"from\":\"test\"}"))
  ignore(editor.mount())
  assert_true(editor.snapshot().contains("retained"))
}

///|
test "business navigation is query-free for Tabs and laboratories are secondary pages" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let page = app.mount(@showcase.program)
  let command = page.tap(@testing.by_event_key("workbench/drafts"))
  assert_true(command.contains("SwitchTab"))
  assert_false(command.contains("?"))
  let more = app.mount(@more.program)
  for name in ["interaction", "platform", "request_lifecycle", "runtime_lab"] {
    let command = more.tap(@testing.by_event_key("more/" + name))
    assert_true(command.contains("NavigateTo"))
    assert_true(command.contains("/pages/" + name + "/" + name))
  }
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
