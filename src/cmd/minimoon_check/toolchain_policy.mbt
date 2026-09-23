///|
// Inspect command arguments, not Bun's package metadata, embedded JavaScript,
// comments, or the backend argument vector passed to vp.
fn bare_bun_process_violations(source : String) -> Array[String] {
  let violations : Array[String] = []
  let calls : Array[(String, Int)] = []
  let mut identifier = ""
  let mut cursor = 0
  while cursor < source.length() {
    let character = source[cursor]
    if source[cursor:].has_prefix("//") || source[cursor:].has_prefix("#|") {
      while cursor < source.length() && source[cursor] != '\n' {
        cursor += 1
      }
      continue
    }
    if character == '"' || character == '\'' {
      let quote = character
      let start = cursor
      cursor += 1
      while cursor < source.length() && source[cursor] != quote {
        cursor += if source[cursor] == '\\' { 2 } else { 1 }
      }
      let literal = source[start:cursor.min(source.length())].to_owned()
      if quote == '"' && (literal == "\"bun" || literal == "\"bunx") {
        match calls.last() {
          Some((name, argument)) => {
            let is_command = match name {
              "@process.run"
              | "@process.collect_output"
              | "@process.collect_stdout"
              | "@toolchain.run"
              | "@toolchain.collect_output"
              | "run_checked" => argument == 0
              "require_command_failure" => argument == 1
              "run" => argument == 0 || argument == 2
              "supervised_check_process" => argument == 2
              _ => false
            }
            if is_command {
              violations.push(name + " must launch Bun through vp")
            }
          }
          None => ()
        }
      }
      cursor += 1
      identifier = ""
      continue
    }
    if moon_identifier_character(character) ||
      character == '@' ||
      character == '.' {
      let start = cursor
      while cursor < source.length() &&
            (
              moon_identifier_character(source[cursor]) ||
              source[cursor] == '@' ||
              source[cursor] == '.'
            ) {
        cursor += 1
      }
      identifier = source[start:cursor].to_owned()
      continue
    }
    match character {
      '(' => {
        calls.push((identifier, 0))
        identifier = ""
      }
      '[' | '{' => {
        calls.push(("", 0))
        identifier = ""
      }
      ')' | ']' | '}' => {
        ignore(calls.pop())
        identifier = ""
      }
      ',' => {
        match calls.pop() {
          Some((name, argument)) => calls.push((name, argument + 1))
          None => ()
        }
        identifier = ""
      }
      ' ' | '\t' | '\r' | '\n' => ()
      _ => identifier = ""
    }
    cursor += 1
  }
  violations
}

///|
async fn vp_toolchain_policy(root : String) -> Unit {
  let workflow_path = ".github/workflows/test.yml"
  let workflow = @fs.read_file(join(root, workflow_path)).text()
  let installers = workflow
    .split("\n")
    .filter(line => line.contains("uses: voidzero-dev/setup-vp@"))
    .collect()
  guard installers.length() == 2 &&
    installers.all(line => {
      line.contains(
        "voidzero-dev/setup-vp@3754dd7dbdb32bd8f6d28b6043de13ad3a75f21f",
      )
    }) else {
    abort("both CI jobs must pin the reviewed setup-vp action")
  }
  for setting in ["version: 1.0.0-rc.0", "run-install: false"] {
    guard workflow.split("\n").filter(line => line.trim() == setting).length() ==
      2 else {
      abort("both CI jobs must explicitly set " + setting)
    }
  }
  for
    token in [
      "version: 1.0.0-rc.0", "vp install --frozen-lockfile", "vp env current --json",
      "vp run --no-cache check:coverage", "vp run --no-cache check:candidate",
    ] {
    require_text(root, workflow_path, token)
  }
  for
    token in [
      "actions/setup-node@", "oven-sh/setup-bun@", "bun install", "bun run", "bun audit",
    ] {
    forbid_text(root, workflow_path, token)
  }
  let manifest = read_json(root, "package.json")
  let engines = json_field(manifest, "devEngines")
  let runtime = json_field(engines, "runtime")
  guard json_string(runtime, "name") == "node" &&
    json_string(runtime, "version") == primary_node_version &&
    json_string(runtime, "onFail") == "download" else {
    abort("repository must pin the primary vp-managed Node runtime")
  }
  let manager = json_field(engines, "packageManager")
  guard json_string(manager, "name") == "bun" &&
    json_string(manager, "version") == supported_bun_version &&
    json_string(manager, "onFail") == "download" else {
    abort("vp must retain the reviewed Bun backend")
  }
}
