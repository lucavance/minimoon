///|
fn valid_resource_package(value : String) -> Bool {
  let parts = value.split("/").collect()
  if parts.length() < 2 {
    return false
  }
  for part in parts {
    if part == "" {
      return false
    }
    for char in part {
      if !(char >= 'a' && char <= 'z') &&
        !(char >= 'A' && char <= 'Z') &&
        !(char >= '0' && char <= '9') &&
        char != '_' &&
        char != '-' {
        return false
      }
    }
  }
  true
}

///|
fn resource_config_issues(raw : Json) -> Array[(String, String)] {
  let issues : Array[(String, String)] = []
  match object(raw, "MiniApp config").get("resources") {
    None => ()
    Some(Array(providers)) => {
      let packages : Set[String] = Set([])
      for index, provider in providers {
        let pointer = "/resources/" + index.to_string()
        match provider {
          Object(fields) => {
            for key in fields.keys() {
              if key != "package" && key != "features" {
                issues.push(
                  (pointer + "/" + key, "unknown resource provider field"),
                )
              }
            }
            match fields.get("package") {
              Some(String(package_path)) if valid_resource_package(package_path) => {
                if packages.contains(package_path) {
                  issues.push(
                    (pointer + "/package", "duplicate resource provider"),
                  )
                }
                packages.add(package_path)
              }
              _ =>
                issues.push(
                  (
                    pointer + "/package",
                    "resource package must be a full MoonBit import path",
                  ),
                )
            }
            match fields.get("features") {
              None => ()
              Some(Array(features)) =>
                for feature_index, feature in features {
                  match feature {
                    String(value) if value.trim() == value && value != "" => ()
                    _ =>
                      issues.push(
                        (
                          pointer + "/features/" + feature_index.to_string(),
                          "resource feature must be a non-empty trimmed string",
                        ),
                      )
                  }
                }
              Some(_) =>
                issues.push(
                  (pointer + "/features", "resource features must be an array"),
                )
            }
          }
          _ => issues.push((pointer, "resource provider must be an object"))
        }
      }
    }
    Some(_) => issues.push(("/resources", "resources must be an array"))
  }
  issues
}

///|
fn resource_features(provider : Json) -> Array[String] {
  let values : Array[String] = []
  match object(provider, "resource provider").get("features") {
    Some(Array(features)) =>
      for feature in features {
        if feature is String(value) && !values.contains(value) {
          values.push(value)
        }
      }
    _ => ()
  }
  values.sort()
  values
}

///|
fn valid_resource_asset_path(value : String) -> Bool {
  if !value.has_prefix("assets/") ||
    !(value.has_suffix(".svg") ||
    value.has_suffix(".txt") ||
    value.has_suffix(".png")) {
    return false
  }
  for segment in value.split("/") {
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
fn resource_bundle_errors(
  bundle : Json,
  assets : Map[String, Json],
) -> Array[String] {
  let errors : Array[String] = []
  for name in ["id", "version"] {
    if string(bundle, name).trim() == "" {
      errors.push("resource bundle " + name + " must not be empty")
    }
  }
  for asset in array(bundle, "assets") {
    let path = string(asset, "path")
    if !valid_resource_asset_path(path) {
      errors.push(
        "resource asset must be a safe SVG/text/PNG path below assets/: " + path,
      )
    } else {
      let validated = try {
        ignore(resource_asset_bytes(asset))
        true
      } catch {
        error => {
          errors.push(error.to_string())
          false
        }
      }
      if validated {
        if assets
          .keys()
          .any(existing => {
            existing.has_prefix(path + "/") || path.has_prefix(existing + "/")
          }) {
          errors.push("resource asset file/directory conflict: " + path)
          continue
        }
        match assets.get(path) {
          Some(existing) if existing != asset =>
            errors.push("conflicting resource asset: " + path)
          _ => assets[path] = asset
        }
      }
    }
  }
  errors
}

///|
async fn compile_resource_bundle(
  app_root : String,
  provider : Json,
  index : Int,
) -> Json {
  let package_path = string(provider, "package")
  let features = resource_features(provider)
  let relative = "src/minimoon_resources_" + index.to_string()
  let directory = join(app_root, relative)
  guard !@fs.exists(directory) else {
    raise Failure::Failure(
      "resource probe directory already exists: " + directory,
    )
  }
  let target = join(app_root, ".minimoon-tmp/resources-" + index.to_string())
  write(
    join(directory, "moon.pkg"),
    "import {\n  \"lampclaw/minimoon/resources\" @resources,\n  " +
    package_path.escape() +
    " @provider,\n}\n\nsupported_targets = \"native\"\n\npkgtype(kind: \"executable\")\n",
  )
  write(
    join(directory, "main.mbt"),
    "///|\nfn main { println(@resources.encode(@provider.resources([" +
    features.map(feature => feature.escape()).join(", ") +
    "]))) }\n",
  )
  let result = try {
    let _ = run_checked(
      "moon",
      ["fmt", relative + "/main.mbt"],
      app_root,
      "resource probe formatting",
    )
    let output = run_checked(
      "moon",
      [
        "run", relative, "--target", "native", "--target-dir", target, "--deny-warn",
      ],
      app_root,
      "resource provider " + package_path,
    )
    Ok(@json.parse(output.trim()))
  } catch {
    error => Err(error)
  }
  @fs.rmdir(directory, recursive=true)
  if @fs.exists(target) {
    @fs.rmdir(target, recursive=true)
  }
  match result {
    Ok(bundle) => bundle
    Err(error) => raise error
  }
}

///|
async fn compile_resources(app_root : String, raw : Json) -> Json {
  let descriptors : Array[Json] = []
  let styles : Array[String] = []
  let assets : Map[String, Json] = Map([])
  let bundle_ids : Set[String] = Set([])
  match object(raw, "MiniApp config").get("resources") {
    Some(Array(providers)) =>
      for index, provider in providers {
        let bundle = compile_resource_bundle(app_root, provider, index)
        let errors = resource_bundle_errors(bundle, assets)
        guard errors.is_empty() else {
          raise Failure::Failure(errors.join("; "))
        }
        let id = string(bundle, "id")
        guard !bundle_ids.contains(id) else {
          raise Failure::Failure("duplicate resource bundle id: " + id)
        }
        bundle_ids.add(id)
        let wxss = string(bundle, "wxss")
        if wxss != "" {
          styles.push(wxss)
        }
        let paths : Array[String] = []
        for asset in array(bundle, "assets") {
          let path = string(asset, "path")
          if !paths.contains(path) {
            paths.push(path)
          }
        }
        paths.sort()
        descriptors.push(
          Json::object({
            "package": field(provider, "package"),
            "features": Json::array(
              resource_features(provider).map(Json::string),
            ),
            "id": Json::string(id),
            "version": field(bundle, "version"),
            "wxssBytes": json_int(@utf8.encode(wxss).length()),
            "assets": Json::array(paths.map(Json::string)),
          }),
        )
      }
    _ => ()
  }
  let paths = assets.keys().collect()
  paths.sort()
  Json::object({
    "descriptors": Json::array(descriptors),
    "wxss": Json::string(
      if styles.is_empty() {
        ""
      } else {
        styles.join("\n") + "\n"
      },
    ),
    "assets": Json::array(paths.map(path => assets[path])),
  })
}
