///|
pub(all) enum Side {
  Top
  Right
  Bottom
  Left
} derive(Eq, Debug)

///|
pub(all) enum OverlayKind {
  DialogSurface
  AlertSurface
  SheetSurface(Side)
  PopoverSurface
  PreviewSurface
  TooltipSurface
  ContextSurface
} derive(Eq, Debug)

///|
fn surface_style(kind : OverlayKind, bounds : @headless.Bounds?) -> String {
  match kind {
    SheetSurface(Top) => "position:fixed;top:0;left:0;right:0;max-height:85vh;"
    SheetSurface(Bottom) =>
      "position:fixed;bottom:0;left:0;right:0;max-height:85vh;"
    SheetSurface(Left) =>
      "position:fixed;top:0;bottom:0;left:0;width:80vw;max-width:420px;"
    SheetSurface(Right) =>
      "position:fixed;top:0;bottom:0;right:0;width:80vw;max-width:420px;"
    PopoverSurface | PreviewSurface | TooltipSurface | ContextSurface =>
      match bounds {
        Some(bounds) =>
          "position:fixed;left:" +
          bounds.left.to_string() +
          "px;top:" +
          bounds.top.to_string() +
          "px;max-width:" +
          bounds.width.to_string() +
          "px;"
        None => "position:fixed;left:8px;top:8px;max-width:calc(100vw - 16px);"
      }
    _ => "position:fixed;left:5vw;right:5vw;top:20vh;max-height:70vh;"
  }
}

///|
fn rect_bounds(rect : @minimoon.NodeRect) -> @headless.Bounds {
  { left: rect.left, top: rect.top, width: rect.width, height: rect.height, }
}

///|
/// One controlled native overlay; content stays reactive while open.
pub fn overlay_controlled(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  trigger_label_value? : @minimoon.Val[String],
  content~ : @minimoon.Val[@minimoon.Node],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  kind? : OverlayKind = DialogSurface,
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
  placement? : @headless.Placement = @headless.BottomStart,
) -> @minimoon.Val[@minimoon.Node] {
  let floating = kind is PopoverSurface ||
    kind is PreviewSurface ||
    kind is TooltipSurface ||
    kind is ContextSurface
  let _ = @minimoon.create_state(
    (),
    update=(_, _message : Unit, _) => @minimoon.no_cmd(()),
    subscriptions=(_, _) => {
      if floating {
        context.page.on_hide(on_change(false))
      } else {
        @minimoon.Sub::none()
      }
    },
  )
  let bounds = if floating {
    floating_bounds(context, id, open, placement)
  } else {
    @minimoon.Val::constant(None)
  }
  let open_command = if disabled { @minimoon.none } else { on_change(true) }
  @minimoon.Val::view5(
    open,
    content,
    bounds,
    context.visible,
    trigger_label_value.unwrap_or(@minimoon.Val::constant(trigger_label)),
    (open, content, bounds, visible, trigger_label) => {
      let trigger = if kind is ContextSurface {
        @minimoon.touch_view(
          id=id + "-trigger",
          on_tap=open_command,
          on_long_press=@minimoon.Emit(_ => open_command),
          event_key=id + "/trigger",
          @minimoon.text(trigger_label),
        )
      } else {
        @minimoon.button(
          id=id + "-trigger",
          disabled~,
          on_tap=open_command,
          event_key=id + "/trigger",
          semantics=@minimoon.semantics(
            expanded=open,
            controls=id + "-surface",
            has_popup="dialog",
          ),
          trigger_label,
        )
      }
      let layer = if open && visible {
        let dismiss = if close_on_overlay && !(kind is AlertSurface) {
          on_change(false)
        } else {
          @minimoon.none
        }
        @minimoon.layer(id=id + "-layer", [
          @minimoon.tap_view(
            on_tap=dismiss,
            event_key=id + "/dismiss",
            class="mmui-overlay",
            style="position:fixed;left:0;top:0;right:0;bottom:0;",
            @minimoon.nothing(),
          ),
          ui_container(
            "surface",
            id=id + "-surface",
            style=surface_style(kind, bounds),
            semantics=@minimoon.semantics(
              role=if kind is AlertSurface {
                @minimoon.AlertDialogRole
              } else if kind is TooltipSurface {
                @minimoon.TooltipRole
              } else {
                @minimoon.DialogRole
              },
              modal=!floating,
              labelled_by=id + "-title",
            ),
            [
              @minimoon.h1(id=id + "-title", class="mmui-surface-title", title),
              content,
              @minimoon.button(
                on_tap=on_change(false),
                event_key=id + "/close",
                "Close",
              ),
            ],
          ),
        ])
      } else {
        @minimoon.nothing()
      }
      ui_container("overlay-trigger", [trigger, layer])
    },
  )
}

///|
pub fn dialog_controlled(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  close_on_overlay? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  overlay_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change~,
    close_on_overlay~,
  )
}

///|
pub fn dialog(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(initially_open)
  dialog_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change=emit.map(value => _ => value),
  )
}

///|
pub fn sheet(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  side? : Side = Right,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  overlay_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change=emit.map(value => _ => value),
    kind=SheetSurface(side),
  )
}

///|
pub fn alert_dialog(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  on_confirm~ : @minimoon.Cmd,
  confirm_label? : String = "Confirm",
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  let confirm = form_dispatch(
    @minimoon.Val::map2(open, context.visible, (open, visible) => {
      open && visible
    }),
    (active, _ : Unit) => {
      if active {
        @minimoon.batch([on_confirm, emit(_ => false)])
      } else {
        @minimoon.none
      }
    },
  )
  let content = content.map(content => {
    @minimoon.fragment([
      content,
      @minimoon.button(
        on_tap=confirm(()),
        event_key=id + "/confirm",
        confirm_label,
      ),
    ])
  })
  overlay_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change=emit.map(value => _ => value),
    kind=AlertSurface,
    close_on_overlay=false,
  )
}

///|
pub fn popover(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  placement? : @headless.Placement = @headless.BottomStart,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  overlay_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change=emit.map(value => _ => value),
    kind=PopoverSurface,
    placement~,
  )
}

///|
pub fn hover_card(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  overlay_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change=emit.map(value => _ => value),
    kind=PreviewSurface,
  )
}

///|
pub fn tooltip(
  context : UiContext,
  id~ : String,
  trigger_label~ : String,
  text~ : String,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  overlay_controlled(
    context,
    id~,
    title=text,
    trigger_label~,
    content=@minimoon.Val::constant(@minimoon.nothing()),
    open~,
    on_change=emit.map(value => _ => value),
    kind=TooltipSurface,
  )
}
