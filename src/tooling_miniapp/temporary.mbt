///|
// Cleanup must include its existence checks in the cancellation shield. The
// filesystem removals alone are nocancel; inspecting the directory is not.
async fn cleanup_compilation_directories(
  directories : Array[String],
) -> Unit nocancel {
  @async.protect_from_cancel(() => {
    for directory in directories {
      try {
        if @fs.exists(directory) {
          @fs.rmdir(directory, recursive=true)
        }
      } catch {
        error =>
          println(
            "minimoon: could not remove compilation temporary directory " +
            directory +
            ": \{error}",
          )
      }
    }
  })
}
