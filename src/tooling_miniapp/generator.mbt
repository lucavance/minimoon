///|
fn devtools_checks(raw : Json) -> Array[String] {
  match object(raw, "MiniApp config").get("devtoolsChecks") {
    Some(Array(items)) =>
      items.map(item => {
        match item {
          String(value) => value.trim().to_owned()
          _ => abort("devtoolsChecks must contain strings")
        }
      })
    Some(_) => abort("devtoolsChecks must be an array")
    None => []
  }
}

///|
pub async fn generate(config_path : String, mode : String) -> Json {
  let config_file = Path::normalize(config_path).to_string()
  let app_root = dirname(config_file)
  let document = load_config_document(config_file)
  let raw = document.value
  let application = object(raw, "MiniApp config").get("application")
  let name = string(raw, "name")
  guard name != "" else {
    abort(
      "App Contract v" +
      @versions.app_contract_version().to_string() +
      " name must not be empty",
    )
  }
  let pages = array(raw, "pages")
  guard pages.length() > 0 else {
    abort(
      "App Contract v" +
      @versions.app_contract_version().to_string() +
      " pages must not be empty",
    )
  }
  let module_id = module_name(@fs.read_file(join(app_root, "moon.mod")).text())
  let resources = compile_resources(app_root, raw) catch {
    error => {
      let message = write_config_issue(
        document, config_file, "MMN2002", "resource provider did not produce a valid build resource bundle",
        "/resources", "Check the native provider's resources(features) function and asset paths.",
      )
      raise Failure::Failure(message + "\ncaused by: \{error}")
    }
  }
  let release = mode == "release"
  let contracts : Array[Json] = []
  let routes : Array[String] = []
  for index = 0; index < pages.length(); index = index + 1 {
    let page = pages[index]
    let package_path = string(page, "package")
    let compiled = try {
      let contract = compile_page_contract(
        app_root,
        module_id,
        index,
        page,
        application?,
      )
      validate_contract(contract, package_path)
      Ok(contract)
    } catch {
      error => Err(error)
    }
    let contract = match compiled {
      Ok(value) => value
      Err(error) => {
        let message = write_config_issue(
          document,
          config_file,
          "MMN2001",
          "page package did not compile as a valid Page: " + package_path,
          "/pages/" + index.to_string() + "/package",
          "Run moon check in the application and fix the reported Page error.",
        )
        raise Failure::Failure(message + "\ncaused by: \{error}")
      }
    }
    let route = string(contract, "route")
    if routes.contains(route) {
      let message = write_config_issue(
        document,
        config_file,
        "MMN1007",
        "duplicate page route: " + route,
        "/pages/" + index.to_string() + "/package",
        "Give each Page a unique MiniappRoute.",
      )
      raise Failure::Failure(message)
    }
    routes.push(route)
    if contract is Object(fields) {
      if page is Object(source) &&
        source.get("navigationBarTextStyle") is Some(style) {
        fields["navigationBarTextStyle"] = style
      }
      fields["smokeInput"] = match page {
        Object(source) =>
          source.get("smokeInput").unwrap_or(Json::empty_object())
        _ => Json::empty_object()
      }
    }
    contracts.push(contract)
  }
  let tab_bar = normalized_tab_bar(raw, pages, contracts, resources) catch {
    error => {
      let message = write_config_issue(
        document,
        config_file,
        "MMN1011",
        error.to_string(),
        "/tabBar",
        "Check tabBar page and resource references before building.",
      )
      raise Failure(message)
    }
  }
  let app_runtime = compile_app_runtime(
    app_root,
    module_id,
    pages,
    contracts,
    release,
    application?,
  )
  let host_bridge = emit_host_bridge(
    app_root,
    shared_host_bridge(
      application=application is Some(_),
      tab_routes=native_tab_routes(tab_bar),
    ),
    release,
  )
  let protocol_bridge = emit_host_bridge(
    app_root,
    shared_protocol_bridge(),
    release,
  )
  let initial_bridge = emit_host_bridge(
    app_root,
    initial_tree_bridge(contracts),
    release,
  )
  let app_runtime_bytes = @utf8.encode(app_runtime).length()
  let component_theme = string(raw, "componentTheme")
  let dist_relative = app_relative_path(
    string(raw, "distDir", fallback="dist"),
    "distDir",
  )
  let dist = join(app_root, dist_relative)
  let private_config_file = join(dist, "project.private.config.json")
  let private_config = if @fs.exists(private_config_file) {
    Some(@fs.read_file(private_config_file).binary())
  } else {
    None
  }
  if @fs.exists(dist) {
    @fs.rmdir(dist, recursive=true)
  }
  if application is Some(_) {
    write(
      join(dist, "minimoon.app.js"),
      emit_host_bridge(app_root, @host_js.application_host_bridge(), release),
    )
    write(
      join(dist, "app.js"),
      "require(\"./minimoon.app.js\").registerMinimoonApp(require(\"./minimoon.runtime.js\"))\n",
    )
  } else {
    write(join(dist, "app.js"), "App({})\n")
  }
  write(join(dist, "app.wxss"), "")
  for asset in array(resources, "assets") {
    write_resource_asset(dist, asset)
  }
  write(
    join(dist, "minimoon.templates.wxml"),
    @renderer.dynamic_templates_wxml(),
  )
  write_json(join(dist, "app.json"), app_json(routes, tab_bar~))
  write_json(
    join(dist, "project.config.json"),
    project_config(name, "touristappid"),
  )
  write_json(
    join(dist, "project.private.config.example.json"),
    private_project_config_example(),
  )
  match private_config {
    Some(content) =>
      @fs.write_file(
        private_config_file,
        content,
        create_mode=CreateOrTruncate,
        permission=0o644,
      )
    None => ()
  }
  write_json(
    join(dist, "sitemap.json"),
    Json::object({ "rules": Json::array([]) }),
  )
  write(join(dist, "minimoon.host.js"), host_bridge)
  write(join(dist, "minimoon.protocol.js"), protocol_bridge)
  write(join(dist, "minimoon.initial.js"), initial_bridge)
  write(join(dist, "minimoon.runtime.js"), app_runtime)
  for index = 0; index < contracts.length(); index = index + 1 {
    write_page(dist, contracts[index], index)
  }
  let generated = join(app_root, "generated")
  let shared_modules = [
    Json::string("minimoon.runtime.js"),
    Json::string("minimoon.host.js"),
    Json::string("minimoon.protocol.js"),
    Json::string("minimoon.initial.js"),
  ]
  if application is Some(_) {
    shared_modules.push(Json::string("minimoon.app.js"))
  }
  let manifest = Json::object({
    "schemaVersion": json_int(@versions.app_contract_version()),
    "adapter": Json::string("page_program"),
    "runtimeApiVersion": json_int(@versions.runtime_api_version()),
    "rendererProtocolVersion": json_int(@versions.renderer_protocol_version()),
    "rendererUpdateStrategy": Json::string("automatic-diff"),
    "hostRegistration": Json::string("page-definition-api"),
    "runtimeLayout": Json::string("application"),
    "pageBridgeEncoding": Json::string("shared-compact-node-v1"),
    "sharedModules": Json::array(shared_modules),
    "application": application.unwrap_or(Json::null()),
    "tabBar": tab_bar,
    "runtimeBytes": Json::object({
      "application": Json::number(
        app_runtime_bytes.to_double(),
        repr=app_runtime_bytes.to_string(),
      ),
    }),
    "rendererPatchPolicy": Json::object({
      "minSavingsPercent": Json::number(25.0, repr="25"),
      "maxHostWrites": Json::number(32.0, repr="32"),
    }),
    "rendererStats": renderer_stats_manifest(),
    "componentTheme": component_theme_manifest(component_theme),
    "resources": field(resources, "descriptors"),
    "name": Json::string(name),
    "pages": Json::array(contracts),
  })
  write_json(join(generated, "manifest.json"), manifest)
  write_config_diagnostics(config_file, [])
  write_json(
    join(generated, "expected_set_data.json"),
    Json::array(contracts.map(contract => field(contract, "initialTree"))),
  )
  let smoke_checks : Array[Json] = [
    Json::string("Page Definition API registration on glass-easel"),
    Json::string(
      "renderer v" +
      @versions.renderer_protocol_version().to_string() +
      " acknowledged typed props/events patch and replacement commits",
    ),
    Json::string("mount and initial dynamic tree"),
    Json::string("typed event dispatch"),
    Json::string("lifecycle dispatch"),
    Json::string("request-ID effect completion"),
    Json::string("dispose"),
  ]
  for check in devtools_checks(raw) {
    smoke_checks.push(Json::string(check))
  }
  write_json(
    join(generated, "smoke_checklist.json"),
    Json::object({
      "runtimeApiVersion": json_int(@versions.runtime_api_version()),
      "rendererProtocolVersion": json_int(@versions.renderer_protocol_version()),
      "pages": Json::array(routes.map(route => Json::string(route))),
      "checks": Json::array(smoke_checks),
    }),
  )
  let tailwind_input_relative = app_relative_path(
    string(raw, "tailwindInput", fallback="styles/tailwind.css"),
    "tailwindInput",
  )
  let source_wxss_relative = app_relative_path(
    string(raw, "sourceWxss", fallback="styles/app.wxss"),
    "sourceWxss",
  )
  Json::object({
    "schemaVersion": json_int(@versions.app_contract_version()),
    "name": Json::string(name),
    "configPath": Json::string(config_file),
    "fixtureDirAbs": Json::string(app_root),
    "distDirAbs": Json::string(dist),
    "tailwindInputAbs": Json::string(join(app_root, tailwind_input_relative)),
    "sourceWxssAbs": Json::string(join(app_root, source_wxss_relative)),
    "componentTheme": Json::string(component_theme),
    "resourcesWxss": field(resources, "wxss"),
    "appMetadata": Json::object({
      "pages": Json::array(
        contracts.map(contract => {
          Json::object({ "route": field(contract, "route") })
        }),
      ),
    }),
    "contracts": Json::array(contracts),
    "manifest": manifest,
  })
}

///|
pub async fn write_release_summary(build : Json, mode : String) -> Unit {
  let app_root = string(build, "fixtureDirAbs")
  write_json(
    join(app_root, "generated/release_summary.json"),
    Json::object({
      "schemaVersion": json_int(@versions.app_contract_version()),
      "runtimeApiVersion": json_int(@versions.runtime_api_version()),
      "rendererProtocolVersion": json_int(@versions.renderer_protocol_version()),
      "rendererUpdateStrategy": Json::string("automatic-diff"),
      "hostRegistration": Json::string("page-definition-api"),
      "rendererPatchPolicy": Json::object({
        "minSavingsPercent": Json::number(25.0, repr="25"),
        "maxHostWrites": Json::number(32.0, repr="32"),
      }),
      "rendererStats": renderer_stats_manifest(),
      "name": field(build, "name"),
      "mode": Json::string(mode),
      "automated": Json::object({
        "status": Json::string("pending"),
        "pageCount": Json::number(
          array(build, "contracts").length().to_double(),
          repr=array(build, "contracts").length().to_string(),
        ),
      }),
      "devtools": Json::object({
        "status": Json::string("pending"),
        "evidence": Json::null(),
      }),
    }),
  )
}
