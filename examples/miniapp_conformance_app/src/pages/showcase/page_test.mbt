///|
test "showcase presents bilingual state and lifecycle feedback" {
  let runtime = program().create_runtime()
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
  inspect(runtime.snapshot().contains("page visits: 1"), content="true")
  let increment = runtime.dispatch("showcase/increment", "{}")
  inspect(increment.contains("PatchViewTree"), content="true")
  inspect(runtime.snapshot().contains("state updates: 1"), content="true")
  let _ = runtime.dispatch("showcase/reset", "{}")
  inspect(runtime.snapshot().contains("state updates: 0"), content="true")
}

///|
test "showcase routes to all technical validation pages" {
  let runtime = program().create_runtime()
  let _ = runtime.mount()
  let console = runtime.dispatch("showcase/open-console", "{}")
  inspect(console.contains("/pages/home/home?name=Studio"), content="true")
  let lab = runtime.dispatch("showcase/open-lab", "{}")
  inspect(lab.contains("/pages/lab/lab?instance=showcase"), content="true")
  let details = runtime.dispatch("showcase/open-details", "{}")
  inspect(
    details.contains("/pages/details/details?from=showcase"),
    content="true",
  )
}
