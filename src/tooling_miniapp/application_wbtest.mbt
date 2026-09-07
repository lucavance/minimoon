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
  assert_true(source.contains("application.create_page(page)"))
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
      "schemaVersion": Json::number(9.0),
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
    ignore(load_config_document(config))
  }
  @fs.rmdir(root, recursive=true)
}
