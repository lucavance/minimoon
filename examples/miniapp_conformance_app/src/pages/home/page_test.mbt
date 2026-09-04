///|
test "home page owns query, count, and request-ID effects" {
  let runtime = program().create_runtime()
  let _ = runtime.lifecycle("onLoad", "{\"name\":\"Query Home\"}")
  let _ = runtime.mount()
  inspect(runtime.snapshot().contains("hello: Query Home"), content="true")
  let increment = runtime.dispatch("home/inc", "{}")
  inspect(increment.contains("PatchViewTree"), content="true")
  inspect(increment.contains("\"value\":\"1\""), content="true")
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
  inspect(
    runtime.dispatch("home/login", "{}").contains("InvokeCapability"),
    content="true",
  )
  let request = runtime.dispatch("home/request", "{}")
  inspect(
    request.contains("https://www.wanandroid.com/banner/json"),
    content="true",
  )
  inspect(!request.contains("/api/profile"), content="true")
  let tree = program().initial_tree().stringify()
  inspect(tree.contains("能力控制台"), content="true")
  inspect(tree.contains("\"section\":\"home-intro\""), content="true")
  inspect(tree.contains("\"section\":\"home-controls\""), content="true")
  inspect(tree.contains("\"section\":\"session-controls\""), content="true")
  inspect(tree.contains("\"section\":\"capability-controls\""), content="true")
  inspect(tree.contains("\"section\":\"navigation-controls\""), content="true")
  inspect(tree.contains("\"section\":\"request-output\""), content="true")
  inspect(tree.contains("overflow-wrap: anywhere"), content="true")
}

///|
test "home transitions preserve request and lifecycle state" {
  let runtime = program().create_runtime()
  let _ = runtime.mount()
  let _ = runtime.dispatch("home/inc", "{}")
  let _ = runtime.dispatch("home/inc", "{}")
  let _ = runtime.dispatch("home/dec", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
  let _ = runtime.dispatch("home/reset", "{}")
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
  let request = runtime.dispatch("home/request", "{}")
  inspect(request.contains("\"request_id\":\"home:0\""), content="true")
  let _ = runtime.resolve_effect(
    "home:0", "success", "{\"statusCode\":200,\"data\":{\"errorCode\":0},\"header\":{},\"cookies\":[]}",
  )
  inspect(
    runtime.snapshot().contains("\"text\":\"request: loaded\""),
    content="true",
  )
  inspect(runtime.snapshot().contains("errorCode"), content="true")
  inspect(
    runtime.dispatch("home/open-lab", "{}").contains("/pages/lab/lab"),
    content="true",
  )
  let back = runtime.dispatch("home/back-studio", "{}")
  inspect(back.contains("\"type\":\"NavigateBackOrRedirect\""), content="true")
  inspect(back.contains("/pages/showcase/showcase"), content="true")
}
