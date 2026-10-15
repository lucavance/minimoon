///|
test "resource selection is deterministic and transitive" {
  let first = @resources.resources(["form", "date-picker", "form"])
  let second = @resources.resources(["date-picker", "form"])
  assert_eq(first, second)
  assert_eq(@resources.features().length(), 67)
  guard first.assets[0].content is @build_resources.Text(manifest) else {
    abort("text manifest")
  }
  assert_true(manifest.contains("field\n"))
  assert_true(manifest.contains("label\n"))
  assert_true(manifest.contains("calendar\n"))
  assert_true(manifest.contains("popover\n"))
  assert_true(first.wxss.contains(".mmui-input"))
  guard @resources.resources([]).assets[0].content is @build_resources.Text(all) else {
    abort("text manifest")
  }
  assert_eq(all.split("\n").count(), 68)
}

///|
test "SVG resources use explicit size and do not introduce browser CSS" {
  let resources = @resources.resources([])
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

///|
test "native-v2 bundles both preset scopes and opts into Markdown styles explicitly" {
  let basic = @resources.resources(["button"])
  let markdown = @resources.resources(["button", "markdown"])
  assert_eq(basic.id, "lampclaw/minimoon_ui/native-v2")
  assert_true(basic.wxss.contains(".mmui-vega-v1"))
  assert_true(basic.wxss.contains(".mmui-nova .mmui-button{min-height:32px"))
  assert_false(basic.wxss.contains(".mmui-markdown-p"))
  assert_true(markdown.wxss.contains(".mmui-markdown-p"))
  assert_true(markdown.wxss.contains(".mmui-markdown-table"))
}
