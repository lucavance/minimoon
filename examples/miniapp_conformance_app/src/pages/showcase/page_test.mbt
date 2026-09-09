///|
test "showcase presents bilingual state and lifecycle feedback" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let initial = runtime.snapshot()
  inspect(initial.contains("\"section\":\"showcase-hero\""), content="true")
  inspect(initial.contains("Minimoon Studio"), content="true")
  inspect(
    initial.contains("用 MoonBit 构建原生 Skyline 小程序"),
    content="true",
  )
  inspect(initial.contains("state updates: 0"), content="true")
  let _ = runtime.mount()
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.dispatch("showcase/notes", "{}")
  inspect(runtime.snapshot().contains("page visits: 1"), content="true")
  let increment = runtime.dispatch("showcase/increment", "{}")
  inspect(increment.contains("PatchViewTree"), content="true")
  inspect(runtime.snapshot().contains("state updates: 1"), content="true")
  let _ = runtime.dispatch("showcase/reset", "{}")
  inspect(runtime.snapshot().contains("state updates: 0"), content="true")
}

///|
test "showcase has only three query-free Tab shortcuts" {
  let app = @application.program().create_runtime()
  defer ignore(app.dispose())
  let page = app.create_page(program(app.deps())).unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  for name in ["interaction", "platform", "application"] {
    let command = page.dispatch("showcase/tab-" + name, "{}")
    assert_true(command.contains("SwitchTab"))
    assert_true(command.contains("/pages/" + name + "/" + name))
    assert_false(command.contains("?"))
  }
  assert_false(page.snapshot().contains("showcase-routes"))
  assert_false(page.snapshot().contains("request_lifecycle"))
  assert_false(page.snapshot().contains("runtime_lab"))
  assert_false(page.snapshot().contains("draft_editor"))
}
