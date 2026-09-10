///|
test "workbench summarizes drafts and routes to editor or saved list without technical controls" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = app.create_page(program(app.deps())).unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  assert_true(page.snapshot().contains("workbench-overview"))
  assert_true(page.snapshot().contains("留住一个想法"))
  assert_false(page.snapshot().contains("shared/inc"))
  assert_false(page.snapshot().contains("platform-http"))
  let resume_command = page.dispatch("workbench/resume", "{}")
  assert_true(resume_command.contains("NavigateTo"))
  assert_true(resume_command.contains("from=workbench&mode=resume"))
  let list = page.dispatch("workbench/drafts", "{}")
  assert_true(list.contains("SwitchTab"))
  assert_true(list.contains("/pages/drafts/drafts"))
  assert_false(list.contains("?"))
}
