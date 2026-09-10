///|
type Path = @path.Path

///|
fn join(base : String, child : String) -> String {
  Path::join(base, child).normalize().to_string()
}

///|
async fn run(
  root : String,
  label : String,
  command : String,
  args : Array[String],
  cwd? : String,
  env? : Map[String, String],
  display_args? : Array[String],
) -> Unit {
  let working_dir = cwd.unwrap_or(root)
  println("\n==> " + label)
  println("$ " + command + " " + display_args.unwrap_or(args).join(" "))
  let code = @process.run(command, args, cwd=working_dir, extra_env?=env) catch {
    err => abort("failed to start \{label}: \{err}")
  }
  guard code == 0 else { abort(label + " exited with code \{code}") }
}

///|
async fn require_command_failure(
  label : String,
  command : String,
  args : Array[String],
  cwd : String,
  needle : String,
) -> Unit {
  println("\n==> " + label)
  println("$ " + command + " " + args.join(" "))
  let (code, stdout, stderr) = @process.collect_output(command, args, cwd~) catch {
    err => abort("failed to start \{label}: \{err}")
  }
  guard code != 0 else { abort(label + " unexpectedly succeeded") }
  let output = stdout.text() + "\n" + stderr.text()
  guard output.contains(needle) else {
    abort(label + " did not report expected error: " + needle)
  }
}

///|
async fn require_file(root : String, path : String) -> Unit {
  guard @fs.exists(join(root, path)) else {
    abort("required file is missing: " + path)
  }
}

///|
async fn require_text(root : String, path : String, needle : String) -> Unit {
  require_file(root, path)
  guard @fs.read_file(join(root, path)).text().contains(needle) else {
    abort(path + " must contain " + needle)
  }
}

///|
async fn require_same_text(
  root : String,
  source : String,
  mirror : String,
) -> Unit {
  require_file(root, source)
  require_file(root, mirror)
  guard @fs.read_file(join(root, source)).text() ==
    @fs.read_file(join(root, mirror)).text() else {
    abort(mirror + " must mirror " + source)
  }
}

///|
async fn forbid_text(root : String, path : String, needle : String) -> Unit {
  require_file(root, path)
  guard !@fs.read_file(join(root, path)).text().contains(needle) else {
    abort(path + " must not contain " + needle)
  }
}

///|
async fn require_untracked_path(root : String, path : String) -> Unit {
  let (code, output) = @process.collect_stdout(
    "git",
    ["ls-files", "--cached", "--", path],
    cwd=root,
  ) catch {
    err => abort("failed to inspect tracked files: \{err}")
  }
  guard code == 0 else { abort("git ls-files failed") }
  guard output.text().trim() == "" else {
    abort("developer-local file must not be tracked: " + path)
  }
}

///|
async fn read_json(root : String, path : String) -> Json {
  require_file(root, path)
  @json.parse(@fs.read_file(join(root, path)).text()) catch {
    err => abort(path + " is not valid JSON: \{err}")
  }
}

///|
fn json_field(json : Json, key : String) -> Json {
  match json {
    Object(fields) =>
      fields
      .get(key)
      .unwrap_or_else(fn() { abort("missing JSON field: " + key) })
    _ => abort("expected JSON object for " + key)
  }
}

///|
fn json_string(json : Json, key : String) -> String {
  match json_field(json, key) {
    String(value) => value
    _ => abort("expected JSON string: " + key)
  }
}

///|
fn json_bool(json : Json, key : String) -> Bool {
  match json_field(json, key) {
    True => true
    False => false
    _ => abort("expected JSON boolean: " + key)
  }
}

///|
async fn repository_scripts(root : String) -> Array[String] {
  let (code, output) = @process.collect_stdout(
    "git",
    [
      "ls-files", "--cached", "--others", "--exclude-standard", "--", "*.js", "*.mjs",
      "*.cjs", "*.jsx", "*.ts", "*.tsx",
    ],
    cwd=root,
  )
  guard code == 0 else { abort("git ls-files failed") }
  let files : Array[String] = []
  for path in output.text().split("\n") {
    if path != "" && @fs.exists(join(root, path.to_owned())) {
      files.push(path.to_owned())
    }
  }
  files
}

///|
async fn repository_moonbit_sources(root : String) -> Array[String] {
  let (code, output) = @process.collect_stdout(
    "git",
    [
      "ls-files", "--cached", "--others", "--exclude-standard", "--", "*.mbt", "*.mbtx",
    ],
    cwd=root,
  )
  guard code == 0 else { abort("git ls-files failed") }
  let files : Array[String] = []
  for path in output.text().split("\n") {
    if path != "" && @fs.exists(join(root, path.to_owned())) {
      files.push(path.to_owned())
    }
  }
  files.sort()
  files
}

///|
fn generated_script(path : String) -> Bool {
  (
    path.has_prefix("examples/miniapp_draft_workbench/dist/") ||
    path.has_prefix("ui/examples/showcase/dist/")
  ) &&
  (path.has_suffix(".js") || path.has_suffix(".mjs"))
}
