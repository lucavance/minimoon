///|
fn tab_host_manifest(tabs : Array[String]) -> Json {
  Json::object({
    "pages": Json::array(
      ["pages/home/home", "pages/lab/lab", "pages/details/details"].map(route => {
        Json::object({ "route": Json::string(route) })
      }),
    ),
    "tabBar": if tabs.is_empty() {
      Json::null()
    } else {
      Json::object({
        "list": Json::array(
          tabs.map(route => Json::object({ "pagePath": Json::string(route) })),
        ),
      })
    },
  })
}

///|
async test "disk host Tab routing rejects empty missing and extra stale route sets" {
  let root = @fs.tmpdir(prefix="minimoon-tab-host")
  defer @fs.rmdir(root, recursive=true)
  write(
    join(root, "dist/minimoon.protocol.js"),
    @host_js.shared_protocol_bridge(),
  )
  let tabs = ["pages/home/home", "pages/lab/lab"]
  let manifest = tab_host_manifest(tabs)
  for application in [false, true] {
    write(
      join(root, "dist/minimoon.host.js"),
      @host_js.shared_host_bridge(
        application~,
        tab_routes=tabs.map(route => "/" + route),
      ),
    )
    let good = native_tab_host_status(root, manifest)
    assert_eq(string(good, "status"), "passed", msg=string(good, "detail"))
  }
  // Use the release host minification flags; the probe must not parse identifiers.
  for file in ["minimoon.host.js", "minimoon.protocol.js"] {
    let (passed, detail) = run(
      "bun",
      [
        "build",
        "dist/" + file,
        "--target",
        "browser",
        "--format",
        "cjs",
        "--minify-whitespace",
        "--minify-identifiers",
        "--minify-syntax",
        "--external=*",
        "--outfile",
        "minified.cjs",
      ],
      root,
    )
    assert_true(passed, msg=detail)
    write(
      join(root, "dist/" + file),
      @fs.read_file(join(root, "minified.cjs")).text(),
    )
  }
  let release = native_tab_host_status(root, manifest)
  assert_eq(string(release, "status"), "passed", msg=string(release, "detail"))
  for
    stale in [
      [],
      ["/pages/home/home"],
      ["/pages/home/home", "/pages/lab/lab", "/pages/details/details"],
    ] {
    write(
      join(root, "dist/minimoon.host.js"),
      @host_js.shared_host_bridge(tab_routes=stale),
    )
    let rejected = native_tab_host_status(root, manifest)
    assert_eq(string(rejected, "status"), "failed")
    assert_true(
      string(rejected, "detail").contains("native Tab host/manifest mismatch"),
    )
  }
  // No-Tab applications still probe ordinary routes and reject stale Tab hosts.
  write(join(root, "dist/minimoon.host.js"), @host_js.shared_host_bridge())
  let plain = native_tab_host_status(root, tab_host_manifest([]))
  assert_eq(string(plain, "status"), "passed", msg=string(plain, "detail"))
  write(
    join(root, "dist/minimoon.host.js"),
    @host_js.shared_host_bridge(tab_routes=["/pages/home/home"]),
  )
  assert_eq(
    string(native_tab_host_status(root, tab_host_manifest([])), "status"),
    "failed",
  )
}

///|
async test "disk host Tab probe rejects missing artifacts and malformed manifest bindings" {
  let root = @fs.tmpdir(prefix="minimoon-tab-host-invalid")
  defer @fs.rmdir(root, recursive=true)
  assert_eq(
    string(native_tab_host_status(root, tab_host_manifest([])), "status"),
    "failed",
  )
  for
    bad in [
      Json::boolean(false),
      Json::empty_object(),
      Json::object({
        "list": Json::array([Json::object({ "pagePath": Json::number(1) })]),
      }),
    ] {
    let manifest = tab_host_manifest([])
    object(manifest, "manifest")["tabBar"] = bad
    assert_eq(
      string(native_tab_host_status(root, manifest), "status"),
      "failed",
    )
  }
}
