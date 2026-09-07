///|
test "check temporary roots use the checkout or an explicit override" {
  assert_eq(
    check_temporary_base("/data/repo", None),
    "/data/.minimoon-check-tmp",
  )
  assert_eq(
    check_temporary_base("/data/repo", Some("../other temp")),
    "/data/other temp",
  )
  assert_eq(
    check_temporary_base("/data/repo", Some("/data/checks")),
    "/data/checks",
  )
  let rejected = try {
    ignore(check_temporary_base("/data/repo", Some(" ")))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  let environment = check_child_environment("/data/checks/run-one")
  for key in ["TMPDIR", "TMP", "TEMP", "MINIMOON_CHECK_WORKER_TMPDIR"] {
    assert_eq(environment[key], "/data/checks/run-one")
  }
}

///|
async test "check temporary creation isolates concurrent owners" {
  let root = @env.current_dir().unwrap()
  let base = create_check_temporary(
    join(root, "_build/check-tmp-tests"),
    "test",
  )
  errdefer @fs.rmdir(base, recursive=true)
  let directories = @async.all([
    () => create_check_temporary(join(base, "parent with spaces"), "fixture"),
    () => create_check_temporary(join(base, "parent with spaces"), "fixture"),
  ])
  assert_not_eq(directories[0], directories[1])
  for directory in directories {
    assert_true(directory.has_prefix(base + "/parent with spaces/fixture-"))
    assert_eq(@fs.kind(directory), @fs.Directory)
  }
  let rejected = try {
    ignore(create_check_temporary(base, "../escape"))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  @fs.rmdir(base, recursive=true)
}

///|
async test "supervisor cleans success failure crash and launch error without following symlinks" {
  let root = @env.current_dir().unwrap()
  let base = create_check_temporary(
    join(root, "_build/check-tmp-tests"),
    "test",
  )
  errdefer @fs.rmdir(base, recursive=true)
  let runs = join(base, "runs with spaces")
  let outside = join(base, "unrelated")
  @fs.mkdir(outside)
  @fs.write_file(join(outside, "sentinel"), "keep", create_mode=CreateNew)
  let source =
    #|const fs = require('node:fs'), path = require('node:path'), os = require('node:os')
    #|const assert = require('node:assert/strict')
    #|const dir = process.env.MINIMOON_CHECK_WORKER_TMPDIR
    #|assert.equal(os.tmpdir(), dir)
    #|assert.equal(process.env.TMP, dir)
    #|assert.equal(process.env.TEMP, dir)
    #|fs.mkdirSync(path.join(dir, 'leftover'))
    #|fs.writeFileSync(path.join(dir, 'leftover', 'file'), 'temporary')
    #|fs.symlinkSync(process.argv[1], path.join(dir, 'outside'), 'dir')
    #|if (process.argv[2] === 'kill') process.kill(process.pid, 'SIGKILL')
    #|else process.exit(Number(process.argv[2]))
  for mode in ["0", "7", "kill"] {
    let code = supervised_check_process(root, runs, "bun", [
      "-e", source, outside, mode,
    ])
    if mode == "0" {
      assert_eq(code, 0)
    } else if mode == "7" {
      assert_eq(code, 7)
    } else {
      assert_not_eq(code, 0)
    }
    assert_eq(@fs.readdir(runs).length(), 0)
    assert_eq(@fs.read_file(join(outside, "sentinel")).text(), "keep")
  }
  let failed = try {
    ignore(
      supervised_check_process(root, runs, join(base, "missing-executable"), []),
    )
    false
  } catch {
    _ => true
  }
  assert_true(failed)
  assert_eq(@fs.readdir(runs).length(), 0)
  assert_eq(@fs.read_file(join(outside, "sentinel")).text(), "keep")
  @fs.rmdir(base, recursive=true)
}
