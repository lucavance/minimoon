///|
async fn native_tab_host_status(app_root : String, manifest : Json) -> Json {
  let routes = array(manifest, "pages").map(page => "/" + string(page, "route"))
  let tabs : Array[String] = []
  match object(manifest, "manifest").get("tabBar") {
    None | Some(Null) => ()
    Some(Object(tab)) =>
      match tab.get("list") {
        Some(Array(items)) =>
          for item in items {
            guard item is Object(fields) &&
              fields.get("pagePath") is Some(String(route)) else {
              return status(
                "native-tab-host", false, "manifest native Tab route must be a string",
              )
            }
            tabs.push("/" + route)
          }
        _ =>
          return status(
            "native-tab-host", false, "manifest native Tab list is missing",
          )
      }
    _ =>
      return status(
        "native-tab-host", false, "manifest tabBar must be an object or null",
      )
  }
  let (passed, detail) = run(
    "bun",
    ["--eval", @host_js.native_tab_host_source(routes, tabs)],
    app_root,
  )
  status(
    "native-tab-host",
    passed,
    if passed {
      "generated host Tab switches, ordinary navigation and back fallbacks match every manifest page"
    } else {
      detail
    },
  )
}
