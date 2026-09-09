///|
test "fixture provider owns eight paired binary PNGs and the dark boot background" {
  let bundle = resources([])
  assert_eq(bundle.assets.length(), 8)
  assert_true(bundle.wxss.contains("page{background:#203B63"))
  assert_true(bundle.wxss.contains(".demo-hero{min-height:128rpx;"))
  assert_true(bundle.wxss.contains(".demo-hero-home{min-height:192rpx}"))
  assert_true(bundle.wxss.contains("min-height:44px;"))
  assert_false(bundle.wxss.contains(".demo-hero{height:"))
  let paths : Map[String, Bool] = Map([])
  for asset in bundle.assets {
    assert_false(paths.contains(asset.path))
    paths[asset.path] = true
    guard asset.content is @build_resources.Binary(bytes) else {
      fail("native Tab icons must be binary PNG assets")
    }
    assert_true(bytes.length() < 40960)
    assert_eq(bytes[0].to_int(), 137)
    assert_eq(bytes[1].to_int(), 80)
    assert_eq(bytes[19].to_int(), 72)
    assert_eq(bytes[23].to_int(), 72)
  }
  for name in ["home", "interaction", "capabilities", "application"] {
    assert_true(paths.contains("assets/tab-" + name + ".png"))
    assert_true(paths.contains("assets/tab-" + name + "-selected.png"))
  }
}
