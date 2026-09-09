///|
fn test_resource_provider(path : String, features : Array[String]) -> Json {
  Json::object({
    "package": Json::string(path),
    "features": Json::array(features.map(Json::string)),
  })
}

///|
test "resource declaration validation rejects unsafe import paths and malformed feature arrays" {
  for
    path in [
      "", "ui", "../ui", "user/ui/../other", "user/ui\"", "user//ui", "user/ui;exec",
      "user/ui\\other",
    ] {
    assert_false(valid_resource_package(path))
  }
  assert_true(valid_resource_package("lampclaw/minimoon_ui/resources"))
  let valid = test_resource_provider("lampclaw/minimoon_ui/resources", [
    "button",
  ])
  assert_true(
    resource_config_issues(Json::object({ "resources": Json::array([valid]) })).is_empty(),
  )
  assert_true(
    !resource_config_issues(
      Json::object({ "resources": Json::array([valid, valid]) }),
    ).is_empty(),
  )
  assert_true(
    !resource_config_issues(Json::object({ "resources": Json::boolean(true) })).is_empty(),
  )
  assert_true(
    !resource_config_issues(
      Json::object({
        "resources": Json::array([
          Json::object({
            "package": Json::string("user/ui"),
            "feature": Json::array([Json::string("button")]),
          }),
        ]),
      }),
    ).is_empty(),
  )
  assert_true(
    !resource_config_issues(
      Json::object({
        "resources": Json::array([test_resource_provider("user/ui", [" "])]),
      }),
    ).is_empty(),
  )
}

///|
test "resource features normalize deterministically without silently enabling unknown features" {
  assert_eq(
    resource_features(
      test_resource_provider("user/ui", ["button", "tabs", "tabs"]),
    ),
    ["tabs", "button"],
  )
  assert_eq(
    resource_features(Json::object({ "package": Json::string("user/ui") })),
    [],
  )
}

///|
test "resource asset paths cannot overwrite host code or escape dist" {
  for
    path in [
      "app.js", "app.wxss", "minimoon.host.js", "/assets/icon.svg", "assets/../icon.svg",
      "assets//icon.svg", "assets/./icon.svg", "assets/icon.js", "assets\\icon.svg",
      "assets/%2e%2e/icon.svg",
    ] {
    assert_false(valid_resource_asset_path(path))
  }
  assert_true(valid_resource_asset_path("assets/mmui/chevron-dark.svg"))
  assert_true(valid_resource_asset_path("assets/ui/license.txt"))
}

///|
fn test_resource_bundle(path : String, content : String) -> Json {
  Json::object({
    "id": Json::string("test"),
    "version": Json::string("1.0.0"),
    "wxss": Json::string(".test{}"),
    "assets": Json::array([
      Json::object({
        "path": Json::string(path),
        "content": Json::string(content),
        "encoding": Json::string("utf8"),
      }),
    ]),
  })
}

///|
test "identical resource assets deduplicate but conflicting bytes fail" {
  let assets : Map[String, Json] = Map([])
  let bundle = test_resource_bundle("assets/test/icon.svg", "<svg/>")
  assert_true(resource_bundle_errors(bundle, assets).is_empty())
  assert_true(resource_bundle_errors(bundle, assets).is_empty())
  assert_eq(assets.length(), 1)
  assert_true(
    !resource_bundle_errors(
      test_resource_bundle("assets/test/icon.svg", "<svg>changed</svg>"),
      assets,
    ).is_empty(),
  )
  assert_true(
    !resource_bundle_errors(test_resource_bundle("app.js", "unsafe"), assets).is_empty(),
  )
  assert_eq(string(assets["assets/test/icon.svg"], "content"), "<svg/>")
}

///|
async test "resource configuration failure leaves existing dist untouched and reports source location" {
  let root = @fs.tmpdir(prefix="minimoon-resource-config")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write(join(root, "moon.mod"), "name = \"test/app\"\nsource = \"src\"\n")
    write(join(root, "src/pages/home/moon.pkg"), "")
    write(join(root, "dist/keep.txt"), "keep\n")
    let config = join(root, "miniapp.minimoon.json")
    write_json(
      config,
      Json::object({
        "schemaVersion": json_int(@versions.app_contract_version()),
        "name": Json::string("resource-test"),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/pages/home") }),
        ]),
        "resources": Json::array([test_resource_provider("../outside", [])]),
      }),
    )
    let failed = try {
      let _ = load_config_document(config)
      false
    } catch {
      _ => true
    }
    assert_true(failed)
    assert_eq(@fs.read_file(join(root, "dist/keep.txt")).text(), "keep\n")
    let diagnostic = read_json(join(root, "generated/diagnostics.json")).stringify()
    assert_true(diagnostic.contains("MMN1010"))
    assert_true(diagnostic.contains("/resources/0/package"))
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "native resource providers compile from application dependencies and clean temporary packages" {
  let root = @fs.tmpdir(prefix="minimoon-native-resource")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let repository = run_checked(
        "git",
        ["rev-parse", "--show-toplevel"],
        ".",
        "locate resource test repository",
      )
      .trim()
      .to_owned()
    let app = join(root, "app")
    write(
      join(app, "moon.mod"),
      "name = \"test/resource_app\"\nsource = \"src\"\nimport { \"lampclaw/minimoon@" +
      @versions.product_version() +
      "\" }\n",
    )
    write(
      join(app, "src/provider/moon.pkg"),
      "import { \"lampclaw/minimoon/resources\", \"moonbitlang/core/encoding/base64\" }\nsupported_targets = \"native\"\n",
    )
    write(
      join(app, "src/provider/provider.mbt"),
      "///|\npub fn resources(features : Array[String]) -> @resources.ResourceBundle {\n" +
      "let png = @base64.decode(" +
      string(test_png_asset(), "content").escape() +
      ") catch { _ => abort(\"PNG fixture\") }\n" +
      "let assets : Array[@resources.ResourceAsset] = [{path: \"assets/test/icon.svg\", content: @resources.Text(\"<svg/>\")}, {path: \"assets/test/icon.png\", content: @resources.Binary(png)}]\n" +
      "if features.contains(\"conflict\") { assets.push({path: \"assets/test/icon.png/child.png\", content: @resources.Binary(png)}) }\n" +
      "{ id: \"test-native\", version: \"1.0.0\", wxss: features.join(\",\"), assets }\n}\n",
    )
    let _ = run_checked(
      "moon",
      ["work", "init", repository, "app"],
      root,
      "resource test workspace",
    )
    let provider = test_resource_provider("test/resource_app/provider", [
      "z", "a", "z",
    ])
    let first = compile_resource_bundle(app, provider, 0)
    assert_eq(string(first, "id"), "test-native")
    assert_eq(string(first, "wxss"), "a,z")
    assert_eq(string(array(first, "assets")[0], "content"), "<svg/>")
    let binary = array(first, "assets")[1]
    assert_eq(string(binary, "encoding"), "base64")
    assert_eq(
      resource_asset_bytes(binary),
      resource_asset_bytes(test_png_asset()),
    )
    write_resource_asset(join(app, "dist"), binary)
    assert_eq(
      @fs.read_file(join(app, "dist/assets/test/icon.png")).binary(),
      resource_asset_bytes(binary),
    )
    assert_false(@fs.exists(join(app, "src/minimoon_resources_0")))
    assert_false(@fs.exists(join(app, ".minimoon-tmp/resources-0")))
    let second = compile_resource_bundle(app, provider, 0)
    assert_eq(first, second)
    write(join(app, "dist/keep.txt"), "preserve before resource validation\n")
    let config = join(app, "miniapp.minimoon.json")
    write_json(
      config,
      Json::object({
        "schemaVersion": json_int(@versions.app_contract_version()),
        "name": Json::string("resource-collision"),
        "pages": Json::array([
          Json::object({ "package": Json::string("src/provider") }),
        ]),
        "resources": Json::array([
          test_resource_provider("test/resource_app/provider", ["conflict"]),
        ]),
      }),
    )
    let failure = try {
      ignore(generate(config, "debug"))
      ""
    } catch {
      error => error.to_string()
    }
    assert_true(
      failure.contains("resource asset file/directory conflict"),
      msg=failure,
    )
    assert_eq(
      @fs.read_file(join(app, "dist/keep.txt")).text(),
      "preserve before resource validation\n",
    )
    assert_eq(
      @fs.read_file(join(app, "dist/assets/test/icon.png")).binary(),
      resource_asset_bytes(binary),
    )
    assert_true(
      read_json(join(app, "generated/diagnostics.json"))
      .stringify()
      .contains("MMN2002"),
    )
  }
  @fs.rmdir(root, recursive=true)
}
