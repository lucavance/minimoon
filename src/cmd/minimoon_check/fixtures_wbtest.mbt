///|
async test "artifact stability compares every text and binary file by path and exact bytes" {
  let root = @fs.tmpdir(prefix="minimoon-binary-snapshot")
  defer @fs.rmdir(root, recursive=true)
  let app = join(root, "examples/" + conformance_fixture)
  @fs.mkdir(join(app, "dist/assets"), recursive=true, permission=0o700)
  @fs.mkdir(join(app, "generated"), recursive=true, permission=0o700)
  let png_file = join(app, "dist/assets/tab.png")
  let png_bytes = b"\x89PNG\r\n\x1a\n\x00\xff\x80"
  @fs.write_file(
    png_file,
    png_bytes,
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let text_file = join(app, "generated/manifest.json")
  @fs.write_file(
    text_file,
    "{}\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let original = artifact_snapshot(root)
  assert_eq(original.length(), 2)
  assert_eq(original[0], (png_file, png_bytes))
  assert_eq(artifact_snapshot(root), original)
  @fs.write_file(
    png_file,
    png_bytes + b"\x00",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  assert_not_eq(artifact_snapshot(root), original)
  @fs.write_file(
    png_file,
    png_bytes,
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  assert_eq(artifact_snapshot(root), original)
  @fs.write_file(
    text_file,
    "{\"changed\":true}\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  assert_not_eq(artifact_snapshot(root), original)
  @fs.write_file(
    text_file,
    "{}\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let renamed = join(app, "dist/assets/selected.png")
  @fs.rename(png_file, renamed)
  assert_not_eq(artifact_snapshot(root), original)
  @fs.rename(renamed, png_file)
  assert_eq(artifact_snapshot(root), original)
}
