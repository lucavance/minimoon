///|
#cfg(target="js")
extern "js" fn run_layout_host_test(
  host_source : String,
  protocol_source : String,
  abi : Int,
) -> String =
  #|(hostSource, protocolSource, abi) => {
  #|  const saved = new Map(["wx", "Page"].map(key => [key, Object.getOwnPropertyDescriptor(globalThis, key)]))
  #|  const hosts = []
  #|  const assert = (value, message) => { if (!value) throw new Error(message) }
  #|  try {
  #|    const protocol = { exports: {} }
  #|    new Function("module", protocolSource)(protocol)
  #|    const module = { exports: {} }
  #|    new Function("require", "module", hostSource)(() => protocol.exports, module)
  #|    const definitions = []
  #|    globalThis.Page = definition => definitions.push(definition)
  #|    let width = 375, reads = 0, menuReads = 0, broken = false
  #|    globalThis.wx = {
  #|      getWindowInfo() { reads++; if (broken) throw new Error("unavailable"); return { windowWidth: width, windowHeight: 720, screenWidth: width, screenHeight: 812, screenTop: 0, statusBarHeight: 44, safeArea: { left: 0, top: 44, width, height: 734 } } },
  #|      getMenuButtonBoundingClientRect() { menuReads++; if (broken) return { left: 0, top: 0, width: 0, height: 0 }; return { left: width - 97, top: 48, width: 87, height: 32 } }
  #|    }
  #|    const entries = [], instances = new Map(), acknowledgements = []
  #|    let writes = 0, nextId = 0
  #|    const layoutWidth = layout => layout.window ? String(layout.window.window_width) : "unknown"
  #|    const tree = layout => ({ kind: "view", identity: "root", text: "", props: {}, events: {}, children: [{ kind: "text", identity: "label", text: layoutWidth(layout), props: {}, events: {}, children: [] }] })
  #|    const render = state => { const base = state.revision++; return JSON.stringify([{ type: "ReplaceViewTree", component_id: "layout", base_revision: base, revision: state.revision, tree: tree(state.layout) }]) }
  #|    const runtime = {
  #|      minimoon_runtime_version: () => abi,
  #|      minimoon_runtime_state_abi_version: () => abi,
  #|      minimoon_runtime_create_app(page, input, raw) {
  #|        const layout = JSON.parse(raw), route = JSON.parse(input)
  #|        assert(page === "layout" && Object.keys(route).join() === "id" && route.id === "actual", "layout polluted route input")
  #|        entries.push("create:" + layoutWidth(layout))
  #|        const id = "layout:" + (++nextId)
  #|        instances.set(id, { layout, revision: 0, hidden: false })
  #|        return JSON.stringify({ ok: true, id })
  #|      },
  #|      minimoon_runtime_lifecycle(id, hook, raw) {
  #|        const state = instances.get(id)
  #|        if (hook === "onLoad") { entries.push("load"); return render(state) }
  #|        if (hook === "onHide") { entries.push("hide"); state.hidden = true }
  #|        if (hook === "$minimoon:layout-show") {
  #|          const next = JSON.parse(raw), changed = JSON.stringify(next) !== JSON.stringify(state.layout)
  #|          entries.push("show:" + layoutWidth(next)); state.hidden = false; state.layout = next
  #|          if (changed) return render(state)
  #|        }
  #|        return "[]"
  #|      },
  #|      minimoon_runtime_update_layout(id, raw) {
  #|        const state = instances.get(id), next = JSON.parse(raw)
  #|        entries.push("resize:" + layoutWidth(next))
  #|        if (state.hidden) { state.pending = next; return "[]" }
  #|        if (JSON.stringify(next) === JSON.stringify(state.layout)) return "[]"
  #|        state.layout = next; return render(state)
  #|      },
  #|      minimoon_runtime_dispatch_batch() { entries.push("tap"); return "[]" },
  #|      minimoon_runtime_mount() { entries.push("mount"); return "[]" },
  #|      minimoon_runtime_snapshot(id) { const state = instances.get(id); return JSON.stringify({ revision: state.revision, tree: tree(state.layout) }) },
  #|      minimoon_runtime_dispose(id) { instances.delete(id); return "[]" }
  #|    }
  #|    const instantiate = () => {
  #|      module.exports.registerMinimoonPage(runtime, "layout", { kind: "view", identity: "root", text: "", props: {}, events: {}, children: [] }, [])
  #|      const definition = definitions.pop()
  #|      const host = { ...definition, data: structuredClone(definition.data), setData(patch, callback) { writes++; for (const [key, value] of Object.entries(patch)) { const [page, field] = key.split("."); this.data[page][field] = value } acknowledgements.push(callback) } }
  #|      hosts.push(host); return host
  #|    }
  #|    const ack = () => { let limit = 100; while (acknowledgements.length) { assert(limit-- > 0, "unbounded render queue"); acknowledgements.shift()() } }
  #|    const host = instantiate()
  #|    host.onLoad({ id: "actual" })
  #|    assert(entries.join() === "create:375,load" && host.data.layout.tree.children[0].text === "375", "first business tree did not include synchronous layout")
  #|    assert(reads === 1 && menuReads === 1 && writes === 1, "first Load sampled or rendered more than once")
  #|    host.onShow(); host.onReady()
  #|    assert(reads === 1 && menuReads === 1, "first Show remeasured initial layout")
  #|    width = 410; host.onResize(); width = 420; host.onResize()
  #|    host._ed("tap", "business", {})
  #|    width = 430; host.onResize()
  #|    assert(entries.length === 2, "layout bypassed outstanding render acknowledgement")
  #|    ack()
  #|    assert(entries.join() === "create:375,load,show:375,mount,resize:420,tap,resize:430", "resize coalescing crossed an interaction or violated queue order: " + entries.join())
  #|    const beforeHide = writes
  #|    host.onHide(); width = 440; host.onResize(); width = 450; host.onResize()
  #|    assert(writes === beforeHide && host.data.layout.tree.children[0].text === "430", "hidden layout caused a render")
  #|    width = 460; host.onShow(); ack()
  #|    assert(writes === beforeHide + 1 && host.data.layout.tree.children[0].text === "460", "resume did not apply latest synchronous reading in one Show")
  #|    broken = true; host.onResize(); ack()
  #|    assert(writes === beforeHide + 1, "invalid resize discarded last valid layout")
  #|    host.onUnload(); const afterUnload = reads; host.onResize(); host.onShow()
  #|    assert(reads === afterUnload && instances.size === 0, "disposed host still read layout")
  #|    const fallback = instantiate(); fallback.onLoad({ id: "actual" }); fallback.onShow(); fallback.onReady(); ack()
  #|    assert(fallback.data.layout.tree.children[0].text === "unknown", "missing API invented device dimensions")
  #|    fallback.onUnload()
  #|    return ""
  #|  } catch (error) { return String(error && error.stack || error) }
  #|  finally { for (const host of hosts) { if (host.__mmInstanceId) host.onUnload() } for (const [key, descriptor] of saved) { if (descriptor) Object.defineProperty(globalThis, key, descriptor); else delete globalThis[key] } }
  #|}

///|
#cfg(target="js")
test "host layout is synchronous, queue ordered, page owned and disposable" {
  assert_eq(
    run_layout_host_test(
      shared_host_bridge(),
      shared_protocol_bridge(),
      @versions.runtime_api_version(),
    ),
    "",
  )
}

///|
test "generated host layout uses a separate creation input and bounded queue entry" {
  let host = shared_host_bridge()
  assert_true(
    host.contains("JSON.stringify(options || {}), JSON.stringify(this._ly)"),
  )
  assert_true(host.contains("$minimoon:layout-show"))
  assert_true(host.contains("this._q[this._q.length - 1].kind === \"layout\""))
  assert_true(host.contains("minimoon_runtime_update_layout"))
  assert_false(host_layout_reader().contains("Promise"))
  assert_false(host_layout_reader().contains("setTimeout"))
  assert_false(host_layout_reader().contains("onWindowResize"))
}
