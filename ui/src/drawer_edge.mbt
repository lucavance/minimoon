///|
fn drawer_cross_axis(side : Side, point : @minimoon.TouchPoint) -> Double {
  match side {
    Left | Right => point.client_y
    Top | Bottom => point.client_x
  }
}

///|
fn drawer_signed_distance(side : Side, drag : DrawerDrag) -> Double {
  (drag.position - drag.start) *
  (if side == Left || side == Top { -1.0 } else { 1.0 })
}

///|
/// Only mounted beside an open panel. The edge faces into the viewport and
/// shares the panel transform; there is no closed-screen gesture listener.
fn drawer_swipe_edge(
  id : String,
  side : Side,
  area : Int32,
  emit : @minimoon.Emit[DrawerMsg],
) -> @minimoon.Node {
  let size = area.to_string() + "px;"
  let placement = match side {
    Bottom => "bottom:100%;left:0;right:0;height:"
    Top => "top:100%;left:0;right:0;height:"
    Left => "left:100%;top:0;bottom:0;width:"
    Right => "right:100%;top:0;bottom:0;width:"
  }
  @minimoon.touch_view(
    id=id + "-swipe-edge",
    class="mmui-drawer-swipe-edge",
    style="position:absolute;" + placement + size,
    catch_move=true,
    on_touch_start=emit.map(value => StartEdge(value)),
    on_touch_move=emit.map(value => Move(value)),
    on_touch_end=emit.map(value => End(value)),
    on_touch_cancel=emit.map(value => CancelTouch(value)),
    event_key=id + "/edge",
    semantics=@minimoon.semantics(label="Swipe toward panel to close"),
    @minimoon.nothing(),
  )
}

///|
fn drawer_body(
  id : String,
  title : String,
  content : @minimoon.Node,
  emit : @minimoon.Emit[DrawerMsg],
  on_change : @minimoon.Emit[Bool],
  side : Side,
  swipe_area : Int32,
) -> Array[@minimoon.Node] {
  let body = [
    @minimoon.touch_view(
      id=id + "-handle",
      class="mmui-drawer-handle",
      style="min-width:44px;min-height:44px;",
      catch_move=true,
      on_touch_start=emit.map(value => DrawerMsg::Start(value)),
      on_touch_move=emit.map(value => Move(value)),
      on_touch_end=emit.map(value => DrawerMsg::End(value)),
      on_touch_cancel=emit.map(value => CancelTouch(value)),
      event_key=id + "/drag",
      semantics=@minimoon.semantics(label="Drag to close"),
      @minimoon.text("—"),
    ),
    @minimoon.h1(id=id + "-title", class="mmui-surface-title", title),
    content,
    @minimoon.button(on_tap=on_change(false), event_key=id + "/close", "Close"),
  ]
  if swipe_area == 0 {
    return body
  }
  let limit = if side == Left || side == Right { "100vh" } else { "85vh" }
  [
    drawer_swipe_edge(id, side, swipe_area, emit),
    @minimoon.div(
      style="display:flex;flex-direction:column;gap:8px;max-height:calc(" +
        limit +
        " - 34px);overflow:auto;",
      body,
    ),
  ]
}
