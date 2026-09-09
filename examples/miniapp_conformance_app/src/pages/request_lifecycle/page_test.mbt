///|
test "request lifecycle owns an optional marker and a page-owned delayed request" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = app
    .create_page(program(app.deps()), input={ "name": "Query Probe" })
    .unwrap()
  ignore(page.lifecycle("onLoad", "{\"name\":\"Query Probe\"}"))
  ignore(page.mount())
  assert_true(page.snapshot().contains("页内标记：Query Probe"))
  assert_true(page.snapshot().contains("application-request-probe"))
  assert_false(page.snapshot().contains("platform-http"))
  assert_false(page.snapshot().contains("shared/inc"))
  let request = page.dispatch("request_lifecycle/request", "{}")
  assert_true(request.contains("https://httpbingo.org/delay/2"))
  assert_true(request.contains("\"request_id\":\"request_lifecycle:0\""))
  ignore(page.lifecycle("onShow", "{}"))
  assert_true(page.snapshot().contains("visible: true"))
  ignore(page.lifecycle("onHide", "{}"))
  assert_true(page.snapshot().contains("visible: false"))
  ignore(
    page.resolve_effect(
      "request_lifecycle:0", "success", "{\"statusCode\":200,\"data\":{}}",
    ),
  )
  ignore(page.lifecycle("onShow", "{}"))
  assert_true(page.snapshot().contains("request: loaded · HTTP 200"))
  assert_true(page.snapshot().contains("页内标记：Query Probe"))
}

///|
test "request lifecycle exposes push replace and stack-aware back with no catalogue" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = app.create_page(program(app.deps())).unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  for
    entry in [
      ("open-editor", "NavigateTo", "request_lifecycle"),
      ("replace-editor", "RedirectTo", "redirect"),
    ] {
    let command = page.dispatch("request_lifecycle/" + entry.0, "{}")
    assert_true(command.contains(entry.1))
    assert_true(
      command.contains("/pages/draft_editor/draft_editor?from=" + entry.2),
    )
  }
  let back = page.dispatch("request_lifecycle/back", "{}")
  assert_true(back.contains("NavigateBackOrRedirect"))
  assert_true(back.contains("/pages/showcase/showcase"))
  ignore(page.dispatch("request_lifecycle/request", "{}"))
  assert_true(page.dispose().contains("CancelEffect"))
  assert_eq(
    page.resolve_effect(
      "request_lifecycle:0", "success", "{\"statusCode\":200,\"data\":{}}",
    ),
    "[]",
  )
}
