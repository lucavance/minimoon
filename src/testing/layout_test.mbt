///|
fn testing_layout(width : Double) -> @minimoon.PageLayout {
  {
    window: Some({
      window_width: width,
      window_height: 700.0,
      screen_width: width,
      screen_height: 812.0,
      screen_top: 0.0,
      status_bar_height: 44.0,
      safe_area: None,
    }),
    menu_button: None,
  }
}

///|
fn testing_layout_page() -> @minimoon.Page {
  @minimoon.page(
    id="layout",
    route=@minimoon.route("pages/layout/index"),
    title="Layout",
    build=context => {
      context
      .layout()
      .view(layout => {
        @minimoon.div(
          id="width",
          match layout.window {
            Some(window) => window.window_width.to_int().to_string()
            None => "unknown"
          },
        )
      })
    },
  )
}

///|
test "standalone and application harnesses inject and update page-owned layout" {
  let first = mount(testing_layout_page(), layout=testing_layout(375.0))
  defer ignore(first.dispose())
  assert_eq(first.get(by_id("width")).text_content(), "375")
  let app = launch(@minimoon.app(build=_ => ()))
  defer app.dispose()
  let second = app.mount(
    _ => testing_layout_page(),
    layout=testing_layout(420.0),
  )
  assert_eq(second.get(by_id("width")).text_content(), "420")
  ignore(second.lifecycle("onHide"))
  assert_eq(second.update_layout(testing_layout(500.0)), "[]")
  app.quiesce()
  assert_eq(second.get(by_id("width")).text_content(), "420")
  ignore(second.lifecycle("onShow"))
  second.quiesce()
  assert_eq(second.get(by_id("width")).text_content(), "500")
  assert_eq(first.get(by_id("width")).text_content(), "375")
  ignore(second.dispose())
  assert_eq(second.update_layout(testing_layout(375.0)), "[]")
}
