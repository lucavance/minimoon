///|
fn prop_name(name : String) -> String {
  match name {
    "scroll-x" => "scrollX"
    "scroll-y" => "scrollY"
    "scroll-top" => "scrollTop"
    "scroll-left" => "scrollLeft"
    "scroll-into-view" => "scrollIntoView"
    "upper-threshold" => "upperThreshold"
    "lower-threshold" => "lowerThreshold"
    "item-id" => "itemId"
    "open-type" => "openType"
    "alt" => "alt"
    "aria-role" => "role"
    "aria-label" => "ariaLabel"
    "aria-expanded" => "ariaExpanded"
    "aria-selected" => "ariaSelected"
    "aria-disabled" => "ariaDisabled"
    "aria-hidden" => "ariaHidden"
    "aria-checked" => "ariaChecked"
    "aria-modal" => "ariaModal"
    "aria-controls" => "ariaControls"
    "aria-labelledby" => "ariaLabelledBy"
    "aria-describedby" => "ariaDescribedBy"
    "aria-orientation" => "ariaOrientation"
    "aria-haspopup" => "ariaHasPopup"
    name => name
  }
}

///|
fn event_prop_name(name : String) -> String {
  match name {
    "on_click" => "tap"
    "on_input" => "input"
    "on_change" => "change"
    "on_confirm" => "confirm"
    "on_focus" => "focus"
    "on_blur" => "blur"
    "on_scroll" => "scroll"
    "on_scrolltoupper" => "upper"
    "on_scrolltolower" => "lower"
    name => abort("unsupported MiniApp event attribute: " + name)
  }
}
