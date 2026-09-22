///|
async test "custom output fingerprint excludes only its local private config" {
  let root = @fs.tmpdir(prefix="minimoon-layout")
  defer @fs.rmdir(root, recursive=true)
  write_fingerprint_fixture(root, "App({})\n")
  let default_fingerprint = artifact_fingerprint(root)
  assert_eq(
    artifact_fingerprint(root, dist_dir=join(root, "dist")),
    default_fingerprint,
  )
  @fs.mkdir(join(root, "output"))
  @fs.rename(join(root, "dist"), join(root, "output/mini app"))
  let config_path = join(root, "custom app.json")
  write(config_path, "{\"name\":\"custom\",\"distDir\":\"output/mini app\"}")
  let expected = artifact_fingerprint(root, config_path~)
  assert_not_eq(expected, default_fingerprint)
  write(join(root, "output/mini app/project.private.config.json"), "private")
  write(join(root, "dist/app.json"), "stale default output")
  assert_eq(artifact_fingerprint(root, config_path~), expected)
  assert_eq(
    artifact_fingerprint(root, dist_dir=join(root, "output/mini app")),
    expected,
  )
  write(
    join(root, "output/mini app/project.private.config.example.json"),
    "changed",
  )
  assert_not_eq(artifact_fingerprint(root, config_path~), expected)
  let moved_fingerprint = artifact_fingerprint(root, config_path~)
  let moved = @fs.tmpdir(prefix="minimoon-layout-moved")
  defer @fs.rmdir(moved, recursive=true)
  @fs.rename(join(root, "output"), join(moved, "output"))
  @fs.rename(join(root, "generated"), join(moved, "generated"))
  @fs.rename(config_path, join(moved, "custom app.json"))
  assert_eq(
    artifact_fingerprint(moved, config_path=join(moved, "custom app.json")),
    moved_fingerprint,
  )
  for directory in ["", ".", "../escape"] {
    write(
      config_path,
      Json::object({ "distDir": Json::string(directory) }).stringify(),
    )
    let rejected = try {
      ignore(artifact_layout(root, config_path~))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  let rejected = try {
    ignore(artifact_layout(root, config_path=join(root, "missing.json")))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
async test "verification timeout cancels the resident managed Bun process" {
  let root = @fs.tmpdir(prefix="minimoon-verify-timeout")
  defer @fs.rmdir(root, recursive=true)
  let script = join(root, "resident.cjs")
  write(
    script, "require('node:fs').writeFileSync('ready.pid', String(process.pid)); setInterval(() => {}, 1000)",
  )
  let (passed, detail) = run(
    "vp",
    @toolchain.bun_args([script]),
    root,
    timeout_ms=5000,
  )
  assert_false(passed)
  assert_true(detail.contains("timed out after 5000 ms"), msg=detail)
  let pid = @fs.read_file(join(root, "ready.pid")).text()
  let (exited, result) = run(
    "vp",
    @toolchain.bun_args([
      "--eval",
      "try { process.kill(" +
      pid +
      ", 0); process.exitCode = 1 } catch { console.log('exited') }",
    ]),
    root,
  )
  assert_true(exited, msg=result)
  assert_eq(result, "exited")
}

///|
async test "verification temporary directory cleanup survives cancellation" {
  let directory = @fs.tmpdir(prefix="minimoon-verify-cleanup")
  @async.with_task_group(group => {
    let task = group.spawn(() => {
      @async.handle_cancellation(() => {
        defer cleanup_verification(directory)
        @async.sleep(10000)
      })
    })
    @async.sleep(20)
    task.cancel()
    assert_true(task.wait() is None)
  })
  assert_false(@fs.exists(directory))
}
