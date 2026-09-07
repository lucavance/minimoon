///|
// Mock-host setup shared by validation scripts, never real-host evidence.
pub fn validation_application_boot() -> String {
  (
    #|const bootedApplications = new Set()
    #|function bootApplication(pageFile) {
    #|  const fs = require("node:fs"), path = require("node:path")
    #|  let directory = path.dirname(path.resolve(pageFile))
    #|  while (!fs.existsSync(path.join(directory, "app.js"))) {
    #|    const parent = path.dirname(directory)
    #|    if (parent === directory) throw new Error(`app.js not found for ${pageFile}`)
    #|    directory = parent
    #|  }
    #|  if (bootedApplications.has(directory)) return
    #|  let application
    #|  const previous = globalThis.App
    #|  globalThis.App = value => { application = value }
    #|  try { require(path.join(directory, "app.js")) }
    #|  finally { globalThis.App = previous }
    #|  if (!application) throw new Error("App was not registered")
    #|  if (application.onLaunch) application.onLaunch({})
    #|  if (application.onShow) application.onShow({})
    #|  bootedApplications.add(directory)
    #|}
    #|
  )
}
