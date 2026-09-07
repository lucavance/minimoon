///|
fn api_test_interface(body : String) -> String {
  "// Generated comment\npackage \"fixture/api\"\n\n// Values\n" + body
}

///|
fn api_test_manifest(
  series : String,
  contract : Int,
  runtime : Int,
  renderer : Int,
) -> Json {
  Json::object({
    "schemaVersion": Json::number(1.0),
    "productSeries": Json::string(series),
    "appContractVersion": Json::number(contract.to_double()),
    "runtimeApiVersion": Json::number(runtime.to_double()),
    "rendererProtocolVersion": Json::number(renderer.to_double()),
  })
}

///|
test "root API policy rejects additions, removals, and modifications" {
  let baseline = api_test_interface(
    "pub fn stable() -> Unit\n\npub type Stable\n",
  )
  let addition = api_test_interface(
    "pub fn stable() -> Unit\n\npub type Stable\n\npub fn added() -> Unit\n",
  )
  let removal = api_test_interface("pub fn stable() -> Unit\n")
  let modification = api_test_interface(
    "pub fn stable(Int) -> Unit\n\npub type Stable\n",
  )
  assert_true(
    !api_compatibility_violations(baseline, addition, true).is_empty(),
  )
  assert_true(!api_compatibility_violations(baseline, removal, true).is_empty())
  assert_true(
    !api_compatibility_violations(baseline, modification, true).is_empty(),
  )
}

///|
test "optional API policy permits complete additive declaration blocks" {
  let baseline = api_test_interface(
    "pub fn first() -> Unit\n\npub struct Stable {\n  value : Int\n}\n",
  )
  let additive = api_test_interface(
    (
      #|pub fn first() -> Unit
      #|
      #|pub fn added() -> Unit
      #|
      #|pub struct Stable {
      #|  value : Int
      #|}
      #|
    ),
  )
  assert_true(
    api_compatibility_violations(baseline, additive, false).is_empty(),
  )
}

///|
test "optional API policy rejects deletions and modifications" {
  let baseline = api_test_interface(
    "pub fn first() -> Unit\n\npub fn second(Int) -> Unit\n",
  )
  let deletion = api_test_interface("pub fn first() -> Unit\n")
  let modification = api_test_interface(
    "pub fn first() -> Unit\n\npub fn second(String) -> Unit\n",
  )
  assert_true(
    !api_compatibility_violations(baseline, deletion, false).is_empty(),
  )
  assert_true(
    !api_compatibility_violations(baseline, modification, false).is_empty(),
  )
}

///|
test "API normalization ignores comments, CRLF, and trailing whitespace" {
  let baseline = api_test_interface("pub fn stable() -> Unit\n")
  let current = "// Different comment\r\npackage \"fixture/api\"\r\n\r\n// Values\r\npub fn stable() -> Unit  \r\n"
  assert_true(api_compatibility_violations(baseline, current, true).is_empty())
}

///|
test "API policy rejects incomplete additive blocks" {
  let baseline = api_test_interface("pub fn stable() -> Unit\n")
  let current = api_test_interface(
    "pub fn stable() -> Unit\n\npub struct Incomplete {\n  value : Int\n",
  )
  assert_true(
    !api_compatibility_violations(baseline, current, false).is_empty(),
  )
}

///|
test "API manifest rejects product and protocol drift" {
  let valid = api_test_manifest("0.1", 7, 10, 7)
  assert_true(api_manifest_violations(valid, "0.1", 7, 10, 7).is_empty())
  let drifted = api_test_manifest("0.4", 8, 11, 8)
  assert_eq(api_manifest_violations(drifted, "0.1", 7, 10, 7).length(), 4)
}

///|
test "unknown product series requires a reviewed API baseline" {
  assert_true(api_baseline_series("0.1.9") is Some("0.1"))
  assert_true(api_baseline_series("0.2.0") is Some("0.2"))
  assert_true(api_baseline_series("0.4.0") is None)
  assert_true(api_baseline_series("invalid") is None)
}
