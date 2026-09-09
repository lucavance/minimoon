///|
fn valid_png_bytes(bytes : Bytes) -> Bool {
  @png.dimensions(bytes) is Some(_)
}

///|
fn resource_asset_bytes(asset : Json) -> Bytes raise {
  let path = string(asset, "path")
  let fields = object(asset, "resource asset")
  guard fields.keys().all(key => ["path", "encoding", "content"].contains(key)) else {
    raise Failure("unknown resource asset field: " + path)
  }
  guard fields.get("content") is Some(String(content)) else {
    raise Failure("resource content must be a string: " + path)
  }
  if path.has_suffix(".png") {
    guard string(asset, "encoding") == "base64" else {
      raise Failure("PNG resource requires base64 encoding: " + path)
    }
    let bytes = @base64.decode(content) catch {
      _ => raise Failure("invalid PNG base64: " + path)
    }
    guard @base64.encode(bytes) == content && valid_png_bytes(bytes) else {
      raise Failure("invalid canonical PNG resource: " + path)
    }
    bytes
  } else {
    guard string(asset, "encoding") == "utf8" else {
      raise Failure("text resource requires utf8 encoding: " + path)
    }
    @utf8.encode(content)
  }
}

///|
async fn write_resource_asset(dist : String, asset : Json) -> Unit {
  let path = string(asset, "path")
  guard valid_resource_asset_path(path) else {
    raise Failure("unsafe resource path")
  }
  let bytes = resource_asset_bytes(asset)
  let file = join(dist, path)
  if !@fs.exists(dirname(file)) {
    @fs.mkdir(dirname(file), recursive=true, permission=0o755)
  }
  @fs.write_file(file, bytes, create_mode=CreateOrTruncate, permission=0o644)
}
