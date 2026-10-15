///|
/// A native inline run. Construct runs with `inline_text` or `inline_image`;
/// block nodes cannot be inserted into an inline flow.
struct Inline {
  node : Node
}

///|
/// Styled text in a native inline flow. Taps emit application commands.
pub fn inline_text(
  value : String,
  id~ : String = "",
  class~ : String = "",
  style~ : String = "",
  semantics? : Semantics,
  on_tap? : Cmd,
  event_key~ : String = "",
) -> Inline {
  let attrs = raw_element_attrs(style, "", semantics?)
  let bindings : Array[NodeBinding] = []
  let binding = on_tap.map(command => {
    event_binding(
      @renderer.page_event_kind("tap"),
      _ => Ok(command),
      explicit_key=event_key,
    )
  })
  if binding is Some(value) {
    append_direct_binding(bindings, value)
  }
  raw_event_attr(attrs, "on_click", "tap", binding)
  {
    node: wrap_node(
      @ui.element("inline-text", id~, class~, attrs~, children=[@ui.text(value)]),
      bindings,
    ),
  }
}

///|
/// An image run. Give it an explicit size appropriate for the text line.
pub fn inline_image(
  src~ : String,
  alt~ : String = "",
  mode? : ImageMode,
  id~ : String = "",
  class~ : String = "",
  style~ : String = "",
  on_load? : Emit[ImageLoadDetail],
  on_error? : Emit[String],
  load_key~ : String = "",
  error_key~ : String = "",
) -> Inline {
  {
    node: image(
      src~,
      alt~,
      mode?,
      id~,
      class~,
      style~,
      on_load?,
      on_error?,
      load_key~,
      error_key~,
    ),
  }
}

///|
/// Native Skyline span flow, restricted to text and image runs. Existing
/// `span` remains a general block container for compatibility.
pub fn inline(
  children : Array[Inline],
  id~ : String = "",
  class~ : String = "",
  style~ : String = "",
  semantics? : Semantics,
) -> Node {
  let nodes = children.map(child => child.node)
  wrap_node(
    @ui.element(
      "inline",
      id~,
      class~,
      attrs=raw_element_attrs(style, "", semantics?),
      children=child_raw(nodes),
    ),
    child_bindings(nodes),
  )
}
