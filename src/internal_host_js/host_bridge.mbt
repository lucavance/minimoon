///|
pub fn shared_host_bridge(
  application? : Bool = false,
  tab_routes? : Array[String] = [],
) -> String {
  let source =
    #|const { exactKeys, validateNode, applyPatch, createRendererStats, eventDispatchers, eventPayload, touchIdentity, validMeasurementPayload, validRequestPayload, measurementNodes } = require("./minimoon.protocol.js")
    #|/* application */const applicationPages = new Map()
    #|const minimoonTabRoutes = new Set(__MM_TAB_ROUTES__)
    #|function registerMinimoonPage(runtime, minimoonPageId, minimoonInitialTree, minimoonCapabilityList) {
    #|if (runtime.minimoon_runtime_version() !== __MM_RUNTIME_VERSION__ || runtime.minimoon_runtime_state_abi_version() !== __MM_RUNTIME_VERSION__) throw new Error("Minimoon runtime ABI v__MM_RUNTIME_VERSION__ required")
    #|const minimoonCapabilities = new Set(minimoonCapabilityList)
    #|
    #|Page({
    #|  ...eventDispatchers,
    #|  data: { [minimoonPageId]: { tree: minimoonInitialTree, commit: 0 } },
    #|  onLoad(options) {
    #|    if (this.__mmInstanceId) { console.error("[minimoon] duplicate_page_load"); return }
    #|    this._st = createRendererStats()
    #|    this._rv = 0
    #|    this._sh = JSON.parse(JSON.stringify(this.data[minimoonPageId].tree))
    #|    this._sb = new Map()
    #|    this._ef = new Map()
    #|    this._q = []
    #|    this._bz = false
    #|    this._cl = false
    #|    this._dw = null
    #|    this._gn = (this._gn || 0) + 1
    #|    this._ra = 0
    #|    this._ct = 0
    #|    this._at = null
    #|    this._pr = null
    #|    this._cr = null
    #|    this._ly = readMinimoonLayout(null)
    #|    this._shown = false
    #|    this.__mmInstanceId = null
    #|    const hadRuntimeWake = Object.prototype.hasOwnProperty.call(globalThis, "__minimoonRuntimeWakeV12")
    #|    const previousRuntimeWake = globalThis.__minimoonRuntimeWakeV12
    #|/* application */    const previousSharedWake = globalThis.__minimoonSharedWakeV12
    #|/* application */    let sharedScheduled = false
    #|    const wakeGeneration = this._gn
    #|    globalThis.__minimoonRuntimeWakeV12 = (through) => this._aw(wakeGeneration, through)
    #|/* application */    globalThis.__minimoonSharedWakeV12 = () => { if (sharedScheduled) return; sharedScheduled = true; Promise.resolve().then(() => { sharedScheduled = false; if (this._gn === wakeGeneration) this._en({ kind: "shared" }) }) }
    #|    try {
    #|      const created = JSON.parse(runtime.minimoon_runtime_create_app(minimoonPageId, JSON.stringify(options || {}), JSON.stringify(this._ly)))
    #|      if (!created || created.ok !== true || typeof created.id !== "string" || !created.id) {
    #|        this._fc("page_input_decode_failed", created && created.error)
    #|        return
    #|      }
    #|      this.__mmInstanceId = created.id
    #|    }
    #|    finally { if (hadRuntimeWake) globalThis.__minimoonRuntimeWakeV12 = previousRuntimeWake; else delete globalThis.__minimoonRuntimeWakeV12; __MM_APP_RESTORE__ }
    #|/* application */    if (runtime.minimoon_application_start) applicationPages.set(this, runtime)
    #|    this._en({ kind: "lifecycle", hook: "onLoad", payload: options || {} })
    #|  },
    #|  onReady() { this._en({ kind: "mount" }) },
    #|  onShow() {
    #|    if (this._cl || !this.__mmInstanceId) return
    #|    if (this._shown) this._ly = readMinimoonLayout(this._ly)
    #|    this._shown = true
    #|    this._en({ kind: "lifecycle", hook: "onShow", layout: this._ly })
    #|  },
    #|  onHide() { this._lc("onHide", {}) },
    #|  onResize() {
    #|    if (this._cl || !this.__mmInstanceId) return
    #|    this._ly = readMinimoonLayout(this._ly)
    #|    this._en({ kind: "layout", layout: this._ly })
    #|  },
    #|  onPullDownRefresh() { this._lc("onPullDownRefresh", {}) },
    #|  onReachBottom() { this._lc("onReachBottom", {}) },
    #|  onUnload() {
    #|/* application */    applicationPages.delete(this)
    #|    const instanceId = this.__mmInstanceId
    #|    this._cl = true
    #|    this._gn = (this._gn || 0) + 1
    #|    this._q = []
    #|    this._bz = false
    #|    this._dw = null
    #|    this._cr = null
    #|    this._pr = null
    #|    if (this._at != null) { clearTimeout(this._at); this._at = null }
    #|    if (instanceId) {
    #|      try { this._ci(runtime.minimoon_runtime_lifecycle(instanceId, "onUnload", "{}")) } catch (error) { console.error("[minimoon] unload lifecycle failed", error) }
    #|      try { this._ci(runtime.minimoon_runtime_dispose(instanceId)) } catch (error) { console.error("[minimoon] runtime dispose failed", error) }
    #|    }
    #|    this._clearTasks()
    #|    this.__mmInstanceId = null
    #|  },
    #|  _dk(event, field, type) {
    #|    event = event || {}
    #|    const currentTarget = event.currentTarget || {}
    #|    const key = (currentTarget.dataset || {})[field] || ""
    #|    if (key) this._ed(type, key, eventPayload(event, type))
    #|  },
    #|  _lc(hook, payload) { this._en({ kind: "lifecycle", hook, payload: payload || {} }) },
    #|  _ed(type, key, payload) {
    #|    if (this._cl || !this.__mmInstanceId) return
    #|    this._st.receivedUiEvents += 1
    #|    const tail = this._q.length ? this._q[this._q.length - 1] : null
    #|    if (tail && tail.kind === "dispatch") {
    #|      const last = tail.events.length ? tail.events[tail.events.length - 1] : null
    #|      if (type === "scroll" && last && last.type === "scroll" && last.key === key) { tail.events[tail.events.length - 1] = { type, key, payload }; this._st.coalescedEvents += 1; return }
    #|      if (last && last.type === type && last.key === key && (type === "changing" || (type === "touchmove" && touchIdentity(last.payload) === touchIdentity(payload)))) { tail.events[tail.events.length - 1] = { type, key, payload }; this._st.coalescedEvents += 1; return }
    #|      if (tail.events.length >= 2048) { this._fc("event batch exceeded the 2048 entry limit"); return }
    #|      tail.events.push({ type, key, payload })
    #|      this._ob(tail)
    #|      return
    #|    }
    #|    const entry = { kind: "dispatch", events: [{ type, key, payload }], warned: false }
    #|    this._q.push(entry)
    #|    this._mq()
    #|    this._ob(entry)
    #|    this._pu()
    #|  },
    #|  _ob(entry) {
    #|    if (entry.events.length > this._st.maxEventBatch) this._st.maxEventBatch = entry.events.length
    #|    if (entry.events.length >= 256 && !entry.warned) { entry.warned = true; this._st.schedulerWarnings += 1; console.warn(`[minimoon] queued UI event batch reached ${entry.events.length} entries`) }
    #|  },
    #|  _en(entry) {
    #|    if (this._cl || !this.__mmInstanceId) return
    #|    if (entry.kind === "layout" && this._q.length && this._q[this._q.length - 1].kind === "layout") { this._q[this._q.length - 1] = entry; return }
    #|/* application */    if (entry.kind === "shared" && this._q.length && this._q[this._q.length - 1].kind === "shared") return
    #|    this._q.push(entry)
    #|    this._mq()
    #|    this._pu()
    #|  },
    #|  _aw(generation, through) {
    #|    if (generation !== this._gn || this._cl || !this.__mmInstanceId || !Number.isInteger(through) || through < 0 || through > 2147483647) return
    #|    const pending = this._dw
    #|    if (pending && pending.generation === generation) { if (through > pending.through) pending.through = through; return }
    #|    const token = { generation, through }
    #|    this._dw = token
    #|    Promise.resolve().then(() => {
    #|      if (this._dw !== token) return
    #|      this._dw = null
    #|      if (generation !== this._gn || this._cl || !this.__mmInstanceId) return
    #|      const tail = this._q.length ? this._q[this._q.length - 1] : null
    #|      if (tail && tail.kind === "drain") { if (token.through > tail.through) tail.through = token.through; return }
    #|      this._en({ kind: "drain", through: token.through })
    #|    })
    #|  },
    #|  _mq() { if (this._q.length > this._st.maxQueueDepth) this._st.maxQueueDepth = this._q.length },
    #|  _pu() {
    #|    if (this._cl || this._bz || !this.__mmInstanceId) return
    #|    const entry = this._q.shift()
    #|    if (!entry) return
    #|    this._bz = true
    #|    this._cr = entry
    #|    const generation = this._gn
    #|    let raw
    #|    try {
    #|      if (entry.kind === "dispatch") { this._st.eventBatches += 1; raw = runtime.minimoon_runtime_dispatch_batch(this.__mmInstanceId, JSON.stringify(entry.events.map(event => ({ key: event.key, payload: event.payload })))) }
    #|      else if (entry.kind === "lifecycle") raw = entry.hook === "onShow" ? runtime.minimoon_runtime_lifecycle(this.__mmInstanceId, "$minimoon:layout-show", JSON.stringify(entry.layout)) : runtime.minimoon_runtime_lifecycle(this.__mmInstanceId, entry.hook, JSON.stringify(entry.payload || {}))
    #|      else if (entry.kind === "layout") raw = runtime.minimoon_runtime_update_layout(this.__mmInstanceId, JSON.stringify(entry.layout))
    #|      else if (entry.kind === "mount") raw = runtime.minimoon_runtime_mount(this.__mmInstanceId)
    #|/* application */      else if (entry.kind === "shared") raw = runtime.minimoon_runtime_lifecycle(this.__mmInstanceId, "$minimoon:shared", "{}")
    #|      else if (entry.kind === "subscription") raw = runtime.minimoon_runtime_subscription(this.__mmInstanceId, entry.key, "{}")
    #|      else if (entry.kind === "drain") { this._st.asyncDrains += 1; raw = runtime.minimoon_runtime_lifecycle(this.__mmInstanceId, "$minimoon:drain", JSON.stringify({ through: entry.through })) }
    #|      else if (entry.kind === "effect") { const stale = entry.measureRevision != null && entry.measureRevision !== this._rv; raw = runtime.minimoon_runtime_resolve_effect(this.__mmInstanceId, entry.requestId, stale ? "failure" : entry.phase, JSON.stringify(stale ? { error: "measurement superseded by a newer render" } : (entry.payload || {}))) }
    #|      else throw new Error(`unknown scheduler entry: ${entry.kind}`)
    #|    } catch (error) { this._fc("runtime entry failed", error); return }
    #|    this._hr(raw, generation)
    #|  },
    #|  _hr(raw, generation) {
    #|    const commands = this._pc(raw)
    #|    if (!commands) { this._fc("invalid runtime command batch"); return }
    #|    const renders = []
    #|    const rest = []
    #|    for (const command of commands) {
    #|      if (!command || typeof command !== "object" || Array.isArray(command)) { this._fc("runtime emitted a non-object command"); return }
    #|      if (command.type === "ReplaceViewTree" || command.type === "PatchViewTree") renders.push(command)
    #|      else rest.push(command)
    #|    }
    #|    if (renders.length > 1) { this._fc("runtime emitted more than one render command"); return }
    #|    const complete = () => {
    #|      if (generation !== this._gn || this._cl) return
    #|      for (const command of rest) this._ac(command)
    #|      this._bz = false
    #|      this._cr = null
    #|      this._pu()
    #|    }
    #|    if (renders.length === 0) complete()
    #|    else this._rr(renders[0], generation, complete)
    #|  },
    #|  _pc(raw) {
    #|    let commands
    #|    try { commands = typeof raw === "string" ? JSON.parse(raw || "[]") : (raw || []) } catch (error) { console.error("[minimoon] invalid runtime commands", error); return null }
    #|    return Array.isArray(commands) ? commands : null
    #|  },
    #|  _ci(raw) {
    #|    const commands = this._pc(raw)
    #|    if (!commands) return
    #|    for (const command of commands) if (command && command.type !== "ReplaceViewTree" && command.type !== "PatchViewTree") this._ac(command)
    #|  },
    #|  __minimoonRendererStats() { return { ...(this._st || {}) } },
    #|  _dp(path) {
    #|    let output = `${minimoonPageId}.tree`
    #|    for (const token of path) output += Number.isInteger(token) ? `[${token}]` : `.${token}`
    #|    return output
    #|  },
    #|  _sc() {
    #|    const snapshot = JSON.parse(runtime.minimoon_runtime_snapshot(this.__mmInstanceId))
    #|    if (!exactKeys(snapshot, ["revision", "tree"]) || !Number.isInteger(snapshot.revision) || snapshot.revision < this._rv || !validateNode(snapshot.tree)) throw new Error("invalid runtime snapshot")
    #|    return { revision: snapshot.revision, shadow: JSON.parse(JSON.stringify(snapshot.tree)), tree: snapshot.tree }
    #|  },
    #|  _sw(candidate, generation, done, retried, writer) {
    #|    if (generation !== this._gn || this._cl) return
    #|    const attempt = ++this._ra
    #|    const commit = ++this._ct
    #|    this._pr = { candidate, generation, done, retried, attempt, startedAt: Date.now() }
    #|    if (this._at != null) clearTimeout(this._at)
    #|    this._at = setTimeout(() => this._to(generation, attempt), 3000)
    #|    try { writer(commit, () => this._ar(generation, attempt)) }
    #|    catch (error) {
    #|      if (this._at != null) clearTimeout(this._at)
    #|      this._at = null
    #|      this._pr = null
    #|      if (retried) this._fc("snapshot render write failed", error)
    #|      else this._rt("render write failed", { candidate, generation, done, retried, attempt }, error)
    #|    }
    #|  },
    #|  _ar(generation, attempt) {
    #|    const pending = this._pr
    #|    if (!pending || pending.generation !== generation || pending.attempt !== attempt || generation !== this._gn || this._cl) return
    #|    if (this._at != null) clearTimeout(this._at)
    #|    this._at = null
    #|    this._pr = null
    #|    this._rv = pending.candidate.revision
    #|    this._sh = pending.candidate.shadow
    #|    this._st.renderCommits += 1
    #|    const elapsed = Math.max(0, Date.now() - pending.startedAt)
    #|    this._st.renderAckSamples += 1; this._st.renderAckTotalMs += elapsed; this._st.renderAckLastMs = elapsed
    #|    if (elapsed > this._st.renderAckMaxMs) this._st.renderAckMaxMs = elapsed
    #|    pending.done()
    #|  },
    #|  _to(generation, attempt) {
    #|    const pending = this._pr
    #|    if (!pending || pending.generation !== generation || pending.attempt !== attempt || generation !== this._gn || this._cl) return
    #|    this._at = null
    #|    this._pr = null
    #|    this._st.renderTimeouts += 1
    #|    if (pending.retried) this._fc("render acknowledgment timed out after snapshot retry")
    #|    else this._rt("render acknowledgment timed out", pending)
    #|  },
    #|  _rt(reason, pending, error) {
    #|    if (error) console.warn(`[minimoon] ${reason}`, error); else console.warn(`[minimoon] ${reason}`)
    #|    this._st.renderRetries += 1
    #|    let candidate
    #|    try { candidate = this._sc() } catch (snapshotError) { this._fc("snapshot retry could not obtain a valid runtime snapshot", snapshotError); return }
    #|    this._wf(candidate, pending.generation, pending.done, true)
    #|  },
    #|  _wf(candidate, generation, done, retried) {
    #|    this._sw(candidate, generation, done, retried, (commit, acknowledge) => {
    #|      this._st.setDataCalls += 1
    #|      this.setData({ [`${minimoonPageId}.tree`]: candidate.tree, [`${minimoonPageId}.commit`]: commit }, acknowledge)
    #|    })
    #|  },
    #|  _fb(reason, generation, done, rejected = true) {
    #|    this._st.patchFallbacks += 1
    #|    if (rejected) this._st.rejectedPatches += 1
    #|    let candidate
    #|    try { candidate = this._sc() } catch (error) { this._fc(`patch fallback failed: ${reason}`, error); return }
    #|    this._wf(candidate, generation, done, false)
    #|  },
    #|  _ap(command, generation, done) {
    #|    this._st.patchCommands += 1
    #|    this._st.patchOps += Array.isArray(command.ops) ? command.ops.length : 0
    #|    const checked = applyPatch(command, minimoonPageId, this._rv, this._sh)
    #|    if (!checked) { this._fb("invalid renderer protocol v__MM_RENDERER_VERSION__ patch", generation, done); return }
    #|    this._st.shadowCopies += checked.copies
    #|    const candidate = { revision: command.revision, shadow: checked.shadow, tree: checked.shadow }
    #|    if (checked.setOnly) {
    #|      this._sw(candidate, generation, done, false, (commit, acknowledge) => {
    #|        const data = { [`${minimoonPageId}.commit`]: commit }
    #|        for (const op of checked.writes) {
    #|          const path = this._dp(op.path), parent = path.slice(0, path.lastIndexOf("."))
    #|          // Coalesce whole-props and lowered leaf writes without overlapping setData paths.
    #|          if (Object.prototype.hasOwnProperty.call(data, parent)) data[parent] = { ...data[parent], [op.path[op.path.length - 1]]: op.value }
    #|          else { for (const key of Object.keys(data)) if (key.startsWith(path + ".")) delete data[key]; data[path] = op.value }
    #|        }
    #|        this._st.setOps += checked.writes.length
    #|        this._st.hostWriteOps += checked.writes.length
    #|        this._st.setDataCalls += 1
    #|        this.setData(data, acknowledge)
    #|      })
    #|      return
    #|    }
    #|    if (typeof this.groupUpdates !== "function" || typeof this.replaceDataOnPath !== "function" || typeof this.spliceArrayDataOnPath !== "function") { this._fb("glass-easel advanced updates unavailable", generation, done, false); return }
    #|    this._sw(candidate, generation, done, false, (commit, acknowledge) => {
    #|      this.groupUpdates(() => {
    #|        for (const op of checked.writes) {
    #|          const path = [minimoonPageId, "tree", ...op.path]
    #|          if (op.op === "set") { this.replaceDataOnPath(path, op.value); this._st.setOps += 1; this._st.hostWriteOps += 1 }
    #|          else if (op.op === "splice") { this.spliceArrayDataOnPath(path, op.index, op.delete_count, op.items); this._st.spliceOps += 1; this._st.hostWriteOps += 1 }
    #|          else { this.spliceArrayDataOnPath(path, op.from, 1, []); this.spliceArrayDataOnPath(path, op.to, 0, [op.item]); this._st.moveOps += 1; this._st.hostWriteOps += 2 }
    #|        }
    #|      })
    #|      this._st.groupUpdateCalls += 1
    #|      this._st.setDataCalls += 1
    #|      this.setData({ [`${minimoonPageId}.commit`]: commit }, acknowledge)
    #|    })
    #|  },
    #|  _rr(command, generation, done) {
    #|    if (command.type === "PatchViewTree") { this._ap(command, generation, done); return }
    #|    if (command.type === "ReplaceViewTree" && exactKeys(command, ["type", "component_id", "base_revision", "revision", "tree"]) && command.component_id === minimoonPageId && Number.isInteger(command.base_revision) && Number.isInteger(command.revision) && command.base_revision === this._rv && command.revision === command.base_revision + 1 && validateNode(command.tree)) {
    #|      this._st.replaceCommands += 1
    #|      this._wf({ revision: command.revision, shadow: JSON.parse(JSON.stringify(command.tree)), tree: command.tree }, generation, done, false)
    #|    } else this._fb("invalid renderer protocol v__MM_RENDERER_VERSION__ replacement", generation, done)
    #|  },
    #|  _ac(command) {
    #|    if (command.type === "MountContext" || command.type === "DisposeContext") return
    #|    if (command.type === "RuntimeError") { console.error(`[minimoon:${command.code}] ${command.message}`); return }
    #|    if (command.type === "InvokeCapability") { this._iv(command); return }
    #|    if (command.type === "NavigateTo") { this._nv("wx.navigateTo", { url: command.url }); return }
    #|    if (command.type === "RedirectTo") { this._nv("wx.redirectTo", { url: command.url }); return }
    #|    if (command.type === "SwitchTab") { if (!exactKeys(command, ["type", "url"])) { console.error("[minimoon] invalid SwitchTab command"); return }; this._nv("wx.switchTab", { url: command.url }); return }
    #|    if (command.type === "NavigateBack") {
    #|      if (!exactKeys(command, ["type", "delta"]) || !Number.isInteger(command.delta) || command.delta < 1) { console.error("[minimoon] invalid NavigateBack command"); return }
    #|      this._nv("wx.navigateBack", { delta: command.delta }); return
    #|    }
    #|    if (command.type === "NavigateBackOrRedirect") {
    #|      if (!exactKeys(command, ["type", "delta", "fallback"]) || !Number.isInteger(command.delta) || command.delta < 1 || typeof command.fallback !== "string" || !command.fallback) { console.error("[minimoon] invalid NavigateBackOrRedirect command"); return }
    #|      const pages = typeof getCurrentPages === "function" ? getCurrentPages() : []
    #|      if (pages.length > command.delta) this._nv("wx.navigateBack", { delta: command.delta }); else this._nv(minimoonTabRoutes.has(command.fallback.split("?")[0]) ? "wx.switchTab" : "wx.redirectTo", { url: command.fallback }); return
    #|    }
    #|    if (command.type === "StartSubscription") { this._ss(command); return }
    #|    if (command.type === "StopSubscription") { this._xs(command); return }
    #|    if (command.type === "CancelEffect") { this._ce(command); return }
    #|    console.error(`[minimoon] unknown runtime command: ${String(command.type || "")}`)
    #|  },
    #|  _ss(command) {
    #|    if (!exactKeys(command, ["type", "component_id", "key", "interval_ms"]) || command.component_id !== minimoonPageId || typeof command.key !== "string" || !command.key || !Number.isInteger(command.interval_ms) || command.interval_ms < 1) { console.error("[minimoon] invalid StartSubscription command"); return }
    #|    this._xs({ type: "StopSubscription", component_id: minimoonPageId, key: command.key }, false)
    #|    const generation = this._gn
    #|    const instanceId = this.__mmInstanceId
    #|    let handle
    #|    handle = setInterval(() => { if (generation === this._gn && instanceId === this.__mmInstanceId && instanceId && !this._cl && this._sb.get(command.key) === handle) this._en({ kind: "subscription", key: command.key }) }, command.interval_ms)
    #|    this._sb.set(command.key, handle); this._st.subscriptionStarts += 1
    #|  },
    #|  _xs(command, count = true) {
    #|    if (!exactKeys(command, ["type", "component_id", "key"]) || command.component_id !== minimoonPageId || typeof command.key !== "string") { console.error("[minimoon] invalid StopSubscription command"); return }
    #|    const handle = this._sb.get(command.key); if (handle != null) { clearInterval(handle); this._sb.delete(command.key); if (count) this._st.subscriptionStops += 1 }
    #|  },
    #|  _ce(command) {
    #|    if (!exactKeys(command, ["type", "component_id", "request_id"]) || command.component_id !== minimoonPageId || typeof command.request_id !== "string") { console.error("[minimoon] invalid CancelEffect command"); return }
    #|    const cancel = this._ef.get(command.request_id); if (cancel) { this._ef.delete(command.request_id); try { cancel() } catch (_) {}; this._st.effectCancellations += 1 }
    #|  },
    #|  _nv(capability, options) {
    #|    if (capability !== "wx.navigateBack") {
    #|      const url = options.url
    #|      if (typeof url !== "string" || !/^\/[a-zA-Z0-9_/-]+(?:\?[^#]*)?$/.test(url) || url.includes("//") || url.endsWith("/")) { console.error("[minimoon] invalid navigation route"); return }
    #|      const tab = minimoonTabRoutes.has(url.split("?")[0])
    #|      if (capability === "wx.switchTab" ? (!tab || url.includes("?")) : tab) { console.error("[minimoon] navigation route kind mismatch"); return }
    #|    }
    #|    if (!minimoonCapabilities.has(capability)) { console.error(`[minimoon] undeclared capability: ${capability}`); return }
    #|    const method = capability.slice(3)
    #|    if (typeof wx === "undefined" || typeof wx[method] !== "function") { console.error(`[minimoon] unavailable capability: ${capability}`); return }
    #|    wx[method](options)
    #|  },
    #|  _iv(command) { invokeMinimoonEffect.call(this, command, minimoonCapabilities) },
    #|  _ev(result) { return result == null ? null : result },
    #|  _clearTasks() {
    #|    if (this._sb) { for (const handle of this._sb.values()) clearInterval(handle); this._sb.clear() }
    #|    if (this._ef) { for (const cancel of this._ef.values()) { try { cancel() } catch (_) {} }; this._ef.clear() }
    #|  },
    #|  _fc(reason, error) {
    #|    if (this._cl) return
    #|    this._cl = true
    #|    this._st.schedulerFailures += 1
    #|    this._q = []
    #|    this._bz = false
    #|    this._dw = null
    #|    this._cr = null
    #|    this._pr = null
    #|    if (this._at != null) { clearTimeout(this._at); this._at = null }
    #|    this._clearTasks()
    #|    if (error) console.error(`[minimoon] scheduler failed closed: ${reason}`, error); else console.error(`[minimoon] scheduler failed closed: ${reason}`)
    #|  },
    #|})
    #|}
    #|
    #|/* application */function disposeMinimoonApplicationPages(runtime) { for (const [page, owner] of Array.from(applicationPages)) if (owner === runtime) page.onUnload() }
    #|module.exports = { registerMinimoonPage __MM_APP_EXPORTS__ }
  let source = source
    .split("\n")
    .filter(line => application || !line.contains("/* application */"))
    .map(line => line.to_owned())
    .collect()
    .join("\n")
    .replace_all(old="/* application */", new="")
    .replace_all(
      old="__MM_APP_RESTORE__",
      new=if application {
        "if (previousSharedWake === undefined) delete globalThis.__minimoonSharedWakeV12; else globalThis.__minimoonSharedWakeV12 = previousSharedWake"
      } else {
        ""
      },
    )
    .replace_all(
      old="__MM_APP_EXPORTS__",
      new=if application {
        ", invokeMinimoonEffect, disposeMinimoonApplicationPages"
      } else {
        ""
      },
    )
  (source + "\n" + host_effect_invoker() + "\n" + host_layout_reader())
  .replace_all(
    old="__MM_TAB_ROUTES__",
    new=Json::array(tab_routes.map(Json::string)).stringify(),
  )
  .replace_all(
    old="__MM_RUNTIME_VERSION__",
    new=@versions.runtime_api_version().to_string(),
  )
  .replace_all(
    old="__MM_RENDERER_VERSION__",
    new=@versions.renderer_protocol_version().to_string(),
  )
}
