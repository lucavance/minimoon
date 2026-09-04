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
