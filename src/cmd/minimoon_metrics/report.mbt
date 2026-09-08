///|
struct FileTotals {
  mut files : Int
  mut bytes : Int
  mut physical_lines : Int
  mut text_files : Int
  mut binary_files : Int
} derive(Debug)

///|
fn empty_file_totals() -> FileTotals {
  { files: 0, bytes: 0, physical_lines: 0, text_files: 0, binary_files: 0, }
}

///|
fn add_file_total(totals : FileTotals, entry : FileMetric) -> Unit {
  totals.files = totals.files + 1
  totals.bytes = totals.bytes + entry.bytes
  match entry.physical_lines {
    Some(lines) => {
      totals.text_files = totals.text_files + 1
      totals.physical_lines = totals.physical_lines + lines
    }
    None => totals.binary_files = totals.binary_files + 1
  }
}

///|
fn total_files(entries : Array[FileMetric]) -> FileTotals {
  let totals = empty_file_totals()
  for entry in entries {
    add_file_total(totals, entry)
  }
  totals
}

///|
fn metrics_number(value : Int) -> Json {
  Json::number(value.to_double())
}

///|
fn totals_fields(totals : FileTotals) -> Map[String, Json] {
  {
    "files": metrics_number(totals.files),
    "bytes": metrics_number(totals.bytes),
    "physicalLines": metrics_number(totals.physical_lines),
    "textFiles": metrics_number(totals.text_files),
    "binaryFiles": metrics_number(totals.binary_files),
  }
}

///|
fn file_groups(
  entries : Array[FileMetric],
  key : (FileMetric) -> String,
) -> Json {
  let groups : Map[String, FileTotals] = Map([])
  for entry in entries {
    let name = key(entry)
    let totals = match groups.get(name) {
      Some(value) => value
      None => {
        let value = empty_file_totals()
        groups[name] = value
        value
      }
    }
    add_file_total(totals, entry)
  }
  let names = groups.keys().collect()
  names.sort_by((left, right) => left.lexical_compare(right))
  Json::array(
    names.map(name => {
      let fields = totals_fields(groups[name])
      fields["key"] = Json::string(name)
      Json::object(fields)
    }),
  )
}

///|
fn file_entry_json(entry : FileMetric) -> Json {
  Json::object({
    "path": Json::string(entry.path),
    "owner": Json::string(entry.owner),
    "area": entry.area.map(Json::string).unwrap_or(Json::null()),
    "role": Json::string(entry.role),
    "language": Json::string(entry.language),
    "bytes": metrics_number(entry.bytes),
    "physicalLines": entry.physical_lines
    .map(metrics_number)
    .unwrap_or(Json::null()),
    "encoding": Json::string(
      if entry.physical_lines is Some(_) {
        "utf8"
      } else {
        "binary"
      },
    ),
  })
}

///|
fn file_ledger_json(ledger : FileLedger) -> Json {
  Json::object({
    "totals": Json::object(totals_fields(total_files(ledger.entries))),
    "byOwner": file_groups(ledger.entries, entry => entry.owner),
    "byRole": file_groups(ledger.entries, entry => entry.role),
    "byLanguage": file_groups(ledger.entries, entry => entry.language),
    "coreBreakdown": file_groups(
      ledger.entries.filter(entry => entry.owner == "core"),
      entry => entry.area.unwrap(),
    ),
    "entries": Json::array(ledger.entries.map(file_entry_json)),
    "missing": Json::array(ledger.missing.map(Json::string)),
  })
}

///|
fn metrics_report(
  ledger : FileLedger,
  embedded : Json,
  include_untracked : Bool,
) -> Json {
  Json::object({
    "schemaVersion": metrics_number(2),
    "scope": Json::object({
      "selection": Json::string(
        if include_untracked {
          "tracked-and-untracked"
        } else {
          "tracked"
        },
      ),
      "includeUntracked": Json::boolean(include_untracked),
      "content": Json::string("working-tree"),
      "selectedFiles": metrics_number(
        ledger.entries.length() + ledger.missing.length(),
      ),
      "lineRule": Json::string(
        "LF-delimited physical lines, including a final unterminated line; CRLF bytes are not normalized",
      ),
      "textRule": Json::string(
        "strict UTF-8 without NUL bytes; binary files have null physicalLines",
      ),
      "embeddedRule": Json::string(
        "overlapping source payload ledger; never add embedded counts to file totals",
      ),
      "snapshotRule": Json::string(
        "api_snapshot includes frozen interfaces, manifests and consumer fixtures under the reviewed API baseline directory",
      ),
      "fileRule": Json::string(
        "regular files only; symlinks and other nonregular entries are rejected without following them",
      ),
    }),
    "files": file_ledger_json(ledger),
    "embeddedScripts": embedded,
  })
}

///|
fn print_metrics_report(
  ledger : FileLedger,
  embedded : Json,
  include_untracked : Bool,
) -> Unit {
  for line in metrics_summary_lines(ledger, embedded, include_untracked) {
    println(line)
  }
}

///|
fn file_summary_group(
  label : String,
  groups : Json,
  lines : Array[String],
) -> Unit {
  lines.push(label + ":")
  guard groups is Array(entries) else {
    abort("invalid metrics summary groups")
  }
  for entry in entries {
    guard entry is Object(fields) && fields["key"] is String(key) else {
      abort("invalid metrics summary group")
    }
    lines.push(
      "  " +
      key +
      ": " +
      fields["files"].stringify() +
      " files, " +
      fields["bytes"].stringify() +
      " bytes, " +
      fields["physicalLines"].stringify() +
      " text lines",
    )
  }
}

///|
fn metrics_summary_lines(
  ledger : FileLedger,
  embedded : Json,
  include_untracked : Bool,
) -> Array[String] {
  let totals = total_files(ledger.entries)
  let selection = if include_untracked {
    "tracked + untracked"
  } else {
    "tracked only"
  }
  let lines = [
    "Minimoon metrics v2 (working-tree bytes; " + selection + ")",
    "Files: \{totals.files}; bytes: \{totals.bytes}; text physical lines: \{totals.physical_lines}",
    "Text files: \{totals.text_files}; binary files: \{totals.binary_files}; missing: \{ledger.missing.length()}",
  ]
  file_summary_group(
    "Owners",
    file_groups(ledger.entries, entry => entry.owner),
    lines,
  )
  file_summary_group(
    "Core areas",
    file_groups(ledger.entries.filter(entry => entry.owner == "core"), entry => {
      entry.area.unwrap()
    }),
    lines,
  )
  file_summary_group(
    "Roles",
    file_groups(ledger.entries, entry => entry.role),
    lines,
  )
  file_summary_group(
    "Languages",
    file_groups(ledger.entries, entry => entry.language),
    lines,
  )
  guard embedded is Object(fields) else { abort("invalid embedded metrics") }
  lines.push(
    "Embedded scripts (overlapping source ledger, not extra file lines): " +
    fields["sourceLines"].stringify() +
    " source lines, " +
    fields["sourceBytes"].stringify() +
    " source bytes",
  )
  if fields.get("categories") is Some(Object(categories)) {
    let keys = categories.keys().collect()
    keys.sort_by((left, right) => left.lexical_compare(right))
    for key in keys {
      guard categories[key] is Object(category) else {
        abort("invalid embedded category")
      }
      lines.push(
        "  " +
        key +
        ": " +
        category["sourceLines"].stringify() +
        " source lines, " +
        category["sourceBytes"].stringify() +
        " source bytes",
      )
    }
  }
  lines.push(
    "Use --json for complete file entries, missing paths, embedded inventory and accounting rules.",
  )
  lines
}
