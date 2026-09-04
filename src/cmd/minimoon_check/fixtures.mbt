///|
let example_apps : Array[String] = ["miniapp_conformance_app"]

///|
let conformance_fixture = "miniapp_conformance_app"

///|
fn dynamic_app_host_smoke_source() -> String {
  @host_validation.dynamic_app_host_smoke_source()
}

///|
async fn dynamic_app_host_smoke(root : String, page_file : String) -> Unit {
  let temp = @fs.tmpdir(prefix="minimoon-dynamic-app-smoke")
  let script = join(temp, "host_smoke.cjs")
  @fs.write_file(
    script,
    dynamic_app_host_smoke_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let (code, stdout, stderr) = @process.collect_output(
    "bun",
    [script, page_file],
    cwd=root,
  ) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to start dynamic renderer bridge smoke: \{err}")
    }
  }
  let output = stdout.text() + "\n" + stderr.text()
  @fs.rmdir(temp, recursive=true)
  guard code == 0 else {
    abort("dynamic renderer bridge smoke failed: " + output.trim().to_owned())
  }
}

///|
async fn scheduler_host_smoke(root : String, host_file : String) -> Unit {
  let temp = @fs.tmpdir(prefix="minimoon-scheduler-smoke")
  let script = join(temp, "scheduler_smoke.cjs")
  @fs.write_file(
    script,
    @host_validation.scheduler_host_smoke_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let (code, stdout, stderr) = @process.collect_output(
    "bun",
    [
      "--expose-gc",
      script,
      host_file,
      @versions.runtime_api_version().to_string(),
    ],
    cwd=root,
  ) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to start scheduler host smoke: \{err}")
    }
  }
  let output = stdout.text() + "\n" + stderr.text()
  @fs.rmdir(temp, recursive=true)
  guard code == 0 else {
    abort("scheduler host smoke failed: " + output.trim().to_owned())
  }
  let report_dir = join(root, "_build/perf")
  if !@fs.exists(report_dir) {
    @fs.mkdir(report_dir, permission=0o755, recursive=true)
  }
  @fs.write_file(
    join(report_dir, "scheduler_heap.json"),
    stdout,
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
}

///|
fn navigation_host_smoke_source() -> String {
  @host_validation.navigation_host_smoke_source()
}

///|
async fn navigation_host_smoke(
  root : String,
  page_files : Array[String],
) -> Unit {
  let temp = @fs.tmpdir(prefix="minimoon-navigation-smoke")
  let script = join(temp, "host_smoke.cjs")
  @fs.write_file(
    script,
    navigation_host_smoke_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let (code, stdout, stderr) = @process.collect_output(
    "bun",
    [script, ..page_files],
    cwd=root,
  ) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to start navigation bridge smoke: \{err}")
    }
  }
  let output = stdout.text() + "\n" + stderr.text()
  @fs.rmdir(temp, recursive=true)
  guard code == 0 else {
    abort("navigation bridge smoke failed: " + output.trim().to_owned())
  }
}

///|
let local_private_config_fixture = "{\n  \"appid\": \"test-real-appid\",\n  \"localOnly\": true\n}\n\n"

///|
async fn build_examples(root : String, mode : String) -> Unit {
  for app in example_apps {
    let config = join(join(root, "examples/" + app), "miniapp.minimoon.json")
    let _ = @build.build(root, config, mode)
  }
}

///|
async fn verify_examples(root : String, release : Bool) -> Unit {
  for app in example_apps {
    let app_root = join(root, "examples/" + app)
    let report = @verify.verify(app_root, release)
    guard json_string(report, "status") == "passed" else {
      abort(app + " automated verification failed")
    }
    guard !@fs.exists(join(app_root, ".minimoon-tmp")) else {
      abort(app + " left .minimoon-tmp behind")
    }
  }
}

///|
async fn artifact_snapshot(root : String) -> String {
  let entries : Array[String] = []
  for app in example_apps {
    for directory in ["dist", "generated"] {
      let base = join(root, "examples/" + app + "/" + directory)
      @fs.walk(
        base,
        (path, names) => {
          for name in names {
            let file = join(path, name)
            if @fs.kind(file) == @fs.Regular {
              entries.push(file + "\n" + @fs.read_file(file).text())
            }
          }
        },
        max_concurrency=1,
      )
    }
  }
  entries.sort()
  entries.join("\n\u{0}\n")
}

///|
