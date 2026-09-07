///|
/// A declarative page layer. Its content must be enclosed by `layer_root`.
/// Layers remain part of their original Val scope and event ownership; only
/// their host location changes. No registry retains removed branch content.
pub fn[C : IsChildren] layer(id~ : String, children : C) -> Node {
  guard id != "" else { abort("layer id must not be empty") }
  let children = children.to_nodes()
  wrap_node(
    @ui.element("$minimoon-layer", id~, children=child_raw(children)),
    child_bindings(children),
  )
}

///|
fn collect_layers(
  node : @ui.Node,
  layers : Array[@ui.Node],
  ids : Map[String, Bool],
) -> @ui.Node {
  match node {
    @ui.Text(_) | @ui.Empty => node
    @ui.Retained(identity, child) =>
      @ui.retained(identity, collect_layers(child, layers, ids))
    @ui.Fragment(children) =>
      @ui.fragment(children.map(child => collect_layers(child, layers, ids)))
    @ui.KeyedFragment(children) =>
      @ui.keyed_fragment(
        children.map(child => {
          @ui.keyed(child.key(), collect_layers(child.node(), layers, ids))
        }),
      )
    @ui.Element(tag, attrs, children) =>
      if tag == "$minimoon-layer" {
        let mut id = ""
        for attr in attrs {
          if attr.name == "id" {
            id = attr.value
          }
        }
        guard !ids.contains(id) else { abort("duplicate layer id: " + id) }
        ids[id] = true
        // Reserve the parent before visiting nested layers: nested surfaces
        // paint above their parent without escaping its graph ownership.
        let index = layers.length()
        layers.push(@ui.nothing())
        let children = children.map(child => collect_layers(child, layers, ids))
        layers[index] = @ui.element("view", attrs~, children~)
        @ui.nothing()
      } else {
        @ui.element(
          tag,
          attrs~,
          children=children.map(child => collect_layers(child, layers, ids)),
        )
      }
  }
}

///|
/// Place all declarative layers after the content, outside scrolling and
/// clipped containers. Call once at the page's visual root.
pub fn[C : IsChildren] layer_root(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let layers : Array[@ui.Node] = []
  let ids : Map[String, Bool] = Map([])
  let body = children.map(child => collect_layers(child.raw, layers, ids))
  let keyed_layers : Array[@ui.KeyedNode] = []
  for layer in layers {
    let mut key = ""
    if layer is @ui.Element(_, attrs, _) {
      for attr in attrs {
        if attr.name == "id" {
          key = attr.value
        }
      }
    }
    keyed_layers.push(@ui.keyed(key, layer))
  }
  body.push(@ui.keyed_fragment(keyed_layers))
  wrap_node(
    @ui.element(
      "view",
      id~,
      class~,
      attrs=raw_element_attrs(style, "layer-root"),
      children=body,
    ),
    child_bindings(children),
  )
}
