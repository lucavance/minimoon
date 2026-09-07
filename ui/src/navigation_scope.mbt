///|
/// Touch-native compound navigation adapted from RUI b1291945 (MIT).
struct NavigationMenuScope {
  id : String
  value : String?
  viewport : Bool
  bounds : @headless.Bounds?
  change : @minimoon.Emit[String?]
  toggle : @minimoon.Emit[String]
  contents : Ref[@minimoon.Node?]
  chrome : Ref[@minimoon.Node?]
  keys : Set[String]
}

///|
struct NavigationMenuItemScope {
  owner : NavigationMenuScope
  value : String
  disabled : Bool
}

///|
priv struct NavigationBounds {
  value : String?
  bounds : @headless.Bounds?
} derive(Eq)

///|
fn navigation_part_id(id : String, value : String, part : String) -> String {
  let pieces : Array[String] = value
    .iter()
    .map(character => character.to_int().to_string())
    .collect()
  let encoded = pieces.join("_")
  id + "-" + part + "-" + encoded
}

///|
pub fn navigation_menu_value(scope : NavigationMenuScope) -> String? {
  scope.value
}

///|
pub fn navigation_menu_activate(
  scope : NavigationMenuScope,
  value : String,
) -> @minimoon.Cmd {
  (scope.change)(Some(value))
}

///|
pub fn navigation_menu_close(scope : NavigationMenuScope) -> @minimoon.Cmd {
  (scope.change)(None)
}

///|
pub fn navigation_menu_item_is_open(scope : NavigationMenuItemScope) -> Bool {
  scope.owner.value == Some(scope.value) && !scope.disabled
}

///|
pub fn[C : @minimoon.IsChildren] navigation_menu_list(
  scope : NavigationMenuScope,
  children : C,
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "navigation-menu-list",
    id=scope.id + "-list",
    class~,
    style="display:flex;flex-wrap:wrap;gap:4px;" + style,
    children.to_nodes(),
  )
}

///|
pub fn navigation_menu_item(
  scope : NavigationMenuScope,
  value~ : String,
  render~ : (NavigationMenuItemScope) -> @minimoon.Node,
  disabled? : Bool = false,
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  guard value != "" && !scope.keys.contains(value) else {
    abort("navigation items require unique nonempty values")
  }
  scope.keys.add(value)
  ui_container(
    "navigation-menu-item",
    class~,
    style="position:relative;" + style,
    [render({ owner: scope, value, disabled, })],
  )
}

///|
pub fn[C : @minimoon.IsChildren] navigation_menu_trigger(
  scope : NavigationMenuItemScope,
  children : C,
  disabled? : Bool = false,
  class? : String = "",
  on_tap? : @minimoon.Cmd,
) -> @minimoon.Node {
  let disabled = disabled || scope.disabled
  let open = navigation_menu_item_is_open(scope)
  @minimoon.button_children(
    id=navigation_part_id(scope.owner.id, scope.value, "trigger"),
    class="mmui-navigation-menu-trigger " + class,
    disabled~,
    event_key=scope.owner.id + "/trigger/" + scope.value,
    on_tap=if disabled {
      @minimoon.none
    } else {
      @minimoon.batch([
        (scope.owner.toggle)(scope.value),
        on_tap.unwrap_or(@minimoon.none),
      ])
    },
    semantics=@minimoon.semantics(
      expanded=open,
      controls=if scope.owner.viewport {
        scope.owner.id + "-viewport"
      } else {
        navigation_part_id(scope.owner.id, scope.value, "content")
      },
    ),
    children,
  )
}

///|
fn navigation_surface(
  scope : NavigationMenuScope,
  id : String,
  content : @minimoon.Node,
) -> @minimoon.Node {
  @minimoon.layer(id=scope.id + "-layer", [
    @minimoon.tap_view(
      on_tap=navigation_menu_close(scope),
      event_key=scope.id + "/dismiss",
      style="position:fixed;left:0;right:0;top:0;bottom:0;",
      @minimoon.nothing(),
    ),
    ui_container(
      "navigation-menu-viewport",
      id~,
      class="mmui-surface",
      style=surface_style(PopoverSurface, scope.bounds) +
        "min-width:240px;max-height:70vh;overflow:auto;",
      semantics=@minimoon.semantics(role=@minimoon.RegionRole),
      [
        content,
        @minimoon.button(
          on_tap=navigation_menu_close(scope),
          event_key=scope.id + "/close",
          "Close menu",
        ),
      ],
    ),
  ])
}

///|
pub fn[C : @minimoon.IsChildren] navigation_menu_content(
  scope : NavigationMenuItemScope,
  children : C,
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  if !navigation_menu_item_is_open(scope) {
    return @minimoon.nothing()
  }
  let content = ui_container(
    "navigation-menu-content",
    class~,
    style~,
    semantics=@minimoon.semantics(
      role=@minimoon.RegionRole,
      labelled_by=navigation_part_id(scope.owner.id, scope.value, "trigger"),
    ),
    children.to_nodes(),
  )
  if scope.owner.viewport {
    scope.owner.contents.val = Some(content)
    @minimoon.nothing()
  } else {
    navigation_surface(
      scope.owner,
      navigation_part_id(scope.owner.id, scope.value, "content"),
      content,
    )
  }
}

///|
/// Optional shared viewport chrome is collected only within the current render.
pub fn[C : @minimoon.IsChildren] navigation_menu_viewport(
  scope : NavigationMenuScope,
  children : C,
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  guard scope.chrome.val is None else {
    abort("navigation menu has only one shared viewport")
  }
  scope.chrome.val = Some(
    ui_container(
      "navigation-menu-viewport-chrome",
      class~,
      style~,
      children.to_nodes(),
    ),
  )
  @minimoon.nothing()
}

///|
pub fn navigation_menu_indicator(
  scope : NavigationMenuItemScope,
  class? : String = "",
) -> @minimoon.Node {
  if !navigation_menu_item_is_open(scope) {
    return @minimoon.nothing()
  }
  ui_container(
    "navigation-menu-indicator",
    class~,
    style="position:absolute;bottom:-4px;left:50%;width:8px;height:8px;transform:rotate(45deg);background:var(--mmui-border);",
    semantics=@minimoon.semantics(hidden=true),
    [],
  )
}

///|
pub fn[C : @minimoon.IsChildren] navigation_menu_link(
  target~ : @minimoon.Route,
  children : C,
  active? : Bool = false,
  scope? : NavigationMenuScope,
  class? : String = "",
  style? : String = "",
  on_tap? : @minimoon.Cmd,
) -> @minimoon.Node {
  @minimoon.tap_view(
    on_tap=@minimoon.batch([
      scope.map(navigation_menu_close).unwrap_or(@minimoon.none),
      on_tap.unwrap_or(@minimoon.none),
    ]),
    @minimoon.navigator(
      target~,
      class="mmui-navigation-menu-link " +
        (if active { "mmui-active " } else { "" }) +
        class,
      style~,
      children,
    ),
  )
}
