///|
test "minimal-v1 component theme is bounded and self-describing" {
  let css = component_theme_css("minimal-v1")
  assert_true(css.contains(".mm-disclosure"))
  assert_true(css.contains(".mm-accordion"))
  assert_true(css.contains(".mm-tabs"))
  assert_true(@utf8.encode(css).length() <= 2048)
  assert_eq(@utf8.encode(css).length(), 1036)
  match component_theme_manifest("minimal-v1") {
    Object(fields) => {
      assert_eq(fields["id"], Json::string("minimal-v1"))
      assert_eq(fields["version"], Json::string("1"))
      assert_eq(fields["hash"], Json::string("fnv1a64-v1:d8ae51244c8024ac"))
    }
    _ => fail("component theme manifest must be an object")
  }
  assert_true(component_theme_manifest("") is Null)
}

///|
test "minimal-v2 adds bounded overlay and menu styles" {
  let css = component_theme_css("minimal-v2")
  assert_true(css.contains(".mm-dialog"))
  assert_true(css.contains(".mm-sheet"))
  assert_true(css.contains(".mm-dropdown"))
  assert_true(@utf8.encode(css).length() <= 4096)
  match component_theme_manifest("minimal-v2") {
    Object(fields) => {
      assert_eq(fields["id"], Json::string("minimal-v2"))
      assert_eq(fields["version"], Json::string("2"))
    }
    _ => fail("component theme manifest must be an object")
  }
}
