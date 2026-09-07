///|
async fn ui_api_suite(root : String) -> Unit {
  let version = ui_package_version(root)
  guard api_product_series(version) is Some("0.1") else {
    abort("UI version requires a separately reviewed API baseline: " + version)
  }
  let baseline = "src/cmd/minimoon_check/fixtures/api/ui/0.1/"
  for
    entry in [
      ("root", "ui/src/pkg.generated.mbti"),
      ("headless", "ui/src/headless/pkg.generated.mbti"),
      ("theme", "ui/src/theme/pkg.generated.mbti"),
      ("resources", "ui/src/resources/pkg.generated.mbti"),
    ] {
    let snapshot = baseline + entry.0 + ".mbti"
    require_file(root, snapshot)
    require_file(root, entry.1)
    let violations = api_compatibility_violations(
      @fs.read_file(join(root, snapshot)).text(),
      @fs.read_file(join(root, entry.1)).text(),
      false,
    )
    guard violations.is_empty() else {
      abort("UI " + entry.0 + " API is incompatible: " + violations.join("; "))
    }
  }
  println("Minimoon UI 0.1 public API compatibility checks passed")
}
