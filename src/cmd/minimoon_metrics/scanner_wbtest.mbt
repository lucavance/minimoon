///|
test "embedded scanner distinguishes actual externs strings and comments" {
  let source = "///|\nfn text() -> String { \"extern \\\"js\\\" fn fake() = \\\"fake\\\"\" }\n" +
    "// extern \"js\" fn commented() = \"ignored\"\n" +
    "///|\n#cfg(target=\"js\")\nextern \"js\" fn real() -> Unit =\n  #|() => {}\n"
  let declarations = scan_embedded_source(source)
  assert_eq(declarations.length(), 2)
  assert_eq(declarations[0].name, "fn:text")
  assert_false(declarations[0].is_extern)
  assert_eq(declarations[1].name, "extern:real")
  assert_true(declarations[1].is_extern)
  assert_eq(declarations[1].literals.length(), 1)
  assert_eq(
    declarations[1].literals.filter(literal => literal.kind == Raw).length(),
    1,
  )
}

///|
test "embedded scanner preserves source spans and UTF8 payloads" {
  let source = "///|\r\nfn source() -> String {\r\n  #|月😀\r\n  #|\r\n}\r\n"
  let declarations = scan_embedded_source(source)
  let literals = declarations[0].literals
  assert_eq(literals.length(), 2)
  assert_eq(literals[0].line, 3)
  assert_eq(literals[0].payload, "月😀\r\n")
  assert_eq(@utf8.encode(literals[0].payload).length(), 9)
  assert_eq(source[literals[0].start:literals[0].end], literals[0].payload)
  assert_eq(literals[1].line, 4)
  assert_eq(literals[1].payload, "\r\n")
  let no_final_newline = scan_embedded_source(
    "fn source() -> String =\n #|last",
  )
  assert_eq(no_final_newline[0].literals[0].payload, "last")
}

///|
test "embedded scanner handles escaped strings and interpolation" {
  let source = "fn source() -> String { \"const value=\\\"月\\\";\\n\" }"
  let literal = scan_embedded_source(source)[0].literals[0]
  assert_eq(embedded_literal_value(literal), "const value=\"月\";\n")
  assert_true(literal.payload.contains("\\n"))
  assert_false(embedded_has_interpolation(literal.payload))
  let interpolated = scan_embedded_source(
    "fn source() -> String { \"before \\{call(\"nested\")} after\" }",
  )
  assert_eq(interpolated[0].literals.length(), 1)
  assert_true(embedded_has_interpolation(interpolated[0].literals[0].payload))
  assert_false(embedded_has_interpolation("\\\\{literal}"))
}

///|
test "embedded scanner rejects ambiguous top level declarations and recognizes commented externs" {
  let commented = "/* header */ extern \"js\" fn wake() -> Unit = \"namedBinding\""
  let declarations = scan_embedded_source(commented)
  assert_eq(declarations[0].name, "extern:wake")
  assert_true(declarations[0].is_extern)
  assert_true(embedded_is_candidate(declarations[0]))
  assert_eq(declarations[0].literals.length(), 1)
  assert_eq(embedded_literal_value(declarations[0].literals[0]), "namedBinding")
  for
    source in [
      "fn first() -> Unit { () }\nextern \"js\" fn wake() -> Unit = \"namedBinding\"",
      "fn first() -> String { \"a\" }\nfn second() -> String { \"b\" }",
    ] {
    let failed = try {
      ignore(scan_embedded_source(source))
      false
    } catch {
      _ => true
    }
    assert_true(failed)
  }
}
