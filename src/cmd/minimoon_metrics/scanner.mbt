///|
enum EmbeddedLiteralKind {
  Quoted
  Raw
  InterpolatedRaw
} derive(Eq, Debug)

///|
struct EmbeddedLiteral {
  start : Int
  end : Int
  line : Int
  kind : EmbeddedLiteralKind
  payload : String
} derive(Debug)

///|
struct EmbeddedDeclaration {
  name : String
  source : String
  literals : Array[EmbeddedLiteral]
  is_extern : Bool
} derive(Debug)

///|
fn embedded_error(message : String) -> Unit raise {
  raise Failure::Failure("embedded JavaScript inventory: " + message)
}

///|
fn scanner_starts(source : String, index : Int, prefix : String) -> Bool {
  index < source.length() && source[index:].has_prefix(prefix)
}

///|
fn scanner_line_end(source : String, index : Int) -> Int {
  let mut end = index
  while end < source.length() && source[end] != '\n' {
    end += 1
  }
  end
}

///|
// Skip interpolated expressions without interpreting them or treating their
// strings/comments as top-level declarations. Selected JS interpolation is
// rejected later: dynamic MoonBit expression bytes are not JavaScript literals.
fn scanner_interpolation_end(source : String, start : Int) -> Int raise {
  let mut depth = 1
  let mut index = start
  while index < source.length() {
    if source[index] == '"' {
      index = scanner_quote_end(source, index + 1, '"') + 1
    } else if source[index] == '\'' {
      index = scanner_quote_end(source, index + 1, '\'') + 1
    } else if scanner_starts(source, index, "//") {
      index = scanner_line_end(source, index)
    } else if source[index] == '{' {
      depth += 1
      index += 1
    } else if source[index] == '}' {
      depth -= 1
      if depth == 0 {
        return index + 1
      }
      index += 1
    } else {
      index += 1
    }
  }
  embedded_error("unterminated string interpolation")
  start
}

///|
fn scanner_quote_end(source : String, start : Int, quote : UInt16) -> Int raise {
  let mut index = start
  while index < source.length() {
    if source[index] == quote {
      return index
    }
    if source[index] == '\\' {
      if quote == '"' && scanner_starts(source, index, "\\{") {
        index = scanner_interpolation_end(source, index + 2)
      } else {
        index += 2
      }
    } else {
      index += 1
    }
  }
  embedded_error("unterminated quoted literal")
  start
}

///|
fn scanner_function_name(line : String) -> String {
  let start = match line.find("fn") {
    Some(index) => index + 2
    None => return "unknown"
  }
  let mut index = start
  let mut brackets = 0
  while index < line.length() {
    let char = line[index]
    if char == '[' {
      brackets += 1
    } else if char == ']' {
      brackets -= 1
    } else if brackets == 0 && char != ' ' && char != '\t' {
      break
    }
    index += 1
  }
  let begin = index
  while index < line.length() &&
        line[index] != '(' &&
        line[index] != '[' &&
        line[index] != ' ' &&
        line[index] != '\t' {
    index += 1
  }
  line[begin:index].to_owned()
}

///|
fn scanner_declaration_name(source : String) -> (String, Bool) {
  let mut start = 0
  while start < source.length() {
    if source[start] == ' ' ||
      source[start] == '\t' ||
      source[start] == '\r' ||
      source[start] == '\n' {
      start += 1
    } else if scanner_starts(source, start, "//") ||
      scanner_starts(source, start, "#") {
      start = scanner_line_end(source, start)
    } else if scanner_starts(source, start, "/*") {
      start += 2
      while start < source.length() && !scanner_starts(source, start, "*/") {
        start += 1
      }
      start = (start + 2).min(source.length())
    } else {
      break
    }
  }
  for raw in source[start:].split("\n") {
    let line = raw.trim().to_owned()
    if line == "" || line.has_prefix("//") || line.has_prefix("#") {
      continue
    }
    let is_extern = line.has_prefix("extern \"js\" fn") ||
      line.has_prefix("pub extern \"js\" fn") ||
      line.has_prefix("pub(all) extern \"js\" fn")
    if is_extern {
      return ("extern:" + scanner_function_name(line), true)
    }
    if line.has_prefix("test \"") || line.has_prefix("async test \"") {
      if line.find("\"") is Some(start) && line.has_suffix(" {") {
        return ("test:" + line[start + 1:line.length() - 3].to_owned(), false)
      }
    }
    if line.has_prefix("fn ") ||
      line.has_prefix("fn[") ||
      line.has_prefix("pub fn") ||
      line.has_prefix("async fn") ||
      line.has_prefix("pub async fn") {
      return ("fn:" + scanner_function_name(line), false)
    }
    // Non-function blocks remain identifiable without pretending to parse the
    // full MoonBit grammar. A newly embedded literal here requires review.
    return ("declaration:" + line, false)
  }
  ("empty", false)
}

///|
fn scanner_add_declaration(
  result : Array[EmbeddedDeclaration],
  source : String,
  begin : Int,
  end : Int,
  literals : Array[EmbeddedLiteral],
  top_level_declarations : Int,
  actual_externs : Int,
) -> Unit raise {
  let block = source[begin:end].to_owned()
  let (name, is_extern) = scanner_declaration_name(block)
  if top_level_declarations > 1 ||
    actual_externs > 1 ||
    (actual_externs > 0 && !is_extern) {
    embedded_error(
      "ambiguous top level declarations; separate them with ///|: " + name,
    )
  }
  if name != "empty" {
    result.push({ name, source: block, literals: literals.copy(), is_extern, })
  }
  literals.clear()
}

///|
fn scanner_identifier_char(char : UInt16) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_'
}

///|
fn scanner_token_at(source : String, index : Int, token : String) -> Bool {
  scanner_starts(source, index, token) &&
  (index == 0 || !scanner_identifier_char(source[index - 1])) &&
  (
    index + token.length() == source.length() ||
    !scanner_identifier_char(source[index + token.length()])
  )
}

///|
fn scanner_named_function_at(source : String, index : Int) -> Bool {
  let mut next = index + 2
  let mut brackets = 0
  while next < source.length() {
    let char = source[next]
    if char == '[' {
      brackets += 1
    } else if char == ']' {
      brackets -= 1
    } else if brackets == 0 &&
      char != ' ' &&
      char != '\t' &&
      char != '\n' &&
      char != '\r' {
      return scanner_identifier_char(char)
    }
    next += 1
  }
  false
}

///|
fn scan_embedded_source(source : String) -> Array[EmbeddedDeclaration] raise {
  let result : Array[EmbeddedDeclaration] = []
  let literals : Array[EmbeddedLiteral] = []
  let mut index = 0
  let mut line = 1
  let mut line_start = 0
  let mut block_start = 0
  let mut brace_depth = 0
  let mut top_level_declarations = 0
  let mut actual_externs = 0
  while index < source.length() {
    if source[index] == '\n' {
      line += 1
      index += 1
      line_start = index
    } else if scanner_starts(source, index, "//") {
      let end = scanner_line_end(source, index)
      if source[line_start:index].trim() == "" &&
        source[index:end].trim() == "///|" {
        scanner_add_declaration(
          result, source, block_start, index, literals, top_level_declarations, actual_externs,
        )
        block_start = end
        top_level_declarations = 0
        actual_externs = 0
      }
      index = end
    } else if scanner_starts(source, index, "/*") {
      let begin = index
      index += 2
      while index < source.length() && !scanner_starts(source, index, "*/") {
        if source[index] == '\n' {
          line += 1
          line_start = index + 1
        }
        index += 1
      }
      if index >= source.length() {
        embedded_error("unterminated comment at offset " + begin.to_string())
      }
      index += 2
    } else if scanner_starts(source, index, "#|") ||
      scanner_starts(source, index, "$|") {
      let end = scanner_line_end(source, index)
      let payload_end = if end < source.length() { end + 1 } else { end }
      literals.push({
        start: index + 2,
        end: payload_end,
        line,
        kind: if source[index] == '$' {
          InterpolatedRaw
        } else {
          Raw
        },
        payload: source[index + 2:payload_end].to_owned(),
      })
      index = end
    } else if source[index] == '"' || source[index] == '\'' {
      let quote = source[index]
      let end = scanner_quote_end(source, index + 1, quote)
      let prefix = source[block_start:index].trim_end()
      let metadata = quote == '"' &&
        (
          source[line_start:index].trim_start().has_prefix("#") ||
          (
            brace_depth == 0 &&
            (prefix.has_suffix("extern") || prefix.has_suffix("test"))
          )
        )
      if quote == '"' && !metadata {
        literals.push({
          start: index + 1,
          end,
          line,
          kind: Quoted,
          payload: source[index + 1:end].to_owned(),
        })
      }
      while index <= end {
        if source[index] == '\n' {
          line += 1
          line_start = index + 1
        }
        index += 1
      }
    } else {
      if brace_depth == 0 {
        if scanner_token_at(source, index, "fn") &&
          scanner_named_function_at(source, index) {
          top_level_declarations += 1
        }
        if scanner_token_at(source, index, "test") &&
          source[index + 4:].trim_start().has_prefix("\"") {
          top_level_declarations += 1
        }
        if scanner_token_at(source, index, "extern") &&
          source[index + 6:].trim_start().has_prefix("\"js\"") {
          actual_externs += 1
        }
      }
      if source[index] == '{' {
        brace_depth += 1
      } else if source[index] == '}' {
        brace_depth -= 1
      }
      index += 1
    }
  }
  scanner_add_declaration(
    result,
    source,
    block_start,
    source.length(),
    literals,
    top_level_declarations,
    actual_externs,
  )
  result
}

///|
fn embedded_literal_value(literal : EmbeddedLiteral) -> String {
  if literal.kind != Quoted {
    return literal.payload
  }
  let parsed = @json.parse("\"" + literal.payload + "\"") catch {
    _ => return literal.payload
  }
  match parsed {
    String(value) => value
    _ => literal.payload
  }
}
