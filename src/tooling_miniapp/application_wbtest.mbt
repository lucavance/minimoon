///|
test "application generation imports typed deps and exports the separate owner lifecycle" {
  let application = Json::object({
    "package": Json::string("src/app"),
    "program": Json::string("start"),
  })
  let pages = [Json::object({ "package": Json::string("src/pages/home") })]
  let contracts = [Json::object({ "id": Json::string("home") })]
  let source = app_runtime_package_source(pages, contracts, application~)
  assert_true(source.contains("@application.start()"))
  assert_true(source.contains("@page0.program(application.deps())"))
  assert_true(source.contains("application.create_page(page, input~)"))
  assert_true(
    source.contains("Ref[@minimoon.AppRuntime[@application.Deps]?] = Ref(None)"),
  )
  assert_true(source.contains("minimoon_application_dispose"))
  assert_true(source.contains("minimoon_instances.clear()"))
  let manifest = app_runtime_package_manifest("test/app", pages, application~)
  assert_true(manifest.contains("\"test/app/app\" @application"))
  assert_true(manifest.contains("minimoon_application_start"))
  let legacy = app_runtime_package_manifest("test/app", pages)
  assert_false(legacy.contains("@application"))
  assert_false(legacy.contains("minimoon_application_start"))
}

///|
async test "optional application config validates paths entry names and the schema boundary" {
  let root = @fs.tmpdir(prefix="minimoon-application-config")
  {
    errdefer @fs.rmdir(root, recursive=true)
    write(join(root, "moon.mod"), "name = \"test/app\"\nsource = \"src\"\n")
    write(join(root, "src/app/moon.pkg"), "supported_targets = \"js\"\n")
    write(join(root, "src/pages/home/moon.pkg"), "supported_targets = \"js\"\n")
    let config = join(root, "miniapp.minimoon.json")
    let fields : Map[String, Json] = {
      "schemaVersion": Json::number(10.0),
      "name": Json::string("test_app"),
      "pages": Json::array([
        Json::object({ "package": Json::string("src/pages/home") }),
      ]),
      "application": Json::object({ "package": Json::string("src/app") }),
    }
    write(config, Json::object(fields).stringify(indent=2))
    ignore(load_config_document(config))
    for
      invalid in [
        Json::null(),
        Json::object({ "package": Json::string("../foreign") }),
        Json::object({ "package": Json::string("src/missing") }),
        Json::object({
          "package": Json::string("src/app"),
          "program": Json::string("start()"),
        }),
      ] {
      fields["application"] = invalid
      write(config, Json::object(fields).stringify(indent=2))
      let failed = try {
        ignore(load_config_document(config))
        false
      } catch {
        _ => true
      }
      assert_true(failed)
    }
    fields["application"] = Json::object({ "package": Json::string("src/app") })
    fields["schemaVersion"] = Json::number(8.0)
    write(config, Json::object(fields).stringify(indent=2))
    let failed = try {
      ignore(load_config_document(config))
      false
    } catch {
      _ => true
    }
    assert_true(failed)
    fields.remove("application")
    write(config, Json::object(fields).stringify(indent=2))
    let failed_without_app = try {
      ignore(load_config_document(config))
      false
    } catch {
      _ => true
    }
    assert_true(failed_without_app)
    fields["schemaVersion"] = Json::number(9.0)
    write(config, Json::object(fields).stringify(indent=2))
    let failed_old_app_schema = try {
      ignore(load_config_document(config))
      false
    } catch {
      _ => true
    }
    assert_true(failed_old_app_schema)
    fields["schemaVersion"] = Json::number(10.0)
    write(config, Json::object(fields).stringify(indent=2))
    ignore(load_config_document(config))
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "page smoke input accepts omitted and string maps and diagnoses invalid values at its pointer" {
  let root = @fs.tmpdir(prefix="minimoon-smoke-input-config")
  {
    errdefer @fs.rmdir(root, recursive=true)
    write(
      join(root, "moon.mod"),
      "name = \"test/smoke_input\"\nsource = \"src\"\n",
    )
    write(join(root, "src/pages/home/moon.pkg"), "supported_targets = \"js\"\n")
    write(
      join(root, "src/pages/details/moon.pkg"),
      "supported_targets = \"js\"\n",
    )
    let config = join(root, "miniapp.minimoon.json")
    let page_fields : Map[String, Json] = {
      "package": Json::string("src/pages/details"),
    }
    let fields : Map[String, Json] = {
      "schemaVersion": Json::number(
        @versions.app_contract_version().to_double(),
      ),
      "name": Json::string("smoke_input"),
      "pages": Json::array([
        Json::object({ "package": Json::string("src/pages/home") }),
        Json::object(page_fields),
      ]),
    }
    write(config, Json::object(fields).stringify(indent=2))
    let omitted = load_config_document(config)
    assert_eq(
      object(array(omitted.value, "pages")[1], "page").get("smokeInput"),
      None,
    )
    for
      input in [
        Json::empty_object(),
        Json::object({
          "id": Json::string("required-id"),
          "query": Json::string("中文 / &"),
          "empty": Json::string(""),
        }),
      ] {
      page_fields["smokeInput"] = input
      write(config, Json::object(fields).stringify(indent=2))
      let valid = load_config_document(config)
      assert_eq(field(array(valid.value, "pages")[1], "smokeInput"), input)
    }
    for
      invalid in [
        Json::null(),
        Json::array([]),
        Json::string("not an object"),
        Json::object({ "id": Json::number(1.0) }),
        Json::object({ "id": Json::boolean(true) }),
        Json::object({ "id": Json::null() }),
        Json::object({ "id": Json::array([Json::string("not a string")]) }),
      ] {
      page_fields["smokeInput"] = invalid
      write(config, Json::object(fields).stringify(indent=2))
      let failed = try {
        ignore(load_config_document(config))
        false
      } catch {
        _ => true
      }
      assert_true(failed)
      let report = read_json(join(root, "generated/diagnostics.json"))
      assert_eq(string(report, "status"), "failed")
      let issues = array(report, "issues")
      assert_eq(issues.length(), 1)
      assert_eq(string(issues[0], "code"), "MMN1004")
      assert_eq(string(issues[0], "jsonPointer"), "/pages/1/smokeInput")
      assert_true(string(issues[0], "message").contains("string values"))
      assert_eq(string(issues[0], "file"), config)
    }
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "initial tree bridge emits one empty boot view per page and never preview content" {
  let preview = Json::object({
    "kind": Json::string("text"),
    "identity": Json::string("root"),
    "text": Json::string("compile-preview-must-not-hydrate"),
    "props": Json::empty_object(),
    "events": Json::object({ "tap": Json::string("preview-event") }),
    "children": Json::array([]),
  })
  let contracts = [
    Json::object({ "id": Json::string("first"), "initialTree": preview }),
    Json::object({ "id": Json::string("second"), "initialTree": preview }),
  ]
  let source = initial_tree_bridge(contracts)
  assert_false(source.contains("compile-preview-must-not-hydrate"))
  assert_false(source.contains("preview-event"))
  let encoded = source.split("const minimoonInitialTrees = ").to_array()[1]
    .split("\n")
    .to_array()[0]
  let trees = @json.parse(encoded)
  let boot = Json::array([
    Json::string("view"),
    Json::string("root"),
    Json::string(""),
    Json::empty_object(),
    Json::empty_object(),
    Json::array([]),
  ])
  assert_eq(trees, Json::array([boot, boot]))
  assert_true(source.contains("return decodeCompactNode(encoded)"))
  assert_true(source.contains("unknown Minimoon initial tree"))
}
