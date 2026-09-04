///|
fn encoded_path_segment(value : String) -> String {
  let output = StringBuilder(size_hint=value.length())
  for character in value.iter() {
    if (character >= 'a' && character <= 'z') ||
      (character >= 'A' && character <= 'Z') ||
      (character >= '0' && character <= '9') ||
      character == '_' ||
      character == '-' {
      output.write_char(character)
    } else {
      output.write_char('_')
      output.write_string(character.to_int().to_string(radix=16))
      output.write_char('_')
    }
  }
  output.to_string()
}

///|
fn index_bindings(
  bindings : Array[NodeBinding],
  output : Map[String, @renderer.PageEvent[Cmd]],
) -> Unit {
  for binding in bindings {
    match binding {
      DirectBinding(event) => {
        guard !output.contains(event.key()) else {
          abort("duplicate event binding marker: " + event.key())
        }
        output[event.key()] = event
      }
      NestedBindings(children) => index_bindings(children, output)
    }
  }
}

///|
fn materialized_event_key(
  binding : @renderer.PageEvent[Cmd],
  path : String,
) -> String {
  let parts = binding.key().split("|").collect()
  if parts.length() > 1 && parts[1] != "" {
    parts[1].to_owned()
  } else {
    "v/" + path + "/" + binding.kind().host_name()
  }
}

///|
fn materialize_node(
  node : @ui.Node,
  path : String,
  bindings : Map[String, @renderer.PageEvent[Cmd]],
  events : @renderer.Events[GraphMessage],
) -> @ui.Node {
  match node {
    @ui.Text(_) | @ui.Empty => node
    @ui.Retained(identity, child) =>
      @ui.retained(identity, materialize_node(child, path, bindings, events))
    @ui.Fragment(children) => {
      let output : Array[@ui.Node] = []
      for index = 0; index < children.length(); index = index + 1 {
        output.push(
          materialize_node(
            children[index],
            path + "/i:" + index.to_string(),
            bindings,
            events,
          ),
        )
      }
      @ui.fragment(output)
    }
    @ui.KeyedFragment(children) => {
      let output : Array[@ui.KeyedNode] = []
      for child in children {
        output.push(
          @ui.keyed(
            child.key(),
            materialize_node(
              child.node(),
              path + "/k:" + encoded_path_segment(child.key()),
              bindings,
              events,
            ),
          ),
        )
      }
      @ui.keyed_fragment(output)
    }
    @ui.Element(tag, attrs, children) => {
      let next_attrs = attrs.map(attr => {
        if attr.name.has_prefix("on_") && attr.value.has_prefix("$minimoon:") {
          let binding = bindings
            .get(attr.value)
            .unwrap_or_else(fn() {
              abort("missing event binding: " + attr.value)
            })
          let key = materialized_event_key(binding, path)
          let _ = events.custom(key, binding.kind(), payload => {
            match binding.decode(payload) {
              Ok(command) => Ok(GraphMessage(command))
              Err(error) => Err(error)
            }
          })
          @ui.attr(attr.name, key)
        } else {
          attr
        }
      })
      let next_children : Array[@ui.Node] = []
      for index = 0; index < children.length(); index = index + 1 {
        next_children.push(
          materialize_node(
            children[index],
            path + "/i:" + index.to_string(),
            bindings,
            events,
          ),
        )
      }
      @ui.element(tag, attrs=next_attrs, children=next_children)
    }
  }
}

///|
fn materialize(
  node : Node,
  events : @renderer.Events[GraphMessage],
) -> @ui.Node {
  let bindings : Map[String, @renderer.PageEvent[Cmd]] = Map([])
  index_bindings(node.bindings, bindings)
  materialize_node(node.raw, "root", bindings, events)
}
