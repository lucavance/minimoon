///|
fn exercise_bounded_scopes(count : Int32) -> Int32 {
  let root = RootScope::new()
  let disposed = Ref(0)
  let (output, set_source) = root.run(fn() {
    let (source, set_source) = input(0)
    let output = source.enumerate_bounded_by(
      capacity=8,
      (initial, current) => {
        on_cleanup(fn() { disposed.val += 1 })
        current.map(value => initial + value)
      },
      by=value => value.to_string(),
    )
    (output, set_source)
  })
  let _ = root.run(fn() { output.read() })
  for tag = 1; tag < count; tag = tag + 1 {
    set_source(tag)
    let _ = root.run(fn() { output.read() })
  }
  root.dispose()
  disposed.val
}

///|
fn bench_bounded_scopes(b : @bench.T, count : Int32) -> Unit {
  b.bench(fn() { b.keep(exercise_bounded_scopes(count)) })
}

///|
fn exercise_sibling_recomputation(count : Int32) -> Int32 {
  let root = RootScope::new()
  let right_computes = Ref(0)
  let (output, set_left) = root.run(fn() {
    let (left, set_left) = input(0)
    let (right, _set_right) = input(1)
    let left_value = left.map(value => value + 1)
    let right_value = right.map(value => {
      right_computes.val += 1
      value + 1
    })
    let output = left_value.map2(right_value, (left, right) => left + right)
    (output, set_left)
  })
  let _ = root.run(fn() { output.read() })
  for value = 1; value <= count; value = value + 1 {
    set_left(value)
    let _ = root.run(fn() { output.read() })
  }
  let result = right_computes.val
  root.dispose()
  result
}

///|
fn bench_sibling_recomputation(b : @bench.T, count : Int32) -> Unit {
  b.bench(fn() { b.keep(exercise_sibling_recomputation(count)) })
}

///|
test "bounded scope cycle 100 tags" (b : @bench.T) {
  bench_bounded_scopes(b, 100)
}

///|
test "bounded scope cycle 500 tags" (b : @bench.T) {
  bench_bounded_scopes(b, 500)
}

///|
test "bounded scope cycle 2000 tags" (b : @bench.T) {
  bench_bounded_scopes(b, 2000)
}

///|
test "unrelated sibling recomputation 100 updates" (b : @bench.T) {
  bench_sibling_recomputation(b, 100)
}

///|
test "unrelated sibling recomputation 500 updates" (b : @bench.T) {
  bench_sibling_recomputation(b, 500)
}

///|
test "unrelated sibling recomputation 2000 updates" (b : @bench.T) {
  bench_sibling_recomputation(b, 2000)
}
