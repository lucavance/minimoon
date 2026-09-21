///|
async test "compilation cancellation removes temporary packages and build output" {
  let root = @fs.tmpdir(prefix="minimoon-compilation-cancel")
  defer @fs.rmdir(root, recursive=true)
  let package_dir = join(root, "src/minimoon_probe")
  let target = join(root, ".minimoon-tmp")
  let reached = Ref(false)
  @async.with_task_group(group => {
    let task : @async.Task[Unit?] = group.spawn(() => {
      @async.handle_cancellation(() => {
        defer cleanup_compilation_directories([package_dir, target])
        write(join(package_dir, "main.mbt"), "temporary package")
        write(join(target, "output"), "temporary output")
        reached.val = true
        for ;; {
          @async.pause()
        }
      })
    })
    while !reached.val {
      @async.pause()
    }
    task.cancel()
    assert_true(task.wait() is None)
  })
  assert_false(@fs.exists(package_dir))
  assert_false(@fs.exists(target))
}
