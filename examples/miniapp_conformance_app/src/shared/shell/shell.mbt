///|
/// Logical px from the host; None uses the reviewed conservative fallback.
fn navigation_pixels(layout : @minimoon.PageLayout) -> Double {
  let origin = layout.window.map(window => window.screen_top).unwrap_or(0.0)
  let status = layout.window.map(window => {
    Double::max(0.0, window.status_bar_height - origin)
  })
  let menu = layout.menu_button.map(rect => {
    Double::max(0.0, rect.top + rect.height - origin) + 8.0
  })
  match (status, menu) {
    (None, None) => 88.0
    (Some(status), None) => status + 44.0
    (None, Some(menu)) => menu
    (Some(status), Some(menu)) => Double::max(status + 44.0, menu)
  }
}

///|
pub fn navigation_height(layout : @minimoon.PageLayout) -> String {
  navigation_pixels(layout).to_string() + "px"
}

///|
pub fn bottom_inset(layout : @minimoon.PageLayout) -> Double {
  match layout.window {
    Some(window) =>
      match window.safe_area {
        Some(safe) =>
          Double::max(
            0.0,
            window.screen_top + window.window_height - safe.top - safe.height,
          )
        None => 0.0
      }
    None => 0.0
  }
}

///|
fn title_bottom(layout : @minimoon.PageLayout) -> Double {
  match layout.menu_button {
    Some(menu) => {
      let origin = layout.window.map(window => window.screen_top).unwrap_or(0.0)
      Double::max(
        0.0,
        navigation_pixels(layout) -
        (menu.top + menu.height / 2.0 - origin) -
        14.0,
      )
    }
    None => 8.0
  }
}

///|
pub fn hero(
  title : String,
  subtitle : String,
  section : String,
  home? : Bool = false,
) -> @minimoon.Node {
  @minimoon.div(
    class=if home { "demo-hero demo-hero-home" } else { "demo-hero" },
    data_section=section,
    [
      @minimoon.h1(class="demo-title", title),
      @minimoon.p(class="demo-hero-note", subtitle),
    ],
  )
}

///|
pub fn frame(
  layout : @minimoon.PageLayout,
  title : String,
  section : String,
  children : Array[@minimoon.Node],
  scroll_target? : String = "",
  on_scroll? : @minimoon.Emit[@minimoon.ScrollDetail],
  scroll_key? : String = "",
) -> @minimoon.Node {
  let band = navigation_height(layout)
  let viewport = layout.window
    .map(window => window.window_height.to_string() + "px")
    .unwrap_or("100vh")
  let reserved = match (layout.window, layout.menu_button) {
    (Some(window), Some(menu)) =>
      Double::max(12.0, window.window_width - menu.left + 12.0).to_string() +
      "px"
    _ => "96px"
  }
  @minimoon.div(class="demo-screen", style="height:" + viewport + ";", [
    @minimoon.div(
      class="demo-nav",
      data_section="safe-navigation",
      style="height:" +
        band +
        ";padding-right:" +
        reserved +
        ";padding-bottom:" +
        title_bottom(layout).to_string() +
        "px;",
      @minimoon.p(class="demo-nav-title", title),
    ),
    @minimoon.scroll_view(
      class="demo-scroll",
      data_section=section,
      style="top:" + band + ";height:calc(100% - " + band + ");",
      scroll_y=true,
      scroll_into_view=scroll_target,
      on_scroll?,
      scroll_key~,
      [
        @minimoon.div(
          style="padding-bottom:" + bottom_inset(layout).to_string() + "px;",
          children,
        ),
      ],
    ),
  ])
}

///|
pub fn card(
  title : String,
  children : Array[@minimoon.Node],
  section? : String = "",
) -> @minimoon.Node {
  @minimoon.div(
    class="demo-card",
    data_section=section,
    [@minimoon.p(class="demo-card-title", title), ..children],
  )
}

///|
/// This is a fixture-local function, not a new framework/UI component.
/// Allocate once in the page builder; collapsing never disposes probe state.
pub fn technical_notes(
  id : String,
  notes : Array[String],
) -> @minimoon.Val[@minimoon.Node] {
  let (open, toggle) = @minimoon.create_variable(false)
  open.view(open => {
    @minimoon.div(class="demo-notes", [
      @minimoon.button(
        class="demo-note-toggle",
        event_key=id + "/notes",
        on_tap=toggle(value => !value),
        if open {
          "收起技术说明 −"
        } else {
          "技术说明 +"
        },
      ),
      if open {
        @minimoon.div(
          class="demo-note-content",
          notes.map(note => @minimoon.p(note)),
        )
      } else {
        @minimoon.nothing()
      },
    ])
  })
}
