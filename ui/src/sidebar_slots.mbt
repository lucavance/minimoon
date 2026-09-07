///|
pub fn[C : @minimoon.IsChildren] sidebar_header(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-header",
    id~,
    class~,
    style="display:flex;flex-direction:column;gap:8px;padding:8px;" + style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_footer(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-footer",
    id~,
    class~,
    style="display:flex;flex-direction:column;gap:8px;padding:8px;" + style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_group(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-group",
    id~,
    class~,
    style="position:relative;display:flex;flex-direction:column;padding:8px;" +
      style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_group_content(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-group-content",
    id~,
    class~,
    style="width:100%;min-width:0;" + style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-menu",
    id~,
    class~,
    style="display:flex;flex-direction:column;gap:4px;" + style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_item(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-menu-item",
    id~,
    class~,
    style="position:relative;min-width:0;" + style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_sub_item(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-menu-sub-item",
    id~,
    class~,
    style="position:relative;min-width:0;" + style,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_content(
  children : C,
  id? : String = "",
  class? : String = "",
  height? : String = "320px",
) -> @minimoon.Node {
  @minimoon.scroll_view(
    id~,
    class="mmui-sidebar-content " + class,
    scroll_y=true,
    style="min-height:0;height:" + height + ";",
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_group_label(
  scope : SidebarSurfaceScope,
  children : C,
  class? : String = "",
) -> @minimoon.Node {
  if sidebar_icon_only(scope) {
    @minimoon.nothing()
  } else {
    ui_container(
      "sidebar-group-label",
      class~,
      style="padding:8px;color:var(--mmui-muted-foreground);font-size:12px;",
      children.to_nodes(),
    )
  }
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_group_action(
  scope : SidebarSurfaceScope,
  on_tap~ : @minimoon.Cmd,
  children : C,
  disabled? : Bool = false,
  class? : String = "",
) -> @minimoon.Node {
  if sidebar_icon_only(scope) {
    @minimoon.nothing()
  } else {
    @minimoon.button_children(
      class="mmui-sidebar-group-action " + class,
      on_tap=if disabled { @minimoon.none } else { on_tap },
      disabled~,
      children,
    )
  }
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_button(
  scope : SidebarSurfaceScope,
  children : C,
  target? : @minimoon.Route,
  is_active? : Bool = false,
  variant? : SidebarMenuButtonVariant = SidebarMenuButtonDefault,
  size? : SidebarMenuButtonSize = SidebarMenuDefault,
  disabled? : Bool = false,
  aria_label? : String = "",
  on_tap? : @minimoon.Cmd,
  icon? : @minimoon.Node,
  id? : String = "",
  event_key? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  let icon_only = sidebar_icon_only(scope)
  let children = if icon_only && icon is Some(icon) {
    [icon]
  } else {
    let nodes : Array[@minimoon.Node] = []
    if icon is Some(icon) {
      nodes.push(icon)
    }
    for child in children.to_nodes() {
      nodes.push(child)
    }
    nodes
  }
  let command = @minimoon.batch([
    (scope.owner.send)(CloseTooltip),
    on_tap.unwrap_or(@minimoon.none),
    if target is Some(_) && scope.mobile {
      sidebar_close_mobile(scope.owner)
    } else {
      @minimoon.none
    },
  ])
  let height = match size {
    SidebarMenuSm => 32
    SidebarMenuDefault => 44
    SidebarMenuLg => 56
  }
  let classes = "mmui-sidebar-menu-button " +
    (if is_active { "mmui-active " } else { "" }) +
    (if variant == SidebarMenuButtonOutline { "mmui-outline " } else { "" }) +
    class
  let styles = "box-sizing:border-box;display:flex;align-items:center;gap:8px;width:100%;min-width:0;overflow:hidden;height:" +
    height.to_string() +
    "px;" +
    (if icon_only {
      "justify-content:center;padding:4px;"
    } else {
      "padding:8px;"
    }) +
    (if is_active { "background:var(--mmui-border);" } else { "" }) +
    (if variant == SidebarMenuButtonOutline {
      "border:1px solid var(--mmui-border);"
    } else {
      ""
    }) +
    style
  if target is Some(target) && !disabled {
    @minimoon.tap_view(
      on_tap=command,
      event_key~,
      @minimoon.navigator(target~, id~, class=classes, style=styles, children),
    )
  } else {
    @minimoon.button_children(
      id~,
      event_key~,
      class=classes,
      style=styles,
      disabled~,
      semantics=@minimoon.semantics(label=aria_label, selected=is_active),
      on_tap=if disabled { @minimoon.none } else { command },
      children,
    )
  }
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_action(
  scope : SidebarSurfaceScope,
  on_tap~ : @minimoon.Cmd,
  children : C,
  disabled? : Bool = false,
  class? : String = "",
) -> @minimoon.Node {
  sidebar_group_action(
    scope,
    on_tap~,
    disabled~,
    class="mmui-sidebar-menu-action " + class,
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_badge(
  scope : SidebarSurfaceScope,
  children : C,
  class? : String = "",
) -> @minimoon.Node {
  if sidebar_icon_only(scope) {
    @minimoon.nothing()
  } else {
    ui_container("sidebar-menu-badge", class~, children.to_nodes())
  }
}

///|
pub fn sidebar_menu_skeleton(
  show_icon? : Bool = false,
  width? : Int = 128,
  class? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-menu-skeleton",
    class~,
    style="display:flex;gap:8px;padding:8px;",
    [
      if show_icon {
        ui_container(
          "skeleton",
          style="width:24px;height:24px;background:var(--mmui-border);border-radius:4px;",
          [],
        )
      } else {
        @minimoon.nothing()
      },
      ui_container(
        "skeleton",
        style="width:" +
          width.max(0).to_string() +
          "px;max-width:80%;height:16px;background:var(--mmui-border);border-radius:4px;",
        [],
      ),
    ],
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_sub(
  scope : SidebarSurfaceScope,
  children : C,
  class? : String = "",
) -> @minimoon.Node {
  if sidebar_icon_only(scope) {
    @minimoon.nothing()
  } else {
    ui_container(
      "sidebar-menu-sub",
      class~,
      style="display:flex;flex-direction:column;margin:4px 12px;padding:4px 8px;border-left:1px solid var(--mmui-border);",
      children.to_nodes(),
    )
  }
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_menu_sub_button(
  scope : SidebarSurfaceScope,
  children : C,
  target? : @minimoon.Route,
  is_active? : Bool = false,
  disabled? : Bool = false,
  on_tap? : @minimoon.Cmd,
  class? : String = "",
) -> @minimoon.Node {
  if sidebar_icon_only(scope) {
    @minimoon.nothing()
  } else {
    sidebar_menu_button(
      scope,
      children,
      target?,
      is_active~,
      disabled~,
      on_tap?,
      size=SidebarMenuSm,
      class="mmui-sidebar-menu-sub-button " + class,
    )
  }
}

///|
pub fn sidebar_separator(class? : String = "") -> @minimoon.Node {
  ui_container(
    "sidebar-separator",
    class~,
    style="height:1px;margin:8px;background:var(--mmui-border);",
    semantics=@minimoon.semantics(role=@minimoon.SeparatorRole),
    [],
  )
}

///|
pub fn sidebar_input(
  value~ : String,
  on_input~ : @minimoon.Emit[String],
  name? : String = "",
  placeholder? : String = "Search",
  disabled? : Bool = false,
  id? : String = "",
  event_key? : String = "",
  class? : String = "",
) -> @minimoon.Node {
  @minimoon.input(
    value~,
    on_input~,
    name~,
    placeholder~,
    disabled~,
    id~,
    event_key~,
    class="mmui-sidebar-input " + class,
  )
}

///|
pub fn[C : @minimoon.IsChildren] sidebar_inset(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "sidebar-inset",
    id~,
    class~,
    style="position:relative;order:1;flex:1;min-width:0;display:flex;flex-direction:column;margin:8px;border-radius:var(--mmui-radius);background:var(--mmui-background);" +
      style,
    children.to_nodes(),
  )
}
