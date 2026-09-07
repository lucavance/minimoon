///|
fn bridge_benchmark_source() -> String {
  @host_validation.bridge_benchmark_source()
}

///|
async fn performance_reports(root : String) -> Unit {
  let report_dir = join(root, "_build/perf")
  if !@fs.exists(report_dir) {
    @fs.mkdir(report_dir, permission=0o755, recursive=true)
  }
  let (version_code, version_stdout, version_stderr) = @process.collect_output(
    "moon",
    ["version", "--all"],
    cwd=root,
  ) catch {
    err => abort("failed to read MoonBit benchmark toolchain: \{err}")
  }
  guard version_code == 0 else {
    abort("moon version failed: " + version_stderr.text())
  }
  let bench_args = [
    "bench", "src/renderer_miniapp", "src/internal_duplix", "--target", "js", "--release",
    "--deny-warn", "--no-parallelize",
  ]
  let (bench_code, bench_stdout, bench_stderr) = @process.collect_output(
    "moon",
    bench_args,
    cwd=root,
  ) catch {
    err => abort("failed to start JS release benchmarks: \{err}")
  }
  guard bench_code == 0 else {
    abort(
      "JS release benchmarks failed\nstdout: " +
      bench_stdout.text() +
      "\nstderr: " +
      bench_stderr.text(),
    )
  }
  let benchmark_report = "command: moon " +
    bench_args.join(" ") +
    "\n" +
    version_stdout.text() +
    "\n" +
    bench_stdout.text() +
    bench_stderr.text()
  @fs.write_file(
    join(report_dir, "moonbit_js_release_bench.txt"),
    benchmark_report,
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  println(benchmark_report)

  let bridge_script = join(report_dir, "bridge_benchmark.cjs")
  @fs.write_file(
    bridge_script,
    bridge_benchmark_source(),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let conformance_root = join(root, "examples/" + conformance_fixture)
  let fingerprint = @verify.artifact_fingerprint(conformance_root)
  let bridge_args = [
    bridge_script,
    join(conformance_root, "dist/pages/lab/lab.js"),
    fingerprint,
  ]
  let (bridge_code, bridge_stdout, bridge_stderr) = @process.collect_output(
    "bun",
    bridge_args,
    cwd=root,
  ) catch {
    err => abort("failed to start generated bridge benchmark: \{err}")
  }
  guard bridge_code == 0 else {
    abort(
      "generated bridge benchmark failed\nstdout: " +
      bridge_stdout.text() +
      "\nstderr: " +
      bridge_stderr.text(),
    )
  }
  let bridge_report = @json.parse(bridge_stdout.text()) catch {
    err => abort("generated bridge benchmark emitted invalid JSON: \{err}")
  }
  let results = match json_field(bridge_report, "results") {
    Array(values) => values
    _ => abort("generated bridge benchmark results must be an array")
  }
  guard results.length() == 3 else {
    abort("generated bridge benchmark must report 100, 500, and 2000 nodes")
  }
  for result in results {
    let nodes = match json_field(result, "nodes") {
      Number(value, ..) => value.to_int()
      _ => abort("generated bridge benchmark nodes must be a number")
    }
    let speedup = match json_field(result, "speedup") {
      Number(value, ..) => value
      _ => abort("generated bridge benchmark speedup must be a number")
    }
    let shadow_copies = match json_field(result, "shadowCopiesPerPatch") {
      Number(value, ..) => value.to_int()
      _ =>
        abort(
          "generated bridge benchmark shadowCopiesPerPatch must be a number",
        )
    }
    let minimum = if nodes >= 500 { 1.5 } else { 1.1 }
    guard speedup >= minimum else {
      abort(
        nodes.to_string() +
        "-node copy-on-write patch speedup " +
        speedup.to_string() +
        " is below " +
        minimum.to_string(),
      )
    }
    guard shadow_copies == 3 else {
      abort("scalar patch must copy exactly three path containers")
    }
  }
  @fs.write_file(
    join(report_dir, "bridge_benchmark.json"),
    bridge_stdout,
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  println(bridge_stdout.text())
}

///|
async fn perf_suite(root : String) -> Unit {
  build_examples(root, "release")
  let page_limits : Array[(String, Int)] = [(".js", 2048), (".wxml", 1024)]
  for app in example_apps {
    let manifest = read_json(
      root,
      "examples/" + app + "/generated/manifest.json",
    )
    guard json_string(manifest, "runtimeLayout") == "application" else {
      abort(app + " must use the application-wide runtime layout")
    }
    guard json_string(manifest, "pageBridgeEncoding") ==
      "shared-compact-node-v1" else {
      abort(app + " must use the shared compact page bridge encoding")
    }
    let pages = match json_field(manifest, "pages") {
      Array(items) => items
      _ => abort(app + " manifest pages must be an array")
    }
    guard pages.length() > 0 else { abort(app + " manifest has no pages") }
    let app_root = "examples/" + app + "/dist/"
    let runtime_path = app_root + "minimoon.runtime.js"
    let host_path = app_root + "minimoon.host.js"
    let protocol_path = app_root + "minimoon.protocol.js"
    let initial_path = app_root + "minimoon.initial.js"
    let app_path = app_root + "app.js"
    let templates_path = app_root + "minimoon.templates.wxml"
    let app_wxss_path = app_root + "app.wxss"
    for
      path in [
        runtime_path, host_path, protocol_path, initial_path, app_path, templates_path,
        app_wxss_path,
      ] {
      require_file(root, path)
    }
    let runtime_size = @fs.read_file(join(root, runtime_path)).binary().length()
    let host_size = @fs.read_file(join(root, host_path)).binary().length()
    let protocol_size = @fs.read_file(join(root, protocol_path))
      .binary()
      .length()
    let initial_size = @fs.read_file(join(root, initial_path)).binary().length()
    guard byte_budget_allows(runtime_size, conformance_runtime_limit) else {
      abort(runtime_path + " exceeds application runtime budget")
    }
    let host_limit = shared_host_limit(
      json_field(manifest, "application") != Json::null(),
    )
    guard byte_budget_allows(host_size, host_limit) else {
      abort(
        host_path +
        " exceeds shared host budget: " +
        host_size.to_string() +
        " / " +
        host_limit.to_string() +
        " bytes",
      )
    }
    guard protocol_size <= 10000 else {
      abort(protocol_path + " exceeds shared protocol budget")
    }
    guard initial_size <= 41000 else {
      abort(initial_path + " exceeds shared initial-tree budget")
    }
    let templates_size = @fs.read_file(join(root, templates_path))
      .binary()
      .length()
    let app_wxss_size = @fs.read_file(join(root, app_wxss_path))
      .binary()
      .length()
    guard templates_size <= 20000 else {
      abort(templates_path + " exceeds shared WXML budget")
    }
    guard app_wxss_size <= 9500 else {
      abort(app_wxss_path + " exceeds application WXSS budget")
    }
    let declared_runtime_size = match
      json_field(json_field(manifest, "runtimeBytes"), "application") {
      Number(value, ..) => value.to_int()
      _ => abort(app + " runtimeBytes.application must be a number")
    }
    guard declared_runtime_size == runtime_size else {
      abort(app + " runtime byte manifest does not match the generated file")
    }
    let aggregate = Ref(
      runtime_size +
      host_size +
      protocol_size +
      initial_size +
      @fs.read_file(join(root, app_path)).binary().length(),
    )
    let application_path = join(root, app_root + "minimoon.app.js")
    if json_field(manifest, "application") != Json::null() {
      require_file(root, app_root + "minimoon.app.js")
      aggregate.val += @fs.read_file(application_path).binary().length()
    }
    for page in pages {
      let route = json_string(page, "route")
      guard !@fs.exists(join(root, app_root + route + ".runtime.js")) else {
        abort(app + " emitted a deprecated per-page runtime")
      }
      let page_wxss = app_root + route + ".wxss"
      require_file(root, page_wxss)
      guard @fs.read_file(join(root, page_wxss)).binary().length() == 0 else {
        abort(page_wxss + " must remain empty; use dist/app.wxss")
      }
      for entry in page_limits {
        let (suffix, limit) = entry
        let path = app_root + route + suffix
        require_file(root, path)
        let size = @fs.read_file(join(root, path)).binary().length()
        println(path + ": " + size.to_string() + " / " + limit.to_string())
        guard size <= limit else { abort(path + " exceeds performance budget") }
        if suffix == ".js" {
          aggregate.val += size
        }
      }
    }
    let aggregate_limit = conformance_javascript_limit
    let remaining = aggregate_limit - aggregate.val
    let headroom = remaining.to_double() / aggregate_limit.to_double() * 100.0
    println(
      "examples/" +
      app +
      "/dist/**/*.js: " +
      aggregate.val.to_string() +
      " / " +
      aggregate_limit.to_string() +
      " (remaining " +
      remaining.to_string() +
      ", headroom " +
      headroom.to_string() +
      "%)",
    )
    guard byte_budget_allows(aggregate.val, aggregate_limit) else {
      abort(app + " exceeds aggregate JavaScript performance budget")
    }
  }
  performance_reports(root)
}
