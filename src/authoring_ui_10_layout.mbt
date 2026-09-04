///|
pub fn text(value : String) -> Node {
  wrap_node(@ui.text(value), [])
}

///|
pub fn nothing() -> Node {
  wrap_node(@ui.nothing(), [])
}

///|
pub fn fragment(children : Array[Node]) -> Node {
  wrap_node(@ui.fragment(child_raw(children)), child_bindings(children))
}

///|
pub fn keyed(key : String, node : Node) -> KeyedNode {
  guard key != "" else { abort("keyed node key must not be empty") }
  { key, node, }
}

///|
pub fn keyed_fragment(children : Array[KeyedNode]) -> Node {
  let raw : Array[@ui.KeyedNode] = []
  let bindings : Array[NodeBinding] = []
  for child in children {
    raw.push(@ui.keyed(child.key, child.node.raw))
    if child.node.bindings.length() > 0 {
      bindings.push(NestedBindings(child.node.bindings))
    }
  }
  wrap_node(@ui.keyed_fragment(raw), bindings)
}

///|
pub fn[C : IsChildren] div(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  children : C,
) -> Node {
  let children = children.to_nodes()
  wrap_node(
    @ui.div(
      id~,
      class~,
      attrs=raw_element_attrs(style, data_section, semantics?),
      child_raw(children),
    ),
    child_bindings(children),
  )
}

///|
/// A tappable MiniApp `view`. Use this for non-button hit surfaces such as
/// modal overlays and menu dismissal layers.
pub fn[C : IsChildren] tap_view(
  on_tap~ : Cmd,
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("tap"),
    _ => Ok(on_tap),
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, data_section, semantics?)
  raw_event_attr(attrs, "on_click", "tap", Some(binding))
  wrap_node(
    @ui.element("view", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] h1(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  children : C,
) -> Node {
  let children = children.to_nodes()
  wrap_node(
    @ui.h1(
      id~,
      class~,
      attrs=raw_element_attrs(style, data_section, semantics?),
      child_raw(children),
    ),
    child_bindings(children),
  )
}

///|
pub fn[C : IsChildren] span(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  children : C,
) -> Node {
  let children = children.to_nodes()
  wrap_node(
    @ui.span(
      id~,
      class~,
      attrs=raw_element_attrs(style, data_section, semantics?),
      child_raw(children),
    ),
    child_bindings(children),
  )
}

///|
pub fn[C : IsChildren] p(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  children : C,
) -> Node {
  let children = children.to_nodes()
  wrap_node(
    @ui.p(
      id~,
      class~,
      attrs=raw_element_attrs(style, data_section, semantics?),
      child_raw(children),
    ),
    child_bindings(children),
  )
}

///|
pub fn image(
  src~ : String,
  alt? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
) -> Node {
  wrap_node(
    @ui.image(
      id~,
      class~,
      src~,
      alt~,
      attrs=raw_element_attrs(style, data_section, semantics?),
    ),
    [],
  )
}
