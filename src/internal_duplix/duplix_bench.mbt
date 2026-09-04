///|
fn exercise_bounded_scopes(count : Int) -> Int {
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
fn bench_bounded_scopes(b : @bench.T, count : Int) -> Unit {
  b.bench(fn() { b.keep(exercise_bounded_scopes(count)) })
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
