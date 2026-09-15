///|
priv struct BuildReplacement {
  staged : String
  target : String
}

///|
priv struct BuildPromotion {
  replacement : BuildReplacement
  backup : String
  mut backed_up : Bool
  mut installed : Bool
}

///|
priv suberror BuildRecoveryError {
  BuildRecoveryError(String)
}

///|
async fn new_build_transaction(base : String) -> String {
  guard @env.rand(16) is Some(bytes) else {
    raise Failure("randomness is unavailable for build staging")
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
  let directory = join(base, token)
  @fs.mkdir(directory, permission=0o700)
  directory
}

///|
fn build_replacements(generated : Json) -> Array[BuildReplacement] {
  let app_root = string(generated, "fixtureDirAbs")
  let dist = string(generated, "distDirFinalAbs")
  let source = string(generated, "sourceWxssFinalAbs")
  let entries = [{ staged: string(generated, "distDirAbs"), target: dist, }]
  if !source.has_prefix(dist + "/") {
    entries.push({ staged: string(generated, "sourceWxssAbs"), target: source, })
  }
  for
    name in [
      "manifest.json", "expected_set_data.json", "smoke_checklist.json", "release_summary.json",
      "diagnostics.json",
    ] {
    entries.push({
      staged: join(string(generated, "generatedDirAbs"), name),
      target: join(app_root, "generated/" + name),
    })
  }
  entries
}

///|
async fn remove_build_output(path : String) -> Unit {
  if @fs.exists(path) {
    if @fs.kind(path, follow_symlink=false) == @fs.Directory {
      @fs.rmdir(path, recursive=true)
    } else {
      @fs.remove(path)
    }
  }
}

///|
async fn build_rename(source : String, target : String) -> Unit {
  @fs.rename(source, target)
}

///|
// The injected move is private to this helper and permits deterministic tests
// of each promotion/rollback edge without production failure switches.
async fn promote_build_outputs(
  entries : Array[BuildReplacement],
  backup_root : String,
  rename_output? : async (String, String) -> Unit = build_rename,
) -> Unit {
  @fs.mkdir(backup_root, permission=0o700, recursive=true)
  let promotions : Array[BuildPromotion] = []
  let created_parents : Array[String] = []
  let outcome = try {
    for index, replacement in entries {
      let state = {
        replacement,
        backup: join(backup_root, index.to_string()),
        backed_up: false,
        installed: false,
      }
      promotions.push(state)
      let mut parent = Path::dirname(replacement.target).to_string()
      let missing : Array[String] = []
      while !@fs.exists(parent) {
        missing.push(parent)
        parent = Path::dirname(parent).to_string()
      }
      for offset in 0..<missing.length() {
        let directory = missing[missing.length() - offset - 1]
        @fs.mkdir(directory, permission=0o755)
        created_parents.push(directory)
      }
      if @fs.exists(replacement.target) {
        rename_output(replacement.target, state.backup)
        state.backed_up = true
      }
      rename_output(replacement.staged, replacement.target)
      state.installed = true
    }
    None
  } catch {
    error => Some(error)
  }
  if outcome is Some(error) {
    let recovery_errors : Array[String] = []
    for offset in 0..<promotions.length() {
      let state = promotions[promotions.length() - offset - 1]
      try {
        if state.installed {
          remove_build_output(state.replacement.target)
        }
        if state.backed_up {
          rename_output(state.backup, state.replacement.target)
        }
      } catch {
        recovery_error => recovery_errors.push("\{recovery_error}")
      }
    }
    for offset in 0..<created_parents.length() {
      let directory = created_parents[created_parents.length() - offset - 1]
      try {
        if @fs.exists(directory) &&
          @fs.readdir(directory, include_hidden=true).is_empty() {
          @fs.rmdir(directory)
        }
      } catch {
        recovery_error => recovery_errors.push("\{recovery_error}")
      }
    }
    if !recovery_errors.is_empty() {
      raise BuildRecoveryError(
        "build output recovery failed; keep backups at " +
        backup_root +
        "\noriginal error: \{error}\nrecovery: " +
        recovery_errors.join("\n"),
      )
    }
    raise Failure(
      "build output replacement failed; previous output restored\n\{error}",
    )
  }
}

///|
async fn cleanup_build_transaction(directory : String) -> Unit {
  remove_build_output(directory) catch {
    error =>
      println(
        "minimoon: could not remove build temporary directory " +
        directory +
        ": \{error}",
      )
  }
}
