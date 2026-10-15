///|
async fn ui_api_suite(root : String) -> Unit {
  let version = ui_package_version(root)
  guard api_product_series(version) is Some(series) &&
    (series == "0.1" || series == "0.2") else {
    abort("UI version requires a separately reviewed API baseline: " + version)
  }
  let baseline = "src/cmd/minimoon_check/fixtures/api/ui/" + series + "/"
  let entries = [
    ("root", "ui/src/pkg.generated.mbti"),
    ("headless", "ui/src/headless/pkg.generated.mbti"),
    ("theme", "ui/src/theme/pkg.generated.mbti"),
    ("resources", "ui/src/resources/pkg.generated.mbti"),
  ]
  if series == "0.2" {
    entries.push(("markdown", "ui/src/markdown/pkg.generated.mbti"))
  }
  for entry in entries {
    let snapshot = baseline + entry.0 + ".mbti"
    require_file(root, snapshot)
    require_file(root, entry.1)
    let violations = if series == "0.2" {
      api_compatibility_violations(
        @fs.read_file(join(root, snapshot)).text(),
        @fs.read_file(join(root, entry.1)).text(),
        true,
      )
    } else {
      api_explicit_method_violations(
        @fs.read_file(join(root, snapshot)).text(),
        @fs.read_file(join(root, entry.1)).text(),
        api_reviewed_explicit_methods(root, "ui/" + entry.0),
        false,
      )
    }
    guard violations.is_empty() else {
      abort("UI " + entry.0 + " API is incompatible: " + violations.join("; "))
    }
  }
  rui_inventory_gate(root)
  nova_recipe_gate(root)
  println("Minimoon UI " + series + " public API compatibility checks passed")
}
