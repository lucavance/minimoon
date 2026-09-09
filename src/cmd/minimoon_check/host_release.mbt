///|
async fn host_suite(root : String) -> Unit {
  application_type_gate(root)
  run(root, "MoonBit native tests", "moon", ["test", "--target", "native"])
  run(root, "MoonBit JavaScript target tests", "moon", [
    "test", "--target", "js",
  ])
  run(root, "MoonBit JavaScript target check", "moon", [
    "check", "--target", "js", "--deny-warn",
  ])
  run_ui_tests(root, "native")
  run_ui_tests(root, "js")
  run(root, "Conformance application and four-Tab interaction tests", "moon", [
    "test", "examples/miniapp_conformance_app/src/app", "examples/miniapp_conformance_app/src/pages/showcase",
    "examples/miniapp_conformance_app/src/pages/home", "examples/miniapp_conformance_app/src/pages/details",
    "examples/miniapp_conformance_app/src/pages/lab", "examples/miniapp_conformance_app/src/components/toggle_card",
    "examples/miniapp_conformance_app/src/shared/shell", "examples/miniapp_conformance_app/src/resources",
    "examples/miniapp_conformance_app/src/tests", "--target", "js", "--deny-warn",
  ])
  build_examples(root, "dev")
  verify_examples(root, false)
  audit_generated_javascript(root, "dev")
  build_verify_ui_gallery(root, "dev", false)
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
    join(
      root, "examples/miniapp_conformance_app/dist/pages/interaction/interaction.js",
    ),
    join(
      root, "examples/miniapp_conformance_app/dist/pages/capabilities/capabilities.js",
    ),
    join(
      root, "examples/miniapp_conformance_app/dist/pages/application/application.js",
    ),
  ])
  http_probe(root, true)
  application_host_smoke(root, join(conformance_root, "dist"))
}

///|
fn candidate_summary_is_public(summary : Json) -> Bool {
  candidate_field(summary, "devtools") ==
  Json::object({ "status": Json::string("pending"), "evidence": Json::null() })
}

///|
fn candidate_field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn candidate_artifact_problems(
  name : String,
  report : Json,
  manifest : Json,
  summary : Json,
  fingerprint : String,
) -> Array[String] {
  let problems : Array[String] = []
  if candidate_field(report, "schemaVersion") != Json::number(1.0) ||
    candidate_field(report, "status") != Json::string("passed") ||
    candidate_field(report, "release") != Json::boolean(false) {
    problems.push("candidate verification must pass without host evidence")
  }
  match candidate_field(report, "checks") {
    Array(checks) =>
      if checks.is_empty() ||
        checks.any(check => {
          candidate_field(check, "status") != Json::string("passed")
        }) {
        problems.push("candidate verification checks must all pass")
      }
    _ => problems.push("candidate verification checks are missing")
  }
  if fingerprint == "" ||
    candidate_field(report, "artifactFingerprint") != Json::string(fingerprint) {
    problems.push(
      "candidate report fingerprint differs from current artifact bytes",
    )
  }
  for value in [manifest, summary] {
    for
      entry in [
        ("schemaVersion", @versions.app_contract_version()),
        ("runtimeApiVersion", @versions.runtime_api_version()),
        ("rendererProtocolVersion", @versions.renderer_protocol_version()),
      ] {
      let (field, expected) = entry
      if candidate_field(value, field) != Json::number(expected.to_double()) {
        problems.push("candidate artifact version differs: " + field)
      }
    }
    if candidate_field(value, "name") != Json::string(name) {
      problems.push("candidate artifact fixture name differs")
    }
  }
  if candidate_field(manifest, "pageBridgeEncoding") !=
    Json::string("shared-compact-node-v1") {
    problems.push("candidate must contain release compact artifacts")
  }
  let automated = candidate_field(summary, "automated")
  if candidate_field(summary, "mode") != Json::string("release") ||
    candidate_field(automated, "status") != Json::string("passed") ||
    candidate_field(automated, "artifactFingerprint") !=
    Json::string(fingerprint) {
    problems.push("candidate summary does not describe verified release bytes")
  }
  if !candidate_summary_is_public(summary) {
    problems.push("candidate summary must keep local DevTools evidence private")
  }
  problems
}

///|
async fn check_candidate_artifacts(
  root : String,
  fixture : String,
  name : String,
) -> Unit {
  let problems = candidate_artifact_problems(
    name,
    read_json(root, fixture + "/generated/verify_report.json"),
    read_json(root, fixture + "/generated/manifest.json"),
    read_json(root, fixture + "/generated/release_summary.json"),
    @verify.artifact_fingerprint(join(root, fixture)),
  )
  guard problems.is_empty() else { abort(fixture + ": " + problems.join("; ")) }
}

///|
async fn candidate_suite(root : String) -> Unit {
  build_examples(root, "release")
  verify_examples(root, false)
  application_host_smoke(
    root,
    join(root, "examples/" + conformance_fixture + "/dist"),
  )
  build_verify_ui_gallery(root, "release", false)
  for app in example_apps {
    check_candidate_artifacts(root, "examples/" + app, app)
  }
}

///|
async fn release_suite(root : String) -> Unit {
  build_examples(root, "release")
  verify_examples(root, true)
  build_verify_ui_gallery(root, "release", true)
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
