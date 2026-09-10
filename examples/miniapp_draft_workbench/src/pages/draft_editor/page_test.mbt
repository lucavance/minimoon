///|
fn open_editor(
  app : @minimoon.AppRuntime[@application.Deps],
) -> @minimoon.PageRuntime {
  let page = app
    .create_page(program(app.deps()), input={ "from": "test" })
    .unwrap()
  ignore(page.lifecycle("onLoad", "{\"from\":\"test\"}"))
  ignore(page.lifecycle("onShow", "{}"))
  ignore(page.mount())
  page
}

///|
fn edit(
  app : @minimoon.AppRuntime[@application.Deps],
  page : @minimoon.PageRuntime,
  title : String,
) -> Unit {
  ignore(
    page.dispatch(
      "draft_editor/draft-title",
      Json::object({ "detail": Json::object({ "value": Json::string(title) }) }).stringify(),
    ),
  )
  ignore(app.flush())
  ignore(page.flush())
}

///|
fn request_id(commands : String) -> String raise {
  guard @json.parse(commands) is Array(entries) else {
    fail("expected command array")
  }
  for entry in entries {
    if entry is Object(fields) &&
      fields.get("capability") == Some(Json::string("wx.request")) &&
      fields.get("request_id") is Some(String(id)) {
      return id
    }
  }
  fail("expected request: " + commands)
}

///|
test "editor rejects malformed route input before graph creation" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  for
    fields in [
      Map([]),
      { "from": "" },
      { "from": "test", "mode": "unknown" },
      { "from": "test", "mode": "edit", "id": "-1" },
      { "from": "test", "mode": "edit", "id": "oops" },
    ] {
    assert_true(app.create_page(program(app.deps()), input=fields) is Err(_))
  }
}

///|
test "editor folds lifecycle trial and routes back with a native Tab fallback" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = open_editor(app)
  assert_false(page.snapshot().contains("来源：test"))
  assert_true(page.snapshot().contains("demo-input demo-title-input"))
  ignore(page.dispatch("draft_editor/notes", "{}"))
  assert_true(page.snapshot().contains("来源：test"))
  assert_true(page.snapshot().contains("本页试发"))
  assert_true(page.snapshot().contains("保存到本地"))
  assert_false(page.snapshot().contains("shared/inc"))
  let back = page.dispatch("Back", "{}")
  assert_true(back.contains("NavigateBackOrRedirect"))
  assert_true(back.contains("/pages/workbench/workbench"))
  let online = page.dispatch("draft_editor/online", "{}")
  assert_true(online.contains("SwitchTab"))
  assert_true(online.contains("/pages/online/online"))
}

///|
test "page trial validates without HTTP, ignores newer edits and cancels on unload" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  ignore(app.lifecycle("onLaunch", "{}"))
  let page = open_editor(app)
  ignore(page.dispatch("draft_editor/notes", "{}"))
  assert_false(
    page.dispatch("draft_editor/page-send", "{}").contains("wx.request"),
  )
  assert_true(page.snapshot().contains("标题不能为空"))
  edit(app, page, "first")
  let request = page.dispatch("draft_editor/page-send", "{}")
  let id = request_id(request)
  assert_true(request.contains("https://httpbingo.org/post"))
  assert_false(
    page.dispatch("draft_editor/page-send", "{}").contains("wx.request"),
  )
  edit(app, page, "newer")
  ignore(
    page.resolve_effect(
      id, "success", "{\"statusCode\":200,\"data\":{\"json\":{\"title\":\"first\",\"note\":\"\"}}}",
    ),
  )
  assert_false(page.snapshot().contains("typed-echo"))
  let request = page.dispatch("draft_editor/page-send", "{}")
  let id = request_id(request)
  assert_true(page.dispose().contains("CancelEffect"))
  assert_eq(page.resolve_effect(id, "success", "{\"statusCode\":200}"), "[]")
  let resumed = open_editor(app)
  assert_true(resumed.snapshot().contains("newer"))
  assert_false(resumed.snapshot().contains("first"))
}

///|
test "App send survives editor disposal and completes in another observer" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  ignore(app.lifecycle("onLaunch", "{}"))
  let page = open_editor(app)
  edit(app, page, "App draft")
  assert_false(page.dispatch("work/send", "{}").contains("wx.request"))
  let commands = app.flush()
  let id = request_id(commands)
  assert_false(page.dispose().contains("CancelEffect"))
  ignore(
    app.resolve_effect(
      id, "success", "{\"statusCode\":200,\"data\":{\"json\":{\"title\":\"App draft\",\"note\":\"\"}}}",
    ),
  )
  let observer = open_editor(app)
  assert_true(observer.snapshot().contains("回显成功"))
  assert_true(observer.snapshot().contains("App draft"))
  assert_true(observer.snapshot().contains("有未保存修改"))
}
