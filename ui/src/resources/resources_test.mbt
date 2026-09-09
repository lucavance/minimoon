///|
test "resource selection is deterministic and transitive" {
  let first = resources(["form", "date-picker", "form"])
  let second = resources(["date-picker", "form"])
  assert_eq(first, second)
  assert_eq(features().length(), 66)
  guard first.assets[0].content is @build_resources.Text(manifest) else {
    abort("text manifest")
  }
  assert_true(manifest.contains("field\n"))
  assert_true(manifest.contains("label\n"))
  assert_true(manifest.contains("calendar\n"))
  assert_true(manifest.contains("popover\n"))
  assert_true(first.wxss.contains(".mmui-input"))
  guard resources([]).assets[0].content is @build_resources.Text(all) else {
    abort("text manifest")
  }
  assert_eq(all.split("\n").length(), 67)
}

///|
test "SVG resources use explicit size and do not introduce browser CSS" {
  let resources = resources([])
  assert_eq(resources.assets.length(), 7)
  for asset in resources.assets {
    assert_true(asset.path.has_prefix("assets/mmui/"))
    if asset.path.has_suffix(".svg") {
      guard asset.content is @build_resources.Text(svg) else {
        abort("text SVG")
      }
      assert_true(svg.contains("width=\"24\" height=\"24\""))
      assert_false(svg.contains("<style"))
      assert_false(svg.contains("%"))
    }
  }
  assert_false(resources.wxss.contains("oklch("))
  assert_false(resources.wxss.contains("color-mix("))
  assert_false(resources.wxss.contains(":hover"))
}
