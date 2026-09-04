///|
test "starter details decodes query and keeps independent page state" {
  let runtime = program().create_runtime()
  let _ = runtime.lifecycle("onLoad", "{\"from\":\"MoonBit\"}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.dispatch("details/toggle", "{}")
  let snapshot = runtime.snapshot()
  inspect(snapshot.contains("from: MoonBit"), content="true")
  inspect(snapshot.contains("enabled: true"), content="true")
  inspect(snapshot.contains("page visits: 1"), content="true")
  let back = runtime.dispatch("details/back", "{}")
  inspect(back.contains("NavigateBackOrRedirect"), content="true")
  inspect(back.contains("/pages/home/home"), content="true")
}
