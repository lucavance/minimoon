///|
test "reviewed example and framework byte budgets retain exact inclusive boundaries" {
  assert_eq(registry_archive_hard_limit, 327680)
  assert_eq(registry_archive_reserve, 8192)
  assert_eq(registry_archive_operating_limit, 319488)
  assert_eq(conformance_runtime_limit, 440000)
  assert_eq(conformance_javascript_limit, 480000)
  assert_eq(starter_runtime_limit, 230000)
  assert_eq(starter_javascript_limit, 258000)
  assert_eq(page_host_limit, 18000)
  assert_eq(application_host_limit, 19000)
  for
    limit in [
      registry_archive_operating_limit, conformance_runtime_limit, conformance_javascript_limit,
      starter_runtime_limit, starter_javascript_limit, page_host_limit, application_host_limit,
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

///|
test "application host budget does not relax the no-App host ceiling" {
  assert_eq(shared_host_limit(false), 18000)
  assert_eq(shared_host_limit(true), 19000)
  assert_true(byte_budget_allows(18000, shared_host_limit(false)))
  assert_false(byte_budget_allows(18001, shared_host_limit(false)))
  assert_true(byte_budget_allows(19000, shared_host_limit(true)))
  assert_false(byte_budget_allows(19001, shared_host_limit(true)))
  assert_false(byte_budget_allows(18499, shared_host_limit(false)))
  assert_true(byte_budget_allows(18499, shared_host_limit(true)))
}
