///|
test "ready drain uses pending state rather than empty command output" {
  let pending = Ref(3)
  drain_ready(
    [
      {
        name: "pure App state",
        ready: () => pending.val > 0,
        flush: () => {
          pending.val -= 1
          "[]"
        },
      },
    ],
    3,
  )
  assert_eq(pending.val, 0)
}

///|
test "ready drain rejects runaway owners with a bounded diagnostic" {
  let steps = Ref(0)
  let error = try {
    drain_ready(
      [
        {
          name: "page runaway (#2)",
          ready: () => true,
          flush: () => {
            steps.val += 1
            "[]"
          },
        },
      ],
      2,
    )
    "unexpected success"
  } catch {
    Failure(message) => message
    error => error.to_string()
  }
  assert_eq(steps.val, 2)
  assert_true(error.contains("exceeded 2"))
  assert_true(error.contains("page runaway (#2)"))
}

///|
test "ready drain rejects runtime failures but not text mentioning RuntimeError" {
  require_success(
    "[{\"type\":\"ReplaceViewTree\",\"tree\":{\"text\":\"RuntimeError\"}}]", "valid page",
  )
  let error = try {
    require_success(
      "[{\"type\":\"RuntimeError\",\"code\":\"bad_input\",\"message\":\"missing value\"}]",
      "page broken",
    )
    "unexpected success"
  } catch {
    Failure(message) => message
    error => error.to_string()
  }
  assert_true(error.contains("page broken"))
  assert_true(error.contains("bad_input"))
}
