///|
async fn application_host_smoke(root : String, dist : String) -> Unit {
  let temp = check_temporary("minimoon-application-smoke")
  let script = join(temp, "application_smoke.cjs")
  @fs.write_file(
    script,
    @host_validation.application_host_smoke_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let result = @process.collect_output("bun", [script, dist], cwd=root) catch {
    error => {
      @fs.rmdir(temp, recursive=true)
      abort("application smoke could not start: \{error}")
    }
  }
  @fs.rmdir(temp, recursive=true)
  let (code, stdout, stderr) = result
  guard code == 0 else {
    abort("application host smoke failed: " + stdout.text() + stderr.text())
  }
}

///|
async fn application_type_gate(root : String) -> Unit {
  let temp = check_temporary("minimoon-shared-types")
  let consumer = join(temp, "consumer")
  let source = join(consumer, "src")
  @fs.mkdir(source, permission=0o755, recursive=true)
  for
    entry in [
      (
        "moon.mod",
        "name = \"test/shared_types\"\nsource = \"src\"\nimport { \"lampclaw/minimoon@" +
        @versions.product_version() +
        "\", }\n",
      ),
      (
        "src/moon.pkg", "import { \"lampclaw/minimoon\", }\nsupported_targets = \"js+native\"\n",
      ),
      (
        "src/types.mbt", "pub struct Deps { count : @minimoon.Shared[Int]; emit : @minimoon.Emit[Int] }\n///|\npub fn start() -> @minimoon.App[Deps] {\n  @minimoon.app(build=context => { let (count, emit) = context.create_pure_state(0, update=(model, delta : Int) => model + delta); { count, emit } })\n}\n",
      ),
      (
        "miniapp.minimoon.json", "{\"schemaVersion\":10,\"name\":\"shared_types\",\"application\":{\"package\":\"src\",\"program\":\"start\"},\"pages\":[]}\n",
      ),
    ] {
    let (file, content) = entry
    @fs.write_file(
      join(consumer, file),
      content,
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
  }
  run(
    root,
    "Bind typed application consumer",
    "moon",
    ["work", "init", root, consumer],
    cwd=temp,
  )
  for target in ["native", "js"] {
    run(
      root,
      "Typed application consumer " + target,
      "moon",
      ["check", "--target", target, "--deny-warn"],
      cwd=consumer,
    )
    for
      invalid in [
        "pub fn bad(context : @minimoon.PageContext, source : @minimoon.Shared[Int]) -> @minimoon.Val[String] { context.bind(source) }\n",
        "pub fn bad(emit : @minimoon.Emit[Int]) -> @minimoon.Cmd { emit(\"wrong type\") }\n",
        "pub fn bad(source : @minimoon.Shared[Int]) -> @minimoon.Val[Int] { source }\n",
      ] {
      @fs.write_file(
        join(source, "invalid.mbt"),
        invalid,
        create_mode=CreateOrTruncate,
        permission=0o600,
      )
      require_command_failure(
        "Shared-state type misuse " + target,
        "moon",
        ["check", "--target", target],
        consumer,
        "Error:",
      )
    }
    @fs.write_file(
      join(source, "invalid.mbt"),
      "",
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
  }
  let bin = join(temp, "bin")
  @fs.mkdir(bin, permission=0o755)
  run(root, "Install application-aware page scaffolder", "moon", [
    "install", "--bin", bin, "--path", "src/cmd/minimoon",
  ])
  run(
    root,
    "Scaffold page with application dependencies",
    join(bin, "minimoon"),
    ["add", "page", "details"],
    cwd=consumer,
  )
  require_text(
    consumer, "src/pages/details/page.mbt", "_deps : @application.Deps",
  )
  require_text(
    consumer, "src/pages/details/moon.pkg", "\"test/shared_types\" @application",
  )
  run(
    root,
    "Check typed scaffold test and custom App entry",
    "moon",
    ["test", "--target", "js", "--deny-warn"],
    cwd=consumer,
  )
  @fs.rmdir(temp, recursive=true)
}
