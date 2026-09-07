///|
// Repository checks must not depend on the system /tmp quota. Only fresh,
// exclusively created children are owned by a run; never sweep the parent.
fn check_temporary_base(root : String, configured : String?) -> String raise {
  match configured {
    // A sibling stays on the checkout's volume without inheriting moon.work.
    None => join(root, "../.minimoon-check-tmp")
    Some(value) => {
      guard value.trim() != "" else {
        raise Failure("MINIMOON_CHECK_TMPDIR must not be empty")
      }
      if @path.Path(value).is_absolute() {
        @path.Path(value).normalize().to_string()
      } else {
        join(root, value)
      }
    }
  }
}

///|
async fn create_check_temporary(base : String, prefix : String) -> String {
  guard prefix != "" &&
    prefix.iter().all(c => (c >= 'a' && c <= 'z') || c == '-') else {
    raise Failure("invalid check temporary directory prefix")
  }
  // mkdir is exclusive even for a random-name collision. Parent creation may
  // race with another independent check process, which is harmless.
  @fs.mkdir(base, recursive=true, permission=0o700) catch {
    err => if !@fs.exists(base) || @fs.kind(base) != @fs.Directory { raise err }
  }
  let parent = @fs.realpath(base)
  guard @env.rand(16) is Some(bytes) else {
    raise Failure("randomness is unavailable for check temporary directory")
  }
  let token = bytes
    .iter()
    .map(byte => {
      let hex = byte.to_int().to_string(radix=16)
      if byte.to_int() < 16 {
        "0" + hex
      } else {
        hex
      }
    })
    .to_array()
    .join("")
  let directory = join(parent, prefix + "-" + token)
  @fs.mkdir(directory, permission=0o700)
  directory
}

///|
async fn check_temporary(prefix : String) -> String {
  let base = @env.get_env_var("MINIMOON_CHECK_WORKER_TMPDIR").unwrap_or_else(() => {
    abort("check temporary directory requires a supervised worker")
  })
  create_check_temporary(base, prefix)
}

///|
fn check_child_environment(directory : String) -> Map[String, String] {
  {
    "MINIMOON_CHECK_WORKER_TMPDIR": directory,
    "TMPDIR": directory,
    "TMP": directory,
    "TEMP": directory,
  }
}

///|
// A worker abort is a process exit, not a catchable MoonBit error. Keep its
// lifetime and cleanup in a separate parent process, including launch errors.
async fn supervised_check_process(
  root : String,
  base : String,
  command : String,
  args : Array[String],
) -> Int {
  let directory = create_check_temporary(base, "run")
  println("Minimoon check temporary directory: " + directory)
  errdefer (if @fs.exists(directory) { @fs.rmdir(directory, recursive=true) })
  let code = @process.run(
    command,
    args,
    cwd=root,
    extra_env=check_child_environment(directory),
  )
  @fs.rmdir(directory, recursive=true)
  code
}
