///|
fn valid_inline_child(node : Json) -> Bool {
  match node {
    { "kind": String(kind), "children": Array([]), .. } =>
      kind == "text" || kind == "image"
    _ => false
  }
}

///|
fn inline_template_wxml(semantics : String) -> String {
  "  <span wx:elif=\"{{node.kind === 'inline'}}\" id=\"{{p.id}}\" class=\"{{p.className}}\" style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  ">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"run\">\n" +
  "      <image wx:if=\"{{run.kind === 'image'}}\" id=\"{{run.props.id}}\" class=\"{{run.props.className}}\" style=\"{{run.props.style}}\" src=\"{{run.props.src}}\" mode=\"{{run.props.mode || 'scaleToFill'}}\" aria-label=\"{{run.props.alt}}\" data-minimoon-load=\"{{run.events.load}}\" data-minimoon-error=\"{{run.events.error}}\" bindload=\"__mmDispatchLoad\" binderror=\"__mmDispatchError\" />\n" +
  "      <text wx:else id=\"{{run.props.id}}\" class=\"{{run.props.className}}\" style=\"{{run.props.style}}\" aria-label=\"{{run.props.ariaLabel}}\"" +
  semantics.replace_all(old="p.", new="run.props.") +
  " data-minimoon-tap=\"{{run.events.tap}}\" bindtap=\"__mmDispatchTap\">{{run.text}}</text>\n" +
  "    </block>\n  </span>\n"
}
