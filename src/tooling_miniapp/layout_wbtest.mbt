///|
test "layout ABI creation and updates keep their decoder separate from route inputs" {
  let source = runtime_package_source("user/app/page", "program", false)
  assert_true(source.contains("input_json : String, layout_json : String"))
  assert_true(source.contains("minimoon_decode_input(input_json)"))
  assert_true(
    source.contains("let layout = minimoon_decode_layout(layout_json)"),
  )
  assert_true(source.contains("program.create_runtime(input~, layout~)"))
  assert_true(source.contains("@minimoon.PageLayout::from_json(value)"))
  assert_true(source.contains("minimoon_runtime_update_layout"))
  assert_true(
    source.contains(
      "instance.update_layout(minimoon_decode_layout(layout_json))",
    ),
  )
  assert_true(
    runtime_link_options().contains("\"minimoon_runtime_update_layout\""),
  )
  assert_false(source.contains("wx.getWindowInfo"))
  assert_false(source.contains("wx.getMenuButtonBoundingClientRect"))
}
