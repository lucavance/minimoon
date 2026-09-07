///|
pub(all) enum InputType {
  TextInput
  NumberInput
  DigitInput
  IdCardInput
} derive(Eq, Debug)

///|
fn InputType::host_name(self : InputType) -> String {
  match self {
    TextInput => "text"
    NumberInput => "number"
    DigitInput => "digit"
    IdCardInput => "idcard"
  }
}

///|
pub(all) enum ImageMode {
  ScaleToFill
  AspectFit
  AspectFill
  WidthFix
  HeightFix
  ImageCenter
} derive(Eq, Debug)

///|
fn ImageMode::host_name(self : ImageMode) -> String {
  match self {
    ScaleToFill => "scaleToFill"
    AspectFit => "aspectFit"
    AspectFill => "aspectFill"
    WidthFix => "widthFix"
    HeightFix => "heightFix"
    ImageCenter => "center"
  }
}

///|
pub struct ImageLoadDetail {
  width : Double
  height : Double
} derive(Eq, Debug)

///|
fn finite_number(value : Double) -> Bool {
  value == value && value - value == 0.0
}

///|
fn finite_detail_number(
  fields : Map[String, Json],
  key : String,
) -> Result[Double, DecodeError] {
  match fields.get(key) {
    Some(Number(value, ..)) if finite_number(value) => Ok(value)
    _ => Err(decode_error("event " + key + " must be a finite number"))
  }
}

///|
fn detail_image_load(payload : Json) -> Result[ImageLoadDetail, DecodeError] {
  let fields = match event_detail(payload) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let width = match finite_detail_number(fields, "width") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let height = match finite_detail_number(fields, "height") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if width < 0.0 || height < 0.0 {
    Err(decode_error("image dimensions must not be negative"))
  } else {
    Ok({ width, height, })
  }
}

///|
fn detail_image_error(payload : Json) -> Result[String, DecodeError] {
  let fields = match event_detail(payload) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match fields.get("errMsg") {
    Some(String(message)) => Ok(message)
    _ => Err(decode_error("image error.errMsg must be a string"))
  }
}

///|
pub(all) enum FormButtonType {
  SubmitForm
  ResetForm
} derive(Eq, Debug)

///|
/// Native button with rich children. The existing string-label button is unchanged.
pub fn[C : IsChildren] button_children(
  on_tap~ : Cmd,
  event_key? : String = "",
  disabled? : Bool = false,
  form_type? : FormButtonType,
  name? : String = "",
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
  let attrs = raw_element_attrs(style, data_section, semantics?)
  raw_bool_attr(attrs, "disabled", disabled)
  raw_string_attr(attrs, "name", name)
  if form_type is Some(value) {
    raw_string_attr(
      attrs,
      "form-type",
      match value {
        SubmitForm => "submit"
        ResetForm => "reset"
      },
    )
  }
  raw_event_attr(attrs, "on_click", "tap", Some(binding))
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  wrap_node(
    @ui.element("button", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] label(
  for_id~ : String,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, "")
  raw_string_attr(attrs, "for", for_id)
  wrap_node(
    @ui.element("label", id~, class~, attrs~, children=child_raw(children)),
    child_bindings(children),
  )
}

///|
pub fn[C : IsChildren] form(
  on_submit~ : Emit[Map[String, Json]],
  on_reset? : Cmd,
  submit_key? : String = "",
  reset_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, "")
  let submit = event_binding(
    @renderer.page_event_kind("submit"),
    payload => {
      let fields = match event_detail(payload) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match fields.get("value") {
        Some(Object(value)) => Ok(on_submit(value))
        _ => Err(decode_error("form detail.value must be an object"))
      }
    },
    explicit_key=submit_key,
  )
  let reset = on_reset.map(command => {
    event_binding(
      @renderer.page_event_kind("reset"),
      _ => Ok(command),
      explicit_key=reset_key,
    )
  })
  let bindings = child_bindings(children)
  append_direct_binding(bindings, submit)
  if reset is Some(binding) {
    append_direct_binding(bindings, binding)
  }
  raw_event_attr(attrs, "on_submit", "submit", Some(submit))
  raw_event_attr(attrs, "on_reset", "reset", reset)
  wrap_node(
    @ui.element("form", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
fn detail_slider(payload : Json) -> Result[Int, DecodeError] {
  let fields = match event_detail(payload) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let value = match finite_detail_number(fields, "value") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if value < -2147483648.0 ||
    value > 2147483647.0 ||
    value.to_int().to_double() != value {
    Err(decode_error("slider value must be an integer"))
  } else {
    Ok(value.to_int())
  }
}

///|
pub fn slider(
  value~ : Int,
  on_change~ : Emit[Int],
  on_changing? : Emit[Int],
  min? : Int = 0,
  max? : Int = 100,
  step? : Int = 1,
  disabled? : Bool = false,
  show_value? : Bool = false,
  active_color? : String = "",
  background_color? : String = "",
  block_color? : String = "",
  block_size? : Int = 28,
  name? : String = "",
  event_key? : String = "",
  changing_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  semantics? : Semantics,
) -> Node {
  guard min < max &&
    step > 0 &&
    (max.to_int64() - min.to_int64()) % step.to_int64() == 0L else {
    abort("slider requires min < max and a positive step dividing the range")
  }
  guard value >= min && value <= max && block_size >= 12 && block_size <= 28 else {
    abort("slider value or block size is out of range")
  }
  let attrs = raw_element_attrs(style, "", semantics?)
  for
    pair in [
      ("value-index", value),
      ("min", min),
      ("max", max),
      ("step", step),
      ("block-size", block_size),
    ] {
    raw_int_attr(attrs, pair.0, pair.1)
  }
  raw_bool_attr(attrs, "disabled", disabled)
  raw_bool_attr(attrs, "show-value", show_value)
  for
    pair in [
      ("active-color", active_color),
      ("background-color", background_color),
      ("block-color", block_color),
      ("name", name),
    ] {
    raw_string_attr(attrs, pair.0, pair.1)
  }
  let change = event_binding(
    @renderer.page_event_kind("change"),
    payload => detail_slider(payload).map(value => on_change(value)),
    explicit_key=event_key,
  )
  let changing = on_changing.map(send => {
    event_binding(
      @renderer.page_event_kind("changing"),
      payload => detail_slider(payload).map(value => send(value)),
      explicit_key=changing_key,
    )
  })
  let bindings = [DirectBinding(change)]
  if changing is Some(binding) {
    append_direct_binding(bindings, binding)
  }
  raw_event_attr(attrs, "on_change", "change", Some(change))
  raw_event_attr(attrs, "on_changing", "changing", changing)
  wrap_node(@ui.element("slider", id~, class~, attrs~), bindings)
}

///|
pub fn progress(
  percent~ : Int,
  stroke_width? : Int = 6,
  show_info? : Bool = false,
  active? : Bool = false,
  active_color? : String = "",
  background_color? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  semantics? : Semantics,
) -> Node {
  guard percent >= 0 && percent <= 100 && stroke_width > 0 else {
    abort("progress requires a percentage in 0..100 and positive stroke width")
  }
  let attrs = raw_element_attrs(style, "", semantics?)
  raw_int_attr(attrs, "percent", percent)
  raw_int_attr(attrs, "stroke-width", stroke_width)
  raw_bool_attr(attrs, "show-info", show_info)
  raw_bool_attr(attrs, "active", active)
  raw_string_attr(attrs, "active-color", active_color)
  raw_string_attr(attrs, "background-color", background_color)
  wrap_node(@ui.element("progress", id~, class~, attrs~), [])
}

///|
pub struct TouchPoint {
  identifier : Int
  client_x : Double
  client_y : Double
  page_x : Double
  page_y : Double
} derive(Eq, Debug)

///|
pub struct TouchDetail {
  touches : Array[TouchPoint]
  changed_touches : Array[TouchPoint]
  timestamp : Double
} derive(Eq, Debug)

///|
fn touch_point(value : Json) -> Result[TouchPoint, DecodeError] {
  guard value is Object(fields) else {
    return Err(decode_error("touch point must be an object"))
  }
  let identifier = match finite_detail_number(fields, "identifier") {
    Ok(value) =>
      match event_int32(value) {
        Some(value) => value
        None =>
          return Err(
            decode_error("touch identifier must be a nonnegative integer"),
          )
      }
    Err(error) => return Err(error)
  }
  let client_x = match finite_detail_number(fields, "clientX") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let client_y = match finite_detail_number(fields, "clientY") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let page_x = match finite_detail_number(fields, "pageX") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let page_y = match finite_detail_number(fields, "pageY") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ identifier, client_x, client_y, page_x, page_y, })
}

///|
fn touch_points(
  root : Map[String, Json],
  name : String,
) -> Result[Array[TouchPoint], DecodeError] {
  guard root.get(name) is Some(Array(values)) else {
    return Err(decode_error(name + " must be an array"))
  }
  let points : Array[TouchPoint] = []
  let ids : Set[Int] = Set([])
  for value in values {
    match touch_point(value) {
      Ok(point) => {
        if ids.contains(point.identifier) {
          return Err(decode_error("duplicate touch identifier"))
        }
        ids.add(point.identifier)
        points.push(point)
      }
      Err(error) => return Err(error)
    }
  }
  Ok(points)
}

///|
fn detail_touch(payload : Json) -> Result[TouchDetail, DecodeError] {
  guard payload is Object(root) else {
    return Err(decode_error("touch event must be an object"))
  }
  let timestamp = match finite_detail_number(root, "timeStamp") {
    Ok(value) if value >= 0.0 => value
    _ => return Err(decode_error("touch timestamp must be nonnegative"))
  }
  let touches = match touch_points(root, "touches") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  touch_points(root, "changedTouches").map(changed_touches => {
    touches,
    changed_touches,
    timestamp,
  })
}

///|
pub fn[C : IsChildren] touch_view(
  on_tap? : Cmd,
  on_long_press? : Emit[TouchDetail],
  on_touch_start? : Emit[TouchDetail],
  on_touch_move? : Emit[TouchDetail],
  on_touch_end? : Emit[TouchDetail],
  on_touch_cancel? : Emit[TouchDetail],
  catch_move? : Bool = false,
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, data_section, semantics?)
  let bindings = child_bindings(children)
  raw_bool_attr(attrs, "catch-move", catch_move)
  if on_tap is Some(command) {
    let binding = event_binding(
      @renderer.page_event_kind("tap"),
      _ => Ok(command),
      explicit_key=if event_key == "" { "" } else { event_key + "/tap" },
    )
    raw_event_attr(attrs, "on_click", "tap", Some(binding))
    append_direct_binding(bindings, binding)
  }
  for
    pair in [
      ("longpress", on_long_press),
      ("touchstart", on_touch_start),
      ("touchmove", on_touch_move),
      ("touchend", on_touch_end),
      ("touchcancel", on_touch_cancel),
    ] {
    if pair.1 is Some(send) {
      let kind = pair.0
      let binding = event_binding(
        @renderer.page_event_kind(kind),
        payload => detail_touch(payload).map(value => send(value)),
        explicit_key=if event_key == "" { "" } else { event_key + "/" + kind },
      )
      raw_event_attr(attrs, "on_" + kind, kind, Some(binding))
      append_direct_binding(bindings, binding)
    }
  }
  wrap_node(
    @ui.element("view", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}
