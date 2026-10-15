///|
fn rui_symbol(line : String) -> String? {
  if line.has_prefix("pub fn") {
    return line
      .split_once("(")
      .map(pair => pair.0.to_owned().rev_split_once(" ").unwrap().1.to_owned())
  }
  for
    prefix in [
      "type ", "pub(all) enum ", "pub(all) struct ", "pub enum ", "pub struct ",
    ] {
    if line.strip_prefix(prefix) is Some(suffix) {
      return Some(
        suffix
        .split(" ")
        .next()
        .unwrap()
        .to_owned()
        .split("[")
        .next()
        .unwrap()
        .to_owned(),
      )
    }
  }
  None
}

///|
fn rui_inventory_violations(
  expected : Map[String, String],
  entries : Array[Json],
) -> Array[String] {
  let seen : Set[String] = Set([])
  let problems : Array[String] = []
  for entry in entries {
    let key = json_string(entry, "package") + ":" + json_string(entry, "symbol")
    if seen.contains(key) {
      problems.push("duplicate RUI symbol: " + key)
    }
    seen.add(key)
    if expected.get(key) != Some(json_string(entry, "signature")) {
      problems.push("RUI declaration mismatch: " + key)
    }
  }
  for key, _ in expected {
    if !seen.contains(key) {
      problems.push("missing RUI symbol: " + key)
    }
  }
  problems
}

///|
async fn rui_inventory_gate(root : String) -> Unit {
  let historical = @fs.read_file(join(root, "ui/docs/rui_api_map.json")).binary()
  guard @crypto.bytes_to_hex_string(@crypto.sha256(historical)) ==
    "3b8c44d8d26a1c613f7091f17eededc3fcdbb702724f32f5efe82cb28f4953bf" else {
    abort("historical RUI 0.1.1 inventory must remain immutable")
  }
  let inventory = read_json(root, "ui/docs/rui_036_api_map.json")
  let baseline = json_field(inventory, "baseline")
  guard json_string(baseline, "commit") ==
    "7d5940fed9b1ba795c84582394024233997ec267" &&
    json_string(baseline, "rui_version") == "0.3.6" else {
    abort("RUI baseline pin changed")
  }
  let expected : Map[String, String] = Map([])
  let sources : Map[String, Array[String]] = Map([])
  for
    (name, digest) in [
      (
        "root", "8ebe0d97a2e63a903224c2ab7b675c7ad4f003887e61b4ecf4a89ecfee07b45a",
      ),
      (
        "markdown", "c3c424d0f89e2f4fad6de49570ae3067225f6375606757d4078896badcb89f74",
      ),
    ] {
    let source = @fs.read_file(
      join(root, "ui/docs/upstream/rui-0.3.6/" + name + ".mbti"),
    )
    guard @crypto.bytes_to_hex_string(@crypto.sha256(source.binary())) == digest else {
      abort("RUI pinned interface hash mismatch: " + name)
    }
    let lines = source.text().split("\n").map(line => line.to_owned()).collect()
    sources[name] = lines
    for line in lines {
      if rui_symbol(line) is Some(symbol) {
        let key = name + ":" + symbol
        guard !expected.contains(key) else {
          abort("duplicate pinned RUI declaration")
        }
        expected[key] = line
      }
    }
  }
  guard json_field(inventory, "entries") is Array(entries) &&
    entries.length() == 655 else {
    abort("RUI inventory must cover 655 consumer symbols")
  }
  let problems = rui_inventory_violations(expected, entries)
  guard problems.is_empty() else { abort(problems.join("; ")) }
  for entry in entries {
    let name = json_string(entry, "symbol")
    guard json_field(entry, "upstream_line") is Number(number, ..) else {
      abort("RUI line number missing")
    }
    let line = number.to_int()
    let lines = sources[json_string(entry, "package")]
    guard line > 0 &&
      line <= lines.length() &&
      lines[line - 1] == json_string(entry, "signature") else {
      abort("RUI source location mismatch: " + name)
    }
    guard ["adapted", "consolidated", "native_substitution", "partial"].contains(
      json_string(entry, "status"),
    ) else {
      abort("RUI status missing: " + name)
    }
    guard json_field(entry, "local") is Array(references) &&
      !references.is_empty() else {
      abort("RUI native mapping missing: " + name)
    }
    for reference in references {
      require_file(root, json_string(reference, "path"))
    }
    guard json_field(entry, "tests") is Array(tests) && !tests.is_empty() else {
      abort("RUI test mapping missing: " + name)
    }
    for item in tests {
      guard item is String(path) else { abort("invalid RUI test path") }
      require_file(root, path)
    }
  }
  guard json_string(inventory, "host_status") == "pending" else {
    abort("RUI source inventory must not claim real-host evidence")
  }
  println(
    "Offline RUI 0.3.6 inventory: 655 symbols, complete pinned source coverage",
  )
}
