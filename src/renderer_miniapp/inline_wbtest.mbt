///|
test "inline normalization validates native runs and keeps legacy span as view" {
  let normalize = fn(node : @ui.Node) {
    normalize_miniapp_tree_checked(node, ([] : Array[PageEvent[Unit]]))
  }
  let flow = normalize(
    @ui.element("inline", children=[
      @ui.element("inline-text", attrs=[@ui.style_attr("font-weight:700;")], children=[
        @ui.text("hello"),
      ]),
      @ui.image(src="/logo.svg"),
    ]),
  ).unwrap()
  assert_eq(tree_node_field(flow, "kind"), Some(Json::string("inline")))
  let next = normalize(
    @ui.element("inline", children=[
      @ui.element("inline-text", children=[@ui.text("updated")]),
    ]),
  ).unwrap()
  assert_eq(patch_test_apply(flow, patch_test_diff(flow, next)), next)
  assert_true(
    normalize(@ui.element("inline", children=[@ui.element("view")])) is Err(_),
  )
  assert_true(
    normalize(@ui.element("inline-text", children=[@ui.element("view")]))
    is Err(_),
  )
  assert_eq(
    tree_node_field(normalize(@ui.span([@ui.text("legacy")])).unwrap(), "kind"),
    Some(Json::string("view")),
  )
  let wxml = inline_template_wxml("")
  assert_true(wxml.contains("<span"))
  assert_true(wxml.contains("<image"))
  assert_true(!wxml.contains("<template"))
}
