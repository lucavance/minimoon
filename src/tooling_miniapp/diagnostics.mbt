///|
priv struct SourceSpan {
  line : Int
  column : Int
}

///|
priv struct ConfigIssue {
  code : String
  message : String
  file : String
  line : Int
  column : Int
  json_pointer : String
  hint : String
}

///|
priv struct ConfigDocument {
  value : Json
  spans : Map[String, SourceSpan]
}

///|
fn source_span(raw : String, offset : Int) -> SourceSpan {
  let mut line = 1
  let mut column = 1
  for index = 0; index < offset && index < raw.length(); index = index + 1 {
    if raw[index] == '\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
  }
  { line, column, }
}

///|
fn pointer_key(value : String) -> String {
  value.split("~").collect().join("~0").split("/").collect().join("~1")
}

///|
fn skip_space(raw : String, offset : Ref[Int]) -> Unit {
  while offset.val < raw.length() &&
        (
          raw[offset.val] == ' ' ||
          raw[offset.val] == '\n' ||
          raw[offset.val] == '\r' ||
          raw[offset.val] == '\t'
        ) {
    offset.val = offset.val + 1
  }
}

///|
fn scan_string(raw : String, offset : Ref[Int]) -> (Int, Int) {
  let start = offset.val
  offset.val = offset.val + 1
  let mut escaped = false
  while offset.val < raw.length() {
    let char = raw[offset.val]
    if escaped {
      escaped = false
    } else if char == '\\' {
      escaped = true
    } else if char == '"' {
      offset.val = offset.val + 1
      return (start, offset.val)
    }
    offset.val = offset.val + 1
  }
  (start, offset.val)
}

///|
fn decoded_key(raw : String, start : Int, end : Int) -> String {
  let parsed = @json.parse(raw[start:end]) catch { _ => Json::string("") }
  match parsed {
    String(value) => value
    _ => ""
  }
}

///|
fn scan_primitive(raw : String, offset : Ref[Int]) -> Unit {
  while offset.val < raw.length() &&
        raw[offset.val] != ',' &&
        raw[offset.val] != ']' &&
        raw[offset.val] != '}' &&
        raw[offset.val] != ' ' &&
        raw[offset.val] != '\n' &&
        raw[offset.val] != '\r' &&
        raw[offset.val] != '\t' {
    offset.val = offset.val + 1
  }
}

///|
fn scan_value(
  raw : String,
  offset : Ref[Int],
  pointer : String,
  spans : Map[String, SourceSpan],
  duplicates : Array[ConfigIssue],
  file : String,
) -> Unit {
  skip_space(raw, offset)
  guard offset.val < raw.length() else { return }
  if raw[offset.val] == '{' {
    offset.val = offset.val + 1
    let names : Array[String] = []
    skip_space(raw, offset)
    while offset.val < raw.length() && raw[offset.val] != '}' {
      let (start, end) = scan_string(raw, offset)
      let name = decoded_key(raw, start, end)
      let child = pointer + "/" + pointer_key(name)
      let span = source_span(raw, start + 1)
      if names.contains(name) {
        duplicates.push({
          code: "MMN1002",
          message: "duplicate JSON object key: " + name,
          file,
          line: span.line,
          column: span.column,
          json_pointer: child,
          hint: "Remove the duplicate key and keep one authoritative value.",
        })
      } else {
        names.push(name)
      }
      spans[child] = span
      skip_space(raw, offset)
      if offset.val < raw.length() && raw[offset.val] == ':' {
        offset.val = offset.val + 1
      }
      scan_value(raw, offset, child, spans, duplicates, file)
      skip_space(raw, offset)
      if offset.val < raw.length() && raw[offset.val] == ',' {
        offset.val = offset.val + 1
        skip_space(raw, offset)
      }
    }
    if offset.val < raw.length() && raw[offset.val] == '}' {
      offset.val = offset.val + 1
    }
  } else if raw[offset.val] == '[' {
    offset.val = offset.val + 1
    let mut index = 0
    skip_space(raw, offset)
    while offset.val < raw.length() && raw[offset.val] != ']' {
      let child = pointer + "/" + index.to_string()
      spans[child] = source_span(raw, offset.val)
      scan_value(raw, offset, child, spans, duplicates, file)
      index = index + 1
      skip_space(raw, offset)
      if offset.val < raw.length() && raw[offset.val] == ',' {
        offset.val = offset.val + 1
        skip_space(raw, offset)
      }
    }
    if offset.val < raw.length() && raw[offset.val] == ']' {
      offset.val = offset.val + 1
    }
  } else if raw[offset.val] == '"' {
    let _ = scan_string(raw, offset)
  } else {
    scan_primitive(raw, offset)
  }
}

///|
fn issue_at(
  code : String,
  message : String,
  file : String,
  pointer : String,
  hint : String,
  spans : Map[String, SourceSpan],
) -> ConfigIssue {
  let span = spans.get(pointer).unwrap_or({ line: 1, column: 1, })
  {
    code,
    message,
    file,
    line: span.line,
    column: span.column,
    json_pointer: pointer,
    hint,
  }
}

///|
fn issue_json(issue : ConfigIssue) -> Json {
  Json::object({
    "code": Json::string(issue.code),
    "severity": Json::string("error"),
    "message": Json::string(issue.message),
    "file": Json::string(issue.file),
    "line": Json::number(issue.line.to_double(), repr=issue.line.to_string()),
    "column": Json::number(
      issue.column.to_double(),
      repr=issue.column.to_string(),
    ),
    "jsonPointer": Json::string(issue.json_pointer),
    "hint": Json::string(issue.hint),
  })
}

///|
async fn write_config_diagnostics(
  config_file : String,
  issues : Array[ConfigIssue],
) -> Unit {
  write_json(
    join(dirname(config_file), "generated/diagnostics.json"),
    Json::object({
      "schemaVersion": Json::number(1.0, repr="1"),
      "status": Json::string(
        if issues.length() == 0 {
          "passed"
        } else {
          "failed"
        },
      ),
      "issues": Json::array(issues.map(issue_json)),
    }),
  )
}

///|
async fn write_config_issue(
  document : ConfigDocument,
  config_file : String,
  code : String,
  message : String,
  pointer : String,
  hint : String,
) -> String {
  let issues = [
    issue_at(code, message, config_file, pointer, hint, document.spans),
  ]
  write_config_diagnostics(config_file, issues)
  diagnostic_message(issues)
}

///|
fn diagnostic_message(issues : Array[ConfigIssue]) -> String {
  issues
  .map(issue => {
    issue.file +
    ":" +
    issue.line.to_string() +
    ":" +
    issue.column.to_string() +
    ": error[" +
    issue.code +
    "]: " +
    issue.message
  })
  .join("\n")
}

///|
fn valid_app_path(value : String) -> Bool {
  value != "" && !Path::is_absolute(value) && !value.contains("..")
}

///|
async fn load_config_document(config_file : String) -> ConfigDocument {
  let raw = @fs.read_file(config_file).text()
  let parsed : Result[Json, @json.ParseError] = Ok(@json.parse(raw)) catch {
    error => Err(error)
  }
  let value = match parsed {
    Ok(value) => value
    Err(error) => {
      let span = match error {
        @json.InvalidChar(position, _)
        | @json.InvalidNumber(position, _)
        | @json.InvalidIdentEscape(position) =>
          { line: position.line, column: position.column + 1, }
        _ => source_span(raw, raw.length())
      }
      let issues = [
        {
          code: "MMN1001",
          message: "invalid JSON: \{error}",
          file: config_file,
          line: span.line,
          column: span.column,
          json_pointer: "",
          hint: "Fix the JSON syntax before building the MiniApp.",
        },
      ]
      write_config_diagnostics(config_file, issues)
      raise Failure::Failure(diagnostic_message(issues))
    }
  }
  let spans : Map[String, SourceSpan] = Map([])
  spans[""] = { line: 1, column: 1, }
  let duplicates : Array[ConfigIssue] = []
  let offset = Ref(0)
  scan_value(raw, offset, "", spans, duplicates, config_file)
  let issues = duplicates
  let schema_version = @versions.app_contract_version()
  match value {
    Object(fields) => {
      match fields.get("schemaVersion") {
        Some(Number(version, ..)) if version == schema_version.to_double() ||
          (version == 8.0 && !fields.contains("application")) => ()
        Some(Number(_, ..)) =>
          issues.push(
            issue_at(
              "MMN1008",
              "schemaVersion must be " + schema_version.to_string(),
              config_file,
              "/schemaVersion",
              "Set schemaVersion to " + schema_version.to_string() + ".",
              spans,
            ),
          )
        Some(_) =>
          issues.push(
            issue_at(
              "MMN1004",
              "schemaVersion must be a number",
              config_file,
              "/schemaVersion",
              "Use the numeric value " + schema_version.to_string() + ".",
              spans,
            ),
          )
        None =>
          issues.push(
            issue_at(
              "MMN1003",
              "schemaVersion is required",
              config_file,
              "",
              "Add \"schemaVersion\": " + schema_version.to_string() + ".",
              spans,
            ),
          )
      }
      validate_application_config(fields, config_file, spans, issues)
      match fields.get("name") {
        Some(String(name)) if name != "" => ()
        Some(_) =>
          issues.push(
            issue_at(
              "MMN1004", "name must be a non-empty string", config_file, "/name",
              "Use a MoonBit-safe application name.", spans,
            ),
          )
        None =>
          issues.push(
            issue_at(
              "MMN1003", "name is required", config_file, "", "Add a non-empty name field.",
              spans,
            ),
          )
      }
      match fields.get("pages") {
        Some(Array(pages)) if pages.length() > 0 => {
          let packages : Array[String] = []
          for index, page in pages {
            let pointer = "/pages/" + index.to_string()
            match page {
              Object(page_fields) =>
                match page_fields.get("package") {
                  Some(String(package_path)) if valid_app_path(package_path) => {
                    if packages.contains(package_path) {
                      issues.push(
                        issue_at(
                          "MMN1007",
                          "duplicate page package: " + package_path,
                          config_file,
                          pointer + "/package",
                          "Keep each Page package once.",
                          spans,
                        ),
                      )
                    } else {
                      packages.push(package_path)
                    }
                    let package_dir = join(dirname(config_file), package_path)
                    if !@fs.exists(join(package_dir, "moon.pkg")) {
                      issues.push(
                        issue_at(
                          "MMN1006",
                          "page package does not contain moon.pkg: " +
                          package_path,
                          config_file,
                          pointer + "/package",
                          "Create the MoonBit package or correct its path.",
                          spans,
                        ),
                      )
                    }
                  }
                  Some(_) =>
                    issues.push(
                      issue_at(
                        "MMN1005",
                        "page package must be a safe app-relative path",
                        config_file,
                        pointer + "/package",
                        "Use src or a path below src without '..'.",
                        spans,
                      ),
                    )
                  None =>
                    issues.push(
                      issue_at(
                        "MMN1003", "page package is required", config_file, pointer,
                        "Add a package field such as src/pages/home.", spans,
                      ),
                    )
                }
              _ =>
                issues.push(
                  issue_at(
                    "MMN1004", "each pages entry must be an object", config_file,
                    pointer, "Use { \"package\": \"src/pages/...\" }.", spans,
                  ),
                )
            }
          }
        }
        Some(_) =>
          issues.push(
            issue_at(
              "MMN1004", "pages must be a non-empty array", config_file, "/pages",
              "Declare at least one Page package.", spans,
            ),
          )
        None =>
          issues.push(
            issue_at(
              "MMN1003", "pages is required", config_file, "", "Add a non-empty pages array.",
              spans,
            ),
          )
      }
      for
        entry in [
          ("distDir", "dist"),
          ("tailwindInput", "styles/tailwind.css"),
          ("sourceWxss", "styles/app.wxss"),
        ] {
        let (name, fallback) = entry
        match fields.get(name) {
          Some(String(path)) if valid_app_path(path) => ()
          Some(_) =>
            issues.push(
              issue_at(
                "MMN1005",
                name + " must be a safe app-relative path",
                config_file,
                "/" + name,
                "Use a relative path such as " + fallback + ".",
                spans,
              ),
            )
          None => ()
        }
      }
      match fields.get("componentTheme") {
        Some(String("minimal-v1")) | Some(String("minimal-v2")) | None => ()
        Some(String(value)) =>
          issues.push(
            issue_at(
              "MMN1009",
              "unsupported componentTheme: " + value,
              config_file,
              "/componentTheme",
              "Use \"minimal-v1\", \"minimal-v2\", or remove componentTheme.",
              spans,
            ),
          )
        Some(_) =>
          issues.push(
            issue_at(
              "MMN1004", "componentTheme must be a string", config_file, "/componentTheme",
              "Use \"minimal-v1\", \"minimal-v2\", or remove componentTheme.", spans,
            ),
          )
      }
      match fields.get("devtoolsChecks") {
        Some(Array(checks)) => {
          let declared : Set[String] = Set([])
          for index, check in checks {
            let pointer = "/devtoolsChecks/" + index.to_string()
            match check {
              String(value) if value.trim() != "" => {
                let normalized = value.trim().to_owned()
                if declared.contains(normalized) {
                  issues.push(
                    issue_at(
                      "MMN1007",
                      "duplicate DevTools check: " + normalized,
                      config_file,
                      pointer,
                      "Keep each manual validation check once.",
                      spans,
                    ),
                  )
                } else {
                  declared.add(normalized)
                }
              }
              _ =>
                issues.push(
                  issue_at(
                    "MMN1004", "each devtoolsChecks entry must be a non-empty string",
                    config_file, pointer, "Describe one observable manual validation step.",
                    spans,
                  ),
                )
            }
          }
        }
        Some(_) =>
          issues.push(
            issue_at(
              "MMN1004", "devtoolsChecks must be an array", config_file, "/devtoolsChecks",
              "Use an array of unique non-empty strings.", spans,
            ),
          )
        None => ()
      }
      for resource_issue in resource_config_issues(value) {
        issues.push(
          issue_at(
            "MMN1010",
            resource_issue.1,
            config_file,
            resource_issue.0,
            "Declare a native MoonBit resource provider and an optional feature array.",
            spans,
          ),
        )
      }
    }
    _ =>
      issues.push(
        issue_at(
          "MMN1004", "MiniApp config root must be an object", config_file, "", "Wrap configuration fields in a JSON object.",
          spans,
        ),
      )
  }
  if !@fs.exists(join(dirname(config_file), "moon.mod")) {
    issues.push(
      issue_at(
        "MMN1006", "application moon.mod was not found", config_file, "", "Place miniapp.minimoon.json beside the application's moon.mod.",
        spans,
      ),
    )
  }
  if issues.length() > 0 {
    write_config_diagnostics(config_file, issues)
    raise Failure::Failure(diagnostic_message(issues))
  }
  { value, spans, }
}
