///|
async fn generated_javascript(root : String, app : String) -> Array[String] {
  let manifest = read_json(root, "examples/" + app + "/generated/manifest.json")
  let javascript = [
    "examples/" + app + "/dist/app.js",
    "examples/" + app + "/dist/minimoon.host.js",
    "examples/" + app + "/dist/minimoon.protocol.js",
    "examples/" + app + "/dist/minimoon.initial.js",
    "examples/" + app + "/dist/minimoon.runtime.js",
  ]
  if json_field(manifest, "application") != Json::null() {
    javascript.push("examples/" + app + "/dist/minimoon.app.js")
  }
  match json_field(manifest, "pages") {
    Array(pages) =>
      for page in pages {
        javascript.push(
          "examples/" + app + "/dist/" + json_string(page, "route") + ".js",
        )
      }
    _ => abort(app + " manifest pages must be an array")
  }
  javascript
}

///|
fn javascript_audit_source() -> String {
  (
    #|import { parse } from "acorn"
    #|import { analyze } from "eslint-scope"
    #|import { readFileSync } from "node:fs"
    #|import assert from "node:assert/strict"
    #|import path from "node:path"
    #|
    #|const bigintLiteral = /\b(?:0[xX][\da-fA-F]+|0[bB][01]+|0[oO][0-7]+|[0-9]+)n\b/g
    #|const allowed = {
    #|  app: new Set(["App", "require"]),
    #|  application: new Set(["App", "Array", "Error", "JSON", "Map", "Number", "Promise", "Set", "clearInterval", "console", "globalThis", "module", "require", "setInterval", "undefined"]),
    #|  page: new Set(["require"]),
    #|  runtime: new Set([
    #|    "Array", "ArrayBuffer", "BigInt", "DataView", "Error", "JSON",
    #|    "Map", "Math", "Number", "Object", "Set", "String", "Uint8Array",
    #|    "Uint32Array", "exports", "globalThis", "setTimeout", "undefined",
    #|  ]),
    #|  host: new Set([
    #|    "Array", "Date", "Error", "JSON", "Map", "Math", "Number", "Object", "Page", "Set",
    #|    "Promise", "String", "clearInterval", "clearTimeout", "console", "getCurrentPages",
    #|    "globalThis", "module", "require", "setInterval", "setTimeout", "undefined", "wx",
    #|  ]),
    #|}
    #|const allowedGlobalThisProperties = {
    #|  app: new Set(), page: new Set(),
    #|  application: new Set(["__minimoonAppWakeV12"]),
    #|  host: new Set(["__minimoonRuntimeWakeV12", "__minimoonSharedWakeV12"]),
    #|  runtime: new Set(["crypto", "TextEncoder", "__minimoonRuntimeWakeV12", "__minimoonAppWakeV12", "__minimoonSharedWakeV12"]),
    #|}
    #|
    #|const kindOf = (file) => {
    #|  const name = path.basename(file)
    #|  if (name === "app.js") return "app"
    #|  if (name === "minimoon.app.js") return "application"
    #|  if (name === "minimoon.host.js") return "host"
    #|  if (name === "minimoon.protocol.js" || name === "minimoon.initial.js") return "host"
    #|  if (name === "minimoon.runtime.js") return "runtime"
    #|  return "page"
    #|}
    #|
    #|const memberName = (node) => {
    #|  if (!node.computed && node.property?.type === "Identifier") return node.property.name
    #|  if (node.computed && node.property?.type === "Literal" && typeof node.property.value === "string") return node.property.value
    #|  return null
    #|}
    #|
    #|const inspect = (source, kind, file) => {
    #|  const compatible = source.replace(bigintLiteral, "0")
    #|  const ast = parse(compatible, { ecmaVersion: 2019, sourceType: "script", ranges: true })
    #|  const scopes = analyze(ast, { ecmaVersion: 2019, sourceType: "script", optimistic: false, ignoreEval: true })
    #|  const globals = [...new Set(scopes.globalScope.through.map((reference) => reference.identifier.name))].sort()
    #|  const unexpected = globals.filter((name) => !allowed[kind].has(name))
    #|  if (unexpected.length) throw new Error(`${file}: unexpected ${kind} globals: ${unexpected.join(", ")}`)
    #|
    #|  const globalThisProperties = new Set()
    #|  const visit = (value) => {
    #|    if (!value || typeof value !== "object") return
    #|    if (Array.isArray(value)) { for (const child of value) visit(child); return }
    #|    if (value.type === "MemberExpression" && value.object?.type === "Identifier" && value.object.name === "globalThis") {
    #|      const property = memberName(value)
    #|      if (property === null) throw new Error(`${file}: dynamic globalThis property access is forbidden`)
    #|      globalThisProperties.add(property)
    #|    }
    #|    for (const [key, child] of Object.entries(value)) {
    #|      if (key !== "start" && key !== "end" && key !== "range" && key !== "loc") visit(child)
    #|    }
    #|  }
    #|  visit(ast)
    #|  const unexpectedProperties = [...globalThisProperties].filter((name) => !allowedGlobalThisProperties[kind].has(name)).sort()
    #|  if (unexpectedProperties.length) throw new Error(`${file}: unexpected globalThis properties: ${unexpectedProperties.join(", ")}`)
    #|  return { globals, globalThisProperties: [...globalThisProperties].sort() }
    #|}
    #|
    #|inspect("exports.value=Array.from([])", "runtime", "<positive-control>")
    #|for (const unsafe of ["new WebSocket('wss://invalid')", "new TextEncoder()"] ) {
    #|  let rejected = false
    #|  try { inspect(unsafe, "runtime", "<negative-control>") } catch { rejected = true }
    #|  if (!rejected) throw new Error(`host-global audit accepted unsafe source: ${unsafe}`)
    #|}
    #|
    #|let failed = false
    #|for (const file of process.argv.slice(1)) {
    #|  try {
    #|    const result = inspect(readFileSync(file, "utf8"), kindOf(file), file)
    #|    if (path.basename(file) === "minimoon.initial.js") {
    #|      const initial = require(path.resolve(file))
    #|      const manifest = JSON.parse(readFileSync(path.join(path.dirname(file), "../generated/manifest.json"), "utf8"))
    #|      for (let index = 0; index < manifest.pages.length; index++) {
    #|        assert.deepEqual(initial.minimoonInitialTree(index), {
    #|          kind: "view", identity: "root", text: "", props: {}, events: {}, children: [],
    #|        }, `${file}: host boot must not contain a preview tree`)
    #|      }
    #|      assert.throws(() => initial.minimoonInitialTree(manifest.pages.length), /unknown Minimoon initial tree/)
    #|    }
    #|    console.log(`${file}: globals=[${result.globals.join(",")}] globalThis=[${result.globalThisProperties.join(",")}]`)
    #|  } catch (error) {
    #|    console.error(error.message)
    #|    failed = true
    #|  }
    #|}
    #|if (failed) process.exit(1)
    #|
  )
}

///|
async fn audit_generated_javascript(root : String, mode : String) -> Unit {
  for app in example_apps {
    let args = ["-e", javascript_audit_source()]
    let display_args = ["-e", "<inline MiniApp syntax and host-global audit>"]
    for file in generated_javascript(root, app) {
      args.push(file)
      display_args.push(file)
    }
    run(
      root,
      "MiniApp JavaScript compatibility (" + mode + "): " + app,
      "bun",
      args,
      display_args~,
    )
  }
}

///|
async fn codegen_suite(root : String) -> Unit {
  build_examples(root, "release")
  verify_examples(root, false)
  let first = artifact_snapshot(root)
  build_examples(root, "release")
  verify_examples(root, false)
  let second = artifact_snapshot(root)
  guard first == second else {
    abort("MiniApp generation is not stable across consecutive builds")
  }
  audit_generated_javascript(root, "release")
  for app in example_apps {
    let base = "examples/" + app + "/generated/"
    for
      file in [
        "manifest.json", "diagnostics.json", "expected_set_data.json", "smoke_checklist.json",
        "release_summary.json", "verify_report.json",
      ] {
      let _ = read_json(root, base + file)
    }
  }
  for
    marker in [
      "workbench-hero", "saved-drafts", "work-laboratory", "work-echo", "storage-status",
      "request-lifecycle-state", "request-output", "draft-editor", "interaction-native",
      "composed-controls", "platform-http", "application-controls", "dynamic-lab",
      "component-lab", "control-lab",
    ] {
    require_text(
      root, "examples/miniapp_draft_workbench/dist/minimoon.runtime.js", marker,
    )
    forbid_text(
      root, "examples/miniapp_draft_workbench/dist/minimoon.initial.js", marker,
    )
  }
  require_text(
    root, "examples/miniapp_draft_workbench/dist/minimoon.runtime.js", "https://echo.apifox.com",
  )
  forbid_text(
    root, "examples/miniapp_draft_workbench/dist/minimoon.runtime.js", "httpbingo.org",
  )
  forbid_text(
    root, "examples/miniapp_draft_workbench/dist/minimoon.runtime.js", "https://example.com/api/profile",
  )
  require_text(
    root, "examples/miniapp_draft_workbench/generated/smoke_checklist.json", "Runtime Lab native input focus, blur, and confirm",
  )
  require_text(
    root, "examples/miniapp_draft_workbench/generated/smoke_checklist.json", "Interaction Dropdown checkbox, radio, submenu action, and dismiss",
  )
  require_text(
    root, "examples/miniapp_draft_workbench/styles/tailwind.css", "@source not \"../src/**/*_test.mbt\"",
  )
  forbid_text(
    root, "examples/miniapp_draft_workbench/dist/app.wxss", ".transition {",
  )
  run(root, "Embedded template drift", "moon", [
    "run", "src/cmd/minimoon_template_generate", "--target", "native",
  ])
  let template = @fs.read_file(
    join(root, "src/cmd/minimoon/templates.generated.mbt"),
  ).text()
  run(root, "Embedded template stability", "moon", [
    "run", "src/cmd/minimoon_template_generate", "--target", "native",
  ])
  guard template ==
    @fs.read_file(join(root, "src/cmd/minimoon/templates.generated.mbt")).text() else {
    abort("embedded template generation is not formatter-stable")
  }
  ui_gallery_codegen_gate(root)
}

///|
let registry_root_files : Array[String] = [
  "CHANGELOG.md", "LICENSE", "README.mbt.md", "README.md", "README.zh-CN.md", "THIRD_PARTY_NOTICES.md",
  "moon.mod",
]

///|
let registry_documentation_files : Array[String] = [
  "docs/guides/http.md", "docs/README.md", "docs/architecture.md", "docs/guides/api_ergonomics.md",
  "docs/guides/native_navigation.md", "docs/guides/keyed_children_diff.md", "docs/guides/miniapp_authoring_example.md",
  "docs/guides/miniapp_quickstart.md", "docs/guides/resource_state_design.md", "docs/guides/shared_state.md",
  "docs/guides/subscription_scope.md", "docs/guides/testing_and_components.md", "docs/mvp.md",
  "docs/operations/dogfood.md", "docs/operations/miniapp_devtools_validation.md",
  "docs/operations/miniapp_javascript_compatibility.md", "docs/operations/release_candidate_handoff.md",
  "docs/positioning.md", "docs/reference/compatibility_and_upgrades.md", "docs/reference/miniapp_fixture_matrix.md",
  "docs/reference/miniapp_host_capabilities.md",
]

///|
let registry_source_directories : Array[String] = [
  "src/http", "src", "src/cmd/minimoon", "src/components", "src/components/styles",
  "src/internal_any", "src/internal_duplix", "src/internal_host_js", "src/internal_slotmap",
  "src/internal_versions", "src/renderer_miniapp", "src/resources", "src/runtime_core",
  "src/internal_png", "src/testing", "src/tooling_miniapp", "src/tooling_minimoon_build",
  "src/tooling_minimoon_verify", "src/ui_dsl", "src/val_runtime",
]

///|
fn registry_source_filename_allowed(filename : String) -> Bool {
  filename == "moon.pkg" ||
  filename.has_suffix(".mbti") ||
  (
    filename.has_suffix(".mbt") &&
    !filename.has_suffix("_test.mbt") &&
    !filename.has_suffix("_wbtest.mbt") &&
    !filename.has_suffix("_bench.mbt")
  )
}

///|
fn registry_source_path_allowed(path : String) -> Bool {
  if path == "src/README.mbt.md" {
    return true
  }
  for directory in registry_source_directories {
    let prefix = directory + "/"
    if path.has_prefix(prefix) {
      let filename = path[prefix.length():]
      if !filename.contains("/") &&
        registry_source_filename_allowed(filename.to_owned()) {
        return true
      }
    }
  }
  false
}

///|
fn registry_package_path_allowed(path : String) -> Bool {
  registry_root_files.contains(path) ||
  registry_documentation_files.contains(path) ||
  registry_source_path_allowed(path)
}

///|
fn registry_package_paths(listing : String) -> Array[String] {
  let paths : Array[String] = []
  let mut collecting = false
  for raw_line in listing.split("\n") {
    let line = raw_line.trim().to_owned()
    if line == "Check passed" {
      collecting = true
      continue
    }
    if line.has_prefix("Package to ") {
      break
    }
    if collecting && line != "" {
      paths.push(line)
    }
  }
  paths
}

///|
async fn distribution_package_gate(root : String, temp : String) -> Unit {
  println("\n==> Registry package allowlist")
  println("$ moon package --frozen --list")
  let (code, stdout, stderr) = @process.collect_output(
    "moon",
    ["package", "--frozen", "--list"],
    cwd=root,
  ) catch {
    err => abort("failed to package Minimoon: \{err}")
  }
  let listing = stdout.text() + "\n" + stderr.text()
  guard code == 0 else { abort("moon package failed:\n" + listing) }
  let packaged_paths = registry_package_paths(listing)
  guard !packaged_paths.is_empty() else {
    abort("moon package did not report any packaged paths")
  }
  for
    required in [
      "moon.mod", "LICENSE", "CHANGELOG.md", "README.mbt.md", "README.md", "README.zh-CN.md",
      "src/README.mbt.md", "src/pkg.generated.mbti", "src/cmd/minimoon/main.mbt",
      "src/cmd/minimoon/templates.generated.mbt", "docs/guides/shared_state.md",
    ] {
    guard packaged_paths.contains(required) else {
      abort("registry package is missing required path: " + required)
    }
  }
  for path in packaged_paths {
    guard registry_package_path_allowed(path) else {
      abort("registry package contains a path outside the allowlist: " + path)
    }
  }
  let archive = join(
    root,
    "_build/publish/lampclaw-minimoon-" + @versions.product_version() + ".zip",
  )
  require_file(
    root,
    "_build/publish/lampclaw-minimoon-" + @versions.product_version() + ".zip",
  )
  let archive_size = @fs.read_file(archive).binary().length()
  let hard_limit = registry_archive_hard_limit
  let operating_limit = registry_archive_operating_limit
  let reserve_kib = (registry_archive_reserve / 1024).to_string()
  guard byte_budget_allows(archive_size, operating_limit) else {
    abort(
      "registry package must retain at least " +
      reserve_kib +
      " KiB reserve under the " +
      (hard_limit / 1024).to_string() +
      " KiB hard cap: " +
      archive_size.to_string() +
      " / " +
      operating_limit.to_string() +
      " bytes",
    )
  }
  println(
    "registry archive: " +
    archive_size.to_string() +
    " / " +
    operating_limit.to_string() +
    " operating bytes (" +
    reserve_kib +
    " KiB reserved below " +
    hard_limit.to_string() +
    ")",
  )

  let distribution = join(temp, "distribution")
  let package_root = join(distribution, "package")
  let consumer = join(distribution, "consumer")
  let package_bin = join(distribution, "bin")
  @fs.mkdir(package_root, permission=0o755, recursive=true)
  @fs.mkdir(package_bin, permission=0o755, recursive=true)
  run(root, "Unpack registry candidate", "unzip", [
    "-q", archive, "-d", package_root,
  ])
  archive_documentation_self_test(root, distribution)
  archive_documentation_gate(root, distribution, package_root, "core")
  run(
    root,
    "Install CLI from registry candidate",
    "moon",
    ["install", "--bin", package_bin, "--path", "src/cmd/minimoon"],
    cwd=package_root,
  )
  let package_executable = join(package_bin, "minimoon")
  run(
    root,
    "Initialize registry consumer from packaged CLI",
    package_executable,
    ["init", consumer],
    cwd=distribution,
  )
  guard !@fs.exists(join(consumer, "moon.work")) else {
    abort("packaged CLI emitted a local workspace in registry mode")
  }
  require_text(
    consumer,
    "moon.mod",
    ("lampclaw/minimoon@" + @versions.product_version()).escape(),
  )
  run(
    root,
    "Packaged registry consumer formatting",
    "moon",
    ["fmt", "--check"],
    cwd=consumer,
  )
  @fs.symlink(
    target=join(root, "node_modules"),
    join(consumer, "node_modules"),
    force_symlink=true,
  )
  run(
    root,
    "Inject temporary package-consumer workspace",
    "moon",
    ["work", "init", "package", "consumer"],
    cwd=distribution,
  )
  run(
    root,
    "Packaged registry consumer check",
    "moon",
    ["check", "--deny-warn"],
    cwd=distribution,
  )
  run(
    root,
    "Packaged registry consumer build",
    package_executable,
    ["build", consumer],
    cwd=consumer,
  )
  run(
    root,
    "Packaged registry consumer verify",
    package_executable,
    ["verify", consumer, "--candidate"],
    cwd=consumer,
  )
  ui_distribution_package_gate(root, distribution, package_executable)
}

///|
async fn generator_suite(root : String) -> Unit {
  let temp = check_temporary("minimoon-generator")
  let bin = join(temp, "bin")
  let repository_package = read_json(root, "package.json")
  let repository_dev_dependencies = json_field(
    repository_package, "devDependencies",
  )
  let repository_engines = json_field(repository_package, "engines")
  let repository_package_manager = json_field(
    json_field(repository_package, "devEngines"),
    "packageManager",
  )
  let repository_overrides = json_field(repository_package, "overrides")
  guard json_string(repository_engines, "node") == supported_node_engine else {
    abort("repository engines.node must be " + supported_node_engine)
  }
  @fs.mkdir(bin, permission=0o755, recursive=true)
  run(root, "Install native minimoon CLI", "moon", [
    "install", "--bin", bin, "--path", "src/cmd/minimoon",
  ])
  let executable = join(bin, "minimoon")
  run(root, "Installed CLI help", executable, ["--help"])
  run(root, "Installed CLI version", executable, ["--version"])
  require_command_failure(
    "Invalid CLI arguments",
    executable,
    ["init"],
    root,
    "init requires an app directory",
  )
  for removed in ["counter", "profile", "minimal"] {
    require_command_failure(
      "Removed " + removed + " template",
      executable,
      [
        "init",
        join(temp, "removed-" + removed),
        "--template",
        removed,
        "--minimoon-root",
        root,
      ],
      root,
      "was removed; use --template starter",
    )
  }
  let default_alias = join(temp, "default-alias")
  run(root, "Initialize default alias", executable, [
    "init", default_alias, "--template", "default", "--minimoon-root", root,
  ])
  require_text(default_alias, "miniapp.minimoon.json", "src/pages/home")
  require_text(default_alias, "miniapp.minimoon.json", "src/pages/details")
  require_file(default_alias, "moon.work")
  require_text(default_alias, "README.md", "local Minimoon checkout")
  let registry_app = join(temp, "registry-starter")
  run(
    root,
    "Initialize standalone registry template",
    executable,
    ["init", registry_app],
    cwd=temp,
  )
  guard !@fs.exists(join(registry_app, "moon.work")) else {
    abort("standalone registry template must not contain moon.work")
  }
  require_text(
    registry_app,
    "moon.mod",
    ("lampclaw/minimoon@" + @versions.product_version()).escape(),
  )
  require_text(registry_app, "README.md", "MoonBit package registry")
  forbid_text(registry_app, "README.md", "local source checkout by `moon.work`")
  guard !@fs.exists(join(registry_app, ".node-version")) else {
    abort("standalone registry template must not contain .node-version")
  }
  run(
    root,
    "Standalone registry template formatting",
    "moon",
    ["fmt", "--check"],
    cwd=registry_app,
  )
  require_command_failure(
    "Mutually exclusive candidate and release verification",
    executable,
    ["verify", registry_app, "--candidate", "--release"],
    registry_app,
    "either --candidate or --release",
  )
  for template in ["starter"] {
    let app = join(temp, template)
    run(root, "Initialize " + template + " template", executable, [
      "init", app, "--minimoon-root", root,
    ])
    for
      file in [
        "moon.mod", "moon.work", "miniapp.minimoon.json", "package.json", "README.md",
        ".gitignore", "styles/tailwind.css",
      ] {
      guard @fs.exists(join(app, file)) else {
        abort(template + " template is missing " + file)
      }
    }
    for
      ignored in [
        "_build/", ".mooncakes/", ".minimoon-tmp/", "node_modules/", "dist/", "generated/",
        "styles/app.wxss", "*.log", ".env", ".env.*",
      ] {
      require_text(app, ".gitignore", ignored)
    }
    let product_version = @versions.product_version()
    require_text(app, "moon.mod", "version = " + product_version.escape())
    require_text(
      app,
      "moon.mod",
      ("lampclaw/minimoon@" + product_version).escape(),
    )
    guard !@fs.exists(join(app, ".node-version")) else {
      abort(template + " template must not contain .node-version")
    }
    let generated_package = read_json(app, "package.json")
    let generated_dev_dependencies = json_field(
      generated_package, "devDependencies",
    )
    for
      dependency in [
        "@tailwindcss/cli", "postcss", "tailwindcss", "weapp-tailwindcss",
      ] {
      guard json_string(generated_dev_dependencies, dependency) ==
        json_string(repository_dev_dependencies, dependency) else {
        abort(template + " template has stale dependency " + dependency)
      }
    }
    guard json_string(json_field(generated_package, "engines"), "node") ==
      json_string(repository_engines, "node") else {
      abort(template + " template has stale Node engine")
    }
    let generated_package_manager = json_field(
      json_field(generated_package, "devEngines"),
      "packageManager",
    )
    for field in ["name", "version", "onFail"] {
      guard json_string(generated_package_manager, field) ==
        json_string(repository_package_manager, field) else {
        abort(template + " template has stale package manager " + field)
      }
    }
    guard json_string(json_field(generated_package, "overrides"), "postcss") ==
      json_string(repository_overrides, "postcss") else {
      abort(template + " template has stale PostCSS override")
    }
    guard !@fs.exists(join(app, "_minimoon")) &&
      !@fs.exists(join(app, "src/cmd")) else {
      abort(template + " template contains a removed V1 directory")
    }
    if template == "starter" {
      require_command_failure(
        "Missing application dependencies",
        executable,
        ["build", app],
        app,
        "Run `bun install` in the Minimoon app directory",
      )
      guard !@fs.exists(join(app, ".minimoon-tmp")) else {
        abort("dependency lookup failure left .minimoon-tmp behind")
      }
    }
    let tailwind = @fs.read_file(join(app, "styles/tailwind.css")).text()
    guard !tailwind.contains("tooling_miniapp") &&
      !tailwind.contains("scripts/") else {
      abort(template + " template leaks Minimoon repository Tailwind sources")
    }
    @fs.symlink(
      target=join(root, "node_modules"),
      join(app, "node_modules"),
      force_symlink=true,
    )
    if template == "starter" {
      let input = join(app, "styles/tailwind.css")
      @fs.write_file(
        input,
        "@import \"definitely-missing-minimoon-test.css\";\n" + tailwind,
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
      require_command_failure(
        "Tailwind failure cleanup",
        executable,
        ["build", app],
        app,
        "Tailwind generation failed",
      )
      guard !@fs.exists(join(app, ".minimoon-tmp")) &&
        !@fs.exists(join(app, "styles/.minimoon-tailwind-input.css")) else {
        abort("Tailwind failure left temporary files behind")
      }
      @fs.write_file(
        input,
        tailwind,
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
    }
    run(root, template + " template build", executable, ["build", app], cwd=app)
    let starter_manifest = read_json(app, "generated/manifest.json")
    let starter_runtime = @fs.read_file(join(app, "dist/minimoon.runtime.js"))
      .binary()
      .length()
    let starter_host = @fs.read_file(join(app, "dist/minimoon.host.js"))
      .binary()
      .length()
    let starter_protocol = @fs.read_file(join(app, "dist/minimoon.protocol.js"))
      .binary()
      .length()
    let starter_initial = @fs.read_file(join(app, "dist/minimoon.initial.js"))
      .binary()
      .length()
    guard byte_budget_allows(starter_runtime, starter_runtime_limit) else {
      abort(
        "starter runtime exceeds byte budget: actual=" +
        starter_runtime.to_string() +
        " bytes, limit=" +
        starter_runtime_limit.to_string() +
        " bytes",
      )
    }
    let starter_host_limit = shared_host_limit(false)
    guard byte_budget_allows(starter_host, starter_host_limit) else {
      abort(
        "starter host exceeds " +
        starter_host_limit.to_string() +
        "-byte budget",
      )
    }
    guard starter_protocol <= 10000 else {
      abort("starter protocol exceeds 10000-byte budget")
    }
    guard starter_initial <= 36000 else {
      abort("starter initial tree exceeds 36000-byte budget")
    }
    guard json_string(starter_manifest, "pageBridgeEncoding") ==
      "shared-compact-node-v1" else {
      abort("starter must use the shared compact page bridge encoding")
    }
    guard @fs.read_file(join(app, "dist/minimoon.templates.wxml"))
      .binary()
      .length() <=
      20000 else {
      abort("starter shared WXML exceeds 20000-byte budget")
    }
    guard @fs.read_file(join(app, "dist/app.wxss")).binary().length() <= 9500 else {
      abort("starter application WXSS exceeds 9500-byte budget")
    }
    let starter_aggregate = Ref(
      starter_runtime +
      starter_host +
      starter_protocol +
      starter_initial +
      @fs.read_file(join(app, "dist/app.js")).binary().length(),
    )
    match json_field(starter_manifest, "pages") {
      Array(pages) =>
        for page in pages {
          let route = json_string(page, "route")
          starter_aggregate.val += @fs.read_file(
              join(app, "dist/" + route + ".js"),
            )
            .binary()
            .length()
          guard @fs.read_file(join(app, "dist/" + route + ".wxml"))
            .binary()
            .length() <=
            1024 else {
            abort("starter page WXML exceeds 1024-byte budget: " + route)
          }
          guard @fs.read_file(join(app, "dist/" + route + ".wxss"))
            .binary()
            .length() ==
            0 else {
            abort("starter page WXSS must remain empty: " + route)
          }
        }
      _ => abort("starter manifest pages must be an array")
    }
    guard byte_budget_allows(starter_aggregate.val, starter_javascript_limit) else {
      abort(
        "starter aggregate JavaScript exceeds byte budget: actual=" +
        starter_aggregate.val.to_string() +
        " bytes, limit=" +
        starter_javascript_limit.to_string() +
        " bytes",
      )
    }
    if template == "starter" {
      let page_file = join(app, "src/pages/home/page.mbt")
      onboarding_gate(root, app, executable)
      let page_source = @fs.read_file(page_file).text()
      let dist_app = @fs.read_file(join(app, "dist/app.json")).text()
      @fs.write_file(
        page_file,
        page_source + "\nthis is not valid MoonBit\n",
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
      require_command_failure(
        "Page compile diagnostic",
        executable,
        ["build", app],
        app,
        "MMN2001",
      )
      require_text(app, "generated/diagnostics.json", "MMN2001")
      guard @fs.read_file(join(app, "dist/app.json")).text() == dist_app else {
        abort("page compile failure changed the last valid dist")
      }
      @fs.write_file(
        page_file,
        page_source,
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
      run(
        root,
        "Starter template rebuild after diagnostic",
        executable,
        ["build", app],
        cwd=app,
      )
      run(
        root,
        "Add page scaffold",
        executable,
        [
          "add", "page", "activity_log", "--after", "home", "--title", "Activity Log",
        ],
        cwd=app,
      )
      require_file(app, "src/pages/activity_log/page.mbt")
      require_file(app, "src/pages/activity_log/page_test.mbt")
      require_text(app, "miniapp.minimoon.json", "src/pages/activity_log")
      require_command_failure(
        "Duplicate page scaffold",
        executable,
        ["add", "page", "activity_log"],
        app,
        "page already exists",
      )
      run(
        root,
        "Add component scaffold",
        executable,
        ["add", "component", "status_badge", "--page", "home"],
        cwd=app,
      )
      require_file(app, "src/components/status_badge/component.mbt")
      require_file(app, "src/components/status_badge/component_test.mbt")
      require_file(app, "src/pages/home/status_badge.component.mbt")
      require_text(
        app, "src/pages/home/moon.pkg", "lampclaw/starter/components/status_badge",
      )
      require_text(
        app, "src/components/status_badge/component.mbt", "@minimoon.create_pure_state",
      )
      require_text(
        app, "src/components/status_badge/component.mbt", "props.view2(model",
      )
      require_text(
        app, "src/components/status_badge/component.mbt", "emit(Increment)",
      )
      for
        initialization in [
          "definition.create_runtime().unwrap()", "runtime.lifecycle(\"onLoad\", \"{}\")",
          "runtime.lifecycle(\"onShow\", \"{}\")",
        ] {
        require_text(
          app, "src/components/status_badge/component_test.mbt", initialization,
        )
      }
      for
        stale in [
          "@minimoon.state(", "@minimoon.next(", ".sender()", ".value()",
        ] {
        forbid_text(app, "src/components/status_badge/component.mbt", stale)
      }
      require_command_failure(
        "Duplicate component scaffold",
        executable,
        ["add", "component", "status_badge", "--page", "home"],
        app,
        "component already exists",
      )
      run(
        root,
        "Starter template build after scaffolding",
        executable,
        ["build", app],
        cwd=app,
      )
      require_file(app, "dist/pages/activity_log/activity_log.js")
    }
    require_file(app, "dist/project.private.config.example.json")
    let generated_project = read_json(app, "dist/project.config.json")
    let private_example = read_json(
      app, "dist/project.private.config.example.json",
    )
    guard json_string(generated_project, "appid") == "touristappid" &&
      json_bool(json_field(generated_project, "setting"), "es6") &&
      json_bool(json_field(generated_project, "setting"), "enhance") &&
      json_bool(json_field(generated_project, "setting"), "minified") &&
      json_string(private_example, "appid") == "xxxxx-your-wechat-miniapp-appid" &&
      json_string(private_example, "libVersion") == "3.17.0" else {
      abort(template + " template project AppID ownership is invalid")
    }
    forbid_text(app, "dist/project.private.config.example.json", "\"setting\"")
    forbid_text(app, "dist/app.json", "navigationBarTitleText")
    guard !@fs.exists(join(app, "dist/project.private.config.json")) else {
      abort(template + " template generated a local private project config")
    }
    if template == "starter" {
      let page_config_file = join(app, "dist/pages/home/home.json")
      let page_config = @fs.read_file(page_config_file).text()
      @fs.write_file(
        page_config_file,
        "{\"renderer\":\"skyline\"}\n",
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
      let invalid_report = @verify.verify(app, false)
      guard json_string(invalid_report, "status") == "failed" &&
        invalid_report.stringify().contains("skyline-page-config") else {
        abort("Verifier accepted a Skyline page without custom navigation")
      }
      @fs.write_file(
        page_config_file,
        page_config,
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
      let fingerprint = @verify.artifact_fingerprint(app)
      @fs.write_file(
        join(app, "dist/project.private.config.json"),
        local_private_config_fixture,
        create_mode=CreateOrTruncate,
        permission=0o600,
      )
      guard @verify.artifact_fingerprint(app) == fingerprint else {
        abort("local private project config changed the artifact fingerprint")
      }
    }
    run(
      root,
      template + " template verify",
      executable,
      ["verify", app],
      cwd=app,
    )
    if template == "starter" {
      guard @fs.read_file(join(app, "dist/project.private.config.json")).text() ==
        local_private_config_fixture else {
        abort("Starter build did not preserve its local private project config")
      }
      let evidence_args = [
        "devtools", "record", app, "--status", "passed", "--recorded-at", "2000-01-01T00:00:00Z",
        "--tool-version", "fixture-devtools", "--notes", "generator suite evidence",
      ]
      require_command_failure(
        "DevTools evidence requires release artifacts", executable, evidence_args,
        app, "must describe release artifacts",
      )
      require_command_failure(
        "Release verify requires current evidence",
        executable,
        ["verify", app, "--release"],
        app,
        "verification report contains failed checks",
      )
      require_command_failure(
        "JSON release verify returns failure",
        executable,
        ["verify", app, "--release", "--json"],
        app,
        "\"status\": \"failed\"",
      )
      run(
        root,
        "Record matching DevTools evidence",
        executable,
        evidence_args,
        cwd=app,
      )
      run(
        root,
        "Matching release evidence",
        executable,
        ["verify", app, "--release"],
        cwd=app,
      )
      let page_file = join(app, "src/pages/home/page.mbt")
      let source = @fs.read_file(page_file).text()
      @fs.write_file(
        page_file,
        source.split("title=\"Home\"").collect().join("title=\"Home Changed\""),
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
      require_command_failure(
        "Changed release invalidates DevTools evidence",
        executable,
        ["verify", app, "--release"],
        app,
        "verification report contains failed checks",
      )
      guard @fs.read_file(join(app, "dist/project.private.config.json")).text() ==
        local_private_config_fixture else {
        abort(
          "Release verification did not preserve local private project config",
        )
      }
    }
    run(
      root,
      template + " template formatting",
      "moon",
      [
        "fmt", "--check", "moon.mod", "src/pages/home", "src/pages/details", "src/pages/activity_log",
        "src/components/status_badge",
      ],
      cwd=app,
    )
    run(
      root,
      template + " template MoonBit check",
      "moon",
      ["check", "--deny-warn"],
      cwd=app,
    )
    run(
      root,
      template + " template tests",
      "moon",
      ["test", "--target", "js"],
      cwd=app,
    )
  }
  distribution_package_gate(root, temp)
  @fs.rmdir(temp, recursive=true)
}

///|
