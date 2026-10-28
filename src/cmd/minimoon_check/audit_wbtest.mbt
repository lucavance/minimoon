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
  name~ : String = "braces",
  url~ : String = "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm",
  severity~ : String = "high",
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
test "audit blocks the withdrawn braces advisory if it reappears" {
  let lock = audit_test_lock(["braces@3.0.3", "@scope/tool@1.2.3"])
  let decision = evaluate_dependency_audit(1, audit_test_report(), "", lock)
  assert_eq(decision.status, "failed")
  assert_eq(
    json_string(dependency_audit_summary(decision, Some(1)), "status"),
    "failed",
  )
}

///|
test "audit rejects high and critical advisories and command errors" {
  let lock = audit_test_lock(["braces@3.0.3", "other@1.0.0"])
  for
    (name, url, severity, code, stderr) in [
      (
        "other", "https://github.com/advisories/GHSA-aaaa-bbbb-cccc", "high", 1,
        "",
      ),
      (
        "braces", "https://github.com/advisories/GHSA-aaaa-bbbb-cccc", "high", 1,
        "",
      ),
      (
        "braces", "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm", "critical",
        1, "",
      ),
      (
        "braces", "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm", "urgent",
        1, "",
      ),
      (
        "braces", "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm", "high", 1,
        "network error",
      ),
      (
        "braces", "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm", "high", 0,
        "",
      ),
      (
        "braces", "https://github.com/advisories/GHSA-vfj7-8cjw-p6xm", "high", 2,
        "",
      ),
    ] {
    assert_eq(
      evaluate_dependency_audit(
        code,
        audit_test_report(name~, url~, severity~),
        stderr,
        lock,
      ).status,
      "failed",
    )
  }
}

///|
test "audit keeps informational findings clean and rejects nonzero exit" {
  let lock = audit_test_lock(["braces@3.0.3"])
  assert_eq(evaluate_dependency_audit(0, "{}", "", lock).status, "clean")
  assert_eq(evaluate_dependency_audit(1, "{}", "", lock).status, "failed")
  for severity in ["info", "low", "moderate"] {
    assert_eq(
      evaluate_dependency_audit(0, audit_test_report(severity~), "", lock).status,
      "clean",
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
    assert_eq(evaluate_dependency_audit(0, report, "", lock).status, "failed")
  }
  for
    bad_lock in [
      "", "{}", "{\"packages\":{}}", "{\"packages\":{\"x\":[]}}", "{\"packages\":{\"braces\":[\"braces@3.0.3\"]}}",
    ] {
    assert_eq(evaluate_dependency_audit(0, "{}", "", bad_lock).status, "failed")
  }
  assert_eq(
    dependency_audit_record_identity("@scope/tool@1.2.3"),
    Some(("@scope/tool", "1.2.3")),
  )
}
