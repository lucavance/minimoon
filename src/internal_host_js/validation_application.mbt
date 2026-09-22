///|
// Mock-host setup shared by validation scripts, never real-host evidence.
pub fn validation_application_boot() -> String {
  (
    #|const bootedApplications = new Map()
    #|function disposeApplications() {
    #|  let failure
    #|  for (const { controller } of bootedApplications.values()) {
    #|    try { if (controller) controller.dispose() } catch (error) { failure ||= error }
    #|  }
    #|  bootedApplications.clear()
    #|  if (failure) throw failure
    #|}
    #|const flushApplicationTasks = () => new Promise(resolve => setTimeout(resolve, 0))
    #|function bootApplication(pageFile) {
    #|  const fs = require("node:fs"), path = require("node:path")
    #|  let directory = path.dirname(path.resolve(pageFile))
    #|  while (!fs.existsSync(path.join(directory, "app.js"))) {
    #|    const parent = path.dirname(directory)
    #|    if (parent === directory) throw new Error(`app.js not found for ${pageFile}`)
    #|    directory = parent
    #|  }
    #|  if (bootedApplications.has(directory)) return
    #|  let application, controller
    #|  const bridgeFile = path.join(directory, "minimoon.app.js")
    #|  const bridge = fs.existsSync(bridgeFile) ? require(bridgeFile) : null
    #|  const register = bridge && bridge.registerMinimoonApp
    #|  if (bridge) bridge.registerMinimoonApp = (...args) => {
    #|    controller = register(...args)
    #|    bootedApplications.set(directory, { application, controller })
    #|    return controller
    #|  }
    #|  const previous = globalThis.App
    #|  globalThis.App = value => { application = value }
    #|  try { require(path.join(directory, "app.js")) }
    #|  finally { globalThis.App = previous; if (bridge) bridge.registerMinimoonApp = register }
    #|  if (!application) throw new Error("App was not registered")
    #|  bootedApplications.set(directory, { application, controller })
    #|  if (application.onLaunch) application.onLaunch({})
    #|  if (application.onShow) application.onShow({})
    #|}
    #|
  )
}
