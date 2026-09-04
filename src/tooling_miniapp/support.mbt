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
fn json_int(value : Int) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
fn join(base : String, child : String) -> String {
  Path::join(base, child).normalize().to_string()
}

///|
fn dirname(path : String) -> String {
  Path::dirname(path).to_string()
}

///|
fn app_relative_path(value : String, label : String) -> String {
  guard value != "" && !Path::is_absolute(value) && !value.contains("..") else {
    abort(label + " must stay inside the app: " + value)
  }
  value
}

///|
fn valid_page_route(route : String) -> Bool {
  route != "" && !route.has_prefix("/") && !route.contains("..")
}

///|
async fn write(file : String, content : String) -> Unit {
  let parent = dirname(file)
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
fn module_name(moon_mod : String) -> String {
  for line in moon_mod.split("\n") {
    let line = line.trim()
    if line.has_prefix("name =") {
      let raw = line["name =".length():].trim()
      let parsed = @json.parse(raw) catch { _ => Json::null() }
      return match parsed {
        String(value) => value
        _ => abort("moon.mod name must be a quoted string")
      }
    }
  } nobreak {
    abort("moon.mod is missing name")
  }
}

///|
fn package_import(module_id : String, package_path : String) -> String {
  guard package_path == "src" || package_path.has_prefix("src/") else {
    abort("page package must be src or live below src/: " + package_path)
  }
  if package_path == "src" {
    module_id
  } else {
    module_id + "/" + package_path["src/".length():].to_owned()
  }
}

///|
fn moon_identifier(value : String, label : String) -> String {
  guard value != "" else { abort(label + " must not be empty") }
  for index = 0; index < value.length(); index = index + 1 {
    let char = value[index]
    let valid = (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (index > 0 && char >= '0' && char <= '9') ||
      char == '_'
    guard valid else { abort(label + " is not a MoonBit identifier: " + value) }
  }
  value
}
