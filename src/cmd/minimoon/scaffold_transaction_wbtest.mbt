///|
async test "scaffolding restores manifests and removes new files on cancellation" {
  let root = @fs.tmpdir(prefix="minimoon-scaffold-cancel")
  defer @fs.rmdir(root, recursive=true)
  let directory = join_path(root, "component")
  let manifest = join_path(root, "moon.pkg")
  let config = join_path(root, "miniapp.minimoon.json")
  let binding = join_path(root, "component.mbt")
  write_file(manifest, "old manifest")
  write_file(config, "old config")
  let reached = Ref(false)
  @async.with_task_group(group => {
    let task : @async.Task[Unit?] = group.spawn(() => {
      @async.handle_cancellation(() => {
        scaffold_transaction(
          directory,
          [(manifest, "old manifest"), (config, "old config")],
          [binding],
          () => {
            write_file(manifest, "new manifest")
            write_file(config, "new config")
            write_file(binding, "new binding")
            write_file(join_path(directory, "component.mbt"), "new component")
            reached.val = true
            for ;; {
              @async.pause()
            }
          },
        )
      })
    })
    while !reached.val {
      @async.pause()
    }
    task.cancel()
    assert_true(task.wait() is None)
  })
  assert_eq(@fs.read_file(manifest).text(), "old manifest")
  assert_eq(@fs.read_file(config).text(), "old config")
  assert_false(@fs.exists(binding))
  assert_false(@fs.exists(directory))
}

///|
async test "formatter failures raise through scaffolding recovery before CLI exit" {
  for throws in [false, true] {
    let root = @fs.tmpdir(prefix="minimoon-scaffold-format-failure")
    defer @fs.rmdir(root, recursive=true)
    let directory = join_path(root, "page")
    let manifest = join_path(root, "moon.pkg")
    let binding = join_path(root, "binding.mbt")
    write_file(manifest, "original manifest")
    let failed = try {
      scaffold_transaction(
        directory,
        [(manifest, "original manifest")],
        [binding],
        () => {
          write_file(manifest, "changed manifest")
          write_file(binding, "new binding")
          write_formatted_moon(
            join_path(directory, "page.mbt"),
            "invalid source",
            format=async fn(_) {
              @async.pause()
              if throws {
                raise Failure("formatter launch failed")
              }
              1
            },
          )
        },
      )
      false
    } catch {
      error =>
        error
        .to_string()
        .contains(
          if throws {
            "formatter launch failed"
          } else {
            "moon fmt failed"
          },
        )
    }
    assert_true(failed)
    assert_eq(@fs.read_file(manifest).text(), "original manifest")
    assert_false(@fs.exists(binding))
    assert_false(@fs.exists(directory))
  }
}

///|
async test "successful scaffolding retains its new files and manifest" {
  let root = @fs.tmpdir(prefix="minimoon-scaffold-success")
  defer @fs.rmdir(root, recursive=true)
  let directory = join_path(root, "component")
  let manifest = join_path(root, "moon.pkg")
  let binding = join_path(root, "binding.mbt")
  write_file(manifest, "original manifest")
  scaffold_transaction(
    directory,
    [(manifest, "original manifest")],
    [binding],
    () => {
      write_file(manifest, "new manifest")
      write_file(binding, "new binding")
      write_formatted_moon(join_path(directory, "component.mbt"), "source", format=async fn(
        _,
      ) {
        @async.pause()
        0
      })
    },
  )
  assert_eq(@fs.read_file(manifest).text(), "new manifest")
  assert_eq(@fs.read_file(binding).text(), "new binding")
  assert_eq(
    @fs.read_file(join_path(directory, "component.mbt")).text(),
    "source",
  )
}

///|
async test "failed scaffold recovery reports its error without masking the original failure" {
  let root = @fs.tmpdir(prefix="minimoon-scaffold-recovery-failure")
  defer @fs.rmdir(root, recursive=true)
  let directory = join_path(root, "component")
  let blocked_manifest = join_path(root, "manifest-is-a-directory")
  @fs.mkdir(blocked_manifest)
  let messages : Array[String] = []
  let original = try {
    scaffold_transaction(
      directory,
      [(blocked_manifest, "original manifest")],
      [],
      () => {
        @async.pause()
        raise Failure("original formatter failure")
      },
      report_recovery=message => messages.push(message),
    )
    false
  } catch {
    Failure(message) => message == "original formatter failure"
    _ => false
  }
  assert_true(original)
  assert_eq(messages.length(), 1)
  assert_true(messages[0].contains("scaffold recovery failed"))
  assert_true(messages[0].contains(blocked_manifest))
  assert_false(@fs.exists(directory))
}

///|
async test "failed scaffold recovery preserves cancellation" {
  let root = @fs.tmpdir(prefix="minimoon-scaffold-cancel-recovery-failure")
  defer @fs.rmdir(root, recursive=true)
  let directory = join_path(root, "component")
  let blocked_manifest = join_path(root, "manifest-is-a-directory")
  @fs.mkdir(blocked_manifest)
  let reached = Ref(false)
  let messages : Array[String] = []
  @async.with_task_group(group => {
    let task : @async.Task[Unit?] = group.spawn(() => {
      @async.handle_cancellation(() => {
        scaffold_transaction(
          directory,
          [(blocked_manifest, "original manifest")],
          [],
          () => {
            reached.val = true
            for ;; {
              @async.pause()
            }
          },
          report_recovery=message => messages.push(message),
        )
      })
    })
    while !reached.val {
      @async.pause()
    }
    task.cancel()
    assert_true(task.wait() is None)
  })
  assert_eq(messages.length(), 1)
  assert_true(messages[0].contains(blocked_manifest))
  assert_false(@fs.exists(directory))
}
