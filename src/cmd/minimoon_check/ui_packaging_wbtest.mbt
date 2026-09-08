///|
test "UI packaging stages maintained trees without prefiltering publication paths" {
  for
    name in ["docs", "examples", "source_test.mbt", ".moonignore", ".gitignore"] {
    assert_false(ui_packaging_local_path(name))
  }
  for
    name in [
      ".git", "_build", ".mooncakes", "node_modules", "dist", ".env", ".env.local",
      "private.key", "private.pem", "build.log", "devtools.evidence.json", "project.private.config.json",
    ] {
    assert_true(ui_packaging_local_path(name))
  }
}

///|
test "UI packaging requires one archive in its own stage even when paths contain spaces" {
  let stage = "/project/check stage"
  let archive = stage + "/_build/publish/test-ui-0.0.1.zip"
  assert_eq(
    ui_packaging_archive_path(
      "Check passed\nPackage to " + archive + "\n",
      stage,
    ),
    archive,
  )
  for
    listing in [
      "Check passed\n",
      "Package to " + archive + "\nPackage to " + archive,
      "Package to _build/publish/test-ui-0.0.1.zip",
      "Package to /project/old/_build/publish/test-ui-0.0.1.zip",
      "Package to /project/check stage/_build/publish/../../old.zip",
    ] {
    let rejected = try {
      ignore(ui_packaging_archive_path(listing, stage))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
async test "UI packaging isolates inherited ignores and lets moonignore filter source fixtures" {
  let root = @env.current_dir().unwrap()
  let base = create_check_temporary(
    join(root, "_build/check-tmp-tests"),
    "test",
  )
  errdefer @fs.rmdir(base, recursive=true)
  let (code, _, _) = @process.collect_output("git", ["init", "--quiet", base])
  assert_eq(code, 0)
  write_ui_consumer_file(base, ".moonignore", "/staging/\n")
  let core = join(base, "core")
  write_ui_consumer_file(
    core, "moon.mod", "name = \"testaudit/packaging_core\"\nversion = \"0.0.1\"\nsource = \"src\"\n",
  )
  write_ui_consumer_file(core, "src/moon.pkg", "")
  write_ui_consumer_file(core, "src/lib.mbt", "pub fn value() -> Int { 1 }\n")
  let source = join(base, "source")
  write_ui_consumer_file(
    source, "moon.mod", "name = \"testaudit/packaging_ui\"\nversion = \"0.0.1\"\nsource = \"src\"\nimport { \"testaudit/packaging_core@0.0.1\" }\n",
  )
  write_ui_consumer_file(
    source, "src/moon.pkg", "import { \"testaudit/packaging_core\" @core }\n",
  )
  write_ui_consumer_file(
    source, "src/lib.mbt", "pub fn value() -> Int { @core.value() }\n",
  )
  write_ui_consumer_file(
    source, "src/lib_test.mbt", "test { assert_eq(1, 1) }\n",
  )
  write_ui_consumer_file(source, "docs/local.md", "not published\n")
  write_ui_consumer_file(source, "examples/fixture.txt", "not published\n")
  write_ui_consumer_file(source, ".env.local", "not copied\n")
  write_ui_consumer_file(source, ".gitignore", "/src/\n")
  write_ui_consumer_file(
    source,
    ".moonignore",
    @fs.read_file(join(root, "ui/.moonignore")).text(),
  )
  let stage = create_check_temporary(join(base, "staging"), "candidate")
  let staged_ui = prepare_ui_packaging_stage(source, core, stage)
  for path in ["docs/local.md", "examples/fixture.txt", "src/lib_test.mbt"] {
    assert_true(@fs.exists(join(staged_ui, path)))
  }
  assert_false(@fs.exists(join(staged_ui, ".env.local")))
  assert_false(@fs.exists(join(source, ".git")))
  let (archive, paths) = package_staged_ui(stage, staged_ui)
  assert_true(@fs.read_file(archive).binary().length() > 22)
  assert_eq(paths, ["moon.mod", "src/lib.mbt", "src/moon.pkg"])
  // The sibling/core entry is not a package member, and the remaining local
  // fixtures disappear because of .moonignore, not because of our copier.
  assert_false(paths.any(path => path.has_prefix("core/")))
  @fs.remove(join(staged_ui, ".moonignore"))
  @fs.remove(join(staged_ui, ".gitignore"))
  let (_, unfiltered) = package_staged_ui(stage, staged_ui)
  for path in ["docs/local.md", "examples/fixture.txt", "src/lib_test.mbt"] {
    assert_true(unfiltered.contains(path))
  }
  @fs.rmdir(base, recursive=true)
}

///|
async test "UI packaging rejects unexpected symlinks instead of copying external data" {
  let root = @env.current_dir().unwrap()
  let base = create_check_temporary(
    join(root, "_build/check-tmp-tests"),
    "test",
  )
  errdefer @fs.rmdir(base, recursive=true)
  let source = join(base, "source")
  @fs.mkdir(source)
  @fs.symlink(target=root, join(source, "external"))
  let rejected = try {
    copy_ui_packaging_tree(source, join(base, "copy"))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  @fs.rmdir(base, recursive=true)
}
