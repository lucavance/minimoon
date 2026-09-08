///|
fn embedded_script_candidate(literal : EmbeddedLiteral) -> Bool {
  if literal.kind != Quoted {
    return true
  }
  let value = embedded_literal_value(literal).trim().to_owned()
  if value == "" {
    return false
  }
  for
    prefix in [
      "const ", "let ", "var ", "function ", "import ", "export ", "module.exports",
      "exports.", "globalThis.", "App(", "Page(", "require(", "process.", "console.",
      "throw ", "if(", "if (", "for(", "for (", "return ", "() =>", "(globalThis.",
    ] {
    if value.has_prefix(prefix) {
      return true
    }
  }
  value.contains("module.exports") ||
  value.contains("globalThis.") ||
  (value.has_prefix("(") && value.contains("=>"))
}

///|
fn embedded_execution_candidate(declaration : EmbeddedDeclaration) -> Bool {
  let writes_or_executes = declaration.source.contains("write(") ||
    declaration.source.contains("write_file(") ||
    declaration.source.contains("run_checked(") ||
    declaration.source.contains("collect_output(") ||
    declaration.source.contains("supervised_check_process(")
  if !writes_or_executes {
    return false
  }
  declaration.literals.any(literal => {
    if literal.kind != Quoted {
      return false
    }
    let value = embedded_literal_value(literal)
    value == "-e" ||
    value.has_suffix(".js") ||
    value.has_suffix(".mjs") ||
    value.has_suffix(".cjs")
  })
}

///|
fn embedded_is_candidate(declaration : EmbeddedDeclaration) -> Bool {
  declaration.is_extern ||
  declaration.literals.any(embedded_script_candidate) ||
  embedded_execution_candidate(declaration)
}

///|
fn embedded_has_interpolation(payload : String) -> Bool {
  let mut index = 0
  while index < payload.length() {
    if payload[index] == '\\' {
      if scanner_starts(payload, index, "\\{") {
        return true
      }
      index += 2
    } else {
      index += 1
    }
  }
  false
}

///|
fn embedded_selected_literals(
  declaration : EmbeddedDeclaration,
  specification : EmbeddedInventoryEntry,
) -> Array[EmbeddedLiteral] raise {
  let selected : Array[EmbeddedLiteral] = []
  let prefix_hits : Map[String, Int] = Map([])
  let ignored_hits : Map[String, Int] = Map([])
  let except_hits : Map[String, Int] = Map([])
  let missed : Array[String] = []
  for item in specification.ignored_literals {
    if ignored_hits.contains(item.0) || item.1 <= 0 {
      embedded_error("invalid ignored literal selector in " + declaration.name)
    }
    ignored_hits[item.0] = 0
  }
  if specification.extraction is ExceptLiterals(values) {
    for value in values {
      if except_hits.contains(value) {
        embedded_error(
          "duplicate excluded literal selector in " + declaration.name,
        )
      }
      except_hits[value] = 0
    }
  }
  if specification.extraction is SelectedLiterals(_, prefixes) {
    for item in prefixes {
      let (prefix, count) = item
      if prefix_hits.contains(prefix) || count <= 0 {
        embedded_error("duplicate literal selector in " + declaration.name)
      }
      prefix_hits[prefix] = 0
    }
  }
  for literal in declaration.literals {
    let value = embedded_literal_value(literal)
    let keep = match specification.extraction {
      Excluded => false
      AllLiterals => true
      RawLiterals => literal.kind != Quoted
      ExceptLiterals(excluded) =>
        if excluded.contains(value) {
          except_hits[value] = except_hits[value] + 1
          false
        } else {
          true
        }
      SelectedLiterals(include_raw, prefixes) => {
        let mut matches = 0
        for item in prefixes {
          let prefix = item.0
          if literal.kind == Quoted && value.has_prefix(prefix) {
            prefix_hits[prefix] = prefix_hits[prefix] + 1
            matches += 1
          }
        }
        if matches > 1 {
          embedded_error("overlapping literal selectors in " + declaration.name)
        }
        (include_raw && literal.kind != Quoted) || matches == 1
      }
    }
    let explicitly_ignored = ignored_hits.contains(value)
    if explicitly_ignored {
      if keep {
        embedded_error(
          "overlapping selected and ignored literal in " + declaration.name,
        )
      }
      ignored_hits[value] = ignored_hits[value] + 1
    }
    if !keep &&
      !(specification.extraction is Excluded) &&
      !explicitly_ignored &&
      !except_hits.contains(value) &&
      embedded_script_candidate(literal) {
      missed.push(value)
    }
    if keep && (literal.kind != Quoted || literal.payload != "") {
      if literal.kind == InterpolatedRaw ||
        (literal.kind == Quoted && embedded_has_interpolation(literal.payload)) {
        embedded_error(
          "selected interpolated literal requires explicit decomposition in " +
          declaration.name,
        )
      }
      selected.push(literal)
    }
  }
  if specification.extraction is SelectedLiterals(_, prefixes) {
    for item in prefixes {
      let (prefix, expected) = item
      let count = prefix_hits[prefix]
      if count == 0 {
        embedded_error(
          "stale literal selector in " + declaration.name + ": " + prefix,
        )
      }
      if count != expected {
        embedded_error(
          "ambiguous literal selector in " + declaration.name + ": " + prefix,
        )
      }
    }
  }
  for item in specification.ignored_literals {
    if ignored_hits[item.0] != item.1 {
      embedded_error(
        "stale or ambiguous ignored literal selector in " +
        declaration.name +
        ": " +
        item.0,
      )
    }
  }
  for value, count in except_hits {
    if count == 0 {
      embedded_error(
        "stale excluded literal selector in " + declaration.name + ": " + value,
      )
    }
  }
  if !missed.is_empty() {
    embedded_error(
      "unclassified literal in " + declaration.name + ": " + missed[0],
    )
  }
  if !(specification.extraction is Excluded) && selected.is_empty() {
    embedded_error(
      "registered declaration contains no selected source: " + declaration.name,
    )
  }
  selected
}
