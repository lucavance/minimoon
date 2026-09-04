///|
async fn host_suite(root : String) -> Unit {
  run(root, "MoonBit native tests", "moon", ["test"])
  run(root, "MoonBit JavaScript target tests", "moon", [
    "test", "--target", "js",
  ])
  run(root, "MoonBit JavaScript target check", "moon", [
    "check", "--target", "js", "--deny-warn",
  ])
  build_examples(root, "dev")
  verify_examples(root, false)
  audit_generated_javascript(root, "dev")
  let conformance_root = join(root, "examples/" + conformance_fixture)
  let conformance_report = @verify.verify(conformance_root, false)
  guard json_string(conformance_report, "status") == "passed" else {
    abort("conformance app automated verification failed")
  }
  require_text(
    root, "examples/miniapp_conformance_app/dist/minimoon.templates.wxml", "template name=\"minimoon_dynamic_node\"",
  )
  require_text(
    root, "examples/miniapp_conformance_app/dist/minimoon.templates.wxml", "wx:key=\"identity\"",
  )
  require_text(
    root, "examples/miniapp_conformance_app/dist/pages/lab/lab.wxml", "<import src=\"../../minimoon.templates.wxml\" />",
  )
  dynamic_app_host_smoke(root, join(conformance_root, "dist/pages/lab/lab.js"))
  scheduler_host_smoke(root, join(conformance_root, "dist/minimoon.host.js"))
  navigation_host_smoke(root, [
    join(
      root, "examples/miniapp_conformance_app/dist/pages/showcase/showcase.js",
    ),
    join(root, "examples/miniapp_conformance_app/dist/pages/home/home.js"),
    join(root, "examples/miniapp_conformance_app/dist/pages/details/details.js"),
    join(root, "examples/miniapp_conformance_app/dist/pages/lab/lab.js"),
  ])
}

///|
fn candidate_summary_is_public(summary : Json) -> Bool {
  let devtools = json_field(summary, "devtools")
  guard json_string(devtools, "status") == "pending" else { return false }
  match json_field(devtools, "evidence") {
    Null => true
    _ => false
  }
}

///|
async fn candidate_suite(root : String) -> Unit {
  build_examples(root, "release")
  verify_examples(root, false)
  for app in example_apps {
    let report = read_json(
      root,
      "examples/" + app + "/generated/verify_report.json",
    )
    guard json_string(report, "status") == "passed" &&
      !json_bool(report, "release") else {
      abort(app + " candidate verification must pass without host evidence")
    }
    let manifest = read_json(
      root,
      "examples/" + app + "/generated/manifest.json",
    )
    guard json_string(manifest, "pageBridgeEncoding") ==
      "shared-compact-node-v1" else {
      abort(app + " candidate must contain release compact artifacts")
    }
    let summary = read_json(
      root,
      "examples/" + app + "/generated/release_summary.json",
    )
    let report_fingerprint = json_string(report, "artifactFingerprint")
    let automated = json_field(summary, "automated")
    guard json_string(summary, "mode") == "release" &&
      json_string(automated, "status") == "passed" &&
      json_string(automated, "artifactFingerprint") == report_fingerprint else {
      abort(app + " candidate summary does not describe verified release bytes")
    }
    guard candidate_summary_is_public(summary) else {
      abort(
        app + " candidate summary must keep local DevTools evidence private",
      )
    }
  }
}

///|
async fn release_suite(root : String) -> Unit {
  build_examples(root, "release")
  verify_examples(root, true)
  for app in example_apps {
    let summary = read_json(
      root,
      "examples/" + app + "/generated/release_summary.json",
    )
    let _ = json_field(summary, "schemaVersion")
    let _ = json_field(summary, "runtimeApiVersion")
    let automated = json_field(summary, "automated")
    guard json_string(automated, "status") == "passed" else {
      abort(app + " release summary must reflect automated verification")
    }
    let _ = json_field(automated, "artifactFingerprint")
    let _ = json_field(summary, "devtools")
    let manifest = read_json(
      root,
      "examples/" + app + "/generated/manifest.json",
    )
    guard json_field(manifest, "runtimeApiVersion") ==
      Json::number(@versions.runtime_api_version().to_double()) &&
      json_field(manifest, "rendererProtocolVersion") ==
      Json::number(@versions.renderer_protocol_version().to_double()) else {
      abort(
        app +
        " must use runtime API v" +
        @versions.runtime_api_version().to_string() +
        " and renderer protocol v" +
        @versions.renderer_protocol_version().to_string(),
      )
    }
  }
}

///|
