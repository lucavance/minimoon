///|
priv enum OverlayRequest {
  Request(Bool, OverlayCloseReason)
  Apply(Int, Bool, OverlayCloseReason)
  Hide
  InputChanged
  Toggle
  Act(@minimoon.Cmd, Bool, OverlayCloseReason)
}

///|
pub fn[Input : Eq] overlay_provider_controlled_with_input(
  context : UiContext,
  id~ : String,
  input~ : @minimoon.Val[Input],
  open~ : @minimoon.Val[Bool],
  on_open_change~ : @minimoon.Emit[Bool],
  render~ : (OverlayScope, Input) -> @minimoon.Node,
  kind? : OverlayKind = DialogSurface,
  disabled? : Bool = false,
  modal? : Bool,
  close_on_overlay? : Bool = true,
  force_mount? : Bool = false,
  placement? : @headless.Placement = @headless.BottomStart,
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
  delay_ms? : Int = 0,
  close_delay_ms? : Int = 0,
  on_close? : @minimoon.Emit[OverlayCloseReason],
) -> @minimoon.Val[@minimoon.Node] {
  let floating = kind is PopoverSurface ||
    kind is PreviewSurface ||
    kind is TooltipSurface ||
    kind is ContextSurface
  let state = @minimoon.Val::map2(open, context.visible, (open, visible) => {
    (open, visible)
  })
  let (_, emit) = @minimoon.create_state_with_input(
    input=state,
    init=(_, _) => @minimoon.no_cmd(0),
    update=(token, state, message : OverlayRequest, emit) => {
      let (open, visible) = state
      match message {
        Act(command, close, reason) =>
          (
            token,
            if open && visible {
              @minimoon.batch([
                command,
                if close {
                  emit(Request(false, reason))
                } else {
                  @minimoon.none
                },
              ])
            } else {
              @minimoon.none
            },
          )
        Toggle => (token, emit(Request(!open, Programmatic)))
        InputChanged => @minimoon.no_cmd(token + 1)
        Request(next, reason) => {
          if disabled && next {
            return @minimoon.no_cmd(token)
          }
          let delay = if next { delay_ms } else { close_delay_ms }
          (
            token + 1,
            if delay <= 0 {
              emit(Apply(token + 1, next, reason))
            } else {
              @minimoon.delay(emit(Apply(token + 1, next, reason)), delay)
            },
          )
        }
        Apply(expected, next, reason) => {
          if token != expected || !visible || (next && disabled) {
            return @minimoon.no_cmd(token)
          }
          (
            token,
            @minimoon.batch([
              on_open_change(next),
              if open && !next {
                on_close.map(emit => emit(reason)).unwrap_or(@minimoon.none)
              } else {
                @minimoon.none
              },
            ]),
          )
        }
        Hide =>
          (
            token + 1,
            if floating && open {
              @minimoon.batch([
                on_open_change(false),
                on_close.map(emit => emit(PageHidden)).unwrap_or(@minimoon.none),
              ])
            } else {
              @minimoon.none
            },
          )
      }
    },
    subscriptions=(_, _, emit) => context.page.on_hide(emit(Hide)),
  )
  let watcher = open.switch_by(
    (_, _) => {
      let (_, _) = @minimoon.create_state_with_init(
        init=_ => ((), emit(InputChanged)),
        update=(_, _ : Unit, _) => @minimoon.no_cmd(()),
      )
      @minimoon.Val::constant(@minimoon.nothing())
    },
    by=open => if open { "open" } else { "closed" },
  )
  let bounds = if floating {
    floating_bounds(context, id, open, placement, side_offset~, align_offset~)
  } else {
    @minimoon.Val::constant(None)
  }
  let rendered = @minimoon.Val::view4(open, input, bounds, context.visible, (
    open,
    input,
    bounds,
    visible,
  ) => {
    render(
      OverlayScope::{
        id,
        open,
        visible,
        disabled,
        modal: modal.unwrap_or(!floating),
        force_mount,
        close_on_overlay,
        kind,
        bounds,
        toggle: emit(Toggle),
        act: emit.map(value => {
          let (command, close, reason) = value
          Act(command, close, reason)
        }),
        change: emit.map(value => {
          let (open, reason) = value
          Request(open, reason)
        }),
      },
      input,
    )
  })
  @minimoon.Val::view2(rendered, watcher, (rendered, watcher) => {
    @minimoon.fragment([rendered, watcher])
  })
}

///|
pub fn overlay_provider_controlled(
  context : UiContext,
  id~ : String,
  open~ : @minimoon.Val[Bool],
  on_open_change~ : @minimoon.Emit[Bool],
  render~ : (OverlayScope) -> @minimoon.Node,
  kind? : OverlayKind = DialogSurface,
  disabled? : Bool = false,
  modal? : Bool,
  close_on_overlay? : Bool = true,
  force_mount? : Bool = false,
  placement? : @headless.Placement = @headless.BottomStart,
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
  delay_ms? : Int = 0,
  close_delay_ms? : Int = 0,
  on_close? : @minimoon.Emit[OverlayCloseReason],
) -> @minimoon.Val[@minimoon.Node] {
  overlay_provider_controlled_with_input(
    context,
    id~,
    input=@minimoon.Val::constant(()),
    open~,
    on_open_change~,
    render=(scope, _) => render(scope),
    kind~,
    disabled~,
    modal?,
    close_on_overlay~,
    force_mount~,
    placement~,
    side_offset~,
    align_offset~,
    delay_ms~,
    close_delay_ms~,
    on_close?,
  )
}

///|
pub fn overlay_provider(
  context : UiContext,
  id~ : String,
  render~ : (OverlayScope) -> @minimoon.Node,
  initially_open? : Bool = false,
  kind? : OverlayKind = DialogSurface,
  disabled? : Bool = false,
  modal? : Bool,
  close_on_overlay? : Bool = true,
  force_mount? : Bool = false,
  placement? : @headless.Placement = @headless.BottomStart,
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
  delay_ms? : Int = 0,
  close_delay_ms? : Int = 0,
  on_close? : @minimoon.Emit[OverlayCloseReason],
  on_open_change? : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(initially_open)
  overlay_provider_controlled(
    context,
    id~,
    open~,
    on_open_change=@minimoon.Emit(value => {
      @minimoon.batch([
        emit(_ => value),
        on_open_change.map(emit => emit(value)).unwrap_or(@minimoon.none),
      ])
    }),
    render~,
    kind~,
    disabled~,
    modal?,
    close_on_overlay~,
    force_mount~,
    placement~,
    side_offset~,
    align_offset~,
    delay_ms~,
    close_delay_ms~,
    on_close?,
  )
}
