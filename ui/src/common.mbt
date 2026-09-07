///|
/// Build a native component boundary with a stable inspection section.
fn ui_container(
  kind : String,
  children : Array[@minimoon.Node],
  id? : String = "",
  class? : String = "",
  style? : String = "",
  semantics? : @minimoon.Semantics,
) -> @minimoon.Node {
  @minimoon.div(
    id~,
    class="mmui-" + kind + (if class == "" { "" } else { " " + class }),
    style~,
    data_section="mmui-" + kind,
    semantics?,
    children,
  )
}
