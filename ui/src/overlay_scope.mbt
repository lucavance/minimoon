///|
pub(all) enum OverlayCloseReason {
  CloseButton
  Backdrop
  Action
  PageHidden
  Programmatic
} derive(Eq, Debug)

///|
struct OverlayScope {
  id : String
  open : Bool
  visible : Bool
  disabled : Bool
  modal : Bool
  force_mount : Bool
  close_on_overlay : Bool
  kind : OverlayKind
  bounds : @headless.Bounds?
  change : @minimoon.Emit[(Bool, OverlayCloseReason)]
  toggle : @minimoon.Cmd
  act : @minimoon.Emit[(@minimoon.Cmd, Bool, OverlayCloseReason)]
}

///|
pub fn overlay_is_open(scope : OverlayScope) -> Bool {
  scope.open
}

///|
pub fn overlay_open(scope : OverlayScope) -> @minimoon.Cmd {
  (scope.change)((true, Programmatic))
}

///|
pub fn overlay_close(
  scope : OverlayScope,
  reason? : OverlayCloseReason = Programmatic,
) -> @minimoon.Cmd {
  (scope.change)((false, reason))
}

///|
pub fn overlay_toggle(scope : OverlayScope) -> @minimoon.Cmd {
  scope.toggle
}

///|
pub fn[C : @minimoon.IsChildren] overlay_trigger(
  scope : OverlayScope,
  children : C,
  on_tap? : @minimoon.Cmd,
  class? : String = "",
) -> @minimoon.Node {
  let command = if scope.disabled {
    @minimoon.none
  } else {
    @minimoon.batch([overlay_toggle(scope), on_tap.unwrap_or(@minimoon.none)])
  }
  let semantics = @minimoon.semantics(
    expanded=scope.open,
    controls=scope.id + "-surface",
    has_popup="dialog",
  )
  if scope.kind is ContextSurface {
    @minimoon.touch_view(
      id=scope.id + "-trigger",
      class="mmui-overlay-trigger " + class,
      event_key=scope.id + "/trigger",
      semantics~,
      on_tap=command,
      on_long_press=@minimoon.Emit(_ => command),
      children,
    )
  } else {
    @minimoon.button_children(
      id=scope.id + "-trigger",
      class="mmui-overlay-trigger " + class,
      event_key=scope.id + "/trigger",
      semantics~,
      disabled=scope.disabled,
      on_tap=command,
      children,
    )
  }
}

///|
pub fn[C : @minimoon.IsChildren] overlay_content(
  scope : OverlayScope,
  children : C,
  show_close? : Bool = true,
  close_label? : String = "Close",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  let displayed = scope.open && scope.visible
  if !displayed && !scope.force_mount {
    return @minimoon.nothing()
  }
  let surface = ui_container(
    "surface",
    id=scope.id + "-surface",
    class~,
    style=surface_style(scope.kind, scope.bounds) +
      (if displayed { "" } else { "display:none;" }) +
      style,
    semantics=@minimoon.semantics(
      role=if scope.kind is TooltipSurface {
        @minimoon.TooltipRole
      } else if scope.kind is AlertSurface {
        @minimoon.AlertDialogRole
      } else {
        @minimoon.DialogRole
      },
      modal=scope.modal,
      labelled_by=scope.id + "-title",
      described_by=scope.id + "-description",
      hidden=!displayed,
    ),
    [
      @minimoon.fragment(children.to_nodes()),
      if show_close {
        overlay_close_button(scope, close_label)
      } else {
        @minimoon.nothing()
      },
    ],
  )
  @minimoon.layer(id=scope.id + "-layer", [
    if displayed {
      @minimoon.tap_view(
        class="mmui-overlay",
        style="position:fixed;inset:0;",
        event_key=scope.id + "/dismiss",
        on_tap=if scope.close_on_overlay && !(scope.kind is AlertSurface) {
          overlay_close(scope, reason=Backdrop)
        } else {
          @minimoon.none
        },
        @minimoon.nothing(),
      )
    } else {
      @minimoon.nothing()
    },
    surface,
  ])
}

///|
pub fn[C : @minimoon.IsChildren] overlay_title(
  scope : OverlayScope,
  children : C,
) -> @minimoon.Node {
  @minimoon.h1(id=scope.id + "-title", class="mmui-surface-title", children)
}

///|
pub fn[C : @minimoon.IsChildren] overlay_description(
  scope : OverlayScope,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "surface-description",
    id=scope.id + "-description",
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] overlay_header(children : C) -> @minimoon.Node {
  ui_container("surface-header", children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] overlay_footer(children : C) -> @minimoon.Node {
  ui_container("surface-footer", children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] overlay_close_button(
  scope : OverlayScope,
  children : C,
  on_tap? : @minimoon.Cmd,
  key? : String = "close",
) -> @minimoon.Node {
  @minimoon.button_children(
    event_key=scope.id + "/" + key,
    disabled=!scope.open || !scope.visible,
    on_tap=(scope.act)((on_tap.unwrap_or(@minimoon.none), true, CloseButton)),
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] overlay_action(
  scope : OverlayScope,
  children : C,
  on_tap~ : @minimoon.Cmd,
  close? : Bool = true,
  key? : String = "action",
) -> @minimoon.Node {
  @minimoon.button_children(
    event_key=scope.id + "/" + key,
    disabled=!scope.open || !scope.visible,
    on_tap=(scope.act)((on_tap, close, Action)),
    children,
  )
}

///|
pub fn overlay_arrow(side? : Side = Top) -> @minimoon.Node {
  let margin = match side {
    Top => "margin-top:-20px;"
    Bottom => "margin-bottom:-20px;"
    Left => "margin-left:-20px;"
    Right => "margin-right:-20px;"
  }
  ui_container(
    "surface-arrow",
    style="width:8px;height:8px;background:var(--mmui-background);transform:rotate(45deg);" +
      margin,
    semantics=@minimoon.semantics(hidden=true),
    [],
  )
}
