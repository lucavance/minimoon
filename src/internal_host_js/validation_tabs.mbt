///|
/// Exercise the generated file, not a fresh host template, against the manifest.
/// Only the VM's navigation stubs run; no page builder or real wx API is invoked.
pub fn native_tab_host_source(
  routes : Array[String],
  tab_routes : Array[String],
) -> String {
  "const routes = " +
  Json::array(routes.map(Json::string)).stringify() +
  "\nconst tabRoutes = " +
  Json::array(tab_routes.map(Json::string)).stringify() +
  "\nconst abi = " +
  @versions.runtime_api_version().to_string() +
  "\n" +
  (
    #|const fs = require("node:fs"), path = require("node:path"), vm = require("node:vm")
    #|const hostFile = path.resolve("dist/minimoon.host.js"), protocolFile = path.resolve("dist/minimoon.protocol.js")
    #|const protocol = { exports: {} }, calls = [], errors = []
    #|vm.runInNewContext(fs.readFileSync(protocolFile, "utf8"), { module: protocol }, { filename: protocolFile, timeout: 1000 })
    #|let definition, depth = 1
    #|const environment = {
    #|  module: { exports: {} },
    #|  require(name) { if (name !== "./minimoon.protocol.js") throw new Error(`unexpected native Tab probe dependency: ${name}`); return protocol.exports },
    #|  console: { error: (...args) => errors.push(args.join(" ")) },
    #|  Page(value) { definition = value }, getCurrentPages: () => Array(depth).fill({}),
    #|  wx: Object.fromEntries(["navigateTo", "redirectTo", "switchTab", "navigateBack"].map(name => [name, options => calls.push([name, options])])),
    #|}
    #|vm.runInNewContext(fs.readFileSync(hostFile, "utf8"), environment, { filename: hostFile, timeout: 1000 })
    #|const runtime = { minimoon_runtime_version: () => abi, minimoon_runtime_state_abi_version: () => abi }
    #|environment.module.exports.registerMinimoonPage(runtime, "tab_probe", {}, ["wx.navigateTo", "wx.redirectTo", "wx.switchTab", "wx.navigateBack"])
    #|if (!definition || typeof definition._ac !== "function") throw new Error("native Tab host probe could not register its page")
    #|function probe(command, method, options) {
    #|  calls.length = 0; errors.length = 0
    #|  definition._ac(command)
    #|  const label = `${command.type} ${command.url || command.fallback || ""}`
    #|  if (method === null) {
    #|    if (calls.length !== 0 || errors.length !== 1 || !errors[0].includes("navigation route kind mismatch")) throw new Error(`native Tab host/manifest mismatch: ${label} was not rejected`)
    #|  } else if (errors.length !== 0 || calls.length !== 1 || calls[0][0] !== method || JSON.stringify(calls[0][1]) !== JSON.stringify(options)) {
    #|    throw new Error(`native Tab host/manifest mismatch: ${label} expected ${method}; ${errors.join("; ")}`)
    #|  }
    #|}
    #|const tabs = new Set(tabRoutes)
    #|if (new Set(routes).size !== routes.length || tabs.size !== tabRoutes.length || tabRoutes.some(route => !routes.includes(route))) throw new Error("invalid manifest native Tab route set")
    #|for (const route of routes) {
    #|  const tab = tabs.has(route), options = { url: route }
    #|  probe({ type: "SwitchTab", url: route }, tab ? "switchTab" : null, options)
    #|  probe({ type: "NavigateTo", url: route }, tab ? null : "navigateTo", options)
    #|  probe({ type: "RedirectTo", url: route }, tab ? null : "redirectTo", options)
    #|  depth = 1
    #|  probe({ type: "NavigateBackOrRedirect", delta: 1, fallback: route }, tab ? "switchTab" : "redirectTo", options)
    #|  depth = 2
    #|  probe({ type: "NavigateBackOrRedirect", delta: 1, fallback: route }, "navigateBack", { delta: 1 })
    #|  if (tab) probe({ type: "SwitchTab", url: `${route}?from=probe` }, null, {})
    #|}
    #|console.log("generated native Tab host routes match every manifest page")
  )
}
