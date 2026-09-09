///|
test "capability_probe page owns query, count, and request-ID effects" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app
    .create_page(program(runtime_app.deps()), input={ "name": "Query Probe" })
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{\"name\":\"Query Probe\"}")
  let _ = runtime.mount()
  inspect(runtime.snapshot().contains("hello: Query Probe"), content="true")
  let increment = runtime.dispatch("capability_probe/inc", "{}")
  inspect(increment.contains("PatchViewTree"), content="true")
  inspect(increment.contains("\"value\":\"1\""), content="true")
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
  inspect(
    runtime
    .dispatch("capability_probe/login", "{}")
    .contains("InvokeCapability"),
    content="true",
  )
  let request = runtime.dispatch("capability_probe/request", "{}")
  inspect(
    request.contains("https://httpbingo.org/get?existing=yes"),
    content="true",
  )
  inspect(!request.contains("/api/profile"), content="true")
  let tree = @application.program()
    .preview(deps => program(deps).initial_tree())
    .stringify()
  inspect(tree.contains("能力验证"), content="true")
  inspect(
    tree.contains("\"section\":\"capability_probe-intro\""),
    content="true",
  )
  inspect(
    tree.contains("\"section\":\"capability_probe-controls\""),
    content="true",
  )
  inspect(tree.contains("\"section\":\"session-controls\""), content="true")
  inspect(tree.contains("\"section\":\"capability-controls\""), content="true")
  inspect(tree.contains("\"section\":\"navigation-controls\""), content="true")
  inspect(tree.contains("\"section\":\"request-output\""), content="true")
  inspect(tree.contains("overflow-wrap: anywhere"), content="true")
}

///|
test "capability_probe transitions preserve request and lifecycle state" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let _ = runtime.dispatch("capability_probe/inc", "{}")
  let _ = runtime.dispatch("capability_probe/inc", "{}")
  let _ = runtime.dispatch("capability_probe/dec", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
  let _ = runtime.dispatch("capability_probe/reset", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"0\""), content="true")
  let _ = runtime.lifecycle("onShow", "{}")
  inspect(
    runtime.snapshot().contains("\"text\":\"visible: true\""),
    content="true",
  )
  let _ = runtime.lifecycle("onHide", "{}")
  inspect(
    runtime.snapshot().contains("\"text\":\"visible: false\""),
    content="true",
  )
  let request = runtime.dispatch("capability_probe/request", "{}")
  inspect(
    request.contains("\"request_id\":\"capability_probe:0\""),
    content="true",
  )
  let _ = runtime.resolve_effect(
    "capability_probe:0", "success", "{\"statusCode\":200,\"data\":{\"method\":\"GET\"},\"header\":{},\"cookies\":[]}",
  )
  inspect(
    runtime.snapshot().contains("request: loaded · HTTP 200"),
    content="true",
  )
  assert_true(runtime.snapshot().contains("GET"))
  inspect(
    runtime
    .dispatch("capability_probe/open-lab", "{}")
    .contains("/pages/lab/lab"),
    content="true",
  )
  let back = runtime.dispatch("capability_probe/back-studio", "{}")
  inspect(back.contains("\"type\":\"NavigateBackOrRedirect\""), content="true")
  inspect(back.contains("/pages/showcase/showcase"), content="true")
}
