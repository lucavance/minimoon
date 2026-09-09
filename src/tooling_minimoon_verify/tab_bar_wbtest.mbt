///|
fn verification_tab_fixture() -> Json {
  Json::object({
    "position": Json::string("bottom"),
    "color": Json::string("#123456"),
    "selectedColor": Json::string("#ABCDEF"),
    "backgroundColor": Json::string("#FFFFFF"),
    "borderStyle": Json::string("white"),
    "list": Json::array(
      ["pages/home/home", "pages/lab/lab"].map(route => {
        Json::object({
          "pagePath": Json::string(route),
          "text": Json::string("Tab"),
        })
      }),
    ),
  })
}

///|
async test "native Tab verification detects manifest drift, malformed entries and page foreground drift" {
  let root = @fs.tmpdir(prefix="minimoon-tab-verification")
  defer @fs.rmdir(root, recursive=true)
  let pages = ["pages/home/home", "pages/lab/lab"].map(route => {
    Json::object({ "route": Json::string(route) })
  })
  let tab = verification_tab_fixture()
  let manifest = Json::object({ "pages": Json::array(pages), "tabBar": tab })
  let app = Json::object({ "tabBar": tab })
  assert_eq(string(tab_bar_status(root, manifest), "status"), "failed")
  write_json(join(root, "dist/app.json"), app)
  for page in pages {
    write_json(
      join(root, "dist/" + string(page, "route") + ".json"),
      Json::empty_object(),
    )
  }
  assert_eq(string(tab_bar_status(root, manifest), "status"), "passed")
  for
    invalid in [
      ("position", Json::string("top")),
      ("color", Json::string("red")),
      ("borderStyle", Json::string("red")),
      ("custom", Json::boolean(true)),
      ("list", Json::array([array(tab, "list")[0], array(tab, "list")[0]])),
      ("list", Json::array([Json::null(), Json::null()])),
    ] {
    let (key, value) = invalid
    let changed = Json::object(object(tab, "tab").copy())
    object(changed, "tab")[key] = value
    object(manifest, "manifest")["tabBar"] = changed
    write_json(join(root, "dist/app.json"), Json::object({ "tabBar": changed }))
    assert_eq(string(tab_bar_status(root, manifest), "status"), "failed")
  }
  object(manifest, "manifest")["tabBar"] = tab
  write_json(join(root, "dist/app.json"), Json::empty_object())
  assert_eq(string(tab_bar_status(root, manifest), "status"), "failed")
  write_json(join(root, "dist/app.json"), app)
  write_json(
    join(root, "dist/pages/home/home.json"),
    Json::object({ "navigationBarTextStyle": Json::string("white") }),
  )
  assert_eq(string(tab_bar_status(root, manifest), "status"), "failed")
  object(pages[0], "page")["navigationBarTextStyle"] = Json::string("white")
  assert_eq(string(tab_bar_status(root, manifest), "status"), "passed")
  object(pages[0], "page")["navigationBarTextStyle"] = Json::string("red")
  write_json(
    join(root, "dist/pages/home/home.json"),
    Json::object({ "navigationBarTextStyle": Json::string("red") }),
  )
  assert_eq(string(tab_bar_status(root, manifest), "status"), "failed")
}

///|
async test "PNG resource verification and fingerprints both observe raw byte mutations" {
  let root = @fs.tmpdir(prefix="minimoon-png-fingerprint")
  defer @fs.rmdir(root, recursive=true)
  write_fingerprint_fixture(root, "App({})\n")
  let manifest = Json::object({
    "resources": Json::array([
      Json::object({
        "id": Json::string("icons"),
        "version": Json::string("1"),
        "assets": Json::array([Json::string("assets/tab.png")]),
      }),
    ]),
  })
  let png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x04\x00\x00\x00\xb5\x1c\x0c\x02\x00\x00\x00\x0bIDAT\x78\xda\x63\xfc\xff\x1f\x00\x03\x03\x02\x00\xef\xa2\xa7\x5b\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let file = join(root, "dist/assets/tab.png")
  write(file, "")
  @fs.write_file(file, png, create_mode=CreateOrTruncate, permission=0o600)
  assert_eq(string(resource_assets_status(root, manifest), "status"), "passed")
  let fingerprint = artifact_fingerprint(root)
  let changed = png.to_array()
  changed[45] = changed[45] ^ 1
  @fs.write_file(
    file,
    Bytes::from_array(changed),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  assert_eq(string(resource_assets_status(root, manifest), "status"), "failed")
  assert_not_eq(artifact_fingerprint(root), fingerprint)
}
