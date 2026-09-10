///|
// Repository-only transport shim: this is not WeChat host evidence.
pub fn http_probe_source() -> String {
  @host_js.validation_application_boot() +
  (
    #|const { writeFileSync } = require("node:fs")
    #|const assert = require("node:assert/strict")
    #|const offline = process.argv[4] === "--offline"
    #|const report = { status: "failed", mode: offline ? "offline" : "public-api", realHost: false, artifactFingerprint: process.argv[6] || null, uiArtifactFingerprint: process.argv[8] || null, runAt: new Date().toISOString(), cases: [] }
    #|const reportFile = process.argv[3]
    #|const save = () => writeFileSync(reportFile, JSON.stringify(report, null, 2) + "\n")
    #|save()
    #|const deadline = setTimeout(() => { report.error = "whole-run deadline exceeded"; save(); process.exit(1) }, 120000)
    #|let definition, host, observed, lastOptions
    #|globalThis.Page = page => { definition = page }
    #|globalThis.Component = () => { throw new Error("unexpected Component registration") }
    #|globalThis.getCurrentPages = () => host ? [host] : []
    #|const requireCheck = (condition, label) => { if (!condition) throw new Error(label) }
    #|const pairs = params => { const value = {}; for (const [key, item] of params) (value[key] ||= []).push(item); return value }
    #|const list = value => typeof value === "string" ? [value] : value
    #|const normalizedPairs = value => Object.fromEntries(Object.entries(value).map(([key, item]) => [key, list(item)]))
    #|const echoPairs = params => Object.fromEntries(Object.entries(pairs(params)).map(([key, items]) => [key, items.length === 1 ? items[0] : items]))
    #|const fakeFetch = async (url, options) => {
    #|  if (process.argv[5] === "--fault-network") throw new Error("synthetic transport failure")
    #|  const parsed = new URL(url)
    #|  if (parsed.pathname === "/delay/3") await new Promise((resolve, reject) => { const timer = setTimeout(resolve, 3000); options.signal.addEventListener("abort", () => { clearTimeout(timer); reject(new Error("aborted")) }, { once: true }) })
    #|  const status = parsed.pathname.startsWith("/status/") ? Number(parsed.pathname.split("/").pop()) : 200
    #|  const legacy = process.argv[5] === "--legacy-echo"
    #|  const headers = Object.fromEntries(Object.entries(options.headers).map(([key, value]) => [key, legacy ? [value] : value]))
    #|  const value = { url, ...(legacy ? { method: options.method } : {}), args: (legacy ? pairs : echoPairs)(parsed.searchParams), headers, data: options.body || "", json: null, form: {} }
    #|  if (process.argv[5] === "--fault-echo") value.args = {}
    #|  if (process.argv[5] === "--fault-header") value.headers = {}
    #|  if (process.argv[5] === "--fault-method") value.method = "wrong"
    #|  if (options.headers["content-type"] === "application/json") value.json = JSON.parse(options.body)
    #|  if (options.headers["content-type"] === "application/x-www-form-urlencoded") { value.form = (legacy ? pairs : echoPairs)(new URLSearchParams(options.body)); value.data = "" }
    #|  if (process.argv[5] === "--fault-json") value.json = null
    #|  if (process.argv[5] === "--fault-form") value.form = {}
    #|  if (process.argv[5] === "--fault-body") value.data = "wrong"
    #|  return new Response(["HEAD", "OPTIONS"].includes(options.method) || status !== 200 ? "" : JSON.stringify(value), { status, headers: { "content-type": "application/json" } })
    #|}
    #|const transport = (options, fetcher = offline ? fakeFetch : fetch) => {
    #|  lastOptions = options
    #|  const controller = new AbortController()
    #|  let timedOut = false, settled = false
    #|  const timer = setTimeout(() => { timedOut = true; controller.abort() }, options.timeout || 60000)
    #|  Promise.resolve().then(() => fetcher(options.url, { method: options.method, headers: options.header, ...(Object.hasOwn(options, "data") ? { body: options.data } : {}), signal: controller.signal, redirect: "error" })).then(async response => {
    #|    const text = await response.text()
    #|    let data = text
    #|    try { data = JSON.parse(text) } catch (_) {}
    #|    observed = { statusCode: response.status, data, header: Object.fromEntries(response.headers), cookies: [] }
    #|    if (!settled) { settled = true; options.success(observed) }
    #|  }).catch(() => {
    #|    if (!settled) { settled = true; observed = { error: timedOut ? "timeout" : "network" }; options.fail({ errMsg: `request:fail ${observed.error}` }) }
    #|  }).finally(() => clearTimeout(timer))
    #|  return { abort() { if (!settled) { settled = true; clearTimeout(timer); controller.abort(); options.fail({ errMsg: "request:fail abort" }) } } }
    #|}
    #|globalThis.wx = { request: options => transport(options) }
    #|const resolvePath = (root, path) => path.reduce((value, key) => value[key], root)
    #|const assign = (root, path, value) => { resolvePath(root, path.slice(0, -1))[path.at(-1)] = value }
    #|const start = (input = {}) => {
    #|  const pending = []
    #|  host = { ...definition, data: structuredClone(definition.data),
    #|    setData(patch, callback) { for (const [key, value] of Object.entries(patch)) assign(this.data, key.replace(/\[(\d+)\]/g, ".$1").split("."), value); if (callback) callback() },
    #|    replaceDataOnPath(path, value) { pending.push([path, value]) },
    #|    spliceArrayDataOnPath(path, index, del, items) { pending.push([path, index, del, items]) },
    #|    groupUpdates(callback) { callback(); for (const op of pending.splice(0)) { if (op.length === 2) assign(this.data, op[0], op[1]); else resolvePath(this.data, op[0]).splice(op[1], op[2], ...op[3]) } },
    #|  }
    #|  host.onLoad(input); host.onShow(); host.onReady()
    #|}
    #|const dispatch = (kind, key, detail = {}) => host[`__mmDispatch${kind}`]({ currentTarget: { dataset: { [`minimoon${kind}`]: key } }, target: { dataset: {} }, detail })
    #|const tree = () => JSON.stringify(host.data)
    #|const waitDone = async () => { const until = Date.now() + 17000; while (tree().includes("request: loading") && Date.now() < until) await new Promise(resolve => setTimeout(resolve, 10)); requireCheck(!tree().includes("request: loading"), "request did not settle") }
    #|const echoedHeader = (data, name) => list(Object.entries(data.headers).find(([key]) => key.toLowerCase() === name)?.[1])
    #|const verify = index => {
    #|  assert.equal(lastOptions.method, ["GET", "POST", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "GET", "GET", "GET"][index])
    #|  assert.equal(lastOptions.timeout, index === 9 ? 500 : 15000)
    #|  assert.equal(lastOptions.header["x-minimoon-test"], "public-smoke")
    #|  if (index === 9) { assert.equal(observed.error, "timeout"); requireCheck(tree().includes("request: failed") && tree().includes("request:fail timeout"), "timeout did not reach page"); return }
    #|  const status = index === 7 ? 400 : index === 8 ? 500 : 200
    #|  assert.equal(observed.statusCode, status)
    #|  requireCheck(tree().includes(`request: loaded · HTTP ${status}`), "response status did not reach page")
    #|  requireCheck(Object.keys(observed.header).length > 0, "response headers missing")
    #|  if (index >= 5) { assert.equal(observed.data, ""); return }
    #|  const data = observed.data
    #|  // Apifox omits method; always validate the outbound host method above,
    #|  // and validate it in the reply too when the service supplies that field.
    #|  if (Object.hasOwn(data, "method")) assert.equal(data.method, lastOptions.method)
    #|  const echoedUrl = new URL(data.url), sentUrl = new URL(lastOptions.url)
    #|  assert.equal(echoedUrl.pathname, sentUrl.pathname)
    #|  assert.deepEqual(pairs(echoedUrl.searchParams), pairs(sentUrl.searchParams))
    #|  assert.deepEqual(echoedHeader(data, "x-minimoon-test"), ["public-smoke"])
    #|  if (index === 0) assert.deepEqual(normalizedPairs(data.args), { existing: ["yes"], message: ["Minimoon 测试 +&="], tag: ["one", "two"] })
    #|  if (index === 1) { assert.deepEqual(data.json, { message: "Minimoon 测试", count: 2 }); assert.deepEqual(echoedHeader(data, "content-type"), ["application/json"]) }
    #|  if (index === 2) { assert.deepEqual(normalizedPairs(data.form), { message: ["测试 +&="], tag: ["one", "two"] }); assert.deepEqual(echoedHeader(data, "content-type"), ["application/x-www-form-urlencoded"]) }
    #|  if (index === 3) { assert.equal(data.data, "Minimoon 测试 +&="); assert.deepEqual(echoedHeader(data, "content-type"), ["text/plain; charset=utf-8"]) }
    #|  if (index === 4) assert.deepEqual(normalizedPairs(data.args), { id: ["synthetic"] })
    #|}
    #|const offlineLifecycle = async () => {
    #|  dispatch("Change", "platform/http-case", { value: 0 })
    #|  const pending = []; let aborts = 0
    #|  wx.request = options => { pending.push(options); return { abort() { aborts += 1; options.fail({ errMsg: "aborted" }) } } }
    #|  dispatch("Tap", "platform/request"); dispatch("Tap", "platform/request")
    #|  assert.equal(pending.length, 2)
    #|  pending[1].success({ statusCode: 201, data: "second" }); pending[0].success({ statusCode: 202, data: "first" })
    #|  requireCheck(tree().includes("HTTP 202"), "out-of-order request IDs crossed")
    #|  const before = tree(); pending[0].success({ statusCode: 500 }); pending[1].fail({ errMsg: "duplicate" }); assert.equal(tree(), before)
    #|  wx.request = () => { throw new Error("sync failure") }; dispatch("Tap", "platform/request"); requireCheck(tree().includes("sync failure"), "synchronous failure lost")
    #|  delete wx.request; dispatch("Tap", "platform/request"); requireCheck(tree().includes("wx.request unavailable"), "unavailable failure lost")
    #|  wx.request = options => options.success({ statusCode: "bad" }); dispatch("Tap", "platform/request"); requireCheck(tree().includes("must be an integer"), "malformed success accepted")
    #|  wx.request = options => transport(options, async () => { throw new Error("offline network failure") }); dispatch("Tap", "platform/request"); await waitDone(); requireCheck(tree().includes("request:fail network"), "network failure lost")
    #|  wx.request = options => { pending.push(options); return { abort() { aborts += 1; options.fail({ errMsg: "aborted" }) } } }
    #|  host.onUnload()
    #|  require(require("node:path").resolve(require("node:path").dirname(process.argv[2]), "../request_lifecycle/request_lifecycle.js"))
    #|  start()
    #|  dispatch("Tap", "request_lifecycle/request"); const dead = host; host.onUnload(); host.onUnload(); assert.equal(aborts, 1)
    #|  const unloaded = tree(); pending.at(-1).success({ statusCode: 200, data: "late" }); assert.equal(tree(), unloaded)
    #|  start(); pending.at(-1).success({ statusCode: 200, data: "old instance" }); requireCheck(!tree().includes("old instance"), "old callback reached new instance"); assert.notEqual(host.__mmInstanceId, dead.__mmInstanceId)
    #|  let invoked = 0; wx.request = () => { invoked += 1 }
    #|  for (const payload of [{ url: "https://example.test", method: "PATCH", header: {} }, { url: "https://example.test", method: "GET", header: {}, data: "bad" }, { url: "https://example.test", method: "GET", header: {}, timeout: 0 }]) host._iv({ capability: "wx.request", request_id: "invalid", payload })
    #|  assert.equal(invoked, 0); assert.equal(host._ef.size, 0)
    #|  host.onUnload()
    #|  require(require("node:path").resolve(require("node:path").dirname(process.argv[2]), "../draft_editor/draft_editor.js"))
    #|  start({ from: "http-probe" })
    #|  assert.ok(host.__mmInstanceId, "Details must accept explicit probe route input")
    #|  host.onUnload()
    #|  require(require("node:path").resolve(require("node:path").dirname(process.argv[2]), "../workbench/workbench.js"))
    #|  start()
    #|  let rejected; const enqueue = host._en; host._en = entry => { rejected = entry }
    #|  host._iv({ capability: "wx.request", request_id: "undeclared", payload: { url: "https://example.test", method: "GET", header: {} } })
    #|  host._en = enqueue
    #|  assert.equal(invoked, 0); assert.equal(rejected.phase, "failure"); assert.equal(rejected.payload.error, "undeclared capability: wx.request")
    #|  report.cases.push({ name: "lifecycle-and-failures", status: "passed" })
    #|}
    #|const draftEcho = async () => {
    #|  host.onUnload()
    #|  const loadSibling = name => { const file = require("node:path").resolve(require("node:path").dirname(process.argv[2]), "../" + name + "/" + name + ".js"); delete require.cache[file]; require(file) }
    #|  const flush = async () => { for (let index = 0; index < 24; index++) await Promise.resolve() }
    #|  wx.request = options => transport(options)
    #|  loadSibling("draft_editor"); start({ from: "public-draft-probe" })
    #|  dispatch("Input", "draft_editor/draft-title", { value: "Minimoon draft probe" })
    #|  dispatch("Input", "draft_editor/draft-note", { value: "Synthetic public echo" })
    #|  await flush(); observed = undefined; lastOptions = undefined
    #|  const item = { name: "draft-app-echo", status: "failed" }; report.cases.push(item); save()
    #|  dispatch("Tap", "work/send"); await flush()
    #|  requireCheck(lastOptions && lastOptions.method === "POST", "draft App did not send")
    #|  assert.equal(lastOptions.url, "https://echo.apifox.com/post")
    #|  item.origin = new URL(lastOptions.url).origin
    #|  assert.deepEqual(JSON.parse(lastOptions.data), { title: "Minimoon draft probe", note: "Synthetic public echo" })
    #|  host.onUnload(); loadSibling("online"); start()
    #|  const until = Date.now() + 12000
    #|  while (!observed && Date.now() < until) await new Promise(resolve => setTimeout(resolve, 10))
    #|  await flush()
    #|  requireCheck(observed && observed.statusCode === 200 && tree().includes("typed-echo") && tree().includes("回显成功"), "typed App echo did not complete after editor unload")
    #|  item.status = "passed"; item.statusCode = 200; save()
    #|  process.stdout.write("draft-app-echo: passed\n")
    #|}
    #|const uiEcho = async () => {
    #|  host.onUnload()
    #|  requireCheck(process.argv[7] && report.uiArtifactFingerprint, "UI fixture and fingerprint are required")
    #|  require(process.argv[7]); start()
    #|  const flush = async () => { for (let index = 0; index < 24; index++) await Promise.resolve() }
    #|  dispatch("Input", "forms-field/input", { value: "Minimoon UI public probe" }); await flush()
    #|  observed = undefined; lastOptions = undefined
    #|  const item = { name: "ui-form-echo", status: "failed" }; report.cases.push(item); save()
    #|  dispatch("Submit", "forms/submit", { value: { project_name: "Minimoon UI public probe" } }); await flush()
    #|  requireCheck(lastOptions && lastOptions.method === "POST", "UI Form did not send")
    #|  assert.equal(lastOptions.url, "https://echo.apifox.com/post"); assert.equal(lastOptions.timeout, 10000)
    #|  assert.deepEqual(JSON.parse(lastOptions.data), { title: "Minimoon UI public probe" })
    #|  item.origin = new URL(lastOptions.url).origin
    #|  const until = Date.now() + 12000
    #|  while (!observed && Date.now() < until) await new Promise(resolve => setTimeout(resolve, 10))
    #|  await flush()
    #|  requireCheck(observed && observed.statusCode === 200 && tree().includes("Echo title: Minimoon UI public probe — not persisted."), "UI typed echo did not reach the form")
    #|  item.status = "passed"; item.statusCode = 200; save()
    #|  process.stdout.write("ui-form-echo: passed\n")
    #|}
    #|;(async () => {
    #|  bootApplication(process.argv[2])
    #|  require(process.argv[2])
    #|  requireCheck(definition, "generated Platform did not register Page")
    #|  const base = offline ? "https://echo.apifox.com" : process.env.MINIMOON_HTTP_BASE_URL || "https://echo.apifox.com"
    #|  const parsed = new URL(base)
    #|  requireCheck(parsed.protocol === "https:" && !parsed.username && !parsed.password && !parsed.hash && !parsed.search, "base must be a credential-free HTTPS echo service without query or fragment")
    #|  report.origin = parsed.origin
    #|  start()
    #|  dispatch("Input", "platform/http-base", { value: base.replace(/\/$/, "") })
    #|  dispatch("Tap", "platform/toggle-response")
    #|  const names = ["get-query", "post-json", "post-form", "put-text", "delete", "head", "options", "http-400", "http-500", "timeout"]
    #|  for (let index = 0; index < names.length; index += 1) {
    #|    const item = { name: names[index], status: "failed" }; report.cases.push(item); save()
    #|    dispatch("Change", "platform/http-case", { value: index }); observed = undefined; lastOptions = undefined
    #|    dispatch("Tap", "platform/request"); await waitDone(); requireCheck(observed && lastOptions, "no transport result"); verify(index)
    #|    item.status = "passed"; item.origin = new URL(lastOptions.url).origin; if (observed.statusCode) item.statusCode = observed.statusCode; save()
    #|    process.stdout.write(`${names[index]}: passed\n`)
    #|  }
    #|  if (offline) await offlineLifecycle()
    #|  await draftEcho()
    #|  await uiEcho()
    #|  report.status = "passed"
    #|})().catch(error => { report.error = "HTTP probe failed; see last case (transport/assertion/setup)"; process.stderr.write(report.error + "\n" + String(error.stack || "").split("\n").filter(line => /^\s+at /.test(line)).join("\n") + "\n"); process.exitCode = 1 }).finally(() => { if (host && host.__mmInstanceId) host.onUnload(); clearTimeout(deadline); save() })
  )
}
