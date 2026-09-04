///|
pub fn shared_protocol_bridge() -> String {
  (
    #|const nodeKinds = new Set(["view", "text", "button", "input", "image", "fragment", "empty", "scroll-view", "textarea", "switch", "checkbox-group", "checkbox", "radio-group", "radio", "picker", "swiper", "swiper-item", "navigator"])
    #|const nodeFields = new Set(["kind", "identity", "text", "props", "events", "children"])
    #|const propFields = new Set(["id", "className", "style", "section", "value", "placeholder", "src", "alt", "role", "ariaLabel", "ariaExpanded", "ariaSelected", "ariaDisabled", "ariaHidden", "ariaChecked", "ariaModal", "ariaControls", "ariaLabelledBy", "ariaDescribedBy", "ariaOrientation", "ariaHasPopup", "scrollX", "scrollY", "scrollTop", "scrollLeft", "scrollIntoView", "upperThreshold", "lowerThreshold", "maxlength", "disabled", "focus", "checked", "color", "mode", "range", "current", "autoplay", "circular", "interval", "duration", "itemId", "url", "openType"])
    #|const eventFields = new Set(["tap", "input", "change", "confirm", "focus", "blur", "scroll", "upper", "lower"])
    #|const booleanProps = new Set(["scrollX", "scrollY", "disabled", "focus", "checked", "autoplay", "circular", "ariaExpanded", "ariaSelected", "ariaDisabled", "ariaHidden", "ariaChecked", "ariaModal"])
    #|const numberProps = new Set(["scrollTop", "scrollLeft", "upperThreshold", "lowerThreshold", "maxlength", "current", "interval", "duration"])
    #|
    #|function exactKeys(value, keys) {
    #|  if (!value || typeof value !== "object" || Array.isArray(value)) return false
    #|  const actual = Object.keys(value)
    #|  return actual.length === keys.length && actual.every((key) => keys.includes(key))
    #|}
    #|function validateProps(props) {
    #|  if (!props || typeof props !== "object" || Array.isArray(props)) return false
    #|  for (const [key, value] of Object.entries(props)) {
    #|    if (!propFields.has(key)) return false
    #|    if (booleanProps.has(key) ? typeof value !== "boolean" : numberProps.has(key) ? !Number.isInteger(value) : key === "range" || (key === "value" && Array.isArray(value)) ? !Array.isArray(value) || !value.every((item) => typeof item === "string") : typeof value !== "string" && !(key === "value" && Number.isInteger(value))) return false
    #|  }
    #|  return true
    #|}
    #|function validateEvents(events) {
    #|  if (!events || typeof events !== "object" || Array.isArray(events)) return false
    #|  for (const [key, value] of Object.entries(events)) if (!eventFields.has(key) || typeof value !== "string" || !value) return false
    #|  return true
    #|}
    #|function validateNode(node) {
    #|  if (!node || typeof node !== "object" || Array.isArray(node) || !nodeKinds.has(node.kind) || typeof node.identity !== "string" || typeof node.text !== "string" || !node.props || typeof node.props !== "object" || Array.isArray(node.props) || !node.events || typeof node.events !== "object" || Array.isArray(node.events) || !Array.isArray(node.children)) return false
    #|  if (Object.keys(node).some((field) => !nodeFields.has(field)) || Object.keys(node).length !== nodeFields.size || !validateProps(node.props) || !validateEvents(node.events)) return false
    #|  return node.children.every(validateNode)
    #|}
    #|function validatePath(path, children) {
    #|  if (!Array.isArray(path) || path.length === 0 || path.length % 2 === 0) return false
    #|  for (let index = 0; index < path.length - 1; index += 2) if (path[index] !== "children" || !Number.isInteger(path[index + 1]) || path[index + 1] < 0) return false
    #|  return children ? path[path.length - 1] === "children" : ["text", "props", "events"].includes(path[path.length - 1])
    #|}
    #|function resolvePath(root, path) {
    #|  let value = root
    #|  for (const token of path) {
    #|    if (value == null || typeof value !== "object" || !(token in value)) return undefined
    #|    value = value[token]
    #|  }
    #|  return value
    #|}
    #|function copyPath(root, path) {
    #|  if (!root || typeof root !== "object") return null
    #|  let source = root
    #|  const copiedRoot = Array.isArray(source) ? source.slice() : { ...source }
    #|  let copied = copiedRoot
    #|  let copies = 1
    #|  for (const token of path) {
    #|    if (source == null || typeof source !== "object" || !(token in source)) return null
    #|    source = source[token]
    #|    if (!source || typeof source !== "object") return null
    #|    const next = Array.isArray(source) ? source.slice() : { ...source }
    #|    copied[token] = next
    #|    copied = next
    #|    copies += 1
    #|  }
    #|  return { root: copiedRoot, value: copied, copies }
    #|}
    #|function applyPatch(command, pageId, revision, authoritative) {
    #|  if (!exactKeys(command, ["type", "component_id", "base_revision", "revision", "ops"]) || command.type !== "PatchViewTree" || command.component_id !== pageId || !Number.isInteger(command.base_revision) || !Number.isInteger(command.revision) || command.base_revision !== revision || command.revision !== command.base_revision + 1 || !Array.isArray(command.ops) || command.ops.length === 0) return null
    #|  let shadow = authoritative
    #|  let cost = 0
    #|  let copies = 0
    #|  let setOnly = true
    #|  for (const op of command.ops) {
    #|    if (!op || typeof op !== "object") return null
    #|    if (op.op === "set") {
    #|      cost += 1
    #|      if (!exactKeys(op, ["op", "path", "value"]) || !validatePath(op.path, false)) return null
    #|      const parentPath = op.path.slice(0, -1)
    #|      const parent = resolvePath(shadow, parentPath)
    #|      const key = op.path[op.path.length - 1]
    #|      if (!parent || typeof parent !== "object" || !(key in parent) || (key === "text" ? typeof op.value !== "string" : key === "props" ? !validateProps(op.value) : !validateEvents(op.value))) return null
    #|      const candidate = copyPath(shadow, parentPath)
    #|      if (!candidate) return null
    #|      candidate.value[key] = op.value
    #|      shadow = candidate.root
    #|      copies += candidate.copies
    #|    } else if (op.op === "splice") {
    #|      setOnly = false
    #|      cost += 1
    #|      const target = resolvePath(shadow, op.path)
    #|      if (!exactKeys(op, ["op", "path", "index", "delete_count", "items"]) || !validatePath(op.path, true) || !Array.isArray(target) || !Number.isInteger(op.index) || !Number.isInteger(op.delete_count) || op.index < 0 || op.delete_count < 0 || op.index > target.length || op.index + op.delete_count > target.length || !Array.isArray(op.items) || !op.items.every(validateNode)) return null
    #|      const candidate = copyPath(shadow, op.path)
    #|      if (!candidate || !Array.isArray(candidate.value)) return null
    #|      candidate.value.splice(op.index, op.delete_count, ...op.items)
    #|      shadow = candidate.root
    #|      copies += candidate.copies
    #|    } else if (op.op === "move") {
    #|      setOnly = false
    #|      cost += 2
    #|      const target = resolvePath(shadow, op.path)
    #|      if (!exactKeys(op, ["op", "path", "from", "to", "identity", "item"]) || !validatePath(op.path, true) || !Array.isArray(target) || !Number.isInteger(op.from) || !Number.isInteger(op.to) || op.from < 0 || op.from >= target.length || op.to < 0 || op.to >= target.length || op.from === op.to || typeof op.identity !== "string" || !target[op.from] || target[op.from].identity !== op.identity || !validateNode(op.item) || op.item.identity !== op.identity) return null
    #|      const candidate = copyPath(shadow, op.path)
    #|      if (!candidate || !Array.isArray(candidate.value)) return null
    #|      candidate.value.splice(op.from, 1)
    #|      candidate.value.splice(op.to, 0, op.item)
    #|      shadow = candidate.root
    #|      copies += candidate.copies
    #|    } else return null
    #|    if (cost > 32) return null
    #|  }
    #|  return { shadow, setOnly, cost, copies }
    #|}
    #|function createRendererStats() {
    #|  return { patchCommands: 0, replaceCommands: 0, patchOps: 0, setOps: 0, spliceOps: 0, moveOps: 0, hostWriteOps: 0, groupUpdateCalls: 0, setDataCalls: 0, renderCommits: 0, patchFallbacks: 0, rejectedPatches: 0, subscriptionStarts: 0, subscriptionStops: 0, effectCancellations: 0, asyncDrains: 0, receivedUiEvents: 0, coalescedEvents: 0, eventBatches: 0, maxEventBatch: 0, maxQueueDepth: 0, schedulerWarnings: 0, schedulerFailures: 0, renderRetries: 0, renderTimeouts: 0, renderAckSamples: 0, renderAckTotalMs: 0, renderAckMaxMs: 0, renderAckLastMs: 0, shadowCopies: 0 }
    #|}
    #|function decodeNode(encoded) {
    #|  if (!Array.isArray(encoded) || encoded.length !== 6 || !Array.isArray(encoded[5])) throw new Error("invalid compact MiniApp node")
    #|  return { kind: encoded[0], identity: encoded[1], text: encoded[2], props: encoded[3], events: encoded[4], children: encoded[5].map(decodeNode) }
    #|}
    #|function decodeCompactNode(encoded) {
    #|  const node = decodeNode(encoded)
    #|  if (!validateNode(node)) throw new Error("invalid compact MiniApp tree")
    #|  return node
    #|}
    #|
    #|module.exports = { exactKeys, validateNode, applyPatch, createRendererStats, decodeCompactNode }
  )
}
