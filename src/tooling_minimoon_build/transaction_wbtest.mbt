///|
async test "every promotion failure restores the complete previous output" {
  for fail_at in 0..<6 {
    let root = @fs.tmpdir(prefix="minimoon-promote-rollback")
    defer @fs.rmdir(root, recursive=true)
    let live = join(root, "live")
    let stage = join(root, "stage")
    write(join(live, "dist/app.wxss"), "old css")
    write(join(live, "dist/nested/page.js"), "old page")
    write(join(live, "dist/project.private.config.json"), "private bytes")
    write(join(live, "styles/app.wxss"), "old source css")
    write(join(live, "generated/manifest.json"), "old manifest")
    write(join(live, "generated/devtools.evidence.json"), "local evidence")
    write(join(stage, "dist/app.wxss"), "new css")
    write(join(stage, "source.wxss"), "new source css")
    write(join(stage, "manifest.json"), "new manifest")
    let entries = [
      { staged: join(stage, "dist"), target: join(live, "dist"), },
      {
        staged: join(stage, "source.wxss"),
        target: join(live, "styles/app.wxss"),
      },
      {
        staged: join(stage, "manifest.json"),
        target: join(live, "generated/manifest.json"),
      },
    ]
    let calls = Ref(0)
    let failed = try {
      promote_build_outputs(entries, join(root, "backup"), rename_output=async fn(
        source,
        target,
      ) {
        let number = calls.val
        calls.val += 1
        if number == fail_at {
          raise Failure("injected promotion failure")
        }
        @fs.rename(source, target)
      })
      false
    } catch {
      error => {
        assert_true(error.to_string().contains("previous output restored"))
        true
      }
    }
    assert_true(failed)
    assert_eq(@fs.read_file(join(live, "dist/app.wxss")).text(), "old css")
    assert_eq(
      @fs.read_file(join(live, "dist/nested/page.js")).text(),
      "old page",
    )
    assert_eq(
      @fs.read_file(join(live, "dist/project.private.config.json")).text(),
      "private bytes",
    )
    assert_eq(
      @fs.read_file(join(live, "styles/app.wxss")).text(),
      "old source css",
    )
    assert_eq(
      @fs.read_file(join(live, "generated/manifest.json")).text(),
      "old manifest",
    )
    assert_eq(
      @fs.read_file(join(live, "generated/devtools.evidence.json")).text(),
      "local evidence",
    )
  }
}

///|
async test "failed first promotion removes installed outputs and newly created parents" {
  let root = @fs.tmpdir(prefix="minimoon-first-promote")
  defer @fs.rmdir(root, recursive=true)
  write(join(root, "stage/dist/app.js"), "new app")
  write(join(root, "stage/source.wxss"), "new css")
  let entries = [
    { staged: join(root, "stage/dist"), target: join(root, "new/output/dist"), },
    {
      staged: join(root, "stage/source.wxss"),
      target: join(root, "new/styles/app.wxss"),
    },
  ]
  let calls = Ref(0)
  let failed = try {
    promote_build_outputs(entries, join(root, "backup"), rename_output=async fn(
      source,
      target,
    ) {
      calls.val += 1
      if calls.val == 2 {
        raise Failure("injected first-build failure")
      }
      @fs.rename(source, target)
    })
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  assert_false(@fs.exists(join(root, "new")))
}

///|
async test "recovery failure identifies and retains the unrestored backup" {
  let root = @fs.tmpdir(prefix="minimoon-recovery-failure")
  defer @fs.rmdir(root, recursive=true)
  write(join(root, "old.wxss"), "old bytes")
  write(join(root, "new.wxss"), "new bytes")
  let backup = join(root, "backup")
  let failed = try {
    promote_build_outputs(
      [{ staged: join(root, "new.wxss"), target: join(root, "old.wxss"), }],
      backup,
      rename_output=async fn(source, target) {
        if source != join(root, "old.wxss") {
          raise Failure("unavailable destination")
        }
        @fs.rename(source, target)
      },
    )
    false
  } catch {
    BuildRecoveryError(message) => {
      assert_true(message.contains(backup))
      true
    }
    _ => false
  }
  assert_true(failed)
  assert_eq(@fs.read_file(join(backup, "0")).text(), "old bytes")
}

///|
async test "successful promotion removes obsolete dist files and leaves unowned metadata alone" {
  let root = @fs.tmpdir(prefix="minimoon-promote-success")
  defer @fs.rmdir(root, recursive=true)
  write(join(root, "dist/obsolete.js"), "obsolete")
  write(join(root, "generated/devtools.evidence.json"), "evidence")
  write(join(root, "generated/verify_report.json"), "old verification")
  write(join(root, "stage/dist/app.js"), "new app")
  write(join(root, "stage/dist/project.private.config.json"), "private bytes")
  write(join(root, "stage/manifest.json"), "new manifest")
  promote_build_outputs(
    [
      { staged: join(root, "stage/dist"), target: join(root, "dist"), },
      {
        staged: join(root, "stage/manifest.json"),
        target: join(root, "generated/manifest.json"),
      },
    ],
    join(root, "backup"),
  )
  assert_false(@fs.exists(join(root, "dist/obsolete.js")))
  assert_eq(
    @fs.read_file(join(root, "dist/project.private.config.json")).text(),
    "private bytes",
  )
  assert_eq(
    @fs.read_file(join(root, "generated/devtools.evidence.json")).text(),
    "evidence",
  )
  assert_eq(
    @fs.read_file(join(root, "generated/verify_report.json")).text(),
    "old verification",
  )
}

///|
test "source WXSS inside dist is committed once and metadata selection excludes local evidence" {
  let generated = Json::object({
    "fixtureDirAbs": Json::string("/app"),
    "distDirAbs": Json::string("/stage/dist"),
    "distDirFinalAbs": Json::string("/app/output"),
    "sourceWxssAbs": Json::string("/stage/dist/app.wxss"),
    "sourceWxssFinalAbs": Json::string("/app/output/app.wxss"),
    "generatedDirAbs": Json::string("/stage/generated"),
  })
  let entries = build_replacements(generated)
  assert_eq(entries.length(), 6)
  assert_eq(entries[0].target, "/app/output")
  assert_false(
    entries.any(entry => entry.target.has_suffix("devtools.evidence.json")),
  )
  assert_false(
    entries.any(entry => entry.target.has_suffix("verify_report.json")),
  )
}

///|
async test "cancellation at every promotion boundary completes one consistent commit" {
  for cancel_at in 0..<4 {
    let root = @fs.tmpdir(prefix="minimoon-promote-cancel")
    defer @fs.rmdir(root, recursive=true)
    write(join(root, "live/dist/app.js"), "old app")
    write(join(root, "live/dist/project.private.config.json"), "private bytes")
    write(join(root, "live/generated/manifest.json"), "old manifest")
    write(join(root, "live/generated/devtools.evidence.json"), "local evidence")
    write(join(root, "stage/dist/app.js"), "new app")
    write(join(root, "stage/dist/project.private.config.json"), "private bytes")
    write(join(root, "stage/manifest.json"), "new manifest")
    let reached = Ref(false)
    let proceed = Ref(false)
    let calls = Ref(0)
    @async.with_task_group(group => {
      let task : @async.Task[Unit?] = group.spawn(() => {
        @async.handle_cancellation(() => {
          promote_build_outputs(
            [
              {
                staged: join(root, "stage/dist"),
                target: join(root, "live/dist"),
              },
              {
                staged: join(root, "stage/manifest.json"),
                target: join(root, "live/generated/manifest.json"),
              },
            ],
            join(root, "backup"),
            rename_output=async fn(source, target) {
              let index = calls.val
              calls.val += 1
              if index == cancel_at {
                reached.val = true
                while !proceed.val {
                  @async.pause()
                }
              }
              @fs.rename(source, target)
            },
          )
          @async.pause()
        })
      })
      while !reached.val {
        @async.pause()
      }
      task.cancel()
      proceed.val = true
      assert_true(task.wait() is None)
    })
    assert_eq(@fs.read_file(join(root, "live/dist/app.js")).text(), "new app")
    assert_eq(
      @fs.read_file(join(root, "live/generated/manifest.json")).text(),
      "new manifest",
    )
    assert_eq(
      @fs.read_file(join(root, "live/dist/project.private.config.json")).text(),
      "private bytes",
    )
    assert_eq(
      @fs.read_file(join(root, "live/generated/devtools.evidence.json")).text(),
      "local evidence",
    )
  }
}

///|
async test "cancellation during a failed promotion still restores the previous output" {
  let root = @fs.tmpdir(prefix="minimoon-promote-cancel-rollback")
  defer @fs.rmdir(root, recursive=true)
  write(join(root, "old.wxss"), "old bytes")
  write(join(root, "new.wxss"), "new bytes")
  let reached = Ref(false)
  let proceed = Ref(false)
  let calls = Ref(0)
  @async.with_task_group(group => {
    let task = group.spawn(() => {
      try {
        promote_build_outputs(
          [{ staged: join(root, "new.wxss"), target: join(root, "old.wxss"), }],
          join(root, "backup"),
          rename_output=async fn(source, target) {
            calls.val += 1
            if calls.val == 2 {
              reached.val = true
              while !proceed.val {
                @async.pause()
              }
              raise Failure("injected failure after cancellation")
            }
            @fs.rename(source, target)
          },
        )
        false
      } catch {
        error => error.to_string().contains("previous output restored")
      }
    })
    while !reached.val {
      @async.pause()
    }
    task.cancel()
    proceed.val = true
    assert_true(task.wait())
  })
  assert_eq(@fs.read_file(join(root, "old.wxss")).text(), "old bytes")
}

///|
async test "cancelled staging is cleaned before any live output promotion" {
  let root = @fs.tmpdir(prefix="minimoon-stage-cancel")
  defer @fs.rmdir(root, recursive=true)
  write(join(root, "live/app.js"), "old app")
  let stage = join(root, "transaction")
  let reached = Ref(false)
  @async.with_task_group(group => {
    let task : @async.Task[Unit?] = group.spawn(() => {
      @async.handle_cancellation(() => {
        errdefer cleanup_build_transaction(stage)
        write(join(stage, "next/app.js"), "new app")
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
  assert_false(@fs.exists(stage))
  assert_eq(@fs.read_file(join(root, "live/app.js")).text(), "old app")
}

///|
async test "cancelled promotion with failed recovery keeps its unrestored backup" {
  let root = @fs.tmpdir(prefix="minimoon-cancel-recovery-failure")
  defer @fs.rmdir(root, recursive=true)
  let transaction = join(root, "transaction")
  let backup = join(transaction, "backup")
  write(join(root, "old.wxss"), "old bytes")
  write(join(transaction, "new.wxss"), "new bytes")
  let reached = Ref(false)
  let proceed = Ref(false)
  @async.with_task_group(group => {
    let task = group.spawn(() => {
      let preserve_backup = Ref(false)
      errdefer (if !preserve_backup.val {
        cleanup_build_transaction(transaction)
      })
      promote_build_outputs(
        [
          {
            staged: join(transaction, "new.wxss"),
            target: join(root, "old.wxss"),
          },
        ],
        backup,
        rename_output=async fn(source, target) {
          if source != join(root, "old.wxss") {
            reached.val = true
            while !proceed.val {
              @async.pause()
            }
            raise Failure("unavailable destination after cancellation")
          }
          @fs.rename(source, target)
        },
      ) catch {
        BuildRecoveryError(_) as error => {
          preserve_backup.val = true
          raise error
        }
        error => raise error
      }
    })
    while !reached.val {
      @async.pause()
    }
    task.cancel()
    proceed.val = true
    let failed = try {
      task.wait()
      false
    } catch {
      BuildRecoveryError(message) => message.contains(backup)
      _ => false
    }
    assert_true(failed)
  }) catch {
    BuildRecoveryError(_) => ()
    error => raise error
  }
  assert_eq(@fs.read_file(join(backup, "0")).text(), "old bytes")
}
