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
  name == "aria-haspopup" ||
  name == "aria-required" ||
  name == "aria-invalid" ||
  name == "aria-busy" ||
  name == "aria-live" ||
  name == "aria-valuemin" ||
  name == "aria-valuemax" ||
  name == "aria-valuenow" ||
  name == "aria-valuetext"
}

///|
fn supported_tree_attr(tag : String, name : String) -> Bool {
  if common_tree_attr(name) || name == "on_click" {
    return true
  }
  if name == "name" &&
    (
      tag == "textarea" ||
      tag == "switch" ||
      tag == "checkbox-group" ||
      tag == "radio-group" ||
      tag == "picker"
    ) {
    return true
  }
  match tag {
    "div" | "view" =>
      name == "catch-move" ||
      name == "on_longpress" ||
      name == "on_touchstart" ||
      name == "on_touchmove" ||
      name == "on_touchend" ||
      name == "on_touchcancel"
    "button" => name == "disabled" || name == "form-type" || name == "name"
    "input" =>
      name == "value" ||
      name == "placeholder" ||
      name == "disabled" ||
      name == "focus" ||
      name == "name" ||
      name == "type" ||
      name == "maxlength" ||
      name == "password" ||
      name == "selection-start" ||
      name == "selection-end" ||
      name == "on_input" ||
      name == "on_confirm" ||
      name == "on_focus" ||
      name == "on_blur"
    "img" | "image" =>
      name == "src" ||
      name == "alt" ||
      name == "aria-label" ||
      name == "mode" ||
      name == "on_load" ||
      name == "on_error"
    "label" => name == "for"
    "form" => name == "on_submit" || name == "on_reset"
    "slider" =>
      name == "value-index" ||
      name == "min" ||
      name == "max" ||
      name == "step" ||
      name == "disabled" ||
      name == "show-value" ||
      name == "active-color" ||
      name == "background-color" ||
      name == "block-color" ||
      name == "block-size" ||
      name == "name" ||
      name == "on_change" ||
      name == "on_changing"
    "progress" =>
      name == "percent" ||
      name == "stroke-width" ||
      name == "show-info" ||
      name == "active" ||
      name == "active-color" ||
      name == "background-color"
    "scroll-view" =>
      name == "scroll-x" ||
      name == "scroll-y" ||
      name == "scroll-top" ||
      name == "scroll-left" ||
      name == "scroll-top-px" ||
      name == "scroll-left-px" ||
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
      name == "vertical" ||
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
    "on_submit" => Some(page_event_kind("submit"))
    "on_reset" => Some(page_event_kind("reset"))
    "on_changing" => Some(page_event_kind("changing"))
    "on_load" => Some(page_event_kind("load"))
    "on_error" => Some(page_event_kind("error"))
    "on_longpress" => Some(page_event_kind("longpress"))
    "on_touchstart" => Some(page_event_kind("touchstart"))
    "on_touchmove" => Some(page_event_kind("touchmove"))
    "on_touchend" => Some(page_event_kind("touchend"))
    "on_touchcancel" => Some(page_event_kind("touchcancel"))
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
  tag == "navigator" ||
  tag == "label" ||
  tag == "form" ||
  tag == "slider" ||
  tag == "progress"
}
