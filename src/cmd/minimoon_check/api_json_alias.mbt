///|
// MoonBit 0.10.19 qualifies the builtin Json and ToJson aliases. Only the
// default alias of the actual core/json import can use the historical spelling.
// Local type/generic bindings, other packages, strings and method names stay exact.
fn api_json_alias(source : String) -> String {
  let tokens = api_interface_tokens(source)
  let token = fn(i : Int32) { api_interface_token(source, tokens, i) }
  let mut in_import = false
  let mut core_json = false
  let mut generic = false
  for i in 0..<tokens.length() {
    let current = token(i)
    if current == "import" && token(i + 1) == "{" {
      in_import = true
    } else if in_import && current == "}" {
      in_import = false
    } else if in_import &&
      current == "\"moonbitlang/core/json\"" &&
      [",", "}"].contains(token(i + 1)) {
      core_json = true
    }
    if current == "[" &&
      (
        token(i - 1) == "fn" ||
        ["type", "struct", "enum", "trait"].contains(token(i - 2))
      ) {
      generic = true
    }
    if current == "]" {
      generic = false
    }
    if ["Json", "ToJson"].contains(current) &&
      (
        (generic && ["[", ","].contains(token(i - 1))) ||
        ["type", "struct", "enum", "trait"].contains(token(i - 1))
      ) {
      return source
    }
  }
  guard core_json else { return source }
  let builder = StringBuilder()
  let mut copied = 0
  for i, (start, _) in tokens {
    if token(i) == "@" &&
      token(i + 1) == "json" &&
      token(i + 2) == "." &&
      ["Json", "ToJson"].contains(token(i + 3)) &&
      token(i + 4) != ":" &&
      [":", "(", "[", ",", ">", "=", "impl", "for", "+"].contains(token(i - 1)) {
      builder.write_string(source[copied:start].to_owned())
      builder.write_string(token(i + 3))
      let (_, end) = tokens[i + 3]
      copied = end
    }
  }
  builder.write_string(source[copied:].to_owned())
  let normalized = builder.to_string()
  let lines : Array[String] = []
  let mut in_import = false
  for line in normalized.split("\n") {
    let trimmed = line.trim()
    if trimmed == "import {" {
      in_import = true
    } else if in_import && trimmed == "}" {
      in_import = false
    } else if in_import && trimmed == "\"moonbitlang/core/json\"," {
      continue
    }
    lines.push(line.to_owned())
  }
  lines.join("\n")
}
