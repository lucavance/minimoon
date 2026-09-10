///|
#cfg(target="js")
extern "js" fn run_input_patch_test(
  protocol_source : String,
  host_source : String,
  abi : Int,
) -> String =
  #|(source, hostSource, abi) => {
  #|  try {
  #|    const module = { exports: {} }; new Function("module", source)(module)
  #|    const { applyPatch } = module.exports
  #|    const assert = (condition, message) => { if (!condition) throw new Error(message) }
  #|    const same = (a, b) => JSON.stringify(a) === JSON.stringify(b)
  #|    const node = (kind, identity, props = {}) => ({ kind, identity, props, events: {}, text: "", children: [] })
  #|    const command = ops => ({ type: "PatchViewTree", component_id: "test", base_revision: 0, revision: 1, ops })
  #|    const set = (path, value) => ({ op: "set", path, value })
  #|    let page
  #|    const hostModule = { exports: {} }
  #|    new Function("module", "require", "Page", hostSource)(hostModule, () => module.exports, value => { page = value })
  #|    hostModule.exports.registerMinimoonPage({ minimoon_runtime_version: () => abi, minimoon_runtime_state_abi_version: () => abi }, "test", node("empty", "root"), [])
  #|    const execute = (ops, tree) => {
  #|      const patches = [], advanced = []
  #|      page._sh = tree; page._rv = 0; page._st = module.exports.createRendererStats()
  #|      page._fb = reason => { throw new Error(reason) }
  #|      page._sw = (candidate, generation, done, retry, write) => write(1, () => {})
  #|      page.setData = patch => { patches.push(patch) }
  #|      page.groupUpdates = callback => callback()
  #|      page.replaceDataOnPath = (path, value) => advanced.push(set(path, value))
  #|      page.spliceArrayDataOnPath = (path, index, delete_count, items) => advanced.push({ op: "splice", path, index, delete_count, items })
  #|      page._ap(command(ops), 1, () => {})
  #|      assert(patches.length === 1, "patch must produce one acknowledged host commit")
  #|      const fields = Object.keys(patches[0])
  #|      assert(!fields.some(a => fields.some(b => a !== b && b.startsWith(a + "."))), "setData has overlapping whole-props/leaf paths")
  #|      return { patch: patches[0], advanced }
  #|    }
  #|    for (const kind of ["input", "textarea"]) {
  #|      const props = { value: "a", focus: false, disabled: false, selectionStart: -1, selectionEnd: -1 }
  #|      const tree = node(kind, "editor", props)
  #|      const edited = { ...props, value: "ab" }
  #|      const result = applyPatch(command([set(["props"], edited)]), "test", 0, tree)
  #|      assert(result && same(result.writes, [set(["props", "value"], "ab")]), kind + ": typing must write only value, not the whole props object or focus/selection")
  #|      assert(same(result.shadow.props, edited) && tree.props.value === "a", "lowering mutated the authoritative input or lost the next snapshot")
  #|      assert(result.cost === 1, "value-only write must retain its cost")
  #|      assert(same(execute([set(["props"], edited)], tree).patch, { "test.commit": 1, "test.tree.props.value": "ab" }), "generated host did not use the lowered value write")
  #|      const focused = applyPatch(command([set(["props"], { ...props, focus: true, selectionStart: 0 })]), "test", 0, tree)
  #|      assert(same(focused.writes, [set(["props", "focus"], true), set(["props", "selectionStart"], 0)]), "explicit focus/selection changes were suppressed")
  #|      assert(focused.cost === 2, "expanded host writes must count against the budget")
  #|      const blurredTree = node(kind, "editor", { ...props, focus: true })
  #|      const blurred = applyPatch(command([set(["props"], props)]), "test", 0, blurredTree)
  #|      assert(same(blurred.writes, [set(["props", "focus"], false)]), "explicit blur was suppressed")
  #|      const withoutSelection = { value: "a", focus: false, disabled: false }
  #|      const removed = applyPatch(command([set(["props"], withoutSelection)]), "test", 0, tree)
  #|      assert(same(removed.writes, [set(["props"], withoutSelection)]), "property removal must keep exact replacement semantics")
  #|      for (const values of [[withoutSelection, edited], [edited, withoutSelection], [withoutSelection, edited, props]]) {
  #|        const original = JSON.stringify(values)
  #|        const host = execute(values.map(value => set(["props"], value)), tree)
  #|        assert(same(host.patch, { "test.commit": 1, "test.tree.props": values[values.length - 1] }), "repeated whole-props/leaf writes lost the final value or key removal")
  #|        assert(JSON.stringify(values) === original, "host coalescing mutated the command or shadow props")
  #|      }
  #|      assert(applyPatch(command([set(["props", "focus"], false)]), "test", 0, tree) === null, "wire protocol must still reject externally supplied leaf paths")
  #|      const root = { ...node("view", "root"), children: [tree] }
  #|      const insert = { op: "splice", path: ["children"], index: 0, delete_count: 0, items: [node("text", "notice")] }
  #|      const mixed = applyPatch(command([insert, set(["children", 1, "props"], edited)]), "test", 0, root)
  #|      assert(mixed && !mixed.setOnly && same(mixed.writes, [insert, set(["children", 1, "props", "value"], "ab")]), "mixed structural/input patch used the wrong intermediate path")
  #|      const advanced = execute([insert, set(["children", 1, "props"], edited)], root)
  #|      assert(same(advanced.advanced, [{ ...insert, path: ["test", "tree", "children"] }, set(["test", "tree", "children", 1, "props", "value"], "ab")]), "generated host lost ordered structural/input writes")
  #|      assert(same(advanced.patch, { "test.commit": 1 }), "structural update must finish with a sentinel-only setData")
  #|      const repeated = applyPatch(command([set(["props"], edited), set(["props"], { ...edited, value: "abc" })]), "test", 0, tree)
  #|      assert(same(repeated.writes, [set(["props", "value"], "ab"), set(["props", "value"], "abc")]), "sequential writes were not lowered in order")
  #|      const many = Array.from({ length: 17 }, (_, index) => set(["props"], { ...props, value: String(index), focus: index % 2 === 0 }))
  #|      assert(applyPatch(command(many), "test", 0, tree) === null, "expanded writes bypassed the 32-write ceiling")
  #|      assert(applyPatch(command(Array.from({ length: 33 }, () => set(["props"], props))), "test", 0, tree) === null, "no-op writes bypassed the protocol operation ceiling")
  #|    }
  #|    const button = node("button", "action", { disabled: false })
  #|    const update = set(["props"], { disabled: true })
  #|    assert(same(applyPatch(command([update]), "test", 0, button).writes, [update]), "unrelated controls changed their write semantics")
  #|    return ""
  #|  } catch (error) { return String(error && error.stack || error) }
  #|}

///|
#cfg(target="js")
test "input host writes preserve unchanged native focus and selection" {
  for application in [false, true] {
    assert_eq(
      run_input_patch_test(
        shared_protocol_bridge(),
        shared_host_bridge(application~),
        @versions.runtime_api_version(),
      ),
      "",
    )
  }
}
