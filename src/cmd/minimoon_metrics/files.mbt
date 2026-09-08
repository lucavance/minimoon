///|
type Path = @path.Path

///|
struct FileMetric {
  path : String
  owner : String
  area : String?
  role : String
  language : String
  bytes : Int
  physical_lines : Int?
} derive(Debug)

///|
struct FileLedger {
  entries : Array[FileMetric]
  missing : Array[String]
  sources : Array[(String, String)]
}

///|
fn physical_lines(content : String) -> Int {
  if content == "" {
    return 0
  }
  let mut count = 0
  for ch in content {
    if ch == '\n' {
      count = count + 1
    }
  }
  count + (if content.has_suffix("\n") { 0 } else { 1 })
}

///|
fn metrics_text(content : Bytes) -> String? {
  if content.iter().any(byte => byte == b'\x00') {
    return None
  }
  Some(@utf8.decode(content, ignore_bom=false)) catch {
    _ => None
  }
}

///|
fn file_metric(path : String, bytes : Bytes) -> (FileMetric, String?) {
  let text = metrics_text(bytes)
  let (owner, area) = file_ownership(path)
  (
    {
      path,
      owner,
      area,
      role: file_role(path),
      language: file_language(path, text is Some(_)),
      bytes: bytes.length(),
      physical_lines: text.map(physical_lines),
    },
    text,
  )
}

///|
fn metrics_paths(output : String) -> Array[String] raise {
  guard output == "" || output.has_suffix("\u{0000}") else {
    raise Failure("git ls-files output must be NUL terminated")
  }
  let seen : Map[String, Bool] = Map([])
  let paths : Array[String] = []
  for item in output.split("\u{0000}") {
    let path = item.to_owned()
    if path == "" {
      continue
    }
    guard !path.has_prefix("/") &&
      !path.split("/").any(part => part == ".." || part == "" || part == ".") else {
      raise Failure("invalid repository-relative Git path: " + path)
    }
    if !seen.contains(path) {
      seen[path] = true
      paths.push(path)
    }
  }
  paths.sort_by((left, right) => left.lexical_compare(right))
  paths
}

///|
async fn metrics_repository_root(cwd : String) -> String {
  let (code, stdout, stderr) = @process.collect_output(
    "git",
    ["rev-parse", "--show-toplevel"],
    cwd~,
  )
  guard code == 0 else {
    raise Failure("metrics requires a Git repository: " + stderr.text())
  }
  let output = @utf8.decode(stdout.binary(), ignore_bom=false)
  guard output.has_suffix("\n") else {
    raise Failure("git rev-parse returned an invalid repository root")
  }
  output[:output.length() - 1].to_owned()
}

///|
async fn metrics_file_paths(
  root : String,
  include_untracked : Bool,
) -> Array[String] {
  let args = ["ls-files", "-z", "--cached"]
  if include_untracked {
    args.push("--others")
    args.push("--exclude-standard")
  }
  let (code, stdout, stderr) = @process.collect_output("git", args, cwd=root)
  guard code == 0 else {
    raise Failure("git ls-files failed: " + stderr.text())
  }
  metrics_paths(@utf8.decode(stdout.binary(), ignore_bom=false))
}

///|
async fn measure_files(root : String, include_untracked : Bool) -> FileLedger {
  let paths = metrics_file_paths(root, include_untracked)
  let entries : Array[FileMetric] = []
  let missing : Array[String] = []
  let sources : Array[(String, String)] = []
  for path in paths {
    let absolute = Path::join(root, path).to_string()
    if !metrics_regular_file(root, path) {
      missing.push(path)
      continue
    }
    let (entry, source) = file_metric(path, @fs.read_file(absolute).binary())
    entries.push(entry)
    if source is Some(text) &&
      path.has_suffix(".mbt") &&
      entry.role != "generated_artifact" &&
      entry.role != "api_snapshot" {
      sources.push((path, text))
    }
  }
  { entries, missing, sources, }
}

///|
async fn metrics_regular_file(root : String, path : String) -> Bool {
  let parts = path.split("/").collect()
  let mut current = root
  for index = 0; index < parts.length(); index = index + 1 {
    current = Path::join(current, parts[index].to_owned()).to_string()
    if !@fs.exists(current) {
      return false
    }
    let kind = @fs.kind(current, follow_symlink=false)
    guard kind != @fs.SymLink else {
      raise Failure(
        "metrics will not follow a file or parent-directory symlink: " + path,
      )
    }
    if index + 1 < parts.length() {
      if kind != @fs.Directory {
        return false
      }
    } else {
      guard kind == @fs.Regular else {
        raise Failure("metrics requires a regular file: " + path)
      }
    }
  }
  true
}
