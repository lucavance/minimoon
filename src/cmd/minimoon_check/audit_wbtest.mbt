///|
fn audit_test_lock(records : Array[String]) -> String {
  let packages : Map[String, Json] = Map([])
  for record in records {
    packages[record] = Json::array([
      Json::string(record),
      Json::string(""),
      Json::empty_object(),
      Json::string("sha512-test"),
    ])
  }
  Json::object({
    "lockfileVersion": Json::number(1),
    "configVersion": Json::number(1),
    "packages": Json::object(packages),
  }).stringify()
}

///|
fn audit_test_report(
  name? : String = "braces",
  url? : String = dependency_audit_exception_url,
  severity? : String = "high",
) -> String {
  let packages : Map[String, Json] = Map([])
  packages[name] = Json::array([
    Json::object({
      "url": Json::string(url),
      "severity": Json::string(severity),
    }),
  ])
  Json::object(packages).stringify()
}

///|
test "audit accepts only the temporary braces exception" {
  let lock = audit_test_lock(["braces@3.0.3", "@scope/tool@1.2.3"])
  let decision = evaluate_dependency_audit(
    1,
    audit_test_report(),
    "",
    lock,
    dependency_audit_exception_deadline_ms - 1UL,
  )
  assert_eq(decision.status, "accepted_exception")
  assert_eq(dependency_audit_lock_packages(lock).0, ["3.0.3"])
  let summary = dependency_audit_summary(decision, Some(1))
  assert_eq(json_string(summary, "status"), "accepted_exception")
  assert_true(
    json_string(summary, "reason").contains("not a vulnerability fix"),
  )
}

///|
test "audit rejects changed advisory, versions, criticals and command errors" {
  let lock = audit_test_lock(["braces@3.0.3", "other@1.0.0"])
  for
    (name, url, severity, code, stderr) in [
      ("other", dependency_audit_exception_url, "high", 1, ""),
      (
        "braces", "https://github.com/advisories/GHSA-aaaa-bbbb-cccc", "high", 1,
        "",
      ),
      ("braces", dependency_audit_exception_url, "critical", 1, ""),
      ("braces", dependency_audit_exception_url, "urgent", 1, ""),
      ("braces", dependency_audit_exception_url, "high", 1, "network error"),
      ("braces", dependency_audit_exception_url, "high", 0, ""),
      ("braces", dependency_audit_exception_url, "high", 2, ""),
    ] {
    assert_eq(
      evaluate_dependency_audit(
        code,
        audit_test_report(name~, url~, severity~),
        stderr,
        lock,
        0UL,
      ).status,
      "failed",
    )
  }
  assert_eq(
    evaluate_dependency_audit(
      1,
      audit_test_report(),
      "",
      audit_test_lock(["braces@3.0.3", "braces@3.0.2"]),
      0UL,
    ).status,
    "failed",
  )
}

///|
test "audit keeps informational findings clean and enforces expiry" {
  let lock = audit_test_lock(["braces@3.0.3"])
  assert_eq(evaluate_dependency_audit(0, "{}", "", lock, 0UL).status, "clean")
  assert_eq(evaluate_dependency_audit(1, "{}", "", lock, 0UL).status, "failed")
  for severity in ["info", "low", "moderate"] {
    assert_eq(
      evaluate_dependency_audit(0, audit_test_report(severity~), "", lock, 0UL).status,
      "clean",
    )
  }
  for
    now in [
      dependency_audit_exception_deadline_ms,
      dependency_audit_exception_deadline_ms + 1UL,
    ] {
    assert_eq(
      evaluate_dependency_audit(1, audit_test_report(), "", lock, now).status,
      "failed",
    )
  }
}

///|
test "audit rejects malformed reports and locks" {
  let lock = audit_test_lock(["braces@3.0.3"])
  for
    report in [
      "",
      "[]",
      "null",
      "{\"braces\":{}}",
      "{\"braces\":[{}]}",
      "{\"error\":[{\"url\":\"\",\"severity\":\"low\"}]}",
      audit_test_report(name="missing", severity="low"),
      audit_test_report(url="", severity="low"),
    ] {
    assert_eq(
      evaluate_dependency_audit(0, report, "", lock, 0UL).status,
      "failed",
    )
  }
  for
    bad_lock in [
      "", "{}", "{\"packages\":{}}", "{\"packages\":{\"x\":[]}}", "{\"packages\":{\"braces\":[\"braces@3.0.3\"]}}",
    ] {
    assert_eq(
      evaluate_dependency_audit(0, "{}", "", bad_lock, 0UL).status,
      "failed",
    )
  }
  assert_eq(
    dependency_audit_record_identity("@scope/tool@1.2.3"),
    Some(("@scope/tool", "1.2.3")),
  )
}
