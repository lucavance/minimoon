///|
fn match_value(values : Map[String, Array[String]], name : String) -> String? {
  match values.get(name) {
    Some([value]) => Some(value)
    _ => None
  }
}

///|
fn add_option(args : Array[String], name : String, value : String?) -> Unit {
  match value {
    Some(item) => {
      args.push(name)
      args.push(item)
    }
    None => ()
  }
}

///|
async fn discover_minimoon_root(cwd : String, explicit : String?) -> String? {
  match explicit {
    Some(value) => {
      let root = resolve_from(cwd, value)
      let manifest = join_path(root, "moon.mod")
      guard @fs.exists(manifest) &&
        @fs.read_file(manifest).text().contains("name = \"lampclaw/minimoon\"") else {
        fail("--minimoon-root is not a lampclaw/minimoon repository: " + root)
      }
      return Some(root)
    }
    None => ()
  }
  let mut current = cwd
  while true {
    let manifest = join_path(current, "moon.mod")
    if @fs.exists(manifest) &&
      @fs.read_file(manifest).text().contains("name = \"lampclaw/minimoon\"") {
      return Some(current)
    }
    let parent = dirname(current)
    if parent == current {
      return None
    }
    current = parent
  }
  None
}

///|
async fn run_repo_command(
  root : String,
  package_path : String,
  args : Array[String],
) -> Unit {
  let command_args = ["run", package_path, "--target", "native", "--", ..args]
  let code = @process.run("moon", command_args, cwd=root) catch {
    err => fail("failed to run " + package_path + ": \{err}")
  }
  guard code == 0 else { fail(package_path + " exited with code \{code}") }
}

///|
async fn main {
  let raw_args = @env.args()
  if raw_args.any(value => value == "--version") {
    println(
      "minimoon " +
      @versions.product_version() +
      " (contract " +
      @versions.app_contract_version().to_string() +
      ", runtime ABI " +
      @versions.runtime_api_version().to_string() +
      ", renderer " +
      @versions.renderer_protocol_version().to_string() +
      ")",
    )
    return
  }
  let cli = @argparse.Command(
    "minimoon",
    subcommands=[
      Command(
        "init",
        positionals=[PositionArg("app-dir", about="Directory for the new app.")],
        options=[
          OptionArg("name", about="MoonBit-safe application name."),
          OptionArg("template", about="starter. Default: starter."),
          OptionArg(
            "minimoon-root",
            about="Explicit local lampclaw/minimoon repository.",
          ),
        ],
        about="Create a standalone Skyline MiniApp project.",
      ),
      Command(
        "build",
        positionals=[
          PositionArg("target", about="App directory or miniapp.minimoon.json."),
        ],
        options=[
          OptionArg("config", about="Explicit miniapp.minimoon.json path."),
          OptionArg("mode", about="dev or release. Default: release."),
          OptionArg(
            "minimoon-root",
            about="Explicit local lampclaw/minimoon repository.",
          ),
        ],
        about="Generate Skyline MiniApp artifacts.",
      ),
      Command(
        "dev",
        positionals=[
          PositionArg("target", about="App directory or miniapp.minimoon.json."),
        ],
        options=[
          OptionArg(
            "debounce-ms",
            about="Watcher debounce in milliseconds. Default: 50.",
          ),
        ],
        about="Watch a Minimoon app and rebuild its development artifacts.",
      ),
      Command(
        "add",
        positionals=[
          PositionArg("kind", about="page or component."),
          PositionArg("name", about="Lowercase snake_case name."),
        ],
        options=[
          OptionArg("route", about="Route for a generated page."),
          OptionArg("title", about="Title for a generated page."),
          OptionArg("after", about="Insert a page after this page id."),
          OptionArg("page", about="Owning page id for a component."),
        ],
        about="Add a typed page or component scaffold.",
      ),
      Command(
        "check",
        positionals=[
          PositionArg("scope", about="mvp, candidate, or all. Default: mvp."),
        ],
        options=[
          OptionArg(
            "suite",
            about="static, docs, quality, api, codegen, generator, host, coverage, candidate, release, or perf.",
          ),
        ],
        about="Run native Minimoon validation suites.",
      ),
      Command(
        "verify",
        positionals=[
          PositionArg("target", about="App directory or miniapp.minimoon.json."),
        ],
        flags=[
          FlagArg(
            "candidate",
            about="Build release bytes without requiring host evidence.",
          ),
          FlagArg(
            "release",
            about="Require current WeChat Developer Tools evidence.",
          ),
          FlagArg("json", about="Print the full verification report."),
        ],
        about="Build and verify one current App Contract MiniApp.",
      ),
      Command(
        "devtools",
        positionals=[
          PositionArg("action", about="Evidence action. Currently: record."),
          PositionArg("target", about="App directory or miniapp.minimoon.json."),
        ],
        options=[
          OptionArg("status", about="passed or failed."),
          OptionArg("recorded-at", about="Explicit ISO-8601 validation time."),
          OptionArg("tool-version", about="WeChat Developer Tools version."),
          OptionArg("notes", about="Optional validation notes."),
        ],
        about="Record local WeChat Developer Tools evidence.",
      ),
      Command(
        "metrics",
        flags=[FlagArg("json", about="Print machine-readable JSON.")],
        about="Report MoonBit and JavaScript ownership metrics.",
      ),
    ],
    about="Build MoonBit applications for WeChat MiniApp Skyline.",
  ).parse()
  let cwd = @env.current_dir().unwrap()
  guard cli.subcommand is Some((command, matches)) else {
    println(usage())
    return
  }
  match command {
    "init" => {
      let target = match_value(matches.values, "app-dir").unwrap_or_else(fn() {
        fail("init requires an app directory")
      })
      let local_root = match match_value(matches.values, "minimoon-root") {
        Some(value) => discover_minimoon_root(cwd, Some(value))
        None => None
      }
      let args = [target]
      add_option(args, "--name", match_value(matches.values, "name"))
      add_option(args, "--template", match_value(matches.values, "template"))
      run_init(local_root, cwd, args, 0)
    }
    "build" => {
      let args : Array[String] = []
      match match_value(matches.values, "target") {
        Some(value) => args.push(value)
        None => ()
      }
      add_option(args, "--config", match_value(matches.values, "config"))
      add_option(args, "--mode", match_value(matches.values, "mode"))
      run_build(cwd, cwd, args, 0)
    }
    "dev" => {
      let debounce = match match_value(matches.values, "debounce-ms") {
        Some(value) => decimal_arg(value, "--debounce-ms")
        None => 50
      }
      run_dev(cwd, match_value(matches.values, "target"), debounce)
    }
    "add" => {
      let kind = match_value(matches.values, "kind").unwrap_or_else(fn() {
        fail("add requires page or component")
      })
      let name = match_value(matches.values, "name").unwrap_or_else(fn() {
        fail("add requires a name")
      })
      match kind {
        "page" =>
          run_add_page(
            cwd,
            name,
            match_value(matches.values, "route"),
            match_value(matches.values, "title"),
            match_value(matches.values, "after"),
          )
        "component" =>
          run_add_component(
            cwd,
            name,
            match_value(matches.values, "page").unwrap_or_else(fn() {
              fail("add component requires --page <page-id>")
            }),
          )
        _ => fail("add kind must be page or component")
      }
    }
    "check" => {
      let root = discover_minimoon_root(cwd, None).unwrap_or_else(fn() {
        fail("minimoon check must run inside a lampclaw/minimoon repository")
      })
      let args : Array[String] = [
        match_value(matches.values, "scope").unwrap_or("mvp"),
      ]
      add_option(args, "--suite", match_value(matches.values, "suite"))
      run_repo_command(root, "src/cmd/minimoon_check", args)
    }
    "verify" => {
      let target = match_value(matches.values, "target")
      let config_path = resolve_config_path(cwd, target)
      let release = raw_args.any(value => value == "--release")
      let candidate = raw_args.any(value => value == "--candidate")
      guard !(release && candidate) else {
        fail("verify accepts either --candidate or --release, not both")
      }
      let mode = if release || candidate { "release" } else { "dev" }
      let _ = @build.build(cwd, config_path, mode) catch {
        err => fail("build failed: \{err}")
      }
      let report = @verify.verify(dirname(config_path), release) catch {
        err => fail("verification failed: \{err}")
      }
      let status = match report {
        Object(fields) =>
          match fields.get("status") {
            Some(String(value)) => value
            _ => "unknown"
          }
        _ => "unknown"
      }
      if raw_args.any(value => value == "--json") {
        println(report.stringify(indent=2))
        if status != "passed" {
          @sys.exit(1)
        }
      } else {
        println("Minimoon verification: " + status)
        println(
          "Report: " +
          join_path(dirname(config_path), "generated/verify_report.json"),
        )
        if status != "passed" {
          fail("verification report contains failed checks")
        }
      }
    }
    "devtools" => {
      guard match_value(matches.values, "action") == Some("record") else {
        fail("devtools requires the `record` action")
      }
      let config_path = resolve_config_path(
        cwd,
        match_value(matches.values, "target"),
      )
      let evidence = @verify.record_devtools(
        dirname(config_path),
        match_value(matches.values, "status").unwrap_or_else(fn() {
          fail("devtools record requires --status passed|failed")
        }),
        match_value(matches.values, "recorded-at").unwrap_or_else(fn() {
          fail("devtools record requires --recorded-at")
        }),
        match_value(matches.values, "tool-version").unwrap_or_else(fn() {
          fail("devtools record requires --tool-version")
        }),
        match_value(matches.values, "notes").unwrap_or(""),
      ) catch {
        err => fail("could not record DevTools evidence: \{err}")
      }
      println(evidence.stringify(indent=2))
    }
    "metrics" => {
      let root = discover_minimoon_root(cwd, None).unwrap_or_else(fn() {
        fail("minimoon metrics must run inside a lampclaw/minimoon repository")
      })
      let args : Array[String] = []
      if raw_args.any(value => value == "--json") {
        args.push("--json")
      }
      run_repo_command(root, "src/cmd/minimoon_metrics", args)
    }
    _ => fail("unknown command: " + command)
  }
}
