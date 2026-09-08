///|
test "physical file lines preserve UTF-8 and CRLF byte counts" {
  for
    pair in [
      ("", 0),
      ("one", 1),
      ("one\n", 1),
      ("\n", 1),
      ("one\n\n", 2),
      ("中\r\n文", 2),
      ("a\rb", 1),
    ] {
    let (text, lines) = pair
    assert_eq(physical_lines(text), lines)
  }
  let (entry, text) = file_metric(
    "src/中文 file.mbt",
    @utf8.encode("中文\r\nA"),
  )
  assert_eq(entry.bytes, 9)
  assert_eq(entry.physical_lines, Some(2))
  assert_eq(entry.language, "MoonBit")
  assert_eq(text, Some("中文\r\nA"))
  let (empty, _) = file_metric("empty", b"")
  assert_eq(empty.physical_lines, Some(0))
}

///|
test "binary files never receive physical source lines" {
  for content in [b"a\x00b\n", b"\xFF\n", b"\xC0\xAF"] {
    let (entry, text) = file_metric("image.bin", content)
    assert_eq(entry.bytes, content.length())
    assert_eq(entry.physical_lines, None)
    assert_eq(text, None)
    assert_eq(entry.language, "Binary")
  }
}

///|
test "Git NUL paths preserve whitespace quotes unicode and lexical order" {
  assert_eq(
    metrics_paths(
      "z\u{0000}aa\u{0000}a b\u{0000}line\n\t\"中\u{0000}aa\u{0000}",
    ),
    ["a b", "aa", "line\n\t\"中", "z"],
  )
  assert_eq(metrics_paths(""), [])
  for
    bad in [
      "not terminated", "../escape\u{0000}", "/absolute\u{0000}", "a//b\u{0000}",
      "a/./b\u{0000}",
    ] {
    let rejected = try {
      ignore(metrics_paths(bad))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
test "owners separate the UI fixture before the UI module and classify all scopes" {
  for
    pair in [
      ("ui/examples/showcase/src/pages/forms/page.mbt", ("ui_fixture", None)),
      ("ui/src/field.mbt", ("ui", None)),
      (
        "examples/miniapp_conformance_app/src/pages/home/page.mbt",
        ("core_fixture", None),
      ),
      ("templates/starter/src/pages/home/page.mbt", ("starter", None)),
      ("src/authoring_core.mbt", ("core", Some("framework"))),
      ("src/tooling_miniapp/generator.mbt", ("core", Some("tooling"))),
      ("src/cmd/minimoon_check/main.mbt", ("core", Some("validation"))),
      (
        "scripts/bridge/weapp_tailwindcss_adapter.mjs",
        ("core", Some("tooling")),
      ),
      ("README.md", ("repo", None)),
    ] {
    assert_eq(file_ownership(pair.0), pair.1)
  }
}

///|
test "generated roles precede source and frozen API snapshots precede interfaces" {
  for
    pair in [
      ("ui/examples/showcase/dist/app.js", "generated_artifact"),
      (
        "examples/miniapp_conformance_app/generated/manifest.json", "generated_artifact",
      ),
      ("ui/examples/showcase/styles/tailwind.wxss", "generated_artifact"),
      ("src/cmd/minimoon/templates.generated.mbt", "generated_artifact"),
      ("ui/src/pkg.generated.mbti", "generated_interface"),
      ("src/cmd/minimoon_check/fixtures/api/0.2/root.mbti", "api_snapshot"),
      ("src/cmd/minimoon_check/fixtures/api/0.2/consumer.mbt", "api_snapshot"),
      ("src/renderer_miniapp/renderer_bench.mbt", "benchmark"),
      ("ui/src/forms_test.mbt", "test"),
      ("src/internal_duplix/duplix_wbtest.mbt", "test"),
      ("ui/src/theme/palette.mbt", "maintained_source"),
      ("src/dist/maintained.mbt", "maintained_source"),
      ("ui/src/generated/maintained.mbt", "maintained_source"),
      ("ui/src/styles/custom.wxss", "maintained_source"),
      ("ui/examples/showcase/src/dist/maintained.mbt", "maintained_source"),
      (
        "examples/miniapp_conformance_app/src/styles/custom.wxss", "maintained_source",
      ),
      ("ui/README.md", "docs"),
      ("ui/moon.mod", "config"),
      ("docs/diagram.png", "asset"),
    ] {
    assert_eq(file_role(pair.0), pair.1)
  }
  assert_eq(file_language("ui/moon.mod", true), "MoonBit config")
  assert_eq(file_language("src/moon.pkg", true), "MoonBit config")
  assert_eq(file_language("moon.work", true), "MoonBit config")
}

///|
async fn metrics_test_command(root : String, args : Array[String]) -> Unit {
  let (code, _, stderr) = @process.collect_output("git", args, cwd=root)
  guard code == 0 else { raise Failure("fixture git failed: " + stderr.text()) }
}

///|
async test "file ledger reads tracked working-tree contents and opt-in nonignored additions" {
  let repository = metrics_repository_root(@env.current_dir().unwrap())
  let template = Path::join(repository, "_build/metrics-file-test.XXXXXX").to_string()
  let (code, stdout, _) = @process.collect_output("mktemp", ["-d", template])
  assert_eq(code, 0)
  let root = stdout.text().trim().to_owned()
  assert_true(
    root.has_prefix(
      Path::join(repository, "_build/metrics-file-test.").to_string(),
    ),
  )
  errdefer @fs.rmdir(root, recursive=true)
  metrics_test_command(root, ["init", "--quiet"])
  let special = "空 白\nline\t\".mbt"
  @fs.write_file(
    Path::join(root, ".gitignore").to_string(),
    "ignored.tmp\n",
    create_mode=CreateNew,
  )
  @fs.write_file(
    Path::join(root, special).to_string(),
    "staged\n",
    create_mode=CreateNew,
  )
  @fs.write_file(
    Path::join(root, "deleted.mbt").to_string(),
    "deleted\n",
    create_mode=CreateNew,
  )
  metrics_test_command(root, ["add", "--", ".gitignore", special, "deleted.mbt"])
  @fs.write_file(
    Path::join(root, special).to_string(),
    "中文\r\nA",
    create_mode=TruncateExisting,
  )
  @fs.remove(Path::join(root, "deleted.mbt").to_string())
  @fs.write_file(
    Path::join(root, "added.mbt").to_string(),
    "new\n",
    create_mode=CreateNew,
  )
  @fs.write_file(
    Path::join(root, "ignored.tmp").to_string(),
    "ignore\n",
    create_mode=CreateNew,
  )
  let tracked = measure_files(root, false)
  assert_eq(tracked.entries.map(entry => entry.path), [".gitignore", special])
  assert_eq(tracked.entries[1].bytes, 9)
  assert_eq(tracked.entries[1].physical_lines, Some(2))
  assert_eq(tracked.missing, ["deleted.mbt"])
  assert_eq(tracked.sources, [(special, "中文\r\nA")])
  let expanded = measure_files(root, true)
  assert_eq(expanded.entries.map(entry => entry.path), [
    ".gitignore", "added.mbt", special,
  ])
  assert_eq(expanded.missing, ["deleted.mbt"])
  let repeated = measure_files(root, true)
  assert_eq(file_ledger_json(expanded), file_ledger_json(repeated))
  assert_false(expanded.entries.any(entry => entry.path == "ignored.tmp"))
  @fs.symlink(
    target=Path::join(root, special).to_string(),
    Path::join(root, "linked.mbt").to_string(),
  )
  @fs.mkdir(Path::join(root, "actual-dir").to_string())
  @fs.write_file(
    Path::join(root, "actual-dir/file.mbt").to_string(),
    "private target",
    create_mode=CreateNew,
  )
  @fs.symlink(
    target=Path::join(root, "actual-dir").to_string(),
    Path::join(root, "linked-dir").to_string(),
  )
  for path in ["linked.mbt", "linked-dir/file.mbt"] {
    let rejected = try {
      ignore(metrics_regular_file(root, path))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  @fs.remove(Path::join(root, "linked.mbt").to_string())
  @fs.remove(Path::join(root, "linked-dir").to_string())
  @fs.rmdir(root, recursive=true)
}
