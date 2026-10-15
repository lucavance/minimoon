///|
struct ArchiveMember {
  path : String
  uncompressed_bytes : Int32
  compressed_bytes : Int32
} derive(Debug, Eq)

///|
// Info-ZIP is already required by the distribution gates. Read its actual
// member sizes, then require exact parity with moon package's path inventory.
fn archive_members(
  listing : String,
  expected_paths : Array[String],
) -> Array[ArchiveMember] raise {
  let separator = "--------  ------  ------- ---- ---------- ----- --------  ----"
  let entries : Array[ArchiveMember] = []
  let seen : Map[String, Bool] = Map([])
  let mut separators = 0
  for line in listing.split("\n") {
    if separators == 0 && line.trim() == separator {
      separators = 1
      continue
    }
    if separators == 1 &&
      line.trim() ==
      "--------          -------  ---                            -------" {
      separators = 2
      continue
    }
    if separators != 1 {
      continue
    }
    let columns : Array[String] = []
    let mut remaining = line.trim_start()
    for _ in 0..<7 {
      guard remaining.split_once(" ") is Some((column, rest)) else {
        raise Failure("unsupported unzip member listing: " + line.to_owned())
      }
      columns.push(column.to_owned())
      remaining = rest.trim_start()
    }
    let path = remaining.to_owned()
    let uncompressed_bytes = @string.parse_int(columns[0], base=10)
    let compressed_bytes = @string.parse_int(columns[2], base=10)
    guard path != "" &&
      uncompressed_bytes >= 0 &&
      compressed_bytes >= 0 &&
      !seen.contains(path) else {
      raise Failure("invalid or duplicate ZIP member: " + path)
    }
    seen[path] = true
    entries.push({ path, uncompressed_bytes, compressed_bytes, })
  }
  guard separators == 2 && !entries.is_empty() else {
    raise Failure("unzip did not report a complete member table")
  }
  let actual = entries.map(entry => entry.path)
  let expected = expected_paths.copy()
  actual.sort()
  expected.sort()
  guard actual == expected else {
    raise Failure("ZIP members differ from moon package's path inventory")
  }
  entries.sort_by((left, right) => left.path.lexical_compare(right.path))
  entries
}

///|
fn archive_member_group(path : String) -> String {
  if path.has_prefix("src/") {
    Path::dirname(path).to_string()
  } else if path.has_prefix("docs/") {
    "docs"
  } else {
    "metadata"
  }
}

///|
fn archive_number(value : Int32) -> Json {
  Json::number(value.to_double())
}

///|
fn archive_member_json(entry : ArchiveMember) -> Json {
  Json::object({
    "path": Json::string(entry.path),
    "group": Json::string(archive_member_group(entry.path)),
    "uncompressedBytes": archive_number(entry.uncompressed_bytes),
    "compressedBytes": archive_number(entry.compressed_bytes),
  })
}

///|
fn archive_review_report(
  module_name : String,
  version : String,
  archive_name : String,
  archive : Bytes,
  entries : Array[ArchiveMember],
  hard_limit : Int32,
  reserve : Int32,
) -> Json raise {
  guard hard_limit >= reserve && reserve >= 0 else {
    raise Failure("invalid archive budget")
  }
  let files = entries.copy()
  files.sort_by((left, right) => left.path.lexical_compare(right.path))
  let groups : Map[String, (Int32, Int32, Int32)] = Map([])
  let mut uncompressed = 0
  let mut compressed = 0
  for entry in files {
    guard entry.uncompressed_bytes >= 0 &&
      entry.compressed_bytes >= 0 &&
      entry.compressed_bytes <= archive.length() - compressed &&
      entry.uncompressed_bytes <= 0x7fffffff - uncompressed else {
      raise Failure("invalid archive member byte totals")
    }
    uncompressed += entry.uncompressed_bytes
    compressed += entry.compressed_bytes
    let key = archive_member_group(entry.path)
    let (count, raw, packed) = groups.get(key).unwrap_or((0, 0, 0))
    groups[key] = (
      count + 1,
      raw + entry.uncompressed_bytes,
      packed + entry.compressed_bytes,
    )
  }
  let group_names = groups.keys().collect()
  group_names.sort_by((left, right) => left.lexical_compare(right))
  let largest = files.copy()
  largest.sort_by((left, right) => {
    if left.compressed_bytes == right.compressed_bytes {
      left.path.lexical_compare(right.path)
    } else {
      right.compressed_bytes - left.compressed_bytes
    }
  })
  let operating_limit = hard_limit - reserve
  Json::object({
    "schemaVersion": archive_number(1),
    "module": Json::string(module_name),
    "version": Json::string(version),
    "archive": Json::string(archive_name),
    "archiveSha256": Json::string(
      @crypto.bytes_to_hex_string(@crypto.sha256(archive)),
    ),
    "status": Json::string(
      if byte_budget_allows(archive.length(), operating_limit) {
        "passed"
      } else {
        "failed"
      },
    ),
    "budget": Json::object({
      "hardLimitBytes": archive_number(hard_limit),
      "reserveBytes": archive_number(reserve),
      "operatingLimitBytes": archive_number(operating_limit),
      "operatingHeadroomBytes": archive_number(
        operating_limit - archive.length(),
      ),
      "hardLimitHeadroomBytes": archive_number(hard_limit - archive.length()),
    }),
    "totals": Json::object({
      "files": archive_number(files.length()),
      "archiveBytes": archive_number(archive.length()),
      "uncompressedBytes": archive_number(uncompressed),
      "compressedPayloadBytes": archive_number(compressed),
      "zipMetadataBytes": archive_number(archive.length() - compressed),
    }),
    "groups": Json::array(
      group_names.map(key => {
        let (count, raw, packed) = groups[key]
        Json::object({
          "key": Json::string(key),
          "files": archive_number(count),
          "uncompressedBytes": archive_number(raw),
          "compressedBytes": archive_number(packed),
        })
      }),
    ),
    "largestFiles": Json::array(
      largest[:Int32::min(20, largest.length())].map(archive_member_json),
    ),
    "files": Json::array(files.map(archive_member_json)),
  })
}

///|
async fn write_archive_review(
  root : String,
  label : String,
  module_name : String,
  version : String,
  archive : String,
  paths : Array[String],
  hard_limit : Int32,
  reserve : Int32,
) -> Unit {
  let (code, stdout, stderr) = @toolchain.collect_output(
    "unzip",
    ["-v", archive],
    cwd=root,
    extra_env={ "LC_ALL": "C" },
  )
  guard code == 0 && stderr.text() == "" else {
    raise Failure("failed to inspect archive: " + stdout.text() + stderr.text())
  }
  let report = archive_review_report(
    module_name,
    version,
    Path::basename(archive).to_owned(),
    @fs.read_file(archive).binary(),
    archive_members(stdout.text(), paths),
    hard_limit,
    reserve,
  )
  let directory = join(root, "_build/package-review")
  if !@fs.exists(directory) {
    @fs.mkdir(directory, permission=0o700, recursive=true)
  }
  let output = join(directory, label + ".json")
  @fs.write_file(
    output,
    report.stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  println("archive size report: _build/package-review/" + label + ".json")
}
