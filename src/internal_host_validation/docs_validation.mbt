///|
pub fn docs_check_source() -> String {
  // This source is executed only by repository validation.
  (
    #|const fs = require("node:fs")
    #|const path = require("node:path")
    #|const crypto = require("node:crypto")
    #|const { spawnSync } = require("node:child_process")
    #|
    #|const [rootArg, productVersion, contractVersion, runtimeVersion, protocolVersion, mode] = process.argv.slice(2)
    #|if (!rootArg || !productVersion || !contractVersion || !runtimeVersion || !protocolVersion) {
    #|  throw new Error("usage: docs-check <root> <product> <contract> <runtime> <protocol>")
    #|}
    #|const root = path.resolve(rootArg)
    #|const errors = []
    #|const fail = (message) => errors.push(message)
    #|const absolute = (relative) => path.join(root, relative)
    #|const read = (relative) => fs.readFileSync(absolute(relative), "utf8")
    #|const normalized = (relative) => read(relative).replace(/\s+/g, " ")
    #|const sha256 = (data) => crypto.createHash("sha256").update(data).digest("hex")
    #|const posix = (value) => value.split(path.sep).join("/")
    #|const fixtures = [
    #|  { name: "miniapp_conformance_app", directory: "examples/miniapp_conformance_app" },
    #|  { name: "minimoon_ui_showcase", directory: "ui/examples/showcase" },
    #|]
    #|
    #|function moduleVersionProblems(source, content, expected) {
    #|  const problems = []
    #|  for (const [module, version] of Object.entries(expected)) {
    #|    const escaped = module.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
    #|    const pattern = new RegExp(`${escaped}(?:@|[ \\x60]+)([0-9]+\\.[0-9]+\\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?)`, "g")
    #|    const versions = [...content.matchAll(pattern)].map((match) => match[1])
    #|    if (!versions.includes(version)) problems.push(`${source}: missing current module version ${module}@${version}`)
    #|    for (const found of versions) {
    #|      if (found !== version) problems.push(`${source}: stale module version ${module}@${found}; expected ${version}`)
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function mirroredTextProblems(source, expected, actual) {
    #|  return expected === actual ? [] : [source + ": README mirror drift"]
    #|}
    #|
    #|function markedCode(source, content, name, language) {
    #|  const start = "<!-- minimoon:" + name + ":start -->"
    #|  const end = "<!-- minimoon:" + name + ":end -->"
    #|  if (content.split(start).length !== 2 || content.split(end).length !== 2) {
    #|    return { code: "", problems: [source + ": missing or duplicate " + name + " block"] }
    #|  }
    #|  const begin = content.indexOf(start) + start.length
    #|  const finish = content.indexOf(end)
    #|  const lines = content.slice(begin, finish).trim().split("\n")
    #|  const fence = String.fromCharCode(96).repeat(3)
    #|  if (finish < begin || lines[0] !== fence + language || lines.at(-1) !== fence) {
    #|    return { code: "", problems: [source + ": malformed " + name + " block"] }
    #|  }
    #|  return { code: lines.slice(1, -1).join("\n"), problems: [] }
    #|}
    #|
    #|function schemaMigrationProblems(source, content, expected) {
    #|  const { active, problems } = historicalSections(source, content)
    #|  const plain = active.replace(/[\x60*_]/g, "").replace(/\s+/g, " ")
    #|  const patterns = [
    #|    /\bschema(?:Version)?\b[^.;]*?\bmigrate\s+to\s+(?:schema(?:Version)?\s+)?(\d+)\b/gi,
    #|    /\bupgrade\b[^.;]*?\bschemaVersion\s+to\s+(\d+)\b/gi,
    #|  ]
    #|  for (const pattern of patterns) {
    #|    for (const match of plain.matchAll(pattern)) {
    #|      if (Number(match[1]) !== Number(expected.contractVersion)) {
    #|        problems.push(source + ": stale schema migration target: " + match[1])
    #|      }
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function fixtureIndexProblems(source, content, inventory) {
    #|  const rows = content.split("\n").filter(line => line.startsWith("|"))
    #|  const problems = []
    #|  for (const fixture of inventory) {
    #|    const found = rows.filter(row => row.includes(fixture.link))
    #|    if (found.length !== 1) {
    #|      problems.push(source + ": missing or duplicate fixture row: " + fixture.link)
    #|      continue
    #|    }
    #|    const cells = found[0].split("|").map(cell => cell.trim())
    #|    if (Number(cells[2]) !== fixture.pages || Number(cells[3]) !== fixture.tabs.length) {
    #|      problems.push(source + ": stale fixture page/Tab count: " + fixture.link)
    #|    }
    #|    const documentedTabs = cells[4]?.split(";")[0].trim()
    #|    if (fixture.tabs.length && documentedTabs !== fixture.tabs.join(" / ")) {
    #|      problems.push(source + ": stale fixture Tab labels: " + fixture.link)
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function fixtureReadmeProblems(source, content, inventory) {
    #|  const problems = []
    #|  for (const fixture of inventory) {
    #|    const row = content.split("\n").find(line => line.startsWith("|") && line.includes(fixture.directory + "/README.md"))
    #|    if (!row) {
    #|      problems.push(source + ": missing fixture overview: " + fixture.directory)
    #|      continue
    #|    }
    #|    const description = row.split("|")[2] || ""
    #|    const counts = (description.match(/\d+/g) || []).map(Number)
    #|    if (counts[0] !== fixture.pages || (fixture.tabs.length && counts[1] !== fixture.tabs.length)) {
    #|      problems.push(source + ": stale fixture overview count: " + fixture.directory)
    #|    }
    #|    if (fixture.tabs.length && !description.includes(fixture.tabs.join(" / "))) {
    #|      problems.push(source + ": stale fixture overview Tab labels: " + fixture.directory)
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function currentFixtureProseProblems(source, content) {
    #|  let current = content
    #|  if (source === "CHANGELOG.md") {
    #|    // Only the unreleased section describes current fixture ownership.
    #|    const sections = content.split(/(?=^## )/m)
    #|    current = sections.find(section => /^## \[[^\]]+\] - Unreleased/m.test(section)) || ""
    #|  }
    #|  const { active, problems } = historicalSections(source, current)
    #|  for (const sentence of active.split(/[.!?。](?:\s+|$)/)) {
    #|    if (/\b(?:migrate|migration|removed|formerly|historical)\b|旧.{0,30}迁移|已迁移/i.test(sentence)) continue
    #|    if (/Capability Probe|capability_probe|能力验证(?:页面|[（(])|retains Lab and Details/.test(sentence)) {
    #|      problems.push(source + ": stale active Conformance page ownership")
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function normalizedMoonSnippet(code) {
    #|  return code.replace(/@minimoon\./g, "").replace(/\s+/g, "").replace(/,(?=[}\])])/g, "")
    #|}
    #|
    #|function onboardingParityProblems(source, reference, content) {
    #|  const problems = []
    #|  for (const [name, language] of [["onboarding", "bash"], ["counter", "moonbit"]]) {
    #|    if (name === "counter" && source.endsWith("miniapp_quickstart.md")) continue
    #|    const expected = markedCode("README.mbt.md", reference, name, language)
    #|    const actual = markedCode(source, content, name, language)
    #|    problems.push(...expected.problems, ...actual.problems)
    #|    const normalize = name === "counter" ? normalizedMoonSnippet : text => text.trim()
    #|    if (normalize(expected.code) !== normalize(actual.code)) problems.push(source + ": onboarding example drift: " + name)
    #|  }
    #|  return problems
    #|}
    #|
    #|
    #|function bilingualProblems(source, content) {
    #|  const problems = []
    #|  const headings = content.match(/^#{1,6} .+$/gm) || []
    #|  for (const heading of headings) {
    #|    if (!heading.includes(" / ")) problems.push(`${source}: heading is not bilingual: ${heading}`)
    #|  }
    #|  const sections = content.split(/(?=^## )/m).filter((section) => section.startsWith("## "))
    #|  for (const section of sections) {
    #|    const heading = section.split("\n", 1)[0]
    #|    if (!/[\u3400-\u9fff]/u.test(section)) problems.push(`${source}: section has no Chinese text: ${heading}`)
    #|    if (!/^> \*\*English:\*\*$/m.test(section)) problems.push(`${source}: section is missing its English translation: ${heading}`)
    #|  }
    #|  const markers = [...content.matchAll(/^> \*\*English:\*\*$/gm)]
    #|  if (markers.length < 2) problems.push(`${source}: too few interleaved English paragraphs`)
    #|  for (const marker of markers) {
    #|    const before = content.slice(Math.max(0, marker.index - 1600), marker.index)
    #|    const after = content.slice(marker.index + marker[0].length, marker.index + marker[0].length + 1200)
    #|    if (!/[\u3400-\u9fff]/u.test(before)) problems.push(`${source}: English paragraph has no preceding Chinese paragraph`)
    #|    if (!/^\n>\n> .*[A-Za-z]/m.test(after)) problems.push(`${source}: English marker has no blockquoted translation`)
    #|  }
    #|  return problems
    #|}
    #|
    #|function missingSymbolProblems(source, sourceText, symbols) {
    #|  return symbols
    #|    .filter((symbol) => !sourceText.includes(symbol))
    #|    .map((symbol) => `${source}: stale source symbol: ${symbol}`)
    #|}
    #|
    #|function diagramSourceProblems(source, extracted, generated) {
    #|  return extracted === generated ? [] : [`${source}: Mermaid source drift`]
    #|}
    #|
    #|function svgViewBox(svg) {
    #|  const match = svg.match(/\bviewBox="([^"]+)"/)
    #|  return match ? match[1] : null
    #|}
    #|
    #|function pngScaleProblems(source, viewBox, width, height, scale) {
    #|  const values = String(viewBox).trim().split(/\s+/).map(Number)
    #|  if (values.length !== 4 || values.some((value) => !Number.isFinite(value))) {
    #|    return [`${source}: SVG viewBox is missing or invalid`]
    #|  }
    #|  const expectedWidth = Math.ceil(values[2]) * scale
    #|  const expectedHeight = Math.ceil(values[3]) * scale
    #|  return width === expectedWidth && height === expectedHeight
    #|    ? []
    #|    : [`${source}: PNG scale mismatch; expected ${expectedWidth}x${expectedHeight}, received ${width}x${height}`]
    #|}
    #|
    #|function inventoryProblems(source, expected, actual) {
    #|  const wanted = [...expected].sort().join("\n")
    #|  const found = [...actual].sort().join("\n")
    #|  return wanted === found ? [] : [`${source}: stale or missing diagram assets`]
    #|}
    #|
    #|function historicalSections(source, content) {
    #|  const problems = []
    #|  let historical = false
    #|  const active = content.split("\n").map((line, index) => {
    #|    const marker = line.match(/^[ \t]*<!-- minimoon:historical:(start|end) -->[ \t]*$/)
    #|    if (marker) {
    #|      if (marker[1] === "start") {
    #|        if (historical) problems.push(`${source}:${index + 1}: nested historical documentation marker`)
    #|        historical = true
    #|      } else {
    #|        if (!historical) problems.push(`${source}:${index + 1}: unmatched historical documentation end marker`)
    #|        historical = false
    #|      }
    #|      return ""
    #|    }
    #|    if (/<!--[ \t]*minimoon:historical:/.test(line)) problems.push(`${source}:${index + 1}: malformed historical documentation marker`)
    #|    return historical ? "" : line
    #|  }).join("\n")
    #|  if (historical) problems.push(`${source}: unclosed historical documentation marker`)
    #|  return { active, problems }
    #|}
    #|
    #|function currentReferenceProblems(source, content, expected) {
    #|  const { active, problems } = historicalSections(source, content)
    #|  return [
    #|    ...problems,
    #|    ...versionReferenceProblems(source, active, expected),
    #|    ...currentConfigProblems(source, active, expected),
    #|    ...schemaMigrationProblems(source, active, expected),
    #|  ]
    #|}
    #|
    #|function versionReferenceProblems(source, content, expected) {
    #|  // Published history and migration paths are not current-version claims.
    #|  if (source === "CHANGELOG.md") return []
    #|  const problems = []
    #|  const plain = content.replace(/[`*_]/g, "")
    #|  const boundaries = [
    #|    ["App Contract", /\b(?:App[ \t]+)?Contract(?:[ \t]+schema)?(?:[ \t]*:[ \t]*|[ \t]+)v?(\d+)\b/gi, Number(expected.contractVersion)],
    #|    ["runtime ABI", /\b(?:runtime[ \t]+)?ABI(?:[ \t]*:[ \t]*|[ \t-]+)v?(\d+)\b/gi, Number(expected.runtimeVersion)],
    #|    ["renderer protocol", /\b(?:renderer[ \t]+protocol(?:[ \t]*:[ \t]*|[ \t-]+)v?|protocol[ \t-]+v)(\d+)\b/gi, Number(expected.protocolVersion)],
    #|    ["App Contract", /^\|[ \t]*(?:App[ \t]+)?Contract[ \t]*\|[ \t]*v?(\d+)[ \t]*\|/gim, Number(expected.contractVersion)],
    #|    ["runtime ABI", /^\|[ \t]*(?:runtime[ \t]+)?ABI[ \t]*\|[ \t]*v?(\d+)[ \t]*\|/gim, Number(expected.runtimeVersion)],
    #|    ["renderer protocol", /^\|[ \t]*(?:renderer[ \t]+)?protocol[ \t]*\|[ \t]*v?(\d+)[ \t]*\|/gim, Number(expected.protocolVersion)],
    #|    ["App Contract", /\bnon-v(\d+)\s+(?:configs\/)?contracts\b/gi, Number(expected.contractVersion)],
    #|    ["runtime ABI", /\bnon-v(\d+)\s+runtime\s+APIs\b/gi, Number(expected.runtimeVersion)],
    #|    ["renderer protocol", /\bnon-v(\d+)\s+renderer\s+protocols\b/gi, Number(expected.protocolVersion)],
    #|  ]
    #|  for (const [label, pattern, current] of boundaries) {
    #|    for (const match of plain.matchAll(pattern)) {
    #|      if (Number(match[1]) !== current) {
    #|        problems.push(`${source}: stale documentation version: ${match[0]}; expected ${label} v${current}`)
    #|      }
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function currentConfigProblems(source, content, expected) {
    #|  if (source === "CHANGELOG.md") return []
    #|  const problems = []
    #|  for (const match of content.matchAll(/^```json[^\n]*\n([\s\S]*?)^```[ \t]*$/gm)) {
    #|    let value
    #|    try { value = JSON.parse(match[1]) } catch { continue }
    #|    if (!value || typeof value !== "object" || Array.isArray(value)) continue
    #|    const configuration = Object.hasOwn(value, "application") || (typeof value.name === "string" && Array.isArray(value.pages))
    #|    if (configuration && value.schemaVersion !== Number(expected.contractVersion)) {
    #|      problems.push(`${source}: stale current MiniApp configuration schema: ${value.schemaVersion}; expected ${expected.contractVersion}`)
    #|    }
    #|  }
    #|  return problems
    #|}
    #|
    #|function authoringOwnershipProblems(source, content) {
    #|  const plain = content.replace(/[`*_]/g, "").replace(/\s+/g, " ")
    #|  const obsolete = [
    #|    /Each configured page package exports program\(\) -> Page/,
    #|    /每个配置的页面包导出 program\(\) -> Page/,
    #|    /An Emit carries only a private graph\/state address/,
    #|    /Emit 只携带私有的 graph\/state 地址/,
    #|    /The page renderer is the sole owner of live host interval/,
    #|    /The renderer owns the only live host-subscription table/,
    #|  ]
    #|  return obsolete.filter((pattern) => pattern.test(plain)).map(() => `${source}: unqualified page-only authoring claim must distinguish optional App ownership`)
    #|}
    #|
    #|function fixtureReportProblems(fixture, report, summary, evidence, expected, manifest) {
    #|  const problems = []
    #|  const problem = (message) => problems.push(`${fixture}: ${message}`)
    #|  const fingerprint = report?.artifactFingerprint
    #|  const devtools = summary?.devtools
    #|  if (report?.schemaVersion !== 1) problem("verify_report schema must be 1")
    #|  if (report?.status !== "passed") problem("verify_report status is not passed")
    #|  if (typeof report?.release !== "boolean") problem("verify_report release flag is missing")
    #|  if (typeof fingerprint !== "string" || fingerprint.length === 0) problem("verify_report fingerprint is missing")
    #|  if (!Array.isArray(report?.checks) || report.checks.length === 0 || report.checks.some((check) => check?.status !== "passed")) problem("verify_report checks must all pass")
    #|  if (manifest?.schemaVersion !== Number(expected.contractVersion)) problem("manifest contract version differs from internal_versions")
    #|  if (manifest?.runtimeApiVersion !== Number(expected.runtimeVersion)) problem("manifest runtime version differs from internal_versions")
    #|  if (manifest?.rendererProtocolVersion !== Number(expected.protocolVersion)) problem("manifest protocol version differs from internal_versions")
    #|  if (manifest?.name !== fixture) problem("manifest fixture name differs from its configured name")
    #|  if (manifest?.pageBridgeEncoding !== "shared-compact-node-v1") problem("manifest does not describe release compact artifacts")
    #|  if (summary?.schemaVersion !== Number(expected.contractVersion)) problem("release_summary contract version differs from internal_versions")
    #|  if (summary?.runtimeApiVersion !== Number(expected.runtimeVersion)) problem("release_summary runtime version differs from internal_versions")
    #|  if (summary?.rendererProtocolVersion !== Number(expected.protocolVersion)) problem("release_summary protocol version differs from internal_versions")
    #|  if (summary?.name !== fixture) problem("release_summary fixture name differs from its configured name")
    #|  if (summary?.mode !== "release") problem("release_summary does not describe release-mode bytes")
    #|  if (summary?.automated?.status !== report?.status) problem("release_summary status differs from verify_report")
    #|  if (summary?.automated?.artifactFingerprint !== fingerprint) problem("release_summary fingerprint differs from verify_report")
    #|  if (!devtools || typeof devtools !== "object") {
    #|    problem("release_summary DevTools state is missing")
    #|  } else if (devtools.status === "pending") {
    #|    if (Object.keys(devtools).sort().join(",") !== "evidence,status") problem("pending release_summary must contain only public pending fields")
    #|    if (devtools.evidence !== null) problem("pending release_summary must not name Developer Tools evidence")
    #|    if (devtools.artifactFingerprint != null) problem("pending release_summary must not retain a Developer Tools fingerprint")
    #|    if (report?.release === true) problem("release verification cannot be complete while Developer Tools evidence is pending")
    #|  } else if (devtools.status === "passed") {
    #|    if (report?.release !== true) problem("candidate release_summary must keep Developer Tools pending")
    #|    if (devtools.evidence !== "generated/devtools.evidence.json") problem("release_summary Developer Tools evidence path is not canonical")
    #|    if (devtools.artifactFingerprint !== fingerprint) problem("release_summary Developer Tools fingerprint differs from verify_report")
    #|    if (!evidence) {
    #|      problem("passed release_summary has no Developer Tools evidence")
    #|    } else {
    #|      if (evidence.schemaVersion !== 1) problem("Developer Tools evidence schema must be 1")
    #|      if (evidence.app !== fixture) problem("Developer Tools evidence app differs from its fixture")
    #|      if (evidence.scope !== `current-v${expected.contractVersion}`) problem("Developer Tools evidence scope differs from App Contract")
    #|      if (evidence.status !== "passed") problem("Developer Tools evidence status differs from release_summary")
    #|      if (evidence.artifactFingerprint !== fingerprint) problem("Developer Tools evidence does not match the release report")
    #|      if (evidence.tool !== "WeChat Developer Tools") problem("Developer Tools evidence tool is invalid")
    #|      if (typeof evidence.recordedAt !== "string" || evidence.recordedAt.length === 0) problem("Developer Tools evidence timestamp is missing")
    #|      if (typeof evidence.toolVersion !== "string" || evidence.toolVersion.length === 0) problem("Developer Tools evidence version is missing")
    #|    }
    #|  } else {
    #|    problem(`unsupported release_summary Developer Tools status: ${devtools.status}`)
    #|  }
    #|  return {
    #|    problems,
    #|    state: {
    #|      fixture,
    #|      phase: report?.release === true ? "release" : "candidate",
    #|      automated: report?.status ?? "missing",
    #|      devtools: devtools?.status ?? "missing",
    #|    },
    #|  }
    #|}
    #|
    #|function statusDocumentProblems(source, content, states) {
    #|  const problems = []
    #|  const requiredLinks = fixtures.flatMap(({ directory }) =>
    #|    ["verify_report.json", "release_summary.json", "devtools.evidence.json"].map((file) => `../${directory}/generated/${file}`))
    #|  for (const link of requiredLinks) {
    #|    if (!content.includes(`(${link})`)) problems.push(`${source}: active status must link ${link}`)
    #|  }
    #|  for (const copied of [
    #|    [/fnv1a64-relpath-v\d+:/i, "artifact fingerprint"],
    #|    [/\"release\"\s*:\s*(?:true|false)/i, "release boolean"],
    #|    [/\brecordedAt\b/i, "evidence timestamp field"],
    #|    [/\btoolVersion\b/i, "evidence tool-version field"],
    #|    [/passed the exact Developer Tools checklist on \d{4}-\d{2}-\d{2}/i, "evidence timestamp"],
    #|  ]) {
    #|    if (copied[0].test(content)) problems.push(`${source}: active status copies transient ${copied[1]}`)
    #|  }
    #|  if (states.length === 0) problems.push(`${source}: active status has no fixture report`)
    #|  if (!content.includes("local and Git-ignored")) problems.push(`${source}: active status must state that real-host evidence is local and Git-ignored`)
    #|  const completion = /Lifecycle\s+real-host\s+validation\s+and\s+release\s+verification\s+are\s+complete\s+for\s+the\s+current\s+generated\s+bytes/i
    #|  if (completion.test(content)) problems.push(`${source}: active status must not publish transient real-host completion`)
    #|  return problems
    #|}
    #|
    #|function pngDimensions(data) {
    #|  const signature = "89504e470d0a1a0a"
    #|  if (data.length < 24 || data.subarray(0, 8).toString("hex") !== signature) return null
    #|  return [data.readUInt32BE(16), data.readUInt32BE(20)]
    #|}
    #|
    #|function runOnboardingSelfTest() {
    #|  const expected = { contractVersion }
    #|  const inventory = [{ directory: "examples/core", link: "core/README.md", pages: 7, tabs: ["首页", "交互", "平台", "应用"] }]
    #|  const index = "| [core](core/README.md) | 7 | 4 | 首页 / 交互 / 平台 / 应用; Runtime Lab |"
    #|  const overview = "| [core](https://github.com/lucavance/minimoon/blob/main/examples/core/README.md) | 7 pages, 4 native Tabs — 首页 / 交互 / 平台 / 应用 |"
    #|  const fence = String.fromCharCode(96).repeat(3)
    #|  const marked = "<!-- minimoon:onboarding:start -->\n" + fence + "bash\nminimoon init ../my-app --minimoon-root \"$PWD\"\n" + fence + "\n<!-- minimoon:onboarding:end -->"
    #|  const counter = "<!-- minimoon:counter:start -->\n" + fence + "moonbit\nfn demo() { () }\n" + fence + "\n<!-- minimoon:counter:end -->"
    #|  const doc = marked + "\n" + counter
    #|  const oldSchema = Number(contractVersion) - 1
    #|  const migration = "Schema 8 and 9 configurations must migrate to " + contractVersion + ";"
    #|  const badMigration = "Schema 8 and 9 configurations must migrate to " + oldSchema + ";"
    #|  const cases = [
    #|    ["mirror drift", mirroredTextProblems("readme", "current", "old"), "mirror drift"],
    #|    ["page count", fixtureIndexProblems("index", index.replace("| 7 |", "| 4 |"), inventory), "page/Tab count"],
    #|    ["Tab count", fixtureIndexProblems("index", index.replace("| 4 |", "| 3 |"), inventory), "page/Tab count"],
    #|    ["Tab label", fixtureIndexProblems("index", index.replace("平台", "能力"), inventory), "Tab labels"],
    #|    ["overview count", fixtureReadmeProblems("readme", overview.replace("7 pages", "4 pages"), inventory), "overview count"],
    #|    ["overview label", fixtureReadmeProblems("readme", overview.replace("平台", "能力"), inventory), "overview Tab labels"],
    #|    ["schema migration", schemaMigrationProblems("ui", badMigration, expected), "schema migration target"],
    #|    ["source workflow", onboardingParityProblems("translation", doc, doc.replace("--minimoon-root", "--wrong")), "example drift"],
    #|    ["missing source block", onboardingParityProblems("translation", doc, counter), "missing or duplicate"],
    #|    ["missing counter", onboardingParityProblems("translation", doc, marked), "missing or duplicate"],
    #|    ["duplicate block", markedCode("readme", marked + marked, "onboarding", "bash").problems, "missing or duplicate"],
    #|    ["active old HTTP owner", currentFixtureProseProblems("README.md", "Ten public-API Capability Probe scenarios."), "page ownership"],
    #|    ["migration cannot hide stale owner", currentFixtureProseProblems("CHANGELOG.md", "## [0.2.0] - Unreleased\n\nCapability Probe owns HTTP. Migrate the old capability_probe route without aliases."), "page ownership"],
    #|    ["Chinese old HTTP owner", currentFixtureProseProblems("README.zh-CN.md", "公共 API 验证能力验证页面。"), "page ownership"],
    #|    ["unreleased old route", currentFixtureProseProblems("CHANGELOG.md", "## [0.2.0] - Unreleased\n\n- Retains Capability Probe and Details.\n\n## [0.1.0] - historical\nOld text."), "page ownership"],
    #|  ]
    #|  for (const [name, problems, diagnostic] of cases) {
    #|    if (!problems.some(problem => problem.includes(diagnostic))) throw new Error("onboarding self-test did not reject " + name)
    #|  }
    #|  const history = "<!-- minimoon:historical:start -->\n" + badMigration + "\nCapability Probe\n<!-- minimoon:historical:end -->"
    #|  const accepted = [
    #|    mirroredTextProblems("readme", "same", "same"),
    #|    fixtureIndexProblems("index", index, inventory),
    #|    fixtureReadmeProblems("readme", overview, inventory),
    #|    schemaMigrationProblems("ui", migration, expected),
    #|    schemaMigrationProblems("history", history, expected),
    #|    currentFixtureProseProblems("history", history),
    #|    currentFixtureProseProblems("CHANGELOG.md", "## [0.2.0] - Unreleased\n\n- Platform HTTP scenarios.\n\n## [0.1.0] - 2026-09-04\nCapability Probe"),
    #|    currentFixtureProseProblems("migration", "Migrate the old capability_probe route to request_lifecycle without aliases."),
    #|    currentFixtureProseProblems("README.zh-CN.md", "核心能力验证：7 个页面、4 个原生 Tab"),
    #|    onboardingParityProblems("translation", doc, doc),
    #|  ]
    #|  if (accepted.some(problems => problems.length)) throw new Error("onboarding self-test rejected current facts or explicit history")
    #|}
    #|
    #|
    #|function runSelfTest() {
    #|  runOnboardingSelfTest()
    #|  const expected = { contractVersion, runtimeVersion, protocolVersion }
    #|  const mismatchedContract = `App Contract v${Number(contractVersion) + 1}`
    #|  const mismatchedRuntime = `runtime ABI v${Number(runtimeVersion) + 1}`
    #|  const mismatchedProtocol = `renderer protocol v${Number(protocolVersion) + 1}`
    #|  const historicalStart = "<!-- minimoon:historical:start -->"
    #|  const historicalEnd = "<!-- minimoon:historical:end -->"
    #|  const legacyExample = 'App Contract 8; runtime ABI 10\n```json\n{"schemaVersion":8,"name":"legacy","pages":[]}\n```'
    #|  const markedHistory = `${historicalStart}\n${legacyExample}\n${historicalEnd}`
    #|  const currentExample = `App Contract ${contractVersion}; runtime ABI ${runtimeVersion}\n\`\`\`json\n{"schemaVersion":${contractVersion},"name":"current","pages":[]}\n\`\`\``
    #|  const cases = [
    #|    ["missing English", bilingualProblems("fixture.md", "# 标题 / Title\n\n## 章节 / Section\n\n只有中文。\n"), "missing its English translation"],
    #|    ["stale symbol", missingSymbolProblems("fixture.md", "fn present() {}", ["missing"]), "stale source symbol"],
    #|    ["tampered Mermaid", diagramSourceProblems("fixture.mmd", "graph TD\n", "graph LR\n"), "Mermaid source drift"],
    #|    ["missing viewBox", pngScaleProblems("fixture.svg", null, 30, 30, 3), "viewBox is missing or invalid"],
    #|    ["wrong PNG scale", pngScaleProblems("fixture.png", "0 0 10 10", 29, 30, 3), "PNG scale mismatch"],
    #|    ["stale asset", inventoryProblems("fixture", ["one.svg"], ["one.svg", "old.svg"]), "stale or missing diagram assets"],
    #|    ["stale contract version", versionReferenceProblems("fixture.md", mismatchedContract, expected), "stale documentation version"],
    #|    ["stale runtime version", versionReferenceProblems("fixture.md", mismatchedRuntime, expected), "stale documentation version"],
    #|    ["stale protocol version", versionReferenceProblems("fixture.md", mismatchedProtocol, expected), "stale documentation version"],
    #|    ["contract without v", versionReferenceProblems("fixture.md", "Contract 8", expected), "stale documentation version"],
    #|    ["ABI without v", versionReferenceProblems("fixture.md", "runtime ABI 10", expected), "stale documentation version"],
    #|    ["backticked ABI", versionReferenceProblems("fixture.md", "runtime ABI `10`", expected), "stale documentation version"],
    #|    ["contract table", versionReferenceProblems("fixture.md", "| App Contract | `8` | old |", expected), "stale documentation version"],
    #|    ["ABI table", versionReferenceProblems("fixture.md", "| runtime ABI | 10 | old |", expected), "stale documentation version"],
    #|    ["protocol table", versionReferenceProblems("fixture.md", "| renderer protocol | 7 | old |", expected), "stale documentation version"],
    #|    ["contract schema colon", versionReferenceProblems("fixture.md", "- App Contract schema: 7", expected), "stale documentation version"],
    #|    ["runtime state ABI colon", versionReferenceProblems("fixture.md", "- runtime API/state ABI: 10", expected), "stale documentation version"],
    #|    ["renderer protocol colon", versionReferenceProblems("fixture.md", "- renderer protocol: 7", expected), "stale documentation version"],
    #|    ["inverse contract requirement", versionReferenceProblems("fixture.md", "rejects non-v7 configs/contracts", expected), "stale documentation version"],
    #|    ["inverse runtime requirement", versionReferenceProblems("fixture.md", "rejects non-v10 runtime APIs", expected), "stale documentation version"],
    #|    ["inverse protocol requirement", versionReferenceProblems("fixture.md", "rejects non-v7\nrenderer protocols", expected), "stale documentation version"],
    #|    ["current config schema", currentConfigProblems("fixture.md", '```json\n{"schemaVersion":8,"name":"old","pages":[]}\n```', expected), "stale current MiniApp configuration schema"],
    #|    ["App config schema", currentConfigProblems("fixture.md", '```json\n{"schemaVersion":8,"application":{"package":"src/app"}}\n```', expected), "stale current MiniApp configuration schema"],
    #|    ["unmarked legacy version", currentReferenceProblems("fixture.md", legacyExample, expected), "stale documentation version"],
    #|    ["unmarked legacy config", currentReferenceProblems("fixture.md", legacyExample, expected), "stale current MiniApp configuration schema"],
    #|    ["history does not hide current drift", currentReferenceProblems("fixture.md", `${markedHistory}\nApp Contract 8`, expected), "stale documentation version"],
    #|    ["history does not hide current config drift", currentReferenceProblems("fixture.md", `${markedHistory}\n${legacyExample}`, expected), "stale current MiniApp configuration schema"],
    #|    ["nested history", currentReferenceProblems("fixture.md", `${historicalStart}\n${markedHistory}\n${historicalEnd}`, expected), "nested historical documentation marker"],
    #|    ["unclosed history", currentReferenceProblems("fixture.md", `${historicalStart}\n${legacyExample}`, expected), "unclosed historical documentation marker"],
    #|    ["unmatched history end", currentReferenceProblems("fixture.md", historicalEnd, expected), "unmatched historical documentation end marker"],
    #|    ["inline history marker", currentReferenceProblems("fixture.md", `text ${historicalStart}`, expected), "malformed historical documentation marker"],
    #|    ["unqualified no-argument factory", authoringOwnershipProblems("fixture.md", "Each configured page package exports `program() -> Page`"), "unqualified page-only authoring claim"],
    #|    ["unqualified Chinese factory", authoringOwnershipProblems("fixture.md", "每个配置的页面包导出 `program() -> Page`"), "unqualified page-only authoring claim"],
    #|    ["unqualified local emitter", authoringOwnershipProblems("fixture.md", "An `Emit` carries only a private graph/state address"), "unqualified page-only authoring claim"],
    #|    ["unqualified Chinese emitter", authoringOwnershipProblems("fixture.md", "`Emit` 只携带私有的 graph/state 地址"), "unqualified page-only authoring claim"],
    #|    ["unqualified page interval owner", authoringOwnershipProblems("fixture.md", "The page renderer is the sole owner of live host interval keys"), "unqualified page-only authoring claim"],
    #|    ["unqualified subscription owner", authoringOwnershipProblems("fixture.md", "The renderer owns the only live host-subscription table"), "unqualified page-only authoring claim"],
    #|    ["wrong core module version", moduleVersionProblems("fixture.md", "lampclaw/minimoon@9.9.9", { "lampclaw/minimoon": productVersion }), "stale module version"],
    #|    ["wrong UI module version", moduleVersionProblems("fixture.md", "lampclaw/minimoon_ui 9.9.9", { "lampclaw/minimoon_ui": "0.1.0" }), "stale module version"],
    #|  ]
    #|  for (const [name, problems, expected] of cases) {
    #|    if (!problems.some((problem) => problem.includes(expected))) throw new Error(`documentation self-test did not reject ${name}`)
    #|  }
    #|  const accepted = [
    #|    ["current versions", versionReferenceProblems("fixture.md", `App Contract v${contractVersion}; ABI ${runtimeVersion}; renderer protocol \`${protocolVersion}\``, expected)],
    #|    ["current version table", versionReferenceProblems("fixture.md", `| App Contract | ${contractVersion} |\n| runtime ABI | \`${runtimeVersion}\` |\n| renderer protocol | ${protocolVersion} |`, expected)],
    #|    ["current colon versions", versionReferenceProblems("fixture.md", `App Contract schema: ${contractVersion}; runtime API/state ABI: ${runtimeVersion}; renderer protocol: ${protocolVersion}`, expected)],
    #|    ["current inverse requirements", versionReferenceProblems("fixture.md", `non-v${contractVersion} contracts; non-v${runtimeVersion} runtime APIs; non-v${protocolVersion} renderer protocols`, expected)],
    #|    ["protocol byte budget", versionReferenceProblems("fixture.md", "| shared protocol | 10,000 bytes |", expected)],
    #|    ["published history", versionReferenceProblems("CHANGELOG.md", "App Contract v7, runtime ABI v10, renderer protocol v7", expected)],
    #|    ["migration text", versionReferenceProblems("fixture.md", "App Contract advances from 7 to 9, runtime ABI from 10 to 11, and renderer protocol from 7 to 8.", expected)],
    #|    ["legacy schema explanation", versionReferenceProblems("fixture.md", "Schema `8` input remains accepted without application.", expected)],
    #|    ["current config", currentConfigProblems("fixture.md", `\`\`\`json\n{"schemaVersion":${contractVersion},"name":"current","pages":[]}\n\`\`\``, expected)],
    #|    ["current App config", currentConfigProblems("fixture.md", `\`\`\`json\n{"schemaVersion":${contractVersion},"application":{"package":"src/app"}}\n\`\`\``, expected)],
    #|    ["unrelated report schema", currentConfigProblems("fixture.md", '```json\n{"schemaVersion":1,"status":"passed"}\n```', expected)],
    #|    ["historical config", currentConfigProblems("CHANGELOG.md", '```json\n{"schemaVersion":8,"name":"historical","pages":[]}\n```', expected)],
    #|    ["same-page legacy and current versions", currentReferenceProblems("fixture.md", `${currentExample}\n${markedHistory}\n${currentExample}`, expected)],
    #|    ["separate historical sections", currentReferenceProblems("fixture.md", `${markedHistory}\n${currentExample}\n${markedHistory}`, expected)],
    #|    ["no-App factory", authoringOwnershipProblems("fixture.md", "Without application, page factories remain `program() -> Page`. With application, use `program(deps : @application.Deps) -> Page`.")],
    #|    ["local and App emitters", authoringOwnershipProblems("fixture.md", "A page-local Emit uses graph/state addresses; App Emit delivers after the page transaction commits.")],
    #|  ]
    #|  for (const [name, problems] of accepted) {
    #|    if (problems.length) throw new Error(`documentation self-test rejected ${name}: ${problems.join("; ")}`)
    #|  }
    #|  const report = { schemaVersion: 1, status: "passed", release: true, artifactFingerprint: "fixture-fingerprint", checks: [{ status: "passed" }] }
    #|  const summary = {
    #|    schemaVersion: Number(contractVersion),
    #|    runtimeApiVersion: Number(runtimeVersion),
    #|    rendererProtocolVersion: Number(protocolVersion),
    #|    name: "fixture",
    #|    mode: "release",
    #|    automated: { status: "passed", artifactFingerprint: "fixture-fingerprint" },
    #|    devtools: { status: "passed", evidence: "generated/devtools.evidence.json", artifactFingerprint: "fixture-fingerprint" },
    #|  }
    #|  const manifest = { ...summary, pageBridgeEncoding: "shared-compact-node-v1" }
    #|  const evidence = {
    #|    schemaVersion: 1,
    #|    scope: `current-v${contractVersion}`,
    #|    status: "passed",
    #|    app: "fixture",
    #|    recordedAt: "fixture-timestamp",
    #|    tool: "WeChat Developer Tools",
    #|    toolVersion: "fixture-version",
    #|    artifactFingerprint: "fixture-fingerprint",
    #|  }
    #|  const validate = (reportValue, summaryValue, evidenceValue = null, manifestValue = manifest) => fixtureReportProblems("fixture", reportValue, summaryValue, evidenceValue, expected, manifestValue)
    #|  const release = validate(report, summary, evidence)
    #|  if (release.problems.length !== 0 || release.state.phase !== "release") throw new Error("documentation self-test rejected a consistent release state")
    #|  const candidateReport = { ...report, release: false }
    #|  const candidateSummary = { ...summary, devtools: { status: "pending", evidence: null } }
    #|  const candidate = validate(candidateReport, candidateSummary)
    #|  if (candidate.problems.length !== 0 || candidate.state.phase !== "candidate") throw new Error("documentation self-test rejected a consistent candidate state")
    #|  const badPath = { ...summary, devtools: { ...summary.devtools, evidence: "wrong.json" } }
    #|  if (!validate(report, badPath, evidence).problems.some((problem) => problem.includes("evidence path is not canonical"))) throw new Error("documentation self-test did not reject a stale evidence path")
    #|  const pendingRelease = validate(report, candidateSummary)
    #|  if (!pendingRelease.problems.some((problem) => problem.includes("evidence is pending"))) throw new Error("documentation self-test did not reject a release report with pending evidence")
    #|  const badReports = [
    #|    ["failed automated report", validate({ ...candidateReport, status: "failed" }, candidateSummary), "status is not passed"],
    #|    ["failed check in passed report", validate({ ...candidateReport, checks: [{ status: "failed" }] }, candidateSummary), "checks must all pass"],
    #|    ["missing release flag", validate({ ...candidateReport, release: undefined }, candidateSummary), "release flag is missing"],
    #|    ["candidate leaked evidence", validate(candidateReport, summary, evidence), "must keep Developer Tools pending"],
    #|    ["pending fingerprint leak", validate(candidateReport, { ...candidateSummary, devtools: { ...candidateSummary.devtools, artifactFingerprint: "private" } }), "must not retain"],
    #|    ["mismatched summary fingerprint", validate(candidateReport, { ...candidateSummary, automated: { status: "passed", artifactFingerprint: "stale" } }), "fingerprint differs"],
    #|    ["wrong manifest version", validate(candidateReport, candidateSummary, null, { ...manifest, rendererProtocolVersion: Number(protocolVersion) + 1 }), "manifest protocol version differs"],
    #|    ["development manifest", validate(candidateReport, candidateSummary, null, { ...manifest, pageBridgeEncoding: "debug" }), "release compact artifacts"],
    #|    ["wrong UI fixture name", fixtureReportProblems("minimoon_ui_showcase", candidateReport, candidateSummary, null, expected, manifest), "fixture name differs"],
    #|  ]
    #|  for (const [name, result, diagnostic] of badReports) {
    #|    if (!result.problems.some((problem) => problem.includes(diagnostic))) throw new Error(`documentation self-test did not reject ${name}`)
    #|  }
    #|  const statusLinks = fixtures.flatMap(({ directory }) =>
    #|    ["verify_report.json", "release_summary.json", "devtools.evidence.json"].map((file) => `[](../${directory}/generated/${file})`)).join("\n")
    #|  const policyStatus = `${statusLinks}\nReal-host evidence is local and Git-ignored.`
    #|  if (statusDocumentProblems("fixture.md", policyStatus, [release.state]).length !== 0) throw new Error("documentation self-test rejected release-independent evidence policy")
    #|  if (statusDocumentProblems("fixture.md", policyStatus, [candidate.state]).length !== 0) throw new Error("documentation self-test rejected candidate evidence policy")
    #|  if (!statusDocumentProblems("fixture.md", statusLinks, [candidate.state]).some((problem) => problem.includes("local and Git-ignored"))) throw new Error("documentation self-test did not require the local-evidence policy")
    #|  if (!statusDocumentProblems("fixture.md", policyStatus.replace(/.*ui\/examples\/showcase.*\n/g, ""), [candidate.state]).some((problem) => problem.includes("ui/examples/showcase"))) throw new Error("documentation self-test did not require UI fixture status links")
    #|  const completedStatus = `${policyStatus}\nLifecycle real-host validation and release verification are complete for the current generated bytes.`
    #|  if (!statusDocumentProblems("fixture.md", completedStatus, [release.state]).some((problem) => problem.includes("must not publish transient real-host completion"))) throw new Error("documentation self-test did not reject transient completion text")
    #|}
    #|
    #|if (mode === "--self-test") {
    #|  runSelfTest()
    #|  process.stdout.write("documentation validator self-test passed\n")
    #|  process.exit(0)
    #|}
    #|
    #|let markdown
    #|if (mode === "--archive-links") {
    #|  markdown = []
    #|  const collect = (directory) => {
    #|    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    #|      const file = path.join(directory, entry.name)
    #|      if (entry.isDirectory()) collect(file)
    #|      else if (entry.isFile() && entry.name.endsWith(".md")) markdown.push(posix(path.relative(root, file)))
    #|    }
    #|  }
    #|  collect(root)
    #|} else {
    #|  const listed = spawnSync("git", ["ls-files", "--cached", "--others", "--exclude-standard", "--", "*.md"], { cwd: root, encoding: "utf8" })
    #|  if (listed.error || listed.status !== 0) throw listed.error || new Error(`git ls-files exited with ${listed.status}: ${listed.stderr}`)
    #|  markdown = listed.stdout.split("\n").filter(Boolean).filter((relative) => fs.existsSync(absolute(relative)))
    #|}
    #|const markdownSet = new Set(markdown)
    #|
    #|const linkPattern = /!?\[[^\]]*\]\(([^)\n]+)\)/g
    #|for (const source of markdown) {
    #|  const content = read(source).replace(/```[\s\S]*?```/g, "")
    #|  for (const match of content.matchAll(linkPattern)) {
    #|    let target = match[1].trim()
    #|    if (target.startsWith("<")) {
    #|      const end = target.indexOf(">")
    #|      if (end >= 0) target = target.slice(1, end)
    #|    } else {
    #|      target = target.split(/\s+(?=["'])/, 1)[0]
    #|    }
    #|    if (/^(?:https?:|mailto:|tel:|data:|#|\/\/)/.test(target)) continue
    #|    target = target.split("#", 1)[0].split("?", 1)[0]
    #|    if (!target) continue
    #|    try { target = decodeURIComponent(target) } catch {}
    #|    const resolved = target.startsWith("/")
    #|      ? path.join(root, target.slice(1))
    #|      : path.resolve(path.dirname(absolute(source)), target)
    #|    if (mode === "--archive-links") {
    #|      const contained = (file) => file === root || file.startsWith(root + path.sep)
    #|      if (!contained(resolved) || (fs.existsSync(resolved) && !contained(fs.realpathSync(resolved)))) {
    #|        fail(`${source}: local Markdown link escapes archive: ${match[1]}`)
    #|        continue
    #|      }
    #|    }
    #|    const optionalPendingEvidence = mode !== "--archive-links" && fixtures.some(({ directory }) => resolved === absolute(`${directory}/generated/devtools.evidence.json`))
    #|    if (!fs.existsSync(resolved) && !optionalPendingEvidence) fail(`${source}: broken local Markdown link: ${match[1]}`)
    #|  }
    #|}
    #|if (mode === "--links-only" || mode === "--archive-links") {
    #|  if (errors.length) {
    #|    process.stderr.write(`${errors.join("\n")}\n`)
    #|    process.exit(1)
    #|  }
    #|  process.exit(0)
    #|}
    #|
    #|const docsIndex = read("docs/README.md")
    #|for (const active of markdown.filter((relative) => relative.startsWith("docs/") && relative !== "docs/README.md")) {
    #|  const fromIndex = path.relative(absolute("docs"), absolute(active)).split(path.sep).join("/")
    #|  const repositoryLink = `https://github.com/lucavance/minimoon/blob/main/${active}`
    #|  if (!docsIndex.includes(`(${fromIndex})`) && !docsIndex.includes(`(${repositoryLink})`)) fail(`docs/README.md does not index ${active}`)
    #|}
    #|
    #|const banned = [
    #|  "tooling_miniapp_v3",
    #|  "miniapp_dynamic_spike",
    #|  "performance_architecture_plan.md",
    #|  "miniapp_devtools_screenshots.md",
    #|  "fnv1a64-relpath-v1:",
    #|  "setting.es6=false",
    #|  "setting.enhance=false",
    #|  "setting.minified=false",
    #|  "internal_miniapp",
    #|]
    #|for (const source of markdown) {
    #|  const content = read(source)
    #|  const legacyReference = source === "CHANGELOG.md"
    #|  for (const token of banned) {
    #|    if (!legacyReference && content.includes(token)) fail(`${source}: stale documentation token: ${token}`)
    #|  }
    #|  if (!legacyReference) {
    #|    for (const problem of currentReferenceProblems(source, content, {
    #|      contractVersion,
    #|      runtimeVersion,
    #|      protocolVersion,
    #|    })) fail(problem)
    #|    for (const problem of authoringOwnershipProblems(source, content)) fail(problem)
    #|  }
    #|}
    #|const analysisRoot = "docs/code-analysis"
    #|const analysisDocuments = [
    #|  "README.md",
    #|  "01-SYSTEM-ARCHITECTURE.md",
    #|  "02-AUTHORING-MODEL.md",
    #|  "03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md",
    #|  "04-RENDERER-AND-DIFF.md",
    #|  "05-RUNTIME-AND-HOST-SCHEDULER.md",
    #|  "06-BUILD-VERIFY-AND-RELEASE.md",
    #|  "07-SYMBOL-INDEX.md",
    #|  "08-RISKS-TESTING-AND-PERFORMANCE.md",
    #|]
    #|const diagramRoot = `${analysisRoot}/assets/diagrams`
    #|const diagramReadme = `${diagramRoot}/README.md`
    #|const expectedAnalysisMarkdown = [
    #|  ...analysisDocuments.map((document) => `${analysisRoot}/${document}`),
    #|  diagramReadme,
    #|]
    #|const actualAnalysisMarkdown = markdown.filter((relative) => relative.startsWith(`${analysisRoot}/`))
    #|const expectedAnalysisSet = new Set(expectedAnalysisMarkdown)
    #|const actualAnalysisSet = new Set(actualAnalysisMarkdown)
    #|for (const expected of expectedAnalysisSet) {
    #|  if (!actualAnalysisSet.has(expected)) fail(`missing bilingual code-analysis document: ${expected}`)
    #|}
    #|for (const actual of actualAnalysisSet) {
    #|  if (!expectedAnalysisSet.has(actual)) fail(`unexpected bilingual code-analysis document: ${actual}`)
    #|}
    #|
    #|for (const relative of expectedAnalysisMarkdown) {
    #|  if (!fs.existsSync(absolute(relative))) continue
    #|  for (const problem of bilingualProblems(relative, read(relative))) fail(problem)
    #|}
    #|
    #|for (const document of analysisDocuments) {
    #|  const source = `${analysisRoot}/${document}`
    #|  if (!fs.existsSync(absolute(source))) continue
    #|  const content = read(source)
    #|  const markerLines = content
    #|    .split("\n")
    #|    .filter((line) => /^> \*\*(?:源码 \/ Source|生成产物 \/ Generated artifact):\*\*/.test(line))
    #|  if (/^0[1-8]-/.test(document) && markerLines.length === 0) fail(`${source}: no source provenance markers`)
    #|  for (const line of markerLines) {
    #|    if (line.includes("snapshot:")) fail(`${source}: source marker must not publish Git history`)
    #|    const links = [...line.matchAll(/\]\(([^)\n]+)\)/g)].map((match) => match[1])
    #|    if (links.length === 0) {
    #|      fail(`${source}: source marker has no source path`)
    #|      continue
    #|    }
    #|    const sourceTexts = []
    #|    for (const link of links) {
    #|      const resolved = path.resolve(path.dirname(absolute(source)), link)
    #|      const relative = posix(path.relative(root, resolved))
    #|      if (relative.startsWith("../") || path.isAbsolute(relative)) {
    #|        fail(`${source}: source marker escapes the repository: ${link}`)
    #|        continue
    #|      }
    #|      if (!fs.existsSync(absolute(relative))) {
    #|        fail(`${source}: source path is absent from the current tree: ${relative}`)
    #|      } else {
    #|        sourceTexts.push(read(relative))
    #|      }
    #|    }
    #|    const symbols = [...line.matchAll(/`([^`]+)`/g)]
    #|      .map((match) => match[1])
    #|      .filter((symbol) => !symbol.includes("/") && !/\.(?:mbt|mbti|js|json)$/.test(symbol) && !/^[0-9a-f]{40}$/.test(symbol))
    #|    if (symbols.length === 0 && !line.includes("public package surface")) fail(`${source}: source marker has no named symbol`)
    #|    for (const problem of missingSymbolProblems(source, sourceTexts.join("\n"), symbols)) fail(problem)
    #|  }
    #|}
    #|
    #|function extractMermaid(document, content) {
    #|  const diagrams = []
    #|  const lines = content.split("\n")
    #|  let heading = "Document overview / 文档总览"
    #|  let inside = false
    #|  let body = []
    #|  for (const line of lines) {
    #|    if (!inside && line.startsWith("## ")) heading = line.slice(3)
    #|    if (!inside && line === "```mermaid") {
    #|      inside = true
    #|      body = []
    #|    } else if (inside && line === "```") {
    #|      inside = false
    #|      const index = diagrams.length + 1
    #|      const stem = `${document.replace(/\.md$/, "")}-${index}`
    #|      diagrams.push({ document, index, heading, stem, mermaid: `${body.join("\n")}\n` })
    #|    } else if (inside) {
    #|      body.push(line)
    #|    }
    #|  }
    #|  if (inside) fail(`${analysisRoot}/${document}: unterminated Mermaid block`)
    #|  return diagrams
    #|}
    #|
    #|const extractedDiagrams = analysisDocuments.flatMap((document) => {
    #|  const relative = `${analysisRoot}/${document}`
    #|  return fs.existsSync(absolute(relative)) ? extractMermaid(document, read(relative)) : []
    #|})
    #|if (extractedDiagrams.length !== 21) fail(`expected 21 code-analysis diagrams, found ${extractedDiagrams.length}`)
    #|const manifestPath = `${diagramRoot}/manifest.json`
    #|let diagramManifest = null
    #|if (!fs.existsSync(absolute(manifestPath))) {
    #|  fail("code-analysis diagram manifest is missing")
    #|} else {
    #|  try { diagramManifest = JSON.parse(read(manifestPath)) } catch (error) { fail(`invalid code-analysis diagram manifest: ${error}`) }
    #|}
    #|if (diagramManifest) {
    #|  if (diagramManifest.schemaVersion !== 1) fail("code-analysis diagram manifest schema must be 1")
    #|  if (diagramManifest.renderer !== "@mermaid-js/mermaid-cli" || diagramManifest.rendererVersion !== "11.16.0") {
    #|    fail("code-analysis diagram renderer is not pinned to Mermaid CLI 11.16.0")
    #|  }
    #|  if (diagramManifest.scale !== 3 || diagramManifest.diagramCount !== 21 || !Array.isArray(diagramManifest.diagrams)) {
    #|    fail("code-analysis diagram manifest count or scale is invalid")
    #|  } else if (diagramManifest.diagrams.length !== extractedDiagrams.length) {
    #|    fail("code-analysis diagram manifest entries differ from extracted Mermaid blocks")
    #|  }
    #|  const expectedInventory = { source: [], svg: [], png: [] }
    #|  for (let index = 0; index < extractedDiagrams.length; index += 1) {
    #|    const diagram = extractedDiagrams[index]
    #|    const entry = diagramManifest.diagrams[index]
    #|    if (!entry) continue
    #|    const sourceName = `${diagram.stem}.mmd`
    #|    const svgName = `${diagram.stem}.svg`
    #|    const pngName = `${diagram.stem}.png`
    #|    expectedInventory.source.push(sourceName)
    #|    expectedInventory.svg.push(svgName)
    #|    expectedInventory.png.push(pngName)
    #|    const expected = {
    #|      document: diagram.document,
    #|      index: diagram.index,
    #|      heading: diagram.heading,
    #|      source: `source/${sourceName}`,
    #|      svg: `svg/${svgName}`,
    #|      png: `png/${pngName}`,
    #|      scale: 3,
    #|    }
    #|    for (const [key, value] of Object.entries(expected)) {
    #|      if (entry[key] !== value) fail(`${manifestPath}: ${diagram.stem} has invalid ${key}`)
    #|    }
    #|    const sourcePath = `${diagramRoot}/${expected.source}`
    #|    const svgPath = `${diagramRoot}/${expected.svg}`
    #|    const pngPath = `${diagramRoot}/${expected.png}`
    #|    if (!fs.existsSync(absolute(sourcePath)) || !fs.existsSync(absolute(svgPath)) || !fs.existsSync(absolute(pngPath))) {
    #|      fail(`${diagram.stem}: generated diagram files are missing`)
    #|      continue
    #|    }
    #|    const generatedSource = read(sourcePath)
    #|    for (const problem of diagramSourceProblems(sourcePath, diagram.mermaid, generatedSource)) fail(problem)
    #|    const sourceBytes = fs.readFileSync(absolute(sourcePath))
    #|    const svgBytes = fs.readFileSync(absolute(svgPath))
    #|    const pngBytes = fs.readFileSync(absolute(pngPath))
    #|    if (entry.sourceSha256 !== sha256(sourceBytes)) fail(`${sourcePath}: SHA-256 differs from manifest`)
    #|    if (entry.svgSha256 !== sha256(svgBytes)) fail(`${svgPath}: SHA-256 differs from manifest`)
    #|    if (entry.pngSha256 !== sha256(pngBytes)) fail(`${pngPath}: SHA-256 differs from manifest`)
    #|    const viewBox = svgViewBox(svgBytes.toString("utf8"))
    #|    if (!viewBox) {
    #|      fail(`${svgPath}: SVG viewBox is missing or invalid`)
    #|    } else if (entry.viewBox !== viewBox) {
    #|      fail(`${svgPath}: viewBox differs from manifest`)
    #|    }
    #|    const dimensions = pngDimensions(pngBytes)
    #|    if (!dimensions) {
    #|      fail(`${pngPath}: invalid PNG header`)
    #|    } else {
    #|      const [width, height] = dimensions
    #|      if (entry.pngWidth !== width || entry.pngHeight !== height) fail(`${pngPath}: dimensions differ from manifest`)
    #|      for (const problem of pngScaleProblems(pngPath, viewBox, width, height, 3)) fail(problem)
    #|    }
    #|  }
    #|  for (const kind of ["source", "svg", "png"]) {
    #|    const directory = `${diagramRoot}/${kind}`
    #|    const actual = fs.existsSync(absolute(directory)) ? fs.readdirSync(absolute(directory)) : []
    #|    for (const problem of inventoryProblems(directory, expectedInventory[kind], actual)) fail(problem)
    #|  }
    #|}
    #|
    #|if (!read("moon.mod").includes(`version = "${productVersion}"`)) fail("moon.mod product version differs from internal_versions")
    #|const uiModuleVersion = read("ui/moon.mod").match(/^version\s*=\s*"([^"]+)"/m)?.[1]
    #|if (!uiModuleVersion) fail("ui/moon.mod is missing its independent version")
    #|for (const problem of moduleVersionProblems("ui/moon.mod", read("ui/moon.mod"), { "lampclaw/minimoon": productVersion })) fail(problem)
    #|const moduleVersions = { "lampclaw/minimoon": productVersion, "lampclaw/minimoon_ui": uiModuleVersion }
    #|for (const source of ["README.mbt.md", "README.zh-CN.mbt.md", "ui/README.mbt.md"]) {
    #|  for (const problem of moduleVersionProblems(source, read(source), moduleVersions)) fail(problem)
    #|}
    #|for (const [source, mirror] of [["README.mbt.md", "README.md"], ["README.zh-CN.mbt.md", "README.zh-CN.md"], ["ui/README.mbt.md", "ui/README.md"]]) {
    #|  for (const problem of mirroredTextProblems(mirror, read(source), fs.existsSync(absolute(mirror)) ? read(mirror) : "")) fail(problem)
    #|}
    #|const fixtureInventory = fixtures.map(fixture => {
    #|  const config = JSON.parse(read(fixture.directory + "/miniapp.minimoon.json"))
    #|  return { ...fixture, link: fixture.directory.startsWith("examples/") ? fixture.name + "/README.md" : "../" + fixture.directory + "/README.md",
    #|    pages: config.pages.length, tabs: (config.tabBar?.list || []).map(tab => tab.text) }
    #|})
    #|for (const problem of fixtureIndexProblems("examples/README.md", read("examples/README.md"), fixtureInventory)) fail(problem)
    #|const primaryReadme = read("README.mbt.md")
    #|for (const readme of ["README.mbt.md", "README.zh-CN.mbt.md"]) {
    #|  const content = normalized(readme)
    #|  for (const token of [
    #|    productVersion, "3.17.0", "setting.es6=true", "setting.enhance=true", "setting.minified=true",
    #|    "docs/README.md", "docs/guides/miniapp_quickstart.md", "docs/project_status.md", "docs/roadmap.md",
    #|    "docs/architecture.md", "docs/operations/release_candidate_handoff.md", "docs/guides/http.md",
    #|    "docs/guides/shared_state.md", "docs/guides/native_navigation.md",
    #|    "minimoon init ../my-app --minimoon-root", "minimoon verify . --candidate", "my-app/dist/",
    #|    "src/pages/home/page.mbt", 'name: "My App"', "Hello My App", "create_variable", "count.view",
    #|  ]) {
    #|    if (!content.includes(token)) fail(readme + ": missing onboarding fact: " + token)
    #|  }
    #|  for (const problem of onboardingParityProblems(readme, primaryReadme, read(readme))) fail(problem)
    #|  for (const problem of fixtureReadmeProblems(readme, read(readme), fixtureInventory)) fail(problem)
    #|  for (const problem of currentFixtureProseProblems(readme, read(readme))) fail(problem)
    #|  for (const stale of ["setting.es6=false", "setting.enhance=false", "setting.minified=false"]) {
    #|    if (content.includes(stale)) fail(readme + ": stale Developer Tools setting: " + stale)
    #|  }
    #|}
    #|for (const problem of onboardingParityProblems("docs/guides/miniapp_quickstart.md", primaryReadme, read("docs/guides/miniapp_quickstart.md"))) fail(problem)
    #|for (const problem of currentFixtureProseProblems("CHANGELOG.md", read("CHANGELOG.md"))) fail(problem)
    #|// Advanced facts belong in their subject guides, not in the first-app landing page.
    #|const authoritativeFacts = {
    #|  "docs/architecture.md": [
    #|    "App Contract v" + contractVersion, "Runtime ABI v" + runtimeVersion, "renderer protocol v" + protocolVersion,
    #|    "App[Deps]", "Shared[T]", "PageContext.bind/select", "minimoon.app.js", "minimoon.templates.wxml", "app.wxss",
    #|    "generational", "transaction", "snapshot", "acknowledgement",
    #|  ],
    #|  "docs/guides/api_ergonomics.md": ["@minimoon.create_state", "@minimoon.no_cmd", "Emit[Msg]", "Val::map2", "create_state_with_input", "create_resource"],
    #|  "docs/guides/shared_state.md": ["program(deps : @application.Deps) -> @minimoon.Page", "App[Deps]", "Shared"],
    #|  "docs/operations/release_candidate_handoff.md": ["check:coverage", "check:candidate", "check:all", "check:mvp", "check:api", "moon package --frozen --list", "MINIMOON_CHECK_TMPDIR"],
    #|}
    #|for (const [document, tokens] of Object.entries(authoritativeFacts)) {
    #|  const content = normalized(document)
    #|  for (const token of tokens) if (!content.includes(token)) fail(document + ": missing canonical fact: " + token)
    #|}
    #|
    #|
    #|for (const active of [
    #|  "README.mbt.md",
    #|  "README.zh-CN.mbt.md",
    #|  "docs/reference/miniapp_host_capabilities.md",
    #|  "docs/guides/miniapp_quickstart.md",
    #|  "docs/guides/miniapp_authoring_example.md",
    #|  "docs/guides/api_ergonomics.md",
    #|  "docs/guides/subscription_scope.md",
    #|  "docs/guides/resource_state_design.md",
    #|]) {
    #|  const content = read(active)
    #|  for (const stale of [
    #|    "MiniappCommands",
    #|    "MiniappRoute",
    #|    "MiniappDecodeError",
    #|    "MiniappScrollDetail",
    #|    "MiniappCapability",
    #|    "MiniappPaymentParams",
    #|    "MiniappError",
    #|    "@minimoon.state(",
    #|    "@minimoon.state_with_input(",
    #|    "@minimoon.variable(",
    #|    "@minimoon.resource(",
    #|    "@minimoon.next(",
    #|    ".sender()",
    #|    "emit.emit(",
    #|  ]) {
    #|    if (content.includes(stale)) fail(`${active}: stale public API name: ${stale}`)
    #|  }
    #|}
    #|if (!fs.existsSync(absolute("src/README.mbt.md"))) fail("root package compile-checked authoring README is missing")
    #|
    #|const fixtureStates = []
    #|const exampleIndex = read("examples/README.md")
    #|for (const { name: fixture, directory } of fixtures) {
    #|  const fixtureReadme = `${directory}/README.md`
    #|  if (!markdownSet.has(fixtureReadme)) fail(`missing maintained fixture README: ${fixtureReadme}`)
    #|  if (directory.startsWith("examples/") && !exampleIndex.includes(`(${fixture}/README.md)`)) fail(`examples/README.md does not index ${fixture}`)
    #|  const reportPath = `${directory}/generated/verify_report.json`
    #|  const summaryPath = `${directory}/generated/release_summary.json`
    #|  const manifestPath = `${directory}/generated/manifest.json`
    #|  if (![reportPath, summaryPath, manifestPath].every((file) => fs.existsSync(absolute(file)))) {
    #|    fail(`${fixture}: generated verification reports are missing`)
    #|    continue
    #|  }
    #|  const report = JSON.parse(read(reportPath))
    #|  const summary = JSON.parse(read(summaryPath))
    #|  const manifest = JSON.parse(read(manifestPath))
    #|  const evidencePath = `${directory}/generated/devtools.evidence.json`
    #|  const evidence = report.release === true && fs.existsSync(absolute(evidencePath)) ? JSON.parse(read(evidencePath)) : null
    #|  const validation = fixtureReportProblems(fixture, report, summary, evidence, {
    #|    contractVersion,
    #|    runtimeVersion,
    #|    protocolVersion,
    #|  }, manifest)
    #|  for (const problem of validation.problems) fail(problem)
    #|  fixtureStates.push(validation.state)
    #|}
    #|for (const statusDocument of ["docs/project_status.md", "docs/roadmap.md"]) {
    #|  for (const problem of statusDocumentProblems(statusDocument, read(statusDocument), fixtureStates)) fail(problem)
    #|}
    #|
    #|if (errors.length) {
    #|  process.stderr.write(`${errors.join("\n")}\n`)
    #|  process.exit(1)
    #|}
    #|const liveStates = fixtureStates
    #|  .map((state) => `${state.fixture}=${state.phase}/${state.automated}/devtools-${state.devtools}`)
    #|  .join(", ")
    #|process.stdout.write(`checked ${markdown.length} Markdown files and ${fixtures.length} fixture reports; live state: ${liveStates}\n`)
    #|
  )
}
