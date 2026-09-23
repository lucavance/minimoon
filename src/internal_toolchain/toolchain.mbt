///|
/// Use with this package's process helpers to pin Bun without a wrapper process.
/// The vp shim replaces itself on Unix so cancellation reaches the backend.
pub fn bun_args(args : Array[String]) -> Array[String] {
  ["env", "exec", "bun", ..args]
}

///|
fn uses_bun(command : String, args : Array[String]) -> Bool {
  command == "vp" && args is ["env", "exec", "bun", ..]
}

///|
async fn prepare_environment(
  command : String,
  args : Array[String],
  cwd : String?,
  extra_env : Map[String, String],
) -> (Bool, Map[String, String]) {
  if !uses_bun(command, args) {
    return (true, extra_env)
  }
  let child_env = @env.get_env_vars()
  for key, value in extra_env {
    child_env[key] = value
  }
  guard !child_env.contains("VP_BYPASS") else {
    raise Failure::Failure(
      "Minimoon requires vp-managed Bun. Unset VP_BYPASS and run `vp env on bun`.",
    )
  }
  child_env["VP_BUN_VERSION"] = "1.4.2"
  // An inherited shim-wrapper marker would reuse a parent's injected tool path
  // instead of resolving this invocation's explicit backend version.
  child_env.remove("VP_SHIM_WRAPPER")
  let (code, stdout, stderr) = @process.collect_output(
    "vp",
    ["env", "current", "bun", "--json"],
    cwd?=cwd.map(path => path[:]),
    extra_env=child_env,
    inherit_env=false,
  ) catch {
    err =>
      raise Failure::Failure(
        "Unable to start vp: \{err}. Install Vite+ CLI 1.0.0-rc.0 and make sure `vp` is available on PATH.",
      )
  }
  guard code == 0 else {
    raise Failure::Failure(
      "Unable to inspect vp Bun environment: " + stderr.text(),
    )
  }
  let current = @json.parse(stdout.text())
  guard current is Object(fields) &&
    fields.get("package_manager") is Some(Object(manager)) &&
    manager.get("name") is Some(String("bun")) &&
    manager.get("version") is Some(String("1.4.2")) &&
    manager.get("mode") is Some(String("managed")) else {
    raise Failure::Failure(
      "Minimoon requires vp-managed Bun 1.4.2. Run `vp env on bun` and retry.",
    )
  }
  (false, child_env)
}

///|
#cfg(not(platform="windows"))
fn cancellation_handler(_command : String) -> @process.CancellationHandler {
  @process.graceful_cancel(timeout=5000)
}

///|
#cfg(platform="windows")
fn cancellation_handler(command : String) -> @process.CancellationHandler {
  if command != "vp" {
    return @process.graceful_cancel(timeout=5000)
  }
  // Windows has no exec replacement; terminate vp and its descendants together.
  pid => {
    let code = @process.run(
      "taskkill",
      ["/PID", pid.to_string(), "/T", "/F"],
      no_console_window=true,
    ) catch {
      _ => -1
    }
    if code != 0 {
      @process.hard_cancel()(pid)
    }
  }
}

///|
pub async fn run(
  command : String,
  args : Array[String],
  cwd? : String,
  extra_env? : Map[String, String] = Map([]),
) -> Int {
  let (inherit_env, child_env) = prepare_environment(
    command, args, cwd, extra_env,
  )
  @process.run(
    command,
    args,
    cwd?=cwd.map(path => path[:]),
    extra_env=child_env,
    inherit_env~,
    cancel_handler=cancellation_handler(command),
  )
}

///|
pub async fn collect_output(
  command : String,
  args : Array[String],
  cwd? : String,
  extra_env? : Map[String, String] = Map([]),
) -> (Int, &@io.Data, &@io.Data) {
  let (inherit_env, child_env) = prepare_environment(
    command, args, cwd, extra_env,
  )
  let (output, output_redirect) = @process.read_from_process()
  defer output.close()
  let (error, error_redirect) = @process.read_from_process()
  defer error.close()
  @async.with_task_group(group => {
    let status = group.spawn(() => {
      @process.run(
        command,
        args,
        cwd?=cwd.map(path => path[:]),
        extra_env=child_env,
        inherit_env~,
        stdout=output_redirect,
        stderr=error_redirect,
        cancel_handler=cancellation_handler(command),
      )
    })
    let out = group.spawn(() => output.read_all())
    let err = group.spawn(() => error.read_all())
    (status.wait(), out.wait(), err.wait())
  })
}
