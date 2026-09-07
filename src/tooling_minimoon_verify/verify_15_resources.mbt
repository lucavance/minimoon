///|
fn safe_resource_asset(path : String) -> Bool {
  if !path.has_prefix("assets/") ||
    !(path.has_suffix(".svg") || path.has_suffix(".txt")) {
    return false
  }
  for segment in path.split("/") {
    if segment == "" || segment == "." || segment == ".." {
      return false
    }
    for char in segment {
      if !(char >= 'a' && char <= 'z') &&
        !(char >= 'A' && char <= 'Z') &&
        !(char >= '0' && char <= '9') &&
        char != '_' &&
        char != '-' &&
        char != '.' {
        return false
      }
    }
  }
  true
}

///|
async fn resource_assets_status(app_root : String, manifest : Json) -> Json {
  let errors : Array[String] = []
  match object(manifest, "manifest").get("resources") {
    None => ()
    Some(Array(providers)) =>
      for provider in providers {
        let id = string(provider, "id")
        if id == "" || string(provider, "version") == "" {
          errors.push("resource descriptor requires id and version")
        }
        for asset in array(provider, "assets") {
          let path = match asset {
            String(path) => path
            _ => ""
          }
          if !safe_resource_asset(path) {
            errors.push("unsafe declared resource path: " + path)
          } else {
            let file = join(app_root, "dist/" + path)
            if !@fs.exists(file) {
              errors.push("missing declared resource asset: " + path)
            } else if @fs.kind(file, follow_symlink=false) != @fs.Regular {
              errors.push(
                "declared resource asset must be a regular file: " + path,
              )
            }
          }
        }
      }
    Some(_) => errors.push("manifest resources must be an array")
  }
  status(
    "build-resources",
    errors.is_empty(),
    if errors.is_empty() {
      "declared native provider assets exist below dist/assets and participate in the artifact fingerprint"
    } else {
      errors.join("; ")
    },
  )
}
