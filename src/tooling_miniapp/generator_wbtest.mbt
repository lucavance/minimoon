///|
async fn read_json(file : String) -> Json {
  @json.parse(@fs.read_file(file).text()) catch {
    err => abort("invalid JSON in " + file + ": \{err}")
  }
}

///|
test "page bridge uses the application runtime and gates navigation" {
  let contract = Json::object({
    "id": Json::string("home"),
    "initialTree": Json::empty_object(),
    "capabilities": Json::array([
      Json::string("wx.navigateTo"),
      Json::string("wx.navigateBack"),
    ]),
  })
  let page = page_bridge(
    contract, 0, "../../minimoon.runtime.js", "../../minimoon.host.js", "../../minimoon.initial.js",
  )
  let bridge = page + shared_host_bridge()
  let protocol = shared_protocol_bridge()
  assert_true(bridge.contains("require(\"../../minimoon.runtime.js\")"))
  assert_true(page.contains("require(\"../../minimoon.host.js\")"))
  assert_true(page.contains("require(\"../../minimoon.initial.js\")"))
  assert_true(page.contains("minimoonInitialTree(0)"))
  assert_true(bridge.contains("Minimoon runtime ABI v10 required"))
  assert_false(bridge.contains("runtime ABI v9"))
  assert_true(bridge.contains("__minimoonRuntimeWakeV10"))
  assert_true(bridge.contains("Promise.resolve().then"))
  assert_true(
    bridge.contains(
      "minimoon_runtime_lifecycle(this.__mmInstanceId, \"$minimoon:drain\"",
    ),
  )
  assert_true(bridge.contains("this._st.asyncDrains += 1"))
  assert_true(bridge.contains("this._dw !== token"))
  assert_true(bridge.contains("JSON.stringify({ through: entry.through })"))
  assert_true(bridge.contains("instanceId !== this.__mmInstanceId"))
  assert_true(bridge.contains("this._sb.get(command.key) === handle"))
  assert_true(bridge.contains("exactKeys(timeoutPayload, [\"ms\"])"))
  assert_false(
    bridge.contains(
      "module.exports = { registerMinimoonPage, __minimoonRuntimeWakeV10 }",
    ),
  )
  assert_true(bridge.contains("minimoonCapabilities.has(capability)"))
  assert_true(bridge.contains("this._nv(\"wx.navigateTo\""))
  assert_true(bridge.contains("this._nv(\"wx.redirectTo\""))
  assert_true(bridge.contains("this._nv(\"wx.navigateBack\""))
  assert_true(bridge.contains("Number.isInteger(command.delta)"))
  assert_true(bridge.contains("wx[method](options)"))
  assert_true(bridge.contains("ReplaceViewTree"))
  assert_true(bridge.contains("PatchViewTree"))
  assert_true(bridge.contains("Page({"))
  assert_true(bridge.contains("spliceArrayDataOnPath"))
  assert_true(bridge.contains("__minimoonRendererStats"))
  assert_true(bridge.contains("require(\"./minimoon.protocol.js\")"))
  assert_true(protocol.contains("exactKeys"))
  assert_true(
    protocol.contains(
      "if (!value || typeof value !== \"object\" || Array.isArray(value)) return false",
    ),
  )
  assert_true(protocol.contains("copyPath"))
  assert_true(protocol.contains("decodeCompactNode"))
  assert_true(bridge.contains("this._sh"))
  assert_true(protocol.contains("command.base_revision !== revision"))
  assert_false(
    bridge.contains(
      "JSON.parse(JSON.stringify(this.data?.[minimoonPageId]?.tree))",
    ),
  )
  assert_true(protocol.contains("nodeFields"))
  assert_true(bridge.contains("minimoon_runtime_dispatch_batch"))
  assert_true(bridge.contains("event batch exceeded the 2048 entry limit"))
  assert_true(
    bridge.contains(
      "success: (result) => finish(\"success\", this._ev(result))",
    ),
  )
  assert_true(
    bridge.contains(
      "typeof task.abort === \"function\" && this._ef.has(command.request_id)",
    ),
  )
  assert_false(
    bridge.contains("success: (result) => finish(\"success\", { value:"),
  )
  assert_false(bridge.contains("Component().pageDefinition"))
  assert_false(bridge.contains("command.writes"))
  assert_false(bridge.contains("ApplyListOps"))
  assert_false(bridge.contains("?."))
  assert_false(bridge.contains("??"))
  assert_false(protocol.contains("?."))
  assert_false(protocol.contains("??"))
  let wxml = @renderer.dynamic_templates_wxml()
  for
    handler in [
      "__mmDispatchTap", "__mmDispatchInput", "__mmDispatchChange", "__mmDispatchConfirm",
      "__mmDispatchFocus", "__mmDispatchBlur", "__mmDispatchScroll", "__mmDispatchUpper",
      "__mmDispatchLower",
    ] {
    assert_true(wxml.contains(handler))
    assert_true(bridge.contains(handler + "("))
  }
  assert_false(wxml.contains("__minimoonDispatch"))
}

///|
test "generated project configuration uses the verified host JavaScript boundary" {
  let config = project_config("fixture", "touristappid").stringify()
  assert_true(config.contains("\"es6\":true"))
  assert_true(config.contains("\"enhance\":true"))
  assert_true(config.contains("\"minified\":true"))
}

///|
test "MoonBit core optional chaining is normalized for MiniApp parsers" {
  let emitted = "if(globalThis.crypto?.getRandomValues){globalThis.crypto.getRandomValues(array)}"
  let compatible = miniapp_compatible_javascript(emitted)
  assert_eq(
    compatible, "if((globalThis.crypto&&globalThis.crypto.getRandomValues)){globalThis.crypto.getRandomValues(array)}",
  )
}

///|
test "MoonBit UTF-8 encoding is compatible with MiniApp hosts without TextEncoder" {
  let with_parentheses = miniapp_compatible_javascript(
    "const encoder = new TextEncoder()\n",
  )
  assert_true(with_parentheses.has_prefix("var __mmTextEncoder="))
  assert_true(with_parentheses.contains("const encoder = __mmTextEncoder"))
  assert_false(with_parentheses.contains("new TextEncoder"))
  let without_parentheses = miniapp_compatible_javascript(
    "const encoder = new TextEncoder\n",
  )
  assert_true(without_parentheses.contains("const encoder = __mmTextEncoder"))
  assert_eq(
    miniapp_compatible_javascript("const value = 1\n"),
    "const value = 1\n",
  )
}

///|
test "MiniApp compatibility transforms are complete and idempotent" {
  let source = "const a = new TextEncoder(); const b = new TextEncoder\n" +
    "if(globalThis.crypto?.getRandomValues){globalThis.crypto?.getRandomValues(bytes)}\n"
  let compatible = miniapp_compatible_javascript(source)
  assert_eq(compatible.split("var __mmTextEncoder=").length(), 2)
  assert_false(compatible.contains("new TextEncoder"))
  assert_false(compatible.contains("?."))
  assert_false(compatible.contains("??"))
  assert_eq(miniapp_compatible_javascript(compatible), compatible)
  let literal = "const question = 'What?. really??'"
  assert_eq(miniapp_compatible_javascript(literal), literal)
}

///|
async test "MiniApp TextEncoder fallback emits standard UTF-8 bytes" {
  let root = @fs.tmpdir(prefix="minimoon-text-encoder-fallback")
  let script = join(root, "fallback.js")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write(
      script,
      "globalThis.TextEncoder = undefined\n" +
      miniapp_compatible_javascript(
        (
          #|const encoder = new TextEncoder()
          #|const check = (value, expected) => {
          #|  const actual = Array.from(encoder.encode(value))
          #|  if (JSON.stringify(actual) !== JSON.stringify(expected)) throw new Error(`${value}: ${actual}`)
          #|}
          #|check("", [])
          #|check("A", [65])
          #|check("月", [230, 156, 136])
          #|check("😀", [240, 159, 152, 128])
          #|check(String.fromCharCode(0xd800), [239, 191, 189])
          #|check(String.fromCharCode(0xdc00), [239, 191, 189])
          #|
        ),
      ),
    )
    let _ = run_checked("bun", [script], root, "MiniApp TextEncoder fallback")
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "release metadata declares every renderer statistic" {
  let stats = renderer_stats_manifest().stringify()
  for
    name in [
      "patchCommands", "replaceCommands", "patchOps", "setOps", "spliceOps", "moveOps",
      "hostWriteOps", "groupUpdateCalls", "setDataCalls", "renderCommits", "patchFallbacks",
      "rejectedPatches", "subscriptionStarts", "subscriptionStops", "effectCancellations",
      "asyncDrains", "receivedUiEvents", "coalescedEvents", "maxQueueDepth", "renderAckSamples",
      "renderAckTotalMs", "renderAckMaxMs", "renderAckLastMs", "shadowCopies",
    ] {
    assert_true(stats.contains(name))
  }
}

///|
test "generated runtime exports ABI v10 page-aware creation and batch dispatch" {
  let source = runtime_package_source("app/page", "program", false)
  assert_true(
    source.contains("minimoon_runtime_state_abi_version() -> Int { 10 }"),
  )
  assert_false(
    source.contains("minimoon_runtime_state_abi_version() -> Int { 9 }"),
  )
  assert_true(source.contains("minimoon_runtime_create_app(page_id : String)"))
  assert_true(source.contains("minimoon_runtime_dispatch_batch"))
}

///|
test "application runtime dispatches every configured page through one bundle" {
  let pages = [
    Json::object({
      "package": Json::string("src/pages/home"),
      "program": Json::string("program"),
    }),
    Json::object({
      "package": Json::string("src/pages/settings"),
      "program": Json::string("settings_program"),
    }),
  ]
  let contracts = [
    Json::object({ "id": Json::string("home") }),
    Json::object({ "id": Json::string("settings") }),
  ]
  let source = app_runtime_package_source(pages, contracts)
  assert_true(source.contains("\"home\" => @page0.program().create_runtime()"))
  assert_true(
    source.contains(
      "\"settings\" => @page1.settings_program().create_runtime()",
    ),
  )
  assert_true(source.contains("unknown runtime page id"))
  let manifest = app_runtime_package_manifest("test/app", pages)
  assert_true(manifest.contains("\"test/app/pages/home\" @page0"))
  assert_true(manifest.contains("\"test/app/pages/settings\" @page1"))
}

///|
async test "config diagnostics report duplicate keys and missing packages without touching dist" {
  let root = @fs.tmpdir(prefix="minimoon-config-diagnostics")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write(join(root, "moon.mod"), "name = \"test/app\"\nsource = \"src\"\n")
    write(join(root, "dist/keep.txt"), "keep\n")
    let config = join(root, "miniapp.minimoon.json")
    write(
      config,
      (
        #|{
        #|  "schemaVersion": 7,
        #|  "name": "first",
        #|  "name": "second",
        #|  "pages": [{ "package": "src/pages/home" }]
        #|}
        #|
      ),
    )
    let failed = try {
      let _ = load_config_document(config)
      false
    } catch {
      _ => true
    }
    assert_true(failed)
    assert_true(@fs.exists(join(root, "dist/keep.txt")))
    let report = read_json(join(root, "generated/diagnostics.json")).stringify()
    assert_true(report.contains("MMN1002"))
    assert_true(report.contains("MMN1006"))
    assert_true(report.contains("\"line\":4"))
    assert_true(report.contains("\"status\":\"failed\""))
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "config diagnostics reject traversal paths without touching dist" {
  let root = @fs.tmpdir(prefix="minimoon-config-traversal")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write(join(root, "moon.mod"), "name = \"test/app\"\nsource = \"src\"\n")
    write(join(root, "src/pages/home/moon.pkg"), "")
    write(join(root, "dist/keep.txt"), "keep\n")
    let config = join(root, "miniapp.minimoon.json")
    let documents : Array[Json] = [
      Json::object({
        "schemaVersion": Json::number(7.0),
        "name": Json::string("unsafe-package"),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/../outside") }),
        ]),
      }),
      Json::object({
        "schemaVersion": Json::number(7.0),
        "name": Json::string("unsafe-dist"),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/pages/home") }),
        ]),
        "distDir": Json::string("../outside"),
      }),
      Json::object({
        "schemaVersion": Json::number(7.0),
        "name": Json::string("unsafe-tailwind-input"),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/pages/home") }),
        ]),
        "tailwindInput": Json::string("styles/../outside.css"),
      }),
      Json::object({
        "schemaVersion": Json::number(7.0),
        "name": Json::string("unsafe-source-wxss"),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/pages/home") }),
        ]),
        "sourceWxss": Json::string("../outside.wxss"),
      }),
    ]
    for document in documents {
      write(config, document.stringify(indent=2) + "\n")
      let failed = try {
        let _ = load_config_document(config)
        false
      } catch {
        _ => true
      }
      assert_true(failed)
      let report = read_json(join(root, "generated/diagnostics.json")).stringify()
      assert_true(report.contains("MMN1005"))
      assert_true(@fs.exists(join(root, "dist/keep.txt")))
      assert_eq(@fs.read_file(join(root, "dist/keep.txt")).text(), "keep\n")
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "config diagnostics validate the optional component theme" {
  let root = @fs.tmpdir(prefix="minimoon-config-component-theme")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write(join(root, "moon.mod"), "name = \"test/app\"\nsource = \"src\"\n")
    write(join(root, "src/pages/home/moon.pkg"), "")
    let config = join(root, "miniapp.minimoon.json")
    for
      entry in [
        (Json::string("unknown"), "MMN1009"),
        (Json::boolean(true), "MMN1004"),
      ] {
      let (theme, code) = entry
      write(
        config,
        Json::object({
          "schemaVersion": Json::number(7.0, repr="7"),
          "name": Json::string("theme-test"),
          "componentTheme": theme,
          "pages": Json::array([
            Json::object({ "package": Json::string("src/pages/home") }),
          ]),
        }).stringify(indent=2) +
        "\n",
      )
      let failed = try {
        let _ = load_config_document(config)
        false
      } catch {
        _ => true
      }
      assert_true(failed)
      assert_true(
        read_json(join(root, "generated/diagnostics.json"))
        .stringify()
        .contains(code),
      )
    }
    for theme in ["minimal-v1", "minimal-v2"] {
      write(
        config,
        Json::object({
          "schemaVersion": Json::number(7.0, repr="7"),
          "name": Json::string("theme-test"),
          "componentTheme": Json::string(theme),
          "pages": Json::array([
            Json::object({ "package": Json::string("src/pages/home") }),
          ]),
        }).stringify(indent=2) +
        "\n",
      )
      let _ = load_config_document(config)
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "DevTools checks are trimmed and preserve declaration order" {
  let checks = devtools_checks(
    Json::object({
      "devtoolsChecks": Json::array([
        Json::string(" first check "),
        Json::string("second check"),
      ]),
    }),
  )
  assert_eq(checks, ["first check", "second check"])
}

///|
async test "config diagnostics validate optional DevTools checks" {
  let root = @fs.tmpdir(prefix="minimoon-config-devtools-checks")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write(join(root, "moon.mod"), "name = \"test/app\"\nsource = \"src\"\n")
    write(join(root, "src/pages/home/moon.pkg"), "")
    let config = join(root, "miniapp.minimoon.json")
    for
      entry in [
        (Json::boolean(true), "MMN1004"),
        (Json::array([Json::string(" ")]), "MMN1004"),
        (Json::array([Json::number(1.0, repr="1")]), "MMN1004"),
        (Json::array([Json::string("same"), Json::string(" same ")]), "MMN1007"),
      ] {
      let (checks, code) = entry
      write(
        config,
        Json::object({
          "schemaVersion": Json::number(7.0, repr="7"),
          "name": Json::string("devtools-check-test"),
          "devtoolsChecks": checks,
          "pages": Json::array([
            Json::object({ "package": Json::string("src/pages/home") }),
          ]),
        }).stringify(indent=2) +
        "\n",
      )
      let failed = try {
        let _ = load_config_document(config)
        false
      } catch {
        _ => true
      }
      assert_true(failed)
      assert_true(
        read_json(join(root, "generated/diagnostics.json"))
        .stringify()
        .contains(code),
      )
    }
    write(
      config,
      Json::object({
        "schemaVersion": Json::number(7.0, repr="7"),
        "name": Json::string("devtools-check-test"),
        "devtoolsChecks": Json::array([
          Json::string("first"),
          Json::string("second"),
        ]),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/pages/home") }),
        ]),
      }).stringify(indent=2) +
      "\n",
    )
    let _ = load_config_document(config)
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "page route validation rejects traversal and absolute routes" {
  assert_false(valid_page_route("pages/home/../outside"))
  assert_false(valid_page_route("/pages/home/home"))
  assert_false(valid_page_route(""))
  assert_true(valid_page_route("pages/home/home"))
}

///|
async test "invalid JSON records a source-located diagnostic" {
  let root = @fs.tmpdir(prefix="minimoon-config-invalid-json")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let config = join(root, "miniapp.minimoon.json")
    write(config, "{\n  \"schemaVersion\": 7,\n  ?\n}\n")
    let failed = try {
      let _ = load_config_document(config)
      false
    } catch {
      _ => true
    }
    assert_true(failed)
    let report = read_json(join(root, "generated/diagnostics.json")).stringify()
    assert_true(report.contains("MMN1001"))
    assert_true(report.contains("\"line\":3"))
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "Skyline page config uses custom navigation without dead system title" {
  let config = page_json(Json::object({ "title": Json::string("Home") }))
  assert_false(object(config, "page config").contains("navigationBarTitleText"))
  assert_eq(string(config, "navigationStyle"), "custom")
  assert_eq(string(config, "renderer"), "skyline")
}

///|
test "project config preserves the verified CommonJS host boundary" {
  let app = app_json(["pages/home/home"])
  assert_false(object(app, "app config").contains("window"))
  let project = project_config("home", "touristappid")
  let setting = field(project, "setting")
  match field(setting, "es6") {
    True => ()
    _ => fail("generated project must enable ES6-to-ES5 transformation")
  }
  match field(setting, "enhance") {
    True => ()
    _ => fail("generated project must enable enhanced compilation")
  }
  match field(setting, "minified") {
    True => ()
    _ => fail("generated project must enable Developer Tools minification")
  }
  let config = private_project_config_example()
  assert_eq(string(config, "appid"), "xxxxx-your-wechat-miniapp-appid")
  assert_eq(string(config, "libVersion"), "3.17.0")
  assert_false(object(config, "private config example").contains("setting"))
}

///|
async test "Moon JavaScript bundle discovery follows relocated compiler output" {
  let root = @fs.tmpdir(prefix="minimoon-bundle-relocated")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let target = join(root, "target")
    let relocated = join(
      target, "js/new-layout/build/example/minimoon_app_runtime/minimoon_app_runtime.js",
    )
    write(relocated, "module.exports = {}\n")
    write(join(target, "minimoon_app_runtime.min.js"), "module.exports = {}\n")
    write(join(target, "unrelated.js"), "module.exports = {}\n")
    assert_eq(
      locate_moon_javascript_bundle(target, "minimoon_app_runtime"),
      relocated,
    )
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "Moon JavaScript bundle discovery accepts current debug and release layouts" {
  let root = @fs.tmpdir(prefix="minimoon-bundle-current-layout")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    for profile in ["debug", "release"] {
      let target = join(root, profile)
      let bundle = join(
        target,
        "js/" +
        profile +
        "/build/test/app/minimoon_app_runtime/minimoon_app_runtime.js",
      )
      write(bundle, "module.exports = {}\n")
      assert_eq(
        locate_moon_javascript_bundle(target, "minimoon_app_runtime"),
        bundle,
      )
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "Moon JavaScript bundle discovery rejects zero and multiple outputs" {
  let root = @fs.tmpdir(prefix="minimoon-bundle-cardinality")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let target = join(root, "target")
    @fs.mkdir(target, permission=0o700, recursive=true)
    let missing = try {
      let _ = locate_moon_javascript_bundle(target, "minimoon_app_runtime")
      false
    } catch {
      _ => true
    }
    assert_true(missing)
    let second = join(target, "b/minimoon_app_runtime.js")
    let first = join(target, "a/minimoon_app_runtime.js")
    write(second, "module.exports = 2\n")
    write(first, "module.exports = 1\n")
    assert_eq(
      moon_javascript_bundle_candidates(target, "minimoon_app_runtime"),
      [first, second],
    )
    let ambiguous = try {
      let _ = locate_moon_javascript_bundle(target, "minimoon_app_runtime")
      false
    } catch {
      _ => true
    }
    assert_true(ambiguous)
  }
  @fs.rmdir(root, recursive=true)
}
