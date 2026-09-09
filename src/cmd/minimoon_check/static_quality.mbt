///|
let supported_moon_floor = "0.1.20260904"

///|
let supported_moonc_floor = "0.10.12"

///|
let supported_node_engine = ">=24.20.0"

///|
let node_lts_floor = "24.20.0"

///|
let primary_node_version = "26.8.1"

///|
let supported_bun_version = "1.4.2"

///|
fn moon_identifier_character(char : UInt16) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_'
}

///|
fn signature_contains_type(signature : String, name : String) -> Bool {
  guard signature.length() >= name.length() else { return false }
  for index = 0; index <= signature.length() - name.length(); index = index + 1 {
    if signature[index:].has_prefix(name) &&
      (index == 0 || !moon_identifier_character(signature[index - 1])) {
      let mut cursor = index + name.length()
      while cursor < signature.length() &&
            (
              signature[cursor] == ' ' ||
              signature[cursor] == '\t' ||
              signature[cursor] == '\r' ||
              signature[cursor] == '\n'
            ) {
        cursor = cursor + 1
      }
      if cursor < signature.length() && signature[cursor] == '[' {
        return true
      }
    }
  }
  false
}

///|
fn append_extern_signature_violations(
  violations : Array[String],
  signature : String,
  line : Int,
) -> Unit {
  let declaration = match signature.find("=") {
    Some(end) => signature[0:end].to_owned()
    None => signature
  }
  if signature_contains_type(declaration, "ReadOnlyArray") {
    violations.push(
      "line " +
      line.to_string() +
      ": extern \"js\" signatures must use FixedArray[T], not ReadOnlyArray[T]",
    )
  }
  if signature_contains_type(declaration, "Array") {
    violations.push(
      "line " +
      line.to_string() +
      ": extern \"js\" signatures must use FixedArray[T], not Array[T]",
    )
  }
}

///|
fn starts_js_extern_signature(line : String) -> Bool {
  let marker = "extern \"js\" fn"
  match line.find(marker) {
    None => false
    Some(0) => true
    Some(index) => {
      let prefix = line[0:index].trim()
      prefix == "pub" || (prefix.has_prefix("pub(") && prefix.has_suffix(")"))
    }
  }
}

///|
fn moon_source_boundary_violations(source : String) -> Array[String] {
  let violations : Array[String] = []
  let deprecated_constructor = "StringBuilder::" + "new"
  if source.contains(deprecated_constructor) {
    violations.push(
      "deprecated StringBuilder constructor is forbidden; use StringBuilder(...) instead",
    )
  }
  let mut collecting = false
  let mut signature = ""
  let mut start_line = 0
  let mut line_number = 0
  for view in source.split("\n") {
    line_number = line_number + 1
    let line = view.trim().to_owned()
    if !collecting && starts_js_extern_signature(line) {
      collecting = true
      signature = line
      start_line = line_number
    } else if collecting {
      signature = signature + " " + line
    }
    if collecting && line.contains("=") {
      append_extern_signature_violations(violations, signature, start_line)
      collecting = false
      signature = ""
    }
  }
  violations
}

///|
async fn static_suite(root : String) -> Unit {
  for
    path in [
      ".github/workflows/test.yml", "src/README.mbt.md", "src/cmd/minimoon/main.mbt",
      "src/cmd/minimoon/templates.generated.mbt", "src/pkg.generated.mbti", "src/renderer_miniapp/page_program_10_contract.mbt",
      "src/tooling_minimoon_build/build.mbt", "src/tooling_minimoon_verify/verify_00_files.mbt",
      "src/tooling_miniapp/generator.mbt", "src/internal_host_js/host_bridge.mbt",
      "src/internal_versions/versions.mbt", "scripts/bridge/weapp_tailwindcss_adapter.mjs",
    ] {
    require_file(root, path)
  }
  require_text(
    root,
    ".github/workflows/test.yml",
    "version_at_least \"" + supported_moon_floor + "\" \"$installed_moon\"",
  )
  require_text(
    root,
    ".github/workflows/test.yml",
    "supported floor " + supported_moon_floor,
  )
  require_text(
    root,
    ".github/workflows/test.yml",
    "version_at_least \"" + supported_moonc_floor + "\" \"$installed_moonc\"",
  )
  require_text(
    root,
    ".github/workflows/test.yml",
    "supported floor " + supported_moonc_floor,
  )
  let installers = @fs.read_file(join(root, ".github/workflows/test.yml"))
    .text()
    .split("\n")
    .filter(line => line.contains("cli.moonbitlang.com/install/unix.sh"))
    .collect()
  guard installers.length() == 2 &&
    installers.all(line => {
      line.trim() ==
      "curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- 0.10.12+1634b282e"
    }) else {
    abort("both CI jobs must install the reviewed official MoonBit binary")
  }
  for
    token in [
      "cargo build", "rustup toolchain", "./.github/actions/setup-moonbit",
    ] {
    forbid_text(root, ".github/workflows/test.yml", token)
  }
  require_text(
    root,
    ".github/workflows/test.yml",
    "node-version: " + primary_node_version,
  )
  require_text(
    root,
    ".github/workflows/test.yml",
    "node-version: " + node_lts_floor,
  )
  require_text(root, ".github/workflows/test.yml", "node-lts-compat:")
  require_text(root, ".github/workflows/test.yml", "Node 24 LTS compatibility")
  require_text(root, ".github/workflows/test.yml", "moon test --target js")
  require_text(
    root, ".github/workflows/test.yml", "moon run src/cmd/minimoon --target native -- check --suite generator",
  )
  forbid_text(root, ".github/workflows/test.yml", "node-version-file")
  guard !@fs.exists(join(root, ".node-version")) else {
    abort(
      "repository must express Node compatibility through engines, not .node-version",
    )
  }
  require_text(
    root,
    "package.json",
    "\"node\": \"" + supported_node_engine + "\"",
  )
  require_text(root, ".gitignore", "**/generated/devtools.evidence.json")
  for fixture in ["examples/miniapp_conformance_app", "ui/examples/showcase"] {
    for
      private_file in [
        "/generated/devtools.evidence.json", "/dist/project.private.config.json",
      ] {
      let path = fixture + private_file
      require_untracked_path(root, path)
      let (code, _, _) = @process.collect_output(
        "git",
        ["check-ignore", "--no-index", "--quiet", "--", path],
        cwd=root,
      )
      guard code == 0 else {
        abort("developer-local fixture file must be ignored: " + path)
      }
    }
  }
  forbid_text(
    root, ".github/workflows/test.yml", "Release gate when evidence is present",
  )
  forbid_text(root, ".github/workflows/test.yml", "devtools.evidence.json")
  require_text(
    root, ".github/workflows/test.yml", "CI handoff accepts candidate verification reports only",
  )
  for
    token in [
      "package_handoff examples/miniapp_conformance_app miniapp_conformance_app core 7",
      "package_handoff ui/examples/showcase minimoon_ui_showcase ui 6", "name: minimoon-devtools-${{ github.sha }}",
      "name: minimoon-ui-devtools-${{ github.sha }}", "path: _build/devtools-handoff/core/",
      "path: _build/devtools-handoff/ui/", "git status --porcelain --untracked-files=all",
      "CI requires a clean tracked and untracked worktree",
    ] {
    require_text(root, ".github/workflows/test.yml", token)
  }
  ci_handoff_gate(root)
  forbid_text(
    root, ".github/workflows/test.yml", "version_at_least \"0.10.6\" \"$installed_moonc\"",
  )
  forbid_text(
    root, ".github/workflows/test.yml", "moonc $installed_moonc is below the supported floor 0.10.6",
  )
  for
    path in [
      "AGENTS.md", "README.mbt.md", "README.zh-CN.mbt.md", "docs/guides/miniapp_quickstart.md",
      "docs/reference/compatibility_and_upgrades.md", "docs/project_status.md",
    ] {
    for
      token in [
        "moon " + supported_moon_floor,
        "moonc v" + supported_moonc_floor,
        supported_node_engine,
        supported_bun_version,
      ] {
      require_text(root, path, token)
    }
  }
  require_text(root, "src/cmd/minimoon/main.mbt", "@argparse.Command")
  require_text(
    root, "src/cmd/minimoon/templates.generated.mbt", "embedded_template_files",
  )
  require_text(root, "src/authoring_core.mbt", "struct Val")
  require_text(root, "src/authoring_core.mbt", "pub(all) struct Emit")
  require_text(root, "src/authoring_core.mbt", "Emit::map")
  require_text(
    root, "src/authoring_core.mbt", "pub fn[Model : Eq, Msg] create_state",
  )
  require_text(root, "src/authoring_core.mbt", "create_state_with_init")
  require_text(root, "src/authoring_core.mbt", "create_state_with_input")
  require_text(root, "src/authoring_core.mbt", "create_pure_state")
  require_text(root, "src/authoring_core.mbt", "create_variable")
  require_text(root, "src/authoring_core.mbt", "create_resource")
  require_text(root, "src/authoring_core.mbt", "pub fn[Model] no_cmd")
  require_text(root, "src/authoring_core.mbt", "pub fn[Model] with_cmd")
  require_text(root, "src/authoring_core.mbt", "pub fn[Model] with_cmds")
  require_text(root, "src/authoring_core.mbt", "Val::view2")
  require_text(root, "src/authoring_core.mbt", "Val::view9")
  require_text(root, "src/authoring_page.mbt", "pub fn page")
  for leaked in ["@renderer", "@runtime", "@val", "@ui", "internal_miniapp"] {
    forbid_text(root, "src/pkg.generated.mbti", leaked)
  }
  for
    removed in [
      "type State", "type Transition", "type Resource", "pub fn state(", "pub fn state_with_input(",
      "pub fn variable(", "pub fn resource(", "pub fn[Model] next(",
    ] {
    forbid_text(root, "src/pkg.generated.mbti", removed)
  }
  require_text(root, "src/val_runtime/val_runtime_10_state.mbt", "Val::assoc")
  require_text(
    root, "src/renderer_miniapp/page_program_10_contract.mbt", "PageProgram",
  )
  require_text(root, "src/tooling_miniapp/generator.mbt", "runtimeApiVersion")
  require_same_text(root, "README.mbt.md", "README.md")
  require_same_text(root, "README.zh-CN.mbt.md", "README.zh-CN.md")
  require_same_text(root, "ui/README.mbt.md", "ui/README.md")
  for path in repository_moonbit_sources(root) {
    let violations = moon_source_boundary_violations(
      @fs.read_file(join(root, path)).text(),
    )
    guard violations.is_empty() else {
      abort(path + ": " + violations.join("; "))
    }
  }
  for
    legacy in [
      "examples/miniapp_counter_fake", "examples/miniapp_js_runtime_bridge_spike",
      "examples/miniapp_counter", "examples/miniapp_components_app", "examples/miniapp_dynamic_app",
      "examples/miniapp_minimal_app", "examples/miniapp_profile_app", "src/renderer_miniapp_codegen",
      "src/renderer_miniapp_js", "src/renderer_miniapp_metadata", "src/renderer_miniapp_runtime",
      "src/renderer_miniapp_testing", "src/tooling_minimoon_config", "src/tooling_miniapp_app_driver",
      "src/tooling_miniapp_codegen", "src/tooling_miniapp_counter_driver", "src/tooling_miniapp_prepare",
      "src/tooling_miniapp_writer", "src/tea_runtime", "src/signal_core", "src/patch_graph",
      "src/projection_experiment", "src/internal_miniapp",
    ] {
    guard !@fs.exists(join(root, legacy)) else {
      abort("removed V1 path must not return: " + legacy)
    }
  }
  for
    dependency in [
      "renderer_miniapp_runtime", "renderer_miniapp_metadata", "renderer_miniapp_codegen",
      "signal_core", "patch_graph",
    ] {
    forbid_text(root, "src/renderer_miniapp/moon.pkg", dependency)
  }
  for
    page_package in [
      "examples/miniapp_conformance_app/src/pages/showcase/moon.pkg", "examples/miniapp_conformance_app/src/pages/request_lifecycle/moon.pkg",
      "examples/miniapp_conformance_app/src/pages/runtime_lab/moon.pkg", "examples/miniapp_conformance_app/src/pages/draft_editor/moon.pkg",
      "examples/miniapp_conformance_app/src/pages/interaction/moon.pkg", "examples/miniapp_conformance_app/src/pages/platform/moon.pkg",
      "examples/miniapp_conformance_app/src/pages/application/moon.pkg", "examples/miniapp_conformance_app/src/components/toggle_card/moon.pkg",
      "examples/miniapp_conformance_app/src/components/shared_app/moon.pkg", "examples/miniapp_conformance_app/src/scenes/interaction/moon.pkg",
      "examples/miniapp_conformance_app/src/scenes/composition/moon.pkg", "templates/starter/src/pages/home/moon.pkg",
      "templates/starter/src/pages/details/moon.pkg",
    ] {
    require_text(root, page_package, "\"lampclaw/minimoon\"")
    forbid_text(root, page_package, "lampclaw/minimoon/miniapp")
    for internal_package in ["renderer_miniapp", "runtime_core", "ui_dsl"] {
      forbid_text(root, page_package, internal_package)
    }
  }
  // In these fixed fixture packages the first import block is production-only;
  // subsequent `for "test"` imports may reference another page for integration tests.
  for
    page in [
      "showcase", "interaction", "platform", "application", "request_lifecycle",
      "runtime_lab", "draft_editor",
    ] {
    let package_path = "examples/miniapp_conformance_app/src/pages/" +
      page +
      "/moon.pkg"
    let production = @fs.read_file(join(root, package_path))
      .text()
      .split("}")
      .collect()[0]
    guard !production.contains("miniapp_conformance_app/pages/") else {
      abort(
        "Conformance production pages must compose scenes, not other pages: " +
        page,
      )
    }
  }
  for internal_package in ["renderer_miniapp", "runtime_core", "ui_dsl"] {
    forbid_text(
      root,
      "src/cmd/minimoon/templates.generated.mbt",
      "lampclaw/minimoon/" + internal_package,
    )
  }
  forbid_text(
    root, "src/cmd/minimoon/templates.generated.mbt", "lampclaw/minimoon/miniapp",
  )
  for
    application_source in [
      "src/cmd/minimoon/templates.generated.mbt", "templates/starter/src/pages/home/page.mbt",
      "templates/starter/src/pages/details/page.mbt", "examples/miniapp_conformance_app/src/pages/showcase/page.mbt",
      "examples/miniapp_conformance_app/src/pages/request_lifecycle/page.mbt", "examples/miniapp_conformance_app/src/pages/runtime_lab/page.mbt",
      "examples/miniapp_conformance_app/src/pages/draft_editor/page.mbt", "examples/miniapp_conformance_app/src/components/toggle_card/card.mbt",
      "examples/miniapp_conformance_app/src/pages/interaction/page.mbt", "examples/miniapp_conformance_app/src/pages/platform/page.mbt",
      "examples/miniapp_conformance_app/src/pages/application/page.mbt", "examples/miniapp_conformance_app/src/components/shared_app/panels.mbt",
      "examples/miniapp_conformance_app/src/scenes/interaction/scene.mbt", "examples/miniapp_conformance_app/src/scenes/composition/scene.mbt",
    ] {
    for
      stale_public_name in [
        "MiniappCommands", "MiniappDecodeError", "MiniappScrollDetail", "MiniappCapability",
        "@minimoon.state(", "@minimoon.state_with_input(", "@minimoon.variable(",
        "@minimoon.resource(", "@minimoon.next(", ".sender()", "emit.emit(",
      ] {
      forbid_text(root, application_source, stale_public_name)
    }
  }
  let allowed = "scripts/bridge/weapp_tailwindcss_adapter.mjs"
  for path in repository_scripts(root) {
    guard path == allowed || generated_script(path) else {
      abort("unexpected maintained script is forbidden: " + path)
    }
  }
  let adapter = @fs.read_file(join(root, allowed)).text()
  guard adapter.split("\n").length() <= 101 else {
    abort("weapp-tailwindcss adapter exceeds 100 lines")
  }
  guard adapter.trim() == @build.adapter_source().trim() else {
    abort("embedded weapp-tailwindcss adapter has drifted from " + allowed)
  }
  for
    package_dir in [
      "src/components", "src/internal_duplix", "src/renderer_miniapp", "src/runtime_core",
      "src/tooling_minimoon_verify", "src/val_runtime", "ui/src",
    ] {
    @fs.walk(
      join(root, package_dir),
      (path, names) => {
        for name in names {
          if name.has_suffix(".mbt") &&
            !name.has_suffix("_test.mbt") &&
            !name.has_suffix("_wbtest.mbt") &&
            !name.has_suffix("_bench.mbt") {
            let file = join(path, name)
            let lines = @fs.read_file(file).text().split("\n").length()
            guard lines <= 450 else {
              abort(
                package_dir +
                "/" +
                name +
                " exceeds the 450-line production source budget: " +
                lines.to_string(),
              )
            }
          }
        }
      },
      max_concurrency=1,
    )
  }
}

///|
async fn quality_suite(root : String) -> Unit {
  run(root, "MoonBit warning-free source check", "moon", [
    "check", "--deny-warn",
  ])
  run(root, "MoonBit formatting check", "moon", ["fmt", "--check"])
  run(root, "MoonBit public API check", "moon", ["info"])
}

///|
