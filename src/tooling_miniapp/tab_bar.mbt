///|
fn tab_color(value : Json) -> Bool {
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
fn tab_bar_config_issues(raw : Json) -> Array[(String, String)] {
  let issues : Array[(String, String)] = []
  let fields = object(raw, "config")
  let packages : Array[String] = []
  if fields.get("pages") is Some(Array(pages)) {
    for index, page in pages {
      if page is Object(entry) {
        if entry.get("package") is Some(String(package_path)) {
          packages.push(package_path)
        }
        match entry.get("navigationBarTextStyle") {
          None | Some(String("white")) | Some(String("black")) => ()
          _ =>
            issues.push(
              (
                "/pages/" + index.to_string() + "/navigationBarTextStyle",
                "navigationBarTextStyle must be white or black",
              ),
            )
        }
      }
    }
  }
  guard fields.get("tabBar") is Some(tab_bar) else { return issues }
  guard tab_bar is Object(tab) else {
    issues.push(("/tabBar", "tabBar must be an object"))
    return issues
  }
  for key in tab.keys() {
    if ![
        "color", "selectedColor", "backgroundColor", "borderStyle", "position", "list",
      ].contains(key) {
      issues.push(("/tabBar/" + key, "unknown native tabBar field"))
    }
  }
  for key in ["color", "selectedColor", "backgroundColor"] {
    if tab.get(key) is Some(value) && !tab_color(value) {
      issues.push(("/tabBar/" + key, "tabBar color must be #RRGGBB"))
    }
  }
  match tab.get("position") {
    None | Some(String("bottom")) => ()
    _ =>
      issues.push(
        ("/tabBar/position", "only bottom native tabBar is supported"),
      )
  }
  match tab.get("borderStyle") {
    None | Some(String("white")) | Some(String("black")) => ()
    _ =>
      issues.push(("/tabBar/borderStyle", "borderStyle must be white or black"))
  }
  guard tab.get("list") is Some(Array(items)) else {
    issues.push(("/tabBar/list", "tabBar list must contain 2 to 5 pages"))
    return issues
  }
  if items.length() < 2 || items.length() > 5 {
    issues.push(("/tabBar/list", "tabBar list must contain 2 to 5 pages"))
  }
  let selected : Set[String] = Set([])
  for index, item in items {
    let pointer = "/tabBar/list/" + index.to_string()
    guard item is Object(entry) else {
      issues.push((pointer, "tabBar entry must be an object"))
      continue
    }
    for key in entry.keys() {
      if !["package", "text", "iconPath", "selectedIconPath"].contains(key) {
        issues.push((pointer + "/" + key, "unknown tabBar entry field"))
      }
    }
    match entry.get("package") {
      Some(String(package_path)) if packages.contains(package_path) => {
        if fields.get("pages") is Some(Array(pages)) {
          for page in pages {
            if page is Object(page_fields) &&
              page_fields.get("package") == Some(Json::string(package_path)) {
              match page_fields.get("smokeInput") {
                None => ()
                Some(Object(input)) if input.is_empty() => ()
                _ =>
                  issues.push(
                    (
                      pointer + "/package",
                      "native Tab pages must pass smoke validation with empty route input",
                    ),
                  )
              }
            }
          }
        }
        if selected.contains(package_path) {
          issues.push((pointer + "/package", "duplicate tabBar page"))
        }
        selected.add(package_path)
      }
      _ =>
        issues.push(
          (
            pointer + "/package",
            "tabBar package must reference a declared pages entry",
          ),
        )
    }
    match entry.get("text") {
      Some(String(text)) if text.trim() == text && text != "" => ()
      _ =>
        issues.push(
          (pointer + "/text", "tabBar text must be a non-empty trimmed string"),
        )
    }
    if entry.contains("iconPath") != entry.contains("selectedIconPath") {
      issues.push(
        (
          pointer, "tabBar icons must provide both iconPath and selectedIconPath",
        ),
      )
    }
    for key in ["iconPath", "selectedIconPath"] {
      match entry.get(key) {
        None => ()
        Some(String(path)) if valid_resource_asset_path(path) &&
          path.has_suffix(".png") => ()
        _ =>
          issues.push(
            (
              pointer + "/" + key,
              "tabBar icon must reference a PNG below assets/",
            ),
          )
      }
    }
  }
  issues
}

///|
fn normalized_tab_bar(
  raw : Json,
  pages : Array[Json],
  contracts : Array[Json],
  resources : Json,
) -> Json raise {
  guard object(raw, "config").get("tabBar") is Some(tab) else {
    return Json::null()
  }
  let routes : Map[String, String] = Map([])
  for index, page in pages {
    routes[string(page, "package")] = string(contracts[index], "route")
  }
  let assets : Map[String, Json] = Map([])
  for asset in array(resources, "assets") {
    assets[string(asset, "path")] = asset
  }
  let items : Array[Json] = []
  for item in array(tab, "list") {
    let entry = object(item, "tabBar item").copy()
    let package_path = string(item, "package")
    guard routes.get(package_path) is Some(route) else {
      raise Failure("unknown tabBar page: " + package_path)
    }
    entry.remove("package")
    entry["pagePath"] = Json::string(route)
    for key in ["iconPath", "selectedIconPath"] {
      if entry.get(key) is Some(String(path)) {
        guard assets.get(path) is Some(asset) else {
          raise Failure("missing tabBar resource: " + path)
        }
        let bytes = resource_asset_bytes(asset)
        guard path.has_suffix(".png") && bytes.length() <= 40 * 1024 else {
          raise Failure("tabBar PNG must not exceed 40 KiB: " + path)
        }
        guard @png.dimensions(bytes) is Some((width, height)) &&
          width <= 256 &&
          height <= 256 else {
          raise Failure(
            "tabBar PNG dimensions must be 1 to 256 pixels: " + path,
          )
        }
      }
    }
    items.push(Json::object(entry))
  }
  Json::object({
    "color": Json::string(string(tab, "color", fallback="#64748B")),
    "selectedColor": Json::string(
      string(tab, "selectedColor", fallback="#2563EB"),
    ),
    "backgroundColor": Json::string(
      string(tab, "backgroundColor", fallback="#FFFFFF"),
    ),
    "borderStyle": Json::string(string(tab, "borderStyle", fallback="white")),
    "position": Json::string("bottom"),
    "list": Json::array(items),
  })
}

///|
fn native_tab_routes(tab_bar : Json) -> Array[String] {
  if tab_bar is Null {
    []
  } else {
    array(tab_bar, "list").map(item => "/" + string(item, "pagePath"))
  }
}
