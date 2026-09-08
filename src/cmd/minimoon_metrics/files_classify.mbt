///|
fn file_ownership(path : String) -> (String, String?) {
  if path.has_prefix("ui/examples/showcase/") {
    return ("ui_fixture", None)
  }
  if path.has_prefix("examples/miniapp_conformance_app/") {
    return ("core_fixture", None)
  }
  if path.has_prefix("templates/starter/") {
    return ("starter", None)
  }
  if path.has_prefix("ui/") {
    return ("ui", None)
  }
  if path.has_prefix("src/") ||
    path == "scripts/bridge/weapp_tailwindcss_adapter.mjs" {
    let area = if path.has_prefix("src/cmd/minimoon_check/") ||
      path.has_prefix("src/internal_host_validation/") ||
      path.has_prefix("src/internal_components_behavior_test/") ||
      path.has_prefix("src/internal_component_styles_behavior_test/") ||
      path.has_prefix("src/testing/") {
      "validation"
    } else if path.has_prefix("src/cmd/") ||
      path.has_prefix("src/tooling_") ||
      path.has_prefix("scripts/") {
      "tooling"
    } else {
      "framework"
    }
    return ("core", Some(area))
  }
  ("repo", None)
}

///|
fn file_role(path : String) -> String {
  let name = path.split("/").last().unwrap_or("").to_owned()
  if path.has_prefix("src/cmd/minimoon_check/fixtures/api/") {
    return "api_snapshot"
  }
  if path.has_suffix(".generated.mbt") || file_is_fixture_output(path) {
    return "generated_artifact"
  }
  if path.has_suffix(".mbti") {
    return "generated_interface"
  }
  if path.has_suffix("_bench.mbt") || path.has_suffix("_bench_wbtest.mbt") {
    return "benchmark"
  }
  if path.has_suffix("_test.mbt") || path.has_suffix("_wbtest.mbt") {
    return "test"
  }
  if path.has_suffix(".md") ||
    path.has_suffix(".rst") ||
    name == "LICENSE" ||
    name.has_prefix("LICENSE.") ||
    name == "NOTICE" {
    return "docs"
  }
  if [
      ".mbt", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".css", ".wxss", ".wxml",
      ".html", ".sh", ".bash", ".ps1",
    ].any(extension => path.has_suffix(extension)) ||
    path.has_prefix(".githooks/") {
    return "maintained_source"
  }
  if [
      "moon.mod", "moon.pkg", "moon.work", "bun.lock", ".gitignore", ".moonignore",
      ".gitattributes",
    ].contains(name) ||
    [".json", ".yaml", ".yml", ".toml", ".lock", ".ini", ".cfg"].any(extension => {
      path.has_suffix(extension)
    }) {
    return "config"
  }
  "asset"
}

///|
fn file_is_fixture_output(path : String) -> Bool {
  for fixture in ["examples/miniapp_conformance_app/", "ui/examples/showcase/"] {
    if path.has_prefix(fixture + "dist/") ||
      path.has_prefix(fixture + "generated/") ||
      (path.has_prefix(fixture + "styles/") && path.has_suffix(".wxss")) {
      return true
    }
  }
  false
}

///|
fn file_language(path : String, is_text : Bool) -> String {
  let name = path.split("/").last().unwrap_or("").to_owned()
  if ["moon.mod", "moon.pkg", "moon.work"].contains(name) {
    return "MoonBit config"
  }
  for
    pair in [
      (".mbt", "MoonBit"),
      (".mbti", "MoonBit interface"),
      (".mjs", "JavaScript"),
      (".cjs", "JavaScript"),
      (".js", "JavaScript"),
      (".jsx", "JavaScript"),
      (".ts", "TypeScript"),
      (".tsx", "TypeScript"),
      (".css", "CSS"),
      (".wxss", "WXSS"),
      (".wxml", "WXML"),
      (".xml", "XML"),
      (".svg", "SVG"),
      (".json", "JSON"),
      (".md", "Markdown"),
      (".rst", "reStructuredText"),
      (".yaml", "YAML"),
      (".yml", "YAML"),
      (".toml", "TOML"),
      (".html", "HTML"),
      (".sh", "Shell"),
      (".bash", "Shell"),
      (".ps1", "PowerShell"),
      (".mmd", "Mermaid"),
    ] {
    if path.has_suffix(pair.0) {
      return pair.1
    }
  }
  if path.has_prefix(".githooks/") {
    "Shell"
  } else if is_text {
    "Text"
  } else {
    "Binary"
  }
}
