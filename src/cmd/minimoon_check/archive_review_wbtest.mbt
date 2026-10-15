///|
fn archive_listing(rows : String) -> String {
  "Archive: /tmp/candidate with spaces.zip\n" +
  " Length   Method    Size  Cmpr    Date    Time   CRC-32   Name\n" +
  "--------  ------  ------- ---- ---------- ----- --------  ----\n" +
  rows +
  "--------          -------  ---                            -------\n"
}

///|
test "archive inventory reads stored and deflated members without losing path spaces" {
  // unzip uses a different closing separator from its opening one.
  let listing = archive_listing(
    "    4 Stored 4 0% 1980-01-01 00:00 00000000 src/space name.mbt\n" +
    "    9 Defl:N 3 67% 1980-01-01 00:00 00000000 moon.mod\n",
  )
  assert_eq(archive_members(listing, ["src/space name.mbt", "moon.mod"]), [
    { path: "moon.mod", uncompressed_bytes: 9, compressed_bytes: 3, },
    { path: "src/space name.mbt", uncompressed_bytes: 4, compressed_bytes: 4, },
  ])
}

///|
test "archive inventory rejects incomplete malformed duplicate or mismatched tables" {
  let row = "    9 Defl:N 3 67% 1980-01-01 00:00 00000000 moon.mod\n"
  for
    listing in [
      "",
      archive_listing(""),
      archive_listing("broken row\n"),
      archive_listing(row + row),
      archive_listing(row).replace(old="moon.mod", new="unexpected.mbt"),
      archive_listing(row).replace(old="9 Defl:N", new="-1 Defl:N"),
      archive_listing(row).replace(old="N 3", new="N -1"),
      archive_listing(row).replace(old="N 3", new="N invalid"),
      archive_listing(row).replace(
        old="--------          -------  ---                            -------",
        new="",
      ),
    ] {
    let rejected = try {
      ignore(archive_members(listing, ["moon.mod"]))
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  let rejected = try {
    ignore(archive_members(archive_listing(row), ["moon.mod", "moon.mod"]))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
}

///|
test "archive review reconciles compression metadata groups hashes and budget boundaries" {
  let entries : Array[ArchiveMember] = [
    { path: "src/b.mbt", uncompressed_bytes: 4, compressed_bytes: 1, },
    { path: "moon.mod", uncompressed_bytes: 1, compressed_bytes: 0, },
    { path: "src/a.mbt", uncompressed_bytes: 6, compressed_bytes: 1, },
  ]
  let report = archive_review_report(
    "test/module", "0.0.1", "candidate.zip", b"abc", entries, 5, 2,
  )
  assert_eq(json_string(report, "status"), "passed")
  assert_eq(
    json_string(report, "archiveSha256"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  json_inspect(json_field(report, "totals"), content={
    "files": 3,
    "archiveBytes": 3,
    "uncompressedBytes": 11,
    "compressedPayloadBytes": 2,
    "zipMetadataBytes": 1,
  })
  json_inspect(json_field(report, "groups"), content=[
    {
      "key": "metadata",
      "files": 1,
      "uncompressedBytes": 1,
      "compressedBytes": 0,
    },
    { "key": "src", "files": 2, "uncompressedBytes": 10, "compressedBytes": 2 },
  ])
  guard json_field(report, "largestFiles") is Array(largest) else {
    fail("largest files must be an array")
  }
  assert_eq(largest.map(entry => json_string(entry, "path")), [
    "src/a.mbt", "src/b.mbt", "moon.mod",
  ])
  assert_eq(
    report,
    archive_review_report(
      "test/module",
      "0.0.1",
      "candidate.zip",
      b"abc",
      entries.rev(),
      5,
      2,
    ),
  )
  let over = archive_review_report(
    "test/module", "0.0.1", "candidate.zip", b"abc", entries, 4, 2,
  )
  assert_eq(json_string(over, "status"), "failed")
  json_inspect(json_field(over, "budget"), content={
    "hardLimitBytes": 4,
    "reserveBytes": 2,
    "operatingLimitBytes": 2,
    "operatingHeadroomBytes": -1,
    "hardLimitHeadroomBytes": 1,
  })
}

///|
test "archive review separates documentation and package owners and bounds top files" {
  assert_eq(archive_member_group("docs/guides/http.md"), "docs")
  assert_eq(
    archive_member_group("src/cmd/minimoon/main.mbt"),
    "src/cmd/minimoon",
  )
  assert_eq(archive_member_group("src/theme/theme.mbt"), "src/theme")
  let entries : Array[ArchiveMember] = []
  for index in 0..<25 {
    entries.push({
      path: "src/file" + index.to_string() + ".mbt",
      uncompressed_bytes: index,
      compressed_bytes: index,
    })
  }
  let report = archive_review_report(
    "test/module",
    "0.0.1",
    "candidate.zip",
    Bytes::make(400, 0),
    entries,
    500,
    100,
  )
  guard json_field(report, "largestFiles") is Array(largest) else {
    fail("largest files must be an array")
  }
  assert_eq(largest.length(), 20)
  assert_eq(json_string(largest[0], "path"), "src/file24.mbt")
  assert_eq(json_string(largest[19], "path"), "src/file5.mbt")
  assert_eq(json_field(json_field(report, "totals"), "files"), Json::number(25))
}

///|
test "archive review rejects impossible totals and invalid reserves" {
  for
    (entries, hard_limit, reserve) in [
      (
        [{ path: "moon.mod", uncompressed_bytes: 1, compressed_bytes: 4, }],
        5,
        2,
      ),
      (
        [{ path: "moon.mod", uncompressed_bytes: -1, compressed_bytes: 1, }],
        5,
        2,
      ),
      (
        [{ path: "moon.mod", uncompressed_bytes: 1, compressed_bytes: -1, }],
        5,
        2,
      ),
      ([], 1, 2),
      ([], 5, -1),
    ] {
    let rejected = try {
      ignore(
        archive_review_report(
          "test/module", "0.0.1", "candidate.zip", b"abc", entries, hard_limit, reserve,
        ),
      )
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
}

///|
async test "archive report inspects real ZIP bytes and persists over-budget diagnostics" {
  let root = @env.current_dir().unwrap()
  let base = create_check_temporary(
    join(root, "_build/check-tmp-tests"),
    "test",
  )
  errdefer @fs.rmdir(base, recursive=true)
  write_ui_consumer_file(base, "moon.mod", "name = \"test/archive\"\n")
  write_ui_consumer_file(base, "src/space name.mbt", "MoonBit ".repeat(100))
  write_ui_consumer_file(base, "src/empty.mbt", "")
  let paths = ["moon.mod", "src/space name.mbt", "src/empty.mbt"]
  let archive = join(base, "candidate with spaces.zip")
  let (code, _, _) = @toolchain.collect_output(
    "zip",
    ["-X", "-q", archive, ..paths],
    cwd=base,
  )
  assert_eq(code, 0)
  write_archive_review(
    base, "core", "test/archive", "0.0.1", archive, paths, 4096, 1024,
  )
  let report = read_json(base, "_build/package-review/core.json")
  assert_eq(json_string(report, "status"), "passed")
  assert_eq(json_string(report, "archive"), "candidate with spaces.zip")
  assert_eq(json_field(json_field(report, "totals"), "files"), Json::number(3))
  let size = @fs.read_file(archive).binary().length()
  assert_eq(
    json_field(json_field(report, "totals"), "archiveBytes"),
    archive_number(size),
  )
  write_archive_review(
    base, "core", "test/archive", "0.0.1", archive, paths, size, 1,
  )
  let failed = read_json(base, "_build/package-review/core.json")
  assert_eq(json_string(failed, "status"), "failed")
  assert_eq(
    json_field(json_field(failed, "budget"), "operatingHeadroomBytes"),
    archive_number(-1),
  )
  @fs.rmdir(base, recursive=true)
}
