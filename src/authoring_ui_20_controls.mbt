///|
pub fn button(
  on_tap~ : Cmd,
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
  disabled? : Bool = false,
  label : String,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("tap"),
    _ => Ok(on_tap),
    explicit_key=event_key,
  )
  let attrs = raw_element_attrs(style, data_section, semantics?)
  raw_bool_attr(attrs, "disabled", disabled)
  wrap_node(@ui.button(id~, class~, on_click=binding.key(), attrs~, label), [
    DirectBinding(binding),
  ])
}

///|
/// Native MiniApp focus payload shared by `input` and `textarea`.
pub struct FocusDetail {
  value : String
  height : Int
}

///|
/// Native MiniApp `input` blur payload.
pub struct InputBlurDetail {
  value : String
}

///|
/// Native MiniApp `textarea` blur payload.
pub struct TextareaBlurDetail {
  value : String
  cursor : Int
}

///|
fn detail_focus(payload : Json) -> Result[FocusDetail, DecodeError] {
  match detail_string(payload) {
    Err(error) => Err(error)
    Ok(value) =>
      match event_detail(payload) {
        Ok(detail) =>
          match detail_int(detail, "height") {
            Ok(height) => Ok({ value, height, })
            Err(error) => Err(error)
          }
        Err(error) => Err(error)
      }
  }
}

///|
fn detail_input_blur(payload : Json) -> Result[InputBlurDetail, DecodeError] {
  detail_string(payload).map(value => { value, })
}

///|
fn detail_textarea_blur(
  payload : Json,
) -> Result[TextareaBlurDetail, DecodeError] {
  match detail_string(payload) {
    Err(error) => Err(error)
    Ok(value) =>
      match event_detail(payload) {
        Ok(detail) =>
          match detail_int(detail, "cursor") {
            Ok(cursor) => Ok({ value, cursor, })
            Err(error) => Err(error)
          }
        Err(error) => Err(error)
      }
  }
}

///|
pub fn input(
  value~ : String,
  on_input~ : Emit[String],
  event_key? : String = "",
  disabled? : Bool = false,
  focus? : Bool = false,
  on_confirm? : Emit[String],
  confirm_key? : String = "",
  on_focus? : Emit[FocusDetail],
  focus_key? : String = "",
  on_blur? : Emit[InputBlurDetail],
  blur_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  placeholder? : String = "",
  semantics? : Semantics,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("input"),
    payload => {
      match detail_string(payload) {
        Ok(value) => Ok(on_input(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let confirm_binding = on_confirm.map(send => {
    event_binding(
      @renderer.page_event_kind("confirm"),
      payload => detail_string(payload).map(value => send(value)),
      explicit_key=confirm_key,
    )
  })
  let focus_binding = on_focus.map(send => {
    event_binding(
      @renderer.page_event_kind("focus"),
      payload => detail_focus(payload).map(value => send(value)),
      explicit_key=focus_key,
    )
  })
  let blur_binding = on_blur.map(send => {
    event_binding(
      @renderer.page_event_kind("blur"),
      payload => detail_input_blur(payload).map(value => send(value)),
      explicit_key=blur_key,
    )
  })
  let bindings = [DirectBinding(binding)]
  for optional_binding in [confirm_binding, focus_binding, blur_binding] {
    match optional_binding {
      Some(value) => append_direct_binding(bindings, value)
      None => ()
    }
  }
  let attrs = raw_element_attrs(style, data_section, semantics?)
  attrs.push(@ui.value_attr(value))
  raw_bool_attr(attrs, "disabled", disabled)
  raw_bool_attr(attrs, "focus", focus)
  raw_event_attr(attrs, "on_input", "input", Some(binding))
  raw_event_attr(attrs, "on_confirm", "confirm", confirm_binding)
  raw_event_attr(attrs, "on_focus", "focus", focus_binding)
  raw_event_attr(attrs, "on_blur", "blur", blur_binding)
  raw_string_attr(attrs, "placeholder", placeholder)
  wrap_node(@ui.input(id~, class~, attrs~), bindings)
}

///|
pub fn switch(
  checked~ : Bool,
  on_change~ : Emit[Bool],
  event_key? : String = "",
  disabled? : Bool = false,
  color? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_bool(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let attrs = raw_element_attrs(style, data_section, semantics?)
  raw_bool_attr(attrs, "checked", checked)
  raw_bool_attr(attrs, "disabled", disabled)
  raw_string_attr(attrs, "color", color)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(@ui.element("switch", id~, class~, attrs~), [DirectBinding(binding)])
}

///|
pub fn[C : IsChildren] checkbox_group(
  on_change~ : Emit[Array[String]],
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_strings(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, data_section)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(
    @ui.element(
      "checkbox-group",
      id~,
      class~,
      attrs~,
      children=child_raw(children),
    ),
    bindings,
  )
}

///|
pub fn[C : IsChildren] checkbox(
  value~ : String,
  checked? : Bool = false,
  disabled? : Bool = false,
  color? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.value_attr(value))
  raw_bool_attr(attrs, "checked", checked)
  raw_bool_attr(attrs, "disabled", disabled)
  raw_string_attr(attrs, "color", color)
  wrap_node(
    @ui.element("checkbox", id~, class~, attrs~, children=child_raw(children)),
    child_bindings(children),
  )
}

///|
pub fn[C : IsChildren] radio_group(
  on_change~ : Emit[String],
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_string(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, data_section)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(
    @ui.element(
      "radio-group",
      id~,
      class~,
      attrs~,
      children=child_raw(children),
    ),
    bindings,
  )
}

///|
pub fn[C : IsChildren] radio(
  value~ : String,
  checked? : Bool = false,
  disabled? : Bool = false,
  color? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.value_attr(value))
  raw_bool_attr(attrs, "checked", checked)
  raw_bool_attr(attrs, "disabled", disabled)
  raw_string_attr(attrs, "color", color)
  wrap_node(
    @ui.element("radio", id~, class~, attrs~, children=child_raw(children)),
    child_bindings(children),
  )
}

///|
pub struct ScrollDetail {
  scroll_left : Double
  scroll_top : Double
  scroll_height : Double
  scroll_width : Double
  delta_x : Double
  delta_y : Double
}

///|
fn detail_int(
  detail : Map[String, Json],
  name : String,
) -> Result[Int, DecodeError] {
  match detail.get(name) {
    Some(Number(value, ..)) =>
      match event_int32(value) {
        Some(integer) => Ok(integer)
        None =>
          Err(
            decode_error(
              "event detail." +
              name +
              " must be an integer from 0 to 2147483647",
            ),
          )
      }
    _ =>
      Err(
        decode_error(
          "event detail." + name + " must be an integer from 0 to 2147483647",
        ),
      )
  }
}

///|
fn detail_number(
  detail : Map[String, Json],
  name : String,
) -> Result[Double, DecodeError] {
  match detail.get(name) {
    Some(Number(value, ..)) => Ok(value)
    _ => Err(decode_error("event detail." + name + " must be a number"))
  }
}

///|
fn detail_scroll(payload : Json) -> Result[ScrollDetail, DecodeError] {
  match event_detail(payload) {
    Ok(detail) => {
      let scroll_left = match detail_number(detail, "scrollLeft") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let scroll_top = match detail_number(detail, "scrollTop") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let scroll_height = match detail_number(detail, "scrollHeight") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let scroll_width = match detail_number(detail, "scrollWidth") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let delta_x = match detail_number(detail, "deltaX") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let delta_y = match detail_number(detail, "deltaY") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      Ok({
        scroll_left,
        scroll_top,
        scroll_height,
        scroll_width,
        delta_x,
        delta_y,
      })
    }
    Err(error) => Err(error)
  }
}

///|
pub fn[C : IsChildren] scroll_view(
  scroll_x? : Bool = false,
  scroll_y? : Bool = false,
  scroll_top? : Int = 0,
  scroll_left? : Int = 0,
  scroll_into_view? : String = "",
  upper_threshold? : Int = 50,
  lower_threshold? : Int = 50,
  on_scroll? : Emit[ScrollDetail],
  scroll_key? : String = "",
  on_upper? : Cmd,
  upper_key? : String = "",
  on_lower? : Cmd,
  lower_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  children : C,
) -> Node {
  let scroll_binding = on_scroll.map(send => {
    event_binding(
      @renderer.page_event_kind("scroll"),
      payload => {
        match detail_scroll(payload) {
          Ok(value) => Ok(send(value))
          Err(error) => Err(error)
        }
      },
      explicit_key=scroll_key,
    )
  })
  let upper_binding = on_upper.map(command => {
    event_binding(
      @renderer.page_event_kind("scrolltoupper"),
      _ => Ok(command),
      explicit_key=upper_key,
    )
  })
  let lower_binding = on_lower.map(command => {
    event_binding(
      @renderer.page_event_kind("scrolltolower"),
      _ => Ok(command),
      explicit_key=lower_key,
    )
  })
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  for binding in [scroll_binding, upper_binding, lower_binding] {
    match binding {
      Some(value) => append_direct_binding(bindings, value)
      None => ()
    }
  }
  let attrs = raw_element_attrs(style, data_section)
  raw_bool_attr(attrs, "scroll-x", scroll_x)
  raw_bool_attr(attrs, "scroll-y", scroll_y)
  raw_int_attr(attrs, "scroll-top", scroll_top)
  raw_int_attr(attrs, "scroll-left", scroll_left)
  raw_string_attr(attrs, "scroll-into-view", scroll_into_view)
  raw_int_attr(attrs, "upper-threshold", upper_threshold)
  raw_int_attr(attrs, "lower-threshold", lower_threshold)
  raw_event_attr(attrs, "on_scroll", "scroll", scroll_binding)
  raw_event_attr(attrs, "on_scrolltoupper", "scrolltoupper", upper_binding)
  raw_event_attr(attrs, "on_scrolltolower", "scrolltolower", lower_binding)
  wrap_node(
    @ui.element(
      "scroll-view",
      id~,
      class~,
      attrs~,
      children=child_raw(children),
    ),
    bindings,
  )
}

///|
pub fn textarea(
  value~ : String,
  on_input~ : Emit[String],
  input_key? : String = "",
  placeholder? : String = "",
  maxlength? : Int = 140,
  disabled? : Bool = false,
  focus? : Bool = false,
  on_confirm? : Emit[String],
  confirm_key? : String = "",
  on_focus? : Emit[FocusDetail],
  focus_key? : String = "",
  on_blur? : Emit[TextareaBlurDetail],
  blur_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  data_section? : String = "",
  semantics? : Semantics,
) -> Node {
  let input_binding = event_binding(
    @renderer.page_event_kind("input"),
    payload => {
      match detail_string(payload) {
        Ok(value) => Ok(on_input(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=input_key,
  )
  let confirm_binding = on_confirm.map(send => {
    event_binding(
      @renderer.page_event_kind("confirm"),
      payload => {
        match detail_string(payload) {
          Ok(value) => Ok(send(value))
          Err(error) => Err(error)
        }
      },
      explicit_key=confirm_key,
    )
  })
  let focus_binding = on_focus.map(send => {
    event_binding(
      @renderer.page_event_kind("focus"),
      payload => detail_focus(payload).map(value => send(value)),
      explicit_key=focus_key,
    )
  })
  let blur_binding = on_blur.map(send => {
    event_binding(
      @renderer.page_event_kind("blur"),
      payload => detail_textarea_blur(payload).map(value => send(value)),
      explicit_key=blur_key,
    )
  })
  let bindings = [DirectBinding(input_binding)]
  for optional_binding in [confirm_binding, focus_binding, blur_binding] {
    match optional_binding {
      Some(value) => append_direct_binding(bindings, value)
      None => ()
    }
  }
  let attrs = raw_element_attrs(style, data_section, semantics?)
  attrs.push(@ui.value_attr(value))
  raw_string_attr(attrs, "placeholder", placeholder)
  raw_int_attr(attrs, "maxlength", maxlength)
  raw_bool_attr(attrs, "disabled", disabled)
  raw_bool_attr(attrs, "focus", focus)
  raw_event_attr(attrs, "on_input", "input", Some(input_binding))
  raw_event_attr(attrs, "on_confirm", "confirm", confirm_binding)
  raw_event_attr(attrs, "on_focus", "focus", focus_binding)
  raw_event_attr(attrs, "on_blur", "blur", blur_binding)
  wrap_node(@ui.element("textarea", id~, class~, attrs~), bindings)
}

///|
pub fn[C : IsChildren] picker_selector(
  options~ : Array[String],
  selected~ : Int,
  on_change~ : Emit[Int],
  event_key? : String = "",
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_index(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.attr("mode", "selector"))
  attrs.push(
    @ui.attr(
      "range-json",
      Json::array(options.map(value => Json::string(value))).stringify(),
    ),
  )
  raw_int_attr(attrs, "value-index", selected)
  raw_bool_attr(attrs, "disabled", disabled)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(
    @ui.element("picker", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] picker_date(
  value~ : String,
  on_change~ : Emit[String],
  disabled? : Bool = false,
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_string(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.attr("mode", "date"))
  attrs.push(@ui.attr("value", value))
  raw_bool_attr(attrs, "disabled", disabled)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(
    @ui.element("picker", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] picker_time(
  value~ : String,
  on_change~ : Emit[String],
  disabled? : Bool = false,
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_string(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.attr("mode", "time"))
  attrs.push(@ui.attr("value", value))
  raw_bool_attr(attrs, "disabled", disabled)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(
    @ui.element("picker", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] picker_region(
  value~ : Array[String],
  on_change~ : Emit[Array[String]],
  disabled? : Bool = false,
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let binding = event_binding(
    @renderer.page_event_kind("change"),
    payload => {
      match detail_strings(payload) {
        Ok(value) => Ok(on_change(value))
        Err(error) => Err(error)
      }
    },
    explicit_key=event_key,
  )
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  append_direct_binding(bindings, binding)
  let attrs = raw_element_attrs(style, "")
  attrs.push(@ui.attr("mode", "region"))
  attrs.push(
    @ui.attr(
      "value",
      Json::array(value.map(item => Json::string(item))).stringify(),
    ),
  )
  raw_bool_attr(attrs, "disabled", disabled)
  raw_event_attr(attrs, "on_change", "change", Some(binding))
  wrap_node(
    @ui.element("picker", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] swiper(
  current? : Int = 0,
  autoplay? : Bool = false,
  circular? : Bool = false,
  interval? : Int = 5000,
  duration? : Int = 500,
  on_change? : Emit[Int],
  event_key? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let change_binding = on_change.map(send => {
    event_binding(
      @renderer.page_event_kind("change"),
      payload => {
        match detail_current(payload) {
          Ok(value) => Ok(send(value))
          Err(error) => Err(error)
        }
      },
      explicit_key=event_key,
    )
  })
  let children = children.to_nodes()
  let bindings = child_bindings(children)
  match change_binding {
    Some(binding) => append_direct_binding(bindings, binding)
    None => ()
  }
  let attrs = raw_element_attrs(style, "")
  raw_int_attr(attrs, "current", current)
  raw_bool_attr(attrs, "autoplay", autoplay)
  raw_bool_attr(attrs, "circular", circular)
  raw_int_attr(attrs, "interval", interval)
  raw_int_attr(attrs, "duration", duration)
  raw_event_attr(attrs, "on_change", "change", change_binding)
  wrap_node(
    @ui.element("swiper", id~, class~, attrs~, children=child_raw(children)),
    bindings,
  )
}

///|
pub fn[C : IsChildren] swiper_item(
  item_id? : String = "",
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> Node {
  let children = children.to_nodes()
  let attrs = raw_element_attrs(style, "")
  raw_string_attr(attrs, "item-id", item_id)
  wrap_node(
    @ui.element(
      "swiper-item",
      id~,
      class~,
      attrs~,
      children=child_raw(children),
    ),
    child_bindings(children),
  )
}
