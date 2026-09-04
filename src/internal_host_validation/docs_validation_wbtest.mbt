///|
test "documentation validator covers drift and status failures" {
  // Keep the repository-only source contract visible at its ownership boundary.
  let source = docs_check_source()
  assert_true(source.contains("broken local Markdown link"))
  assert_true(source.contains("section is missing its English translation"))
  assert_true(source.contains("stale source symbol"))
  assert_true(source.contains("Mermaid source drift"))
  assert_true(source.contains("SVG viewBox is missing or invalid"))
  assert_true(source.contains("PNG scale mismatch"))
  assert_true(source.contains("stale or missing diagram assets"))
  assert_true(source.contains("documentation validator self-test passed"))
  assert_true(source.contains("stale documentation token"))
  assert_true(source.contains("verify_report status is not passed"))
  assert_true(source.contains("Developer Tools evidence does not match"))
  assert_true(
    source.contains(
      "release_summary Developer Tools evidence path is not canonical",
    ),
  )
  assert_true(
    source.contains(
      "stale pending status conflicts with the completed release report",
    ),
  )
  assert_true(
    source.contains(
      "stale completed status conflicts with the candidate report",
    ),
  )
  assert_true(source.contains("live state:"))
}
