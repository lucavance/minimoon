///|
pub fn render_page_wxml(component_id : String, node : @ui.Node) -> String {
  let _ = node
  dynamic_page_wxml(component_id)
}

///|
priv struct MiniappTreeProps {
  props : Map[String, Json]
  events : Map[String, Json]
}

///|
fn empty_tree_props() -> MiniappTreeProps {
  { props: Map([]), events: Map([]), }
}

///|
fn[Msg] render_event_validation_error(
  key : String,
  expected : PageEventKind,
  events : Map[String, PageEvent[Msg]],
) -> String? {
  if key == "" {
    return Some("MiniApp render event key must not be empty")
  }
  match events.get(key) {
    Some(event) =>
      if event.kind == expected {
        None
      } else {
        Some(
          "MiniApp render event kind mismatch for " +
          key +
          ": expected " +
          expected.host_name() +
          ", declared " +
          event.kind.host_name(),
        )
      }
    None => Some("MiniApp render event is not declared: " + key)
  }
}

///|
fn common_tree_attr(name : String) -> Bool {
  name == "id" ||
  name == "class" ||
  name == "style" ||
  name == "data-minimoon-section" ||
  name == "aria-role" ||
  name == "aria-label" ||
  name == "aria-expanded" ||
  name == "aria-selected" ||
  name == "aria-disabled" ||
  name == "aria-hidden" ||
  name == "aria-checked" ||
  name == "aria-modal" ||
  name == "aria-controls" ||
  name == "aria-labelledby" ||
  name == "aria-describedby" ||
  name == "aria-orientation" ||
  name == "aria-haspopup"
}

///|
fn supported_tree_attr(tag : String, name : String) -> Bool {
  if common_tree_attr(name) || name == "on_click" {
    return true
  }
  match tag {
    "button" => name == "disabled"
    "input" =>
      name == "value" ||
      name == "placeholder" ||
      name == "disabled" ||
      name == "focus" ||
      name == "on_input" ||
      name == "on_confirm" ||
      name == "on_focus" ||
      name == "on_blur"
    "img" | "image" => name == "src" || name == "alt" || name == "aria-label"
    "scroll-view" =>
      name == "scroll-x" ||
      name == "scroll-y" ||
      name == "scroll-top" ||
      name == "scroll-left" ||
      name == "scroll-into-view" ||
      name == "upper-threshold" ||
      name == "lower-threshold" ||
      name == "on_scroll" ||
      name == "on_scrolltoupper" ||
      name == "on_scrolltolower"
    "textarea" =>
      name == "value" ||
      name == "placeholder" ||
      name == "maxlength" ||
      name == "disabled" ||
      name == "focus" ||
      name == "on_input" ||
      name == "on_confirm" ||
      name == "on_focus" ||
      name == "on_blur"
    "switch" =>
      name == "checked" ||
      name == "disabled" ||
      name == "color" ||
      name == "on_change"
    "checkbox-group" | "radio-group" => name == "on_change"
    "checkbox" | "radio" =>
      name == "value" ||
      name == "checked" ||
      name == "disabled" ||
      name == "color"
    "picker" =>
      name == "mode" ||
      name == "value" ||
      name == "value-index" ||
      name == "range-json" ||
      name == "disabled" ||
      name == "on_change"
    "swiper" =>
      name == "current" ||
      name == "autoplay" ||
      name == "circular" ||
      name == "interval" ||
      name == "duration" ||
      name == "on_change"
    "swiper-item" => name == "item-id"
    "navigator" => name == "url" || name == "open-type"
    _ => false
  }
}

///|
fn event_attr_kind(name : String) -> PageEventKind? {
  match name {
    "on_click" => Some(Tap)
    "on_input" => Some(Input)
    "on_change" => Some(Change)
    "on_confirm" => Some(page_event_kind("confirm"))
    "on_focus" => Some(page_event_kind("focus"))
    "on_blur" => Some(page_event_kind("blur"))
    "on_scroll" => Some(page_event_kind("scroll"))
    "on_scrolltoupper" => Some(page_event_kind("scrolltoupper"))
    "on_scrolltolower" => Some(page_event_kind("scrolltolower"))
    _ => None
  }
}

///|
fn supported_tree_tag(tag : String) -> Bool {
  tag == "div" ||
  tag == "view" ||
  tag == "h1" ||
  tag == "span" ||
  tag == "p" ||
  tag == "text" ||
  tag == "img" ||
  tag == "image" ||
  tag == "button" ||
  tag == "input" ||
  tag == "scroll-view" ||
  tag == "textarea" ||
  tag == "switch" ||
  tag == "checkbox-group" ||
  tag == "checkbox" ||
  tag == "radio-group" ||
  tag == "radio" ||
  tag == "picker" ||
  tag == "swiper" ||
  tag == "swiper-item" ||
  tag == "navigator"
}

///|
fn[Msg] checked_tree_props(
  tag : String,
  attrs : Array[@ui.Attr],
  events : Map[String, PageEvent[Msg]],
) -> Result[MiniappTreeProps, String] {
  let output = empty_tree_props()
  let names : Set[String] = Set([])
  for attr in attrs {
    if names.contains(attr.name) {
      return Err("duplicate MiniApp render attribute: " + attr.name)
    }
    names.add(attr.name)
    if !supported_tree_attr(tag, attr.name) {
      return Err("unsupported MiniApp render attribute: " + attr.name)
    }
    let value = attr.value
    match attr.name {
      name if event_attr_kind(name) is Some(kind) => {
        match render_event_validation_error(value, kind, events) {
          Some(error) => return Err(error)
          None => ()
        }
        output.events[event_prop_name(name)] = Json::string(value)
      }
      "class" =>
        output.props["className"] = Json::string(
          escape_miniapp_class_name(value),
        )
      "data-minimoon-section" => output.props["section"] = Json::string(value)
      "scroll-x"
      | "scroll-y"
      | "disabled"
      | "focus"
      | "checked"
      | "autoplay"
      | "circular"
      | "aria-expanded"
      | "aria-selected"
      | "aria-disabled"
      | "aria-hidden"
      | "aria-checked"
      | "aria-modal" =>
        output.props[prop_name(attr.name)] = Json::boolean(value == "true")
      "scroll-top"
      | "scroll-left"
      | "upper-threshold"
      | "lower-threshold"
      | "maxlength"
      | "value-index"
      | "current"
      | "interval"
      | "duration" => {
        let number = match signed_decimal(value) {
          Some(number) => number
          None => return Err("invalid integer MiniApp attribute: " + attr.name)
        }
        output.props[if attr.name == "value-index" {
          "value"
        } else {
          prop_name(attr.name)
        }] = Json::number(number.to_double(), repr=number.to_string())
      }
      "range-json" => {
        let range : Json? = Some(@json.parse(value)) catch { _ => None }
        match range {
          Some(range) => output.props["range"] = range
          None => return Err("invalid picker range JSON")
        }
      }
      "value" if tag == "picker" && value.has_prefix("[") => {
        let picker_value : Json? = Some(@json.parse(value)) catch { _ => None }
        match picker_value {
          Some(picker_value) => output.props["value"] = picker_value
          None => return Err("invalid picker value JSON")
        }
      }
      name if supported_tree_attr(tag, name) =>
        output.props[prop_name(name)] = Json::string(value)
      name => return Err("unsupported MiniApp render attribute: " + name)
    }
  }
  Ok(output)
}

///|
fn signed_decimal(value : String) -> Int? {
  if value == "" {
    return None
  }
  let negative = value[0] == '-'
  let start = if negative { 1 } else { 0 }
  if start == value.length() {
    return None
  }
  let result = Ref(0)
  for index = start; index < value.length(); index = index + 1 {
    let ch = value[index]
    if ch.to_int() < '0'.to_int() || ch.to_int() > '9'.to_int() {
      return None
    }
    result.val = result.val * 10 + ch.to_int() - '0'.to_int()
  }
  Some(if negative { -result.val } else { result.val })
}

///|
fn normalized_tree_node(
  kind : String,
  identity : String,
  text : String,
  props : MiniappTreeProps,
  children : Array[Json],
) -> Json {
  Json::object({
    "kind": Json::string(kind),
    "identity": Json::string(identity),
    "text": Json::string(text),
    "props": Json::object(props.props),
    "events": Json::object(props.events),
    "children": Json::array(children),
  })
}

///|
// Keep dynamic class names on the same host representation as the selectors
// emitted by weapp-tailwindcss. The recursive WXML binds `node.className`, so
// its classes cannot be rewritten by the adapter's static-WXML pass.
fn escape_miniapp_class_character(ch : Char) -> String? {
  match ch.to_int() {
    91 => Some("_b")
    93 => Some("_B")
    40 => Some("_p")
    41 => Some("_P")
    35 => Some("_h")
    33 => Some("_e")
    47 => Some("_f")
    92 => Some("_r")
    46 => Some("_d")
    58 => Some("_c")
    37 => Some("_v")
    44 => Some("_m")
    39 => Some("_a")
    34 => Some("_q")
    42 => Some("_x")
    38 => Some("_n")
    64 => Some("_t")
    123 => Some("_k")
    125 => Some("_K")
    43 => Some("_u")
    59 => Some("_j")
    60 => Some("_l")
    126 => Some("_w")
    61 => Some("_z")
    62 => Some("_g")
    63 => Some("_Q")
    94 => Some("_y")
    96 => Some("_i")
    124 => Some("_o")
    36 => Some("_s")
    code if code > 127 => Some("u_x" + code.to_string(radix=16) + "_")
    _ => None
  }
}

///|
fn escape_miniapp_class_token(token : String) -> String {
  let output = StringBuilder(size_hint=token.length())
  let chars = token.to_array()
  for index = 0; index < chars.length(); index = index + 1 {
    let ch = chars[index]
    match escape_miniapp_class_character(ch) {
      Some(value) => output.write_string(value)
      None => {
        let is_leading_digit = index == 0 && ch.is_ascii_digit()
        let is_ambiguous_dash = index == 0 &&
          ch == '-' &&
          (chars.length() == 1 || chars[1].is_ascii_digit())
        if is_leading_digit || is_ambiguous_dash {
          output.write_char('_')
        }
        output.write_char(ch)
      }
    }
  }
  output.to_string()
}

///|
fn escape_miniapp_class_name(class_name : String) -> String {
  let output = StringBuilder(size_hint=class_name.length())
  let token = StringBuilder()
  let has_output = Ref(false)
  let flush = () => {
    if !token.is_empty() {
      if has_output.val {
        output.write_char(' ')
      }
      output.write_string(escape_miniapp_class_token(token.to_string()))
      token.reset()
      has_output.val = true
    }
  }
  for ch in class_name.iter() {
    if ch.is_whitespace() {
      flush()
    } else {
      token.write_char(ch)
    }
  }
  flush()
  output.to_string()
}

///|
fn miniapp_tree_kind(tag : String) -> String {
  match tag {
    // Element containers stay recursive views. Only @ui.Text becomes a leaf
    // `text` node, so generated WXML never nests block/template nodes inside
    // a MiniApp <text> element.
    "div" | "view" | "h1" | "span" | "p" | "text" => "view"
    "img" | "image" => "image"
    "button" => "button"
    "input" => "input"
    "scroll-view" => "scroll-view"
    "textarea" => "textarea"
    "switch" => "switch"
    "checkbox-group" => "checkbox-group"
    "checkbox" => "checkbox"
    "radio-group" => "radio-group"
    "radio" => "radio"
    "picker" => "picker"
    "swiper" => "swiper"
    "swiper-item" => "swiper-item"
    "navigator" => "navigator"
    tag => abort("unsupported MiniApp render tag: " + tag)
  }
}
