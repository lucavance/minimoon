///|
/// Touch-native adaptation of RUI drawer.mbt at b1291945 (MIT).
priv struct DrawerDrag {
  pointer : Int32
  start : Double
  position : Double
  started_at : Double
  timestamp : Double
  size : Double?
  ended : Bool
  edge : Bool
  cross_start : Double
  locked : Bool
} derive(Eq)

///|
priv struct DrawerState {
  token : Int32
  drag : DrawerDrag?
} derive(Eq)

///|
priv enum DrawerMsg {
  Start(@minimoon.TouchDetail)
  StartEdge(@minimoon.TouchDetail)
  Move(@minimoon.TouchDetail)
  End(@minimoon.TouchDetail)
  Cancel
  CancelTouch(@minimoon.TouchDetail)
  Measured(Int32, Result[Array[@minimoon.NodeRect?], @minimoon.HostError])
}

///|
fn drawer_axis(side : Side, point : @minimoon.TouchPoint) -> Double {
  match side {
    Left | Right => point.client_x
    Top | Bottom => point.client_y
  }
}

///|
fn drawer_distance(side : Side, drag : DrawerDrag) -> Double {
  if drag.edge && !drag.locked {
    return 0.0
  }
  let sign = if side == Left || side == Top { -1.0 } else { 1.0 }
  ((drag.position - drag.start) * sign).max(0.0)
}

///|
fn drawer_dismisses(side : Side, drag : DrawerDrag) -> Bool {
  guard drag.size is Some(size) else { return false }
  let distance = drawer_distance(side, drag)
  let elapsed = (drag.timestamp - drag.started_at).max(1.0)
  distance >= (size * 0.25).max(48.0).min(160.0) ||
  (distance >= 16.0 && distance / elapsed >= 0.5)
}

///|
fn drawer_trigger(
  id : String,
  label : String,
  open : Bool,
  on_change : @minimoon.Emit[Bool],
  disabled : Bool,
) -> @minimoon.Node {
  @minimoon.button(
    id=id + "-trigger",
    disabled~,
    on_tap=if disabled { @minimoon.none } else { on_change(true) },
    event_key=id + "/trigger",
    semantics=@minimoon.semantics(
      expanded=open,
      controls=id + "-surface",
      has_popup="dialog",
    ),
    label,
  )
}

///|
pub fn drawer_controlled(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  side~ : Side = Bottom,
  disabled~ : Bool = false,
  close_on_overlay~ : Bool = true,
  swipe_area~ : Int32 = 0,
) -> @minimoon.Val[@minimoon.Node] {
  guard swipe_area >= 0 else { abort("drawer swipe_area must be nonnegative") }
  open.switch_by(
    (opened, _) => {
      if !opened {
        return @minimoon.Val::constant(
          drawer_trigger(id, trigger_label, false, on_change, disabled),
        )
      }
      let (state, emit) = @minimoon.create_state(
        DrawerState::{ token: 0, drag: None, },
        update=(state, msg : DrawerMsg, emit) => {
          match msg {
            CancelTouch(detail) =>
              if state.drag is Some(drag) &&
                slider_point(detail.changed_touches, drag.pointer) is Some(_) {
                @minimoon.no_cmd({ token: state.token + 1, drag: None, })
              } else {
                @minimoon.no_cmd(state)
              }
            Cancel => @minimoon.no_cmd({ token: state.token + 1, drag: None, })
            Start(detail) | StartEdge(detail) => {
              guard !disabled &&
                state.drag is None &&
                detail.changed_touches.length() == 1 else {
                return @minimoon.no_cmd(state)
              }
              let point = detail.changed_touches[0]
              let token = state.token + 1
              (
                {
                  token,
                  drag: Some({
                    pointer: point.identifier,
                    start: drawer_axis(side, point),
                    position: drawer_axis(side, point),
                    started_at: detail.timestamp,
                    timestamp: detail.timestamp,
                    size: None,
                    ended: false,
                    edge: msg is StartEdge(_),
                    cross_start: drawer_cross_axis(side, point),
                    locked: !(msg is StartEdge(_)),
                  }),
                },
                @minimoon.measure_nodes(
                  [id + "-surface"],
                  emit.map(result => Measured(token, result)),
                ),
              )
            }
            Measured(token, result) => {
              guard state.token == token && state.drag is Some(drag) else {
                return @minimoon.no_cmd(state)
              }
              guard result is Ok([Some(rect)]) else {
                return @minimoon.no_cmd({ ..state, drag: None, })
              }
              let size = if side == Top || side == Bottom {
                rect.height
              } else {
                rect.width
              }
              guard size > 0.0 else {
                return @minimoon.no_cmd({ ..state, drag: None, })
              }
              let drag = { ..drag, size: Some(size), }
              if drag.ended {
                (
                  { ..state, drag: None, },
                  if drawer_dismisses(side, drag) {
                    on_change(false)
                  } else {
                    @minimoon.none
                  },
                )
              } else {
                @minimoon.no_cmd({ ..state, drag: Some(drag), })
              }
            }
            Move(detail) | End(detail) => {
              guard state.drag is Some(drag) else {
                return @minimoon.no_cmd(state)
              }
              let ended = msg is End(_)
              let points = if ended {
                detail.changed_touches
              } else {
                detail.touches
              }
              guard slider_point(points, drag.pointer) is Some(point) else {
                return @minimoon.no_cmd(state)
              }
              let drag = {
                ..drag,
                position: drawer_axis(side, point),
                timestamp: detail.timestamp,
                ended,
              }
              let drag = if drag.edge && !drag.locked {
                let along = drawer_signed_distance(side, drag)
                let across = (drawer_cross_axis(side, point) - drag.cross_start).abs()
                if (across >= 6.0 && across >= along.abs()) || along <= -6.0 {
                  return @minimoon.no_cmd({
                    token: state.token + 1,
                    drag: None,
                  })
                }
                if along >= 6.0 && along > across {
                  { ..drag, locked: true, }
                } else if ended {
                  return (
                    { token: state.token + 1, drag: None, },
                    if close_on_overlay {
                      on_change(false)
                    } else {
                      @minimoon.none
                    },
                  )
                } else {
                  drag
                }
              } else {
                drag
              }
              if ended && drag.size is Some(_) {
                (
                  { ..state, drag: None, },
                  if drawer_dismisses(side, drag) {
                    on_change(false)
                  } else {
                    @minimoon.none
                  },
                )
              } else {
                @minimoon.no_cmd({ ..state, drag: Some(drag), })
              }
            }
          }
        },
        subscriptions=(_, emit) => context.page.on_hide(emit(Cancel)),
      )
      @minimoon.Val::view3(content, state, context.visible, (
        content,
        state,
        visible,
      ) => {
        let offset = match state.drag {
          Some(drag) if drag.size is Some(_) => drawer_distance(side, drag)
          _ => 0.0
        }
        let signed = if side == Left || side == Top { -offset } else { offset }
        let axis = if side == Left || side == Right { "X" } else { "Y" }
        let surface = if visible {
          @minimoon.layer(id=id + "-layer", [
            @minimoon.tap_view(
              class="mmui-overlay",
              style="position:fixed;left:0;right:0;top:0;bottom:0;",
              on_tap=if close_on_overlay {
                on_change(false)
              } else {
                @minimoon.none
              },
              event_key=id + "/dismiss",
              @minimoon.nothing(),
            ),
            ui_container(
              "drawer",
              class="mmui-surface",
              id=id + "-surface",
              style=surface_style(SheetSurface(side), None) +
                (if swipe_area > 0 { "overflow:visible;" } else { "" }) +
                "transform:translate" +
                axis +
                "(" +
                signed.to_string() +
                "px);",
              semantics=@minimoon.semantics(
                role=@minimoon.DialogRole,
                modal=true,
                labelled_by=id + "-title",
              ),
              drawer_body(id, title, content, emit, on_change, side, swipe_area),
            ),
          ])
        } else {
          @minimoon.nothing()
        }
        ui_container("drawer-root", [
          drawer_trigger(id, trigger_label, true, on_change, disabled),
          surface,
        ])
      })
    },
    by=value => value.to_string(),
  )
}

///|
pub fn drawer(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  side~ : Side = Bottom,
  initially_open~ : Bool = false,
  disabled~ : Bool = false,
  swipe_area~ : Int32 = 0,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, change) = @minimoon.create_variable(initially_open)
  drawer_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    side~,
    open~,
    on_change=change.map(value => _ => value),
    disabled~,
    swipe_area~,
  )
}
