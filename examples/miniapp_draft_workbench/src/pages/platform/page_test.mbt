///|
test "platform reports failures beside each capability without overwriting HTTP errors" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = app.create_page(program(app.deps())).unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  let request = page.dispatch("platform/request", "{}")
  assert_true(request.contains("https://echo.apifox.com/get?existing=yes"))
  ignore(
    page.resolve_effect(
      "platform:0", "failure", "{\"error\":\"HTTP probe failed\"}",
    ),
  )
  ignore(page.dispatch("platform/login", "{}"))
  ignore(
    page.resolve_effect("platform:1", "failure", "{\"error\":\"Login denied\"}"),
  )
  assert_true(page.snapshot().contains("HTTP probe failed"))
  assert_true(page.snapshot().contains("login: failed: Login denied"))
  ignore(page.dispatch("platform/clear-login", "{}"))
  assert_false(page.snapshot().contains("Login denied"))
  assert_true(page.snapshot().contains("HTTP probe failed"))
  ignore(page.dispatch("platform/request", "{}"))
  assert_false(page.snapshot().contains("HTTP probe failed"))
  assert_true(page.snapshot().contains("request: loading"))
}

///|
test "platform storage has its own editable value and no shared state controls" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = app.create_page(program(app.deps())).unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  ignore(
    page.dispatch(
      "platform/storage-input", "{\"detail\":{\"value\":\"Stored text\"}}",
    ),
  )
  let save = page.dispatch("platform/save-storage", "{}")
  assert_true(save.contains("minimoon-conformance-platform"))
  assert_true(save.contains("\"data\":\"Stored text\""))
  assert_false(page.snapshot().contains("shared/inc"))
  assert_false(page.snapshot().contains("shared/load"))
  assert_false(page.snapshot().contains("http-response-detail"))
  ignore(page.dispatch("platform/toggle-response", "{}"))
  assert_true(page.snapshot().contains("http-response-detail"))
  assert_true(page.snapshot().contains("Stored text"))
}
