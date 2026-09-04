///|
async fn run_build(
  root : String,
  cwd : String,
  args : Array[String],
  start : Int,
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
  let first = path.split("/").next().unwrap_or("")
  first == ".git" ||
  first == "_build" ||
  first == ".mooncakes" ||
  first == "node_modules" ||
  first == ".minimoon-tmp" ||
  first == "dist" ||
  first == "generated" ||
  path.has_suffix("styles/app.wxss")
}

///|
fn watch_relevant(path : String) -> Bool {
  path.has_suffix(".mbt") ||
  path.has_suffix("moon.pkg") ||
  path.has_suffix("moon.mod") ||
  path.has_suffix("moon.work") ||
  path.has_suffix("miniapp.minimoon.json") ||
  path.has_suffix("tailwind.css") ||
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
async fn run_dev(cwd : String, target : String?, debounce_ms : Int) -> Unit {
  guard debounce_ms >= 1 && debounce_ms <= 5000 else {
    fail("--debounce-ms must be between 1 and 5000")
  }
  let config_path = resolve_config_path(cwd, target)
  let app_dir = dirname(config_path)
  let build_number = Ref(0)
  let build_once = async fn(changed : Array[String]) {
    build_number.val = build_number.val + 1
    let label = "minimoon dev build #" + build_number.val.to_string()
    if changed.length() > 0 {
      println(label + " changed: " + changed.join(", "))
    } else {
      println(label + " initial")
    }
    let result = try {
      let _ = @build.build(cwd, config_path, "dev")
      None
    } catch {
      error => Some("\{error}")
    }
    match result {
      Some(error) =>
        println(label + " failed; keeping the last valid dist\n" + error)
      None => println(label + " ready")
    }
  }
  build_once([])
  let watcher = @fs.Watcher(
    app_dir,
    debounce_timeout=debounce_ms,
    max_debounce_delay=debounce_ms * 10,
    ignored_paths=watch_ignored,
  ) catch {
    error => fail("could not watch app directory: \{error}")
  }
  defer watcher.close()
  println("minimoon dev watching " + relative_to(app_dir, cwd))
  for ;; {
    let paths : Array[String] = []
    for event in watcher.wait() {
      for path in watch_event_paths(event) {
        if watch_relevant(path) && !paths.contains(path) {
          paths.push(path)
        }
      }
    }
    if paths.length() > 0 {
      build_once(paths)
    }
  }
}

///|
