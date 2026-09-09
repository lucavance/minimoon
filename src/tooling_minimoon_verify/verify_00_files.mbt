///|
type Path = @path.Path

///|
fn object(json : Json, label : String) -> Map[String, Json] {
  match json {
    Object(fields) => fields
    _ => abort(label + " must be an object")
  }
}

///|
fn field(json : Json, key : String) -> Json {
  object(json, key).get(key).unwrap_or_else(fn() { abort("missing " + key) })
}

///|
fn string(json : Json, key : String, fallback? : String = "") -> String {
  match object(json, key).get(key) {
    Some(String(value)) => value
    Some(Null) | None => fallback
    Some(_) => abort(key + " must be a string")
  }
}

///|
fn array(json : Json, key : String) -> Array[Json] {
  match field(json, key) {
    Array(items) => items
    _ => abort(key + " must be an array")
  }
}

///|
fn join(base : String, child : String) -> String {
  Path::join(base, child).normalize().to_string()
}

///|
async fn read_json(file : String) -> Json {
  @json.parse(@fs.read_file(file).text()) catch {
    err => abort("invalid JSON in " + file + ": \{err}")
  }
}

///|
async fn write(file : String, content : String) -> Unit {
  let parent = Path::dirname(file).to_string()
  if parent != "" && !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  @fs.write_file(file, content, create_mode=CreateOrTruncate, permission=0o644)
}

///|
async fn write_json(file : String, value : Json) -> Unit {
  write(file, value.stringify(indent=2) + "\n")
}

///|
fn fingerprint_bytes(hash : UInt64, bytes : Bytes) -> UInt64 {
  let mut current = hash
  for byte in bytes {
    current = (current ^ byte.to_int().to_uint64()) * 1099511628211UL
  }
  current
}

///|
fn fingerprint_length(hash : UInt64, length : Int) -> UInt64 {
  let mut current = hash
  let value = length.to_uint64()
  for shift = 0; shift < 64; shift = shift + 8 {
    current = (current ^ ((value >> shift) & 255UL)) * 1099511628211UL
  }
  current
}

///|
fn fingerprint_entry(
  hash : UInt64,
  relative : String,
  content : Bytes,
) -> UInt64 {
  let path = @utf8.encode(relative)
  let with_path_length = fingerprint_length(hash, path.length())
  let with_path = fingerprint_bytes(with_path_length, path)
  let with_content_length = fingerprint_length(with_path, content.length())
  fingerprint_bytes(with_content_length, content)
}

///|
fn portable_relative_path(app_root : String, file : String) -> String {
  Path::relative(file, base=app_root)
  .normalize()
  .to_string()
  .replace_all(old="\\", new="/")
}

///|
async fn fingerprint_files(app_root : String) -> Array[String] {
  let dist = join(app_root, "dist")
  let files : Array[String] = []
  @fs.walk(
    dist,
    (path, names) => {
      for name in names {
        let file = join(path, name)
        if @fs.kind(file, follow_symlink=false) == @fs.Regular {
          let relative = portable_relative_path(app_root, file)
          if relative != "dist/project.private.config.json" {
            files.push(relative)
          }
        }
      }
    },
    max_concurrency=1,
  )
  files.push("generated/manifest.json")
  files.push("generated/smoke_checklist.json")
  files.sort()
  files
}

///|
pub async fn artifact_fingerprint(app_root : String) -> String {
  for
    relative in [
      "dist/app.json", "generated/manifest.json", "generated/smoke_checklist.json",
    ] {
    let file = join(app_root, relative)
    guard @fs.exists(file) &&
      @fs.kind(file, follow_symlink=false) == @fs.Regular else {
      abort(
        "artifact fingerprint input is missing: " +
        relative +
        "; run minimoon build first",
      )
    }
  }
  let files = fingerprint_files(app_root)
  let mut hash = 14695981039346656037UL
  for relative in files {
    let file = join(app_root, relative)
    hash = fingerprint_entry(hash, relative, @fs.read_file(file).binary())
  }
  "fnv1a64-relpath-v2:" + hash.to_string(radix=16)
}

///|
fn status(name : String, passed : Bool, detail : String) -> Json {
  Json::object({
    "name": Json::string(name),
    "status": Json::string(if passed { "passed" } else { "failed" }),
    "detail": Json::string(detail),
  })
}

///|
fn valid_skyline_page_config(config : Json) -> Bool {
  match config {
    Object(fields) => {
      let renderer = match fields.get("renderer") {
        Some(String(value)) => value
        _ => ""
      }
      let navigation_style = match fields.get("navigationStyle") {
        Some(String(value)) => value
        _ => ""
      }
      renderer == "skyline" &&
      navigation_style == "custom" &&
      !fields.contains("navigationBarTitleText") &&
      (match fields.get("navigationBarTextStyle") {
        None | Some(String("white")) | Some(String("black")) => true
        _ => false
      }) &&
      !fields.contains("navigationBarBackgroundColor")
    }
    _ => false
  }
}

///|
fn transform_setting(config : Json, name : String) -> Bool? {
  match config {
    Object(fields) =>
      match fields.get("setting") {
        Some(Object(settings)) =>
          match settings.get(name) {
            Some(True) => Some(true)
            Some(False) => Some(false)
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
fn valid_devtools_host_project_config(config : Json) -> Bool {
  transform_setting(config, "es6") == Some(true) &&
  transform_setting(config, "enhance") == Some(true) &&
  transform_setting(config, "minified") == Some(true)
}

///|
fn valid_custom_navigation_app_config(config : Json) -> Bool {
  match config {
    Object(fields) =>
      match fields.get("window") {
        None => true
        Some(Object(window)) =>
          !window.contains("navigationStyle") &&
          !window.contains("navigationBarTitleText") &&
          !window.contains("navigationBarTextStyle") &&
          !window.contains("navigationBarBackgroundColor")
        _ => false
      }
    _ => false
  }
}

///|
async fn check_skyline_page_config(file : String) -> (Bool, String) {
  let config = @json.parse(@fs.read_file(file).text()) catch {
    err => return (false, file + " is invalid JSON: \{err}")
  }
  if valid_skyline_page_config(config) {
    (true, "")
  } else {
    (false, file + " must set renderer=skyline and navigationStyle=custom")
  }
}

///|
async fn check_devtools_host_project_config(
  project_file : String,
) -> (Bool, String) {
  guard @fs.exists(project_file) else {
    return (false, "missing " + project_file)
  }
  let project = @json.parse(@fs.read_file(project_file).text()) catch {
    err => return (false, project_file + " is invalid JSON: \{err}")
  }
  guard valid_devtools_host_project_config(project) else {
    return (
      false,
      "MMN2002: " +
      project_file +
      " must set setting.es6=true, setting.enhance=true, and setting.minified=true for the verified Developer Tools compilation boundary",
    )
  }
  (true, "")
}

///|
async fn run(
  command : String,
  args : Array[String],
  cwd : String,
) -> (Bool, String) {
  let (code, stdout, stderr) = @process.collect_output(command, args, cwd~) catch {
    err => return (false, "failed to start " + command + ": \{err}")
  }
  let output = stdout.text() catch { _ => "" }
  let error = stderr.text() catch { _ => "" }
  (code == 0, (output + "\n" + error).trim().to_owned())
}

///|
fn host_smoke_source(
  page_files : Array[String],
  inputs? : Array[Json] = [],
) -> String {
  @host_js.host_smoke_source(page_files, inputs~)
}
