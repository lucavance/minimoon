///|
test "URL policy rejects unsafe schemes whitespace and network paths after rewriting" {
  for
    url in [
      "javascript:alert(1)", "JaVaScRiPt:alert", "data:image/svg+xml,a", "vbscript:bad",
      "//evil.test", "https://ok.test\n.bad", "\\evil", " https://example.com",
    ] {
    assert_false(safe_url(url, false))
    assert_false(safe_url(url, true))
  }
  for
    url in [
      "https://example.com", "/assets/a.svg", "./image.png", "../image.png",
    ] {
    assert_true(safe_url(url, false))
    assert_true(safe_url(url, true))
  }
  assert_true(safe_url("#heading", false))
  assert_false(safe_url("#heading", true))
  assert_true(safe_url("mailto:user@example.com", false))
  assert_false(safe_url("mailto:user@example.com", true))
  assert_true(anchor_id("one", "a-b") != anchor_id("one", "a_b"))
  assert_true(anchor_id("one", "fn-n") != footnote_id("one", "n"))
}
