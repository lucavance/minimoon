///|
async fn generated_checks(app_root : String, manifest : Json) -> Array[Json] {
  let checks : Array[Json] = []
  checks.push(resource_assets_status(app_root, manifest))
  let dist = join(app_root, "dist")
  let temp = join(app_root, ".minimoon-tmp/verify")
  if @fs.exists(join(app_root, ".minimoon-tmp")) {
    @fs.rmdir(join(app_root, ".minimoon-tmp"), recursive=true)
  }
  @fs.mkdir(temp, permission=0o700, recursive=true)
  let preload = join(temp, "preload.mjs")
  write(preload, @host_js.verify_preload_source())
  let page_files : Array[String] = []
  let all_files = Ref(true)
  let syntax_ok = Ref(true)
  let syntax_detail : Array[String] = []
  let shared_layout_ok = Ref(true)
  let shared_layout_detail : Array[String] = []
  let skyline_config_ok = Ref(true)
  let skyline_config_detail : Array[String] = []
  let (devtools_compile_ok, devtools_compile_detail) = check_devtools_host_project_config(
    join(dist, "project.config.json"),
  )
  checks.push(
    status(
      "devtools-host-boundary",
      devtools_compile_ok,
      if devtools_compile_ok {
        "generated CommonJS uses the verified WeChat ES6-to-ES5, enhanced compilation, and minification boundary"
      } else {
        devtools_compile_detail
      },
    ),
  )
  let shared_host_file = join(dist, "minimoon.host.js")
  let shared_protocol_file = join(dist, "minimoon.protocol.js")
  let shared_initial_file = join(dist, "minimoon.initial.js")
  let shared_runtime_file = join(dist, "minimoon.runtime.js")
  let shared_template_file = join(dist, "minimoon.templates.wxml")
  let app_wxss_file = join(dist, "app.wxss")
  for
    file in [
      shared_host_file, shared_protocol_file, shared_initial_file, shared_runtime_file,
      shared_template_file, app_wxss_file,
    ] {
    if !@fs.exists(file) {
      all_files.val = false
      syntax_detail.push("missing " + file)
    } else if file.has_suffix(".js") {
      let (passed, detail) = run(
        "bun",
        ["--preload", preload, "--check", file],
        app_root,
      )
      if !passed {
        syntax_ok.val = false
        syntax_detail.push(file + ": " + detail)
      }
    }
  }
  if @fs.exists(shared_template_file) &&
    !@fs.read_file(shared_template_file)
    .text()
    .contains("template name=\"minimoon_dynamic_node\"") {
    shared_layout_ok.val = false
    shared_layout_detail.push("shared recursive WXML template is missing")
  }
  for page in array(manifest, "pages") {
    let route = string(page, "route")
    let page_file = join(dist, route + ".js")
    let page_config_file = join(dist, route + ".json")
    let page_wxml_file = join(dist, route + ".wxml")
    let page_wxss_file = join(dist, route + ".wxss")
    page_files.push(page_file)
    for
      file in [
        page_file,
        join(dist, route + ".json"),
        join(dist, route + ".wxml"),
        join(dist, route + ".wxss"),
      ] {
      if !@fs.exists(file) {
        all_files.val = false
        syntax_detail.push("missing " + file)
      }
    }
    if @fs.exists(page_wxml_file) &&
      !@fs.read_file(page_wxml_file).text().contains("minimoon.templates.wxml") {
      shared_layout_ok.val = false
      shared_layout_detail.push(page_wxml_file + " does not import shared WXML")
    }
    if @fs.exists(page_wxss_file) &&
      @fs.read_file(page_wxss_file).binary().length() != 0 {
      shared_layout_ok.val = false
      shared_layout_detail.push(page_wxss_file + " must remain empty")
    }
    if @fs.exists(page_config_file) {
      let (passed, detail) = check_skyline_page_config(page_config_file)
      if !passed {
        skyline_config_ok.val = false
        skyline_config_detail.push(detail)
      }
    } else {
      skyline_config_ok.val = false
      skyline_config_detail.push("missing " + page_config_file)
    }
    for file in [page_file] {
      if @fs.exists(file) {
        let (passed, detail) = run(
          "bun",
          ["--preload", preload, "--check", file],
          app_root,
        )
        if !passed {
          syntax_ok.val = false
          syntax_detail.push(file + ": " + detail)
        }
      }
    }
  }
  checks.push(
    status(
      "shared-page-artifacts",
      shared_layout_ok.val,
      if shared_layout_ok.val {
        "one recursive WXML template and application WXSS serve empty per-page WXSS stubs"
      } else {
        shared_layout_detail.join("; ")
      },
    ),
  )
  checks.push(
    status(
      "skyline-page-config",
      skyline_config_ok.val,
      if skyline_config_ok.val {
        "all pages use renderer=skyline and navigationStyle=custom without ineffective system navigation fields"
      } else {
        skyline_config_detail.join("; ")
      },
    ),
  )
  checks.push(
    status(
      "generated-files",
      all_files.val,
      if all_files.val {
        "shared host/protocol/initial/runtime/WXML/WXSS and all page artifacts present"
      } else {
        syntax_detail.join("; ")
      },
    ),
  )
  checks.push(
    status(
      "bun-check",
      syntax_ok.val,
      if syntax_ok.val {
        "generated shared host/protocol/initial/runtime and page JavaScript parsed"
      } else {
        syntax_detail.join("; ")
      },
    ),
  )
  let smoke = join(temp, "host_smoke.cjs")
  write(smoke, host_smoke_source(page_files))
  let (host_ok, host_detail) = run("bun", [smoke], app_root)
  checks.push(
    status(
      "host-smoke",
      host_ok,
      if host_ok {
        "Page Definition API registration, dynamic-class/WXSS parity, hydration, mount, dynamic tree, and dispose passed"
      } else {
        host_detail
      },
    ),
  )
  @fs.rmdir(join(app_root, ".minimoon-tmp"), recursive=true)
  checks
}
