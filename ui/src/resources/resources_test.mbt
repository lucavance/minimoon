///|
test "resource selection is deterministic and transitive" {
  let first = resources(["form", "date-picker", "form"])
  let second = resources(["date-picker", "form"])
  assert_eq(first, second)
  assert_eq(features().length(), 66)
  assert_true(first.assets[0].content.contains("field\n"))
  assert_true(first.assets[0].content.contains("label\n"))
  assert_true(first.assets[0].content.contains("calendar\n"))
  assert_true(first.assets[0].content.contains("popover\n"))
  assert_true(first.wxss.contains(".mmui-input"))
  assert_eq(resources([]).assets[0].content.split("\n").length(), 67)
}

///|
test "SVG resources use explicit size and do not introduce browser CSS" {
  let resources = resources([])
  assert_eq(resources.assets.length(), 7)
  for asset in resources.assets {
    assert_true(asset.path.has_prefix("assets/mmui/"))
    if asset.path.has_suffix(".svg") {
      assert_true(asset.content.contains("width=\"24\" height=\"24\""))
      assert_false(asset.content.contains("<style"))
      assert_false(asset.content.contains("%"))
    }
  }
  assert_false(resources.wxss.contains("oklch("))
  assert_false(resources.wxss.contains("color-mix("))
  assert_false(resources.wxss.contains(":hover"))
}
