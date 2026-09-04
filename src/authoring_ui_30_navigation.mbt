///|
pub struct Query {
  name : String
  value : String
}

///|
pub struct Route {
  path : String
  query : Array[Query]
}

///|
fn valid_route_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_' ||
  char == '-'
}

///|
pub fn route(path : String) -> Route {
  guard path != "" && !path.has_prefix("/") && !path.has_suffix("/") else {
    abort("MiniApp route must be a non-empty relative path: " + path)
  }
  guard !path.contains("//") && !path.contains("?") && !path.contains("#") else {
    abort(
      "MiniApp route must not contain empty segments, query, or fragment: " +
      path,
    )
  }
  for segment in path.split("/") {
    guard segment != "." && segment != ".." && segment != "" else {
      abort("MiniApp route contains an unsafe segment: " + path)
    }
    for char in segment {
      guard valid_route_char(char) else {
        abort("MiniApp route contains an unsupported character: " + path)
      }
    }
  }
  { path, query: [], }
}

///|
pub fn query(name : String, value : String) -> Query {
  guard name != "" else { abort("MiniApp query name must not be empty") }
  { name, value, }
}

///|
pub fn Route::path(self : Route) -> String {
  self.path
}

///|
pub fn Route::has_query(self : Route) -> Bool {
  self.query.length() > 0
}

///|
pub fn Route::with_query(self : Route, query : Array[Query]) -> Route {
  { ..self, query, }
}

///|
fn percent_encode(value : String) -> String {
  let parts : Array[String] = []
  let hex = "0123456789ABCDEF"
  for byte in @utf8.encode(value) {
    let code = byte.to_int()
    let unreserved = (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      (code >= 48 && code <= 57) ||
      code == 45 ||
      code == 46 ||
      code == 95 ||
      code == 126
    if unreserved {
      parts.push(String::make(1, byte.to_char()))
    } else {
      parts.push(
        "%" +
        String::make(1, hex[code / 16].to_int().unsafe_to_char()) +
        String::make(1, hex[code % 16].to_int().unsafe_to_char()),
      )
    }
  }
  parts.join("")
}

///|
pub fn Route::url(self : Route) -> String {
  let base = "/" + self.path
  if self.query.length() == 0 {
    base
  } else {
    base +
    "?" +
    self.query
    .map(item => percent_encode(item.name) + "=" + percent_encode(item.value))
    .join("&")
  }
}

///|
pub(all) enum NavigatorMode {
  Navigate
  Redirect
} derive(Eq)

///|
pub fn[C : IsChildren] navigator(
  target~ : Route,
  mode? : NavigatorMode = Navigate,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.attr("url", target.url()))
  attrs.push(
    @ui.attr(
      "open-type",
      if mode == Navigate {
        "navigate"
      } else {
        "redirect"
      },
    ),
  )
  wrap_node(
    @ui.element("navigator", id~, class~, attrs~, children=child_raw(children)),
    child_bindings(children),
  )
}
