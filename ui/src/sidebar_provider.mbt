///|
fn[Input : Eq] sidebar_build(
  context : UiContext,
  id : String,
  input : @minimoon.Val[Input],
  value : @minimoon.Val[SidebarState],
  change : @minimoon.Emit[SidebarState],
  render : (SidebarScope, Input) -> @minimoon.Node,
  style : String,
) -> @minimoon.Val[@minimoon.Node] {
  let initial = SidebarTransient::{
    token: 0,
    drag: None,
    suppress_tap: false,
    tooltip: None,
  }
  let (transient, send) = @minimoon.create_state_with_input(
    input=value,
    init=(_, _) => @minimoon.no_cmd(initial),
    update=(transient_state, current, message : SidebarMsg, emit) => {
      match message {
        ToggleCollapsed =>
          (
            { ..initial, token: transient_state.token + 1, },
            change({ ..current, collapsed: !current.collapsed, }),
          )
        ToggleMobile =>
          (
            { ..initial, token: transient_state.token + 1, },
            change({ ..current, mobile_open: !current.mobile_open, }),
          )
        SetCollapsed(collapsed) =>
          (
            { ..initial, token: transient_state.token + 1, },
            if current.collapsed == collapsed {
              @minimoon.none
            } else {
              change({ ..current, collapsed, })
            },
          )
        SetMobile(mobile_open) =>
          (
            { ..initial, token: transient_state.token + 1, },
            if current.mobile_open == mobile_open {
              @minimoon.none
            } else {
              change({ ..current, mobile_open, })
            },
          )
        SetWidth(width) =>
          (
            transient_state,
            if width == current.width {
              @minimoon.none
            } else {
              change({ ..current, width, })
            },
          )
        RailTap =>
          if transient_state.suppress_tap {
            @minimoon.no_cmd({ ..transient_state, suppress_tap: false, })
          } else {
            (
              { ..initial, token: transient_state.token + 1, },
              change({ ..current, collapsed: !current.collapsed, }),
            )
          }
        ClearTransient =>
          @minimoon.no_cmd({ ..initial, token: transient_state.token + 1, })
        Hide =>
          (
            { ..initial, token: transient_state.token + 1, },
            transient_state.drag
            .map(drag => change({ ..current, width: drag.initial, }))
            .unwrap_or(@minimoon.none),
          )
        RailStart(side, minimum, maximum, detail) => {
          guard !current.collapsed &&
            !current.mobile_open &&
            transient_state.drag is None &&
            detail.changed_touches.length() == 1 else {
            return @minimoon.no_cmd(transient_state)
          }
          let point = detail.changed_touches[0]
          @minimoon.no_cmd({
            ..transient_state,
            suppress_tap: false,
            drag: Some({
              pointer: point.identifier,
              start: point.client_x,
              initial: current.width,
              minimum,
              maximum,
              side,
              moved: false,
            }),
          })
        }
        RailMove(detail) | RailEnd(detail) => {
          guard transient_state.drag is Some(drag) else {
            return @minimoon.no_cmd(transient_state)
          }
          let ended = message is RailEnd(_)
          guard slider_point(
              if ended {
                detail.changed_touches
              } else {
                detail.touches
              },
              drag.pointer,
            )
            is Some(point) else {
            return @minimoon.no_cmd(transient_state)
          }
          let delta = (point.client_x - drag.start) *
            (if drag.side == SidebarLeft { 1.0 } else { -1.0 })
          let width = (drag.initial + delta).clamp(
            min=drag.minimum,
            max=drag.maximum,
          )
          let moved = drag.moved || delta.abs() >= 4.0
          (
            {
              ..transient_state,
              drag: if ended {
                None
              } else {
                Some({ ..drag, moved, })
              },
              suppress_tap: ended && moved,
            },
            if moved && width != current.width {
              change({ ..current, width, })
            } else {
              @minimoon.none
            },
          )
        }
        RailCancel(detail) => {
          guard transient_state.drag is Some(drag) &&
            slider_point(detail.changed_touches, drag.pointer) is Some(_) else {
            return @minimoon.no_cmd(transient_state)
          }
          (
            { ..transient_state, drag: None, suppress_tap: false, },
            change({ ..current, width: drag.initial, }),
          )
        }
        CloseTooltip =>
          @minimoon.no_cmd({
            ..transient_state,
            token: transient_state.token + 1,
            tooltip: None,
          })
        ShowTooltip(tooltip) => {
          let token = transient_state.token + 1
          (
            { ..transient_state, token, tooltip: Some(tooltip), },
            @minimoon.measure_nodes(
              [tooltip.id, tooltip.id + "-tooltip", "mmui-viewport"],
              emit.map(result => TooltipMeasured(token, result)),
            ),
          )
        }
        TooltipMeasured(token, result) => {
          guard transient_state.token == token &&
            transient_state.tooltip is Some(tip) else {
            return @minimoon.no_cmd(transient_state)
          }
          match result {
            Ok([Some(anchor), Some(surface), Some(window)]) =>
              @minimoon.no_cmd({
                ..transient_state,
                tooltip: Some({
                  ..tip,
                  bounds: Some(
                    sidebar_tooltip_bounds(tip, anchor, surface, window),
                  ),
                }),
              })
            _ => @minimoon.no_cmd({ ..transient_state, tooltip: None, })
          }
        }
      }
    },
    subscriptions=(_, _, emit) => context.page.on_hide(emit(Hide)),
  )
  let watcher = value
    .map(value => (value.collapsed, value.mobile_open))
    .switch_by(
      (_, _) => {
        let (_, _) = @minimoon.create_state_with_init(
          init=_ => ((), send(ClearTransient)),
          update=(_, _ : Unit, _) => @minimoon.no_cmd(()),
        )
        @minimoon.Val::constant(@minimoon.nothing())
      },
      by=flags => flags.0.to_string() + flags.1.to_string(),
    )
  let view = @minimoon.Val::view4(value, transient, input, context.visible, (
    state,
    transient,
    input,
    visible,
  ) => {
    guard state.width > 0.0 && state.width - state.width == 0.0 else {
      abort("sidebar width must be finite and positive")
    }
    let scope = SidebarScope::{ id, state, transient, visible, send, }
    ui_container(
      "sidebar-provider",
      id~,
      style="display:flex;position:relative;min-width:0;min-height:0;" + style,
      [render(scope, input)],
    )
  })
  @minimoon.Val::view2(view, watcher, (view, watcher) => {
    @minimoon.fragment([view, watcher])
  })
}

///|
pub fn[Input : Eq] sidebar_provider_controlled_with_input(
  context : UiContext,
  id~ : String,
  state~ : @minimoon.Val[SidebarState],
  on_change~ : @minimoon.Emit[SidebarState],
  input~ : @minimoon.Val[Input],
  render~ : (SidebarScope, Input) -> @minimoon.Node,
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  sidebar_build(context, id, input, state, on_change, render, style)
}

///|
pub fn sidebar_provider_controlled(
  context : UiContext,
  id~ : String,
  state~ : @minimoon.Val[SidebarState],
  on_change~ : @minimoon.Emit[SidebarState],
  render~ : (SidebarScope) -> @minimoon.Node,
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  sidebar_build(
    context,
    id,
    @minimoon.Val::constant(()),
    state,
    on_change,
    (scope, _) => render(scope),
    style,
  )
}

///|
pub fn[Input : Eq] sidebar_provider_with_input(
  context : UiContext,
  id~ : String,
  input~ : @minimoon.Val[Input],
  render~ : (SidebarScope, Input) -> @minimoon.Node,
  default_collapsed? : Bool = false,
  default_mobile_open? : Bool = false,
  default_width? : Double = 256.0,
  on_collapsed_change? : @minimoon.Emit[Bool],
  on_mobile_open_change? : @minimoon.Emit[Bool],
  on_width_change? : @minimoon.Emit[Double],
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  let (state, emit) = @minimoon.create_state(
    sidebar_state(
      collapsed=default_collapsed,
      mobile_open=default_mobile_open,
      width=default_width,
    ),
    update=(old, next : SidebarState, _) => {
      let commands : Array[@minimoon.Cmd] = []
      if old.collapsed != next.collapsed {
        if on_collapsed_change is Some(send) {
          commands.push(send(next.collapsed))
        }
      }
      if old.mobile_open != next.mobile_open {
        if on_mobile_open_change is Some(send) {
          commands.push(send(next.mobile_open))
        }
      }
      if old.width != next.width {
        if on_width_change is Some(send) {
          commands.push(send(next.width))
        }
      }
      (next, @minimoon.batch(commands))
    },
  )
  sidebar_build(context, id, input, state, emit, render, style)
}

///|
pub fn sidebar_provider(
  context : UiContext,
  id~ : String,
  render~ : (SidebarScope) -> @minimoon.Node,
  default_collapsed? : Bool = false,
  default_mobile_open? : Bool = false,
  default_width? : Double = 256.0,
  on_collapsed_change? : @minimoon.Emit[Bool],
  on_mobile_open_change? : @minimoon.Emit[Bool],
  on_width_change? : @minimoon.Emit[Double],
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  sidebar_provider_with_input(
    context,
    id~,
    input=@minimoon.Val::constant(()),
    render=(scope, _) => render(scope),
    default_collapsed~,
    default_mobile_open~,
    default_width~,
    on_collapsed_change?,
    on_mobile_open_change?,
    on_width_change?,
    style~,
  )
}
