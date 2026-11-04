///|
fn api_interface_tokens(source : String) -> Array[(Int32, Int32)] {
  let tokens : Array[(Int32, Int32)] = []
  let mut index = 0
  while index < source.length() {
    let start = index
    let char = source[index]
    index += 1
    if char == ' ' || char == '\n' || char == '\r' || char == '\t' {
      continue
    }
    if char == '/' && index < source.length() && source[index] == '/' {
      while index < source.length() && source[index] != '\n' {
        index += 1
      }
      continue
    } else if char == '"' {
      while index < source.length() {
        let next = source[index]
        index += 1
        if next == '\\' && index < source.length() {
          index += 1
        } else if next == '"' {
          break
        }
      }
    } else if moon_identifier_character(char) {
      while index < source.length() && moon_identifier_character(source[index]) {
        index += 1
      }
    }
    tokens.push((start, index))
  }
  tokens
}

///|
fn api_interface_token(
  source : String,
  tokens : Array[(Int32, Int32)],
  index : Int32,
) -> String {
  if index < 0 || index >= tokens.length() {
    ""
  } else {
    let (start, end) = tokens[index]
    source[start:end].to_owned()
  }
}

///|
// The current compiler prints the existing builtin Int alias as Int32. Only
// type-position tokens are normalized: strings, qualified names and declarations stay exact.
// A local type or generic binding with either name disables this normalization.
fn api_integer_alias(source : String) -> String {
  let tokens = api_interface_tokens(source)
  let token = fn(i : Int32) { api_interface_token(source, tokens, i) }
  let mut generic = false
  for i in 0..<tokens.length() {
    let current = token(i)
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
    if (current == "Int" || current == "Int32") &&
      (generic || ["type", "struct", "enum", "trait"].contains(token(i - 1))) {
      return source
    }
  }
  let builder = StringBuilder()
  let mut copied = 0
  let mut type_nesting = 0
  for i, (start, end) in tokens {
    if token(i) == "(" || token(i) == "[" {
      type_nesting += 1
    }
    if token(i) == ")" || token(i) == "]" {
      type_nesting -= 1
    }
    if token(i) == "Int" &&
      [":", "(", "[", ",", ">", "="].contains(token(i - 1)) &&
      (token(i - 1) != "," || type_nesting > 0) &&
      token(i + 1) != ":" {
      builder.write_string(source[copied:start].to_owned())
      builder.write_string("Int32")
      copied = end
    }
  }
  builder.write_string(source[copied:].to_owned())
  builder.to_string()
}
