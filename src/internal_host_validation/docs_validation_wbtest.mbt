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
  assert_true(source.contains("stale documentation version"))
  assert_true(source.contains("stale current MiniApp configuration schema"))
  assert_true(source.contains("unqualified page-only authoring claim"))
  assert_true(source.contains("contract without v"))
  assert_true(source.contains("contract schema colon"))
  assert_true(source.contains("inverse runtime requirement"))
  assert_true(source.contains("published history"))
  assert_true(source.contains("legacy schema explanation"))
  assert_true(source.contains("same-page legacy and current versions"))
  assert_true(source.contains("history does not hide current config drift"))
  assert_true(source.contains("nested historical documentation marker"))
  assert_true(source.contains("unclosed historical documentation marker"))
  assert_true(source.contains("unmatched historical documentation end marker"))
  assert_true(source.contains("malformed historical documentation marker"))
  assert_true(source.contains("verify_report status is not passed"))
  assert_true(source.contains("Developer Tools evidence does not match"))
  assert_true(
    source.contains(
      "release_summary Developer Tools evidence path is not canonical",
    ),
  )
  assert_true(
    source.contains(
      "active status must state that real-host evidence is local and Git-ignored",
    ),
  )
  assert_true(
    source.contains(
      "active status must not publish transient real-host completion",
    ),
  )
  assert_true(source.contains("live state:"))
  assert_true(source.contains("ui/examples/showcase"))
  assert_true(source.contains("moduleVersionProblems"))
  assert_true(source.contains("manifest protocol version differs"))
  assert_true(
    source.contains(
      "candidate release_summary must keep Developer Tools pending",
    ),
  )
  assert_true(source.contains("local Markdown link escapes archive"))
}
