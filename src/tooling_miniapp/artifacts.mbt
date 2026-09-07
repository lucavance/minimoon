///|
fn validate_contract(contract : Json, package_path : String) -> Unit {
  let contract_version = @versions.app_contract_version()
  let runtime_version = @versions.runtime_api_version()
  let renderer_version = @versions.renderer_protocol_version()
  match field(contract, "schemaVersion") {
    Number(value, ..) if value == contract_version.to_double() => ()
    _ =>
      abort(
        "Page contract schemaVersion must be " +
        contract_version.to_string() +
        ": " +
        package_path,
      )
  }
  match field(contract, "runtimeApiVersion") {
    Number(value, ..) if value == runtime_version.to_double() => ()
    _ =>
      abort(
        "Page runtimeApiVersion must be " +
        runtime_version.to_string() +
        ": " +
        package_path,
      )
  }
  match field(contract, "rendererProtocolVersion") {
    Number(value, ..) if value == renderer_version.to_double() => ()
    _ =>
      abort(
        "Page rendererProtocolVersion must be " +
        renderer_version.to_string() +
        ": " +
        package_path,
      )
  }
  let route = string(contract, "route")
  guard valid_page_route(route) else {
    abort("Page route must be a safe relative route: " + route)
  }
}

///|
fn shared_host_bridge(application? : Bool = false) -> String {
  @host_js.shared_host_bridge(application~)
}

///|
fn shared_protocol_bridge() -> String {
  @host_js.shared_protocol_bridge()
}

///|
fn compact_node(node : Json) -> Json {
  Json::array([
    field(node, "kind"),
    field(node, "identity"),
    field(node, "text"),
    field(node, "props"),
    field(node, "events"),
    Json::array(array(node, "children").map(child => compact_node(child))),
  ])
}

///|
fn initial_tree_bridge(contracts : Array[Json]) -> String {
  "const { decodeCompactNode } = require(\"./minimoon.protocol.js\")\n" +
  "const minimoonInitialTrees = " +
  Json::array(
    contracts.map(contract => compact_node(field(contract, "initialTree"))),
  ).stringify() +
  "\nfunction minimoonInitialTree(index) {\n" +
  "  const encoded = minimoonInitialTrees[index]\n" +
  "  if (!encoded) throw new Error(\"unknown Minimoon initial tree\")\n" +
  "  return decodeCompactNode(encoded)\n" +
  "}\n" +
  "module.exports = { minimoonInitialTree }\n"
}

///|
fn page_bridge(
  contract : Json,
  page_index : Int,
  runtime_module : String,
  host_module : String,
  initial_module : String,
) -> String {
  "const { registerMinimoonPage } = require(" +
  host_module.escape() +
  ")\n" +
  "const { minimoonInitialTree } = require(" +
  initial_module.escape() +
  ")\n" +
  "registerMinimoonPage(require(" +
  runtime_module.escape() +
  "), " +
  string(contract, "id").escape() +
  ", " +
  "minimoonInitialTree(" +
  page_index.to_string() +
  ")" +
  ", " +
  field(contract, "capabilities").stringify() +
  ")\n"
}

///|
fn app_json(routes : Array[String]) -> Json {
  Json::object({
    "pages": Json::array(routes.map(route => Json::string(route))),
    "renderer": Json::string("skyline"),
    "componentFramework": Json::string("glass-easel"),
    "lazyCodeLoading": Json::string("requiredComponents"),
    "rendererOptions": Json::object({
      "skyline": Json::object({ "disableABTest": Json::boolean(true) }),
    }),
  })
}

///|
fn project_config(name : String, appid : String) -> Json {
  Json::object({
    "appid": Json::string(appid),
    "projectname": Json::string("minimoon-" + name),
    "compileType": Json::string("miniprogram"),
    "miniprogramRoot": Json::string("./"),
    "setting": Json::object({
      "urlCheck": Json::boolean(false),
      "es6": Json::boolean(true),
      "enhance": Json::boolean(true),
      "postcss": Json::boolean(true),
      "minified": Json::boolean(true),
      "skylineRenderEnable": Json::boolean(true),
    }),
    "condition": Json::empty_object(),
  })
}

///|
fn private_project_config_example() -> Json {
  Json::object({
    "appid": Json::string("xxxxx-your-wechat-miniapp-appid"),
    "libVersion": Json::string("3.17.0"),
  })
}

///|
fn page_json(contract : Json) -> Json {
  let _ = contract
  Json::object({
    "navigationStyle": Json::string("custom"),
    "renderer": Json::string("skyline"),
  })
}

///|
async fn write_page(dist : String, contract : Json, page_index : Int) -> Unit {
  let route = string(contract, "route")
  let base = join(dist, route)
  let host_relative = Path::relative(
    join(dist, "minimoon.host.js"),
    base=dirname(base),
  ).to_string()
  let runtime_relative = Path::relative(
    join(dist, "minimoon.runtime.js"),
    base=dirname(base),
  ).to_string()
  let initial_relative = Path::relative(
    join(dist, "minimoon.initial.js"),
    base=dirname(base),
  ).to_string()
  let templates_relative = Path::relative(
    join(dist, "minimoon.templates.wxml"),
    base=dirname(base),
  ).to_string()
  let host_module = if host_relative.has_prefix(".") {
    host_relative
  } else {
    "./" + host_relative
  }
  let runtime_module = if runtime_relative.has_prefix(".") {
    runtime_relative
  } else {
    "./" + runtime_relative
  }
  let initial_module = if initial_relative.has_prefix(".") {
    initial_relative
  } else {
    "./" + initial_relative
  }
  let templates_src = if templates_relative.has_prefix(".") {
    templates_relative
  } else {
    "./" + templates_relative
  }
  write_json(base + ".json", page_json(contract))
  write(
    base + ".wxml",
    @renderer.dynamic_page_wxml(string(contract, "id"), templates_src~),
  )
  write(base + ".wxss", "")
  write(
    base + ".js",
    page_bridge(
      contract, page_index, runtime_module, host_module, initial_module,
    ),
  )
}

///|
fn renderer_stats_manifest() -> Json {
  Json::array(
    [
      "patchCommands", "replaceCommands", "patchOps", "setOps", "spliceOps", "moveOps",
      "hostWriteOps", "groupUpdateCalls", "setDataCalls", "renderCommits", "patchFallbacks",
      "rejectedPatches", "subscriptionStarts", "subscriptionStops", "effectCancellations",
      "asyncDrains", "receivedUiEvents", "coalescedEvents", "eventBatches", "maxEventBatch",
      "maxQueueDepth", "schedulerWarnings", "schedulerFailures", "renderRetries",
      "renderTimeouts", "renderAckSamples", "renderAckTotalMs", "renderAckMaxMs",
      "renderAckLastMs", "shadowCopies",
    ].map(value => Json::string(value)),
  )
}
