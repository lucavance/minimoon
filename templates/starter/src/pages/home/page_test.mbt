///|
test "starter home owns state, lifecycle, controlled input, and navigation" {
  let runtime = program().create_runtime()
  let _ = runtime.mount()
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.dispatch("home/increment", "{}")
  let _ = runtime.dispatch("home/name", "{\"detail\":{\"value\":\"MoonBit\"}}")
  let snapshot = runtime.snapshot()
  inspect(snapshot.contains("Hello MoonBit"), content="true")
  inspect(snapshot.contains("page visits: 1"), content="true")
  inspect(snapshot.contains("\"text\":\"1\""), content="true")
  let navigation = runtime.dispatch("home/open-details", "{}")
  inspect(navigation.contains("/pages/details/details"), content="true")
  inspect(navigation.contains("from=MoonBit"), content="true")
}
