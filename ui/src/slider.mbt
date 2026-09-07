///|
/// Multi-thumb slider uses only typed native touch and page-local layout measurement.
priv struct SliderDrag {
  token : Int
  pointer : Int
  x : Double
  y : Double
  initial : Array[Int]
  last : Array[Int]
  index : Int
  bounds : @minimoon.NodeRect?
  ended : Bool
} derive(Eq)

///|
priv struct SliderState {
  token : Int
  drag : SliderDrag?
} derive(Eq)

///|
priv enum SliderMessage {
  StartDrag(@minimoon.TouchDetail)
  MoveDrag(@minimoon.TouchDetail)
  EndDrag(@minimoon.TouchDetail)
  CancelDrag
  Measured(Int, Result[Array[@minimoon.NodeRect?], @minimoon.HostError])
}

///|
fn slider_point(
  points : Array[@minimoon.TouchPoint],
  identifier : Int,
) -> @minimoon.TouchPoint? {
  for point in points {
    if point.identifier == identifier {
      return Some(point)
    }
  }
  None
}

///|
fn slider_position(
  spec : @headless.SliderSpec,
  rect : @minimoon.NodeRect,
  x : Double,
  y : Double,
  orientation : Orientation,
  direction : @theme.TextDirection,
) -> Double {
  let fraction = if orientation == Vertical {
    (rect.bottom - y) / rect.height
  } else if direction == @theme.Rtl {
    (rect.right - x) / rect.width
  } else {
    (x - rect.left) / rect.width
  }
  spec.min.to_double() +
  fraction.clamp(min=0.0, max=1.0) * (spec.max - spec.min).to_double()
}

///|
pub fn slider_values_controlled(
  context : UiContext,
  id~ : String,
  values~ : @minimoon.Val[Array[Int]],
  on_change~ : @minimoon.Emit[Array[Int]],
  on_commit? : @minimoon.Emit[Array[Int]],
  spec? : @headless.SliderSpec = @headless.slider_spec(),
  orientation? : Orientation = Horizontal,
  direction? : @theme.TextDirection = @theme.Ltr,
  disabled? : Bool = false,
  label? : String = "Value",
) -> @minimoon.Val[@minimoon.Node] {
  validate_measured_id(id)
  let (state, emit) = @minimoon.create_state_with_input(
    input=values,
    init=(_, _) => @minimoon.no_cmd(SliderState::{ token: 0, drag: None, }),
    update=(state, input, message, emit) => {
      let current = spec.normalize(input)
      match message {
        CancelDrag => {
          let restore = state.drag
            .map(drag => on_change(drag.initial))
            .unwrap_or(@minimoon.none)
          ({ ..state, drag: None, }, restore)
        }
        StartDrag(detail) => {
          if disabled ||
            state.drag is Some(_) ||
            detail.changed_touches.is_empty() {
            return @minimoon.no_cmd(state)
          }
          let point = detail.changed_touches[0]
          let token = state.token + 1
          let drag = SliderDrag::{
            token,
            pointer: point.identifier,
            x: point.client_x,
            y: point.client_y,
            initial: current,
            last: current,
            index: 0,
            bounds: None,
            ended: false,
          }
          (
            { token, drag: Some(drag), },
            @minimoon.measure_nodes(
              [id + "-track"],
              emit.map(result => Measured(token, result)),
            ),
          )
        }
        Measured(token, result) => {
          guard state.drag is Some(drag) && drag.token == token else {
            return @minimoon.no_cmd(state)
          }
          guard result is Ok([Some(bounds)]) &&
            bounds.width > 0.0 &&
            bounds.height > 0.0 else {
            return @minimoon.no_cmd({ ..state, drag: None, })
          }
          let position = slider_position(
            spec,
            bounds,
            drag.x,
            drag.y,
            orientation,
            direction,
          )
          let index = spec.nearest(current, position)
          let next = spec.update(current, index, position)
          let commands = [on_change(next)]
          if drag.ended {
            if on_commit is Some(commit) {
              commands.push(commit(next))
            }
            ({ ..state, drag: None, }, @minimoon.batch(commands))
          } else {
            (
              {
                ..state,
                drag: Some({ ..drag, index, bounds: Some(bounds), last: next, }),
              },
              @minimoon.batch(commands),
            )
          }
        }
        MoveDrag(detail) | EndDrag(detail) => {
          guard state.drag is Some(drag) else { return @minimoon.no_cmd(state) }
          let ended = message is EndDrag(_)
          let points = if ended {
            detail.changed_touches
          } else {
            detail.touches
          }
          guard slider_point(points, drag.pointer) is Some(point) else {
            return @minimoon.no_cmd(state)
          }
          match drag.bounds {
            None =>
              @minimoon.no_cmd({
                ..state,
                drag: Some({
                  ..drag,
                  x: point.client_x,
                  y: point.client_y,
                  ended,
                }),
              })
            Some(bounds) => {
              let next = spec.update(
                current,
                drag.index,
                slider_position(
                  spec,
                  bounds,
                  point.client_x,
                  point.client_y,
                  orientation,
                  direction,
                ),
              )
              let commands = [on_change(next)]
              if ended {
                if on_commit is Some(commit) {
                  commands.push(commit(next))
                }
                ({ ..state, drag: None, }, @minimoon.batch(commands))
              } else {
                (
                  {
                    ..state,
                    drag: Some({
                      ..drag,
                      x: point.client_x,
                      y: point.client_y,
                      last: next,
                    }),
                  },
                  @minimoon.batch(commands),
                )
              }
            }
          }
        }
      }
    },
    subscriptions=(_, _, emit) => context.page.on_hide(emit(CancelDrag)),
  )
  @minimoon.Val::view2(values, state, (values, state) => {
    let values = spec.normalize(values)
    // Native slider is exact only for the single horizontal divisible-step case.
    if values.length() == 1 &&
      orientation == Horizontal &&
      direction == @theme.Ltr &&
      (spec.max - spec.min) % spec.step == 0 {
      @minimoon.slider(
        id~,
        class="mmui-slider-native",
        value=values[0],
        min=spec.min,
        max=spec.max,
        step=spec.step,
        disabled~,
        event_key=id + "/change",
        changing_key=id + "/changing",
        on_changing=@minimoon.Emit(value => {
          if disabled {
            @minimoon.none
          } else {
            on_change([value])
          }
        }),
        on_change=@minimoon.Emit(value => {
          if disabled {
            @minimoon.none
          } else {
            @minimoon.batch([
              on_change([value]),
              on_commit.map(commit => commit([value])).unwrap_or(@minimoon.none),
            ])
          }
        }),
        semantics=@minimoon.semantics(
          role=@minimoon.SliderRole,
          label~,
          value_min=spec.min,
          value_max=spec.max,
          value_now=values[0],
          disabled~,
        ),
      )
    } else {
      let start = if values.length() > 1 {
        spec.fraction(values[0]) * 100.0
      } else {
        0.0
      }
      let end = spec.fraction(values[values.length() - 1]) * 100.0
      let side = if orientation == Vertical {
        "bottom"
      } else if direction == @theme.Rtl {
        "right"
      } else {
        "left"
      }
      let nodes : Array[@minimoon.Node] = [
        ui_container(
          "slider-range",
          [],
          style=side +
            ":" +
            start.to_string() +
            "%;" +
            (if orientation == Vertical { "height:" } else { "width:" }) +
            (end - start).to_string() +
            "%;",
        ),
      ]
      for index, value in values {
        nodes.push(
          ui_container(
            "slider-thumb",
            [],
            id=id + "-thumb-" + index.to_string(),
            style=side + ":" + (spec.fraction(value) * 100.0).to_string() + "%;",
            class=if state.drag is Some(drag) && drag.index == index {
              "mmui-active"
            } else {
              ""
            },
            semantics=@minimoon.semantics(
              role=@minimoon.SliderRole,
              label=label + " " + (index + 1).to_string(),
              value_min=spec.min,
              value_max=spec.max,
              value_now=value,
              disabled~,
            ),
          ),
        )
      }
      @minimoon.touch_view(
        id~,
        class="mmui-slider " +
          orientation_class(orientation) +
          (if disabled { " mmui-disabled" } else { "" }),
        event_key=id + "/gesture",
        catch_move=true,
        on_touch_start=emit.map(detail => StartDrag(detail)),
        on_touch_move=emit.map(detail => MoveDrag(detail)),
        on_touch_end=emit.map(detail => EndDrag(detail)),
        on_touch_cancel=emit.map(_ => CancelDrag),
        [ui_container("slider-track", nodes, id=id + "-track")],
      )
    }
  })
}

///|
pub fn slider_values(
  context : UiContext,
  id~ : String,
  default_values~ : Array[Int],
  spec? : @headless.SliderSpec = @headless.slider_spec(),
  orientation? : Orientation = Horizontal,
  direction? : @theme.TextDirection = @theme.Ltr,
  disabled? : Bool = false,
  label? : String = "Value",
  on_value_change? : @minimoon.Emit[Array[Int]],
  on_value_commit? : @minimoon.Emit[Array[Int]],
) -> @minimoon.Val[@minimoon.Node] {
  let (values, update) = @minimoon.create_variable(
    spec.normalize(default_values),
  )
  slider_values_controlled(
    context,
    id~,
    values~,
    on_change=@minimoon.Emit(values => {
      @minimoon.batch([
        update(_ => values),
        on_value_change.map(emit => emit(values)).unwrap_or(@minimoon.none),
      ])
    }),
    on_commit?=on_value_commit,
    spec~,
    orientation~,
    direction~,
    disabled~,
    label~,
  )
}

///|
pub fn slider_controlled(
  context : UiContext,
  id~ : String,
  value~ : @minimoon.Val[Int],
  on_change~ : @minimoon.Emit[Int],
  on_commit? : @minimoon.Emit[Int],
  spec? : @headless.SliderSpec = @headless.slider_spec(),
  orientation? : Orientation = Horizontal,
  direction? : @theme.TextDirection = @theme.Ltr,
  disabled? : Bool = false,
  label? : String = "Value",
) -> @minimoon.Val[@minimoon.Node] {
  slider_values_controlled(
    context,
    id~,
    values=value.map(value => [value]),
    on_change=on_change.map(values => values[0]),
    on_commit?=on_commit.map(emit => emit.map(values => values[0])),
    spec~,
    orientation~,
    direction~,
    disabled~,
    label~,
  )
}

///|
pub fn slider(
  context : UiContext,
  id~ : String,
  default_value? : Int = 0,
  spec? : @headless.SliderSpec = @headless.slider_spec(),
  orientation? : Orientation = Horizontal,
  direction? : @theme.TextDirection = @theme.Ltr,
  disabled? : Bool = false,
  label? : String = "Value",
  on_value_change? : @minimoon.Emit[Int],
  on_value_commit? : @minimoon.Emit[Int],
) -> @minimoon.Val[@minimoon.Node] {
  slider_values(
    context,
    id~,
    default_values=[default_value],
    spec~,
    orientation~,
    direction~,
    disabled~,
    label~,
    on_value_change?=on_value_change.map(emit => emit.map(values => values[0])),
    on_value_commit?=on_value_commit.map(emit => emit.map(values => values[0])),
  )
}
