///|
test "explicit trait methods preserve the historical exact API" {
  let baseline = "pub(all) enum Choice {\n  Yes\n  No\n} derive(Eq)\n"
  let methods = "pub fn Choice::equal(Self, Self) -> Bool\npub fn Choice::not_equal(Self, Self) -> Bool\n"
  let current = baseline + methods
  assert_true(
    api_explicit_method_violations(baseline, current, methods, true).is_empty(),
  )
  for
    invalid in [
      baseline,
      current + "pub fn Choice::new_api(Self) -> Unit\n",
      current + "pub fn Choice::equal(Self, Self) -> Bool\n",
      baseline + "pub fn Choice::equal(Self, Self) -> Int\n",
      "pub(all) enum Choice {\n  Yes\n} derive(Eq)\n" + methods,
    ] {
    assert_true(
      !api_explicit_method_violations(baseline, invalid, methods, true).is_empty(),
    )
  }
}

///|
test "optional APIs retain implicit methods while allowing ordinary additions" {
  let baseline = "pub type Stable\n"
  let methods = "pub fn Stable::to_string(Self) -> String\n"
  let current = baseline + methods + "pub fn added() -> Unit\n"
  assert_true(
    api_explicit_method_violations(baseline, current, methods, false).is_empty(),
  )
  assert_true(
    !api_explicit_method_violations(
      baseline,
      baseline + "pub fn added() -> Unit\n",
      methods,
      false,
    ).is_empty(),
  )
}

///|
test "explicit method review cannot hide ordinary declarations or duplicates" {
  let baseline = "pub type Stable\n"
  let declaration = "pub fn Stable::to_string(Self) -> String\n"
  for invalid_review in [baseline, declaration + declaration] {
    assert_true(
      !api_explicit_method_violations(
        baseline,
        baseline + declaration,
        invalid_review,
        true,
      ).is_empty(),
    )
  }
}
