///|
test "reviewed HTTP byte budgets retain exact inclusive boundaries" {
  assert_eq(registry_archive_hard_limit, 256000)
  assert_eq(registry_archive_reserve, 8192)
  assert_eq(registry_archive_operating_limit, 247808)
  assert_eq(conformance_runtime_limit, 360000)
  assert_eq(conformance_javascript_limit, 424000)
  for
    limit in [
      registry_archive_operating_limit, conformance_runtime_limit, conformance_javascript_limit,
    ] {
    assert_true(byte_budget_allows(0, limit))
    assert_true(byte_budget_allows(limit - 1, limit))
    assert_true(byte_budget_allows(limit, limit))
    assert_false(byte_budget_allows(limit + 1, limit))
    assert_false(byte_budget_allows(-1, limit))
  }
  assert_false(
    byte_budget_allows(
      registry_archive_hard_limit, registry_archive_operating_limit,
    ),
  )
}
