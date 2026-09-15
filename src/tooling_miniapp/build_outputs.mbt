///|
/// A validated source configuration. Physical staging paths are kept separate
/// from the original application paths used by MoonBit and Tailwind.
struct PreparedBuild {
  config_file : String
  document : ConfigDocument
  app_root : String
  dist : String
  source_wxss : String
  tailwind_input : String
}

///|
pub fn PreparedBuild::app_root(self : PreparedBuild) -> String {
  self.app_root
}

///|
fn contains_path(parent : String, child : String) -> Bool {
  parent == child || child.has_prefix(parent + "/")
}

///|
fn normalized_output_path(value : String) -> String {
  Path::normalize(app_relative_path(value, "build output"))
  .to_string()
  .replace_all(old="\\", new="/")
}

///|
fn output_path_problem(
  dist : String,
  source_wxss : String,
  tailwind_input : String,
  config_name : String,
  source_paths? : Array[String] = ["src"],
) -> (String, String)? {
  let tailwind_temporary = join(
    dirname(tailwind_input),
    ".minimoon-tailwind-input.css",
  )
  if tailwind_input == tailwind_temporary {
    return Some(
      (
        "tailwindInput", "tailwindInput must not use the reserved Tailwind temporary filename",
      ),
    )
  }
  let reserved = [
    "src", "generated", "_build", ".minimoon-tmp", ".git", ".mooncakes", "node_modules",
    "moon.mod", "moon.work", "package.json", "bun.lock", "bun.lockb", config_name,
    tailwind_input, tailwind_temporary, ..source_paths,
  ]
  if dist == "." ||
    reserved.any(path => contains_path(dist, path) || contains_path(path, dist)) {
    return Some(
      (
        "distDir", "distDir overlaps application inputs or reserved output paths",
      ),
    )
  }
  let protected_source = [
    "src",
    "_build",
    ".minimoon-tmp",
    ".git",
    ".mooncakes",
    "node_modules",
    "moon.mod",
    "moon.work",
    "package.json",
    "bun.lock",
    "bun.lockb",
    config_name,
    tailwind_input,
    tailwind_temporary,
    ..source_paths,
    "generated/manifest.json",
    "generated/expected_set_data.json",
    "generated/smoke_checklist.json",
    "generated/release_summary.json",
    "generated/diagnostics.json",
    "generated/verify_report.json",
    "generated/devtools.evidence.json",
    dist + "/project.private.config.json",
  ]
  if source_wxss == "." ||
    source_wxss == "generated" ||
    protected_source.any(path => {
      contains_path(source_wxss, path) || contains_path(path, source_wxss)
    }) ||
    (source_wxss.has_prefix("generated/") && !source_wxss.has_suffix(".wxss")) ||
    contains_path(source_wxss, dist) {
    return Some(
      (
        "sourceWxss", "sourceWxss overlaps application inputs or reserved output paths",
      ),
    )
  }
  if contains_path(dist, source_wxss) && !source_wxss.has_suffix(".wxss") {
    return Some(
      ("sourceWxss", "sourceWxss inside distDir must name a WXSS file"),
    )
  }
  None
}

///|
/// Reject symlink traversal, including dangling links, before writing or
/// renaming an output. Missing ancestors are safe and are created later.
pub async fn validate_output_path(
  app_root : String,
  relative : String,
  directory : Bool,
) -> Unit {
  let parts = relative.split("/").collect()
  let mut current = app_root
  for index, part in parts {
    guard part != "" && part != "." && part != ".." else {
      raise Failure("invalid build output path: " + relative)
    }
    if !@fs.readdir(current, include_hidden=true).contains(part.to_owned()) {
      return
    }
    current = join(current, part.to_owned())
    let kind = @fs.kind(current, follow_symlink=false)
    let expected = if index < parts.length() - 1 || directory {
      @fs.Directory
    } else {
      @fs.Regular
    }
    guard kind == expected else {
      raise Failure(
        "build output must not traverse symlinks or replace a different file kind: " +
        current,
      )
    }
  }
}

///|
fn module_source_directory(source : String) -> String? raise {
  for line in source.split("\n") {
    if line.split_once("=") is Some((key, rest)) && key.trim() == "source" {
      let literal = rest.trim()
      guard literal.length() >= 2 && (literal[0] == '"' || literal[0] == '\'') else {
        raise Failure("moon.mod source must be a quoted relative directory")
      }
      let quote = literal[0]
      let mut escaped = false
      for index in 1..<literal.length() {
        let char = literal[index]
        if char == quote && !escaped {
          let tail = literal[index + 1:].trim()
          guard tail == "" || tail.has_prefix("#") else {
            raise Failure("unexpected text after moon.mod source directory")
          }
          let value = if quote == '\'' {
            literal[1:index].to_owned()
          } else {
            match @json.parse(literal[:index + 1]) {
              String(value) => value
              _ => raise Failure("moon.mod source must be a string")
            }
          }
          guard valid_app_path(value) else {
            raise Failure("moon.mod source must stay inside the application")
          }
          return Some(normalized_output_path(value))
        }
        escaped = quote == '"' && char == '\\' && !escaped
      }
      raise Failure("unterminated moon.mod source directory")
    }
  }
  None
}

///|
async fn application_source_paths(
  app_root : String,
  raw : Json,
) -> Array[String] {
  let paths : Array[String] = []
  if module_source_directory(@fs.read_file(join(app_root, "moon.mod")).text())
    is Some(directory) &&
    directory != "." {
    paths.push(directory)
  }
  // Default/root source layouts still protect every explicitly declared page
  // and application package, as well as module-root MoonBit source files.
  for name in @fs.readdir(app_root, include_hidden=true) {
    if name.has_suffix(".mbt") || name == "moon.pkg" {
      paths.push(name)
    }
  }
  for page in array(raw, "pages") {
    paths.push(normalized_output_path(string(page, "package")))
  }
  if raw is Object(fields) && fields.get("application") is Some(application) {
    paths.push(normalized_output_path(string(application, "package")))
  }
  paths
}

///|
pub async fn prepare_build(config_path : String) -> PreparedBuild {
  let config_file = Path::normalize(config_path).to_string()
  let app_root = dirname(config_file)
  // Diagnostics themselves are an output and must not follow a user symlink.
  validate_output_path(app_root, "generated/diagnostics.json", false)
  let document = load_config_document(config_file)
  let raw = document.value
  let dist = normalized_output_path(string(raw, "distDir", fallback="dist"))
  let source_wxss = normalized_output_path(
    string(raw, "sourceWxss", fallback="styles/app.wxss"),
  )
  let tailwind_input = normalized_output_path(
    string(raw, "tailwindInput", fallback="styles/tailwind.css"),
  )
  let config_name = Path::basename(config_file).to_owned()
  match
    output_path_problem(
      dist,
      source_wxss,
      tailwind_input,
      config_name,
      source_paths=application_source_paths(app_root, raw),
    ) {
    Some((field, problem)) => {
      let message = write_config_issue(
        document,
        config_file,
        "MMN1012",
        problem,
        "/" + field,
        "Keep output paths separate from source, configuration and build temporary directories.",
      )
      raise Failure(message)
    }
    None => ()
  }
  for
    (path, directory) in [
      (dist, true),
      (source_wxss, false),
      ("_build/minimoon-build", true),
      ("_build/minimoon-build/build.lock", false),
      (join(dirname(tailwind_input), ".minimoon-tailwind-input.css"), false),
      ("generated/manifest.json", false),
      ("generated/expected_set_data.json", false),
      ("generated/smoke_checklist.json", false),
      ("generated/release_summary.json", false),
      (dist + "/project.private.config.json", false),
    ] {
    validate_output_path(app_root, path, directory)
  }
  { config_file, document, app_root, dist, source_wxss, tailwind_input, }
}

///|
pub async fn write_build_failure(
  config_file : String,
  message : String,
) -> Unit {
  // Preserve a more precise configuration/compiler diagnostic when one exists.
  let file = join(dirname(config_file), "generated/diagnostics.json")
  validate_output_path(
    dirname(config_file),
    "generated/diagnostics.json",
    false,
  )
  let current = if @fs.exists(file) {
    Some(@fs.read_file(file).text())
  } else {
    None
  }
  if current is Some(text) {
    let precise = @json.parse(text) catch { _ => Json::null() }
    if precise is Object(fields) &&
      fields.get("status") == Some(Json::string("failed")) {
      return
    }
  }
  write_config_diagnostics(config_file, [
    {
      code: "MMN2003",
      message,
      file: config_file,
      line: 1,
      column: 1,
      json_pointer: "",
      hint: "Fix the build error and rebuild the application.",
    },
  ])
}
