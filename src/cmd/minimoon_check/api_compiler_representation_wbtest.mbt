///|
test "API comparison preserves derives across compiler syntax and ordering" {
  let baseline = "pub struct Value {\n  data : Json\n} derive(ToJson, Eq, @debug.Debug)\n"
  let current = "import {\n  \"moonbitlang/core/json\",\n}\n#derive(Eq, @debug.Debug, @json.ToJson)\npub struct Value {\n  data : @json.Json\n}\n"
  assert_true(api_compatibility_violations(baseline, current, true).is_empty())
  let opaque_old = "type Value derive(Eq)\n"
  let opaque_new = "#derive(Eq)\ntype Value\n"
  assert_true(
    api_compatibility_violations(opaque_old, opaque_new, true).is_empty(),
  )
  for
    changed in [
      current.replace_all(
        old="#derive(Eq, @debug.Debug, @json.ToJson)",
        new="#derive(Eq, @json.ToJson)",
      ),
      current.replace_all(old="@json.Json\n}", new="String\n}"),
      current.replace_all(old="data :", new="renamed :"),
      current + "pub fn Value::added(Self) -> Unit\n",
      "#derive(Eq)\n",
      "#derive(Eq)\n#derive(Eq)\ntype Value\n",
    ] {
    assert_true(
      !api_compatibility_violations(baseline, changed, true).is_empty(),
    )
  }
}

///|
test "API comparison qualifies only the actual core JSON aliases" {
  let baseline = "pub fn[T : ToJson] encode(T, Json) -> Json\n"
  let imports = "import {\n  \"moonbitlang/core/json\",\n}\n"
  let signature = "pub fn[T : @json.ToJson] encode(T, @json.Json) -> @json.Json\n"
  assert_true(
    api_compatibility_violations(baseline, imports + signature, true).is_empty(),
  )
  for
    changed in [
      signature,
      imports.replace_all(old="moonbitlang/core/json", new="example/json") +
      signature,
      imports + signature.replace_all(old="@json.Json)", new="String)"),
      imports + "type Json\n" + signature,
      imports + "trait ToJson\n" + signature,
      imports + "pub fn[Json] encode(Json, @json.Json) -> @json.Json\n",
      imports + "pub fn[ToJson] encode(ToJson, @json.Json) -> @json.Json\n",
    ] {
    assert_true(
      !api_compatibility_violations(baseline, changed, true).is_empty(),
    )
  }
}

///|
test "API JSON normalization preserves strings names and qualified methods" {
  let source = "import {\n  \"moonbitlang/core/json\",\n}\n#deprecated(\"@json.Json ToJson\")\npub fn Json() -> @json.Json\npub fn @json.Json::method(Self) -> @json.Json\n"
  let normalized = api_json_alias(source)
  assert_true(normalized.contains("#deprecated(\"@json.Json ToJson\")"))
  assert_true(normalized.contains("pub fn Json() -> Json"))
  assert_true(normalized.contains("pub fn @json.Json::method(Self) -> Json"))
  let baseline = "pub fn Json() -> Json\n"
  let renamed = "import {\n  \"moonbitlang/core/json\",\n}\npub fn Json32() -> @json.Json\n"
  assert_true(!api_compatibility_violations(baseline, renamed, true).is_empty())
}

///|
test "API derives remain attached to the same declaration" {
  let baseline = "pub enum First {\n  A\n} derive(Eq)\npub enum Second {\n  B\n}\n"
  let moved = "pub enum First {\n  A\n}\n#derive(Eq)\npub enum Second {\n  B\n}\n"
  assert_true(!api_compatibility_violations(baseline, moved, true).is_empty())
  let duplicate = "#derive(Eq, Eq)\npub enum First {\n  A\n}\npub enum Second {\n  B\n}\n"
  assert_true(
    !api_compatibility_violations(baseline, duplicate, true).is_empty(),
  )
}
