///|
fn candidate_summary(devtools : Json) -> Json {
  Json::object({ "devtools": devtools })
}

///|
test "candidate summary exposes only pending host state" {
  let summary = candidate_summary(
    Json::object({ "status": Json::string("pending"), "evidence": Json::null() }),
  )
  assert_true(candidate_summary_is_public(summary))
}

///|
test "candidate summary rejects release evidence" {
  let summary = candidate_summary(
    Json::object({
      "status": Json::string("passed"),
      "evidence": Json::string("generated/devtools.evidence.json"),
      "artifactFingerprint": Json::string("fixture-fingerprint"),
    }),
  )
  assert_false(candidate_summary_is_public(summary))
}

///|
test "candidate pending state cannot name evidence" {
  let summary = candidate_summary(
    Json::object({
      "status": Json::string("pending"),
      "evidence": Json::string("generated/devtools.evidence.json"),
    }),
  )
  assert_false(candidate_summary_is_public(summary))
}

///|
fn candidate_test_replace(
  value : Json,
  field : String,
  replacement : Json,
) -> Json {
  let result : Map[String, Json] = Map([])
  if value is Object(fields) {
    for key, item in fields {
      result[key] = item
    }
  }
  result[field] = replacement
  Json::object(result)
}

///|
fn candidate_test_artifacts(name : String) -> (Json, Json, Json) {
  let report = Json::object({
    "schemaVersion": Json::number(1.0),
    "status": Json::string("passed"),
    "release": Json::boolean(false),
    "artifactFingerprint": Json::string("current-fingerprint"),
    "checks": Json::array([Json::object({ "status": Json::string("passed") })]),
  })
  let manifest = Json::object({
    "name": Json::string(name),
    "schemaVersion": Json::number(@versions.app_contract_version().to_double()),
    "runtimeApiVersion": Json::number(
      @versions.runtime_api_version().to_double(),
    ),
    "rendererProtocolVersion": Json::number(
      @versions.renderer_protocol_version().to_double(),
    ),
    "pageBridgeEncoding": Json::string("shared-compact-node-v1"),
  })
  let summary = candidate_test_replace(
    candidate_test_replace(
      candidate_test_replace(manifest, "mode", Json::string("release")),
      "automated",
      Json::object({
        "status": Json::string("passed"),
        "artifactFingerprint": Json::string("current-fingerprint"),
      }),
    ),
    "devtools",
    Json::object({ "status": Json::string("pending"), "evidence": Json::null() }),
  )
  (report, manifest, summary)
}

///|
test "core and UI candidates enforce the same report and artifact boundary" {
  for name in ["miniapp_conformance_app", "minimoon_ui_showcase"] {
    let (report, manifest, summary) = candidate_test_artifacts(name)
    assert_true(
      candidate_artifact_problems(
        name, report, manifest, summary, "current-fingerprint",
      ).is_empty(),
    )
    for
      entry in [
        ("schemaVersion", Json::number(99.0)),
        ("status", Json::string("failed")),
        ("release", Json::boolean(true)),
        ("release", Json::null()),
        ("artifactFingerprint", Json::string("stale-fingerprint")),
        ("checks", Json::array([])),
        (
          "checks",
          Json::array([Json::object({ "status": Json::string("failed") })]),
        ),
      ] {
      let (field, invalid) = entry
      assert_false(
        candidate_artifact_problems(
          name,
          candidate_test_replace(report, field, invalid),
          manifest,
          summary,
          "current-fingerprint",
        ).is_empty(),
      )
    }
    assert_false(
      candidate_artifact_problems(
        name, report, manifest, summary, "different-current-bytes",
      ).is_empty(),
    )
    for
      entry in [
        ("schemaVersion", Json::number(99.0)),
        ("runtimeApiVersion", Json::number(99.0)),
        ("rendererProtocolVersion", Json::number(99.0)),
        ("name", Json::string("another-fixture")),
      ] {
      let (field, invalid) = entry
      assert_false(
        candidate_artifact_problems(
          name,
          report,
          candidate_test_replace(manifest, field, invalid),
          summary,
          "current-fingerprint",
        ).is_empty(),
      )
      assert_false(
        candidate_artifact_problems(
          name,
          report,
          manifest,
          candidate_test_replace(summary, field, invalid),
          "current-fingerprint",
        ).is_empty(),
      )
    }
    assert_false(
      candidate_artifact_problems(
        name,
        report,
        candidate_test_replace(
          manifest,
          "pageBridgeEncoding",
          Json::string("debug"),
        ),
        summary,
        "current-fingerprint",
      ).is_empty(),
    )
    for
      entry in [
        ("mode", Json::string("dev")),
        (
          "automated",
          Json::object({
            "status": Json::string("passed"),
            "artifactFingerprint": Json::string("stale"),
          }),
        ),
        (
          "devtools",
          Json::object({
            "status": Json::string("pending"),
            "evidence": Json::null(),
            "artifactFingerprint": Json::string("private"),
          }),
        ),
        ("devtools", Json::object({ "status": Json::string("pending") })),
      ] {
      let (field, invalid) = entry
      assert_false(
        candidate_artifact_problems(
          name,
          report,
          manifest,
          candidate_test_replace(summary, field, invalid),
          "current-fingerprint",
        ).is_empty(),
      )
    }
  }
}
