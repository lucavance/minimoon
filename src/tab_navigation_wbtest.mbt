///|
test "typed native Tab navigation reaches the runtime and remains page owned" {
  assert_eq(SwitchTab.name(), "wx.switchTab")
  let page = page(
    id="tab_test",
    route=route("pages/test/test"),
    title="Tabs",
    capabilities=[SwitchTab],
    build=_ => {
      Val::constant(
        button(
          event_key="switch",
          on_tap=switch_tab(route("pages/home/home")),
          "Home",
        ),
      )
    },
  )
  let runtime = page.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  assert_eq(
    runtime.dispatch("switch", "{}"),
    "[{\"type\":\"SwitchTab\",\"url\":\"/pages/home/home\"}]",
  )
  ignore(runtime.dispose())
  assert_eq(runtime.dispatch("switch", "{}"), "[]")
}

///|
test "runtime Tab commands survive command mapping and diagnostics" {
  let command : @runtime.Cmd[Int] = @runtime.switch_tab_cmd("/pages/home/home")
  assert_true(
    @runtime.map_cmd(command, value => value.to_string())
    is @runtime.CmdSwitchTab("/pages/home/home"),
  )
  let wire = @runtime.switch_tab_command("/pages/home/home")
  assert_eq(
    @runtime.runtime_commands_json([wire]),
    "[{\"type\":\"SwitchTab\",\"url\":\"/pages/home/home\"}]",
  )
  assert_true(wire.describe().contains("SwitchTab"))
}
