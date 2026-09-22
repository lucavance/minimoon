///|
// This is a temporary mock-host consumer, never evidence for a release fixture.
async fn verification_regression_gate(
  root : String,
  executable : String,
) -> Unit {
  let temp = check_temporary("minimoon-verification")
  defer cleanup_check_temporary(temp)
  let app = join(temp, "app with spaces")
  let config_path = join(app, "custom app.json")
  for
    (file, content) in [
      (
        "moon.mod",
        "name = \"test/verification\"\nsource = \"src\"\nimport { \"lampclaw/minimoon@" +
        @versions.product_version() +
        "\", }\n",
      ),
      (
        "src/moon.pkg", "import { \"lampclaw/minimoon\", }\nsupported_targets = \"js\"\n",
      ),
      (
        "src/app.mbt",
        (
          #|///|
          #|pub struct Deps { count : @minimoon.Shared[Int] }
          #|///|
          #|pub fn program() -> @minimoon.App[Deps] {
          #|  @minimoon.app(build=context => {
          #|    let (count, _) = context.create_state(0,
          #|      update=(count, delta : Int, _) => @minimoon.no_cmd(count + delta),
          #|      subscriptions=(_, emit) => context.every(key="resident-timer", interval_ms=60000, command=emit(1)),
          #|    )
          #|    { count, }
          #|  })
          #|}
        ),
      ),
      (
        "src/pages/home/moon.pkg", "import { \"lampclaw/minimoon\", \"test/verification\" @application, }\nsupported_targets = \"js\"\n",
      ),
      (
        "src/pages/home/page.mbt",
        (
          #|///|
          #|pub fn program(deps : @application.Deps) -> @minimoon.Page {
          #|  @minimoon.page(id="home", route=@minimoon.route("pages/home/home"), title="Timer",
          #|    build=context => context.bind(deps.count).view(count => @minimoon.p(count.to_string())),
          #|  )
          #|}
        ),
      ),
      (
        "styles/tailwind.css", "@import \"tailwindcss\" source(none);\n@source \"../src/**/*.mbt\";\n",
      ),
      (
        "custom app.json", "{\"schemaVersion\":11,\"name\":\"verification\",\"distDir\":\"output/mini app\",\"application\":{\"package\":\"src\"},\"pages\":[{\"package\":\"src/pages/home\"}]}\n",
      ),
      ("dist/app.json", "poisoned stale default output"),
    ] {
    write_ui_consumer_file(app, file, content)
  }
  @fs.symlink(
    target=join(root, "node_modules"),
    join(app, "node_modules"),
    force_symlink=true,
  )
  run(
    root,
    "Bind App timer verifier consumer",
    "moon",
    ["work", "init", root, app],
    cwd=temp,
  )
  @async.with_timeout(180000, () => {
    run(
      root,
      "CLI custom config and resident App timer candidate",
      executable,
      ["verify", config_path, "--candidate"],
      cwd=app,
    )
  })
  let report = read_json(app, "generated/verify_report.json")
  guard json_string(report, "status") == "passed" &&
    !json_bool(report, "release") else {
    abort("App timer/custom output candidate failed")
  }
  let fingerprint = @verify.artifact_fingerprint(app, config_path~)
  guard json_string(report, "artifactFingerprint") == fingerprint else {
    abort("CLI verification and custom output fingerprint differ")
  }
  write_ui_consumer_file(
    app, "output/mini app/project.private.config.json", "{\"appid\":\"temporary-test-only\"}",
  )
  guard @verify.artifact_fingerprint(app, config_path~) == fingerprint else {
    abort("custom output private config changed its fingerprint")
  }
  let output_prefix = join(app, "output/mini app") + "/"
  let output_snapshot = build_output_snapshot(app, dist="output/mini app").filter(entry => {
      entry.0.has_prefix(output_prefix)
    },
  )
  require_command_failure(
    "Custom output release requires evidence",
    executable,
    ["verify", config_path, "--release"],
    app,
    "verification report contains failed checks",
  )
  guard build_output_snapshot(app, dist="output/mini app").filter(entry => {
      entry.0.has_prefix(output_prefix)
    }) ==
    output_snapshot else {
    abort("custom output release rebuild changed deterministic artifact bytes")
  }
  run(
    root,
    "Record temporary custom config mock evidence",
    executable,
    [
      "devtools", "record", config_path, "--status", "passed", "--recorded-at", "2000-01-01T00:00:00Z",
      "--tool-version", "fixture-devtools", "--notes", "temporary automated test only",
    ],
    cwd=app,
  )
  let evidence = read_json(app, "generated/devtools.evidence.json")
  guard json_string(evidence, "artifactFingerprint") == fingerprint &&
    json_string(evidence, "app") == "verification" else {
    abort("record did not use the selected custom config and output")
  }
  run(
    root,
    "Matching custom output release evidence",
    executable,
    ["verify", config_path, "--release"],
    cwd=app,
  )
  let page_file = join(app, "src/pages/home/page.mbt")
  @fs.write_file(
    page_file,
    @fs.read_file(page_file)
    .text()
    .replace_all(old="Timer", new="Changed Timer"),
    create_mode=CreateOrTruncate,
  )
  require_command_failure(
    "Changed custom output invalidates evidence",
    executable,
    ["verify", config_path, "--release"],
    app,
    "verification report contains failed checks",
  )
  run(
    root,
    "Restore custom output candidate state",
    executable,
    ["verify", config_path, "--candidate"],
    cwd=app,
  )
  let summary = read_json(app, "generated/release_summary.json")
  guard candidate_summary_is_public(summary) &&
    @fs.read_file(join(app, "dist/app.json")).text() ==
    "poisoned stale default output" else {
    abort(
      "custom verifier must preserve candidate state and ignore stale default output",
    )
  }
  require_build_temporary_cleanup(app)
}
