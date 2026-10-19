///|
async fn run_build(
  root : String,
  cwd : String,
  args : Array[String],
  start : Int32,
) -> Unit {
  let parsed = parse_build_args(args, start)
  if parsed.show_help {
    println(usage())
    return
  }
  let config_path = resolve_config_path(cwd, parsed.target)
  let display_path = relative_to(config_path, root)
  println("minimoon build " + display_path)
  let _ = @build.build(root, config_path, parsed.mode) catch {
    err => fail("build failed: \{err}")
  }
}

///|
fn watch_ignored(path : String) -> Bool {
  path
  .split("/")
  .any(part => {
    [
      ".git", "_build", ".mooncakes", "node_modules", ".minimoon-tmp", "generated",
    ].contains(part.to_owned())
  })
}

///|
fn watch_relevant(path : String) -> Bool {
  path.has_suffix(".mbt") ||
  path.has_suffix("moon.pkg") ||
  path.has_suffix("moon.mod") ||
  path.has_suffix("moon.work") ||
  path.has_suffix("miniapp.minimoon.json") ||
  path.has_suffix(".css") ||
  path.has_suffix(".wxss") ||
  path.has_suffix("package.json") ||
  path.has_suffix("bun.lock") ||
  path.has_suffix("bun.lockb")
}

///|
fn watch_event_paths(event : @fs.FsEvent) -> Array[String] {
  match event {
    Modify(path) | Create(path) | Remove(path) => [path]
    Rename(old~, new~) => [old, new]
  }
}

///|
// Readiness is also consumed through pipes by editors and integration checks.
async fn dev_log(message : String) -> Unit {
  @stdio.stdout.write(message + "\n")
}

///|
async fn run_dev(cwd : String, target : String?, debounce_ms : Int32) -> Unit {
  guard debounce_ms >= 1 && debounce_ms <= 5000 else {
    fail("--debounce-ms must be between 1 and 5000")
  }
  let config_path = resolve_config_path(cwd, target)
  let app_dir = dirname(config_path)
  let config_name = @path.Path::basename(config_path).to_owned()
  let watcher = @fs.Watcher(
    app_dir,
    debounce_timeout=debounce_ms,
    max_debounce_delay=debounce_ms * 10,
    report_child_event=true,
    ignored_paths=watch_ignored,
  ) catch {
    error => fail("could not watch app directory: \{error}")
  }
  defer watcher.close()
  // Watch before reading configuration as well as before building: an edit
  // during validation must refresh the output exclusions on the next pass.
  // Keep the last valid layout while a configuration is temporarily broken.
  let layout = Ref(
    try @miniapp_tooling.watch_layout(config_path) catch {
      _ => None
    } noraise {
      value => Some(value)
    },
  )
  dev_log("minimoon dev watching " + relative_to(app_dir, cwd))
  let build_number = Ref(0)
  let build_once = async fn(changed : Array[String]) {
    build_number.val = build_number.val + 1
    let label = "minimoon dev build #" + build_number.val.to_string()
    if changed.length() > 0 {
      dev_log(label + " changed: " + changed.join(", "))
    } else {
      dev_log(label + " initial")
    }
    let result = try {
      let _ = @build.build(cwd, config_path, "dev")
      None
    } catch {
      error => Some("\{error}")
    }
    match result {
      Some(error) => dev_log(label + " failed\n" + error)
      None => dev_log(label + " ready")
    }
  }
  build_once([])
  for ;; {
    let paths : Array[String] = []
    let renamed_directories : Array[String] = []
    for event in watcher.wait() {
      // Same-parent directory renames are reported without child events.
      if event is Rename(old~, new~) &&
        (try
          @fs.kind(join_path(app_dir, new), follow_symlink=false) ==
          @fs.Directory
        catch {
          _ => false
        }) {
        renamed_directories.push(old)
        renamed_directories.push(new)
      }
      for path in watch_event_paths(event) {
        if !paths.contains(path) {
          paths.push(path)
        }
      }
    }
    if paths.contains(config_name) {
      try {
        layout.val = Some(@miniapp_tooling.watch_layout(config_path))
      } catch {
        error =>
          dev_log(
            "minimoon dev configuration invalid; retaining watch layout: \{error}",
          )
      }
    }
    let changed = paths.filter(path => {
      if path == config_name {
        return true
      }
      match layout.val {
        Some(current) =>
          current.accepts(path) &&
          (
            watch_relevant(path) ||
            path == current.tailwind_input ||
            renamed_directories.contains(path)
          )
        None =>
          (watch_relevant(path) || renamed_directories.contains(path)) &&
          !path.has_prefix("dist/") &&
          path != "styles/app.wxss" &&
          !path.has_suffix(".minimoon-tailwind-input.css")
      }
    })
    if changed.length() > 0 {
      build_once(changed)
    }
  }
}

///|
