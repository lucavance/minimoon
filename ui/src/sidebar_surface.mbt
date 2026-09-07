///|
fn sidebar_icon_only(scope : SidebarSurfaceScope) -> Bool {
  !scope.mobile &&
  scope.collapsible == SidebarIcon &&
  scope.owner.state.collapsed
}

///|
pub fn SidebarSurfaceScope::is_icon_only(self : SidebarSurfaceScope) -> Bool {
  sidebar_icon_only(self)
}

///|
pub fn SidebarSurfaceScope::variant(
  self : SidebarSurfaceScope,
) -> SidebarVariant {
  self.variant
}

///|
pub fn sidebar_surface(
  scope : SidebarScope,
  render~ : (SidebarSurfaceScope) -> @minimoon.Node,
  side? : SidebarSide = SidebarLeft,
  variant? : SidebarVariant = SidebarDefault,
  collapsible? : SidebarCollapsible = SidebarOffcanvas,
  mobile? : Bool = false,
  hidden? : Bool = false,
  aria_label? : String = "Sidebar",
  id? : String,
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  if hidden || (mobile && (!scope.state.mobile_open || !scope.visible)) {
    return @minimoon.nothing()
  }
  let surface = SidebarSurfaceScope::{
    owner: scope,
    side,
    variant,
    collapsible,
    mobile,
  }
  let collapsed = !mobile &&
    collapsible != SidebarFixed &&
    scope.state.collapsed
  let width = if collapsed {
    if collapsible == SidebarIcon {
      48.0
    } else {
      0.0
    }
  } else {
    scope.state.width
  }
  let edge = if side == SidebarLeft { "left" } else { "right" }
  let variant_style = match variant {
    SidebarDefault => "border:1px solid var(--mmui-border);"
    SidebarFloating =>
      "margin:8px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);box-shadow:0 4px 16px rgba(0,0,0,.12);"
    SidebarInset => "margin:8px;border-radius:var(--mmui-radius);"
  }
  let node = ui_container(
    "sidebar-surface",
    id=id.unwrap_or(scope.id + (if mobile { "-mobile" } else { "-surface" })),
    class~,
    style="box-sizing:border-box;display:flex;flex-direction:column;flex-shrink:0;min-height:0;position:relative;overflow:hidden;background:var(--mmui-muted);color:var(--mmui-foreground);width:" +
      width.to_string() +
      "px;" +
      variant_style +
      (if mobile {
        "position:fixed;top:0;bottom:0;" +
        edge +
        ":0;max-width:calc(100vw - 32px);"
      } else if side == SidebarRight {
        "order:2;"
      } else {
        "order:0;"
      }) +
      style,
    semantics=@minimoon.semantics(
      role=if mobile { @minimoon.DialogRole } else { @minimoon.NavigationRole },
      label=aria_label,
      modal=mobile,
      hidden=collapsed && collapsible == SidebarOffcanvas,
    ),
    if collapsed && collapsible == SidebarOffcanvas {
      []
    } else {
      [render(surface)]
    },
  )
  if mobile {
    @minimoon.layer(id=scope.id + "-mobile-layer", [
      @minimoon.tap_view(
        on_tap=sidebar_close_mobile(scope),
        event_key=scope.id + "/mobile-dismiss",
        class="mmui-overlay",
        style="position:fixed;left:0;right:0;top:0;bottom:0;",
        @minimoon.nothing(),
      ),
      node,
    ])
  } else {
    node
  }
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_trigger(
  scope : SidebarScope,
  children : C,
  mobile? : Bool = false,
  disabled? : Bool = false,
  id? : String,
  class? : String = "",
  on_tap? : @minimoon.Cmd,
) -> @minimoon.Node {
  @minimoon.button_children(
    id=id.unwrap_or(
      scope.id + (if mobile { "-mobile-trigger" } else { "-trigger" }),
    ),
    class="mmui-sidebar-trigger " + class,
    disabled~,
    event_key=scope.id + (if mobile { "/mobile-toggle" } else { "/toggle" }),
    semantics=@minimoon.semantics(
      expanded=if mobile {
        scope.state.mobile_open
      } else {
        !scope.state.collapsed
      },
      controls=scope.id + (if mobile { "-mobile" } else { "-surface" }),
    ),
    on_tap=if disabled {
      @minimoon.none
    } else {
      @minimoon.batch([
        (scope.send)(if mobile { ToggleMobile } else { ToggleCollapsed }),
        on_tap.unwrap_or(@minimoon.none),
      ])
    },
    children,
  )
}

///|
pub fn sidebar_rail(
  scope : SidebarSurfaceScope,
  min_width? : Double = 160.0,
  max_width? : Double = 512.0,
  class? : String = "",
) -> @minimoon.Node {
  if scope.mobile || scope.collapsible == SidebarFixed {
    return @minimoon.nothing()
  }
  guard min_width > 0.0 &&
    min_width <= max_width &&
    max_width - max_width == 0.0 else {
    abort("sidebar rail needs finite ordered positive width bounds")
  }
  let send = scope.owner.send
  @minimoon.touch_view(
    id=scope.owner.id + "-rail",
    class="mmui-sidebar-rail " + class,
    style="position:absolute;top:0;bottom:0;" +
      (if scope.side == SidebarLeft { "right" } else { "left" }) +
      ":0;width:24px;",
    catch_move=true,
    event_key=scope.owner.id + "/rail",
    on_tap=send(RailTap),
    on_touch_start=send.map(detail => {
      RailStart(scope.side, min_width, max_width, detail)
    }),
    on_touch_move=send.map(detail => RailMove(detail)),
    on_touch_end=send.map(detail => RailEnd(detail)),
    on_touch_cancel=send.map(detail => RailCancel(detail)),
    semantics=@minimoon.semantics(
      role=@minimoon.SeparatorRole,
      orientation="vertical",
      label="Resize or toggle sidebar",
      expanded=!scope.owner.state.collapsed,
    ),
    @minimoon.div(
      style="position:absolute;left:50%;width:2px;top:0;bottom:0;background:var(--mmui-border);",
      @minimoon.nothing(),
    ),
  )
}
