///|
test "file totals count binary bytes but not binary lines" {
  let entries = [
    file_metric("src/a.mbt", b"a\n").0,
    file_metric("ui/src/b.mbt", b"b").0,
    file_metric("asset.bin", b"\x00\n").0,
  ]
  let totals = total_files(entries)
  assert_eq(totals.files, 3)
  assert_eq(totals.bytes, 5)
  assert_eq(totals.physical_lines, 2)
  assert_eq(totals.text_files, 2)
  assert_eq(totals.binary_files, 1)
  assert_eq(
    Json::object(totals_fields(totals)),
    Json::object({
      "files": 3,
      "bytes": 5,
      "physicalLines": 2,
      "textFiles": 2,
      "binaryFiles": 1,
    }),
  )
}

///|
test "schema v2 keeps embedded payload and missing files outside file totals" {
  let ledger : FileLedger = {
    entries: [file_metric("src/a.mbt", b"a\n").0],
    missing: ["missing.mbt"],
    sources: [],
  }
  let embedded : Json = { "sourceLines": 200, "sourceBytes": 1000 }
  let report = metrics_report(ledger, embedded, false)
  guard report is Object(fields) else { fail("report must be an object") }
  assert_eq(fields["schemaVersion"], 2)
  assert_eq(fields["embeddedScripts"], embedded)
  for
    old in [
      "moonbit_lines", "maintained_js_lines", "adapter_js_lines", "embedded_host_js_lines",
      "embedded_validation_js_lines", "generated_js_lines",
    ] {
    assert_false(fields.contains(old))
  }
  guard fields["scope"] is Object(scope) else {
    fail("scope must be an object")
  }
  assert_eq(scope["selection"], "tracked")
  assert_eq(scope["selectedFiles"], 2)
  guard fields["files"] is Object(files) else {
    fail("files must be an object")
  }
  assert_eq(files["missing"], ["missing.mbt"])
  assert_eq(files["totals"], {
    "files": 1,
    "bytes": 2,
    "physicalLines": 1,
    "textFiles": 1,
    "binaryFiles": 0,
  })
}

///|
test "group order is lexical rather than MoonBit shortlex and sums remain separate" {
  let entries = [
    file_metric("ui/src/b.mbt", b"b").0,
    file_metric("src/a.mbt", b"a\n").0,
  ]
  guard file_groups(entries, entry => entry.owner) is Array(groups) else {
    fail("groups must be an array")
  }
  guard groups[0] is Object(core) else { fail("group must be an object") }
  guard groups[1] is Object(ui) else { fail("group must be an object") }
  assert_eq(core["key"], "core")
  assert_eq(ui["key"], "ui")
  assert_eq(core["files"], 1)
  assert_eq(ui["files"], 1)
}

///|
test "default summary shows groups without detailed inventory or file entries" {
  let ledger : FileLedger = {
    entries: [file_metric("src/a.mbt", b"a\n").0],
    missing: [],
    sources: [],
  }
  let embedded : Json = {
    "sourceLines": 10,
    "sourceBytes": 100,
    "categories": {
      "production_host": { "sourceLines": 10, "sourceBytes": 100 },
    },
    "entries": [{ "declaration": "private_detail_should_not_print" }],
  }
  let summary = metrics_summary_lines(ledger, embedded, false).join("\n")
  for
    label in [
      "Owners:", "Core areas:", "Roles:", "Languages:", "production_host: 10 source lines, 100 source bytes",
    ] {
    assert_true(summary.contains(label))
  }
  assert_false(summary.contains("private_detail_should_not_print"))
  assert_false(summary.contains("src/a.mbt"))
}
