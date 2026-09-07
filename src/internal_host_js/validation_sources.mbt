///|
pub fn host_smoke_source(page_files : Array[String]) -> String {
  validation_application_boot() +
  "const fs = require(\"node:fs\")\n" +
  "globalThis.TextEncoder = undefined\n" +
  "const pageFiles = [" +
  page_files.map(file => file.escape()).join(", ") +
  "]\n" +
  "const definitions = []\n" +
  "globalThis.Page = (page) => definitions.push(page)\n" +
  "globalThis.Component = () => { throw new Error(\"unvalidated Chaining page registration is forbidden\") }\n" +
  "globalThis.App = () => {}\n" +
  "globalThis.wx = { navigateTo() {}, redirectTo() {} }\n" +
  "for (const file of pageFiles) { bootApplication(file); require(file) }\n" +
  "if (definitions.length !== " +
  page_files.length().to_string() +
  ") throw new Error(\"Page Definition API registration count mismatch\")\n" +
  "const assertStyleParity = (value, wxss) => {\n" +
  "  if (!value || typeof value !== \"object\") return\n" +
  "  if (typeof value.className === \"string\") {\n" +
  "    for (const token of value.className.split(/\\s+/).filter(Boolean)) {\n" +
  "      if (!wxss.includes(`.${token}`)) throw new Error(`dynamic class selector missing from WXSS: ${token}`)\n" +
  "    }\n" +
  "  }\n" +
  "  for (const child of Object.values(value)) assertStyleParity(child, wxss)\n" +
  "}\n" +
  "const findAppWxss = (file) => {\n" +
  "  let directory = require(\"node:path\").dirname(file)\n" +
  "  while (true) {\n" +
  "    const candidate = require(\"node:path\").join(directory, \"app.wxss\")\n" +
  "    if (fs.existsSync(candidate)) return candidate\n" +
  "    const parent = require(\"node:path\").dirname(directory)\n" +
  "    if (parent === directory) throw new Error(`app.wxss not found for ${file}`)\n" +
  "    directory = parent\n" +
  "  }\n" +
  "}\n" +
  "for (let pageIndex = 0; pageIndex < definitions.length; pageIndex += 1) {\n" +
  "  const page = definitions[pageIndex]\n" +
  "  const wxss = fs.readFileSync(findAppWxss(pageFiles[pageIndex]), \"utf8\")\n" +
  "  assertStyleParity(page.data, wxss)\n" +
  "  const pending = []\n" +
  "  const resolve = (root, path) => { let value = root; for (const token of path) value = value[token]; return value }\n" +
  "  const assign = (root, path, value) => { const parent = resolve(root, path.slice(0, -1)); parent[path[path.length - 1]] = value }\n" +
  "  const host = { ...page, data: structuredClone(page.data), setData(patch, callback) {\n" +
  "    for (const [path, value] of Object.entries(patch)) {\n" +
  "      const tokens = path.replace(/\\[(\\d+)\\]/g, \".$1\").split(\".\").map((token) => /^\\d+$/.test(token) ? Number(token) : token)\n" +
  "      assign(this.data, tokens, value)\n" +
  "    }\n" +
  "    if (callback) callback()\n" +
  "  }, replaceDataOnPath(path, value) { pending.push([\"set\", path, value]) }, spliceArrayDataOnPath(path, index, del, items) { pending.push([\"splice\", path, index, del, items]) }, groupUpdates(callback) { callback(); for (const op of pending.splice(0)) { if (op[0] === \"set\") assign(this.data, op[1], op[2]); else resolve(this.data, op[1]).splice(op[2], op[3], ...op[4]) } } }\n" +
  "  page.onLoad.call(host, {})\n" +
  "  page.onShow.call(host)\n" +
  "  page.onReady.call(host)\n" +
  "  if (!host.__mmInstanceId) throw new Error(\"runtime instance missing\")\n" +
  "  page.onUnload.call(host)\n" +
  "  if (host.__mmInstanceId !== null) throw new Error(\"runtime instance was not cleared on unload\")\n" +
  "}\n"
}

///|
pub fn verify_preload_source() -> String {
  "globalThis.Page = () => {}; globalThis.Component = () => { throw new Error('unvalidated Chaining page registration') }; globalThis.App = () => {}; globalThis.wx = {};\n"
}
