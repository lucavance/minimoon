///|
async fn run_suite(root : String, suite : String) -> Unit {
  match suite {
    "static" => static_suite(root)
    "docs" => docs_suite(root)
    "quality" => quality_suite(root)
    "api" => api_suite(root)
    "codegen" => codegen_suite(root)
    "generator" => generator_suite(root)
    "host" => host_suite(root)
    "http-live" => http_live_suite(root)
    "coverage" => coverage_suite(root)
    "candidate" => candidate_suite(root)
    "release" => release_suite(root)
    "perf" => perf_suite(root)
    _ => abort("unknown Minimoon check suite: " + suite)
  }
}

///|
async fn run_checks(root : String, args : Array[String]) -> Unit {
  let mut scope = "mvp"
  let mut suite : String? = None
  let mut index = 0
  while index < args.length() {
    if args[index] == "--suite" {
      suite = args.get(index + 1)
      index = index + 2
    } else if args[index].has_prefix("--suite=") {
      suite = Some(args[index]["--suite=".length():].to_owned())
      index = index + 1
    } else {
      scope = args[index]
      index = index + 1
    }
  }
  match suite {
    Some(value) => run_suite(root, value)
    None => {
      guard scope == "mvp" || scope == "candidate" || scope == "all" else {
        abort("check scope must be mvp, candidate, or all")
      }
      for
        value in [
          "static", "docs", "quality", "api", "codegen", "generator", "host",
        ] {
        run_suite(root, value)
      }
      if scope == "candidate" || scope == "all" {
        run_suite(root, "perf")
      }
      if scope == "candidate" {
        run_suite(root, "candidate")
      } else {
        run_suite(root, "release")
      }
      println("\nMinimoon " + scope + " checks passed")
    }
  }
}

///|
async fn main {
  let args = @env.args()
  let root = @env.current_dir().unwrap()
  if args.get(1) == Some("--internal-check-worker") {
    run_checks(root, args[2:].to_owned())
  } else {
    let base = check_temporary_base(
      root,
      @env.get_env_var("MINIMOON_CHECK_TMPDIR"),
    )
    let code = supervised_check_process(
      root,
      base,
      args[0],
      ["--internal-check-worker", ..args[1:]],
    )
    if code != 0 {
      @sys.exit(if code < 0 { 128 - code } else { code })
    }
  }
}
