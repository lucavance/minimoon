///|
fn metrics_field(value : Json, key : String) -> Json? {
  match value {
    Object(fields) => fields.get(key)
    _ => None
  }
}

///|
fn metrics_count(value : Json?) -> Int? {
  match value {
    Some(Number(number, ..)) if number >= 0 && number <= 2147483647.0 => {
      let integer = number.to_int()
      if integer.to_double() == number {
        Some(integer)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn metrics_text(value : Json, key : String) -> String? {
  match metrics_field(value, key) {
    Some(String(text)) => Some(text)
    _ => None
  }
}

///|
fn metrics_totals(entries : Array[Json]) -> Json? {
  let mut bytes = 0
  let mut lines = 0
  let mut text_files = 0
  let mut binary_files = 0
  for entry in entries {
    guard metrics_count(metrics_field(entry, "bytes")) is Some(size) else {
      return None
    }
    bytes += size
    match metrics_field(entry, "physicalLines") {
      Some(Null) => {
        guard metrics_text(entry, "encoding") == Some("binary") else {
          return None
        }
        binary_files += 1
      }
      value => {
        guard metrics_count(value) is Some(count) &&
          metrics_text(entry, "encoding") == Some("utf8") else {
          return None
        }
        lines += count
        text_files += 1
      }
    }
  }
  Some(
    Json::object({
      "files": Json::number(entries.length().to_double()),
      "bytes": Json::number(bytes.to_double()),
      "physicalLines": Json::number(lines.to_double()),
      "textFiles": Json::number(text_files.to_double()),
      "binaryFiles": Json::number(binary_files.to_double()),
    }),
  )
}

///|
fn metrics_same_totals(expected : Json, actual : Json) -> Bool {
  ["files", "bytes", "physicalLines", "textFiles", "binaryFiles"].all(key => {
    metrics_count(metrics_field(expected, key)) ==
    metrics_count(metrics_field(actual, key)) &&
    metrics_count(metrics_field(actual, key)) != None
  })
}

///|
fn metrics_group_problems(
  files : Json,
  name : String,
  field : String,
  entries : Array[Json],
) -> Array[String] {
  let errors : Array[String] = []
  guard metrics_field(files, name) is Some(Array(groups)) else {
    return ["missing metrics grouping: " + name]
  }
  let keys : Array[String] = []
  for entry in entries {
    guard metrics_text(entry, field) is Some(key) else {
      errors.push("missing metrics entry classification: " + field)
      continue
    }
    if !keys.contains(key) {
      keys.push(key)
    }
  }
  keys.sort_by((left, right) => left.lexical_compare(right))
  let actual_keys : Array[String] = []
  for group in groups {
    guard metrics_text(group, "key") is Some(key) else {
      errors.push("missing metrics group key: " + name)
      continue
    }
    actual_keys.push(key)
    let selected = entries.filter(entry => {
      metrics_text(entry, field) == Some(key)
    })
    match metrics_totals(selected) {
      Some(expected) if metrics_same_totals(expected, group) => ()
      _ => errors.push("metrics group totals differ: " + name + "/" + key)
    }
  }
  if keys != actual_keys {
    errors.push(
      "metrics group keys are missing, duplicated or unsorted: " + name,
    )
  }
  errors
}

///|
fn metrics_report_problems(report : Json) -> Array[String] {
  let errors : Array[String] = []
  if metrics_count(metrics_field(report, "schemaVersion")) != Some(2) {
    errors.push("metrics schemaVersion must be 2")
  }
  guard metrics_field(report, "files") is Some(files) &&
    metrics_field(files, "entries") is Some(Array(entries)) &&
    metrics_field(files, "totals") is Some(totals) &&
    metrics_field(files, "missing") is Some(Array(missing)) &&
    metrics_field(report, "scope") is Some(scope) else {
    errors.push("metrics file ledger or scope is missing")
    return errors
  }
  if metrics_text(scope, "content") != Some("working-tree") ||
    metrics_count(metrics_field(scope, "selectedFiles")) !=
    Some(entries.length() + missing.length()) {
    errors.push("metrics scope does not describe selected worktree paths")
  }
  let paths : Array[String] = []
  for entry in entries {
    guard metrics_text(entry, "path") is Some(path) else {
      errors.push("metrics entry path is missing")
      continue
    }
    if paths.contains(path) {
      errors.push("duplicate metrics path: " + path)
    }
    paths.push(path)
  }
  let sorted = paths.copy()
  sorted.sort_by((left, right) => left.lexical_compare(right))
  if paths != sorted {
    errors.push("metrics paths are not sorted")
  }
  match metrics_totals(entries) {
    Some(expected) if metrics_same_totals(expected, totals) => ()
    _ => errors.push("metrics file totals differ from entries")
  }
  for
    pair in [
      ("byOwner", "owner"),
      ("byRole", "role"),
      ("byLanguage", "language"),
    ] {
    let (name, field) = pair
    errors.append(metrics_group_problems(files, name, field, entries))
  }
  errors.append(
    metrics_group_problems(
      files,
      "coreBreakdown",
      "area",
      entries.filter(entry => metrics_text(entry, "owner") == Some("core")),
    ),
  )
  match metrics_field(report, "embeddedScripts") {
    Some(embedded) =>
      errors.append(metrics_embedded_problems(embedded, entries))
    None => errors.push("metrics embedded-script ledger is missing")
  }
  errors
}

///|
async fn metrics_suite(root : String) -> Unit {
  run(root, "Metrics counting and inventory regressions", "moon", [
    "test", "src/cmd/minimoon_metrics", "--target", "native",
  ])
  println("\n==> Metrics schema, accounting and deterministic public CLI")
  let (git_code, git_output) = @process.collect_stdout(
    "git",
    ["ls-files", "-z", "--cached", "--others", "--exclude-standard"],
    cwd=root,
  )
  guard git_code == 0 else {
    abort("cannot independently enumerate metrics Git paths")
  }
  let expected_paths : Array[String] = []
  for part in git_output.text().split("\u{0000}") {
    let path = part.to_owned()
    if path != "" && !expected_paths.contains(path) {
      expected_paths.push(path)
    }
  }
  expected_paths.sort_by((left, right) => left.lexical_compare(right))
  let args = [
    "run", "src/cmd/minimoon", "--target", "native", "--", "metrics", "--include-untracked",
    "--json",
  ]
  let mut previous : String? = None
  for _ in 0..<2 {
    let (code, stdout, stderr) = @process.collect_output("moon", args, cwd=root)
    guard code == 0 else {
      abort("metrics command failed: " + stdout.text() + stderr.text())
    }
    let output = stdout.text()
    let report = @json.parse(output) catch {
      err => abort("metrics command did not produce JSON: \{err}")
    }
    let problems = metrics_report_problems(report)
    guard problems.is_empty() else {
      abort("metrics accounting failed:\n" + problems.join("\n"))
    }
    let scope = json_field(report, "scope")
    guard metrics_text(scope, "selection") == Some("tracked-and-untracked") &&
      metrics_field(scope, "includeUntracked") == Some(Json::boolean(true)) else {
      abort("metrics public CLI did not forward --include-untracked")
    }
    let files = json_field(report, "files")
    guard json_field(files, "missing") is Array([]) else {
      abort("metrics repository inventory contains missing tracked files")
    }
    guard json_field(files, "entries") is Array(entries) else {
      abort("metrics repository entries are missing")
    }
    guard entries.map(entry => json_string(entry, "path")) == expected_paths else {
      abort("metrics file ledger differs from independent Git path enumeration")
    }
    guard json_field(files, "byOwner") is Array(owners) else {
      abort("metrics owners are missing")
    }
    for owner in ["core", "ui", "core_fixture", "ui_fixture", "starter", "repo"] {
      guard owners.any(entry => metrics_text(entry, "key") == Some(owner)) else {
        abort("metrics omitted repository owner: " + owner)
      }
    }
    match previous {
      Some(value) if value != output =>
        abort("metrics JSON is not deterministic")
      _ => previous = Some(output)
    }
  }
  println("Metrics schema v2, independent ledgers and stable output passed")
}
