///|
// Inspect command arguments, not Bun's package metadata, embedded JavaScript,
// comments, or the backend argument vector passed to vp.
fn bare_bun_process_violations(source : String) -> Array[String] {
  let violations : Array[String] = []
  let calls : Array[(String, Int32)] = []
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
  guard installers.length() == 1 &&
    installers.all(line => {
      line.contains(
        "voidzero-dev/setup-vp@cab1ab9eaff52d4857875f4f2c016e36af8f2c76",
      )
    }) else {
    abort("the CI job must pin the reviewed setup-vp action")
  }
  for setting in ["version: 1.4.0", "run-install: false"] {
    guard workflow.split("\n").filter(line => line.trim() == setting).count() ==
      1 else {
      abort("the CI job must explicitly set " + setting)
    }
  }
  for
    token in [
      "version: 1.4.0", "vp install --frozen-lockfile", "vp env current --json",
      "vp run --no-cache check:coverage", "vp run --no-cache check:candidate", "sha256sum --check --strict",
      "name: Setup MoonBit", "MOON_VERSION: 0.1.20261023 (3778465 2026-10-23)", "MOONC_VERSION: v0.10.17+d971670cd (2026-10-23)",
      "\"moon $MOON_VERSION\"", "\"moonrun $MOON_VERSION\"", "\"moonc $MOONC_VERSION\"",
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
