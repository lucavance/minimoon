///|
test "reviewed authoring byte budgets retain exact inclusive boundaries" {
  assert_eq(registry_archive_hard_limit, 307200)
  assert_eq(registry_archive_reserve, 8192)
  assert_eq(registry_archive_operating_limit, 299008)
  assert_eq(conformance_runtime_limit, 400000)
  assert_eq(conformance_javascript_limit, 453000)
  assert_eq(page_host_limit, 15000)
  assert_eq(application_host_limit, 16000)
  for
    limit in [
      registry_archive_operating_limit, conformance_runtime_limit, conformance_javascript_limit,
      page_host_limit, application_host_limit,
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
  assert_eq(shared_host_limit(false), 15000)
  assert_eq(shared_host_limit(true), 16000)
  assert_true(byte_budget_allows(15000, shared_host_limit(false)))
  assert_false(byte_budget_allows(15001, shared_host_limit(false)))
  assert_true(byte_budget_allows(16000, shared_host_limit(true)))
  assert_false(byte_budget_allows(16001, shared_host_limit(true)))
  assert_false(byte_budget_allows(15499, shared_host_limit(false)))
  assert_true(byte_budget_allows(15499, shared_host_limit(true)))
}
