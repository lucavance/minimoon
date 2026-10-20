///|
async fn watch_wait(log : Ref[String], marker : String) -> Unit {
  let found = @async.with_timeout_opt(180000, () => {
    while !log.val.contains(marker) {
      @async.sleep(20)
    }
  })
  guard found is Some(_) else {
    raise Failure("watcher timed out waiting for " + marker + "\n" + log.val)
  }
}

///|
async fn dev_regression_gate(root : String, executable : String) -> Unit {
  let temp = check_temporary("minimoon-dev")
  defer cleanup_check_temporary(temp)
  let app = join(temp, "app with spaces")
  run(root, "Initialize watcher regression Starter", executable, [
    "init", app, "--minimoon-root", root,
  ])
  @fs.symlink(target=join(root, "node_modules"), join(app, "node_modules"))
  let config = read_json(app, "miniapp.minimoon.json")
  let fields = match config {
    Object(fields) => fields
    _ => abort("expected configuration")
  }
  fields["tailwindInput"] = Json::string("styles/custom.input")
  fields["distDir"] = Json::string("output/mini app")
  fields["sourceWxss"] = Json::string("styles/compiled.wxss")
  let selected = "custom app.json"
  // One complete editor save avoids truncate/write events straddling a build;
  // queued source edits are checked separately during the initial build.
  let write_config = async fn(content : String) {
    let staged = join(app, "configuration.pending")
    @fs.write_file(
      staged,
      content,
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    @fs.rename(staged, join(app, selected))
  }
  write_config(config.stringify())
  @fs.remove(join(app, "miniapp.minimoon.json"))
  let input = @fs.read_file(join(app, "styles/tailwind.css")).text() +
    "\n@import \"./palette.css\";\n"
  write_ui_consumer_file(app, "styles/custom.input", input)
  write_ui_consumer_file(
    app, "styles/palette.css", ".watch-probe { color: #123456; }\n",
  )
  let (output, redirect) = @process.read_from_process()
  defer output.close()
  let (errors, error_redirect) = @process.read_from_process()
  defer errors.close()
  let log = Ref("")
  @async.with_task_group(group => {
    let process = @process.spawn(
      group,
      executable,
      ["dev", join(app, selected), "--debounce-ms", "20"],
      cwd=app,
      stdout=redirect,
      stderr=error_redirect,
      cancel_handler=@process.graceful_cancel(timeout=5000),
    )
    defer process.cancel()
    let reader = group.spawn(() => {
      while output.read_until("\n") is Some(line) {
        log.val += line + "\n"
      }
    })
    defer reader.cancel()
    let error_reader = group.spawn(() => {
      while errors.read_until("\n") is Some(line) {
        log.val += line + "\n"
      }
    })
    defer error_reader.cancel()
    watch_wait(log, "build #1 initial")
    // The initial build is already running; this event must survive its completion.
    write_ui_consumer_file(
      app, "styles/palette.css", ".watch-probe { color: #234567; }\n",
    )
    watch_wait(log, "build #2 ready")
    require_text(app, "output/mini app/app.wxss", "#234567")
    let build = Ref(2)
    let finish = async fn(status : String) {
      build.val += 1
      watch_wait(log, "build #" + build.val.to_string() + " " + status)
    }
    let quiet = async fn() {
      @async.sleep(700)
      guard !log.val.contains("build #" + (build.val + 1).to_string() + " ") else {
        raise Failure("generated output caused a watch rebuild\n" + log.val)
      }
    }
    quiet()
    write_ui_consumer_file(
      app,
      "styles/custom.input",
      input + ".input-probe { color: #345678; }\n",
    )
    finish("ready")
    require_text(app, "output/mini app/app.wxss", "#345678")
    write_config("{ broken")
    finish("failed")
    fields["distDir"] = Json::string("dist")
    fields["sourceWxss"] = Json::string("styles/app.wxss")
    fields["tailwindInput"] = Json::string("styles/next.input")
    write_ui_consumer_file(app, "styles/next.input", input)
    write_config(config.stringify())
    finish("ready")
    quiet()
    write_ui_consumer_file(
      app,
      "styles/next.input",
      input + ".next-probe { color: #456789; }\n",
    )
    finish("ready")
    require_text(app, "dist/app.wxss", "#456789")
    @fs.remove(join(app, "styles/palette.css"))
    finish("failed")
    write_ui_consumer_file(
      app, "styles/palette.css", ".watch-probe { color: #567890; }\n",
    )
    finish("ready")
    require_text(app, "dist/app.wxss", "#567890")
    let source = @fs.read_file(join(app, "src/pages/home/page.mbt")).text()
    write_ui_consumer_file(
      app, "src/pages/home/page.mbt", "invalid MoonBit syntax",
    )
    finish("failed")
    write_ui_consumer_file(app, "src/pages/home/page.mbt", source)
    finish("ready")
    // Directory create, rename, and removal must report relevant descendants.
    write_ui_consumer_file(
      app, "extras/one/probe.wxss", ".extra { color: red; }\n",
    )
    finish("ready")
    @fs.rename(join(app, "extras/one"), join(app, "extras/two"))
    finish("ready")
    @fs.rmdir(join(app, "extras"), recursive=true)
    finish("ready")
    quiet()
    @fs.remove(join(app, selected))
    finish("failed")
    write_config(config.stringify())
    finish("ready")
    quiet()
  })
  println(
    "Development watcher: custom inputs, recovery, directory events, queued edits, and output isolation passed",
  )
}
