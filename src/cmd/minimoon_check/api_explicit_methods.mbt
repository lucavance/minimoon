///|
// This is a representation migration, not an additive exception to the root API.
// Every reviewed method must be present exactly once. Everything else still
// passes through the unchanged historical compatibility policy.
fn api_explicit_method_violations(
  baseline_source : String,
  current_source : String,
  explicit_source : String,
  exact : Bool,
) -> Array[String] {
  let expected = api_interface_snapshot(explicit_source)
  let current = api_interface_snapshot(current_source)
  let violations : Array[String] = []
  if !expected.complete || !current.complete {
    return ["explicit method migration contains an incomplete declaration"]
  }
  let reviewed : Map[String, Int] = Map([])
  for declaration in expected.blocks {
    if !declaration.has_prefix("pub fn") || !declaration.contains("::") {
      violations.push(
        "explicit method migration may contain only method declarations",
      )
    }
    if reviewed.contains(declaration) {
      violations.push("duplicate reviewed explicit method: " + declaration)
    }
    reviewed[declaration] = 0
  }
  let preserved : Array[String] = []
  for declaration in current.blocks {
    match reviewed.get(declaration) {
      Some(count) => reviewed[declaration] = count + 1
      None => preserved.push(declaration)
    }
  }
  for declaration in expected.blocks {
    if reviewed.get(declaration) != Some(1) {
      violations.push("expected exactly one explicit method: " + declaration)
    }
  }
  for
    violation in api_compatibility_violations(
      baseline_source,
      preserved.join("\n\n"),
      exact,
    ) {
    violations.push(violation)
  }
  violations
}

///|
async fn api_reviewed_explicit_methods(
  root : String,
  package_name : String,
) -> String {
  let path = "src/cmd/minimoon_check/fixtures/api/explicit_methods/0.10.14/" +
    package_name +
    ".mbti"
  require_file(root, path)
  @fs.read_file(join(root, path)).text()
}
