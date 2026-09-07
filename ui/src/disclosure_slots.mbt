///|
/// RUI disclosure compound primitives; callers own state through Val and Emit.
pub(all) enum TabsListVariant {
  TabsDefault
  TabsLine
} derive(Eq, Debug)

///|
fn validate_panels(items : Array[Panel]) -> Unit {
  let seen : Map[String, Bool] = Map([])
  for item in items {
    guard item.key != "" && !seen.contains(item.key) else {
      abort("panel keys must be unique and nonempty")
    }
    seen[item.key] = true
  }
}

///|
fn normalize_panel_keys(
  items : Array[Panel],
  keys : Array[String],
  multiple : Bool,
) -> Array[String] {
  let normalized : Array[String] = []
  for key in keys {
    if !normalized.contains(key) && items.any(item => item.key == key) {
      normalized.push(key)
      if !multiple {
        break
      }
    }
  }
  normalized
}

///|
fn valid_tab_selection(items : Array[Panel], selected : String?) -> String? {
  if items.any(item => selected == Some(item.key) && !item.disabled) {
    return selected
  }
  for item in items {
    if !item.disabled {
      return Some(item.key)
    }
  }
  None
}

///|
fn panel_trigger(item : Panel) -> @minimoon.Node {
  item.trigger.unwrap_or(
    @minimoon.fragment([
      item.icon.unwrap_or(@minimoon.nothing()),
      @minimoon.text(item.title),
    ]),
  )
}

///|
pub fn[C : @minimoon.IsChildren] accordion_root(
  id? : String = "",
  disabled? : Bool = false,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "accordion",
    children.to_nodes(),
    id~,
    semantics=@minimoon.semantics(disabled~),
  )
}

///|
pub fn[C : @minimoon.IsChildren] accordion_item(
  id? : String = "",
  open? : Bool = false,
  disabled? : Bool = false,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "accordion-item",
    children.to_nodes(),
    id~,
    semantics=@minimoon.semantics(expanded=open, disabled~),
  )
}

///|
pub fn[C : @minimoon.IsChildren] accordion_trigger(
  value~ : String,
  on_change~ : @minimoon.Emit[String],
  open? : Bool = false,
  disabled? : Bool = false,
  controls? : String = "",
  id? : String = "",
  show_indicator? : Bool = true,
  children : C,
) -> @minimoon.Node {
  @minimoon.button_children(
    id~,
    class="mmui-accordion-trigger",
    disabled~,
    on_tap=if disabled { @minimoon.none } else { on_change(value) },
    semantics=@minimoon.semantics(
      role=@minimoon.ButtonRole,
      expanded=open,
      controls~,
      disabled~,
    ),
    [
      @minimoon.fragment(children.to_nodes()),
      if show_indicator {
        @minimoon.text(if open { "−" } else { "+" })
      } else {
        @minimoon.nothing()
      },
    ],
  )
}

///|
pub fn[C : @minimoon.IsChildren] accordion_content(
  id? : String = "",
  open? : Bool = false,
  force_mount? : Bool = false,
  labelled_by? : String = "",
  children : C,
) -> @minimoon.Node {
  if !open && !force_mount {
    @minimoon.nothing()
  } else {
    ui_container(
      "accordion-panel",
      children.to_nodes(),
      id~,
      style=if open { "" } else { "display:none;" },
      semantics=@minimoon.semantics(
        role=@minimoon.RegionRole,
        hidden=!open,
        labelled_by~,
      ),
    )
  }
}

///|
pub fn[C : @minimoon.IsChildren] collapsible_root(
  id? : String = "",
  open? : Bool = false,
  disabled? : Bool = false,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "collapsible",
    children.to_nodes(),
    id~,
    semantics=@minimoon.semantics(expanded=open, disabled~),
  )
}

///|
pub fn[C : @minimoon.IsChildren] collapsible_trigger(
  on_change~ : @minimoon.Emit[Bool],
  open? : Bool = false,
  disabled? : Bool = false,
  controls? : String = "",
  id? : String = "",
  show_indicator? : Bool = true,
  children : C,
) -> @minimoon.Node {
  @minimoon.button_children(
    id~,
    class="mmui-collapsible-trigger",
    disabled~,
    on_tap=if disabled { @minimoon.none } else { on_change(!open) },
    semantics=@minimoon.semantics(
      role=@minimoon.ButtonRole,
      expanded=open,
      controls~,
      disabled~,
    ),
    [
      @minimoon.fragment(children.to_nodes()),
      if show_indicator {
        @minimoon.text(if open { "−" } else { "+" })
      } else {
        @minimoon.nothing()
      },
    ],
  )
}

///|
pub fn[C : @minimoon.IsChildren] collapsible_content(
  id? : String = "",
  open? : Bool = false,
  force_mount? : Bool = false,
  labelled_by? : String = "",
  children : C,
) -> @minimoon.Node {
  accordion_content(id~, open~, force_mount~, labelled_by~, children)
}

///|
pub fn[C : @minimoon.IsChildren] tabs_root(
  id? : String = "",
  vertical? : Bool = false,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "tabs",
    children.to_nodes(),
    id~,
    class=if vertical { "mmui-vertical" } else { "mmui-horizontal" },
  )
}

///|
pub fn[C : @minimoon.IsChildren] tabs_list(
  id? : String = "",
  vertical? : Bool = false,
  variant? : TabsListVariant = TabsDefault,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "tab-list",
    children.to_nodes(),
    id~,
    class=(if vertical { "mmui-vertical" } else { "mmui-horizontal" }) +
      (if variant == TabsLine {
        " mmui-tabs-line"
      } else {
        " mmui-tabs-default"
      }),
    semantics=@minimoon.semantics(
      role=@minimoon.TabListRole,
      orientation=if vertical { "vertical" } else { "horizontal" },
    ),
  )
}

///|
pub fn[C : @minimoon.IsChildren] tabs_trigger(
  value~ : String,
  on_change~ : @minimoon.Emit[String],
  selected? : Bool = false,
  disabled? : Bool = false,
  controls? : String = "",
  id? : String = "",
  children : C,
) -> @minimoon.Node {
  @minimoon.button_children(
    id~,
    class="mmui-tab",
    disabled~,
    on_tap=if disabled { @minimoon.none } else { on_change(value) },
    semantics=@minimoon.semantics(
      role=@minimoon.TabRole,
      selected~,
      controls~,
      disabled~,
    ),
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] tabs_content(
  id? : String = "",
  selected? : Bool = false,
  force_mount? : Bool = false,
  labelled_by? : String = "",
  children : C,
) -> @minimoon.Node {
  if !selected && !force_mount {
    @minimoon.nothing()
  } else {
    ui_container(
      "tab-panel",
      children.to_nodes(),
      id~,
      style=if selected { "" } else { "display:none;" },
      semantics=@minimoon.semantics(
        role=@minimoon.TabPanelRole,
        hidden=!selected,
        labelled_by~,
      ),
    )
  }
}
