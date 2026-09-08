///|
test "application echoes are typed app state and independent of shared count" {
  let app = program().create_runtime()
  defer ignore(app.dispose())
  ignore(app.lifecycle("onLaunch", "{}"))
  let page = app
    .create_page(
      @minimoon.page(
        id="app_panel",
        route=@minimoon.route("pages/app/panel"),
        title="App panel",
        build=context => panel(context, app.deps()),
      ),
    )
    .unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  assert_true(
    page.snapshot().contains("Application echoed draft: none (not persistent)"),
  )
  let draft : Draft = { title: "Typed", note: "Echo", }
  ignore(app.dispatch((app.deps().save_echo)(draft)))
  ignore(app.dispatch((app.deps().change_count)(2)))
  ignore(page.flush())
  assert_true(
    page
    .snapshot()
    .contains("Application echoed draft: Typed / Echo (not persistent)"),
  )
  assert_true(page.snapshot().contains("Application shared count: 2"))
  assert_true(page.snapshot().contains("Application request: idle"))
}
