///|
struct EmbeddedTotals {
  bytes : Ref[Int]
  lines : Map[String, Bool]
  files : Map[String, Bool]
  declarations : Ref[Int]
}

///|
fn embedded_totals() -> EmbeddedTotals {
  { bytes: Ref(0), lines: Map([]), files: Map([]), declarations: Ref(0), }
}

///|
fn embedded_totals_json(totals : EmbeddedTotals) -> Json {
  Json::object({
    "sourceBytes": Json::number(totals.bytes.val.to_double()),
    "sourceLines": Json::number(totals.lines.length().to_double()),
    "sourceFiles": Json::number(totals.files.length().to_double()),
    "declarations": Json::number(totals.declarations.val.to_double()),
  })
}

///|
fn embedded_add_literal(
  totals : EmbeddedTotals,
  file : String,
  literal : EmbeddedLiteral,
) -> Unit {
  totals.bytes.val += @utf8.encode(literal.payload).length()
  totals.files[file] = true
  let mut line = literal.line
  totals.lines[file + ":" + line.to_string()] = true
  let mut index = 0
  for char in literal.payload {
    index += if char.to_int() > 0xffff { 2 } else { 1 }
    if char == '\n' && index < literal.payload.length() {
      line += 1
      totals.lines[file + ":" + line.to_string()] = true
    }
  }
}

///|
fn embedded_lexical(left : String, right : String) -> Int {
  left.lexical_compare(right)
}

///|
fn embedded_metrics_with_inventory(
  sources : Array[(String, String)],
  inventory : Array[EmbeddedInventoryEntry],
) -> Json raise {
  let declarations : Map[String, EmbeddedDeclaration] = Map([])
  let source_files : Map[String, Bool] = Map([])
  let candidates : Map[String, Bool] = Map([])
  let mut literal_count = 0
  let mut raw_count = 0
  let mut extern_count = 0
  for source in sources {
    let (file, content) = source
    if source_files.contains(file) {
      embedded_error("duplicate source file: " + file)
    }
    if !file.has_suffix(".mbt") || file.has_suffix(".generated.mbt") {
      embedded_error("expected non-generated MoonBit source: " + file)
    }
    source_files[file] = true
    for declaration in scan_embedded_source(content) {
      let key = file + "\n" + declaration.name
      if declarations.contains(key) {
        // Conditional ordinary functions without script literals may share a
        // name. Candidate declarations must remain unique and selectable.
        if embedded_is_candidate(declaration) ||
          embedded_is_candidate(declarations[key]) {
          embedded_error(
            "ambiguous declaration: " + file + ":" + declaration.name,
          )
        }
      }
      declarations[key] = declaration
      literal_count += declaration.literals.length()
      raw_count += declaration.literals
        .filter(literal => literal.kind != Quoted)
        .length()
      if declaration.is_extern {
        extern_count += 1
      }
      if embedded_is_candidate(declaration) {
        candidates[key] = true
      }
    }
  }
  let registered : Map[String, Bool] = Map([])
  let errors : Array[String] = []
  for specification in inventory {
    let key = specification.file + "\n" + specification.declaration
    if registered.contains(key) {
      errors.push(
        "duplicate inventory entry: " + key.replace_all(old="\n", new=":"),
      )
    }
    registered[key] = true
    if !declarations.contains(key) {
      errors.push("stale declaration: " + key.replace_all(old="\n", new=":"))
    }
  }
  for key, _ in candidates {
    if !registered.contains(key) {
      errors.push(
        "unclassified declaration: " + key.replace_all(old="\n", new=":"),
      )
    }
  }
  errors.sort_by(embedded_lexical)
  if !errors.is_empty() {
    embedded_error(errors.join("\n"))
  }
  let totals = embedded_totals()
  let categories : Map[String, EmbeddedTotals] = Map([])
  let occupied : Map[String, Array[(Int, Int)]] = Map([])
  let entries : Array[Json] = []
  let ordered = inventory.copy()
  ordered.sort_by((left, right) => {
    let file_order = embedded_lexical(left.file, right.file)
    if file_order != 0 {
      file_order
    } else {
      embedded_lexical(left.declaration, right.declaration)
    }
  })
  for specification in ordered {
    let key = specification.file + "\n" + specification.declaration
    let declaration = declarations[key]
    let selected = embedded_selected_literals(declaration, specification)
    let own = embedded_totals()
    own.declarations.val = 1
    let category = categories.get_or_init(
      specification.category,
      embedded_totals,
    )
    category.declarations.val += 1
    for literal in selected {
      let ranges = occupied.get_or_init(specification.file, () => [])
      for range in ranges {
        if literal.start < range.1 && literal.end > range.0 {
          embedded_error("overlapping literal source intervals: " + key)
        }
      }
      ranges.push((literal.start, literal.end))
      embedded_add_literal(own, specification.file, literal)
      embedded_add_literal(category, specification.file, literal)
      embedded_add_literal(totals, specification.file, literal)
    }
    if !selected.is_empty() {
      totals.declarations.val += 1
    }
    entries.push(
      Json::object({
        "file": Json::string(specification.file),
        "declaration": Json::string(specification.declaration),
        "category": Json::string(specification.category),
        "sourceLines": Json::number(own.lines.length().to_double()),
        "sourceBytes": Json::number(own.bytes.val.to_double()),
        "literals": Json::number(selected.length().to_double()),
        "reason": Json::string(specification.reason),
      }),
    )
  }
  let category_keys = categories.keys().to_array()
  category_keys.sort_by(embedded_lexical)
  let category_json : Map[String, Json] = Map([])
  for key in category_keys {
    category_json[key] = embedded_totals_json(categories[key])
  }
  Json::object({
    "sourceLines": Json::number(totals.lines.length().to_double()),
    "sourceBytes": Json::number(totals.bytes.val.to_double()),
    "sourceFiles": Json::number(totals.files.length().to_double()),
    "categories": Json::object(category_json),
    "entries": Json::array(entries),
    "coverage": Json::object({
      "sourceFilesScanned": Json::number(source_files.length().to_double()),
      "literalsScanned": Json::number(literal_count.to_double()),
      "rawLiteralLinesScanned": Json::number(raw_count.to_double()),
      "actualJsExterns": Json::number(extern_count.to_double()),
      "candidateDeclarations": Json::number(candidates.length().to_double()),
      "registeredDeclarations": Json::number(registered.length().to_double()),
      "unclassifiedDeclarations": Json::number(0.0),
    }),
    "notes": Json::array([
      Json::string(
        "Overlapping view of MoonBit source; do not add it to file-ledger totals or compute a combined language percentage.",
      ),
      Json::string(
        "UTF-8 payload source spans, excluding delimiters/indentation; source escapes are not expanded into runtime JavaScript lines.",
      ),
      Json::string(
        "Counts each maintained location once, not generated variants or call sites; excludes generated copies, adapter mirror, and classified fixture/text literals.",
      ),
      Json::string(
        "Coverage audits raw literals, actual JS externs, script-like quoted literals, and explicit execution/write boundaries; it is not arbitrary string data-flow analysis.",
      ),
      Json::string(
        "Selected interpolated strings require static decomposition; unclassified interpolated raw literals and ambiguous top-level declaration blocks fail closed.",
      ),
    ]),
  })
}

///|
fn embedded_metrics(sources : Array[(String, String)]) -> Json raise {
  embedded_metrics_with_inventory(sources, embedded_inventory(sources))
}
