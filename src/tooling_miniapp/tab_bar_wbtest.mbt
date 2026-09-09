///|
fn tab_test_config() -> Json {
  Json::object({
    "pages": Json::array(
      ["src/home", "src/lab"].map(path => {
        Json::object({ "package": Json::string(path) })
      }),
    ),
    "tabBar": Json::object({
      "list": Json::array(
        ["src/home", "src/lab"].map(path => {
          Json::object({
            "package": Json::string(path),
            "text": Json::string(path),
          })
        }),
      ),
    }),
  })
}

///|
test "Tab packages resolve once to ordered native routes and optional colors" {
  let config = tab_test_config()
  assert_eq(tab_bar_config_issues(config), [])
  let normalized = normalized_tab_bar(
    config,
    array(config, "pages"),
    ["pages/home/home", "pages/lab/lab"].map(route => {
      Json::object({ "route": Json::string(route) })
    }),
    Json::object({ "assets": Json::array([]) }),
  )
  assert_eq(native_tab_routes(normalized), [
    "/pages/home/home", "/pages/lab/lab",
  ])
  assert_eq(
    field(
      app_json(["pages/home/home", "pages/lab/lab"], tab_bar=normalized),
      "tabBar",
    ),
    normalized,
  )
  assert_false(object(array(normalized, "list")[0], "tab").contains("package"))
  assert_eq(string(normalized, "position"), "bottom")
  assert_eq(
    normalized_tab_bar(Json::empty_object(), [], [], Json::empty_object()),
    Json::null(),
  )
}

///|
test "Tab config rejects duplicate unknown query-like pages and unsupported styles" {
  for
    entry in [
      ("color", Json::string("red")),
      ("position", Json::string("top")),
      ("custom", Json::boolean(true)),
      ("borderStyle", Json::string("gray")),
      ("list", Json::array([])),
      ("list", Json::null()),
    ] {
    let (key, value) = entry
    let config = tab_test_config()
    object(field(config, "tabBar"), "tab")[key] = value
    assert_false(tab_bar_config_issues(config).is_empty())
  }
  for
    entry in [
      ("package", Json::string("src/unknown")),
      ("pagePath", Json::string("pages/home/home")),
      ("text", Json::string("")),
      ("iconPath", Json::string("assets/a.svg")),
      ("package", Json::string("src/lab")),
    ] {
    let (key, value) = entry
    let config = tab_test_config()
    object(array(field(config, "tabBar"), "list")[0], "item")[key] = value
    assert_false(tab_bar_config_issues(config).is_empty())
  }
}

///|
test "custom navigation allows only white or black foreground and Tab smoke input is empty" {
  for color in ["white", "black"] {
    let config = tab_test_config()
    object(array(config, "pages")[0], "page")["navigationBarTextStyle"] = Json::string(
      color,
    )
    assert_eq(tab_bar_config_issues(config), [])
    assert_eq(
      string(page_json(array(config, "pages")[0]), "navigationBarTextStyle"),
      color,
    )
  }
  let config = tab_test_config()
  object(array(config, "pages")[0], "page")["navigationBarTextStyle"] = Json::string(
    "red",
  )
  assert_false(tab_bar_config_issues(config).is_empty())
  object(array(config, "pages")[0], "page").remove("navigationBarTextStyle")
  object(array(config, "pages")[0], "page")["smokeInput"] = Json::object({
    "from": Json::string("fake"),
  })
  assert_false(tab_bar_config_issues(config).is_empty())
}
