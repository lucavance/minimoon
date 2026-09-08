///|
pub fn application_host_bridge() -> String {
  (
    #|const { exactKeys } = require("./minimoon.protocol.js")
    #|const { invokeMinimoonEffect, disposeMinimoonApplicationPages } = require("./minimoon.host.js")
    #|function registerMinimoonApp(runtime) {
    #|  if (runtime.minimoon_runtime_version() !== __MINIMOON_RUNTIME_API_VERSION__ || runtime.minimoon_runtime_state_abi_version() !== __MINIMOON_RUNTIME_API_VERSION__) throw new Error("application runtime ABI mismatch")
    #|  const capabilities = new Set(JSON.parse(runtime.minimoon_application_capabilities()))
    #|  const allowed = new Set(["wx.request", "wx.login", "wx.getStorage", "wx.setStorage"])
    #|  for (const capability of capabilities) if (!allowed.has(capability)) throw new Error("unsupported application capability")
    #|  let scheduled = false, busy = false, started = false
    #|  const queue = []
    #|  const actor = {
    #|    _gn: 1, _cl: false, __mmInstanceId: "$app", _ef: new Map(), _sb: new Map(),
    #|    _ev(result) { return result == null ? null : result },
    #|    _en(entry) { if (!this._cl) { queue.push(entry); schedule() } }
    #|  }
    #|  function clear() {
    #|    actor._cl = true; actor._gn += 1; actor.__mmInstanceId = null; queue.length = 0
    #|    for (const timer of actor._sb.values()) clearInterval(timer)
    #|    actor._sb.clear()
    #|    const cancels = Array.from(actor._ef.values()); actor._ef.clear()
    #|    for (const cancel of cancels) { try { cancel() } catch (_) {} }
    #|  }
    #|  function dispose() {
    #|    if (actor._cl) return
    #|    clear()
    #|    disposeMinimoonApplicationPages(runtime)
    #|    runtime.minimoon_application_dispose()
    #|  }
    #|  function consume(raw) {
    #|    const commands = JSON.parse(raw)
    #|    if (!Array.isArray(commands)) throw new Error("invalid application command batch")
    #|    for (const command of commands) {
    #|      if (command.type === "RuntimeError") { console.error(`[minimoon:${command.code}] ${command.message}`); continue }
    #|      if (command.type === "DisposeContext" || command.type === "MountContext") continue
    #|      if (command.component_id !== "$app") throw new Error("invalid application command owner")
    #|      if (command.type === "InvokeCapability") {
    #|        if (!exactKeys(command, ["type", "component_id", "request_id", "capability", "payload"]) || typeof command.request_id !== "string" || (command.capability !== "minimoon.timeout" && !allowed.has(command.capability))) throw new Error("invalid application effect")
    #|        invokeMinimoonEffect.call(actor, command, capabilities)
    #|      } else if (command.type === "StartSubscription") {
    #|        if (!exactKeys(command, ["type", "component_id", "key", "interval_ms"]) || typeof command.key !== "string" || !command.key || !Number.isInteger(command.interval_ms) || command.interval_ms < 1) throw new Error("invalid application subscription")
    #|        if (actor._sb.has(command.key)) clearInterval(actor._sb.get(command.key))
    #|        const timer = setInterval(() => { if (actor._sb.get(command.key) === timer) actor._en({ kind: "subscription", key: command.key }) }, command.interval_ms)
    #|        actor._sb.set(command.key, timer)
    #|      } else if (command.type === "StopSubscription") {
    #|        if (!exactKeys(command, ["type", "component_id", "key"]) || typeof command.key !== "string") throw new Error("invalid application subscription stop")
    #|        if (actor._sb.has(command.key)) clearInterval(actor._sb.get(command.key))
    #|        actor._sb.delete(command.key)
    #|      } else if (command.type === "CancelEffect") {
    #|        if (!exactKeys(command, ["type", "component_id", "request_id"]) || typeof command.request_id !== "string") throw new Error("invalid application cancellation")
    #|        const cancel = actor._ef.get(command.request_id); actor._ef.delete(command.request_id)
    #|        if (cancel) cancel()
    #|      } else throw new Error("unsupported application command")
    #|    }
    #|  }
    #|  function drain() {
    #|    scheduled = false
    #|    if (actor._cl || busy || !started) return
    #|    busy = true
    #|    try {
    #|      for (let index = 0; index < 2048 && queue.length; index++) {
    #|        const entry = queue.shift()
    #|        if (entry.kind === "effect") consume(runtime.minimoon_application_resolve_effect(entry.requestId, entry.phase, JSON.stringify(entry.payload)))
    #|        else if (entry.kind === "subscription") consume(runtime.minimoon_application_subscription(entry.key))
    #|        else consume(runtime.minimoon_application_lifecycle(entry.hook, JSON.stringify(entry.payload || {})))
    #|      }
    #|      consume(runtime.minimoon_application_flush())
    #|    } catch (error) { dispose(); console.error("[minimoon] application scheduler failed closed", error) }
    #|    finally { busy = false }
    #|    if (queue.length) schedule()
    #|  }
    #|  function schedule() { if (!scheduled && !actor._cl) { scheduled = true; Promise.resolve().then(drain) } }
    #|  App({
    #|    onLaunch(options) {
    #|      if (started || actor._cl) return
    #|      started = true
    #|      const previous = globalThis.__minimoonAppWakeV12
    #|      globalThis.__minimoonAppWakeV12 = schedule
    #|      try { consume(runtime.minimoon_application_start(JSON.stringify(options || {}))) }
    #|      catch (error) { dispose(); throw error }
    #|      finally { if (previous === undefined) delete globalThis.__minimoonAppWakeV12; else globalThis.__minimoonAppWakeV12 = previous }
    #|    },
    #|    onShow(options) { actor._en({ kind: "lifecycle", hook: "onShow", payload: options || {} }) },
    #|    onHide() { actor._en({ kind: "lifecycle", hook: "onHide", payload: {} }) }
    #|  })
    #|  return { dispose }
    #|}
    #|module.exports = { registerMinimoonApp }
  ).replace_all(
    old="__MINIMOON_RUNTIME_API_VERSION__",
    new=@versions.runtime_api_version().to_string(),
  )
}
