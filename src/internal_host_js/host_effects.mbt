///|
fn host_effect_invoker() -> String {
  (
    #|function invokeMinimoonEffect(command, minimoonCapabilities) {
    #|    const generation = this._gn
    #|    const instanceId = this.__mmInstanceId
    #|    const finish = (phase, payload, measureRevision) => { if (generation !== this._gn || instanceId !== this.__mmInstanceId || !instanceId || this._cl || !this._ef.has(command.request_id)) return; this._ef.delete(command.request_id); this._en({ kind: "effect", requestId: command.request_id, phase, payload: payload || {}, measureRevision }) }
    #|    this._ef.set(command.request_id, () => {})
    #|    if (command.capability === "minimoon.timeout") {
    #|      const timeoutPayload = command.payload
    #|      if (!timeoutPayload || typeof timeoutPayload !== "object" || Array.isArray(timeoutPayload) || !exactKeys(timeoutPayload, ["ms"]) || !Number.isInteger(timeoutPayload.ms) || timeoutPayload.ms < 0) { finish("failure", { error: "invalid timeout payload" }); return }
    #|      const handle = setTimeout(() => finish("success", { value: "" }), timeoutPayload.ms); this._ef.set(command.request_id, () => clearTimeout(handle)); return
    #|    }
    #|    if (!minimoonCapabilities.has(command.capability)) { finish("failure", { error: `undeclared capability: ${command.capability}` }); return }
    #|    if (command.capability === "minimoon.measureNodes") {
    #|      const payload = command.payload
    #|      if (!validMeasurementPayload(payload)) { finish("invalid_payload", { error: "invalid measurement IDs" }); return }
    #|      const revision = this._rv
    #|      if (payload.ids.length === 0) { finish("success", { nodes: [] }, revision); return }
    #|      if (typeof this.createSelectorQuery !== "function") { finish("unavailable", { error: "page selector query unavailable" }); return }
    #|      try {
    #|        const query = this.createSelectorQuery()
    #|        for (const id of payload.ids) query.select(`#${id}`).boundingClientRect()
    #|        query.exec(results => {
    #|          if (revision !== this._rv) { finish("failure", { error: "measurement superseded by a newer render" }); return }
    #|          const result = measurementNodes(results, payload.ids)
    #|          if (result.error) { finish("invalid_payload", result); return }
    #|          finish("success", result, revision)
    #|        })
    #|      } catch (error) { finish("failure", { error: String(error.message || error) }) }
    #|      return
    #|    }
    #|    const method = command.capability.startsWith("wx.") ? command.capability.slice(3) : ""
    #|    if (!method || typeof wx === "undefined" || typeof wx[method] !== "function") { finish("unavailable", { error: `${command.capability} unavailable` }); return }
    #|    const options = { ...(command.payload || {}) }
    #|    if (method === "request" && !validRequestPayload(options)) { finish("invalid_payload", { error: "invalid request payload" }); return }
    #|    const fail = (error) => { error = error || {}; const message = String(error.errMsg || error.message || `${command.capability} failed`); finish("failure", { error: message, errCode: error.errCode == null ? null : error.errCode, errMsg: String(error.errMsg || error.message || "") }) }
    #|    let task
    #|    try { task = wx[method]({ ...options, success: (result) => finish("success", this._ev(result)), fail }) }
    #|    catch (error) { fail(error); return }
    #|    if (task && typeof task.abort === "function" && this._ef.has(command.request_id)) this._ef.set(command.request_id, () => task.abort())
    #|}
  )
}
