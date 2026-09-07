///|
/// A selector over the normalized MiniApp tree. Selectors deliberately target
/// host-neutral facts rather than WXML implementation details.
pub enum Selector {
  Kind(String)
  Id(String)
  Section(String)
  Text(String)
  TextContaining(String)
  Prop(String, Json)
  Event(String)
  BoundEvent(String)
  Role(String)
  Label(String)
  All(Array[Selector])
}

///|
pub fn by_kind(kind : String) -> Selector {
  Kind(kind)
}

///|
pub fn by_id(id : String) -> Selector {
  Id(id)
}

///|
pub fn by_section(section : String) -> Selector {
  Section(section)
}

///|
pub fn by_text(text : String) -> Selector {
  Text(text)
}

///|
pub fn containing_text(text : String) -> Selector {
  TextContaining(text)
}

///|
pub fn by_prop(name : String, value : Json) -> Selector {
  Prop(name, value)
}

///|
pub fn by_event(name : String) -> Selector {
  Event(name)
}

///|
/// Match an explicit event route, independently of the native event name.
pub fn by_event_key(key : String) -> Selector {
  BoundEvent(key)
}

///|
pub fn by_role(role : String) -> Selector {
  Role(role)
}

///|
pub fn by_label(label : String) -> Selector {
  Label(label)
}

///|
pub fn all(selectors : Array[Selector]) -> Selector {
  All(selectors)
}

///|
struct TestNode {
  node : Json
}

///|
struct TestRuntime {
  runtime : @minimoon.PageRuntime
}

///|
/// A semantic subtree locator. The selector chain is resolved against the
/// latest normalized snapshot before every query or interaction, so a scope
/// never retains a stale `TestNode` across renders.
struct TestScope {
  runtime : @minimoon.PageRuntime
  selectors : Array[Selector]
}

///|
fn object_field(value : Json, name : String) -> Json? {
  match value {
    Object(fields) => fields.get(name)
    _ => None
  }
}

///|
fn string_field(value : Json, name : String) -> String? {
  match object_field(value, name) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn node_children(value : Json) -> Array[Json] {
  match object_field(value, "children") {
    Some(Array(children)) => children
    _ => []
  }
}

///|
fn node_text_content(value : Json) -> String {
  let output = Ref(string_field(value, "text").unwrap_or(""))
  for child in node_children(value) {
    output.val += node_text_content(child)
  }
  output.val
}

///|
fn selector_matches(value : Json, selector : Selector) -> Bool {
  match selector {
    Kind(kind) => string_field(value, "kind") == Some(kind)
    Id(id) =>
      string_field(object_field(value, "props").unwrap_or(Json::null()), "id") ==
      Some(id)
    Section(section) =>
      string_field(
        object_field(value, "props").unwrap_or(Json::null()),
        "section",
      ) ==
      Some(section)
    Text(text) => node_text_content(value) == text
    TextContaining(text) => node_text_content(value).contains(text)
    Prop(name, expected) =>
      object_field(object_field(value, "props").unwrap_or(Json::null()), name) ==
      Some(expected)
    Event(name) =>
      object_field(object_field(value, "events").unwrap_or(Json::null()), name)
      is Some(_)
    BoundEvent(key) =>
      match object_field(value, "events") {
        Some(Object(events)) =>
          events.values().any(value => value == Json::string(key))
        _ => false
      }
    Role(role) =>
      string_field(object_field(value, "props").unwrap_or(Json::null()), "role") ==
      Some(role)
    Label(label) =>
      string_field(
        object_field(value, "props").unwrap_or(Json::null()),
        "ariaLabel",
      ) ==
      Some(label)
    All(selectors) =>
      selectors.all(selector => selector_matches(value, selector))
  }
}

///|
fn collect_matches(
  value : Json,
  selector : Selector,
  output : Array[TestNode],
) -> Unit {
  if selector_matches(value, selector) {
    output.push({ node: value, })
  }
  for child in node_children(value) {
    collect_matches(child, selector, output)
  }
}

///|
fn collect_descendant_matches(
  value : Json,
  selector : Selector,
  output : Array[TestNode],
) -> Unit {
  for child in node_children(value) {
    collect_matches(child, selector, output)
  }
}

///|
fn exactly_one(matches : Array[TestNode], context : String) -> TestNode {
  guard matches.length() == 1 else {
    abort(
      context +
      " must match exactly one normalized MiniApp node; matched " +
      matches.length().to_string(),
    )
  }
  matches[0]
}

///|
fn parse_snapshot(raw : String) -> Json {
  @json.parse(raw) catch {
    error => abort("invalid normalized MiniApp snapshot: " + error.to_string())
  }
}

///|
pub fn mount(page : @minimoon.Page) -> TestRuntime {
  let runtime = page.create_runtime()
  let _ = runtime.mount()
  { runtime, }
}

///|
pub fn TestRuntime::page_id(self : TestRuntime) -> String {
  self.runtime.page_id()
}

///|
pub fn TestRuntime::snapshot(self : TestRuntime) -> String {
  self.runtime.snapshot()
}

///|
pub fn TestRuntime::tree(self : TestRuntime) -> TestNode {
  let snapshot = parse_snapshot(self.runtime.snapshot())
  match object_field(snapshot, "tree") {
    Some(tree) => { node: tree, }
    None => abort("normalized MiniApp snapshot has no tree")
  }
}

///|
pub fn TestRuntime::query_all(
  self : TestRuntime,
  selector : Selector,
) -> Array[TestNode] {
  let output : Array[TestNode] = []
  collect_matches(self.tree().node, selector, output)
  output
}

///|
pub fn TestRuntime::query(self : TestRuntime, selector : Selector) -> TestNode? {
  let matches = self.query_all(selector)
  if matches.length() == 0 {
    None
  } else {
    Some(matches[0])
  }
}

///|
pub fn TestRuntime::get(self : TestRuntime, selector : Selector) -> TestNode {
  exactly_one(self.query_all(selector), "normalized MiniApp tree selector")
}

///|
pub fn TestRuntime::within(
  self : TestRuntime,
  selector : Selector,
) -> TestScope {
  let scope = { runtime: self.runtime, selectors: [selector], }
  let _ = scope.resolve()
  scope
}

///|
fn TestScope::root_tree(self : TestScope) -> TestNode {
  let snapshot = parse_snapshot(self.runtime.snapshot())
  match object_field(snapshot, "tree") {
    Some(tree) => { node: tree, }
    None => abort("normalized MiniApp snapshot has no tree")
  }
}

///|
fn TestScope::resolve(self : TestScope) -> TestNode {
  let current = Ref(self.root_tree())
  let first = Ref(true)
  for selector in self.selectors {
    let matches : Array[TestNode] = []
    if first.val {
      collect_matches(current.val.node, selector, matches)
      first.val = false
    } else {
      collect_descendant_matches(current.val.node, selector, matches)
    }
    current.val = exactly_one(matches, "normalized MiniApp scope selector")
  }
  current.val
}

///|
pub fn TestScope::within(self : TestScope, selector : Selector) -> TestScope {
  let scope = {
    runtime: self.runtime,
    selectors: [..self.selectors, selector],
  }
  let _ = scope.resolve()
  scope
}

///|
pub fn TestScope::query_all(
  self : TestScope,
  selector : Selector,
) -> Array[TestNode] {
  let output : Array[TestNode] = []
  collect_descendant_matches(self.resolve().node, selector, output)
  output
}

///|
pub fn TestScope::query(self : TestScope, selector : Selector) -> TestNode? {
  let matches = self.query_all(selector)
  if matches.length() == 0 {
    None
  } else {
    Some(matches[0])
  }
}

///|
pub fn TestScope::get(self : TestScope, selector : Selector) -> TestNode {
  exactly_one(self.query_all(selector), "normalized MiniApp scoped selector")
}

///|
pub fn TestNode::snapshot(self : TestNode) -> String {
  self.node.stringify()
}

///|
pub fn TestNode::kind(self : TestNode) -> String {
  string_field(self.node, "kind").unwrap_or("")
}

///|
pub fn TestNode::identity(self : TestNode) -> String {
  string_field(self.node, "identity").unwrap_or("")
}

///|
pub fn TestNode::text(self : TestNode) -> String {
  string_field(self.node, "text").unwrap_or("")
}

///|
pub fn TestNode::text_content(self : TestNode) -> String {
  node_text_content(self.node)
}

///|
pub fn TestNode::prop(self : TestNode, name : String) -> Json? {
  object_field(object_field(self.node, "props").unwrap_or(Json::null()), name)
}

///|
pub fn TestNode::event(self : TestNode, name : String) -> String? {
  string_field(object_field(self.node, "events").unwrap_or(Json::null()), name)
}

///|
pub fn TestNode::children(self : TestNode) -> Array[TestNode] {
  node_children(self.node).map(node => { node, })
}

///|
fn dispatch_node_event(
  runtime : @minimoon.PageRuntime,
  node : TestNode,
  event : String,
  payload : Json,
) -> String {
  match node.event(event) {
    Some(key) => runtime.dispatch(key, payload.stringify())
    None => abort("selected normalized MiniApp node has no " + event + " event")
  }
}

///|
fn detail_payload(fields : Map[String, Json]) -> Json {
  Json::object({ "detail": Json::object(fields) })
}

///|
fn json_int(value : Int) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
fn change_payload(node : TestNode, value : Json) -> Json {
  if node.kind() == "swiper" {
    detail_payload({ "current": value })
  } else {
    detail_payload({ "value": value })
  }
}

///|
fn focus_payload(value : String, height : Int) -> Json {
  detail_payload({ "value": Json::string(value), "height": json_int(height) })
}

///|
fn input_blur_payload(value : String) -> Json {
  detail_payload({ "value": Json::string(value) })
}

///|
fn textarea_blur_payload(value : String, cursor : Int) -> Json {
  detail_payload({ "value": Json::string(value), "cursor": json_int(cursor) })
}

///|
fn scroll_payload(
  scroll_left : Double,
  scroll_top : Double,
  scroll_height : Double,
  scroll_width : Double,
  delta_x : Double,
  delta_y : Double,
) -> Json {
  detail_payload({
    "scrollLeft": Json::number(scroll_left),
    "scrollTop": Json::number(scroll_top),
    "scrollHeight": Json::number(scroll_height),
    "scrollWidth": Json::number(scroll_width),
    "deltaX": Json::number(delta_x),
    "deltaY": Json::number(delta_y),
  })
}

///|
pub fn TestRuntime::tap(self : TestRuntime, selector : Selector) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "tap",
    Json::empty_object(),
  )
}

///|
pub fn TestRuntime::input(
  self : TestRuntime,
  selector : Selector,
  value : String,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "input",
    detail_payload({ "value": Json::string(value) }),
  )
}

///|
pub fn TestRuntime::change(
  self : TestRuntime,
  selector : Selector,
  value : Json,
) -> String {
  let node = self.get(selector)
  dispatch_node_event(self.runtime, node, "change", change_payload(node, value))
}

///|
pub fn TestRuntime::confirm(
  self : TestRuntime,
  selector : Selector,
  value : String,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "confirm",
    detail_payload({ "value": Json::string(value) }),
  )
}

///|
pub fn TestRuntime::focus(
  self : TestRuntime,
  selector : Selector,
  value : String,
  height : Int,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "focus",
    focus_payload(value, height),
  )
}

///|
pub fn TestRuntime::blur_input(
  self : TestRuntime,
  selector : Selector,
  value : String,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "blur",
    input_blur_payload(value),
  )
}

///|
pub fn TestRuntime::blur_textarea(
  self : TestRuntime,
  selector : Selector,
  value : String,
  cursor : Int,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "blur",
    textarea_blur_payload(value, cursor),
  )
}

///|
pub fn TestRuntime::scroll(
  self : TestRuntime,
  selector : Selector,
  scroll_left~ : Double,
  scroll_top~ : Double,
  scroll_height~ : Double,
  scroll_width~ : Double,
  delta_x~ : Double,
  delta_y~ : Double,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "scroll",
    scroll_payload(
      scroll_left, scroll_top, scroll_height, scroll_width, delta_x, delta_y,
    ),
  )
}

///|
pub fn TestRuntime::upper(self : TestRuntime, selector : Selector) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "upper",
    Json::empty_object(),
  )
}

///|
pub fn TestRuntime::lower(self : TestRuntime, selector : Selector) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "lower",
    Json::empty_object(),
  )
}

///|
pub fn TestScope::tap(self : TestScope, selector : Selector) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "tap",
    Json::empty_object(),
  )
}

///|
pub fn TestScope::input(
  self : TestScope,
  selector : Selector,
  value : String,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "input",
    detail_payload({ "value": Json::string(value) }),
  )
}

///|
pub fn TestScope::change(
  self : TestScope,
  selector : Selector,
  value : Json,
) -> String {
  let node = self.get(selector)
  dispatch_node_event(self.runtime, node, "change", change_payload(node, value))
}

///|
pub fn TestScope::confirm(
  self : TestScope,
  selector : Selector,
  value : String,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "confirm",
    detail_payload({ "value": Json::string(value) }),
  )
}

///|
pub fn TestScope::focus(
  self : TestScope,
  selector : Selector,
  value : String,
  height : Int,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "focus",
    focus_payload(value, height),
  )
}

///|
pub fn TestScope::blur_input(
  self : TestScope,
  selector : Selector,
  value : String,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "blur",
    input_blur_payload(value),
  )
}

///|
pub fn TestScope::blur_textarea(
  self : TestScope,
  selector : Selector,
  value : String,
  cursor : Int,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "blur",
    textarea_blur_payload(value, cursor),
  )
}

///|
pub fn TestScope::scroll(
  self : TestScope,
  selector : Selector,
  scroll_left~ : Double,
  scroll_top~ : Double,
  scroll_height~ : Double,
  scroll_width~ : Double,
  delta_x~ : Double,
  delta_y~ : Double,
) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "scroll",
    scroll_payload(
      scroll_left, scroll_top, scroll_height, scroll_width, delta_x, delta_y,
    ),
  )
}

///|
pub fn TestScope::upper(self : TestScope, selector : Selector) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "upper",
    Json::empty_object(),
  )
}

///|
pub fn TestScope::lower(self : TestScope, selector : Selector) -> String {
  dispatch_node_event(
    self.runtime,
    self.get(selector),
    "lower",
    Json::empty_object(),
  )
}

///|
pub fn TestRuntime::lifecycle(
  self : TestRuntime,
  hook : String,
  payload? : Json = Json::empty_object(),
) -> String {
  self.runtime.lifecycle(hook, payload.stringify())
}

///|
pub fn TestRuntime::tick(self : TestRuntime, key : String) -> String {
  self.runtime.subscription(key, "{}")
}

///|
pub fn TestRuntime::dispose(self : TestRuntime) -> String {
  self.runtime.dispose()
}
