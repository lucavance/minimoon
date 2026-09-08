///|
// Copy the source tree, not the publication allowlist. In particular, retain
// docs, examples, and tests so the real .moonignore must exclude them.
fn ui_packaging_local_path(name : String) -> Bool {
  [
    ".git", "_build", ".mooncakes", "node_modules", "dist", ".tmp", ".minimoon-tmp",
    ".bin", ".vscode", ".moonagent", ".DS_Store", ".env", "project.private.config.json",
    "devtools.evidence.json",
  ].contains(name) ||
  name.has_prefix(".env.") ||
  name.has_suffix(".log") ||
  name.has_suffix(".pem") ||
  name.has_suffix(".key")
}

///|
async fn copy_ui_packaging_tree(source : String, destination : String) -> Unit {
  @fs.mkdir(destination, permission=0o700)
  for name in @fs.readdir(source, include_hidden=true, sort=true) {
    if ui_packaging_local_path(name) {
      continue
    }
    let from = join(source, name)
    let to = join(destination, name)
    match @fs.kind(from, follow_symlink=false) {
      @fs.Directory => copy_ui_packaging_tree(from, to)
      @fs.Regular =>
        @fs.write_file(
          to,
          @fs.read_file(from),
          create_mode=CreateNew,
          permission=0o644,
        )
      _ => raise Failure("UI packaging source must be a regular file: " + from)
    }
  }
}

///|
async fn prepare_ui_packaging_stage(
  source : String,
  core : String,
  stage : String,
) -> String {
  guard @fs.readdir(stage, include_hidden=true).is_empty() else {
    raise Failure("UI packaging requires a fresh temporary directory")
  }
  // Moon's package walker inherits ignore rules up to the nearest Git root.
  // A new temporary Git root also isolates an explicitly repository-local
  // MINIMOON_CHECK_TMPDIR; never create .git in the real UI module.
  let (code, stdout, stderr) = @process.collect_output("git", [
    "init", "--quiet", stage,
  ])
  guard code == 0 else {
    raise Failure(
      "UI packaging isolation failed: " + stdout.text() + stderr.text(),
    )
  }
  let staged_ui = join(stage, "ui")
  copy_ui_packaging_tree(source, staged_ui)
  @fs.write_file(
    join(stage, "moon.work"),
    "members = [" + Json::string(core).stringify() + ", \"ui\"]\n",
    create_mode=CreateNew,
    permission=0o644,
  )
  let dependencies = join(core, ".mooncakes")
  if @fs.exists(dependencies) {
    @fs.symlink(target=dependencies, join(stage, ".mooncakes"))
  }
  staged_ui
}

///|
fn ui_packaging_archive_path(listing : String, stage : String) -> String raise {
  let archives : Array[String] = []
  for raw_line in listing.split("\n") {
    let line = raw_line.trim()
    if line.has_prefix("Package to ") {
      archives.push(line["Package to ".length():].to_owned())
    }
  }
  guard archives.length() == 1 else {
    raise Failure("UI packaging must report exactly one archive")
  }
  let archive = archives[0]
  guard @path.Path(archive).is_absolute() &&
    Path::dirname(archive).normalize().to_string() ==
    join(stage, "_build/publish") &&
    archive.has_suffix(".zip") else {
    raise Failure(
      "UI packaging archive is outside its isolated stage: " + archive,
    )
  }
  archive
}

///|
async fn package_staged_ui(
  stage : String,
  staged_ui : String,
) -> (String, Array[String]) {
  let (code, stdout, stderr) = @process.collect_output(
    "moon",
    ["package", "--frozen", "--list", "--target-dir", join(stage, "_build")],
    cwd=staged_ui,
  )
  let listing = stdout.text() + "\n" + stderr.text()
  guard code == 0 else {
    raise Failure("UI registry packaging failed:\n" + listing)
  }
  let archive = ui_packaging_archive_path(listing, stage)
  let paths = registry_package_paths(listing)
  guard !paths.is_empty() else {
    raise Failure("UI registry package path list is empty")
  }
  (archive, paths)
}
