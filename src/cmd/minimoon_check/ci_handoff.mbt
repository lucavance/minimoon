///|
fn ci_handoff_check_source() -> String {
  (
    #|const fs = require("node:fs")
    #|const path = require("node:path")
    #|const os = require("node:os")
    #|const assert = require("node:assert/strict")
    #|const { spawnSync } = require("node:child_process")
    #|const root = path.resolve(process.argv[2])
    #|const workflow = fs.readFileSync(path.join(root, ".github/workflows/test.yml"), "utf8")
    #|const blocks = [...workflow.matchAll(/^      - name: (.+)\n([\s\S]*?)(?=^      - name: |^  [a-z][a-z-]*:|$(?![\s\S]))/gm)]
    #|function scripts(name) {
    #|  return blocks.filter((block) => block[1] === name).map((block) => {
    #|    const run = block[2].match(/^        run: \|\n((?:^          .*\n|^\n)*)/m)
    #|    assert.ok(run, `${name}: expected a literal Bash run block`)
    #|    return run[1].replace(/^          /gm, "")
    #|  })
    #|}
    #|const packagers = scripts("Prepare WeChat Developer Tools handoffs")
    #|const cleanChecks = scripts("Final source cleanliness")
    #|assert.equal(packagers.length, 1, "both fixture handoffs need one reviewed packager")
    #|assert.equal(cleanChecks.length, 2, "both CI jobs need final cleanliness checks")
    #|assert.match(workflow, /name: minimoon-devtools-\$\{\{ github.sha \}\}\n\s+path: _build\/devtools-handoff\/core\//)
    #|assert.match(workflow, /name: minimoon-ui-devtools-\$\{\{ github.sha \}\}\n\s+path: _build\/devtools-handoff\/ui\//)
    #|const temporary = fs.mkdtempSync(path.join(os.tmpdir(), "minimoon-ci-handoff-"))
    #|const fixtures = [
    #|  ["examples/miniapp_conformance_app", "miniapp_conformance_app", "core"],
    #|  ["ui/examples/showcase", "minimoon_ui_showcase", "ui"],
    #|]
    #|const write = (base, relative, contents) => {
    #|  const target = path.join(base, relative)
    #|  fs.mkdirSync(path.dirname(target), { recursive: true })
    #|  fs.writeFileSync(target, contents)
    #|}
    #|const execute = (cwd, command, args, env = {}) => spawnSync(command, args, {
    #|  cwd, encoding: "utf8", env: { ...process.env, ...env }, maxBuffer: 8 * 1024 * 1024,
    #|})
    #|const requirePass = (result, label) => {
    #|  assert.equal(result.status, 0, `${label}: ${result.error || ""}\n${result.stdout}\n${result.stderr}`)
    #|}
    #|const git = (cwd, args) => {
    #|  const result = execute(cwd, "git", ["-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", ...args])
    #|  requirePass(result, `git ${args[0]}`)
    #|  return result.stdout.trim()
    #|}
    #|let cases = 0
    #|function sandbox(label) {
    #|  const directory = path.join(temporary, label)
    #|  fs.mkdirSync(directory)
    #|  for (const file of ["moon.mod", "ui/moon.mod", "docs/operations/miniapp_devtools_validation.md"]) {
    #|    write(directory, file, fs.readFileSync(path.join(root, file)))
    #|  }
    #|  for (const [fixture, name] of fixtures) {
    #|    fs.cpSync(path.join(root, fixture, "dist"), path.join(directory, fixture, "dist"), {
    #|      recursive: true,
    #|      filter: (source) => !/(?:^project\.private\.config\.json$|evidence|\.pem$|\.key$|\.log$)/.test(path.basename(source)),
    #|    })
    #|    for (const file of ["manifest.json", "smoke_checklist.json"]) {
    #|      write(directory, `${fixture}/generated/${file}`, fs.readFileSync(path.join(root, fixture, "generated", file)))
    #|    }
    #|    // These are isolated synthetic candidate fixtures, never real-host evidence.
    #|    // The static suite also runs after a local release verification or dev build.
    #|    const fingerprint = "fnv1a64-relpath-v2:0123456789abcdef"
    #|    write(directory, `${fixture}/generated/verify_report.json`, JSON.stringify({
    #|      schemaVersion: 1, status: "passed", release: false, artifactFingerprint: fingerprint,
    #|      checks: [{ name: "synthetic packaging control", status: "passed" }],
    #|    }))
    #|    write(directory, `${fixture}/generated/release_summary.json`, JSON.stringify({
    #|      name, schemaVersion: 11, runtimeApiVersion: 13, rendererProtocolVersion: 8, mode: "release",
    #|      automated: { status: "passed", pageCount: name === "miniapp_conformance_app" ? 7 : 6, artifactFingerprint: fingerprint },
    #|      devtools: { status: "pending", evidence: null },
    #|    }))
    #|    editJson(directory, `${fixture}/generated/manifest.json`, (value) => {
    #|      value.pageBridgeEncoding = "shared-compact-node-v1"
    #|    })
    #|  }
    #|  write(directory, ".gitignore", "_build/\n*.ignored\n")
    #|  git(directory, ["init", "-q"])
    #|  git(directory, ["add", "."])
    #|  git(directory, ["-c", "user.name=Minimoon CI test", "-c", "user.email=ci-test@example.invalid", "commit", "-qm", "synthetic fixture"])
    #|  return directory
    #|}
    #|function packageResult(directory) {
    #|  return execute(directory, "bash", ["-euo", "pipefail", "-c", packagers[0]], {
    #|    GITHUB_SHA: git(directory, ["rev-parse", "HEAD"]), RUNNER_OS: "Linux",
    #|  })
    #|}
    #|function reject(label, mutate, diagnostic) {
    #|  const directory = sandbox(label)
    #|  mutate(directory)
    #|  const result = packageResult(directory)
    #|  assert.notEqual(result.status, 0, `${label}: unsafe handoff unexpectedly succeeded`)
    #|  if (diagnostic) assert.match(result.stdout + result.stderr, diagnostic, label)
    #|  cases++
    #|}
    #|function editJson(directory, relative, mutate) {
    #|  const value = JSON.parse(fs.readFileSync(path.join(directory, relative), "utf8"))
    #|  mutate(value)
    #|  write(directory, relative, JSON.stringify(value))
    #|}
    #|function setCandidateFingerprint(directory, fixture, fingerprint) {
    #|  editJson(directory, fixture + "/generated/verify_report.json", (value) => { value.artifactFingerprint = fingerprint })
    #|  editJson(directory, fixture + "/generated/release_summary.json", (value) => { value.automated.artifactFingerprint = fingerprint })
    #|}
    #|function assertTechnicalVersions(handoff, manifest, summary, checklist) {
    #|  for (const [field, sourceField, expected] of [
    #|    ["appContract", "schemaVersion", 11],
    #|    ["runtimeAbi", "runtimeApiVersion", 13],
    #|    ["rendererProtocol", "rendererProtocolVersion", 8],
    #|  ]) {
    #|    assert.equal(handoff.versions[field], expected, `handoff ${field} must use the current version`)
    #|    for (const source of [manifest, summary, ...manifest.pages]) {
    #|      assert.equal(handoff.versions[field], source[sourceField], `handoff ${field} must match every generated contract`)
    #|    }
    #|    // Checklist schemaVersion is its document schema, not the App Contract.
    #|    if (field !== "appContract") assert.equal(handoff.versions[field], checklist[sourceField], `handoff ${field} must match its checklist`)
    #|  }
    #|}
    #|try {
    #|  // UInt64.to_string(radix=16) emits 1-16 digits without padding.
    #|  for (const hex of ["0", "a1a87d729b30dd0", "ffffffffffffffff"]) {
    #|    const directory = sandbox("fingerprint-" + hex.length)
    #|    const fingerprint = "fnv1a64-relpath-v2:" + hex
    #|    for (const [fixture] of fixtures) setCandidateFingerprint(directory, fixture, fingerprint)
    #|    requirePass(packageResult(directory), "unpadded " + hex.length + "-digit fingerprint")
    #|    for (const [, , bundle] of fixtures) {
    #|      const handoff = JSON.parse(fs.readFileSync(path.join(directory, "_build/devtools-handoff", bundle, "HANDOFF.json"), "utf8"))
    #|      assert.equal(handoff.artifactFingerprint, fingerprint, "handoff must preserve the producer's exact fingerprint")
    #|    }
    #|  }
    #|  const positive = sandbox("positive")
    #|  requirePass(packageResult(positive), "dual handoff positive control")
    #|  const commit = git(positive, ["rev-parse", "HEAD"])
    #|  for (const [fixture, name, bundle] of fixtures) {
    #|    const base = path.join(positive, "_build/devtools-handoff", bundle)
    #|    const handoff = JSON.parse(fs.readFileSync(path.join(base, "HANDOFF.json"), "utf8"))
    #|    assert.equal(handoff.appDirectory, fixture)
    #|    assert.equal(handoff.fixture, name)
    #|    assert.equal(handoff.commit, commit)
    #|    assert.equal(handoff.versions.minimoon, "0.2.0")
    #|    assert.equal(handoff.versions.minimoonUi, "0.1.0")
    #|    const manifest = JSON.parse(fs.readFileSync(path.join(base, "manifest.json"), "utf8"))
    #|    const summary = JSON.parse(fs.readFileSync(path.join(base, "release_summary.json"), "utf8"))
    #|    const checklist = JSON.parse(fs.readFileSync(path.join(base, "smoke_checklist.json"), "utf8"))
    #|    assertTechnicalVersions(handoff, manifest, summary, checklist)
    #|    for (const [field, stale] of [["appContract", 8], ["runtimeAbi", 10], ["rendererProtocol", 7]]) {
    #|      const oldHandoff = { ...handoff, versions: { ...handoff.versions, [field]: stale } }
    #|      assert.throws(() => assertTechnicalVersions(oldHandoff, manifest, summary, checklist), /must use the current version/)
    #|      cases++
    #|    }
    #|    for (const tool of ["moon", "node", "bun"]) assert.ok(handoff.toolchain[tool])
    #|    const sums = fs.readFileSync(path.join(base, "SHA256SUMS"), "utf8")
    #|    for (const file of ["manifest.json", "smoke_checklist.json", "verify_report.json", "release_summary.json", "HANDOFF.json", "VALIDATION.md", "dist/app.js", "dist/project.private.config.example.json"]) {
    #|      assert.ok(sums.includes(`  ${file}\n`), `handoff checksums omit ${file}`)
    #|    }
    #|    requirePass(execute(base, "sha256sum", ["--check", "--strict", "SHA256SUMS"]), "complete bundle hashes")
    #|    requirePass(execute(base, "sha256sum", ["--check", "--strict", "ARCHIVE_SHA256"]), "zip hash")
    #|    fs.appendFileSync(path.join(base, "manifest.json"), "\n")
    #|    assert.notEqual(execute(base, "sha256sum", ["--check", "--strict", "SHA256SUMS"]).status, 0, "tampered manifest accepted")
    #|    fs.appendFileSync(path.join(base, `${name}-dist.zip`), "tamper")
    #|    assert.notEqual(execute(base, "sha256sum", ["--check", "--strict", "ARCHIVE_SHA256"]).status, 0, "tampered ZIP accepted")
    #|    cases += 2
    #|  }
    #|  for (const [fixture, , bundle] of fixtures) {
    #|    for (const [label, fingerprint] of [
    #|      ["empty", ""],
    #|      ["empty-hex", "fnv1a64-relpath-v2:"],
    #|      ["oversized", "fnv1a64-relpath-v2:1234567890abcdef0"],
    #|      ["nonhex", "fnv1a64-relpath-v2:g"],
    #|      ["upper-hex", "fnv1a64-relpath-v2:ABCDEF"],
    #|      ["wrong-prefix", "fnv1a64-relpath-v1:0"],
    #|    ]) {
    #|      reject(bundle + "-fingerprint-" + label, (dir) => setCandidateFingerprint(dir, fixture, fingerprint))
    #|    }
    #|    reject(bundle + "-short-fingerprint-mismatch", (dir) => {
    #|      editJson(dir, fixture + "/generated/verify_report.json", (value) => { value.artifactFingerprint = "fnv1a64-relpath-v2:0" })
    #|    }, /fingerprints/)
    #|    const report = `${fixture}/generated/verify_report.json`
    #|    const summary = `${fixture}/generated/release_summary.json`
    #|    reject(`${bundle}-release`, (dir) => editJson(dir, report, (value) => { value.release = true }), /candidate verification reports only/)
    #|    reject(`${bundle}-failed-check`, (dir) => editJson(dir, report, (value) => { value.checks[0].status = "failed" }), /passed automated report/)
    #|    reject(`${bundle}-report-schema`, (dir) => editJson(dir, report, (value) => { value.schemaVersion = 0 }), /passed automated report/)
    #|    reject(`${bundle}-noncompact`, (dir) => editJson(dir, `${fixture}/generated/manifest.json`, (value) => { value.pageBridgeEncoding = "development" }), /matching versions/)
    #|    reject(`${bundle}-wrong-version`, (dir) => editJson(dir, summary, (value) => { value.runtimeApiVersion = 9 }), /matching versions/)
    #|    for (const [field, stale] of [["schemaVersion", 8], ["runtimeApiVersion", 10], ["rendererProtocolVersion", 7]]) {
    #|      reject(`${bundle}-old-summary-${field}`, (dir) => editJson(dir, summary, (value) => { value[field] = stale }), /matching versions/)
    #|      reject(`${bundle}-old-manifest-${field}`, (dir) => editJson(dir, `${fixture}/generated/manifest.json`, (value) => { value[field] = stale }), /matching versions/)
    #|      reject(`${bundle}-old-page-${field}`, (dir) => editJson(dir, `${fixture}/generated/manifest.json`, (value) => { value.pages[0][field] = stale }), /matching versions/)
    #|      if (field !== "schemaVersion") {
    #|        reject(`${bundle}-old-checklist-${field}`, (dir) => editJson(dir, `${fixture}/generated/smoke_checklist.json`, (value) => { value[field] = stale }), /matching versions/)
    #|      }
    #|    }
    #|    reject(`${bundle}-wrong-fingerprint`, (dir) => editJson(dir, summary, (value) => { value.automated.artifactFingerprint = "wrong" }), /fingerprints/)
    #|    reject(`${bundle}-private-evidence`, (dir) => editJson(dir, summary, (value) => { value.devtools.evidence = "private-input" }), /private-evidence-free/)
    #|    reject(`${bundle}-evidence-fingerprint`, (dir) => editJson(dir, summary, (value) => { value.devtools.artifactFingerprint = "private-fingerprint" }), /private-evidence-free/)
    #|    reject(`${bundle}-appid`, (dir) => editJson(dir, `${fixture}/dist/project.config.json`, (value) => { value.appid = `wx${"1".repeat(16)}` }), /placeholder AppID/)
    #|    reject(`${bundle}-template-appid`, (dir) => editJson(dir, `${fixture}/dist/project.private.config.example.json`, (value) => { value.appid = `wx${"1".repeat(16)}` }), /public private-config example/)
    #|    reject(`${bundle}-template-extra`, (dir) => editJson(dir, `${fixture}/dist/project.private.config.example.json`, (value) => { value.privateMetadata = "not-public" }), /public private-config example/)
    #|    reject(`${bundle}-private-file`, (dir) => {
    #|      write(dir, `${fixture}/dist/project.private.config.json`, "{}")
    #|      git(dir, ["add", "."])
    #|    }, /private, hidden/)
    #|    reject(`${bundle}-untracked-dist`, (dir) => write(dir, `${fixture}/dist/unreviewed.txt`, "unreviewed"), /committed dist files only/)
    #|    reject(`${bundle}-symlink`, (dir) => fs.symlinkSync("app.js", path.join(dir, fixture, "dist/linked.js")), /symlinks/)
    #|  }
    #|  reject("wrong-pair", (dir) => write(dir, "ui/moon.mod", 'version = "0.1.0"\nimport { "lampclaw/minimoon@0.1.1" }\n'), /reviewed core/)
    #|  reject("wrong-ui-resource-version", (dir) => editJson(dir, "ui/examples/showcase/generated/manifest.json", (value) => { value.resources[0].version = "0.0.0" }), /matching versions/)
    #|  reject("missing-ui", (dir) => fs.unlinkSync(path.join(dir, "ui/examples/showcase/generated/manifest.json")))
    #|  const coreManifest = "examples/miniapp_conformance_app/generated/manifest.json"
    #|  reject("core-missing-tab", (dir) => editJson(dir, coreManifest, (value) => { value.tabBar.list.pop() }), /matching versions/)
    #|  reject("core-tab-order", (dir) => editJson(dir, coreManifest, (value) => { value.tabBar.list.reverse() }), /matching versions/)
    #|  reject("core-missing-secondary", (dir) => editJson(dir, coreManifest, (value) => { value.pages = value.pages.filter((page) => page.route !== "pages/lab/lab") }), /matching versions/)
    #|  reject("core-replaced-secondary", (dir) => editJson(dir, coreManifest, (value) => { value.pages[5].route = "pages/unreviewed/unreviewed" }), /matching versions/)
    #|  reject("core-tab-host-drift", (dir) => editJson(dir, "examples/miniapp_conformance_app/dist/app.json", (value) => { value.tabBar.list[0].text = "unreviewed" }), /matching versions/)
    #|  for (const [index, script] of cleanChecks.entries()) {
    #|    const directory = sandbox(`clean-${index}`)
    #|    const check = () => execute(directory, "bash", ["-euo", "pipefail", "-c", script])
    #|    requirePass(check(), "clean source accepted")
    #|    write(directory, "local.ignored", "ignored developer input")
    #|    requirePass(check(), "ignored local input accepted")
    #|    write(directory, "untracked.mbt", "// new source\n")
    #|    assert.notEqual(check().status, 0, "untracked source accepted")
    #|    git(directory, ["add", "untracked.mbt"])
    #|    assert.notEqual(check().status, 0, "staged source accepted")
    #|    git(directory, ["-c", "user.name=Minimoon CI test", "-c", "user.email=ci-test@example.invalid", "commit", "-qm", "stage probe"])
    #|    write(directory, "untracked.mbt", "// modified tracked source\n")
    #|    assert.notEqual(check().status, 0, "modified tracked source accepted")
    #|    cases += 3
    #|  }
    #|  console.log(`CI handoff and cleanliness regression checks passed (${cases} negative cases)`)
    #|} finally {
    #|  fs.rmSync(temporary, { recursive: true, force: true })
    #|}
  )
}

///|
async fn ci_handoff_gate(root : String) -> Unit {
  let temp = check_temporary("minimoon-ci-check")
  let script = join(temp, "ci_handoff_check.cjs")
  @fs.write_file(
    script,
    ci_handoff_check_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let (code, stdout, stderr) = @process.collect_output(
    "bun",
    [script, root],
    cwd=root,
  )
  @fs.rmdir(temp, recursive=true)
  guard code == 0 else {
    abort("CI handoff regression failed:\n" + stdout.text() + stderr.text())
  }
  println(stdout.text().trim())
}
