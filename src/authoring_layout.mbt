///|
/// A rectangle in logical px, relative to the screen's top-left corner.
pub(all) struct LayoutRect {
  left : Double
  top : Double
  width : Double
  height : Double
} derive(Eq, Debug, ToJson)

///|
/// Synchronous window information. The safe area may be unavailable.
pub(all) struct WindowMetrics {
  window_width : Double
  window_height : Double
  screen_width : Double
  screen_height : Double
  screen_top : Double
  status_bar_height : Double
  safe_area : LayoutRect?
} derive(Eq, Debug, ToJson)

///|
/// Page-owned layout facts, separate from immutable route input.
pub(all) struct PageLayout {
  window : WindowMetrics?
  menu_button : LayoutRect?
} derive(Eq, Debug, ToJson)

///|
pub fn PageLayout::unavailable() -> PageLayout {
  { window: None, menu_button: None, }
}

///|
fn layout_number(value : Double) -> Bool {
  // The upper bound also rejects infinities; comparisons reject NaN.
  value >= 0.0 && value <= 1000000.0
}

///|
fn LayoutRect::valid(self : LayoutRect) -> Bool {
  layout_number(self.left) &&
  layout_number(self.top) &&
  layout_number(self.width) &&
  layout_number(self.height) &&
  self.width > 0.0 &&
  self.height > 0.0
}

///|
fn LayoutRect::fits(self : LayoutRect, window : WindowMetrics) -> Bool {
  self.valid() &&
  self.left + self.width <= window.screen_width &&
  self.top + self.height <= window.screen_height
}

///|
fn WindowMetrics::valid(self : WindowMetrics) -> Bool {
  layout_number(self.window_width) &&
  self.window_width > 0.0 &&
  layout_number(self.window_height) &&
  self.window_height > 0.0 &&
  layout_number(self.screen_width) &&
  self.screen_width >= self.window_width &&
  layout_number(self.screen_height) &&
  self.screen_height >= self.window_height &&
  layout_number(self.screen_top) &&
  self.screen_top + self.window_height <= self.screen_height &&
  layout_number(self.status_bar_height) &&
  self.status_bar_height <= self.screen_height
}

///|
fn merge_layout(next : PageLayout, previous : PageLayout) -> PageLayout {
  let window = match next.window {
    Some(window) if window.valid() => {
      let safe_area = match window.safe_area {
        Some(rect) if rect.fits(window) => Some(rect)
        _ =>
          match previous.window {
            Some(previous) =>
              match previous.safe_area {
                Some(rect) if rect.fits(window) => Some(rect)
                _ => None
              }
            None => None
          }
      }
      Some({ ..window, safe_area, })
    }
    _ => previous.window
  }
  let valid_menu = fn(rect : LayoutRect) {
    rect.valid() &&
    (match window {
      Some(window) => rect.fits(window)
      None => true
    })
  }
  let menu_button = match next.menu_button {
    Some(rect) if valid_menu(rect) => Some(rect)
    _ =>
      match previous.menu_button {
        Some(rect) if valid_menu(rect) => Some(rect)
        _ => None
      }
  }
  { window, menu_button, }
}

///|
fn layout_json_number(value : Json, key : String) -> Double {
  // Negative values are rejected by the geometry validators below. Keeping the
  // failure sentinel private avoids allocating a separate Option for every px.
  match value {
    Object(fields) =>
      match fields.get(key) {
        Some(Number(value, ..)) => value
        _ => -1.0
      }
    _ => -1.0
  }
}

///|
fn layout_json_field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn decode_layout_rect(value : Json) -> LayoutRect? {
  let rect = LayoutRect::{
    left: layout_json_number(value, "left"),
    top: layout_json_number(value, "top"),
    width: layout_json_number(value, "width"),
    height: layout_json_number(value, "height"),
  }
  if rect.valid() {
    Some(rect)
  } else {
    None
  }
}

///|
fn decode_window_metrics(value : Json) -> WindowMetrics? {
  let window = WindowMetrics::{
    window_width: layout_json_number(value, "window_width"),
    window_height: layout_json_number(value, "window_height"),
    screen_width: layout_json_number(value, "screen_width"),
    screen_height: layout_json_number(value, "screen_height"),
    screen_top: layout_json_number(value, "screen_top"),
    status_bar_height: layout_json_number(value, "status_bar_height"),
    safe_area: decode_layout_rect(layout_json_field(value, "safe_area")),
  }
  if window.valid() {
    Some(window)
  } else {
    None
  }
}

///|
/// Decode the owned host layout envelope, dropping unavailable/invalid parts.
/// This never substitutes device dimensions or reads a host API.
pub fn PageLayout::from_json(value : Json) -> PageLayout {
  merge_layout(
    {
      window: decode_window_metrics(layout_json_field(value, "window")),
      menu_button: decode_layout_rect(layout_json_field(value, "menu_button")),
    },
    PageLayout::unavailable(),
  )
}

///|
priv struct PageLayoutState {
  value : Val[PageLayout]
  emit : Emit[PageLayout]
  pending : Ref[PageLayout?]
  visible : Ref[Bool]
}

///|
fn PageLayoutState::new(
  graph : @val.Graph,
  initial : PageLayout,
) -> PageLayoutState {
  // Host input needs the graph's existing transactional slot, not a second
  // generic application-state update/subscription adapter.
  let (value, emit) = graph.create_input(initial)
  {
    value: Val(value),
    emit: wrap_emit(emit),
    pending: Ref(None),
    visible: Ref(true),
  }
}

///|
fn PageLayoutState::command(self : PageLayoutState) -> Cmd {
  Cmd(
    @val.CmdMessage(fn() {
      if self.visible.val && self.pending.val is Some(layout) {
        self.pending.val = None
        // The message is consumed once, but its state write remains transactional.
        // Rejected projections roll back the Val, just like any business message.
        (self.emit)(layout).0
      } else {
        @val.CmdNone
      }
    }),
  )
}

///|
pub fn PageContext::layout(self : PageContext) -> Val[PageLayout] {
  self.layout_value
}

///|
fn PageRuntime::queue_layout(self : PageRuntime, layout : PageLayout) -> Unit {
  let previous = self.5.pending.val.unwrap_or_else(fn() {
    self.1.run(fn() { self.5.value.0.read() })
  })
  self.5.pending.val = Some(merge_layout(layout, previous))
}

///|
/// Update visible layout transactionally; hidden pages retain only the latest
/// metrics until Show. Invalid readings retain the last usable information.
pub fn PageRuntime::update_layout(
  self : PageRuntime,
  layout : PageLayout,
) -> String {
  if self.entry_error() is Some(error) {
    return error
  }
  self.queue_layout(layout)
  if self.5.visible.val {
    self.0.refresh()
  } else {
    "[]"
  }
}
