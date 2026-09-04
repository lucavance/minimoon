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
    #|function fixtureReportProblems(fixture, report, summary, evidence, expected) {
    #|  const problems = []
    #|  const problem = (message) => problems.push(`${fixture}: ${message}`)
    #|  const fingerprint = report?.artifactFingerprint
    #|  const devtools = summary?.devtools
    #|  if (report?.schemaVersion !== 1) problem("verify_report schema must be 1")
    #|  if (report?.status !== "passed") problem("verify_report status is not passed")
    #|  if (typeof report?.release !== "boolean") problem("verify_report release flag is missing")
    #|  if (typeof fingerprint !== "string" || fingerprint.length === 0) problem("verify_report fingerprint is missing")
    #|  if (summary?.schemaVersion !== Number(expected.contractVersion)) problem("release_summary contract version differs from internal_versions")
    #|  if (summary?.runtimeApiVersion !== Number(expected.runtimeVersion)) problem("release_summary runtime version differs from internal_versions")
    #|  if (summary?.rendererProtocolVersion !== Number(expected.protocolVersion)) problem("release_summary protocol version differs from internal_versions")
    #|  if (summary?.name !== fixture) problem("release_summary fixture name differs from its directory")
    #|  if (summary?.mode !== "release") problem("release_summary does not describe release-mode bytes")
    #|  if (summary?.automated?.status !== report?.status) problem("release_summary status differs from verify_report")
    #|  if (summary?.automated?.artifactFingerprint !== fingerprint) problem("release_summary fingerprint differs from verify_report")
    #|  if (!devtools || typeof devtools !== "object") {
    #|    problem("release_summary DevTools state is missing")
    #|  } else if (devtools.status === "pending") {
    #|    if (devtools.evidence !== null) problem("pending release_summary must not name Developer Tools evidence")
    #|    if (devtools.artifactFingerprint != null) problem("pending release_summary must not retain a Developer Tools fingerprint")
    #|    if (report?.release === true) problem("release verification cannot be complete while Developer Tools evidence is pending")
    #|  } else if (devtools.status === "passed") {
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
    #|  const requiredLinks = [
    #|    "../examples/miniapp_conformance_app/generated/verify_report.json",
    #|    "../examples/miniapp_conformance_app/generated/release_summary.json",
    #|    "../examples/miniapp_conformance_app/generated/devtools.evidence.json",
    #|  ]
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
    #|function runSelfTest() {
    #|  const cases = [
    #|    ["missing English", bilingualProblems("fixture.md", "# 标题 / Title\n\n## 章节 / Section\n\n只有中文。\n"), "missing its English translation"],
    #|    ["stale symbol", missingSymbolProblems("fixture.md", "fn present() {}", ["missing"]), "stale source symbol"],
    #|    ["tampered Mermaid", diagramSourceProblems("fixture.mmd", "graph TD\n", "graph LR\n"), "Mermaid source drift"],
    #|    ["missing viewBox", pngScaleProblems("fixture.svg", null, 30, 30, 3), "viewBox is missing or invalid"],
    #|    ["wrong PNG scale", pngScaleProblems("fixture.png", "0 0 10 10", 29, 30, 3), "PNG scale mismatch"],
    #|    ["stale asset", inventoryProblems("fixture", ["one.svg"], ["one.svg", "old.svg"]), "stale or missing diagram assets"],
    #|  ]
    #|  for (const [name, problems, expected] of cases) {
    #|    if (!problems.some((problem) => problem.includes(expected))) throw new Error(`documentation self-test did not reject ${name}`)
    #|  }
    #|  const expected = { contractVersion: "7", runtimeVersion: "10", protocolVersion: "7" }
    #|  const report = { schemaVersion: 1, status: "passed", release: true, artifactFingerprint: "fixture-fingerprint" }
    #|  const summary = {
    #|    schemaVersion: 7,
    #|    runtimeApiVersion: 10,
    #|    rendererProtocolVersion: 7,
    #|    name: "fixture",
    #|    mode: "release",
    #|    automated: { status: "passed", artifactFingerprint: "fixture-fingerprint" },
    #|    devtools: { status: "passed", evidence: "generated/devtools.evidence.json", artifactFingerprint: "fixture-fingerprint" },
    #|  }
    #|  const evidence = {
    #|    schemaVersion: 1,
    #|    scope: "current-v7",
    #|    status: "passed",
    #|    app: "fixture",
    #|    recordedAt: "2026-09-04T05:50:00Z",
    #|    tool: "WeChat Developer Tools",
    #|    toolVersion: "fixture-version",
    #|    artifactFingerprint: "fixture-fingerprint",
    #|  }
    #|  const release = fixtureReportProblems("fixture", report, summary, evidence, expected)
    #|  if (release.problems.length !== 0 || release.state.phase !== "release") throw new Error("documentation self-test rejected a consistent release state")
    #|  const candidateReport = { ...report, release: false }
    #|  const candidateSummary = { ...summary, devtools: { status: "pending", evidence: null } }
    #|  const candidate = fixtureReportProblems("fixture", candidateReport, candidateSummary, null, expected)
    #|  if (candidate.problems.length !== 0 || candidate.state.phase !== "candidate") throw new Error("documentation self-test rejected a consistent candidate state")
    #|  const badPath = { ...summary, devtools: { ...summary.devtools, evidence: "wrong.json" } }
    #|  if (!fixtureReportProblems("fixture", report, badPath, evidence, expected).problems.some((problem) => problem.includes("evidence path is not canonical"))) throw new Error("documentation self-test did not reject a stale evidence path")
    #|  const pendingRelease = fixtureReportProblems("fixture", report, candidateSummary, null, expected)
    #|  if (!pendingRelease.problems.some((problem) => problem.includes("evidence is pending"))) throw new Error("documentation self-test did not reject a release report with pending evidence")
    #|  const statusLinks = [
    #|    "../examples/miniapp_conformance_app/generated/verify_report.json",
    #|    "../examples/miniapp_conformance_app/generated/release_summary.json",
    #|    "../examples/miniapp_conformance_app/generated/devtools.evidence.json",
    #|  ].map((link) => `[](${link})`).join("\n")
    #|  const policyStatus = `${statusLinks}\nReal-host evidence is local and Git-ignored.`
    #|  if (statusDocumentProblems("fixture.md", policyStatus, [release.state]).length !== 0) throw new Error("documentation self-test rejected release-independent evidence policy")
    #|  if (statusDocumentProblems("fixture.md", policyStatus, [candidate.state]).length !== 0) throw new Error("documentation self-test rejected candidate evidence policy")
    #|  if (!statusDocumentProblems("fixture.md", statusLinks, [candidate.state]).some((problem) => problem.includes("local and Git-ignored"))) throw new Error("documentation self-test did not require the local-evidence policy")
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
    #|const listed = spawnSync(
    #|  "git",
    #|  ["ls-files", "--cached", "--others", "--exclude-standard", "--", "*.md"],
    #|  { cwd: root, encoding: "utf8" },
    #|)
    #|if (listed.error || listed.status !== 0) {
    #|  throw listed.error || new Error(`git ls-files exited with ${listed.status}: ${listed.stderr}`)
    #|}
    #|const markdown = listed.stdout
    #|  .split("\n")
    #|  .filter(Boolean)
    #|  .filter((relative) => fs.existsSync(absolute(relative)))
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
    #|    const optionalPendingEvidence = resolved === absolute("examples/miniapp_conformance_app/generated/devtools.evidence.json")
    #|    if (!fs.existsSync(resolved) && !optionalPendingEvidence) fail(`${source}: broken local Markdown link: ${match[1]}`)
    #|  }
    #|}
    #|if (mode === "--links-only") {
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
    #|  "ABI v7",
    #|  "ABI-v7",
    #|  "protocol v3",
    #|  "protocol-v3",
    #|  "App Contract v4",
    #|  "runtime ABI v8",
    #|  "renderer protocol v4",
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
    #|for (const readme of ["README.mbt.md", "README.zh-CN.mbt.md"]) {
    #|  const content = normalized(readme)
    #|  for (const token of [
    #|    productVersion,
    #|    `App Contract v${contractVersion}`,
    #|    `runtime ABI v${runtimeVersion}`,
    #|    `renderer protocol v${protocolVersion}`,
    #|    "3.17.0",
    #|    "setting.es6=true",
    #|    "setting.enhance=true",
    #|    "setting.minified=true",
    #|    "check:coverage",
    #|    "check:all",
    #|    "check:mvp",
    #|    "docs/README.md",
    #|    "@minimoon.create_state",
    #|    "@minimoon.no_cmd",
    #|    "Emit[Msg]",
    #|    "minimoon.templates.wxml",
    #|    "app.wxss",
    #|  ]) {
    #|    if (!content.includes(token)) fail(`${readme}: missing canonical fact: ${token}`)
    #|  }
    #|  for (const stale of ["setting.es6=false", "setting.enhance=false", "setting.minified=false"]) {
    #|    if (content.includes(stale)) fail(`${readme}: stale Developer Tools setting: ${stale}`)
    #|  }
    #|}
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
    #|const fixtures = ["miniapp_conformance_app"]
    #|const fixtureStates = []
    #|const exampleIndex = read("examples/README.md")
    #|for (const fixture of fixtures) {
    #|  const fixtureReadme = `examples/${fixture}/README.md`
    #|  if (!markdownSet.has(fixtureReadme)) fail(`missing maintained fixture README: ${fixtureReadme}`)
    #|  if (!exampleIndex.includes(`(${fixture}/README.md)`)) fail(`examples/README.md does not index ${fixture}`)
    #|  const reportPath = `examples/${fixture}/generated/verify_report.json`
    #|  const summaryPath = `examples/${fixture}/generated/release_summary.json`
    #|  if (!fs.existsSync(absolute(reportPath)) || !fs.existsSync(absolute(summaryPath))) {
    #|    fail(`${fixture}: generated verification reports are missing`)
    #|    continue
    #|  }
    #|  const report = JSON.parse(read(reportPath))
    #|  const summary = JSON.parse(read(summaryPath))
    #|  const evidencePath = `examples/${fixture}/generated/devtools.evidence.json`
    #|  const evidence = fs.existsSync(absolute(evidencePath)) ? JSON.parse(read(evidencePath)) : null
    #|  const validation = fixtureReportProblems(fixture, report, summary, evidence, {
    #|    contractVersion,
    #|    runtimeVersion,
    #|    protocolVersion,
    #|  })
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
