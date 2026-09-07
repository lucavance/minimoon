///|
async fn write_fingerprint_fixture(root : String, app_source : String) -> Unit {
  let files : Array[(String, String)] = [
    (
      "generated/manifest.json",
      (
        #|{
        #|  "schemaVersion": 8,
        #|  "runtimeApiVersion": 10,
        #|  "rendererProtocolVersion": 8,
        #|  "pages": [{ "route": "pages/home/home" }]
        #|}
        #|
      ),
    ),
    (
      "generated/smoke_checklist.json", "{\"schemaVersion\":1,\"checks\":[\"mount\"]}\n",
    ),
    ("dist/app.js", app_source),
    ("dist/app.json", "{\"pages\":[\"pages/home/home\"]}\n"),
    ("dist/app.wxss", "page { color: #111; }\n"),
    ("dist/project.config.json", "{}\n"),
    ("dist/project.private.config.example.json", "{}\n"),
    ("dist/sitemap.json", "{\"rules\":[]}\n"),
    ("dist/minimoon.host.js", "exports.register = () => {}\n"),
    ("dist/minimoon.protocol.js", "exports.protocol = 1\n"),
    ("dist/minimoon.initial.js", "exports.initial = 1\n"),
    ("dist/minimoon.runtime.js", "exports.version = 10\n"),
    ("dist/minimoon.templates.wxml", "<template name=\"mm\" />\n"),
    ("dist/pages/home/home.js", "Page({})\n"),
    ("dist/pages/home/home.json", "{}\n"),
    ("dist/pages/home/home.wxml", "<view>home</view>\n"),
    ("dist/pages/home/home.wxss", "page {}\n"),
  ]
  for entry in files {
    let (relative, content) = entry
    let file = join(root, relative)
    let parent = Path::dirname(file).to_string()
    if !@fs.exists(parent) {
      @fs.mkdir(parent, permission=0o700, recursive=true)
    }
    @fs.write_file(
      file,
      content,
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
  }
}

///|
test "resource verifier shares the generator portable relative-path policy" {
  for
    path in [
      "assets/./icon.svg", "assets/../icon.svg", "assets/x y.svg", "assets/%2e/icon.svg",
      "assets//icon.svg", "assets/icon.js", "app.wxss",
    ] {
    assert_false(safe_resource_asset(path))
  }
  assert_true(safe_resource_asset("assets/icons/a..b.svg"))
  assert_true(safe_resource_asset("assets/icons/license.txt"))
}

///|
async test "resource verification rejects missing or unsafe declared assets" {
  let root = @fs.tmpdir(prefix="minimoon-resource-verification")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let manifest = Json::object({
      "resources": Json::array([
        Json::object({
          "id": Json::string("sample"),
          "version": Json::string("1.0.0"),
          "assets": Json::array([Json::string("assets/sample/icon.svg")]),
        }),
      ]),
    })
    assert_eq(
      string(resource_assets_status(root, manifest), "status"),
      "failed",
    )
    write(join(root, "dist/assets/sample/icon.svg"), "<svg/>")
    assert_eq(
      string(resource_assets_status(root, manifest), "status"),
      "passed",
    )
    let unsafe_manifest = Json::object({
      "resources": Json::array([
        Json::object({
          "id": Json::string("sample"),
          "version": Json::string("1.0.0"),
          "assets": Json::array([Json::string("assets/../app.js")]),
        }),
      ]),
    })
    assert_eq(
      string(resource_assets_status(root, unsafe_manifest), "status"),
      "failed",
    )
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "resource SVG bytes and provider manifest descriptors bind the artifact fingerprint" {
  let root = @fs.tmpdir(prefix="minimoon-resource-fingerprint")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write_fingerprint_fixture(root, "App({})\n")
    let original = artifact_fingerprint(root)
    write(
      join(root, "dist/assets/test/icon.svg"),
      "<svg><title>Light</title></svg>",
    )
    let with_asset = artifact_fingerprint(root)
    assert_not_eq(with_asset, original)
    write(
      join(root, "dist/assets/test/icon.svg"),
      "<svg><title>Dark</title></svg>",
    )
    assert_not_eq(artifact_fingerprint(root), with_asset)
    let with_changed_asset = artifact_fingerprint(root)
    let manifest = object(
      read_json(join(root, "generated/manifest.json")),
      "fixture",
    )
    manifest["resources"] = Json::array([
      Json::object({
        "id": Json::string("test"),
        "version": Json::string("1.0.0"),
        "features": Json::array([Json::string("button")]),
        "assets": Json::array([Json::string("assets/test/icon.svg")]),
      }),
    ])
    write(
      join(root, "generated/manifest.json"),
      Json::object(manifest).stringify(),
    )
    assert_not_eq(artifact_fingerprint(root), with_changed_asset)
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "Skyline page configs require custom navigation" {
  assert_true(
    valid_skyline_page_config(
      Json::object({
        "renderer": Json::string("skyline"),
        "navigationStyle": Json::string("custom"),
      }),
    ),
  )
  assert_true(
    !valid_skyline_page_config(
      Json::object({ "renderer": Json::string("skyline") }),
    ),
  )
  assert_true(
    !valid_skyline_page_config(
      Json::object({
        "renderer": Json::string("skyline"),
        "navigationStyle": Json::string("custom"),
        "navigationBarTitleText": Json::string("ignored"),
      }),
    ),
  )
}

///|
test "verified host boundary requires both WeChat transforms and minification enabled" {
  let enabled = Json::object({
    "setting": Json::object({
      "es6": Json::boolean(true),
      "enhance": Json::boolean(true),
      "minified": Json::boolean(true),
    }),
  })
  let es6_only = Json::object({
    "setting": Json::object({
      "es6": Json::boolean(true),
      "enhance": Json::boolean(false),
      "minified": Json::boolean(true),
    }),
  })
  let enhance_only = Json::object({
    "setting": Json::object({
      "es6": Json::boolean(false),
      "enhance": Json::boolean(true),
      "minified": Json::boolean(true),
    }),
  })
  let disabled = Json::object({
    "setting": Json::object({
      "es6": Json::boolean(false),
      "enhance": Json::boolean(false),
      "minified": Json::boolean(true),
    }),
  })
  let not_minified = Json::object({
    "setting": Json::object({
      "es6": Json::boolean(true),
      "enhance": Json::boolean(true),
      "minified": Json::boolean(false),
    }),
  })
  assert_true(valid_devtools_host_project_config(enabled))
  assert_false(valid_devtools_host_project_config(es6_only))
  assert_false(valid_devtools_host_project_config(enhance_only))
  assert_false(valid_devtools_host_project_config(disabled))
  assert_false(valid_devtools_host_project_config(not_minified))
}

///|
test "custom navigation app config omits ineffective window fields" {
  assert_true(valid_custom_navigation_app_config(Json::empty_object()))
  assert_false(
    valid_custom_navigation_app_config(
      Json::object({
        "window": Json::object({
          "navigationBarTitleText": Json::string("ignored"),
        }),
      }),
    ),
  )
}

///|
async test "DevTools evidence scope follows the current App Contract" {
  assert_eq(current_evidence_scope(), "current-v8")
  let root = @fs.tmpdir(prefix="minimoon-evidence-scope")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let evidence_file = join(root, "generated/devtools.evidence.json")
    write_json(
      evidence_file,
      Json::object({
        "scope": Json::string("current-v6"),
        "status": Json::string("passed"),
        "artifactFingerprint": Json::string("fixture-fingerprint"),
      }),
    )
    assert_false(matching_evidence(root, "fixture-fingerprint"))
    write_json(
      evidence_file,
      Json::object({
        "scope": Json::string(current_evidence_scope()),
        "status": Json::string("passed"),
        "artifactFingerprint": Json::string("fixture-fingerprint"),
      }),
    )
    assert_true(matching_evidence(root, "fixture-fingerprint"))
    assert_false(matching_evidence(root, "different-fingerprint"))
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "candidate verification keeps local evidence private" {
  let root = @fs.tmpdir(prefix="minimoon-private-evidence")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    let fingerprint = "fixture-fingerprint"
    write_json(
      join(root, "generated/devtools.evidence.json"),
      Json::object({
        "scope": Json::string(current_evidence_scope()),
        "status": Json::string("passed"),
        "artifactFingerprint": Json::string(fingerprint),
      }),
    )
    let candidate = evidence_check(root, fingerprint, false)
    assert_eq(string(candidate, "status"), "passed")
    assert_eq(
      string(candidate, "detail"),
      "pending; required only by verify --release",
    )
    let release = evidence_check(root, fingerprint, true)
    assert_eq(
      string(release, "detail"),
      "passed evidence matches current artifact fingerprint",
    )
  }
  @fs.rmdir(root, recursive=true)
}

///|
test "host smoke follows the initial page lifecycle order and verifies disposal" {
  let source = host_smoke_source(["/tmp/pages/home/home.js"])
  assert_true(source.contains("globalThis.TextEncoder = undefined"))
  assert_true(
    source.contains(
      "page.onLoad.call(host, {})\n" +
      "  page.onShow.call(host)\n" +
      "  page.onReady.call(host)",
    ),
  )
  assert_true(
    source.contains(
      "if (host.__mmInstanceId !== null) throw new Error(\"runtime instance was not cleared on unload\")",
    ),
  )
}

///|
async test "artifact fingerprints are independent of checkout location" {
  let first = @fs.tmpdir(prefix="minimoon-fingerprint-first")
  let second = @fs.tmpdir(prefix="minimoon-fingerprint-second")
  {
    errdefer {
      if @fs.exists(first) {
        @fs.rmdir(first, recursive=true)
      }
      if @fs.exists(second) {
        @fs.rmdir(second, recursive=true)
      }
    }
    write_fingerprint_fixture(first, "App({})\n")
    write_fingerprint_fixture(second, "App({})\n")
    let first_fingerprint = artifact_fingerprint(first)
    let second_fingerprint = artifact_fingerprint(second)
    assert_eq(first_fingerprint, second_fingerprint)
    assert_true(first_fingerprint.has_prefix("fnv1a64-relpath-v2:"))
  }
  @fs.rmdir(first, recursive=true)
  @fs.rmdir(second, recursive=true)
}

///|
async test "local private project config is not fingerprinted" {
  let root = @fs.tmpdir(prefix="minimoon-fingerprint-private")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write_fingerprint_fixture(root, "App({})\n")
    let expected = artifact_fingerprint(root)
    let private_config = join(root, "dist/project.private.config.json")
    @fs.write_file(
      private_config,
      "{\"appid\":\"test-real-appid\"}\n",
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    assert_eq(artifact_fingerprint(root), expected)
    @fs.write_file(
      private_config,
      "{\"appid\":\"another-test-appid\"}\n",
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    assert_eq(artifact_fingerprint(root), expected)
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "artifact fingerprints change with protected content" {
  let first = @fs.tmpdir(prefix="minimoon-fingerprint-content-first")
  let second = @fs.tmpdir(prefix="minimoon-fingerprint-content-second")
  {
    errdefer {
      if @fs.exists(first) {
        @fs.rmdir(first, recursive=true)
      }
      if @fs.exists(second) {
        @fs.rmdir(second, recursive=true)
      }
    }
    write_fingerprint_fixture(first, "App({})\n")
    write_fingerprint_fixture(second, "App({ changed: true })\n")
    assert_not_eq(artifact_fingerprint(first), artifact_fingerprint(second))
  }
  @fs.rmdir(first, recursive=true)
  @fs.rmdir(second, recursive=true)
}

///|
async test "shared host and application runtime are fingerprinted" {
  let root = @fs.tmpdir(prefix="minimoon-fingerprint-shared-runtime")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write_fingerprint_fixture(root, "App({})\n")
    let original = artifact_fingerprint(root)
    let host = join(root, "dist/minimoon.host.js")
    @fs.write_file(
      host,
      "exports.register = changed => changed\n",
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    let changed_host = artifact_fingerprint(root)
    assert_not_eq(changed_host, original)
    @fs.write_file(
      host,
      "exports.register = () => {}\n",
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    let runtime = join(root, "dist/minimoon.runtime.js")
    @fs.write_file(
      runtime,
      "exports.version = 8; exports.changed = true\n",
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    assert_not_eq(artifact_fingerprint(root), original)
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "release styles templates checklist and recursive files are fingerprinted" {
  let root = @fs.tmpdir(prefix="minimoon-fingerprint-release-boundary")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write_fingerprint_fixture(root, "App({})\n")
    let original = artifact_fingerprint(root)
    for
      entry in [
        ("dist/app.wxss", "page { color: #222; }\n"),
        ("dist/minimoon.templates.wxml", "<template name=\"changed\" />\n"),
        (
          "generated/smoke_checklist.json", "{\"schemaVersion\":1,\"checks\":[\"changed\"]}\n",
        ),
        ("generated/manifest.json", "{\"schemaVersion\":8}\n"),
      ] {
      let (relative, changed) = entry
      let file = join(root, relative)
      let previous = @fs.read_file(file).text()
      @fs.write_file(
        file,
        changed,
        create_mode=CreateOrTruncate,
        permission=0o600,
      )
      assert_not_eq(artifact_fingerprint(root), original)
      @fs.write_file(
        file,
        previous,
        create_mode=CreateOrTruncate,
        permission=0o600,
      )
      assert_eq(artifact_fingerprint(root), original)
    }
    let nested = join(root, "dist/assets/a/runtime.bin")
    @fs.mkdir(
      Path::dirname(nested).to_string(),
      permission=0o700,
      recursive=true,
    )
    @fs.write_file(
      nested,
      Bytes::from_array([0x00, 0xff, 0x7f]),
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    let nested_fingerprint = artifact_fingerprint(root)
    assert_not_eq(nested_fingerprint, original)
    @fs.remove(nested)
    let relocated = join(root, "dist/assets/b/runtime.bin")
    @fs.mkdir(
      Path::dirname(relocated).to_string(),
      permission=0o700,
      recursive=true,
    )
    @fs.write_file(
      relocated,
      Bytes::from_array([0x00, 0xff, 0x7f]),
      create_mode=CreateOrTruncate,
      permission=0o600,
    )
    let relocated_fingerprint = artifact_fingerprint(root)
    assert_not_eq(relocated_fingerprint, original)
    assert_not_eq(relocated_fingerprint, nested_fingerprint)
    @fs.remove(relocated)
    assert_eq(artifact_fingerprint(root), original)
  }
  @fs.rmdir(root, recursive=true)
}

///|
async test "v1 evidence never matches a v2 artifact fingerprint" {
  let root = @fs.tmpdir(prefix="minimoon-fingerprint-v1-evidence")
  {
    errdefer (if @fs.exists(root) { @fs.rmdir(root, recursive=true) })
    write_fingerprint_fixture(root, "App({})\n")
    let fingerprint = artifact_fingerprint(root)
    write_json(
      join(root, "generated/devtools.evidence.json"),
      Json::object({
        "scope": Json::string(current_evidence_scope()),
        "status": Json::string("passed"),
        "artifactFingerprint": Json::string("fnv1a64-relpath-v1:deadbeef"),
      }),
    )
    assert_false(matching_evidence(root, fingerprint))
  }
  @fs.rmdir(root, recursive=true)
}
