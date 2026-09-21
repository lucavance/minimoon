///|
fn resident_renderer_source() -> String {
  (
    #|const fs = require('node:fs');
    #|const { spawn } = require('node:child_process');
    #|if (process.argv[2] === 'descendant') {
    #|  process.on('SIGTERM', () => {});
    #|  fs.writeFileSync('descendant.pid', String(process.pid));
    #|  setInterval(() => {}, 1000);
    #|} else {
    #|  spawn(process.execPath, [__filename, 'descendant'], { stdio: 'inherit' });
    #|  fs.writeFileSync('parent.pid', String(process.pid));
    #|  setInterval(() => {
    #|    if (process.argv[2] === 'exit-early' && fs.existsSync('descendant.pid')) {
    #|      process.exit(23);
    #|    }
    #|  }, 10);
    #|}
  )
}

///|
async fn assert_renderer_tree_stopped(root : String) -> Unit {
  let pids : Array[String] = []
  for file in ["parent.pid", "descendant.pid"] {
    pids.push(@fs.read_file(join(root, file)).text())
  }
  let (code, stdout, stderr) = @toolchain.collect_output(
    "vp",
    @toolchain.bun_args([
      "--eval",
      (
        #|const pids = PID_LIST;
        #|const alive = () => pids.some(pid => {
        #|  try { process.kill(pid, 0); return true; }
        #|  catch (error) { if (error.code === 'ESRCH') return false; throw error; }
        #|});
        #|const deadline = Date.now() + 2000;
        #|while (alive() && Date.now() < deadline) await Bun.sleep(10);
        #|process.stdout.write(alive() ? 'alive' : 'exited');
      ).replace(old="PID_LIST", new="[" + pids.join(",") + "]"),
    ]),
    cwd=root,
  )
  assert_eq(code, 0, msg=stderr.text())
  assert_eq(stdout.text(), "exited")
}

///|
async test "renderer launch preserves literal arguments stdout stderr and exit status" {
  let root = @fs.tmpdir(prefix="minimoon renderer argument spaces ")
  defer cleanup_diagram_temporary(root)
  let file = join(root, "literal arguments.cjs")
  write(
    file, "process.stdout.write(JSON.stringify(process.argv.slice(2))); process.stderr.write('renderer diagnostic'); process.exit(17);",
  )
  let arguments = ["", "path with spaces", "quote'\"", "$(not-executed)"]
  let (code, stdout, stderr) = collect_renderer_output(
    "vp",
    @toolchain.bun_args([file, ..arguments]),
    root,
  )
  assert_eq(code, 17)
  assert_eq(stdout.text(), Json::array(arguments.map(Json::string)).stringify())
  assert_true(stderr.text().contains("renderer diagnostic"))
  let (missing_code, _, missing_stderr) = collect_renderer_output(
    "minimoon-nonexistent-renderer-command",
    [],
    root,
  )
  assert_eq(missing_code, 1)
  assert_true(
    missing_stderr.text().contains("Unable to start Mermaid renderer"),
  )
}

///|
async test "cancelling renderer launch terminates signal-resistant descendants" {
  let root = @fs.tmpdir(prefix="minimoon-renderer-cancel")
  defer cleanup_diagram_temporary(root)
  let file = join(root, "resident-renderer.cjs")
  write(file, resident_renderer_source())
  @async.with_timeout(15000, () => {
    @async.with_task_group(group => {
      let task : @async.Task[Unit?] = group.spawn(() => {
        @async.handle_cancellation(() => {
          let _ = collect_renderer_output(
            "vp",
            @toolchain.bun_args([file, "resident"]),
            root,
          )
        })
      })
      while !@fs.exists(join(root, "descendant.pid")) {
        @async.sleep(10)
      }
      task.cancel()
      assert_true(task.wait() is None)
    })
  })
  assert_renderer_tree_stopped(root)
}

///|
async test "renderer launch cleans descendants after the package runner exits first" {
  let root = @fs.tmpdir(prefix="minimoon-renderer-early-exit")
  defer cleanup_diagram_temporary(root)
  let file = join(root, "resident-renderer.cjs")
  write(file, resident_renderer_source())
  let (code, _, _) = @async.with_timeout(15000, () => {
    collect_renderer_output(
      "vp",
      @toolchain.bun_args([file, "exit-early"]),
      root,
    )
  })
  assert_eq(code, 23)
  assert_renderer_tree_stopped(root)
}
