///|
async fn validate_application_config(
  fields : Map[String, Json],
  config_file : String,
  spans : Map[String, SourceSpan],
  issues : Array[ConfigIssue],
) -> Unit {
  match fields.get("application") {
    None => ()
    Some(Object(application)) => {
      match application.get("package") {
        Some(String(path)) if valid_app_path(path) &&
          (path == "src" || path.has_prefix("src/")) =>
          if !@fs.exists(join(join(dirname(config_file), path), "moon.pkg")) {
            issues.push(
              issue_at(
                "MMN1006", "application package does not contain moon.pkg", config_file,
                "/application/package", "Create the application package exporting Deps and program() -> App[Deps].",
                spans,
              ),
            )
          }
        _ =>
          issues.push(
            issue_at(
              "MMN1004", "application.package must be an app-relative package path",
              config_file, "/application/package", "Use a package path such as src/app.",
              spans,
            ),
          )
      }
      match application.get("program") {
        None => ()
        Some(String(name)) if valid_application_identifier(name) => ()
        _ =>
          issues.push(
            issue_at(
              "MMN1004", "application.program must be a MoonBit identifier", config_file,
              "/application/program", "Export program() or provide a valid function name.",
              spans,
            ),
          )
      }
    }
    Some(_) =>
      issues.push(
        issue_at(
          "MMN1004", "application must be an object", config_file, "/application",
          "Use an object with package and optional program fields, or omit application.",
          spans,
        ),
      )
  }
}

///|
fn valid_application_identifier(name : String) -> Bool {
  if name.is_empty() || !((name[0] >= 'a' && name[0] <= 'z') || name[0] == '_') {
    return false
  }
  for char in name {
    if !((char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      char == '_') {
      return false
    }
  }
  true
}
