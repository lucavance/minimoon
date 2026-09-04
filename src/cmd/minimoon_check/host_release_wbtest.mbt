///|
fn candidate_summary(devtools : Json) -> Json {
  Json::object({ "devtools": devtools })
}

///|
fn candidate_evidence(fingerprint : String) -> Json {
  Json::object({
    "scope": Json::string(
      "current-v" + @versions.app_contract_version().to_string(),
    ),
    "status": Json::string("passed"),
    "artifactFingerprint": Json::string(fingerprint),
  })
}

///|
test "candidate without evidence remains pending" {
  let summary = candidate_summary(
    Json::object({ "status": Json::string("pending"), "evidence": Json::null() }),
  )
  assert_true(
    candidate_evidence_state(summary, None, "fixture-fingerprint")
    is CandidateEvidencePending,
  )
}

///|
test "candidate with matching passed evidence restores release state" {
  let fingerprint = "fixture-fingerprint"
  let summary = candidate_summary(
    Json::object({
      "status": Json::string("passed"),
      "evidence": Json::string("generated/devtools.evidence.json"),
      "artifactFingerprint": Json::string(fingerprint),
    }),
  )
  assert_true(
    candidate_evidence_state(
      summary,
      Some(candidate_evidence(fingerprint)),
      fingerprint,
    )
    is CandidateEvidencePassed,
  )
}

///|
test "candidate pending ignores stale evidence" {
  let summary = candidate_summary(
    Json::object({ "status": Json::string("pending"), "evidence": Json::null() }),
  )
  assert_true(
    candidate_evidence_state(
      summary,
      Some(candidate_evidence("stale-fingerprint")),
      "current-fingerprint",
    )
    is CandidateEvidencePending,
  )
}

///|
test "panic passed candidate rejects mismatched evidence" {
  let summary = candidate_summary(
    Json::object({
      "status": Json::string("passed"),
      "evidence": Json::string("generated/devtools.evidence.json"),
      "artifactFingerprint": Json::string("current-fingerprint"),
    }),
  )
  let _ = candidate_evidence_state(
    summary,
    Some(candidate_evidence("stale-fingerprint")),
    "current-fingerprint",
  )
}

///|
test "panic candidate rejects malformed evidence state" {
  let summary = candidate_summary(
    Json::object({
      "status": Json::string("passed"),
      "evidence": Json::string("generated/devtools.evidence.json"),
      "artifactFingerprint": Json::string("fixture-fingerprint"),
    }),
  )
  let _ = candidate_evidence_state(
    summary,
    Some(
      Json::object({
        "scope": Json::string("current-v7"),
        "artifactFingerprint": Json::string("fixture-fingerprint"),
      }),
    ),
    "fixture-fingerprint",
  )
}
