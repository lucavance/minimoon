///|
async fn scaffold_application(
  app_dir : String,
  config : Json?,
) -> (String, String)? {
  guard config is Some(Object(fields)) else {
    guard config is None else { fail("application must be an object") }
    return None
  }
  let package_path = match fields.get("package") {
    Some(String(value)) => value
    _ => fail("application.package must name a source package")
  }
  guard (package_path == "src" || package_path.has_prefix("src/")) &&
    !package_path
    .split("/")
    .any(part => part == ".." || part == "." || part == "") &&
    @fs.exists(join_path(app_dir, package_path + "/moon.pkg")) else {
    fail("application.package must name an existing package below src")
  }
  let program = match fields.get("program") {
    None => "program"
    Some(String(program)) => program
    _ => fail("application.program must be an identifier")
  }
  guard program != "" else { fail("application.program must not be empty") }
  for index = 0; index < program.length(); index = index + 1 {
    let ch = program[index]
    guard (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      ch == '_' ||
      (index > 0 && ch >= '0' && ch <= '9') else {
      fail("application.program must be an identifier")
    }
  }
  let source = @fs.read_file(join_path(app_dir, "moon.mod")).text()
  for line in source.split("\n") {
    let line = line.trim()
    if line.has_prefix("name =") {
      if @json.parse(line["name =".length():].trim()) is String(name) {
        return Some((name + package_path[3:].to_owned(), program))
      }
    }
  }
  fail("moon.mod does not contain a module name")
}
