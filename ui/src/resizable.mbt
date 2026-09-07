///|
/// Touch-native pane resizing adapted from RUI b1291945 (MIT).
pub(all) struct ResizablePane {
  key : String
  content : @minimoon.Node
  minimum : Double
  maximum : Double
} derive(Eq)

///|
pub fn resizable_pane(
  key~ : String,
  content~ : @minimoon.Node,
  minimum? : Double = 0.0,
  maximum? : Double = 100.0,
) -> ResizablePane {
  guard key != "" && minimum >= 0.0 && maximum <= 100.0 && minimum <= maximum else {
    abort("resizable pane requires a key and 0 <= minimum <= maximum <= 100")
  }
  { key, content, minimum, maximum, }
}

///|
fn resize_sizes(
  panes : Array[ResizablePane],
  sizes : Array[Double],
) -> Array[Double] {
  guard panes.length() > 0 else { return [] }
  let keys : Set[String] = Set([])
  let mut minimum = 0.0
  let mut maximum = 0.0
  for pane in panes {
    guard pane.key != "" &&
      !keys.contains(pane.key) &&
      pane.minimum >= 0.0 &&
      pane.maximum <= 100.0 &&
      pane.minimum <= pane.maximum else {
      abort("resizable pane keys and constraints are invalid")
    }
    keys.add(pane.key)
    minimum += pane.minimum
    maximum += pane.maximum
  }
  guard minimum <= 100.0 && maximum >= 100.0 else {
    abort("resizable constraints cannot fill 100 percent")
  }
  if sizes.length() == panes.length() {
    let mut valid = true
    let mut total = 0.0
    for index, size in sizes {
      if !(size >= panes[index].minimum && size <= panes[index].maximum) {
        valid = false
      }
      total += size
    }
    if valid && (total - 100.0).abs() < 0.000001 {
      return sizes.copy()
    }
  }
  let result = panes.map(pane => pane.minimum)
  let mut remaining = 100.0 - minimum
  while remaining > 0.000001 {
    let mut available = 0
    for index, size in result {
      if panes[index].maximum - size > 0.000001 {
        available += 1
      }
    }
    if available == 0 {
      break
    }
    let share = remaining / available.to_double()
    for index, size in result {
      let add = share.min(panes[index].maximum - size).max(0.0)
      result[index] = size + add
      remaining -= add
    }
  }
  result
}

///|
priv struct ResizeDrag {
  pointer : Int
  index : Int
  keys : Array[String]
  initial : Array[Double]
  start : Double
  position : Double
  extent : Double?
  ended : Bool
} derive(Eq)

///|
priv struct ResizeState {
  token : Int
  drag : ResizeDrag?
} derive(Eq)

///|
priv enum ResizeMsg {
  StartResize(Int, @minimoon.TouchDetail)
  MoveResize(@minimoon.TouchDetail)
  EndResize(@minimoon.TouchDetail)
  CancelResize
  CancelResizeTouch(@minimoon.TouchDetail)
  MeasuredResize(Int, Result[Array[@minimoon.NodeRect?], @minimoon.HostError])
  ResizeStep(Int, Double)
}

///|
fn resized_values(
  panes : Array[ResizablePane],
  drag : ResizeDrag,
  orientation : Orientation,
  direction : @theme.TextDirection,
) -> Array[Double] {
  let delta = (drag.position - drag.start) /
    drag.extent.unwrap_or(1.0) *
    100.0 *
    (if orientation == Horizontal && direction == @theme.Rtl {
      -1.0
    } else {
      1.0
    })
  @headless.resize_pair(
    drag.initial,
    drag.index,
    delta,
    panes.map(pane => pane.minimum),
    panes.map(pane => pane.maximum),
  )
}

///|
pub fn resizable_controlled(
  context : UiContext,
  id~ : String,
  panes~ : @minimoon.Val[Array[ResizablePane]],
  sizes~ : @minimoon.Val[Array[Double]],
  on_change~ : @minimoon.Emit[Array[Double]],
  on_commit? : @minimoon.Emit[Array[Double]],
  orientation? : Orientation = Horizontal,
  direction? : @theme.TextDirection = @theme.Ltr,
  disabled? : Bool = false,
  style? : String = "height:320px;",
) -> @minimoon.Val[@minimoon.Node] {
  let input = @minimoon.Val::map2(panes, sizes, (panes, sizes) => {
    (panes, resize_sizes(panes, sizes))
  })
  let (state, emit) = @minimoon.create_state_with_input(
    input~,
    init=(_, _) => @minimoon.no_cmd(ResizeState::{ token: 0, drag: None, }),
    update=(state, input, msg : ResizeMsg, emit) => {
      let (panes, sizes) = input
      let keys = panes.map(pane => pane.key)
      let state : ResizeState = if state.drag is Some(drag) && drag.keys != keys {
        { token: state.token + 1, drag: None, }
      } else {
        state
      }
      match msg {
        CancelResizeTouch(detail) =>
          if state.drag is Some(drag) &&
            slider_point(detail.changed_touches, drag.pointer) is Some(_) {
            ({ token: state.token + 1, drag: None, }, on_change(drag.initial))
          } else {
            @minimoon.no_cmd(state)
          }
        CancelResize =>
          (
            { token: state.token + 1, drag: None, },
            match state.drag {
              Some(drag) if drag.keys == keys => on_change(drag.initial)
              _ => @minimoon.none
            },
          )
        ResizeStep(index, amount) => {
          if disabled {
            return @minimoon.no_cmd(state)
          }
          let next = @headless.resize_pair(
            sizes,
            index,
            amount,
            panes.map(pane => pane.minimum),
            panes.map(pane => pane.maximum),
          )
          (
            state,
            @minimoon.batch([
              on_change(next),
              on_commit.map(commit => commit(next)).unwrap_or(@minimoon.none),
            ]),
          )
        }
        StartResize(index, detail) => {
          guard !disabled &&
            state.drag is None &&
            detail.changed_touches.length() == 1 &&
            index >= 0 &&
            index + 1 < panes.length() else {
            return @minimoon.no_cmd(state)
          }
          let point = detail.changed_touches[0]
          let start = if orientation == Horizontal {
            point.client_x
          } else {
            point.client_y
          }
          let token = state.token + 1
          (
            {
              token,
              drag: Some({
                pointer: point.identifier,
                index,
                keys,
                initial: sizes,
                start,
                position: start,
                extent: None,
                ended: false,
              }),
            },
            @minimoon.measure_nodes(
              [id],
              emit.map(result => MeasuredResize(token, result)),
            ),
          )
        }
        MeasuredResize(token, result) => {
          guard state.token == token &&
            state.drag is Some(drag) &&
            drag.keys == keys else {
            return @minimoon.no_cmd(state)
          }
          guard result is Ok([Some(rect)]) else {
            return @minimoon.no_cmd({ ..state, drag: None, })
          }
          let extent = (if orientation == Horizontal {
              rect.width
            } else {
              rect.height
            }) -
            (panes.length() - 1).to_double() * 44.0
          guard extent > 0.0 else {
            return @minimoon.no_cmd({ ..state, drag: None, })
          }
          let drag = { ..drag, extent: Some(extent), }
          let next = resized_values(panes, drag, orientation, direction)
          (
            { ..state, drag: if drag.ended { None } else { Some(drag) }, },
            @minimoon.batch([
              on_change(next),
              if drag.ended {
                on_commit.map(commit => commit(next)).unwrap_or(@minimoon.none)
              } else {
                @minimoon.none
              },
            ]),
          )
        }
        MoveResize(detail) | EndResize(detail) => {
          guard state.drag is Some(drag) else { return @minimoon.no_cmd(state) }
          guard drag.keys == keys else {
            return @minimoon.no_cmd({ ..state, drag: None, })
          }
          let ended = msg is EndResize(_)
          guard slider_point(
              if ended {
                detail.changed_touches
              } else {
                detail.touches
              },
              drag.pointer,
            )
            is Some(point) else {
            return @minimoon.no_cmd(state)
          }
          let drag = {
            ..drag,
            position: if orientation == Horizontal {
              point.client_x
            } else {
              point.client_y
            },
            ended,
          }
          if drag.extent is None {
            return @minimoon.no_cmd({ ..state, drag: Some(drag), })
          }
          let next = resized_values(panes, drag, orientation, direction)
          (
            { ..state, drag: if ended { None } else { Some(drag) }, },
            @minimoon.batch([
              on_change(next),
              if ended {
                on_commit.map(commit => commit(next)).unwrap_or(@minimoon.none)
              } else {
                @minimoon.none
              },
            ]),
          )
        }
      }
    },
    subscriptions=(_, _, emit) => context.page.on_hide(emit(CancelResize)),
  )
  @minimoon.Val::view2(input, state, (input, _state) => {
    let (panes, sizes) = input
    let nodes : Array[@minimoon.KeyedNode] = []
    for index, pane in panes {
      nodes.push(
        @minimoon.keyed(
          "pane:" + pane.key,
          ui_container(
            "resizable-panel",
            id=id + "-pane-" + index.to_string(),
            [pane.content],
            style="flex:" +
              sizes[index].to_string() +
              " 1 0%;min-width:0;min-height:0;overflow:hidden;",
          ),
        ),
      )
      if index + 1 < panes.length() {
        let handle = id + "-handle-" + index.to_string()
        nodes.push(
          @minimoon.keyed(
            "handle:" + pane.key,
            @minimoon.touch_view(
              id=handle,
              class="mmui-resizable-handle",
              style="flex:0 0 44px;min-width:0;min-height:0;display:flex;align-items:center;justify-content:center;flex-direction:" +
                (if orientation == Horizontal { "column" } else { "row" }) +
                ";",
              catch_move=true,
              on_touch_start=emit.map(value => StartResize(index, value)),
              on_touch_move=emit.map(value => MoveResize(value)),
              on_touch_end=emit.map(value => EndResize(value)),
              on_touch_cancel=emit.map(value => CancelResizeTouch(value)),
              event_key=handle,
              semantics=@minimoon.semantics(
                role=@minimoon.SeparatorRole,
                orientation=if orientation == Horizontal {
                  "vertical"
                } else {
                  "horizontal"
                },
                value_now=sizes[index].to_int(),
                disabled~,
              ),
              [
                @minimoon.button(
                  disabled~,
                  on_tap=emit(ResizeStep(index, -5.0)),
                  event_key=handle + "/decrease",
                  semantics=@minimoon.semantics(label="Decrease previous pane"),
                  "−",
                ),
                @minimoon.button(
                  disabled~,
                  on_tap=emit(ResizeStep(index, 5.0)),
                  event_key=handle + "/increase",
                  semantics=@minimoon.semantics(label="Increase previous pane"),
                  "+",
                ),
              ],
            ),
          ),
        )
      }
    }
    ui_container(
      "resizable",
      id~,
      style="display:flex;min-width:0;min-height:0;flex-direction:" +
        (if orientation == Vertical {
          "column"
        } else if direction == @theme.Rtl {
          "row-reverse"
        } else {
          "row"
        }) +
        ";" +
        style,
      [@minimoon.keyed_fragment(nodes)],
    )
  })
}

///|
pub fn resizable(
  context : UiContext,
  id~ : String,
  panes~ : @minimoon.Val[Array[ResizablePane]],
  initial_sizes? : Array[Double] = [],
  orientation? : Orientation = Horizontal,
  direction? : @theme.TextDirection = @theme.Ltr,
  disabled? : Bool = false,
  style? : String = "height:320px;",
) -> @minimoon.Val[@minimoon.Node] {
  let (sizes, change) = @minimoon.create_variable(initial_sizes)
  resizable_controlled(
    context,
    id~,
    panes~,
    sizes~,
    on_change=change.map(value => _ => value),
    orientation~,
    direction~,
    disabled~,
    style~,
  )
}
