///|
// Runs generated CommonJS bytes against an instrumented wx adapter, not DevTools.
pub fn application_host_smoke_source() -> String {
  (
    #|;(async () => {
    #|const assert = require("node:assert/strict"), path = require("node:path")
    #|const dist = path.resolve(process.argv[2])
    #|const runtime = require(path.join(dist, "minimoon.runtime.js"))
    #|let sharedFlushes = 0
    #|const pageLifecycle = runtime.minimoon_runtime_lifecycle
    #|runtime.minimoon_runtime_lifecycle = (id, hook, payload) => { if (hook === "$minimoon:shared") sharedFlushes++; return pageLifecycle(id, hook, payload) }
    #|const { registerMinimoonApp } = require(path.join(dist, "minimoon.app.js"))
    #|const flush = async () => { for (let index = 0; index < 24; index++) await Promise.resolve() }
    #|let application, definition, aborts = 0
    #|const requests = [], errors = []
    #|const originalError = console.error
    #|console.error = (...args) => errors.push(args.join(" "))
    #|globalThis.App = value => { application = value }
    #|globalThis.Page = value => { definition = value }
    #|globalThis.Component = () => { throw new Error("unexpected Component") }
    #|globalThis.wx = { request(options) { requests.push(options); return { abort() { aborts++; options.fail({ errMsg: "request:fail abort" }) } } } }
    #|const controller = registerMinimoonApp(runtime)
    #|assert.equal(requests.length, 0)
    #|application.onLaunch({}); application.onLaunch({}); application.onShow({})
    #|await flush()
    #|const load = file => { require(path.join(dist, file)); return definition }
    #|const probe = load("pages/capability_probe/capability_probe.js"), details = load("pages/details/details.js")
    #|const get = (value, tokens) => tokens.reduce((current, token) => current[token], value)
    #|const assign = (value, tokens, next) => { get(value, tokens.slice(0, -1))[tokens.at(-1)] = next }
    #|const start = (definition, input = {}) => {
    #|  const host = { ...definition, data: structuredClone(definition.data), writes: 0,
    #|    setData(patch, callback) { this.writes++; for (const [key, value] of Object.entries(patch)) assign(this.data, key.replace(/\[(\d+)\]/g, ".$1").split("."), value); if (callback) callback() },
    #|  }
    #|  host.onLoad(input); host.onShow(); host.onReady(); return host
    #|}
    #|const tap = (host, key) => host.__mmDispatchTap({ currentTarget: { dataset: { minimoonTap: key } }, target: { dataset: {} }, detail: {} })
    #|const has = (host, text) => JSON.stringify(host.data).includes(text)
    #|const first = start(probe), second = start(details, { from: "application-smoke" })
    #|const firstId = first.__mmInstanceId, firstWrites = first.writes
    #|first.onLoad({}); assert.equal(first.__mmInstanceId, firstId); assert.equal(first.writes, firstWrites)
    #|assert.match(errors.pop(), /duplicate_page_load/)
    #|tap(first, "shared/inc"); await flush()
    #|assert.ok(has(first, "Application shared count: 1")); assert.ok(has(second, "Application shared count: 1"))
    #|second.onHide(); const hiddenWrites = second.writes
    #|tap(first, "shared/inc"); await flush()
    #|assert.equal(second.writes, hiddenWrites); assert.ok(has(second, "Application shared count: 1"))
    #|second.onShow(); await flush(); assert.ok(has(second, "Application shared count: 2"))
    #|const beforeBurst = sharedFlushes
    #|for (let index = 0; index < 10; index++) tap(first, "shared/inc")
    #|await flush(); assert.ok(has(first, "Application shared count: 12")); assert.ok(has(second, "Application shared count: 12"))
    #|assert.equal(sharedFlushes - beforeBurst, 2, "shared updates must coalesce once per page")
    #|for (let index = 0; index < 3000; index++) tap(first, "shared/inc")
    #|await flush()
    #|assert.ok(has(first, "Application shared count: 3012"), "application inbox must continue beyond one drain budget without another interaction")
    #|assert.ok(has(second, "Application shared count: 3012"), "every page must converge after a multi-batch application burst")
    #|tap(first, "shared/load"); await flush(); assert.equal(requests.length, 1)
    #|assert.equal(requests[0].url, "https://httpbingo.org/delay/2")
    #|first.onUnload(); assert.equal(aborts, 0)
    #|application.onHide(); await flush(); assert.equal(aborts, 0)
    #|requests[0].success({ statusCode: 200, data: { public: true } }); await flush()
    #|assert.ok(has(second, "Application request: loaded HTTP 200"))
    #|requests[0].fail({ errMsg: "duplicate" }); await flush(); assert.ok(has(second, "loaded HTTP 200"))
    #|application.onShow({}); await flush()
    #|tap(second, "shared/load"); await flush(); tap(second, "shared/clear"); await flush()
    #|requests[1].success({ statusCode: 201 }); await flush(); assert.ok(has(second, "Application request: idle"))
    #|tap(second, "shared/load"); await flush(); assert.equal(requests.length, 3)
    #|const viewer = start(probe)
    #|const input = (key, value) => second.__mmDispatchInput({ currentTarget: { dataset: { minimoonInput: key } }, target: { dataset: {} }, detail: { value } })
    #|input("details/draft-title", ""); tap(second, "details/save-draft"); await flush()
    #|assert.equal(requests.length, 3); assert.ok(has(second, "Title is required."))
    #|input("details/draft-title", "Typed host echo"); input("details/draft-note", "shared result")
    #|tap(second, "details/save-draft"); await flush()
    #|assert.equal(requests.length, 4); assert.equal(requests[3].url, "https://httpbingo.org/post"); assert.equal(requests[3].method, "POST")
    #|assert.deepEqual(JSON.parse(requests[3].data), { title: "Typed host echo", note: "shared result" })
    #|requests[3].success({ statusCode: 200, data: { json: { title: "Typed host echo", note: "shared result" }, origin: "not displayed" } }); await flush()
    #|assert.ok(has(second, "Draft save: echoed (not persistent)")); assert.ok(has(viewer, "Application echoed draft: Typed host echo / shared result (not persistent)")); assert.ok(!has(viewer, "not displayed"))
    #|viewer.onUnload()
    #|controller.dispose(); controller.dispose(); assert.equal(aborts, 1); assert.equal(second.__mmInstanceId, null)
    #|const writes = second.writes
    #|requests[2].success({ statusCode: 202 }); await flush(); assert.equal(second.writes, writes)
    #|assert.equal(globalThis.__minimoonAppWakeV12, undefined); assert.equal(globalThis.__minimoonSharedWakeV12, undefined)
    #|assert.deepEqual(errors, [])
    #|
    #|// Exercise the application-only timer scheduler and an independent local-async wake.
    #|let wake, timerTick, timerStops = 0, localReady = false, ticks = 0, launches = 0
    #|const oldSet = globalThis.setInterval, oldClear = globalThis.clearInterval
    #|globalThis.setInterval = callback => { timerTick = callback; return 71 }
    #|globalThis.clearInterval = handle => { assert.equal(handle, 71); timerStops++ }
    #|const command = value => JSON.stringify([value])
    #|const fake = {
    #|  minimoon_runtime_version: runtime.minimoon_runtime_version,
    #|  minimoon_runtime_state_abi_version: runtime.minimoon_runtime_state_abi_version,
    #|  minimoon_application_capabilities: () => "[]",
    #|  minimoon_application_start() { launches++; wake = globalThis.__minimoonAppWakeV12; return "[]" },
    #|  minimoon_application_lifecycle(hook) { return command(hook === "onShow" ? { type: "StartSubscription", component_id: "$app", key: "tick", interval_ms: 1000 } : { type: "StopSubscription", component_id: "$app", key: "tick" }) },
    #|  minimoon_application_subscription() { ticks++; return "[]" },
    #|  minimoon_application_flush() { if (localReady) { ticks += 10; localReady = false }; return "[]" },
    #|  minimoon_application_dispose: () => "[]",
    #|}
    #|const timerApp = registerMinimoonApp(fake)
    #|application.onLaunch({}); application.onLaunch({}); assert.equal(launches, 1)
    #|application.onShow({}); await flush(); timerTick(); await flush(); assert.equal(ticks, 1)
    #|application.onHide(); await flush(); timerTick(); await flush(); assert.equal(ticks, 1); assert.equal(timerStops, 1)
    #|localReady = true; wake(); await flush(); assert.equal(ticks, 11)
    #|application.onShow({}); await flush(); timerApp.dispose(); timerTick(); wake(); await flush(); assert.equal(ticks, 11); assert.equal(timerStops, 2)
    #|globalThis.setInterval = oldSet; globalThis.clearInterval = oldClear; console.error = originalError
    #|assert.deepEqual(errors, [])
    #|process.stdout.write("application shared-state host smoke passed (mock host)\n")
    #|})().catch(error => { process.stderr.write(`${error.stack || error}\n`); process.exitCode = 1 })
    #|
  )
}
