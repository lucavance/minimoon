///|
test "slider normalization snaps sorts and respects minimum separation" {
  let spec = slider_spec(min=-20, max=100, step=5, min_steps_between=2)
  assert_eq(spec.normalize([99, -99, 7]), [-20, 5, 100])
  assert_eq(spec.normalize([10, 10, 10]), [10, 20, 30])
  assert_eq(spec.normalize([95, 95, 100]), [80, 90, 100])
  assert_eq(spec.normalize([]), [-20])
  assert_eq(spec.update([10, 30], 0, 99.0), [20, 30])
  assert_eq(spec.update([10, 30], 1, -99.0), [10, 20])
  assert_eq(spec.update([10, 30], 7, 80.0), [10, 30])
  assert_eq(spec.nearest([10, 30], 29.0), 1)
  assert_eq(spec.fraction(40), 0.5)
}

///|
test "slider non-divisible ranges clamp to the last valid step" {
  let spec = slider_spec(max=10, step=3)
  assert_eq(spec.snap(10.0), 9)
  assert_eq(spec.normalize([10, 2]), [3, 9])
  assert_eq(spec.update([0, 9], 0, 4.0), [3, 9])
}
