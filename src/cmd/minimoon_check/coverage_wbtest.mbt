///|
test "coverage package total includes fully covered files omitted from summary" {
  assert_eq(parse_coverage_total("Total: 61/61\n"), (61, 61))
  assert_eq(
    parse_coverage_total("src/query/types.mbt: 4/5\nTotal: 60/61\n"),
    (60, 61),
  )
  assert_eq(parse_coverage_total("Total: 0/0\n"), (0, 0))
}
