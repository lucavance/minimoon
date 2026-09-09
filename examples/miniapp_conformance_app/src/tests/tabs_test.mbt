///|
test "capability Tab and stack Home share only App domains, not local models" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let tab = app.mount(@capabilities.program)
  let probe = app.mount(@home.program, input={ "name": "Probe" })
  let application = app.mount(@application_page.program)
  ignore(tab.input(@testing.by_event_key("home/name"), "Tab draft"))
  ignore(tab.tap(@testing.by_event_key("home/inc")))
  assert_true(tab.snapshot().contains("hello: Tab draft"))
  assert_true(tab.snapshot().contains("\"text\":\"1\""))
  assert_true(probe.snapshot().contains("hello: Probe"))
  assert_false(probe.snapshot().contains("Tab draft"))
  ignore(tab.tap(@testing.by_event_key("shared/inc")))
  app.quiesce()
  for page in [tab, probe, application] {
    assert_true(page.snapshot().contains("Application shared count: 1"))
  }
  ignore(tab.lifecycle("onHide"))
  ignore(probe.tap(@testing.by_event_key("shared/inc")))
  app.quiesce()
  ignore(tab.lifecycle("onShow"))
  app.quiesce()
  assert_true(tab.snapshot().contains("hello: Tab draft"))
  assert_true(tab.snapshot().contains("Application shared count: 2"))
  ignore(probe.dispose())
  ignore(tab.tap(@testing.by_event_key("home/inc")))
  assert_true(tab.snapshot().contains("\"text\":\"2\""))
}

///|
test "capability Tab collapses HTTP detail without changing the full stack probe" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let tab = app.mount(@capabilities.program)
  let probe = app.mount(@home.program)
  let detail = @testing.by_section("http-response-detail")
  assert_true(tab.query(detail) is None)
  assert_true(probe.query(detail) is Some(_))
  ignore(tab.input(@testing.by_event_key("home/name"), "Retained draft"))
  ignore(tab.tap(@testing.by_event_key("home/toggle-response")))
  assert_true(tab.query(detail) is Some(_))
  ignore(tab.tap(@testing.by_event_key("home/toggle-response")))
  assert_true(tab.query(detail) is None)
  assert_true(tab.snapshot().contains("hello: Retained draft"))
  assert_true(@home.capabilities().contains(@minimoon.SwitchTab))
}

///|
test "interaction Tab reuses Lab functions but owns independent component scopes" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let tab = app.mount(@interaction.program)
  let probe = app.mount(@lab.program, input={ "instance": "isolated" })
  let note = @testing.by_event_key("$component:toggle-card:cards:primary/note")
  ignore(tab.input(note, "Tab component draft"))
  assert_true(tab.snapshot().contains("Tab component draft"))
  assert_false(probe.snapshot().contains("Tab component draft"))
  assert_true(tab.query(@testing.by_section("dynamic-lab")) is None)
  assert_true(probe.query(@testing.by_section("dynamic-lab")) is Some(_))
  ignore(tab.tap(@testing.by_event_key("interaction/toggle-probes")))
  ignore(tab.tap(@testing.by_event_key("dynamic/increment")))
  assert_true(tab.snapshot().contains("count:1"))
  assert_true(probe.snapshot().contains("count:0"))
  ignore(tab.tap(@testing.by_event_key("interaction/toggle-probes")))
  assert_true(tab.snapshot().contains("Tab component draft"))
  ignore(probe.dispose())
  assert_true(tab.snapshot().contains("Tab component draft"))
}

///|
test "homepage Tab shortcuts differ from the retained query-bearing stack probes" {
  let app = @testing.launch(@application.program())
  defer app.dispose()
  let page = app.mount(@showcase.program)
  for name in ["interaction", "capabilities", "application"] {
    let command = page.tap(@testing.by_event_key("showcase/tab-" + name))
    assert_true(command.contains("SwitchTab"))
    assert_true(command.contains("/pages/" + name + "/" + name))
    assert_false(command.contains("?"))
  }
  let probe = page.tap(@testing.by_event_key("showcase/open-console"))
  assert_true(probe.contains("NavigateTo"))
  assert_true(probe.contains("/pages/home/home?name=Studio"))
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
  let page = app.mount(@capabilities.program, layout=layout(390.0, 760.0, 47.0))
  let input = @testing.by_event_key("home/name")
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
