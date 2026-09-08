///|
test "runtime command serialization" (b : @bench.T) {
  let commands = [
    mount_context("bench"),
    replace_view_tree("bench", "{\"count\":1}"),
    patch_view_tree(
      "bench", "[{\"op\":\"set\",\"path\":[\"text\"],\"value\":\"1\"}]",
    ),
    dispose_context("bench"),
  ]
  b.bench(fn() { b.keep(runtime_commands_json(commands)) })
}

///|
test "runtime queue batch" (b : @bench.T) {
  b.bench(fn() {
    let queue = RuntimeCommandQueue::new(fn(commands) { b.keep(commands) })
    queue.batch(fn() {
      queue.push(mount_context("bench"))
      queue.push(replace_view_tree("bench", "{}"))
    })
  })
}
