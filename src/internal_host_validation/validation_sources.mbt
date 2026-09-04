///|
pub fn scheduler_host_smoke_source() -> String {
  (
    #|;(async () => {
    #|const path = require("node:path")
    #|const [hostFile, runtimeVersionSource] = process.argv.slice(2)
    #|if (!hostFile || !runtimeVersionSource) throw new Error("usage: scheduler-smoke <host-file> <runtime-version>")
    #|const runtimeVersion = Number(runtimeVersionSource)
    #|let definition
    #|globalThis.Page = (page) => { definition = page }
    #|globalThis.Component = () => { throw new Error("unexpected Component registration") }
    #|globalThis.App = () => {}
    #|let acknowledgementProbeCalls = 0
    #|globalThis.wx = {
    #|  throwNow() { throw new Error("synchronous capability throw") },
    #|  callbackThenThrow(options) { options.success({ value: "first terminal wins" }); throw new Error("throw after callback") },
    #|  acknowledgementProbe(options) { acknowledgementProbeCalls += 1; options.success({ value: "acknowledged" }) },
    #|}
    #|let now = 0
    #|Date.now = () => now
    #|let nextTimer = 1
    #|const timers = new Map()
    #|const intervals = new Map()
    #|globalThis.setTimeout = (callback, milliseconds) => {
    #|  if (milliseconds !== 3000 && milliseconds !== 500) throw new Error(`unexpected scheduler timeout: ${milliseconds}`)
    #|  const handle = nextTimer++
    #|  timers.set(handle, { callback, at: now + milliseconds })
    #|  return handle
    #|}
    #|globalThis.clearTimeout = (handle) => { timers.delete(handle) }
    #|globalThis.setInterval = (callback, milliseconds) => { const handle = nextTimer++; intervals.set(handle, { callback, milliseconds }); return handle }
    #|globalThis.clearInterval = (handle) => { intervals.delete(handle) }
    #|const advance = (milliseconds) => {
    #|  const target = now + milliseconds
    #|  while (true) {
    #|    let selected = null
    #|    for (const [handle, timer] of timers) if (timer.at <= target && (!selected || timer.at < selected[1].at)) selected = [handle, timer]
    #|    if (!selected) break
    #|    now = selected[1].at
    #|    timers.delete(selected[0])
    #|    selected[1].callback()
    #|  }
    #|  now = target
    #|}
    #|const initialTree = { kind: "text", identity: "root", text: "0:0", props: {}, events: { tap: "increment", scroll: "scroll" }, children: [] }
    #|const states = new Map()
    #|const dispatchBatches = []
    #|const drainCalls = []
    #|const effectResolutions = []
    #|const subscriptionCalls = []
    #|let nextInstance = 1
    #|let throwDuringCreate = false
    #|const runtime = {
    #|  minimoon_runtime_version: () => runtimeVersion,
    #|  minimoon_runtime_state_abi_version: () => runtimeVersion,
    #|  minimoon_runtime_create_app() {
    #|    const wake = globalThis.__minimoonRuntimeWakeV10
    #|    if (typeof wake !== "function") throw new Error("runtime wake was not installed during create")
    #|    if (throwDuringCreate) throw new Error("synchronous runtime create throw")
    #|    const id = `scheduler-${nextInstance++}`
    #|    states.set(id, { revision: 0, count: 0, scrollTop: 0, tree: structuredClone(initialTree), wake, nextAsyncSequence: 0, pendingAsync: [], pendingEffect: null })
    #|    return id
    #|  },
    #|  minimoon_runtime_dispatch_batch(id, raw) {
    #|    const events = JSON.parse(raw)
    #|    if (!Array.isArray(events) || events.some((event) => !event || !["increment", "barrier", "scroll", "delay", "render-effect"].includes(event.key))) throw new Error("invalid fake runtime event batch")
    #|    dispatchBatches.push(events)
    #|    const state = states.get(id)
    #|    const base = state.revision
    #|    for (const event of events) {
    #|      if (event.key === "increment" || event.key === "barrier" || event.key === "render-effect") state.count += 1
    #|      else if (event.key === "scroll") state.scrollTop = Number(event.payload.detail.scrollTop || 0)
    #|      else state.pendingEffect = "reused-delay"
    #|    }
    #|    if (events.some((event) => event.key === "delay")) return JSON.stringify([{ type: "InvokeCapability", component_id: "scheduler", request_id: state.pendingEffect, capability: "minimoon.timeout", payload: { ms: 500 } }])
    #|    state.revision += 1
    #|    state.tree.text = `${state.count}:${state.scrollTop}`
    #|    const render = { type: "PatchViewTree", component_id: "scheduler", base_revision: base, revision: state.revision, ops: [{ op: "set", path: ["text"], value: state.tree.text }] }
    #|    if (events.some((event) => event.key === "render-effect")) {
    #|      state.pendingEffect = "acknowledgement-probe"
    #|      return JSON.stringify([render, { type: "InvokeCapability", component_id: "scheduler", request_id: state.pendingEffect, capability: "wx.acknowledgementProbe", payload: {} }])
    #|    }
    #|    return JSON.stringify([render])
    #|  },
    #|  minimoon_runtime_lifecycle(id, hook, raw) {
    #|    if (hook !== "$minimoon:drain") return "[]"
    #|    const state = states.get(id)
    #|    const through = JSON.parse(raw).through
    #|    drainCalls.push({ id, hook, through })
    #|    if (!state) return "[]"
    #|    const ready = state.pendingAsync.filter((entry) => entry.sequence <= through)
    #|    state.pendingAsync = state.pendingAsync.filter((entry) => entry.sequence > through)
    #|    if (ready.length === 0) return "[]"
    #|    const base = state.revision
    #|    for (const entry of ready) state.count += entry.value
    #|    state.revision += 1
    #|    state.tree.text = `${state.count}:${state.scrollTop}`
    #|    return JSON.stringify([{ type: "PatchViewTree", component_id: "scheduler", base_revision: base, revision: state.revision, ops: [{ op: "set", path: ["text"], value: state.tree.text }] }])
    #|  },
    #|  minimoon_runtime_mount: () => "[]",
    #|  minimoon_runtime_subscription(id, key) { subscriptionCalls.push({ id, key }); return "[]" },
    #|  minimoon_runtime_resolve_effect(id, requestId, phase, payload) { effectResolutions.push({ id, requestId, phase, payload }); const state = states.get(id); if (state && state.pendingEffect === requestId) state.pendingEffect = null; return "[]" },
    #|  minimoon_runtime_snapshot(id) {
    #|    const state = states.get(id)
    #|    return JSON.stringify({ revision: state.revision, tree: state.tree })
    #|  },
    #|  minimoon_runtime_dispose(id) { const state = states.get(id); states.delete(id); return state && state.pendingEffect ? JSON.stringify([{ type: "CancelEffect", component_id: "scheduler", request_id: state.pendingEffect }]) : "[]" },
    #|}
    #|const { registerMinimoonPage } = require(path.resolve(hostFile))
    #|registerMinimoonPage(runtime, "scheduler", initialTree, ["wx.throwNow", "wx.callbackThenThrow", "wx.acknowledgementProbe"])
    #|if (!definition) throw new Error("scheduler page was not registered")
    #|const resolve = (root, tokens) => { let value = root; for (const token of tokens) value = value[token]; return value }
    #|const assign = (root, tokens, value) => { const parent = resolve(root, tokens.slice(0, -1)); parent[tokens[tokens.length - 1]] = value }
    #|const makeUnloadedHost = () => {
    #|  const acknowledgements = []
    #|  const host = {
    #|    ...definition,
    #|    data: structuredClone(definition.data),
    #|    acknowledgements,
    #|    setData(patch, callback) {
    #|      for (const [key, value] of Object.entries(patch)) {
    #|        const tokens = key.replace(/\[(\d+)\]/g, ".$1").split(".").map((token) => /^\d+$/.test(token) ? Number(token) : token)
    #|        assign(this.data, tokens, value)
    #|      }
    #|      if (callback) acknowledgements.push(callback)
    #|    },
    #|  }
    #|  return host
    #|}
    #|const makeHost = () => {
    #|  const host = makeUnloadedHost()
    #|  const hadRuntimeWake = Object.prototype.hasOwnProperty.call(globalThis, "__minimoonRuntimeWakeV10")
    #|  const previousRuntimeWake = globalThis.__minimoonRuntimeWakeV10
    #|  definition.onLoad.call(host, {})
    #|  if (Object.prototype.hasOwnProperty.call(globalThis, "__minimoonRuntimeWakeV10") !== hadRuntimeWake || (hadRuntimeWake && globalThis.__minimoonRuntimeWakeV10 !== previousRuntimeWake)) throw new Error("transient runtime wake was not restored")
    #|  definition.onReady.call(host)
    #|  return host
    #|}
    #|const dispatchTap = (host, key = "increment") => definition.__mmDispatchTap.call(host, { currentTarget: { dataset: { minimoonTap: key } }, target: { dataset: {} }, detail: {} })
    #|const dispatchScroll = (host, top, key = "scroll") => definition.__mmDispatchScroll.call(host, { currentTarget: { dataset: { minimoonScroll: key } }, target: { dataset: {} }, detail: { scrollTop: top } })
    #|const emitAsync = (state, value) => { const sequence = ++state.nextAsyncSequence; state.pendingAsync.push({ sequence, value }); state.wake(sequence); return sequence }
    #|const acknowledge = (host, milliseconds = 0) => {
    #|  advance(milliseconds)
    #|  const callback = host.acknowledgements.shift()
    #|  if (!callback) throw new Error("missing render acknowledgement callback")
    #|  callback()
    #|}
    #|const errors = []
    #|const warnings = []
    #|const originalError = console.error
    #|const originalWarn = console.warn
    #|console.error = (...args) => errors.push(args.join(" "))
    #|console.warn = (...args) => warnings.push(args.join(" "))
    #|
    #|const createThrowSentinelWake = () => {}
    #|globalThis.__minimoonRuntimeWakeV10 = createThrowSentinelWake
    #|const createThrowHost = makeUnloadedHost()
    #|throwDuringCreate = true
    #|let createThrowError = null
    #|try { definition.onLoad.call(createThrowHost, {}) } catch (error) { createThrowError = error } finally { throwDuringCreate = false }
    #|if (!createThrowError || !String(createThrowError.message || createThrowError).includes("synchronous runtime create throw")) throw new Error("synchronous runtime create failure did not propagate")
    #|if (globalThis.__minimoonRuntimeWakeV10 !== createThrowSentinelWake || createThrowHost.__mmInstanceId !== null) throw new Error("runtime wake was not restored after synchronous runtime create failure")
    #|delete globalThis.__minimoonRuntimeWakeV10
    #|
    #|const host = makeHost()
    #|const batchStart = dispatchBatches.length
    #|dispatchTap(host)
    #|if (dispatchBatches.length !== batchStart + 1 || dispatchBatches[batchStart].length !== 1) throw new Error("first scheduler entry was not immediate")
    #|dispatchTap(host)
    #|dispatchTap(host)
    #|if (dispatchBatches.length !== batchStart + 1) throw new Error("scheduler ran while a render was in flight")
    #|if (host.__minimoonRendererStats().maxEventBatch !== 2) throw new Error("adjacent tap events were not batched")
    #|acknowledge(host, 16)
    #|if (dispatchBatches.length !== batchStart + 2 || dispatchBatches[batchStart + 1].length !== 2) throw new Error("queued tap batch order changed")
    #|acknowledge(host, 150)
    #|const batched = host.__minimoonRendererStats()
    #|if (batched.receivedUiEvents !== 3 || batched.coalescedEvents !== 0 || batched.eventBatches !== 2 || batched.renderCommits !== 2 || batched.renderAckSamples !== 2 || batched.renderAckTotalMs !== 166 || batched.renderAckMaxMs !== 150 || batched.renderAckLastMs !== 150 || host.data.scheduler.tree.text !== "3:0") throw new Error(`batched scheduler result mismatch: ${JSON.stringify(batched)}`)
    #|definition.onUnload.call(host)
    #|
    #|const asyncHost = makeHost()
    #|const asyncState = states.get(asyncHost.__mmInstanceId)
    #|const asyncDrainStart = drainCalls.length
    #|dispatchTap(asyncHost)
    #|const firstAsyncThrough = emitAsync(asyncState, 10)
    #|asyncState.wake(firstAsyncThrough)
    #|await Promise.resolve()
    #|if (asyncHost.__minimoonRendererStats().asyncDrains !== 0 || asyncHost._q.map((entry) => `${entry.kind}:${entry.through || 0}`).join(",") !== "drain:1") throw new Error("first asynchronous wake did not queue one bounded drain")
    #|dispatchTap(asyncHost)
    #|const secondAsyncThrough = emitAsync(asyncState, 100)
    #|asyncState.wake(secondAsyncThrough)
    #|await Promise.resolve()
    #|if (asyncHost._q.map((entry) => `${entry.kind}:${entry.through || 0}`).join(",") !== "drain:1,dispatch:0,drain:2") throw new Error("asynchronous drain watermark crossed a queued UI entry")
    #|acknowledge(asyncHost)
    #|if (asyncHost.__minimoonRendererStats().asyncDrains !== 1 || drainCalls.length !== asyncDrainStart + 1 || drainCalls[asyncDrainStart].through !== 1 || asyncHost.__minimoonRendererStats().renderCommits !== 1 || !asyncHost._bz || asyncHost._q.map((entry) => entry.kind).join(",") !== "dispatch,drain") throw new Error("first bounded drain did not start after the prior render")
    #|acknowledge(asyncHost)
    #|if (asyncHost.data.scheduler.tree.text !== "12:0" || asyncHost.__minimoonRendererStats().asyncDrains !== 1 || asyncHost.__minimoonRendererStats().renderCommits !== 2 || !asyncHost._bz || asyncHost._q.map((entry) => entry.kind).join(",") !== "drain") throw new Error("queued UI entry did not remain between bounded drains")
    #|acknowledge(asyncHost)
    #|if (asyncHost.data.scheduler.tree.text !== "112:0" || asyncHost.__minimoonRendererStats().asyncDrains !== 2 || drainCalls.length !== asyncDrainStart + 2 || drainCalls[asyncDrainStart + 1].through !== 2 || asyncHost.__minimoonRendererStats().renderCommits !== 3 || !asyncHost._bz) throw new Error("second bounded drain did not wait for the queued UI entry")
    #|acknowledge(asyncHost)
    #|if (asyncHost.data.scheduler.tree.text !== "112:0" || asyncHost.__minimoonRendererStats().renderCommits !== 4 || asyncHost._bz || asyncHost._q.length !== 0 || asyncState.pendingAsync.length !== 0) throw new Error("bounded asynchronous drains did not preserve D1/UI/D2 order")
    #|definition.onUnload.call(asyncHost)
    #|
    #|const isolatedLeft = makeHost()
    #|const isolatedRight = makeHost()
    #|const isolatedLeftState = states.get(isolatedLeft.__mmInstanceId)
    #|const isolatedRightState = states.get(isolatedRight.__mmInstanceId)
    #|const isolatedLeftThrough = emitAsync(isolatedLeftState, 3)
    #|const isolatedRightThrough = emitAsync(isolatedRightState, 5)
    #|isolatedLeftState.wake(isolatedLeftThrough)
    #|isolatedRightState.wake(isolatedRightThrough)
    #|await Promise.resolve()
    #|if (isolatedLeft.__minimoonRendererStats().asyncDrains !== 1 || isolatedRight.__minimoonRendererStats().asyncDrains !== 1 || isolatedLeft.acknowledgements.length !== 1 || isolatedRight.acknowledgements.length !== 1) throw new Error("simultaneous runtime wakes were not isolated by page host")
    #|acknowledge(isolatedLeft)
    #|acknowledge(isolatedRight)
    #|if (isolatedLeft.data.scheduler.tree.text !== "3:0" || isolatedRight.data.scheduler.tree.text !== "5:0") throw new Error("simultaneous runtime drains crossed page instances")
    #|definition.onUnload.call(isolatedLeft)
    #|definition.onUnload.call(isolatedRight)
    #|
    #|const sentinelWake = () => {}
    #|globalThis.__minimoonRuntimeWakeV10 = sentinelWake
    #|const reusable = makeHost()
    #|if (globalThis.__minimoonRuntimeWakeV10 !== sentinelWake) throw new Error("preexisting runtime wake was not restored")
    #|delete globalThis.__minimoonRuntimeWakeV10
    #|const staleState = states.get(reusable.__mmInstanceId)
    #|const staleWake = staleState.wake
    #|staleWake(1)
    #|definition.onUnload.call(reusable)
    #|definition.onLoad.call(reusable, {})
    #|definition.onReady.call(reusable)
    #|const replacementState = states.get(reusable.__mmInstanceId)
    #|staleWake(1)
    #|const replacementThrough = emitAsync(replacementState, 2)
    #|replacementState.wake(replacementThrough)
    #|await Promise.resolve()
    #|if (reusable.__minimoonRendererStats().asyncDrains !== 1 || reusable.acknowledgements.length !== 1 || replacementState.pendingAsync.length !== 0) throw new Error("stale wake microtask cleared or reached a replacement runtime wake")
    #|acknowledge(reusable)
    #|definition.onUnload.call(reusable)
    #|
    #|const delayed = makeHost()
    #|for (const delay of [0, 16, 150, 500, 2999]) { dispatchTap(delayed); acknowledge(delayed, delay) }
    #|const delayedStats = delayed.__minimoonRendererStats()
    #|if (delayedStats.renderAckSamples !== 5 || delayedStats.renderAckTotalMs !== 3665 || delayedStats.renderAckMaxMs !== 2999 || delayedStats.renderAckLastMs !== 2999 || delayedStats.renderTimeouts !== 0) throw new Error(`delayed acknowledgement metrics mismatch: ${JSON.stringify(delayedStats)}`)
    #|definition.onUnload.call(delayed)
    #|
    #|const acknowledgedEffect = makeHost()
    #|const acknowledgedEffectStart = acknowledgementProbeCalls
    #|const acknowledgedResolutionStart = effectResolutions.length
    #|dispatchTap(acknowledgedEffect, "render-effect")
    #|if (acknowledgementProbeCalls !== acknowledgedEffectStart || effectResolutions.length !== acknowledgedResolutionStart || acknowledgedEffect.acknowledgements.length !== 1) throw new Error("render-coupled capability ran before acknowledgement")
    #|acknowledge(acknowledgedEffect)
    #|const acknowledgedResolutions = effectResolutions.slice(acknowledgedResolutionStart)
    #|if (acknowledgementProbeCalls !== acknowledgedEffectStart + 1 || acknowledgedResolutions.length !== 1 || acknowledgedResolutions[0].requestId !== "acknowledgement-probe" || acknowledgedResolutions[0].phase !== "success" || acknowledgedEffect._ef.size !== 0 || acknowledgedEffect._q.length !== 0) throw new Error("render-coupled capability did not resolve exactly once after acknowledgement")
    #|definition.onUnload.call(acknowledgedEffect)
    #|
    #|const retriedEffect = makeHost()
    #|const retriedEffectStart = acknowledgementProbeCalls
    #|const retriedResolutionStart = effectResolutions.length
    #|dispatchTap(retriedEffect, "render-effect")
    #|advance(3000)
    #|if (acknowledgementProbeCalls !== retriedEffectStart || effectResolutions.length !== retriedResolutionStart || retriedEffect.__minimoonRendererStats().renderRetries !== 1 || retriedEffect.acknowledgements.length !== 2) throw new Error("snapshot retry released a capability before acknowledgement")
    #|acknowledge(retriedEffect)
    #|if (acknowledgementProbeCalls !== retriedEffectStart || effectResolutions.length !== retriedResolutionStart) throw new Error("stale pre-retry acknowledgement released a capability")
    #|acknowledge(retriedEffect)
    #|const retriedResolutions = effectResolutions.slice(retriedResolutionStart)
    #|if (acknowledgementProbeCalls !== retriedEffectStart + 1 || retriedResolutions.length !== 1 || retriedResolutions[0].requestId !== "acknowledgement-probe" || retriedResolutions[0].phase !== "success" || retriedEffect._ef.size !== 0) throw new Error("retry acknowledgement did not resolve one capability")
    #|definition.onUnload.call(retriedEffect)
    #|
    #|const failedEffect = makeHost()
    #|const failedEffectStart = acknowledgementProbeCalls
    #|const failedResolutionStart = effectResolutions.length
    #|dispatchTap(failedEffect, "render-effect")
    #|advance(3000)
    #|advance(3000)
    #|if (acknowledgementProbeCalls !== failedEffectStart || effectResolutions.length !== failedResolutionStart || failedEffect.__minimoonRendererStats().schedulerFailures !== 1) throw new Error("fail-closed render released its withheld capability")
    #|for (const callback of failedEffect.acknowledgements.splice(0)) callback()
    #|if (acknowledgementProbeCalls !== failedEffectStart || effectResolutions.length !== failedResolutionStart) throw new Error("stale failed acknowledgements released a capability")
    #|definition.onUnload.call(failedEffect)
    #|
    #|const unloadedEffect = makeHost()
    #|const unloadedEffectStart = acknowledgementProbeCalls
    #|const unloadedResolutionStart = effectResolutions.length
    #|dispatchTap(unloadedEffect, "render-effect")
    #|definition.onUnload.call(unloadedEffect)
    #|for (const callback of unloadedEffect.acknowledgements.splice(0)) callback()
    #|if (acknowledgementProbeCalls !== unloadedEffectStart || effectResolutions.length !== unloadedResolutionStart) throw new Error("unloaded render released its withheld capability")
    #|
    #|const sustained = makeHost()
    #|const sustainedStart = dispatchBatches.length
    #|dispatchTap(sustained)
    #|for (let index = 0; index < 100000; index += 1) dispatchScroll(sustained, index)
    #|let sustainedStats = sustained.__minimoonRendererStats()
    #|if (sustainedStats.receivedUiEvents !== 100001 || sustainedStats.coalescedEvents !== 99999 || sustainedStats.maxEventBatch !== 1 || sustainedStats.schedulerFailures !== 0) throw new Error(`sustained scroll was not bounded: ${JSON.stringify(sustainedStats)}`)
    #|acknowledge(sustained)
    #|if (dispatchBatches.length !== sustainedStart + 2 || dispatchBatches[sustainedStart + 1].length !== 1 || dispatchBatches[sustainedStart + 1][0].payload.detail.scrollTop !== 99999) throw new Error("sustained scroll did not retain the latest payload")
    #|acknowledge(sustained, 500)
    #|definition.onUnload.call(sustained)
    #|
    #|const barrier = makeHost()
    #|const barrierStart = dispatchBatches.length
    #|dispatchTap(barrier)
    #|dispatchScroll(barrier, 1)
    #|dispatchTap(barrier, "barrier")
    #|dispatchScroll(barrier, 2)
    #|dispatchScroll(barrier, 3)
    #|if (barrier.__minimoonRendererStats().coalescedEvents !== 1 || barrier.__minimoonRendererStats().maxEventBatch !== 3) throw new Error("scroll coalescing crossed a tap barrier")
    #|acknowledge(barrier)
    #|const barrierBatch = dispatchBatches[barrierStart + 1]
    #|if (barrierBatch.map((event) => event.key).join(",") !== "scroll,barrier,scroll" || barrierBatch[2].payload.detail.scrollTop !== 3) throw new Error(`scroll/tap ordering changed: ${JSON.stringify(barrierBatch)}`)
    #|acknowledge(barrier)
    #|definition.onUnload.call(barrier)
    #|
    #|const timeout = makeHost()
    #|const timeoutState = states.get(timeout.__mmInstanceId)
    #|dispatchTap(timeout)
    #|advance(3000)
    #|let timeoutStats = timeout.__minimoonRendererStats()
    #|if (timeoutStats.renderTimeouts !== 1 || timeoutStats.renderRetries !== 1 || timeoutStats.schedulerFailures !== 0) throw new Error(`snapshot retry did not start exactly once: ${JSON.stringify(timeoutStats)}`)
    #|const timeoutThrough = emitAsync(timeoutState, 7)
    #|advance(3000)
    #|await Promise.resolve()
    #|timeoutStats = timeout.__minimoonRendererStats()
    #|if (timeoutStats.renderTimeouts !== 2 || timeoutStats.renderRetries !== 1 || timeoutStats.schedulerFailures !== 1 || timeoutStats.asyncDrains !== 0 || timeout._q.length !== 0) throw new Error(`second timeout did not fail closed: ${JSON.stringify(timeoutStats)}`)
    #|timeoutState.wake(timeoutThrough)
    #|await Promise.resolve()
    #|if (timeout.__minimoonRendererStats().asyncDrains !== 0 || timeout._q.length !== 0) throw new Error("failed-closed scheduler accepted a stale runtime wake")
    #|const beforeClosedDispatch = dispatchBatches.length
    #|dispatchTap(timeout)
    #|if (dispatchBatches.length !== beforeClosedDispatch) throw new Error("failed-closed scheduler accepted another event")
    #|for (const callback of timeout.acknowledgements.splice(0)) callback()
    #|definition.onUnload.call(timeout)
    #|
    #|const ownedDelay = makeHost()
    #|const delayResolutionStart = effectResolutions.length
    #|dispatchTap(ownedDelay, "delay")
    #|const delayTimer = Array.from(timers.entries()).find((entry) => entry[1].at === now + 500)
    #|if (!delayTimer || ownedDelay._ef.size !== 1) throw new Error("owned timeout effect was not registered")
    #|const lateDelayCallback = delayTimer[1].callback
    #|definition.onUnload.call(ownedDelay)
    #|if (ownedDelay.__minimoonRendererStats().effectCancellations !== 1 || ownedDelay._ef.size !== 0 || timers.has(delayTimer[0])) throw new Error("runtime disposal did not cancel its owned timeout effect")
    #|lateDelayCallback()
    #|advance(500)
    #|await Promise.resolve()
    #|if (effectResolutions.length !== delayResolutionStart || ownedDelay._q.length !== 0 || ownedDelay.__mmInstanceId !== null) throw new Error("cancelled timeout completed after page unload")
    #|
    #|const invalidTimeout = makeHost()
    #|const invalidTimeoutResolutionStart = effectResolutions.length
    #|const invalidTimeoutTimerStart = timers.size
    #|const invalidTimeoutPayloads = [null, "invalid", {}, { ms: 1, extra: true }, { ms: -1 }, { ms: 1.5 }]
    #|for (const [index, payload] of invalidTimeoutPayloads.entries()) definition._iv.call(invalidTimeout, { type: "InvokeCapability", component_id: "scheduler", request_id: `invalid-timeout-${index}`, capability: "minimoon.timeout", payload })
    #|const invalidTimeoutResolutions = effectResolutions.slice(invalidTimeoutResolutionStart)
    #|if (timers.size !== invalidTimeoutTimerStart || invalidTimeout._ef.size !== 0 || invalidTimeout._q.length !== 0 || invalidTimeoutResolutions.length !== invalidTimeoutPayloads.length || invalidTimeoutResolutions.some((entry) => entry.phase !== "failure")) throw new Error("invalid minimoon.timeout payload did not fail exactly once without a timer")
    #|definition.onUnload.call(invalidTimeout)
    #|
    #|const throwingEffect = makeHost()
    #|const throwingResolutionStart = effectResolutions.length
    #|definition._iv.call(throwingEffect, { type: "InvokeCapability", component_id: "scheduler", request_id: "throwing-effect", capability: "wx.throwNow", payload: {} })
    #|const throwingResolutions = effectResolutions.slice(throwingResolutionStart)
    #|if (throwingResolutions.length !== 1 || throwingResolutions[0].phase !== "failure" || !JSON.parse(throwingResolutions[0].payload).error.includes("synchronous capability throw") || throwingEffect._ef.size !== 0 || throwingEffect._q.length !== 0) throw new Error("synchronous capability throw did not resolve exactly once as failure")
    #|definition.onUnload.call(throwingEffect)
    #|
    #|const callbackThenThrowEffect = makeHost()
    #|const callbackThenThrowResolutionStart = effectResolutions.length
    #|definition._iv.call(callbackThenThrowEffect, { type: "InvokeCapability", component_id: "scheduler", request_id: "callback-then-throw-effect", capability: "wx.callbackThenThrow", payload: {} })
    #|const callbackThenThrowResolutions = effectResolutions.slice(callbackThenThrowResolutionStart)
    #|if (callbackThenThrowResolutions.length !== 1 || callbackThenThrowResolutions[0].phase !== "success" || callbackThenThrowEffect._ef.size !== 0 || callbackThenThrowEffect._q.length !== 0) throw new Error("callback-then-throw violated first-terminal effect resolution")
    #|definition.onUnload.call(callbackThenThrowEffect)
    #|
    #|const reusedEffect = makeHost()
    #|dispatchTap(reusedEffect, "delay")
    #|const reusedOldTimer = Array.from(timers.entries()).find((entry) => entry[1].at === now + 500)
    #|if (!reusedOldTimer || !reusedEffect._ef.has("reused-delay")) throw new Error("first reused timeout effect was not registered")
    #|const reusedOldCallback = reusedOldTimer[1].callback
    #|definition.onUnload.call(reusedEffect)
    #|definition.onLoad.call(reusedEffect, {})
    #|definition.onReady.call(reusedEffect)
    #|dispatchTap(reusedEffect, "delay")
    #|const reusedNewTimer = Array.from(timers.entries()).find((entry) => entry[1].at === now + 500)
    #|if (!reusedNewTimer || !reusedEffect._ef.has("reused-delay")) throw new Error("replacement reused timeout effect was not registered")
    #|const reusedResolutionStart = effectResolutions.length
    #|reusedOldCallback()
    #|if (effectResolutions.length !== reusedResolutionStart || !reusedEffect._ef.has("reused-delay") || reusedEffect._q.length !== 0) throw new Error("stale effect completion consumed a replacement request ID")
    #|timers.delete(reusedNewTimer[0])
    #|reusedNewTimer[1].callback()
    #|if (effectResolutions.length !== reusedResolutionStart + 1 || reusedEffect._ef.size !== 0 || reusedEffect._q.length !== 0) throw new Error("replacement effect completion did not resolve exactly once")
    #|definition.onUnload.call(reusedEffect)
    #|
    #|const reusedSubscription = makeHost()
    #|const subscriptionCommand = { type: "StartSubscription", component_id: "scheduler", key: "reused", interval_ms: 10 }
    #|definition._ss.call(reusedSubscription, subscriptionCommand)
    #|const firstSubscriptionHandle = reusedSubscription._sb.get("reused")
    #|const firstSubscriptionCallback = intervals.get(firstSubscriptionHandle).callback
    #|definition._ss.call(reusedSubscription, { ...subscriptionCommand, interval_ms: 20 })
    #|const restartedSubscriptionHandle = reusedSubscription._sb.get("reused")
    #|const restartedSubscriptionCallback = intervals.get(restartedSubscriptionHandle).callback
    #|const subscriptionCallStart = subscriptionCalls.length
    #|firstSubscriptionCallback()
    #|if (subscriptionCalls.length !== subscriptionCallStart || reusedSubscription._q.length !== 0) throw new Error("stale restarted subscription tick reached the runtime")
    #|restartedSubscriptionCallback()
    #|if (subscriptionCalls.length !== subscriptionCallStart + 1 || reusedSubscription._q.length !== 0) throw new Error("current restarted subscription tick did not reach the runtime")
    #|definition.onUnload.call(reusedSubscription)
    #|definition.onLoad.call(reusedSubscription, {})
    #|definition.onReady.call(reusedSubscription)
    #|definition._ss.call(reusedSubscription, subscriptionCommand)
    #|const replacementSubscriptionHandle = reusedSubscription._sb.get("reused")
    #|const replacementSubscriptionCallback = intervals.get(replacementSubscriptionHandle).callback
    #|restartedSubscriptionCallback()
    #|if (subscriptionCalls.length !== subscriptionCallStart + 1 || reusedSubscription._q.length !== 0) throw new Error("stale reloaded subscription tick reached the replacement runtime")
    #|replacementSubscriptionCallback()
    #|if (subscriptionCalls.length !== subscriptionCallStart + 2 || reusedSubscription._q.length !== 0) throw new Error("replacement subscription tick did not reach its runtime")
    #|definition.onUnload.call(reusedSubscription)
    #|
    #|const overload = makeHost()
    #|dispatchTap(overload)
    #|for (let index = 0; index < 2048; index += 1) dispatchTap(overload)
    #|let overloadStats = overload.__minimoonRendererStats()
    #|if (overloadStats.schedulerWarnings !== 1 || overloadStats.maxEventBatch !== 2048 || overloadStats.schedulerFailures !== 0) throw new Error(`scheduler thresholds changed: ${JSON.stringify(overloadStats)}`)
    #|dispatchTap(overload)
    #|overloadStats = overload.__minimoonRendererStats()
    #|if (overloadStats.receivedUiEvents !== 2050 || overloadStats.schedulerFailures !== 1 || !warnings.some((message) => message.includes("256")) || !errors.some((message) => message.includes("2048"))) throw new Error(`scheduler overload did not fail closed: ${JSON.stringify({ overloadStats, warnings, errors })}`)
    #|for (const callback of overload.acknowledgements.splice(0)) callback()
    #|definition.onUnload.call(overload)
    #|
    #|const unloading = makeHost()
    #|dispatchTap(unloading)
    #|definition.onShow.call(unloading)
    #|dispatchScroll(unloading, 1)
    #|let cancelled = 0
    #|const interval = setInterval(() => {}, 10)
    #|unloading._sb.set("manual", interval)
    #|unloading._ef.set("manual", () => { cancelled += 1 })
    #|if (unloading.__minimoonRendererStats().maxQueueDepth < 2) throw new Error("maximum queue depth was not recorded")
    #|definition.onUnload.call(unloading)
    #|if (unloading._q.length !== 0 || unloading._pr !== null || unloading._cr !== null || unloading._at !== null || unloading._sb.size !== 0 || unloading._ef.size !== 0 || cancelled !== 1) throw new Error("unload did not clear scheduler resources")
    #|
    #|globalThis.gc()
    #|const heapBefore = process.memoryUsage().heapUsed
    #|const retainedBatchCount = dispatchBatches.length
    #|const createdBefore = nextInstance
    #|for (let cycle = 0; cycle < 1000; cycle += 1) {
    #|  const repeated = makeHost()
    #|  dispatchTap(repeated)
    #|  for (let index = 0; index < 10; index += 1) dispatchScroll(repeated, cycle * 10 + index)
    #|  acknowledge(repeated)
    #|  acknowledge(repeated)
    #|  definition.onUnload.call(repeated)
    #|  if (repeated.__mmInstanceId !== null || repeated._q.length !== 0 || repeated._sb.size !== 0 || repeated._ef.size !== 0 || repeated.acknowledgements.length !== 0) throw new Error(`repeated lifecycle ${cycle} retained host resources`)
    #|  dispatchBatches.length = retainedBatchCount
    #|}
    #|if (nextInstance - createdBefore !== 1000 || states.size !== 0) throw new Error(`repeated lifecycle leaked ${states.size} runtime state(s)`)
    #|globalThis.gc()
    #|const heapAfter = process.memoryUsage().heapUsed
    #|const heapDelta = heapAfter - heapBefore
    #|if (heapDelta > 16 * 1024 * 1024) throw new Error(`repeated lifecycle retained ${heapDelta} heap bytes`)
    #|console.error = originalError
    #|console.warn = originalWarn
    #|if (timers.size !== 0) throw new Error(`scheduler leaked ${timers.size} timer(s)`)
    #|if (intervals.size !== 0) throw new Error(`scheduler leaked ${intervals.size} interval(s)`)
    #|process.stdout.write(`${JSON.stringify({ schemaVersion: 1, scenario: "scheduler-mount-dispatch-dispose", cycles: 1000, forcedGc: true, heapBefore, heapAfter, heapDelta, retainedRuntimeStates: states.size, retainedTimers: timers.size, retainedIntervals: intervals.size }, null, 2)}\n`)
    #|})().catch((error) => { process.stderr.write(`${error && error.stack ? error.stack : error}\n`); process.exitCode = 1 })
    #|
  )
}

///|
pub fn dynamic_app_host_smoke_source() -> String {
  (
    #|let definition
    #|let host
    #|;(async () => {
    #|globalThis.Page = (page) => { definition = page }
    #|globalThis.Component = () => { throw new Error("unvalidated Chaining page registration is forbidden") }
    #|globalThis.App = () => {}
    #|globalThis.wx = { navigateTo() {}, redirectTo() {} }
    #|let now = 0
    #|let nextTimer = 1
    #|const timers = new Map()
    #|const intervals = new Map()
    #|Date.now = () => now
    #|globalThis.setTimeout = (callback, milliseconds) => {
    #|  const handle = nextTimer++
    #|  timers.set(handle, { callback, at: now + Number(milliseconds) })
    #|  return handle
    #|}
    #|globalThis.clearTimeout = (handle) => { timers.delete(handle) }
    #|globalThis.setInterval = (callback, milliseconds) => {
    #|  const handle = nextTimer++
    #|  intervals.set(handle, { callback, milliseconds })
    #|  return handle
    #|}
    #|globalThis.clearInterval = (handle) => { intervals.delete(handle) }
    #|const flushMicrotasks = async () => { for (let index = 0; index < 8; index += 1) await Promise.resolve() }
    #|const advance = async (milliseconds) => {
    #|  const target = now + milliseconds
    #|  while (true) {
    #|    await flushMicrotasks()
    #|    let selected = null
    #|    for (const entry of timers.entries()) {
    #|      const [handle, timer] = entry
    #|      if (timer.at <= target && (!selected || timer.at < selected[1].at || (timer.at === selected[1].at && handle < selected[0]))) selected = entry
    #|    }
    #|    if (!selected) break
    #|    now = selected[1].at
    #|    timers.delete(selected[0])
    #|    selected[1].callback()
    #|  }
    #|  now = target
    #|  await flushMicrotasks()
    #|}
    #|require(process.argv[2])
    #|const pending = []
    #|const resolve = (root, path) => { let value = root; for (const token of path) value = value[token]; return value }
    #|const assign = (root, path, value) => { const parent = resolve(root, path.slice(0, -1)); parent[path[path.length - 1]] = value }
    #|host = {
    #|  ...definition,
    #|  data: structuredClone(definition.data),
    #|  setData(patch, callback) {
    #|    for (const [path, value] of Object.entries(patch)) {
    #|      const tokens = path.replace(/\[(\d+)\]/g, ".$1").split(".").map((token) => /^\d+$/.test(token) ? Number(token) : token)
    #|      assign(this.data, tokens, value)
    #|    }
    #|    if (callback) callback()
    #|  },
    #|  replaceDataOnPath(path, value) { pending.push(["set", path, value]) },
    #|  spliceArrayDataOnPath(path, index, del, items) { pending.push(["splice", path, index, del, items]) },
    #|  groupUpdates(callback) {
    #|    callback()
    #|    for (const op of pending.splice(0)) {
    #|      if (op[0] === "set") assign(this.data, op[1], op[2])
    #|      else resolve(this.data, op[1]).splice(op[2], op[3], ...op[4])
    #|    }
    #|  },
    #|}
    #|definition.onLoad.call(host, {})
    #|definition.onReady.call(host)
    #|const dispatch = (key, detail = {}, expectedCommits = 1) => {
    #|  const before = host.__minimoonRendererStats().renderCommits
    #|  const input = key === "dynamic/name"
    #|  const handler = input ? definition.__mmDispatchInput : definition.__mmDispatchTap
    #|  const field = input ? "minimoonInput" : "minimoonTap"
    #|  handler.call(host, {
    #|    currentTarget: { dataset: { [field]: key } },
    #|    target: { dataset: {} },
    #|    detail,
    #|  })
    #|  const commits = host.__minimoonRendererStats().renderCommits - before
    #|  if (commits !== expectedCommits) throw new Error(`${key} emitted ${commits} renderer commits; expected ${expectedCommits}`)
    #|}
    #|dispatch("dynamic/increment")
    #|if (host.__minimoonRendererStats().setOps < 1) throw new Error("scalar set patch was not used")
    #|dispatch("dynamic/toggle")
    #|if (!JSON.stringify(host.data).includes("expanded branch")) throw new Error("conditional branch did not update")
    #|if (host.__minimoonRendererStats().spliceOps < 1) throw new Error("structural splice patch was not used")
    #|dispatch("dynamic/add-note")
    #|if (!JSON.stringify(host.data).includes("note-1")) throw new Error("unkeyed splice did not update")
    #|dispatch("dynamic/name", { value: "Minimoon cursor probe" })
    #|if (!JSON.stringify(host.data).includes("hello:Minimoon cursor probe")) throw new Error("controlled input event failed")
    #|const findFocusProbeGroup = (node) => {
    #|  if (!node || typeof node !== "object") return null
    #|  if (Array.isArray(node.children) && node.children.some((child) => child.identity === "k:focus-probe")) return node
    #|  for (const child of node.children || []) { const found = findFocusProbeGroup(child); if (found) return found }
    #|  return null
    #|}
    #|const beforeKeyedGroup = findFocusProbeGroup(host.data.lab.tree)
    #|const beforeOrder = beforeKeyedGroup?.children.map((node) => node.identity).join(",") || ""
    #|if (beforeOrder !== "k:focus-probe,k:a,k:b,k:c") throw new Error(`wrong initial keyed order: ${beforeOrder}`)
    #|const focusedProbe = beforeKeyedGroup.children[0]
    #|const beforeArm = host.__minimoonRendererStats()
    #|dispatch("dynamic/arm-focused-reorder", {}, 0)
    #|const afterArm = host.__minimoonRendererStats()
    #|if (afterArm.hostWriteOps !== beforeArm.hostWriteOps || afterArm.renderCommits !== beforeArm.renderCommits || afterArm.subscriptionStops - beforeArm.subscriptionStops !== 1 || afterArm.subscriptionStarts - beforeArm.subscriptionStarts !== 1 || Array.from(host._sb.keys()).join(",") !== "lab/focused-keyed-reorder") throw new Error(`focused reorder arm did not isolate its subscription without a tree write: ${JSON.stringify({ beforeArm, afterArm, subscriptions: Array.from(host._sb.keys()) })}`)
    #|const beforeMove = host.__minimoonRendererStats()
    #|host._en({ kind: "subscription", key: "lab/focused-keyed-reorder" })
    #|const keyedGroup = findFocusProbeGroup(host.data.lab.tree)
    #|const order = keyedGroup?.children.map((node) => node.identity).join(",") || ""
    #|if (order !== "k:focus-probe,k:c,k:a,k:b") throw new Error(`wrong keyed order: ${order}`)
    #|if (keyedGroup.children[0] !== focusedProbe || keyedGroup.children[0].props.value !== "Minimoon cursor probe" || !JSON.stringify(host.data).includes("hello:Minimoon cursor probe")) throw new Error("focused keyed input identity or controlled value changed")
    #|const afterMove = host.__minimoonRendererStats()
    #|if (afterMove.moveOps - beforeMove.moveOps !== 1 || afterMove.hostWriteOps - beforeMove.hostWriteOps !== 2 || afterMove.spliceOps !== beforeMove.spliceOps || afterMove.replaceCommands !== beforeMove.replaceCommands || afterMove.patchFallbacks !== beforeMove.patchFallbacks || afterMove.subscriptionStops - beforeMove.subscriptionStops !== 1 || afterMove.subscriptionStarts - beforeMove.subscriptionStarts !== 1 || Array.from(host._sb.keys()).join(",") !== "lab/page-tick") throw new Error(`focused subscription tick did not use exactly one nonfocused move before restoring page tick: ${JSON.stringify({ beforeMove, afterMove, subscriptions: Array.from(host._sb.keys()) })}`)
    #|const beforeControlledReset = host.__minimoonRendererStats()
    #|dispatch("dynamic/reset-controlled-input")
    #|const resetGroup = findFocusProbeGroup(host.data.lab.tree)
    #|const afterControlledReset = host.__minimoonRendererStats()
    #|if (resetGroup?.children[0] !== focusedProbe || resetGroup.children[0].props.value !== "Minimoon" || JSON.stringify(host.data).includes("Minimoon cursor probe")) throw new Error("controlled input reset replaced its keyed native identity or retained the stale value")
    #|if (afterControlledReset.renderCommits - beforeControlledReset.renderCommits !== 1 || afterControlledReset.setOps <= beforeControlledReset.setOps || afterControlledReset.moveOps !== beforeControlledReset.moveOps || afterControlledReset.spliceOps !== beforeControlledReset.spliceOps || afterControlledReset.replaceCommands !== beforeControlledReset.replaceCommands) throw new Error(`controlled input reset did not use only scalar patches: ${JSON.stringify({ beforeControlledReset, afterControlledReset })}`)
    #|dispatch("dynamic/name", { value: "Native structural probe" })
    #|const findNode = (node, predicate) => {
    #|  if (!node || typeof node !== "object") return null
    #|  if (predicate(node)) return node
    #|  for (const child of node.children || []) { const found = findNode(child, predicate); if (found) return found }
    #|  return null
    #|}
    #|const nativeInput = findNode(host.data.lab.tree, (node) => node.identity === "k:focus-probe")
    #|const nativePicker = findNode(host.data.lab.tree, (node) => node.kind === "picker" && node.props?.id === "control-picker")
    #|const nativeSwiper = findNode(host.data.lab.tree, (node) => node.kind === "swiper")
    #|const selectedSwiperItem = findNode(nativeSwiper, (node) => node.kind === "swiper-item" && node.props?.itemId === "first")
    #|if (!nativeInput || !nativePicker || !nativeSwiper || !selectedSwiperItem) throw new Error("controlled native reconciliation fixtures were not found")
    #|const beforeNativeReconcile = host.__minimoonRendererStats()
    #|dispatch("controls/reconcile-native")
    #|const reconciledInput = findNode(host.data.lab.tree, (node) => node.identity === "k:focus-probe")
    #|const reconciledPicker = findNode(host.data.lab.tree, (node) => node.kind === "picker" && node.props?.id === "control-picker")
    #|const reconciledSwiper = findNode(host.data.lab.tree, (node) => node.kind === "swiper")
    #|const reconciledSwiperItems = findNode(reconciledSwiper, (node) => node.kind === "fragment" && node.children?.some((child) => child.kind === "swiper-item"))
    #|const afterNativeReconcile = host.__minimoonRendererStats()
    #|if (reconciledInput !== nativeInput || reconciledPicker !== nativePicker || reconciledSwiper !== nativeSwiper || reconciledInput.props.value !== "Minimoon") throw new Error("controlled native reconciliation replaced a retained control or kept stale input state")
    #|if (JSON.stringify(reconciledPicker.props.range) !== JSON.stringify(["Skyline", "ArkUI", "MoonBit"]) || reconciledPicker.props.value !== 2 || !JSON.stringify(reconciledPicker).includes("picker: MoonBit")) throw new Error(`picker range/value reconciliation diverged: ${JSON.stringify(reconciledPicker)}`)
    #|if (!reconciledSwiperItems || reconciledSwiper.props.current !== 1 || reconciledSwiper.props.circular !== false || reconciledSwiperItems.children[1].identity !== selectedSwiperItem.identity || reconciledSwiperItems.children.map((node) => node.props.itemId).join(",") !== "second,first") throw new Error(`swiper children/current reconciliation diverged: ${JSON.stringify(reconciledSwiper)}`)
    #|if (afterNativeReconcile.renderCommits - beforeNativeReconcile.renderCommits !== 1 || afterNativeReconcile.setOps <= beforeNativeReconcile.setOps || afterNativeReconcile.moveOps <= beforeNativeReconcile.moveOps || afterNativeReconcile.replaceCommands !== beforeNativeReconcile.replaceCommands || afterNativeReconcile.patchFallbacks !== beforeNativeReconcile.patchFallbacks || afterNativeReconcile.rejectedPatches !== beforeNativeReconcile.rejectedPatches || afterNativeReconcile.schedulerFailures !== beforeNativeReconcile.schedulerFailures) throw new Error(`controlled native reconciliation did not remain one accepted structural patch: ${JSON.stringify({ beforeNativeReconcile, afterNativeReconcile })}`)
    #|dispatch("dynamic/select-c")
    #|if (!JSON.stringify(host.data).includes("selected:c")) throw new Error("keyed event identity failed")
    #|dispatch("dynamic/start-delay")
    #|if (!JSON.stringify(host.data).includes("delay probe:running:600ms")) throw new Error("delay probe did not enter its running state")
    #|await advance(599)
    #|if (!JSON.stringify(host.data).includes("delay probe:running:600ms")) throw new Error("delay probe completed before its 600ms boundary")
    #|await advance(1)
    #|if (!JSON.stringify(host.data).includes("delay probe:completed:600ms")) throw new Error(`delay probe did not complete at 600ms: ${JSON.stringify(host.data)}`)
    #|dispatch("dynamic/replace-root")
    #|if (host.data.lab.tree.kind !== "fragment") throw new Error("root replacement did not update")
    #|const stats = host.__minimoonRendererStats()
    #|if (stats.replaceCommands < 1 || stats.patchCommands < 5) throw new Error(`unexpected renderer stats: ${JSON.stringify(stats)}`)
    #|if (stats.patchFallbacks !== 0 || stats.rejectedPatches !== 0) throw new Error(`valid patches fell back: ${JSON.stringify(stats)}`)
    #|const beforeFallback = JSON.stringify(host.data.lab.tree)
    #|definition._ap.call(host, { type: "PatchViewTree", component_id: "lab", base_revision: host._rv, revision: host._rv + 1, ops: [{ op: "set", path: ["__proto__"], value: "bad" }] }, host._gn, () => {})
    #|const fallbackStats = host.__minimoonRendererStats()
    #|if (fallbackStats.patchFallbacks !== 1 || fallbackStats.rejectedPatches !== 1) throw new Error(`invalid patch did not fall back atomically: ${JSON.stringify(fallbackStats)}`)
    #|if (JSON.stringify(host.data.lab.tree) !== beforeFallback) throw new Error("invalid patch changed the rendered tree")
    #|const beforeAsync = host.__minimoonRendererStats()
    #|dispatch("dynamic/start-async")
    #|const startedAsync = JSON.stringify(host.data)
    #|if (!startedAsync.includes("perform probe:running:250ms") || !startedAsync.includes("attempt probe:running:400ms")) throw new Error("suspended probes did not enter their running states")
    #|await advance(249)
    #|if (!JSON.stringify(host.data).includes("perform probe:running:250ms")) throw new Error("perform probe completed before 250ms")
    #|await advance(1)
    #|if (!JSON.stringify(host.data).includes("perform probe:succeeded:250ms:ready") || !JSON.stringify(host.data).includes("attempt probe:running:400ms")) throw new Error(`perform probe did not complete alone at 250ms: ${JSON.stringify(host.data)}`)
    #|await advance(149)
    #|if (!JSON.stringify(host.data).includes("attempt probe:running:400ms")) throw new Error("attempt probe completed before 400ms")
    #|await advance(1)
    #|if (!JSON.stringify(host.data).includes("attempt probe:failed:400ms:planned")) throw new Error(`attempt probe did not complete at 400ms: ${JSON.stringify(host.data)}`)
    #|const afterAsync = host.__minimoonRendererStats()
    #|if (afterAsync.asyncDrains - beforeAsync.asyncDrains !== 2) throw new Error(`suspended probes did not use exactly two async drains: ${JSON.stringify({ beforeAsync, afterAsync })}`)
    #|const beforeMalformed = JSON.stringify(host.data.lab.tree)
    #|definition._hr.call(host, "{}", host._gn)
    #|if (JSON.stringify(host.data.lab.tree) !== beforeMalformed) throw new Error("malformed command batch changed the rendered tree")
    #|definition.onUnload.call(host)
    #|await flushMicrotasks()
    #|if (timers.size !== 0 || intervals.size !== 0) throw new Error(`dynamic host smoke leaked timers: ${JSON.stringify({ timers: timers.size, intervals: intervals.size })}`)
    #|host = null
    #|})().catch((error) => {
    #|  try { if (host && host.__mmInstanceId) definition.onUnload.call(host) } catch (_) {}
    #|  process.stderr.write(`${error && error.stack ? error.stack : error}\n`)
    #|  process.exitCode = 1
    #|})
    #|
  )
}

///|
pub fn navigation_host_smoke_source() -> String {
  (
    #|let definition
    #|globalThis.Page = (page) => { definition = page }
    #|globalThis.Component = () => { throw new Error("unvalidated Chaining page registration is forbidden") }
    #|globalThis.App = () => {}
    #|const calls = []
    #|const effectCalls = []
    #|let failingCapability = ""
    #|let requestMode = "success"
    #|let pendingRequest = null
    #|let requestAborts = 0
    #|const stableJson = (value) => value && typeof value === "object" ? (Array.isArray(value) ? value.map(stableJson) : Object.fromEntries(Object.keys(value).sort().map((key) => [key, stableJson(value[key])]))) : value
    #|const effectOptions = (method, options, expectedPayload) => {
    #|  if (!options || typeof options.success !== "function" || typeof options.fail !== "function") throw new Error(`${method} did not receive terminal callbacks`)
    #|  const { success, fail, ...payload } = options
    #|  if (JSON.stringify(stableJson(payload)) !== JSON.stringify(stableJson(expectedPayload))) throw new Error(`${method} payload mismatch: ${JSON.stringify(payload)}`)
    #|  effectCalls.push([method, payload])
    #|  return { success, fail }
    #|}
    #|globalThis.wx = {
    #|  navigateTo(options) { calls.push(["navigateTo", options]) },
    #|  redirectTo(options) { calls.push(["redirectTo", options]) },
    #|  navigateBack(options) { calls.push(["navigateBack", options]) },
    #|  login(options) { const terminal = effectOptions("login", options, {}); if (failingCapability === "login") terminal.fail({ errMsg: "wx.login:fail denied", errCode: 401 }); else terminal.success({ code: "host-login" }) },
    #|  getStorage(options) { const terminal = effectOptions("getStorage", options, { key: "minimoon-conformance-home" }); terminal.success({ data: "stored" }) },
    #|  setStorage(options) { const terminal = effectOptions("setStorage", options, { key: "minimoon-conformance-home", data: "0" }); terminal.success({}) },
    #|  request(options) {
    #|    const terminal = effectOptions("request", options, { url: "https://www.wanandroid.com/banner/json" })
    #|    if (requestMode === "deferred") { pendingRequest = terminal; return { abort() { requestAborts += 1 } } }
    #|    terminal.success({ statusCode: 200, data: { ok: true }, header: { "content-type": "application/json" }, cookies: ["session=host"] })
    #|    return { abort() { requestAborts += 1 } }
    #|  },
    #|  showToast(options) { const terminal = effectOptions("showToast", options, { title: "Count: 0" }); terminal.success({}) },
    #|  getLocation(options) { const terminal = effectOptions("getLocation", options, {}); terminal.success({ latitude: 31.2, longitude: 121.5, accuracy: 4.5 }) },
    #|  chooseMedia(options) { const terminal = effectOptions("chooseMedia", options, {}); terminal.success({ type: "image", tempFiles: [{ tempFilePath: "/tmp/minimoon-host.jpg", size: 123, width: 20, height: 10 }] }) },
    #|}
    #|const pageStack = []
    #|globalThis.getCurrentPages = () => pageStack
    #|const load = (file) => { definition = undefined; require(file); if (!definition) throw new Error(`Page was not registered: ${file}`); return definition }
    #|const showcaseDefinition = load(process.argv[2])
    #|const homeDefinition = load(process.argv[3])
    #|const detailsDefinition = load(process.argv[4])
    #|const labDefinition = load(process.argv[5])
    #|const resolve = (root, path) => { let value = root; for (const token of path) value = value[token]; return value }
    #|const assign = (root, path, value) => { const parent = resolve(root, path.slice(0, -1)); parent[path[path.length - 1]] = value }
    #|const makeHost = (page) => {
    #|  const pending = []
    #|  return {
    #|    ...page,
    #|    data: structuredClone(page.data),
    #|    setData(patch, callback) {
    #|      for (const [path, value] of Object.entries(patch)) {
    #|        const tokens = path.replace(/\[(\d+)\]/g, ".$1").split(".").map((token) => /^\d+$/.test(token) ? Number(token) : token)
    #|        assign(this.data, tokens, value)
    #|      }
    #|      if (callback) callback()
    #|    },
    #|    replaceDataOnPath(path, value) { pending.push(["set", path, value]) },
    #|    spliceArrayDataOnPath(path, index, del, items) { pending.push(["splice", path, index, del, items]) },
    #|    groupUpdates(callback) {
    #|      callback()
    #|      for (const op of pending.splice(0)) {
    #|        if (op[0] === "set") assign(this.data, op[1], op[2])
    #|        else resolve(this.data, op[1]).splice(op[2], op[3], ...op[4])
    #|      }
    #|    },
    #|  }
    #|}
    #|const start = (page, options = {}) => {
    #|  const host = makeHost(page)
    #|  page.onLoad.call(host, options)
    #|  page.onReady.call(host)
    #|  page.onShow.call(host)
    #|  pageStack.push(host)
    #|  return host
    #|}
    #|const dispatch = (page, host, key, detail = {}) => {
    #|  const input = key.endsWith("/name")
    #|  const handler = input ? page.__mmDispatchInput : page.__mmDispatchTap
    #|  const field = input ? "minimoonInput" : "minimoonTap"
    #|  handler.call(host, { currentTarget: { dataset: { [field]: key } }, target: { dataset: {} }, detail })
    #|}
    #|const assertLastCall = (method, expected) => {
    #|  const call = calls[calls.length - 1]
    #|  if (!call || call[0] !== method || JSON.stringify(call[1]) !== JSON.stringify(expected)) throw new Error(`unexpected navigation call: ${JSON.stringify(call)}`)
    #|}
    #|const showcase = start(showcaseDefinition)
    #|dispatch(showcaseDefinition, showcase, "showcase/increment")
    #|if (!JSON.stringify(showcase.data).includes("state updates: 1")) throw new Error("showcase did not update state")
    #|dispatch(showcaseDefinition, showcase, "showcase/open-console")
    #|assertLastCall("navigateTo", { url: "/pages/home/home?name=Studio" })
    #|dispatch(showcaseDefinition, showcase, "showcase/open-lab")
    #|assertLastCall("navigateTo", { url: "/pages/lab/lab?instance=showcase" })
    #|dispatch(showcaseDefinition, showcase, "showcase/open-details")
    #|assertLastCall("navigateTo", { url: "/pages/details/details?from=showcase" })
    #|showcaseDefinition.onHide.call(showcase)
    #|const home = start(homeDefinition, { name: "Host" })
    #|const homeInstance = home.__mmInstanceId
    #|dispatch(homeDefinition, home, "home/inc")
    #|if (!JSON.stringify(home.data).includes('"text":"1"')) throw new Error("home did not increment before navigation")
    #|dispatch(homeDefinition, home, "home/open-details")
    #|assertLastCall("navigateTo", { url: "/pages/details/details?from=home" })
    #|homeDefinition.onHide.call(home)
    #|const details = start(detailsDefinition, { from: "home" })
    #|dispatch(detailsDefinition, details, "Back")
    #|assertLastCall("navigateBack", { delta: 1 })
    #|detailsDefinition.onUnload.call(details)
    #|pageStack.pop()
    #|homeDefinition.onShow.call(home)
    #|if (home.__mmInstanceId !== homeInstance || !JSON.stringify(home.data).includes('"text":"1"')) throw new Error("navigateBack did not preserve the home instance")
    #|pageStack.length = 0
    #|const directDetails = start(detailsDefinition)
    #|dispatch(detailsDefinition, directDetails, "Back")
    #|assertLastCall("redirectTo", { url: "/pages/showcase/showcase" })
    #|const beforeInvalid = calls.length
    #|const errors = []
    #|const originalError = console.error
    #|console.error = (...args) => errors.push(args.join(" "))
    #|detailsDefinition._ci.call(directDetails, '[{"type":"NavigateBack","delta":0}]')
    #|showcaseDefinition._ci.call(showcase, '[{"type":"NavigateBack","delta":1}]')
    #|console.error = originalError
    #|if (calls.length !== beforeInvalid || !errors.some((value) => value.includes("invalid NavigateBack command")) || !errors.some((value) => value.includes("undeclared capability: wx.navigateBack"))) throw new Error(`NavigateBack validation failed: ${JSON.stringify(errors)}`)
    #|pageStack.length = 0
    #|dispatch(homeDefinition, home, "home/open-lab")
    #|assertLastCall("navigateTo", { url: "/pages/lab/lab" })
    #|pageStack.length = 0
    #|const firstLab = start(labDefinition, { instance: "first" })
    #|const secondLab = start(labDefinition, { instance: "second" })
    #|dispatch(labDefinition, firstLab, "dynamic/increment")
    #|const firstState = JSON.stringify(firstLab.data)
    #|const secondState = JSON.stringify(secondLab.data)
    #|if (!firstState.includes("count:1") || secondState.includes("count:1")) throw new Error("same-route Lab instances shared state")
    #|const secondInstance = secondLab.__mmInstanceId
    #|labDefinition.onUnload.call(firstLab)
    #|if (secondLab.__mmInstanceId !== secondInstance) throw new Error("unloading one Lab instance disposed another")
    #|labDefinition.onUnload.call(secondLab)
    #|pageStack.length = 0
    #|const capabilityHome = start(homeDefinition, { name: "Capabilities" })
    #|dispatch(homeDefinition, capabilityHome, "home/login")
    #|if (!JSON.stringify(capabilityHome.data).includes("login: success") || !JSON.stringify(capabilityHome.data).includes("code: host-login")) throw new Error("wx.login success did not resolve into Home state")
    #|dispatch(homeDefinition, capabilityHome, "home/load-storage")
    #|if (!JSON.stringify(capabilityHome.data).includes("storage: loaded") || !JSON.stringify(capabilityHome.data).includes("value: stored")) throw new Error("wx.getStorage success did not resolve into Home state")
    #|dispatch(homeDefinition, capabilityHome, "home/save-storage")
    #|if (!JSON.stringify(capabilityHome.data).includes("storage: saved")) throw new Error("wx.setStorage success did not resolve into Home state")
    #|dispatch(homeDefinition, capabilityHome, "home/request")
    #|if (!JSON.stringify(capabilityHome.data).includes("request: loaded") || !JSON.stringify(capabilityHome.data).includes('\\"ok\\":true')) throw new Error("wx.request success did not resolve into Home state")
    #|dispatch(homeDefinition, capabilityHome, "home/toast")
    #|if (!JSON.stringify(capabilityHome.data).includes("toast: shown")) throw new Error("wx.showToast success did not resolve into Home state")
    #|dispatch(homeDefinition, capabilityHome, "home/location")
    #|if (!JSON.stringify(capabilityHome.data).includes("31.2,121.5")) throw new Error("wx.getLocation success did not resolve into Home state")
    #|dispatch(homeDefinition, capabilityHome, "home/media")
    #|if (!JSON.stringify(capabilityHome.data).includes("/tmp/minimoon-host.jpg")) throw new Error("wx.chooseMedia success did not resolve into Home state")
    #|if (capabilityHome._ef.size !== 0 || effectCalls.slice(0, 7).map((entry) => entry[0]).join(",") !== "login,getStorage,setStorage,request,showToast,getLocation,chooseMedia") throw new Error(`capability success completion leaked effects or changed order: ${JSON.stringify(effectCalls)}`)
    #|failingCapability = "login"
    #|dispatch(homeDefinition, capabilityHome, "home/login")
    #|failingCapability = ""
    #|if (!JSON.stringify(capabilityHome.data).includes("login: failed") || !JSON.stringify(capabilityHome.data).includes("wx.login:fail denied") || capabilityHome._ef.size !== 0) throw new Error("wx.login failure did not resolve exactly once")
    #|const getLocation = wx.getLocation
    #|delete wx.getLocation
    #|dispatch(homeDefinition, capabilityHome, "home/location")
    #|wx.getLocation = getLocation
    #|if (!JSON.stringify(capabilityHome.data).includes("wx.getLocation unavailable") || capabilityHome._ef.size !== 0) throw new Error("unavailable wx.getLocation did not resolve exactly once")
    #|requestMode = "deferred"
    #|dispatch(homeDefinition, capabilityHome, "home/request")
    #|if (!pendingRequest || capabilityHome._ef.size !== 1) throw new Error("deferred wx.request was not tracked as one pending effect")
    #|const beforeLateRequest = JSON.stringify(capabilityHome.data)
    #|homeDefinition.onUnload.call(capabilityHome)
    #|pageStack.pop()
    #|if (requestAborts !== 1 || capabilityHome._ef.size !== 0 || capabilityHome.__mmInstanceId !== null) throw new Error("pending wx.request was not aborted exactly once on unload")
    #|pendingRequest.success({ statusCode: 200, data: { late: true } })
    #|if (requestAborts !== 1 || JSON.stringify(capabilityHome.data) !== beforeLateRequest || capabilityHome._ef.size !== 0) throw new Error("late wx.request success crossed the disposed page boundary")
    #|
  )
}

///|
pub fn bridge_benchmark_source() -> String {
  (
    #|const fs = require("node:fs")
    #|const os = require("node:os")
    #|const path = require("node:path")
    #|const [pageFile, fingerprint] = process.argv.slice(2)
    #|if (!pageFile || !fingerprint) throw new Error("usage: bridge-benchmark <page-file> <fingerprint>")
    #|let definition = null
    #|globalThis.Page = (value) => { definition = value }
    #|globalThis.App = () => {}
    #|globalThis.Component = () => { throw new Error("unexpected Component registration") }
    #|globalThis.wx = {}
    #|require(path.resolve(pageFile))
    #|if (!definition || typeof definition._ap !== "function") throw new Error("generated page bridge was not registered")
    #|
    #|const node = (identity, text, children = []) => ({ kind: children.length ? "fragment" : "text", identity, text, props: {}, events: {}, children })
    #|const tree = (count) => node("root", "", Array.from({ length: count }, (_, index) => node(`k:item-${index}`, `value-${index}`)))
    #|const resolve = (root, tokens) => { let value = root; for (const token of tokens) value = value[token]; return value }
    #|const stats = () => ({ patchCommands: 0, replaceCommands: 0, patchOps: 0, setOps: 0, spliceOps: 0, moveOps: 0, hostWriteOps: 0, groupUpdateCalls: 0, setDataCalls: 0, renderCommits: 0, patchFallbacks: 0, rejectedPatches: 0, subscriptionStarts: 0, subscriptionStops: 0, effectCancellations: 0, asyncDrains: 0, shadowCopies: 0 })
    #|const hostFor = (count) => {
    #|  const initial = tree(count)
    #|  return Object.assign({}, definition, {
    #|    data: { lab: { tree: structuredClone(initial), commit: 0 } },
    #|    _rv: 0,
    #|    _sh: structuredClone(initial),
    #|    _st: stats(),
    #|    __mmInstanceId: "benchmark",
    #|    _gn: 1,
    #|    _cl: false,
    #|    _ra: 0,
    #|    _ct: 0,
    #|    _at: null,
    #|    _pr: null,
    #|    groupUpdates(callback) { callback() },
    #|    replaceDataOnPath(tokens, value) { const parent = resolve(this.data, tokens.slice(0, -1)); parent[tokens.at(-1)] = value },
    #|    spliceArrayDataOnPath(tokens, index, remove, items) { resolve(this.data, tokens).splice(index, remove, ...items) },
    #|    setData(patch, callback) { for (const [key, value] of Object.entries(patch)) { if (key === "lab.tree") this.data.lab.tree = value; else if (key === "lab.commit") this.data.lab.commit = value; else { const tokens = key.replace(/\[(\d+)\]/g, ".$1").split(".").map((token) => /^\d+$/.test(token) ? Number(token) : token); const parent = resolve(this.data, tokens.slice(0, -1)); parent[tokens.at(-1)] = value } } if (callback) callback() },
    #|  })
    #|}
    #|const medianNs = (operation, iterations, samples = 25) => {
    #|  for (let index = 0; index < Math.min(iterations, 100); index += 1) operation()
    #|  const values = []
    #|  for (let sample = 0; sample < samples; sample += 1) {
    #|    const start = process.hrtime.bigint()
    #|    for (let index = 0; index < iterations; index += 1) operation()
    #|    values.push(Number(process.hrtime.bigint() - start) / iterations)
    #|  }
    #|  values.sort((left, right) => left - right)
    #|  return values[Math.floor(values.length / 2)]
    #|}
    #|const results = []
    #|for (const count of [100, 500, 2000]) {
    #|  const host = hostFor(count)
    #|  const target = Math.floor(count / 2)
    #|  let value = 0
    #|  const iterations = count === 2000 ? 100 : count === 500 ? 400 : 1000
    #|  const patchNs = medianNs(() => {
    #|    value += 1
    #|    definition._ap.call(host, { type: "PatchViewTree", component_id: "lab", base_revision: host._rv, revision: host._rv + 1, ops: [{ op: "set", path: ["children", target, "text"], value: String(value) }] }, 1, () => {})
    #|  }, iterations)
    #|  let reference = tree(count)
    #|  const cloneNs = medianNs(() => {
    #|    const candidate = JSON.parse(JSON.stringify(reference))
    #|    candidate.children[target].text = String(value += 1)
    #|    reference = candidate
    #|  }, iterations)
    #|  if (host._st.patchFallbacks !== 0 || host._st.rejectedPatches !== 0) throw new Error(`valid ${count}-node patches unexpectedly fell back`)
    #|  if (host._st.shadowCopies !== iterations * 25 * 3 + Math.min(iterations, 100) * 3) throw new Error(`scalar patch copied more than its three-container path: ${host._st.shadowCopies}`)
    #|  results.push({ nodes: count, iterations, samples: 25, patchMedianNs: patchNs, cloneReferenceMedianNs: cloneNs, speedup: cloneNs / patchNs, shadowCopiesPerPatch: 3 })
    #|}
    #|const report = {
    #|  schemaVersion: 1,
    #|  scenario: "generated-host-small-patch",
    #|  target: "bun-js-release-artifact",
    #|  toolchain: { bun: Bun.version, node: process.version, platform: process.platform, arch: process.arch },
    #|  fixture: "miniapp_conformance_app",
    #|  artifactFingerprint: fingerprint,
    #|  sampleMethod: "median of 25 samples after warmup; per-sample iterations are reported",
    #|  results,
    #|}
    #|process.stdout.write(`${JSON.stringify(report, null, 2)}\n`)
  )
}
