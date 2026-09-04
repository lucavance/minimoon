///|
pub type EventKey = String

///|
pub type Key = String

///|
/// Concrete attributes are the only values accepted by the Model-driven DSL.
pub struct Attr {
  name : String
  value : String
}

///|
pub struct KeyedNode {
  key : Key
  node : Node
}

///|
/// A concrete, host-independent view tree produced from the current Model.
pub enum Node {
  Element(String, Array[Attr], Array[Node])
  Text(String)
  Fragment(Array[Node])
  KeyedFragment(Array[KeyedNode])
  Retained(Int, Node)
  Empty
}

///|
pub trait IsChildren {
  fn to_children(Self) -> Array[Node]
}

///|
pub impl IsChildren for Array[Node] with fn to_children(self) {
  self
}

///|
pub impl IsChildren for Node with fn to_children(self) {
  [self]
}

///|
pub impl IsChildren for String with fn to_children(self) {
  [text(self)]
}

///|
pub fn attr(name : String, value : String) -> Attr {
  { name, value, }
}

///|
pub fn class_attr(value : String) -> Attr {
  attr("class", value)
}

///|
pub fn style_attr(value : String) -> Attr {
  attr("style", value)
}

///|
pub fn value_attr(value : String) -> Attr {
  attr("value", value)
}

///|
pub fn src_attr(value : String) -> Attr {
  attr("src", value)
}

///|
pub fn alt_attr(value : String) -> Attr {
  attr("alt", value)
}

///|
pub fn text(value : String) -> Node {
  Text(value)
}

///|
pub fn click_event(key : EventKey) -> EventKey {
  key
}

///|
pub fn nothing() -> Node {
  Empty
}

///|
pub fn fragment(children : Array[Node]) -> Node {
  Fragment(children)
}

///|
pub fn keyed(key : Key, node : Node) -> KeyedNode {
  { key, node, }
}

///|
pub fn keyed_fragment(children : Array[KeyedNode]) -> Node {
  KeyedFragment(children)
}

///|
/// Attaches an opaque authoring identity that renderers may use for retained
/// subtree caches. The wrapper has no host-visible representation.
pub fn retained(identity : Int, node : Node) -> Node {
  Retained(identity, node)
}

///|
pub fn KeyedNode::key(self : KeyedNode) -> Key {
  self.key
}

///|
pub fn KeyedNode::node(self : KeyedNode) -> Node {
  self.node
}

///|
pub fn keyed_nodes(node : Node) -> Array[KeyedNode] {
  match node {
    KeyedFragment(children) => children
    _ => []
  }
}

///|
pub fn map_event_keys(node : Node, map : (EventKey) -> EventKey) -> Node {
  match node {
    Element(tag, attrs, children) =>
      Element(
        tag,
        attrs.map(item => {
          if is_event_attr(item.name) {
            { ..item, value: map(item.value), }
          } else {
            item
          }
        }),
        children.map(child => map_event_keys(child, map)),
      )
    Fragment(children) =>
      Fragment(children.map(child => map_event_keys(child, map)))
    KeyedFragment(children) =>
      KeyedFragment(
        children.map(child => {
          key: child.key,
          node: map_event_keys(child.node, map),
        }),
      )
    Retained(identity, child) => Retained(identity, map_event_keys(child, map))
    Text(_) | Empty => node
  }
}

///|
pub fn element(
  tag : String,
  id? : String = "",
  class? : String = "",
  attrs? : Array[Attr] = [],
  children? : Array[Node] = [],
) -> Node {
  if id != "" {
    attrs.push(attr("id", id))
  }
  if class != "" {
    attrs.push(class_attr(class))
  }
  Element(tag, attrs, children)
}

///|
pub fn[C : IsChildren] h1(
  id? : String = "",
  class? : String = "",
  attrs? : Array[Attr] = [],
  children : C,
) -> Node {
  element("h1", id~, class~, attrs~, children=children.to_children())
}

///|
pub fn[C : IsChildren] div(
  id? : String = "",
  class? : String = "",
  attrs? : Array[Attr] = [],
  children : C,
) -> Node {
  element("div", id~, class~, attrs~, children=children.to_children())
}

///|
pub fn[C : IsChildren] span(
  id? : String = "",
  class? : String = "",
  attrs? : Array[Attr] = [],
  children : C,
) -> Node {
  element("span", id~, class~, attrs~, children=children.to_children())
}

///|
pub fn[C : IsChildren] p(
  id? : String = "",
  class? : String = "",
  attrs? : Array[Attr] = [],
  children : C,
) -> Node {
  element("p", id~, class~, attrs~, children=children.to_children())
}

///|
pub fn[C : IsChildren] button(
  id? : String = "",
  class? : String = "",
  on_click? : String = "",
  attrs? : Array[Attr] = [],
  children : C,
) -> Node {
  if on_click != "" {
    attrs.push(attr("on_click", on_click))
  }
  element("button", id~, class~, attrs~, children=children.to_children())
}

///|
pub fn input(
  id? : String = "",
  class? : String = "",
  attrs? : Array[Attr] = [],
) -> Node {
  element("input", id~, class~, attrs~)
}

///|
pub fn image(
  id? : String = "",
  class? : String = "",
  src? : String = "",
  alt? : String = "",
  attrs? : Array[Attr] = [],
) -> Node {
  if src != "" {
    attrs.push(src_attr(src))
  }
  if alt != "" {
    attrs.push(alt_attr(alt))
  }
  element("img", id~, class~, attrs~)
}

///|
pub fn[C : IsChildren] view(children : C) -> Node {
  div(children)
}

///|
/// A compact renderer used only by internal tests and diagnostics.
pub fn render_to_string(node : Node) -> String {
  match node {
    Text(value) => value
    Fragment(children) => children.map(render_to_string).join("")
    KeyedFragment(children) =>
      children.map(child => render_to_string(child.node)).join("")
    Retained(_, child) => render_to_string(child)
    Empty => ""
    Element(tag, attrs, children) => {
      let rendered_attrs = attrs
        .map(item => item.name + "=\"" + item.value + "\"")
        .join(" ")
      let opening = if rendered_attrs == "" {
        "<" + tag + ">"
      } else {
        "<" + tag + " " + rendered_attrs + ">"
      }
      opening + children.map(render_to_string).join("") + "</" + tag + ">"
    }
  }
}

///|
fn is_event_attr(name : String) -> Bool {
  name.has_prefix("on_")
}
