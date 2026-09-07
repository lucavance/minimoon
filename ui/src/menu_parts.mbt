///|
pub(all) enum MenuIndicatorPlacement {
  IndicatorStart
  IndicatorEnd
} derive(Eq, Debug)

///|
priv struct MenuPresentation {
  content : @minimoon.Node
  shortcut : String
  inset : Bool
  destructive : Bool
  close_on_select : Bool?
  indicator_placement : MenuIndicatorPlacement
}

///|
fn default_menu_presentation(label : String) -> MenuPresentation {
  {
    content: @minimoon.text(label),
    shortcut: "",
    inset: false,
    destructive: false,
    close_on_select: None,
    indicator_placement: IndicatorStart,
  }
}

///|
fn menu_item_content(
  presentation : MenuPresentation,
  checked? : Bool,
  radio? : Bool = false,
  submenu? : Bool = false,
) -> @minimoon.Node {
  let marker = match checked {
    Some(checked) =>
      ui_container(
        "menu-indicator",
        semantics=@minimoon.semantics(hidden=true),
        [
          @minimoon.text(
            if checked {
              if radio {
                "●"
              } else {
                "✓"
              }
            } else {
              ""
            },
          ),
        ],
      )
    None => @minimoon.nothing()
  }
  @minimoon.fragment([
    if presentation.indicator_placement == IndicatorStart {
      marker
    } else {
      @minimoon.nothing()
    },
    presentation.content,
    if presentation.shortcut == "" {
      @minimoon.nothing()
    } else {
      menu_shortcut(presentation.shortcut)
    },
    if presentation.indicator_placement == IndicatorEnd {
      marker
    } else {
      @minimoon.nothing()
    },
    if submenu {
      ui_container("menu-chevron", semantics=@minimoon.semantics(hidden=true), [
        @minimoon.text("›"),
      ])
    } else {
      @minimoon.nothing()
    },
  ])
}

///|
pub fn menu_customize(
  item : MenuItem,
  content? : @minimoon.Node,
  shortcut? : String = "",
  inset? : Bool = false,
  destructive? : Bool = false,
  close_on_select? : Bool,
  indicator_placement? : MenuIndicatorPlacement = IndicatorStart,
) -> MenuItem {
  {
    ..item,
    presentation: Some({
      content: content.unwrap_or(@minimoon.text(item.label)),
      shortcut,
      inset,
      destructive,
      close_on_select,
      indicator_placement,
    }),
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn menu_group(
  key~ : String,
  items~ : Array[MenuItem],
  label? : String = "",
) -> MenuItem {
  {
    key,
    label,
    disabled: false,
    kind: Group(items),
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn[C : @minimoon.IsChildren] menu_shortcut(children : C) -> @minimoon.Node {
  ui_container("menu-shortcut", children.to_nodes())
}

///|
/// A controlled menubar has at most one active menu; all children share one
/// application-owned value and report selection through its Emit.
pub fn menubar_controlled(
  context : UiContext,
  id~ : String,
  groups~ : Array[MenuGroup],
  value~ : @minimoon.Val[String?],
  on_value_change~ : @minimoon.Emit[String?],
) -> @minimoon.Val[@minimoon.Node] {
  let keys : Set[String] = Set([])
  for group in groups {
    guard group.key != "" && !keys.contains(group.key) else {
      abort("menubar keys must be unique and nonempty")
    }
    keys.add(group.key)
  }
  stack(
    groups.map(group => {
      dropdown_menu_controlled(
        context,
        id=id + "-" + group.key,
        trigger_label=group.label,
        items=group.items,
        open=value.map(value => value == Some(group.key)),
        on_change=on_value_change.map(open => {
          if open {
            Some(group.key)
          } else {
            None
          }
        }),
      )
    }),
  ).map(content => ui_container("menubar", [content]))
}
