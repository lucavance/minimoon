///|
fn embedded_test_int(value : Json, key : String) -> Int {
  match value {
    Object(fields) =>
      match fields.get(key) {
        Some(Number(value, ..)) => value.to_int()
        _ => abort("missing numeric field " + key)
      }
    _ => abort("expected metrics object")
  }
}

///|
fn embedded_test_failure(
  sources : Array[(String, String)],
  inventory : Array[EmbeddedInventoryEntry],
) -> String {
  try {
    ignore(embedded_metrics_with_inventory(sources, inventory))
    ""
  } catch {
    error => error.to_string()
  }
}

///|
test "embedded inventory rejects unregistered raw quoted and extern source" {
  for
    source in [
      "fn source() -> String {\n #|console.log(1)\n}", "fn source() -> String { \"const value=1;\\n\" }",
      "extern \"js\" fn source() -> Unit = \"namedBinding\"", "fn source(value : String) -> String {\n $|console.log(\"\\{value}\")\n}",
    ] {
    assert_true(
      embedded_test_failure([("new.mbt", source)], []).contains(
        "unclassified declaration",
      ),
    )
  }
  let css = "fn css() -> String {\n #|page { color: red; }\n}"
  let report = embedded_metrics_with_inventory([("css.mbt", css)], [
    embedded_entry("css.mbt", "fn:css", "excluded", Excluded, reason="CSS"),
  ])
  assert_eq(embedded_test_int(report, "sourceBytes"), 0)
}

///|
test "embedded ledger counts unique source lines and excludes mirrored source" {
  let source = "fn source() -> String { \"const a=1;\" + \"const b=2;\" }"
  let mirror = "fn mirror() -> String {\n #|const a=1;const b=2;\n}"
  let report = embedded_metrics_with_inventory(
    [("source.mbt", source), ("mirror.mbt", mirror)],
    [
      embedded_entry("source.mbt", "fn:source", "production", AllLiterals),
      embedded_entry(
        "mirror.mbt",
        "fn:mirror",
        "excluded",
        Excluded,
        reason="adapter mirror",
      ),
    ],
  )
  assert_eq(embedded_test_int(report, "sourceLines"), 1)
  assert_eq(embedded_test_int(report, "sourceBytes"), 20)
  assert_eq(embedded_test_int(report, "sourceFiles"), 1)
  let second = embedded_metrics_with_inventory(
    [("a.mbt", source), ("b.mbt", source)],
    [
      embedded_entry("a.mbt", "fn:source", "production", AllLiterals),
      embedded_entry("b.mbt", "fn:source", "production", AllLiterals),
    ],
  )
  assert_eq(embedded_test_int(second, "sourceLines"), 2)
  assert_eq(embedded_test_int(second, "sourceBytes"), 40)
}

///|
test "embedded inventory rejects stale ambiguous and overlapping selectors" {
  let source = "fn source() -> String { \"const a=1;\" }"
  let entry = embedded_entry("a.mbt", "fn:source", "production", AllLiterals)
  assert_true(
    embedded_test_failure([("a.mbt", source)], [entry, entry]).contains(
      "duplicate inventory entry",
    ),
  )
  assert_true(embedded_test_failure([], [entry]).contains("stale declaration"))
  assert_true(
    embedded_test_failure([("a.mbt", source + "\n///|\n" + source)], [entry]).contains(
      "ambiguous declaration",
    ),
  )
  assert_true(
    embedded_test_failure([("a.mbt", source)], [
      embedded_entry(
        "a.mbt",
        "fn:source",
        "production",
        SelectedLiterals(false, [("const ", 1), ("const a", 1)]),
      ),
    ]).contains("overlapping literal selectors"),
  )
  assert_true(
    embedded_test_failure([("a.mbt", source)], [
      embedded_entry(
        "a.mbt",
        "fn:source",
        "production",
        SelectedLiterals(false, [("missing", 1)]),
      ),
    ]).contains("stale literal selector"),
  )
  assert_true(
    embedded_test_failure([("a.mbt", source), ("a.mbt", source)], [entry]).contains(
      "duplicate source file",
    ),
  )
}

///|
test "embedded source metrics never expand escaped runtime lines" {
  let source = "fn source() -> String { \"月\\n文\\n\" }"
  let report = embedded_metrics_with_inventory([("a.mbt", source)], [
    embedded_entry("a.mbt", "fn:source", "production", AllLiterals),
  ])
  assert_eq(embedded_test_int(report, "sourceLines"), 1)
  assert_eq(embedded_test_int(report, "sourceBytes"), 10)
  let interpolated = "fn source() -> String { \"const value=\\{dynamic};\" }"
  assert_true(
    embedded_test_failure([("a.mbt", interpolated)], [
      embedded_entry("a.mbt", "fn:source", "production", AllLiterals),
    ]).contains("interpolated literal"),
  )
  assert_true(
    embedded_test_failure(
      [
        (
          "a.mbt", "fn source(value : Int) -> String {\n $|console.log(\\{value})\n}",
        ),
      ],
      [embedded_entry("a.mbt", "fn:source", "production", RawLiterals)],
    ).contains("interpolated literal"),
  )
}

///|
test "embedded selectors audit missed new scripts and exact expected matches" {
  let source = "fn source() -> String {\n #|const raw=1;\n + \"const one=1;\" + \"const two=2;\" }"
  for extraction in [RawLiterals, SelectedLiterals(true, [("const one", 1)])] {
    assert_true(
      embedded_test_failure([("a.mbt", source)], [
        embedded_entry("a.mbt", "fn:source", "production", extraction),
      ]).contains("unclassified literal"),
    )
  }
  assert_true(
    embedded_test_failure([("a.mbt", source)], [
      embedded_entry(
        "a.mbt",
        "fn:source",
        "production",
        SelectedLiterals(true, [("const ", 1)]),
      ),
    ]).contains("ambiguous literal selector"),
  )
  let report = embedded_metrics_with_inventory([("a.mbt", source)], [
    embedded_entry(
      "a.mbt",
      "fn:source",
      "production",
      SelectedLiterals(true, [("const one", 1)]),
      ignored_literals=[("const two=2;", 1)],
    ),
  ])
  assert_eq(embedded_test_int(report, "sourceBytes"), 25)
  for ignored in [[("missing", 1)], [("const two=2;", 2)]] {
    assert_true(
      embedded_test_failure([("a.mbt", source)], [
        embedded_entry(
          "a.mbt",
          "fn:source",
          "production",
          RawLiterals,
          ignored_literals=ignored,
        ),
      ]).contains("ignored literal selector"),
    )
  }
  assert_true(
    embedded_test_failure([("a.mbt", source)], [
      embedded_entry(
        "a.mbt",
        "fn:source",
        "production",
        ExceptLiterals(["missing"]),
      ),
    ]).contains("stale excluded literal selector"),
  )
  assert_true(
    embedded_test_failure([("a.mbt", source)], [
      embedded_entry("a.mbt", "fn:source", "production", AllLiterals, ignored_literals=[
        ("const two=2;", 1),
      ]),
    ]).contains("overlapping selected and ignored"),
  )
}
