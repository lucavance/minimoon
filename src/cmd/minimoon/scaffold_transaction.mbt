///|
// Register recovery before the first write: cancellation can arrive after an
// asynchronous filesystem operation has changed the disk but before it returns.
async fn scaffold_transaction(
  directory : String,
  restored_files : Array[(String, String)],
  created_files : Array[String],
  operation : async () -> Unit,
  report_recovery? : (String) -> Unit = println,
) -> Unit {
  errdefer @async.protect_from_cancel(() => {
    let failures : Array[String] = []
    for (file, original) in restored_files {
      write_file(file, original) catch {
        error => failures.push("could not restore " + file + ": \{error}")
      }
    }
    for file in created_files {
      try {
        if @fs.exists(file) {
          @fs.remove(file)
        }
      } catch {
        error => failures.push("could not remove " + file + ": \{error}")
      }
    }
    try {
      if @fs.exists(directory) {
        @fs.rmdir(directory, recursive=true)
      }
    } catch {
      error => failures.push("could not remove " + directory + ": \{error}")
    }
    if !failures.is_empty() {
      // Retain the original failure or cancellation. Recovery diagnostics must
      // not replace the reason why the scaffold transaction was interrupted.
      report_recovery(
        "minimoon: scaffold recovery failed:\n" + failures.join("\n"),
      )
    }
  })
  @fs.mkdir(directory, permission=0o755, recursive=true)
  operation()
}
