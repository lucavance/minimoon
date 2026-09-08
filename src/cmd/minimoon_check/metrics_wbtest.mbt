///|
fn metrics_test_group(key : String, entries : Array[Json]) -> Json {
  guard metrics_totals(entries) is Some(Object(fields)) else {
    abort("invalid test metrics")
  }
  fields["key"] = Json::string(key)
  Json::object(fields)
}

///|
fn metrics_test_report() -> Json {
  let source = Json::object({
    "path": Json::string("src/example.mbt"),
    "owner": Json::string("core"),
    "area": Json::string("framework"),
    "role": Json::string("maintained_source"),
    "language": Json::string("MoonBit"),
    "bytes": Json::number(20),
    "physicalLines": Json::number(2),
    "encoding": Json::string("utf8"),
  })
  let binary = Json::object({
    "path": Json::string("ui/image.png"),
    "owner": Json::string("ui"),
    "area": Json::null(),
    "role": Json::string("asset"),
    "language": Json::string("Binary"),
    "bytes": Json::number(80),
    "physicalLines": Json::null(),
    "encoding": Json::string("binary"),
  })
  let entries = [source, binary]
  Json::object({
    "schemaVersion": Json::number(2),
    "scope": Json::object({
      "content": Json::string("working-tree"),
      "selection": Json::string("tracked"),
      "includeUntracked": Json::boolean(false),
      "selectedFiles": Json::number(2),
    }),
    "files": Json::object({
      "entries": Json::array(entries),
      "missing": Json::array([]),
      "totals": metrics_totals(entries).unwrap(),
      "byOwner": Json::array([
        metrics_test_group("core", [source]),
        metrics_test_group("ui", [binary]),
      ]),
      "byRole": Json::array([
        metrics_test_group("asset", [binary]),
        metrics_test_group("maintained_source", [source]),
      ]),
      "byLanguage": Json::array([
        metrics_test_group("Binary", [binary]),
        metrics_test_group("MoonBit", [source]),
      ]),
      "coreBreakdown": Json::array([metrics_test_group("framework", [source])]),
    }),
    // Embedded counts deliberately overlap source lines and never enter totals.
    "embeddedScripts": Json::object({
      "sourceLines": Json::number(1),
      "sourceBytes": Json::number(9),
      "sourceFiles": Json::number(1),
      "categories": Json::object({
        "production": Json::object({
          "sourceLines": Json::number(1),
          "sourceBytes": Json::number(9),
          "sourceFiles": Json::number(1),
          "declarations": Json::number(1),
        }),
      }),
      "entries": Json::array([
        Json::object({
          "file": Json::string("src/example.mbt"),
          "declaration": Json::string("fn:example"),
          "category": Json::string("production"),
          "sourceLines": Json::number(1),
          "sourceBytes": Json::number(9),
          "literals": Json::number(1),
        }),
      ]),
      "coverage": Json::object({
        "sourceFilesScanned": Json::number(1),
        "registeredDeclarations": Json::number(1),
        "unclassifiedDeclarations": Json::number(0),
        "literalsScanned": Json::number(1),
      }),
    }),
  })
}

///|
test "metrics gate accepts independently accounted text binary and embedded ledgers" {
  let report = metrics_test_report()
  assert_eq(metrics_report_problems(report), [])
  let totals = json_field(json_field(report, "files"), "totals")
  assert_eq(metrics_count(metrics_field(totals, "files")), Some(2))
  assert_eq(metrics_count(metrics_field(totals, "bytes")), Some(100))
  assert_eq(metrics_count(metrics_field(totals, "physicalLines")), Some(2))
  assert_eq(metrics_count(Some(Json::number(-1))), None)
  assert_eq(metrics_count(Some(Json::number(0.5))), None)
  assert_eq(metrics_count(Some(Json::number(2147483648.0))), None)
}

///|
test "metrics gate rejects missing UI grouping and copied aggregate totals" {
  let report = metrics_test_report()
  guard json_field(report, "files") is Object(files) else { abort("fixture") }
  guard files["byOwner"] is Array(owners) else { abort("fixture") }
  files["byOwner"] = Json::array([owners[0]])
  assert_true(
    metrics_report_problems(report).any(message => message.contains("byOwner")),
  )
  guard files["totals"] is Object(totals) else { abort("fixture") }
  totals["bytes"] = Json::number(101)
  assert_true(
    metrics_report_problems(report).contains(
      "metrics file totals differ from entries",
    ),
  )
}

///|
test "metrics gate rejects duplicate paths and legacy schema" {
  let report = metrics_test_report()
  guard report is Object(root) else { abort("fixture") }
  root["schemaVersion"] = Json::number(1)
  guard json_field(json_field(report, "files"), "entries") is Array(entries) else {
    abort("fixture")
  }
  guard entries[1] is Object(binary) else { abort("fixture") }
  binary["path"] = Json::string("src/example.mbt")
  let problems = metrics_report_problems(report)
  assert_true(problems.contains("metrics schemaVersion must be 2"))
  assert_true(problems.contains("duplicate metrics path: src/example.mbt"))
}

///|
test "metrics gate rejects invalid binary line counts and omitted ledgers" {
  assert_false(metrics_report_problems(Json::empty_object()).is_empty())
  let report = metrics_test_report()
  guard json_field(json_field(report, "files"), "entries") is Array(entries) else {
    abort("fixture")
  }
  guard entries[1] is Object(binary) else { abort("fixture") }
  binary["physicalLines"] = Json::number(0)
  assert_true(
    metrics_report_problems(report).contains(
      "metrics file totals differ from entries",
    ),
  )
}

///|
test "metrics gate rejects incomplete duplicate and miscounted embedded ledgers" {
  let report = metrics_test_report()
  guard report is Object(root) else { abort("fixture") }
  let original = root["embeddedScripts"]
  root["embeddedScripts"] = Json::empty_object()
  assert_true(
    metrics_report_problems(report).any(message => {
      message.contains("coverage are missing")
    }),
  )
  root["embeddedScripts"] = original
  guard original is Object(embedded) else { abort("fixture") }
  embedded["sourceBytes"] = Json::number(100)
  assert_true(
    metrics_report_problems(report).contains(
      "embedded metrics byte or file totals differ from entries",
    ),
  )
  guard embedded["entries"] is Array(entries) else { abort("fixture") }
  entries.push(entries[0])
  assert_true(
    metrics_report_problems(report).contains(
      "duplicate embedded metrics declaration",
    ),
  )
}
