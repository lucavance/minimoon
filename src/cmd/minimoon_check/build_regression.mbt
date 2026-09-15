///|
// Compare every build output, including binary resources and local files.
// Diagnostics belong to the latest attempt rather than the last valid build.
async fn build_output_snapshot(
  app : String,
  dist? : String = "dist",
  source_wxss? : String = "styles/app.wxss",
) -> Array[(String, Bytes)] {
  let entries : Array[(String, Bytes)] = []
  for directory in [dist, "generated"] {
    let base = join(app, directory)
    if @fs.exists(base) {
      @fs.walk(
        base,
        (path, names) => {
          for name in names {
            let file = join(path, name)
            if file != join(app, "generated/diagnostics.json") &&
              @fs.kind(file, follow_symlink=false) == @fs.Regular {
              entries.push((file, @fs.read_file(file).binary()))
            }
          }
        },
        max_concurrency=1,
      )
    }
  }
  let stylesheet = join(app, source_wxss)
  if @fs.exists(stylesheet) && !entries.any(entry => entry.0 == stylesheet) {
    entries.push((stylesheet, @fs.read_file(stylesheet).binary()))
  }
  entries.sort_by((left, right) => left.0.lexical_compare(right.0))
  entries
}

///|
async fn require_build_temporary_cleanup(app : String) -> Unit {
  guard !@fs.exists(join(app, ".minimoon-tmp")) &&
    !@fs.exists(join(app, "styles/.minimoon-tailwind-input.css")) else {
    abort("build left compiler or Tailwind temporary files behind")
  }
  let transactions = join(app, "_build/minimoon-build")
  guard !@fs.exists(transactions) ||
    @fs.readdir(transactions, include_hidden=true).all(name => {
      name == "build.lock"
    }) else {
    abort("build left a completed transaction behind")
  }
}

///|
async fn require_no_initial_build_outputs(app : String) -> Unit {
  guard !@fs.exists(join(app, "dist")) && build_output_snapshot(app).is_empty() else {
    abort("initial build failure left partial application outputs")
  }
  require_build_temporary_cleanup(app)
}

///|
async fn transactional_build_gate(
  root : String,
  app : String,
  executable : String,
) -> Unit {
  let input_file = join(app, "styles/tailwind.css")
  let input = @fs.read_file(input_file).text()
  let broken_input = "@import \"definitely-missing-minimoon-test.css\";\n" +
    input
  let before = build_output_snapshot(app)
  let private_file = join(app, "dist/project.private.config.json")
  let evidence_file = join(app, "generated/devtools.evidence.json")
  let private_bytes = @fs.read_file(private_file).binary()
  let evidence_bytes = @fs.read_file(evidence_file).binary()
  @fs.write_file(input_file, broken_input, create_mode=CreateOrTruncate)
  for
    args in [
      ["build", app, "--mode", "release"],
      ["verify", app, "--candidate"],
    ] {
    require_command_failure(
      "Failed rebuild preserves complete application outputs", executable, args,
      app, "Tailwind generation failed",
    )
    guard build_output_snapshot(app) == before else {
      abort("failed rebuild changed dist, metadata, local files or source WXSS")
    }
    require_build_temporary_cleanup(app)
  }
  @fs.write_file(input_file, input, create_mode=CreateOrTruncate)
  let obsolete = join(app, "dist/obsolete-resource.bin")
  @fs.write_file(obsolete, b"\x00\xff\x80", create_mode=CreateNew)
  run(
    root,
    "Rebuild after Tailwind failure",
    executable,
    ["build", app, "--mode", "release"],
    cwd=app,
  )
  guard !@fs.exists(obsolete) &&
    @fs.read_file(private_file).binary() == private_bytes &&
    @fs.read_file(evidence_file).binary() == evidence_bytes else {
    abort(
      "successful rebuild must remove obsolete output and preserve local files",
    )
  }
  require_build_temporary_cleanup(app)

  // Exercise a custom directory with source WXSS nested inside that directory;
  // promotion must treat the nested file as part of the directory transaction.
  let config_file = join(app, "miniapp.minimoon.json")
  let config_source = @fs.read_file(config_file).text()
  let config = read_json(app, "miniapp.minimoon.json")
  guard config is Object(fields) else { abort("app config must be an object") }
  fields["distDir"] = Json::string("output/miniapp")
  fields["sourceWxss"] = Json::string("output/miniapp/styles/app.wxss")
  @fs.write_file(
    config_file,
    config.stringify(indent=2),
    create_mode=CreateOrTruncate,
  )
  run(
    root,
    "Build with nested custom output paths",
    executable,
    ["build", app, "--mode", "release"],
    cwd=app,
  )
  let custom_wxss = "output/miniapp/styles/app.wxss"
  guard @fs.read_file(join(app, custom_wxss)).binary() ==
    @fs.read_file(join(app, "output/miniapp/app.wxss")).binary() else {
    abort("custom source WXSS must match the generated app stylesheet")
  }
  let custom_before = build_output_snapshot(
    app,
    dist="output/miniapp",
    source_wxss=custom_wxss,
  )
  @fs.write_file(input_file, broken_input, create_mode=CreateOrTruncate)
  require_command_failure(
    "Failed rebuild preserves custom output paths",
    executable,
    ["build", app, "--mode", "release"],
    app,
    "Tailwind generation failed",
  )
  guard build_output_snapshot(
      app,
      dist="output/miniapp",
      source_wxss=custom_wxss,
    ) ==
    custom_before else {
    abort("failed rebuild changed custom output paths")
  }
  require_build_temporary_cleanup(app)
  @fs.write_file(input_file, input, create_mode=CreateOrTruncate)
  @fs.write_file(config_file, config_source, create_mode=CreateOrTruncate)
  @fs.rmdir(join(app, "output"), recursive=true)
  run(
    root,
    "Restore default output paths",
    executable,
    ["build", app, "--mode", "release"],
    cwd=app,
  )
}
