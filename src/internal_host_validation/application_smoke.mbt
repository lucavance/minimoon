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
    #|const stored = new Map(), storageWrites = []
    #|globalThis.wx = { getStorage(options) { if (stored.has(options.key)) options.success({ data: structuredClone(stored.get(options.key)) }); else options.fail({ errMsg: "getStorage:fail data not found" }) }, setStorage(options) { storageWrites.push(options) }, request(options) { requests.push(options); return { abort() { aborts++; options.fail({ errMsg: "request:fail abort" }) } } } }
    #|const controller = registerMinimoonApp(runtime)
    #|assert.equal(requests.length, 0)
    #|application.onLaunch({}); application.onLaunch({}); application.onShow({})
    #|await flush()
    #|const load = file => { require(path.join(dist, file)); return definition }
    #|const appPage = load("pages/drafts/drafts.js"), lifecycle = load("pages/request_lifecycle/request_lifecycle.js"), details = load("pages/draft_editor/draft_editor.js")
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
    #|const first = start(lifecycle), second = start(lifecycle)
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
    #|const origin = start(lifecycle)
    #|tap(origin, "shared/load"); await flush(); assert.equal(requests.length, 1)
    #|assert.equal(requests[0].url, "https://echo.apifox.com/delay/2")
    #|origin.onUnload(); assert.equal(aborts, 0)
    #|application.onHide(); await flush(); assert.equal(aborts, 0)
    #|requests[0].success({ statusCode: 200, data: { public: true } }); await flush()
    #|assert.ok(has(second, "Application request: loaded HTTP 200"))
    #|requests[0].fail({ errMsg: "duplicate" }); await flush(); assert.ok(has(second, "loaded HTTP 200"))
    #|application.onShow({}); await flush()
    #|tap(first, "shared/load"); await flush(); tap(first, "shared/clear"); await flush()
    #|requests[1].success({ statusCode: 201 }); await flush(); assert.ok(has(second, "Application request: idle"))
    #|tap(first, "shared/load"); await flush(); assert.equal(requests.length, 3)
    #|const editor = start(details, { from: "application-smoke" })
    #|const online = load("pages/online/online.js"), viewer = start(online)
    #|const input = (key, value) => editor.__mmDispatchInput({ currentTarget: { dataset: { minimoonInput: key } }, target: { dataset: {} }, detail: { value } })
    #|// Verify the generated host's actual writes, not only the final model: replaying
    #|// an unchanged focus:false or selection property can interrupt native typing.
    #|const controlPath = (node, event, path = "draft_editor.tree") => {
    #|  if (node.events.input === event) return path
    #|  for (let index = 0; index < node.children.length; index++) { const found = controlPath(node.children[index], event, path + ".children[" + index + "]"); if (found) return found }
    #|}
    #|const typingWrites = [], setEditorData = editor.setData
    #|editor.setData = function(patch, callback) { typingWrites.push(structuredClone(patch)); return setEditorData.call(this, patch, callback) }
    #|for (const event of ["draft_editor/draft-title", "draft_editor/draft-note"]) {
    #|  const prefix = controlPath(editor.data.draft_editor.tree, event)
    #|  assert.ok(prefix, "draft input is missing")
    #|  const tokens = prefix.replace(/\[(\d+)\]/g, ".$1").split("."), identity = get(editor.data, tokens).identity
    #|  for (const value of ["a", "ab", "abc", "a中bc", "a中", ""]) {
    #|    typingWrites.length = 0; input(event, value); await flush()
    #|    assert.equal(get(editor.data, tokens).identity, identity, "typing replaced its native input identity")
    #|    assert.equal(get(editor.data, tokens).props.value, value)
    #|    const fields = typingWrites.flatMap(patch => Object.keys(patch))
    #|    assert.ok(fields.includes(prefix + ".props.value"), "typing must reach the native value field")
    #|    assert.deepEqual(fields.filter(key => key.startsWith(prefix + ".")), [prefix + ".props.value"], "typing replayed focus/selection or the whole props object")
    #|    assert.ok(!fields.some(key => prefix === key || prefix.startsWith(key + ".") || prefix.startsWith(key + "[")), "typing replaced an input ancestor")
    #|  }
    #|}
    #|editor.setData = setEditorData
    #|input("draft_editor/draft-title", ""); await flush(); tap(editor, "work/send"); await flush()
    #|assert.equal(requests.length, 3); assert.ok(has(editor, "标题不能为空"))
    #|input("draft_editor/draft-title", "Typed host echo"); input("draft_editor/draft-note", "shared result"); await flush()
    #|tap(editor, "draft_editor/save-draft"); await flush()
    #|assert.equal(storageWrites.length, 1); assert.ok(!has(first, "本地写入成功"))
    #|storageWrites[0].fail({ errMsg: "quota" }); await flush(); assert.ok(has(editor, "本地写入失败"))
    #|tap(editor, "draft_editor/save-draft"); await flush()
    #|const write = storageWrites[1]; stored.set(write.key, structuredClone(write.data)); write.success({}); await flush()
    #|const list = start(appPage); assert.ok(has(list, "Typed host echo")); assert.ok(has(editor, "当前内容已保存到本地"))
    #|tap(editor, "work/send"); await flush()
    #|assert.equal(requests.length, 4); assert.equal(requests[3].url, "https://echo.apifox.com/post"); assert.equal(requests[3].method, "POST")
    #|assert.deepEqual(JSON.parse(requests[3].data), { title: "Typed host echo", note: "shared result" })
    #|editor.onUnload(); assert.equal(aborts, 0)
    #|requests[3].success({ statusCode: 200, data: { json: { title: "Typed host echo", note: "shared result" }, origin: "not displayed" } }); await flush()
    #|assert.ok(has(viewer, "回显成功")); assert.ok(has(viewer, "typed-echo")); assert.ok(!has(viewer, "not displayed"))
    #|list.onUnload()
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
