///|
test "normalization removes optional input keys and preserves empty false and zero" {
  let normalize = fn(attrs : Array[@ui.Attr]) {
    normalize_miniapp_tree_checked(
      @ui.element("input", attrs~),
      ([] : Array[PageEvent[Unit]]),
    ).unwrap()
  }
  let initial = normalize([
    @ui.value_attr("old"),
    @ui.attr("disabled", "true"),
    @ui.attr("password", "true"),
    @ui.attr("maxlength", "12"),
    @ui.attr("selection-start", "1"),
    @ui.attr("selection-end", "3"),
    @ui.attr("placeholder", "old hint"),
  ])
  let original = initial.stringify()
  let cleared = normalize([
    @ui.value_attr(""),
    @ui.attr("disabled", "false"),
    @ui.attr("password", "false"),
    @ui.attr("maxlength", "0"),
    @ui.attr("selection-start", "0"),
    @ui.attr("selection-end", "0"),
    @ui.attr("placeholder", ""),
  ])
  assert_eq(
    tree_node_field(cleared, "props"),
    Some(
      Json::object({
        "value": Json::string(""),
        "disabled": Json::boolean(false),
        "password": Json::boolean(false),
        "maxlength": Json::number(0),
        "selectionStart": Json::number(0),
        "selectionEnd": Json::number(0),
        "placeholder": Json::string(""),
      }),
    ),
  )
  let omitted = normalize([@ui.value_attr(""), @ui.attr("disabled", "false")])
  assert_eq(
    tree_node_field(omitted, "props"),
    Some(
      Json::object({
        "value": Json::string(""),
        "disabled": Json::boolean(false),
      }),
    ),
  )
  for
    (before, after) in [
      (initial, cleared),
      (cleared, omitted),
      (omitted, initial),
    ] {
    assert_eq(patch_test_apply(before, patch_test_diff(before, after)), after)
  }
  assert_eq(initial.stringify(), original)
}

///|
test "input template defaults distinguish absent numeric props from zero" {
  let wxml = dynamic_templates_wxml()
  for
    binding in [
      "maxlength=\"{{p.maxlength == null ? 140 : p.maxlength}}\"", "selection-start=\"{{p.selectionStart == null ? -1 : p.selectionStart}}\"",
      "selection-end=\"{{p.selectionEnd == null ? -1 : p.selectionEnd}}\"",
    ] {
    assert_true(wxml.contains(binding))
  }
}
