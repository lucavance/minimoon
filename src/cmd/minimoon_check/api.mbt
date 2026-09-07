///|
struct ApiInterfaceSnapshot {
  blocks : Array[String]
  complete : Bool
}

///|
fn api_trim_trailing_whitespace(line : String) -> String {
  let mut end = line.length()
  while end > 0 {
    let char = line[end - 1]
    if char == ' ' || char == '\t' || char == '\r' {
      end = end - 1
    } else {
      break
    }
  }
  line[0:end].to_owned()
}

///|
fn api_delimiter_delta(line : String) -> Int {
  let mut delta = 0
  for index = 0; index < line.length(); index = index + 1 {
    match line[index] {
      '{' | '(' | '[' => delta = delta + 1
      '}' | ')' | ']' => delta = delta - 1
      _ => ()
    }
  }
  delta
}

///|
fn api_flush_interface_block(
  blocks : Array[String],
  lines : Array[String],
) -> Unit {
  if !lines.is_empty() {
    blocks.push(lines.join("\n"))
    lines.clear()
  }
}

///|
fn api_interface_snapshot(source : String) -> ApiInterfaceSnapshot {
  let blocks : Array[String] = []
  let lines : Array[String] = []
  let mut delimiter_depth = 0
  let mut complete = true
  let mut in_import = false
  for raw_line in source.split("\n") {
    let line = api_trim_trailing_whitespace(raw_line.to_owned())
    let trimmed = line.trim()
    if trimmed.has_prefix("//") {
      continue
    }
    if in_import {
      if trimmed == "}" {
        in_import = false
      } else if trimmed != "" {
        blocks.push("import " + trimmed.to_owned())
      }
      continue
    }
    if trimmed == "import {" {
      api_flush_interface_block(blocks, lines)
      in_import = true
      continue
    }
    if trimmed.has_prefix("package ") {
      api_flush_interface_block(blocks, lines)
      continue
    }
    if trimmed == "" {
      if delimiter_depth == 0 {
        api_flush_interface_block(blocks, lines)
      }
      continue
    }
    let starts_at_column_zero = line[0] != ' ' && line[0] != '\t'
    if starts_at_column_zero && !lines.is_empty() && delimiter_depth == 0 {
      api_flush_interface_block(blocks, lines)
    }
    lines.push(line)
    delimiter_depth = delimiter_depth + api_delimiter_delta(line)
    if delimiter_depth < 0 {
      complete = false
    }
  }
  api_flush_interface_block(blocks, lines)
  if in_import || delimiter_depth != 0 {
    complete = false
  }
  { blocks, complete, }
}

///|
fn api_block_label(block : String) -> String {
  block.split("\n").next().unwrap_or("").to_owned()
}

///|
fn api_compatibility_violations(
  baseline_source : String,
  current_source : String,
  exact : Bool,
) -> Array[String] {
  let violations : Array[String] = []
  let baseline = api_interface_snapshot(baseline_source)
  let current = api_interface_snapshot(current_source)
  if !baseline.complete {
    violations.push("API baseline contains an incomplete declaration block")
    return violations
  }
  if !current.complete {
    violations.push("current API contains an incomplete declaration block")
    return violations
  }
  if exact {
    let shared = baseline.blocks.length().min(current.blocks.length())
    for index = 0; index < shared; index = index + 1 {
      if baseline.blocks[index] != current.blocks[index] {
        violations.push(
          "API declaration changed at block " +
          index.to_string() +
          ": expected " +
          api_block_label(baseline.blocks[index]) +
          ", found " +
          api_block_label(current.blocks[index]),
        )
        return violations
      }
    }
    if baseline.blocks.length() != current.blocks.length() {
      violations.push(
        "API declaration count changed: expected " +
        baseline.blocks.length().to_string() +
        ", found " +
        current.blocks.length().to_string(),
      )
    }
    return violations
  }
  let mut baseline_index = 0
  for block in current.blocks {
    if baseline_index < baseline.blocks.length() &&
      block == baseline.blocks[baseline_index] {
      baseline_index = baseline_index + 1
    }
  }
  if baseline_index != baseline.blocks.length() {
    violations.push(
      "required API declaration was removed, modified, or reordered: " +
      api_block_label(baseline.blocks[baseline_index]),
    )
  }
  violations
}

///|
fn api_product_series(version : String) -> String? {
  let parts = version.split(".").collect()
  guard parts.length() >= 2 && parts[0] != "" && parts[1] != "" else {
    return None
  }
  Some(parts[0].to_owned() + "." + parts[1].to_owned())
}

///|
fn api_baseline_series(version : String) -> String? {
  match api_product_series(version) {
    Some(series) =>
      if series == "0.1" || series == "0.2" {
        Some(series)
      } else {
        None
      }
    None => None
  }
}

///|
fn api_manifest_violations(
  manifest : Json,
  product_series : String,
  app_contract_version : Int,
  runtime_api_version : Int,
  renderer_protocol_version : Int,
) -> Array[String] {
  let violations : Array[String] = []
  for
    entry in [
      ("schemaVersion", Json::number(1.0)),
      ("productSeries", Json::string(product_series)),
      ("appContractVersion", Json::number(app_contract_version.to_double())),
      ("runtimeApiVersion", Json::number(runtime_api_version.to_double())),
      (
        "rendererProtocolVersion",
        Json::number(renderer_protocol_version.to_double()),
      ),
    ] {
    let (key, expected) = entry
    if json_field(manifest, key) != expected {
      violations.push("API baseline manifest does not match " + key)
    }
  }
  violations
}

///|
async fn api_suite(root : String) -> Unit {
  run(root, "MoonBit public API generation", "moon", ["info"])
  let product_version = @versions.product_version()
  let product_series = match api_baseline_series(product_version) {
    Some(series) => series
    None =>
      abort(
        "no reviewed API baseline exists for product version " +
        product_version +
        "; add a versioned baseline, changelog entry, and migration guidance",
      )
  }
  let baseline_dir = "src/cmd/minimoon_check/fixtures/api/" + product_series
  let manifest = read_json(root, baseline_dir + "/manifest.json")
  let manifest_violations = api_manifest_violations(
    manifest,
    product_series,
    @versions.app_contract_version(),
    @versions.runtime_api_version(),
    @versions.renderer_protocol_version(),
  )
  guard manifest_violations.is_empty() else {
    abort(manifest_violations.join("; "))
  }
  let packages = json_field(manifest, "packages")
  let package_snapshots = [
    ("root", "src/pkg.generated.mbti", "root.mbti", "exact", true),
    (
      "components", "src/components/pkg.generated.mbti", "components.mbti", "additive",
      false,
    ),
    (
      "styles", "src/components/styles/pkg.generated.mbti", "styles.mbti", "additive",
      false,
    ),
    (
      "testing", "src/testing/pkg.generated.mbti", "testing.mbti", "additive", false,
    ),
  ]
  if product_series == "0.2" {
    package_snapshots.push(
      (
        "resources", "src/resources/pkg.generated.mbti", "resources.mbti", "exact",
        true,
      ),
    )
  }
  for entry in package_snapshots {
    let (label, source, snapshot, policy, exact) = entry
    let package_entry = json_field(packages, label)
    guard json_string(package_entry, "source") == source &&
      json_string(package_entry, "snapshot") == snapshot &&
      json_string(package_entry, "policy") == policy else {
      abort("API baseline manifest package entry has drifted: " + label)
    }
    require_file(root, source)
    let baseline_path = baseline_dir + "/" + snapshot
    require_file(root, baseline_path)
    let violations = api_compatibility_violations(
      @fs.read_file(join(root, baseline_path)).text(),
      @fs.read_file(join(root, source)).text(),
      exact,
    )
    guard violations.is_empty() else {
      abort(label + " public API is incompatible: " + violations.join("; "))
    }
  }
  frozen_api_consumer_gate(root)
  ui_api_suite(root)
  println(
    "\nMinimoon " + product_series + " public API compatibility checks passed",
  )
}
