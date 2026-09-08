///|
fn metrics_embedded_problems(
  embedded : Json,
  files : Array[Json],
) -> Array[String] {
  let errors : Array[String] = []
  guard metrics_field(embedded, "entries") is Some(Array(entries)) &&
    metrics_field(embedded, "categories") is Some(Object(categories)) &&
    metrics_field(embedded, "coverage") is Some(coverage) else {
    return ["embedded metrics entries, categories or coverage are missing"]
  }
  let ids : Map[String, Bool] = Map([])
  let source_files : Map[String, Bool] = Map([])
  let category_entries : Map[String, Array[Json]] = Map([])
  let mut source_bytes = 0
  let mut source_lines = 0
  let mut maximum_lines = 0
  let mut literals = 0
  for entry in entries {
    guard metrics_text(entry, "file") is Some(file) &&
      metrics_text(entry, "declaration") is Some(declaration) &&
      metrics_text(entry, "category") is Some(category) &&
      metrics_count(metrics_field(entry, "sourceBytes")) is Some(bytes) &&
      metrics_count(metrics_field(entry, "sourceLines")) is Some(lines) &&
      metrics_count(metrics_field(entry, "literals")) is Some(count) else {
      errors.push("embedded metrics entry is incomplete")
      continue
    }
    let id = file + "\u{0000}" + declaration
    if ids.contains(id) {
      errors.push("duplicate embedded metrics declaration")
    }
    ids[id] = true
    if !files.any(value => {
        metrics_text(value, "path") == Some(file) &&
        file.has_suffix(".mbt") &&
        metrics_text(value, "encoding") == Some("utf8") &&
        metrics_text(value, "role") != Some("generated_artifact") &&
        metrics_text(value, "role") != Some("api_snapshot")
      }) {
      errors.push(
        "embedded metrics file is outside the selected source ledger: " + file,
      )
    }
    if !["production", "validation", "test", "example", "excluded"].contains(
        category,
      ) {
      errors.push("unknown embedded metrics category: " + category)
    }
    if category == "excluded" && (bytes != 0 || lines != 0 || count != 0) {
      errors.push("excluded embedded source must not enter maintained totals")
    }
    category_entries.get_or_init(category, () => []).push(entry)
    source_bytes += bytes
    source_lines += lines
    if lines > maximum_lines {
      maximum_lines = lines
    }
    literals += count
    if lines > 0 {
      source_files[file] = true
    }
  }
  if metrics_count(metrics_field(embedded, "sourceBytes")) != Some(source_bytes) ||
    metrics_count(metrics_field(embedded, "sourceFiles")) !=
    Some(source_files.length()) {
    errors.push("embedded metrics byte or file totals differ from entries")
  }
  // Physical source lines can overlap; unlike bytes, never sum category line
  // counts into a claimed disjoint repository language total.
  match metrics_count(metrics_field(embedded, "sourceLines")) {
    Some(lines) if lines >= maximum_lines && lines <= source_lines => ()
    _ => errors.push("embedded metrics source line union is out of bounds")
  }
  if categories.length() != category_entries.length() {
    errors.push("embedded metrics category inventory differs from entries")
  }
  for name, values in category_entries {
    guard categories.get(name) is Some(category) else {
      errors.push("missing embedded metrics category: " + name)
      continue
    }
    let mut bytes = 0
    let mut lines = 0
    let mut maximum = 0
    let names : Map[String, Bool] = Map([])
    for entry in values {
      let entry_lines = metrics_count(metrics_field(entry, "sourceLines")).unwrap()
      bytes += metrics_count(metrics_field(entry, "sourceBytes")).unwrap()
      lines += entry_lines
      if entry_lines > maximum {
        maximum = entry_lines
      }
      if entry_lines > 0 {
        names[metrics_text(entry, "file").unwrap()] = true
      }
    }
    if metrics_count(metrics_field(category, "sourceBytes")) != Some(bytes) ||
      metrics_count(metrics_field(category, "sourceFiles")) !=
      Some(names.length()) ||
      metrics_count(metrics_field(category, "declarations")) !=
      Some(values.length()) {
      errors.push("embedded metrics category totals differ: " + name)
    }
    match metrics_count(metrics_field(category, "sourceLines")) {
      Some(count) if count >= maximum && count <= lines => ()
      _ =>
        errors.push(
          "embedded metrics category line union is out of bounds: " + name,
        )
    }
  }
  let source_count = files
    .filter(value => {
      metrics_text(value, "path")
      .map(path => path.has_suffix(".mbt"))
      .unwrap_or(false) &&
      metrics_text(value, "encoding") == Some("utf8") &&
      metrics_text(value, "role") != Some("generated_artifact") &&
      metrics_text(value, "role") != Some("api_snapshot")
    })
    .length()
  if metrics_count(metrics_field(coverage, "sourceFilesScanned")) !=
    Some(source_count) ||
    metrics_count(metrics_field(coverage, "registeredDeclarations")) !=
    Some(entries.length()) ||
    metrics_count(metrics_field(coverage, "unclassifiedDeclarations")) !=
    Some(0) {
    errors.push(
      "embedded metrics coverage differs from the selected source inventory",
    )
  }
  match metrics_count(metrics_field(coverage, "literalsScanned")) {
    Some(count) if count >= literals => ()
    _ => errors.push("embedded metrics literal coverage is incomplete")
  }
  errors
}
