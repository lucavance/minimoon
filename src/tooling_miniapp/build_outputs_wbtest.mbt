///|
test "build output paths keep configurable destinations separate from source and temporary files" {
  assert_true(
    output_path_problem(
      "deploy/miniapp", "styles/custom.wxss", "styles/tailwind.css", "app.json",
    )
    is None,
  )
  assert_true(
    output_path_problem(
      "dist", "dist/app.wxss", "styles/tailwind.css", "app.json",
    )
    is None,
  )
  for
    dist in [
      ".", "src", "src/pages", "generated", "_build", "_build/output", "styles",
    ] {
    assert_true(
      output_path_problem(
        dist, "styles/app.wxss", "styles/tailwind.css", "app.json",
      )
      is Some(_),
    )
  }
  for
    source in [
      "styles/tailwind.css", "styles/.minimoon-tailwind-input.css", "generated/manifest.json",
      "generated/devtools.evidence.json", "generated/verify_report.json", "moon.mod",
      "src/page.mbt", "generated/diagnostics.json/nested.wxss", "generated/devtools.evidence.json/nested.wxss",
      "dist/project.private.config.json/nested.wxss",
    ] {
    assert_true(
      output_path_problem("dist", source, "styles/tailwind.css", "app.json")
      is Some(_),
    )
  }
  assert_true(
    output_path_problem(
      "dist", "styles/app.wxss", "styles/.minimoon-tailwind-input.css", "app.json",
    )
    is Some(("tailwindInput", _)),
  )
  assert_true(
    output_path_problem(
      "lib",
      "styles/app.wxss",
      "styles/tailwind.css",
      "app.json",
      source_paths=["lib"],
    )
    is Some(("distDir", _)),
  )
}

///|
test "module source protection accepts TOML spacing literal strings and comments" {
  assert_eq(module_source_directory("source=\"lib\"\n"), Some("lib"))
  assert_eq(
    module_source_directory("source = 'library' # native packages\n"),
    Some("library"),
  )
  assert_eq(
    module_source_directory(
      "name = \"app\"\n source = \"sources/code\" # note\n",
    ),
    Some("sources/code"),
  )
  assert_eq(module_source_directory("name = \"app\"\n"), None)
}

///|
async test "output validation rejects dangling links and symlinked parents without following them" {
  let root = @fs.tmpdir(prefix="minimoon-output-links")
  defer @fs.rmdir(root, recursive=true)
  write(join(root, "outside/keep.wxss"), "outside bytes")
  @fs.symlink(target=join(root, "outside"), join(root, "linked"))
  @fs.symlink(target=join(root, "missing"), join(root, "dangling"))
  for (relative, directory) in [("linked/app.wxss", false), ("dangling", true)] {
    let failed = try {
      validate_output_path(root, relative, directory)
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
  validate_output_path(root, "new/styles/app.wxss", false)
  assert_eq(
    @fs.read_file(join(root, "outside/keep.wxss")).text(),
    "outside bytes",
  )
  assert_false(@fs.exists(join(root, "outside/app.wxss")))
}

///|
async test "preparation protects the actual module source and declared packages before generation" {
  let root = @fs.tmpdir(prefix="minimoon-output-source")
  defer @fs.rmdir(root, recursive=true)
  write(
    join(root, "moon.mod"),
    "name = \"test/app\"\nsource='library' # custom source\n",
  )
  write(join(root, "library/pages/home/moon.pkg"), "")
  write(join(root, "library/keep.mbt"), "source bytes")
  let config = join(root, "miniapp.minimoon.json")
  write_json(
    config,
    Json::object({
      "schemaVersion": json_int(@versions.app_contract_version()),
      "name": Json::string("test"),
      "distDir": Json::string("library"),
      "pages": Json::array([
        Json::object({ "package": Json::string("library/pages/home") }),
      ]),
    }),
  )
  let failed = try {
    let _ = prepare_build(config)
    false
  } catch {
    error => error.to_string().contains("MMN1012")
  }
  assert_true(failed)
  assert_eq(
    @fs.read_file(join(root, "library/keep.mbt")).text(),
    "source bytes",
  )
  assert_false(@fs.exists(join(root, "_build")))
}

///|
async test "failed build diagnostics preserve this attempt's precise error and then report a different failure" {
  let root = @fs.tmpdir(prefix="minimoon-build-diagnostics")
  defer @fs.rmdir(root, recursive=true)
  let config = join(root, "miniapp.minimoon.json")
  let file = join(root, "generated/diagnostics.json")
  let document = { value: Json::empty_object(), spans: Map([]), }
  let mut previous = ""
  for _ in 0..<2 {
    if @fs.exists(file) {
      @fs.remove(file)
    }
    let error = write_config_issue(
      document, config, "MMN2001", "page compile failed", "/pages/0/package", "Run moon check.",
    )
    write_build_failure(config, error)
    let diagnostic = @fs.read_file(file).text()
    if previous != "" {
      assert_eq(diagnostic, previous)
    }
    previous = diagnostic
    assert_true(diagnostic.contains("MMN2001"))
    assert_false(diagnostic.contains("MMN2003"))
  }
  @fs.remove(file)
  write_build_failure(config, "Tailwind generation failed in MMN-example")
  let diagnostic = @fs.read_file(file).text()
  assert_true(diagnostic.contains("MMN2003"))
  assert_false(diagnostic.contains("MMN2001"))
}
