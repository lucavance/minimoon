///|
fn native_tab_color(value : Json) -> Bool {
  guard value is String(text) && text.length() == 7 && text[0] == '#' else {
    return false
  }
  text[1:]
  .iter()
  .all(c => {
    (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
  })
}

///|
async fn tab_bar_status(app_root : String, manifest : Json) -> Json {
  let errors : Array[String] = []
  let app_file = join(app_root, "dist/app.json")
  if !@fs.exists(app_file) {
    return status("native-tab-bar", false, "app.json is missing")
  }
  let app = read_json(app_file)
  let expected = object(manifest, "manifest")
    .get("tabBar")
    .unwrap_or(Json::null())
  let actual = object(app, "app").get("tabBar").unwrap_or(Json::null())
  if actual != expected {
    errors.push("app.json tabBar differs from the generated manifest")
  }
  if expected is Object(tab) {
    if tab
      .keys()
      .any(key => {
        ![
          "position", "color", "selectedColor", "backgroundColor", "borderStyle",
          "list",
        ].contains(key)
      }) {
      errors.push("unknown native tabBar field")
    }
    for key in ["color", "selectedColor", "backgroundColor"] {
      if !native_tab_color(tab.get(key).unwrap_or(Json::null())) {
        errors.push("invalid native tabBar color: " + key)
      }
    }
    match tab.get("borderStyle") {
      Some(String("white")) | Some(String("black")) => ()
      _ => errors.push("invalid native tabBar borderStyle")
    }
    if tab.get("position") != Some(Json::string("bottom")) {
      errors.push("native tabBar must use bottom position")
    }
    let routes = array(manifest, "pages").map(page => string(page, "route"))
    let assets : Set[String] = Set([])
    if object(manifest, "manifest").get("resources") is Some(Array(providers)) {
      for provider in providers {
        for asset in array(provider, "assets") {
          if asset is String(path) {
            assets.add(path)
          }
        }
      }
    }
    match tab.get("list") {
      Some(Array(items)) => {
        if items.length() < 2 || items.length() > 5 {
          errors.push("native tabBar requires 2-5 pages")
        }
        let seen : Set[String] = Set([])
        for item in items {
          guard item is Object(entry) else {
            errors.push("native tabBar item must be an object")
            continue
          }
          if entry
            .keys()
            .any(key => {
              !["pagePath", "text", "iconPath", "selectedIconPath"].contains(
                key,
              )
            }) {
            errors.push("unknown native tabBar item field")
          }
          match entry.get("text") {
            Some(String(text)) if text != "" && text.trim() == text => ()
            _ => errors.push("invalid native tabBar label")
          }
          if entry.contains("iconPath") != entry.contains("selectedIconPath") {
            errors.push("native tabBar icon pair is incomplete")
          }
          guard entry.get("pagePath") is Some(String(_)) else {
            errors.push("native tabBar pagePath must be a string")
            continue
          }
          let route = string(item, "pagePath")
          if !routes.contains(route) || seen.contains(route) {
            errors.push("invalid or duplicate native tabBar route: " + route)
          }
          seen.add(route)
          for key in ["iconPath", "selectedIconPath"] {
            if entry.get(key) is Some(String(path)) {
              if !assets.contains(path) ||
                !safe_resource_asset(path) ||
                !path.has_suffix(".png") {
                errors.push(
                  "native tabBar icon must reference a declared PNG: " + path,
                )
              } else {
                let file = join(app_root, "dist/" + path)
                if !@fs.exists(file) ||
                  @fs.kind(file, follow_symlink=false) != @fs.Regular {
                  errors.push("native tabBar icon is missing: " + path)
                } else {
                  let bytes = @fs.read_file(file).binary()
                  if bytes.length() > 40 * 1024 {
                    errors.push("native tabBar icon exceeds 40 KiB: " + path)
                  }
                  if !(@png.dimensions(bytes) is Some((width, height)) &&
                    width <= 256 &&
                    height <= 256) {
                    errors.push(
                      "native tabBar icon must be a valid PNG of 1 to 256 pixels: " +
                      path,
                    )
                  }
                }
              }
            } else if entry.contains(key) {
              errors.push("native tabBar icon path must be a string")
            }
          }
        }
      }
      _ => errors.push("native tabBar list is missing")
    }
  } else if !(expected is Null) {
    errors.push("manifest tabBar must be an object or null")
  }
  for page in array(manifest, "pages") {
    let file = join(app_root, "dist/" + string(page, "route") + ".json")
    if !@fs.exists(file) {
      errors.push("page config is missing: " + string(page, "route"))
      continue
    }
    let config = read_json(file)
    match object(config, "page config").get("navigationBarTextStyle") {
      None | Some(String("white")) | Some(String("black")) => ()
      _ => errors.push("navigationBarTextStyle must be white or black")
    }
    if object(config, "page config").get("navigationBarTextStyle") !=
      object(page, "page contract").get("navigationBarTextStyle") {
      errors.push(
        "page navigationBarTextStyle differs from its contract: " +
        string(page, "route"),
      )
    }
  }
  status(
    "native-tab-bar",
    errors.is_empty(),
    if errors.is_empty() {
      "native Tab pages, PNG assets and status-bar foreground match the manifest"
    } else {
      errors.join("; ")
    },
  )
}
