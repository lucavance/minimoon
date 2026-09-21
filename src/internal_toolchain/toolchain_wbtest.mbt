///|
async test "vp preserves Bun version cwd environment and literal arguments without a package manifest" {
  let root = @fs.tmpdir(prefix="minimoon vp argument spaces ")
  defer @fs.rmdir(root, recursive=true)
  let script = root + "/literal arguments.cjs"
  @fs.write_file(
    script,
    (
      #|console.log(JSON.stringify({
      #|  version: Bun.version,
      #|  cwd: process.cwd(),
      #|  env: process.env.MINIMOON_TOOLCHAIN_PROBE,
      #|  args: process.argv.slice(2),
      #|}));
    ),
  )
  let args = ["", "space separated", "quote'\"", "$(must-not-run)", "--literal"]
  let (code, stdout, _) = collect_output(
    "vp",
    bun_args([script, ..args]),
    cwd=root,
    extra_env={ "MINIMOON_TOOLCHAIN_PROBE": "inherited probe value" },
  )
  assert_eq(code, 0)
  assert_eq(
    @json.parse(stdout.text()),
    Json::object({
      "version": Json::string("1.4.2"),
      "cwd": Json::string(root),
      "env": Json::string("inherited probe value"),
      "args": Json::array(args.map(Json::string)),
    }),
  )
  assert_false(@fs.exists(root + "/package.json"))
}

///|
async test "vp preserves backend stdout stderr and nonzero exit status" {
  let root = @fs.tmpdir(prefix="minimoon-vp-failure")
  defer @fs.rmdir(root, recursive=true)
  let (code, stdout, stderr) = collect_output(
    "vp",
    bun_args([
      "--eval", "process.stdout.write('{\"ok\":false}'); process.stderr.write('backend failure'); process.exit(23);",
    ]),
    cwd=root,
  )
  assert_eq(code, 23)
  assert_eq(stdout.text(), "{\"ok\":false}")
  assert_true(stderr.text().contains("backend failure"))
}

///|
async test "vp backend pin overrides legacy manifests and inherited shim selections" {
  let root = @fs.tmpdir(prefix="minimoon-vp-legacy-pin")
  defer @fs.rmdir(root, recursive=true)
  @fs.write_file(
    root + "/package.json",
    "{\"devEngines\":{\"packageManager\":{\"name\":\"bun\",\"version\":\"0.0.1\"}}}",
  )
  let (code, stdout, _) = collect_output(
    "vp",
    bun_args(["--version"]),
    cwd=root,
    extra_env={ "VP_BUN_VERSION": "0.0.1", "VP_SHIM_WRAPPER": "1" },
  )
  assert_eq(code, 0)
  assert_eq(stdout.text().trim(), "1.4.2")
}

///|
async test "unmanaged Bun is rejected before the backend command starts" {
  let root = @fs.tmpdir(prefix="minimoon-vp-unmanaged")
  defer @fs.rmdir(root, recursive=true)
  let vp_home = root + "/vp-home"
  @fs.mkdir(vp_home)
  @fs.write_file(
    vp_home + "/config.json",
    "{\"packageManagerShimModes\":{\"bun\":\"system_first\"}}",
  )
  let error = try {
    let _ = collect_output(
      "vp",
      bun_args([
        "--eval", "require('node:fs').writeFileSync('unexpected-execution', 'started')",
      ]),
      cwd=root,
      extra_env={ "VP_HOME": vp_home },
    )
    ""
  } catch {
    err => err.to_string()
  }
  assert_true(error.contains("vp env on bun"), msg=error)
  assert_false(@fs.exists(root + "/unexpected-execution"))
}

///|
async test "cancelling vp execution terminates the resident Bun backend" {
  let root = @fs.tmpdir(prefix="minimoon-vp-cancel")
  defer @fs.rmdir(root, recursive=true)
  let script = root + "/resident.cjs"
  let ready = root + "/ready.pid"
  @fs.write_file(
    script,
    (
      #|require('node:fs').writeFileSync('ready.pid', String(process.pid));
      #|setInterval(() => {}, 1000);
    ),
  )
  @async.with_timeout(30000, () => {
    @async.with_task_group(group => {
      let task : @async.Task[Unit?] = group.spawn(() => {
        @async.handle_cancellation(() => {
          let _ = collect_output("vp", bun_args([script]), cwd=root)
        })
      })
      while !@fs.exists(ready) {
        @async.sleep(20)
      }
      task.cancel()
      assert_true(task.wait() is None)
    })
  })
  let pid = @fs.read_file(ready).text()
  let (code, stdout, _) = collect_output(
    "vp",
    bun_args([
      "--eval",
      "try { process.kill(" +
      pid +
      ", 0); process.stdout.write('alive'); } catch { process.stdout.write('exited'); }",
    ]),
    cwd=root,
  )
  assert_eq(code, 0)
  assert_eq(stdout.text(), "exited")
}
