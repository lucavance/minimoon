///|
struct CoverageEntry {
  path : String
  covered : Int
  total : Int
}

///|
fn coverage_integer(value : String, label : String) -> Int {
  guard value != "" else { abort(label + " must be an integer") }
  let result = Ref(0)
  for index = 0; index < value.length(); index = index + 1 {
    let character = value[index]
    guard character >= '0' && character <= '9' else {
      abort(label + " must be an integer: " + value)
    }
    result.val = result.val * 10 + character.to_int() - '0'.to_int()
  }
  result.val
}

///|
fn parse_coverage_summary(
  root : String,
  output : String,
) -> Array[CoverageEntry] {
  let entries : Array[CoverageEntry] = []
  let root_prefix = root + "/"
  for raw_line in output.split("\n") {
    let line = raw_line.trim().to_owned()
    if line == "" || line.has_prefix("Total: ") {
      continue
    }
    let fields = line.split(": ").collect()
    guard fields.length() == 2 else {
      abort("unexpected MoonBit coverage summary line: " + line)
    }
    let ratio = fields[1].to_owned().split("/").collect()
    guard ratio.length() == 2 else {
      abort("unexpected MoonBit coverage ratio: " + fields[1].to_owned())
    }
    let absolute_or_relative = fields[0].to_owned()
    let path = if absolute_or_relative.has_prefix(root_prefix) {
      absolute_or_relative[root_prefix.length():].to_owned()
    } else {
      absolute_or_relative
    }
    entries.push({
      path,
      covered: coverage_integer(ratio[0].to_owned(), path + " covered count"),
      total: coverage_integer(ratio[1].to_owned(), path + " total count"),
    })
  }
  guard entries.length() > 0 else {
    abort("MoonBit coverage summary did not contain source entries")
  }
  entries
}

///|
fn is_coverage_production_source(path : String) -> Bool {
  path.has_prefix("src/") &&
  !path.has_prefix("src/cmd/") &&
  !path.has_prefix("src/tooling_") &&
  !path.has_prefix("src/internal_host_validation/") &&
  !path.has_prefix("src/internal_components_behavior_test/") &&
  !path.has_prefix("src/internal_component_styles_behavior_test/") &&
  !path.has_suffix("_test.mbt") &&
  !path.has_suffix("_wbtest.mbt") &&
  !path.has_suffix("_bench.mbt") &&
  path != "src/internal_host_js/host_bridge.mbt" &&
  path != "src/internal_host_js/validation_sources.mbt"
}

///|
fn require_coverage(
  label : String,
  covered : Int,
  total : Int,
  minimum_percent : Int,
) -> Unit {
  guard total > 0 else { abort(label + " coverage has no measurable points") }
  println(
    label +
    ": " +
    covered.to_string() +
    "/" +
    total.to_string() +
    " (minimum " +
    minimum_percent.to_string() +
    "%)",
  )
  guard covered * 100 >= total * minimum_percent else {
    abort(label + " coverage is below the required threshold")
  }
}

///|
fn require_coverage_group(
  entries : Array[CoverageEntry],
  label : String,
  minimum_percent : Int,
  matches : (String) -> Bool,
) -> Unit {
  let covered = Ref(0)
  let total = Ref(0)
  for entry in entries {
    if matches(entry.path) {
      covered.val += entry.covered
      total.val += entry.total
    }
  }
  require_coverage(label, covered.val, total.val, minimum_percent)
}

///|
async fn coverage_suite(root : String) -> Unit {
  let target_dir = "_build/coverage"
  run(root, "clean isolated MoonBit coverage target", "moon", [
    "clean", "--target-dir", target_dir,
  ])
  run(root, "run native MoonBit tests with coverage", "moon", [
    "test", "--target", "native", "--enable-coverage", "--target-dir", target_dir,
  ])
  run(root, "run JavaScript MoonBit tests with coverage", "moon", [
    "test", "--target", "js", "--enable-coverage", "--target-dir", target_dir,
  ])
  run_ui_tests(root, "native", coverage_target=target_dir)
  run_ui_tests(root, "js", coverage_target=target_dir)
  println("\n==> analyze MoonBit production coverage")
  let coverage_root = join(root, target_dir)
  let args = ["-f", "summary", "--source-paths", root, "--ignore-missing-files"]
  println("$ moon_cove_report " + args.join(" "))
  let (code, stdout, stderr) = @process.collect_output(
    "moon_cove_report",
    args,
    cwd=coverage_root,
  ) catch {
    err => abort("failed to start MoonBit coverage analysis: \{err}")
  }
  guard code == 0 else {
    abort(
      "MoonBit coverage analysis failed\nstdout: " +
      stdout.text() +
      "\nstderr: " +
      stderr.text(),
    )
  }
  let output = stdout.text()
  let coverage_errors = stderr.text().trim().to_owned()
  guard coverage_errors == "" else {
    abort("MoonBit coverage analysis reported errors: " + coverage_errors)
  }
  let entries = parse_coverage_summary(root, output)
  let complete_report_path = join(coverage_root, "coverage.xml")
  run(
    root,
    "write complete MoonBit coverage detail",
    "moon_cove_report",
    [
      "-f", "cobertura", "--source-paths", root, "--ignore-missing-files", "-o",
      complete_report_path,
    ],
    cwd=coverage_root,
  )
  let production_covered = Ref(0)
  let production_total = Ref(0)
  for entry in entries {
    if is_coverage_production_source(entry.path) {
      production_covered.val += entry.covered
      production_total.val += entry.total
    }
  }
  require_coverage(
    "selected production sources",
    production_covered.val,
    production_total.val,
    80,
  )
  require_coverage_group(entries, "root public package", 80, path => {
    is_coverage_production_source(path) &&
    path.has_prefix("src/") &&
    !path["src/".length():].contains("/")
  })
  require_coverage_group(entries, "renderer_miniapp package", 70, path => {
    is_coverage_production_source(path) &&
    path.has_prefix("src/renderer_miniapp/")
  })
  require_coverage_group(entries, "runtime_core package", 75, path => {
    is_coverage_production_source(path) && path.has_prefix("src/runtime_core/")
  })
  require_coverage_group(entries, "val_runtime package", 75, path => {
    is_coverage_production_source(path) && path.has_prefix("src/val_runtime/")
  })
  require_coverage_group(entries, "independent UI production packages", 70, path => {
    path.has_prefix("ui/src/") &&
    !path.has_suffix("_test.mbt") &&
    !path.has_suffix("_wbtest.mbt") &&
    !path.has_suffix("_bench.mbt")
  })
  println("MoonBit production coverage checks passed")
}
