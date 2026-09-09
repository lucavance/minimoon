///|
fn test_png_asset() -> Json {
  Json::object({
    "path": Json::string("assets/test/icon.png"),
    "encoding": Json::string("base64"),
    "content": Json::string(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+ip1sAAAAASUVORK5CYII=",
    ),
  })
}

///|
fn resource_test_u32(value : UInt) -> Bytes {
  Bytes::from_array([
    (value >> 24).to_byte(),
    (value >> 16).to_byte(),
    (value >> 8).to_byte(),
    value.to_byte(),
  ])
}

///|
fn resource_test_chunk(kind : Bytes, payload : Bytes) -> Bytes {
  let body = kind + payload
  let mut crc = 0xffffffffU
  for byte in body {
    crc = crc ^ byte.to_uint()
    for bit = 0; bit < 8; bit = bit + 1 {
      crc = (crc >> 1) ^ (if (crc & 1) == 1 { 0xedb88320U } else { 0U })
    }
  }
  resource_test_u32(payload.length().reinterpret_as_uint()) +
  body +
  resource_test_u32(crc ^ 0xffffffffU)
}

///|
fn resource_test_png(width : UInt, padding : Int) -> Json raise {
  let asset = test_png_asset()
  let source = resource_asset_bytes(asset)
  let header = resource_test_chunk(
    b"IHDR",
    resource_test_u32(width) + source[20:29].to_owned(),
  )
  let bytes = source[0:8].to_owned() +
    header +
    resource_test_chunk(b"tEXt", Bytes::make(padding, 0)) +
    source[33:].to_owned()
  object(asset, "asset")["content"] = Json::string(@base64.encode(bytes))
  asset
}

///|
test "PNG path ancestor collisions fail in either order within or across bundles" {
  let parent = test_png_asset()
  let child = test_png_asset()
  object(child, "asset")["path"] = Json::string(
    "assets/test/icon.png/child.png",
  )
  let bundle = fn(assets : Array[Json]) {
    Json::object({
      "id": Json::string("test"),
      "version": Json::string("1"),
      "assets": Json::array(assets),
    })
  }
  for ordered in [[parent, child], [child, parent]] {
    assert_false(resource_bundle_errors(bundle(ordered), Map([])).is_empty())
    let merged : Map[String, Json] = Map([])
    assert_eq(resource_bundle_errors(bundle([ordered[0]]), merged), [])
    assert_false(
      resource_bundle_errors(bundle([ordered[1]]), merged).is_empty(),
    )
    assert_eq(merged.length(), 1)
    assert_eq(resource_bundle_errors(bundle([ordered[0]]), merged), [])
  }
}

///|
test "PNG resources require canonical binary encoding and safe image signatures" {
  let asset = test_png_asset()
  let bytes = resource_asset_bytes(asset)
  assert_true(valid_png_bytes(bytes))
  assert_true(valid_resource_asset_path("assets/test/icon.png"))
  let assets : Map[String, Json] = Map([])
  let bundle = Json::object({
    "id": Json::string("png"),
    "version": Json::string("1"),
    "assets": Json::array([asset]),
  })
  assert_eq(resource_bundle_errors(bundle, assets), [])
  assert_eq(resource_bundle_errors(bundle, assets), [])
  assert_eq(assets.length(), 1)
  for
    mutation in [
      ("encoding", Json::string("utf8")),
      ("content", Json::string("not-base64")),
      ("content", Json::string(@base64.encode(b"not png"))),
      ("content", Json::string(@base64.encode(bytes[0:33]))),
      ("content", Json::string(string(asset, "content") + "\n")),
    ] {
    let (key, value) = mutation
    let invalid = Json::object(object(asset, "asset").copy())
    object(invalid, "asset")[key] = value
    let rejected = try {
      ignore(resource_asset_bytes(invalid))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
async test "PNG assets are written byte exact and tab references cannot be missing or oversized" {
  let root = @fs.tmpdir(prefix="minimoon-png")
  defer @fs.rmdir(root, recursive=true)
  let asset = test_png_asset()
  write_resource_asset(root, asset)
  assert_eq(
    @fs.read_file(join(root, "assets/test/icon.png")).binary(),
    resource_asset_bytes(asset),
  )
  let config = tab_test_config()
  let item = object(array(field(config, "tabBar"), "list")[0], "tab")
  item["iconPath"] = field(asset, "path")
  item["selectedIconPath"] = field(asset, "path")
  let pages = array(config, "pages")
  let contracts = ["pages/home/home", "pages/lab/lab"].map(route => {
    Json::object({ "route": Json::string(route) })
  })
  let resources = Json::object({ "assets": Json::array([asset]) })
  assert_eq(tab_bar_config_issues(config), [])
  let tab = normalized_tab_bar(config, pages, contracts, resources)
  assert_eq(string(array(tab, "list")[0], "iconPath"), "assets/test/icon.png")
  let rejected = try {
    ignore(
      normalized_tab_bar(
        config,
        pages,
        contracts,
        Json::object({ "assets": Json::array([]) }),
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  let check = fn(candidate : Json) -> Unit raise {
    let replacement = Json::object({ "assets": Json::array([candidate]) })
    ignore(normalized_tab_bar(config, pages, contracts, replacement))
  }
  // The base image is 68 bytes; adding tEXt costs another 12 bytes.
  let boundary = resource_test_png(256, 40 * 1024 - 80)
  assert_eq(resource_asset_bytes(boundary).length(), 40 * 1024)
  check(boundary)
  for
    invalid in [
      resource_test_png(257, 0),
      resource_test_png(256, 40 * 1024 - 79),
    ] {
    let rejected = try {
      check(invalid)
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}
