///|
type Path = @path.Path

///|
struct OwnershipMetrics {
  moonbit_lines : Int
  adapter_js_lines : Int
  embedded_host_js_lines : Int
  embedded_validation_js_lines : Int
  generated_js_lines : Int
} derive(Debug)

///|
fn line_count(content : String) -> Int {
  if content == "" {
    return 0
  }
  let mut lines = 1
  for ch in content {
    if ch == '\n' {
      lines = lines + 1
    }
  }
  if content.has_suffix("\n") {
    lines - 1
  } else {
    lines
  }
}

///|
async fn files(root : String) -> Array[String] {
  let (code, output) = @process.collect_stdout(
    "git",
    ["ls-files", "--cached", "--others", "--exclude-standard"],
    cwd=root,
  )
  guard code == 0 else { abort("git ls-files exited with code \{code}") }
  output
  .text()
  .split("\n")
  .filter(path => path != "")
  .map(path => path.to_owned())
  .collect()
}

///|
async fn measure(root : String) -> OwnershipMetrics {
  let mut moonbit_lines = 0
  let mut adapter_js_lines = 0
  let mut generated_js_lines = 0
  for path in files(root) {
    let absolute = Path::join(root, path).to_string()
    if !@fs.exists(absolute) {
      continue
    }
    let is_moonbit = path.has_prefix("src/") && path.has_suffix(".mbt")
    let is_js = path.has_suffix(".js") || path.has_suffix(".mjs")
    if is_moonbit || is_js {
      let lines = line_count(@fs.read_file(absolute).text())
      if is_moonbit {
        moonbit_lines = moonbit_lines + lines
      } else if path == "scripts/bridge/weapp_tailwindcss_adapter.mjs" {
        adapter_js_lines = adapter_js_lines + lines
      } else if path.has_prefix("examples/") && path.contains("/dist/") {
        generated_js_lines = generated_js_lines + lines
      }
    }
  }
  let embedded_host_js_lines = line_count(@host_js.shared_host_bridge())
  let embedded_validation_js_lines = line_count(@host_js.host_smoke_source([])) +
    line_count(@host_js.verify_preload_source()) +
    line_count(@host_validation.dynamic_app_host_smoke_source()) +
    line_count(@host_validation.scheduler_host_smoke_source()) +
    line_count(@host_validation.navigation_host_smoke_source()) +
    line_count(@host_validation.bridge_benchmark_source()) +
    line_count(@host_validation.docs_check_source())
  {
    moonbit_lines,
    adapter_js_lines,
    embedded_host_js_lines,
    embedded_validation_js_lines,
    generated_js_lines,
  }
}

///|
fn maintained_js(metrics : OwnershipMetrics) -> Int {
  metrics.adapter_js_lines +
  metrics.embedded_host_js_lines +
  metrics.embedded_validation_js_lines
}

///|
fn metrics_json(metrics : OwnershipMetrics) -> Json {
  Json::object({
    "moonbit_lines": Json::number(metrics.moonbit_lines.to_double()),
    "maintained_js_lines": Json::number(maintained_js(metrics).to_double()),
    "adapter_js_lines": Json::number(metrics.adapter_js_lines.to_double()),
    "embedded_host_js_lines": Json::number(
      metrics.embedded_host_js_lines.to_double(),
    ),
    "embedded_validation_js_lines": Json::number(
      metrics.embedded_validation_js_lines.to_double(),
    ),
    "generated_js_lines": Json::number(metrics.generated_js_lines.to_double()),
  })
}

///|
fn print_metrics(metrics : OwnershipMetrics) -> Unit {
  println("MoonBit source: \{metrics.moonbit_lines}")
  println("Maintained JavaScript: \{maintained_js(metrics)}")
  println("Tailwind adapter JavaScript: \{metrics.adapter_js_lines}")
  println(
    "Embedded production host JavaScript: \{metrics.embedded_host_js_lines}",
  )
  println(
    "Embedded validation JavaScript: \{metrics.embedded_validation_js_lines}",
  )
  println("Tracked generated JavaScript: \{metrics.generated_js_lines}")
}

///|
async fn main {
  let args = @env.args()
  for index = 1; index < args.length(); index = index + 1 {
    guard args[index] == "--json" else {
      abort("unknown minimoon metrics option: " + args[index])
    }
  }
  let root = @env.current_dir().unwrap()
  let metrics = measure(root)
  if args.any(value => value == "--json") {
    println(metrics_json(metrics).stringify(indent=2))
  } else {
    print_metrics(metrics)
  }
}
