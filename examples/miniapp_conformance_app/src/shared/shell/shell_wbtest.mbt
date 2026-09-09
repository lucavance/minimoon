///|
fn sample_layout(
  window_height : Double,
  screen_top? : Double = 0.0,
) -> @minimoon.PageLayout {
  {
    window: Some({
      window_width: 390.0,
      window_height,
      screen_width: 390.0,
      screen_height: 844.0,
      screen_top,
      status_bar_height: 47.0,
      safe_area: Some({ left: 0.0, top: 47.0, width: 390.0, height: 763.0, }),
    }),
    menu_button: Some({ left: 291.0, top: 51.0, width: 87.0, height: 32.0, }),
  }
}

///|
test "safe navigation uses actual capsule row and conservative unavailable fallback" {
  assert_eq(navigation_height(@minimoon.PageLayout::unavailable()), "88px")
  assert_eq(navigation_height(sample_layout(844.0)), "91px")
  assert_eq(title_bottom(sample_layout(844.0)), 10.0)
  let tree = @minimoon.page(
      id="safe_shell",
      route=@minimoon.route("pages/test/test"),
      title="Test",
      build=_ => {
        @minimoon.Val::constant(
          frame(@minimoon.PageLayout::unavailable(), "Title", "test", []),
        )
      },
    )
    .initial_tree()
    .stringify()
  assert_true(tree.contains("padding-right:96px"))
  assert_true(tree.contains("safe-navigation"))
}

///|
test "bottom safe inset intersects the actual page window without double padding a Tab" {
  assert_eq(bottom_inset(sample_layout(844.0)), 34.0)
  assert_eq(bottom_inset(sample_layout(761.0)), 0.0)
  assert_eq(bottom_inset(sample_layout(797.0, screen_top=47.0)), 34.0)
  assert_eq(bottom_inset(@minimoon.PageLayout::unavailable()), 0.0)
}
