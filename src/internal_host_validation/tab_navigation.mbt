///|
pub fn tab_navigation_host_source() -> String {
  "const hostSource = " +
  @host_js.shared_host_bridge(tab_routes=["/pages/home/home", "/pages/lab/lab"]).escape() +
  "\nconst protocolSource = " +
  @host_js.shared_protocol_bridge().escape() +
  "\n" +
  (
    #|const assert = require("node:assert/strict"), vm = require("node:vm")
    #|const protocol = { exports: {} }
    #|vm.runInNewContext(protocolSource, { module: protocol, console })
    #|const calls = [], errors = []
    #|let definition, depth = 1
    #|const environment = {
    #|  module: { exports: {} }, require: () => protocol.exports,
    #|  console: { error: (...args) => errors.push(args.join(" ")) },
    #|  Page: value => { definition = value }, getCurrentPages: () => Array(depth).fill({}),
    #|  wx: Object.fromEntries(["navigateTo", "redirectTo", "switchTab", "navigateBack"].map(name => [name, options => calls.push([name, options])])),
    #|}
    #|vm.runInNewContext(hostSource, environment)
    #|const abi = Number(hostSource.match(/!== (\d+)/)[1])
    #|const runtime = { minimoon_runtime_version: () => abi, minimoon_runtime_state_abi_version: () => abi }
    #|function page(capabilities) {
    #|  environment.module.exports.registerMinimoonPage(runtime, "test", {}, capabilities)
    #|  return definition
    #|}
    #|const host = page(["wx.navigateTo", "wx.redirectTo", "wx.switchTab", "wx.navigateBack"])
    #|function accept(command, method, options) {
    #|  const previous = errors.length, length = calls.length
    #|  host._ac(command)
    #|  assert.equal(errors.length, previous)
    #|  assert.equal(calls.length, length + 1)
    #|  assert.deepEqual(JSON.parse(JSON.stringify(calls.at(-1))), [method, options])
    #|}
    #|accept({ type: "SwitchTab", url: "/pages/home/home" }, "switchTab", { url: "/pages/home/home" })
    #|accept({ type: "NavigateTo", url: "/pages/details/details?from=Home" }, "navigateTo", { url: "/pages/details/details?from=Home" })
    #|accept({ type: "RedirectTo", url: "/pages/details/details" }, "redirectTo", { url: "/pages/details/details" })
    #|accept({ type: "NavigateBackOrRedirect", delta: 1, fallback: "/pages/home/home" }, "switchTab", { url: "/pages/home/home" })
    #|accept({ type: "NavigateBackOrRedirect", delta: 1, fallback: "/pages/details/details?from=direct" }, "redirectTo", { url: "/pages/details/details?from=direct" })
    #|depth = 2
    #|accept({ type: "NavigateBackOrRedirect", delta: 1, fallback: "/pages/home/home" }, "navigateBack", { delta: 1 })
    #|depth = 1
    #|for (const command of [
    #|  { type: "SwitchTab", url: "/pages/details/details" },
    #|  { type: "SwitchTab", url: "/pages/home/home?from=tab" },
    #|  { type: "SwitchTab", url: "/pages/home/home", extra: true },
    #|  { type: "SwitchTab", url: null },
    #|  { type: "NavigateTo", url: "/pages/home/home" },
    #|  { type: "RedirectTo", url: "/pages/home/home?from=tab" },
    #|  { type: "NavigateTo", url: "https://example.invalid" },
    #|  { type: "NavigateTo", url: "/pages/../home" },
    #|  { type: "NavigateBackOrRedirect", delta: 1, fallback: "/pages/home/home?from=tab" },
    #|]) {
    #|  const length = calls.length, previous = errors.length
    #|  host._ac(command)
    #|  assert.equal(calls.length, length)
    #|  assert.equal(errors.length, previous + 1)
    #|}
    #|const missing = page(["wx.navigateBack", "wx.redirectTo"]), length = calls.length
    #|missing._ac({ type: "SwitchTab", url: "/pages/home/home" })
    #|missing._ac({ type: "NavigateBackOrRedirect", delta: 1, fallback: "/pages/home/home" })
    #|assert.equal(calls.length, length)
    #|assert.ok(errors.at(-1).includes("undeclared capability"))
    #|const onlySwitch = page(["wx.switchTab"])
    #|onlySwitch._ac({ type: "NavigateBackOrRedirect", delta: 1, fallback: "/pages/home/home" })
    #|assert.equal(calls.length, length + 1)
    #|console.log("Native Tab navigation host regression passed")
  )
}
