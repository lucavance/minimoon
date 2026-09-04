///|
let next_node_id : Ref[Int] = Ref(1)

///|
let next_binding_id : Ref[Int] = Ref(1)

///|
struct Node {
  id : Int
  raw : @ui.Node
  bindings : Array[NodeBinding]
}

///|
priv enum NodeBinding {
  DirectBinding(@renderer.PageEvent[Cmd])
  NestedBindings(Array[NodeBinding])
}

///|
pub impl Eq for Node with fn equal(left, right) {
  left.id == right.id
}

///|
struct KeyedNode {
  key : String
  node : Node
}

///|
pub trait IsChildren {
  fn to_nodes(Self) -> Array[Node]
}

///|
pub impl IsChildren for Array[Node] with fn to_nodes(self) {
  self
}

///|
pub impl IsChildren for Node with fn to_nodes(self) {
  [self]
}

///|
pub impl IsChildren for String with fn to_nodes(self) {
  [text(self)]
}

///|
pub(all) enum SemanticRole {
  GenericRole
  ButtonRole
  GroupRole
  HeadingRole
  RegionRole
  NavigationRole
  TabRole
  TabListRole
  TabPanelRole
  DialogRole
  MenuRole
  MenuItemRole
  MenuItemCheckboxRole
  MenuItemRadioRole
  SeparatorRole
} derive(Eq, Debug)

///|
struct Semantics {
  role : String
  label : String
  expanded : Bool?
  selected : Bool?
  disabled : Bool?
  hidden : Bool?
  checked : Bool?
  modal : Bool?
  controls : String
  labelled_by : String
  described_by : String
  orientation : String
  has_popup : String
}

///|
fn SemanticRole::host_name(self : SemanticRole) -> String {
  match self {
    GenericRole => "generic"
    ButtonRole => "button"
    GroupRole => "group"
    HeadingRole => "heading"
    RegionRole => "region"
    NavigationRole => "navigation"
    TabRole => "tab"
    TabListRole => "tablist"
    TabPanelRole => "tabpanel"
    DialogRole => "dialog"
    MenuRole => "menu"
    MenuItemRole => "menuitem"
    MenuItemCheckboxRole => "menuitemcheckbox"
    MenuItemRadioRole => "menuitemradio"
    SeparatorRole => "separator"
  }
}

///|
pub fn semantics(
  role? : SemanticRole,
  label? : String = "",
  expanded? : Bool,
  selected? : Bool,
  disabled? : Bool,
  hidden? : Bool,
  checked? : Bool,
  modal? : Bool,
  controls? : String = "",
  labelled_by? : String = "",
  described_by? : String = "",
  orientation? : String = "",
  has_popup? : String = "",
) -> Semantics {
  {
    role: role.map(value => value.host_name()).unwrap_or(""),
    label,
    expanded,
    selected,
    disabled,
    hidden,
    checked,
    modal,
    controls,
    labelled_by,
    described_by,
    orientation,
    has_popup,
  }
}

///|
fn raw_optional_bool_attr(
  attrs : Array[@ui.Attr],
  name : String,
  value : Bool?,
) -> Unit {
  match value {
    Some(value) => attrs.push(@ui.attr(name, value.to_string()))
    None => ()
  }
}

///|
fn raw_semantics_attrs(attrs : Array[@ui.Attr], value : Semantics?) -> Unit {
  match value {
    Some(value) => {
      raw_string_attr(attrs, "aria-role", value.role)
      raw_string_attr(attrs, "aria-label", value.label)
      raw_optional_bool_attr(attrs, "aria-expanded", value.expanded)
      raw_optional_bool_attr(attrs, "aria-selected", value.selected)
      raw_optional_bool_attr(attrs, "aria-disabled", value.disabled)
      raw_optional_bool_attr(attrs, "aria-hidden", value.hidden)
      raw_optional_bool_attr(attrs, "aria-checked", value.checked)
      raw_optional_bool_attr(attrs, "aria-modal", value.modal)
      raw_string_attr(attrs, "aria-controls", value.controls)
      raw_string_attr(attrs, "aria-labelledby", value.labelled_by)
      raw_string_attr(attrs, "aria-describedby", value.described_by)
      raw_string_attr(attrs, "aria-orientation", value.orientation)
      raw_string_attr(attrs, "aria-haspopup", value.has_popup)
    }
    None => ()
  }
}

///|
fn raw_element_attrs(
  style : String,
  data_section : String,
  semantics? : Semantics,
) -> Array[@ui.Attr] {
  let attrs : Array[@ui.Attr] = []
  if style != "" {
    attrs.push(@ui.style_attr(style))
  }
  if data_section != "" {
    attrs.push(@ui.attr("data-minimoon-section", data_section))
  }
  raw_semantics_attrs(attrs, semantics)
  attrs
}

///|
fn raw_bool_attr(attrs : Array[@ui.Attr], name : String, value : Bool) -> Unit {
  attrs.push(@ui.attr(name, value.to_string()))
}

///|
fn raw_int_attr(attrs : Array[@ui.Attr], name : String, value : Int) -> Unit {
  attrs.push(@ui.attr(name, value.to_string()))
}

///|
fn raw_string_attr(
  attrs : Array[@ui.Attr],
  name : String,
  value : String,
) -> Unit {
  if value != "" {
    attrs.push(@ui.attr(name, value))
  }
}

///|
fn raw_event_attr(
  attrs : Array[@ui.Attr],
  name : String,
  expected : String,
  event : @renderer.PageEvent[Cmd]?,
) -> Unit {
  match event {
    Some(event) => {
      guard event.kind().host_name() == expected else {
        abort(
          "MiniApp " +
          name +
          " requires a " +
          expected +
          " event: " +
          event.key(),
        )
      }
      attrs.push(@ui.attr(name, event.key()))
    }
    None => ()
  }
}

///|
fn wrap_node(raw : @ui.Node, bindings : Array[NodeBinding]) -> Node {
  let id = next_node_id.val
  next_node_id.val = id + 1
  { id, raw: @ui.retained(id, raw), bindings, }
}

///|
fn child_raw(children : Array[Node]) -> Array[@ui.Node] {
  children.map(child => child.raw)
}

///|
fn child_bindings(children : Array[Node]) -> Array[NodeBinding] {
  let output : Array[NodeBinding] = []
  for child in children {
    if child.bindings.length() > 0 {
      output.push(NestedBindings(child.bindings))
    }
  }
  output
}

///|
fn append_direct_binding(
  bindings : Array[NodeBinding],
  binding : @renderer.PageEvent[Cmd],
) -> Unit {
  bindings.push(DirectBinding(binding))
}

///|
fn event_binding(
  kind : @renderer.PageEventKind,
  decode : (Json) -> Result[Cmd, DecodeError],
  explicit_key? : String = "",
) -> @renderer.PageEvent[Cmd] {
  let id = next_binding_id.val
  next_binding_id.val = id + 1
  let marker = "$minimoon:" + id.to_string()
  let key = if explicit_key == "" {
    marker
  } else {
    marker + "|" + explicit_key
  }
  @renderer.page_event(key~, kind~, decode=payload => {
    match decode(payload) {
      Ok(command) => Ok(command)
      Err(error) => Err(@renderer.decode_error(error.message()))
    }
  })
}

///|
fn event_detail(payload : Json) -> Result[Map[String, Json], DecodeError] {
  match payload {
    Object(root) =>
      match root.get("detail") {
        Some(Object(detail)) => Ok(detail)
        Some(_) => Err(decode_error("event detail must be an object"))
        None => Err(decode_error("event detail is missing"))
      }
    _ => Err(decode_error("event payload must be an object"))
  }
}

///|
fn detail_string(payload : Json) -> Result[String, DecodeError] {
  match event_detail(payload) {
    Ok(detail) =>
      match detail.get("value") {
        Some(String(value)) => Ok(value)
        _ => Err(decode_error("event detail.value must be a string"))
      }
    Err(error) => Err(error)
  }
}

///|
fn detail_bool(payload : Json) -> Result[Bool, DecodeError] {
  match event_detail(payload) {
    Ok(detail) =>
      match detail.get("value") {
        Some(True) => Ok(true)
        Some(False) => Ok(false)
        _ => Err(decode_error("event detail.value must be a boolean"))
      }
    Err(error) => Err(error)
  }
}

///|
fn detail_strings(payload : Json) -> Result[Array[String], DecodeError] {
  match event_detail(payload) {
    Ok(detail) =>
      match detail.get("value") {
        Some(Array(values)) => {
          let output : Array[String] = []
          for value in values {
            match value {
              String(item) => output.push(item)
              _ =>
                return Err(
                  decode_error("event detail.value must contain strings"),
                )
            }
          }
          Ok(output)
        }
        _ => Err(decode_error("event detail.value must be an array"))
      }
    Err(error) => Err(error)
  }
}

///|
fn event_int32(value : Double) -> Int? {
  if value < 0.0 || value > 2147483647.0 {
    return None
  }
  let integer = value.to_int()
  if integer.to_double() == value {
    Some(integer)
  } else {
    None
  }
}

///|
fn decimal_index(value : String) -> Int? {
  if value == "" {
    return None
  }
  let result = Ref(0)
  for character in value.iter() {
    if character < '0' || character > '9' {
      return None
    }
    let digit = character.to_int() - '0'.to_int()
    if result.val > (2147483647 - digit) / 10 {
      return None
    }
    result.val = result.val * 10 + digit
  }
  Some(result.val)
}

///|
fn detail_index(payload : Json) -> Result[Int, DecodeError] {
  match event_detail(payload) {
    Ok(detail) =>
      match detail.get("value") {
        Some(String(value)) =>
          match decimal_index(value) {
            Some(index) => Ok(index)
            None => Err(decode_error("event detail.value must be an index"))
          }
        Some(Number(value, ..)) =>
          match event_int32(value) {
            Some(index) => Ok(index)
            None => Err(decode_error("event detail.value must be an index"))
          }
        _ => Err(decode_error("event detail.value must be an index"))
      }
    Err(error) => Err(error)
  }
}

///|
fn detail_current(payload : Json) -> Result[Int, DecodeError] {
  match event_detail(payload) {
    Ok(detail) =>
      match detail.get("current") {
        Some(Number(value, ..)) =>
          match event_int32(value) {
            Some(index) => Ok(index)
            None => Err(decode_error("event detail.current must be an index"))
          }
        _ => Err(decode_error("event detail.current must be an index"))
      }
    Err(error) => Err(error)
  }
}
