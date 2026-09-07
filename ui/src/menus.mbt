///|
struct MenuItem {
  key : String
  label : String
  disabled : Bool
  kind : MenuItemKind
  presentation : MenuPresentation?
  stamp : @minimoon.Node
}

///|
priv enum MenuItemKind {
  Action(@minimoon.Cmd)
  Check(Bool, @minimoon.Emit[Bool])
  Radio(Bool, @minimoon.Cmd)
  Branch(Array[MenuItem])
  Group(Array[MenuItem])
  Heading
  Divider
}

///|
pub impl Eq for MenuItem with fn equal(a, b) {
  a.stamp == b.stamp
}

///|
pub fn menu_item(
  key~ : String,
  label~ : String,
  on_select~ : @minimoon.Cmd,
  disabled? : Bool = false,
) -> MenuItem {
  {
    key,
    label,
    disabled,
    kind: Action(on_select),
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn menu_checkbox_item(
  key~ : String,
  label~ : String,
  checked~ : Bool,
  on_change~ : @minimoon.Emit[Bool],
  disabled? : Bool = false,
) -> MenuItem {
  {
    key,
    label,
    disabled,
    kind: Check(checked, on_change),
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn menu_radio_item(
  key~ : String,
  label~ : String,
  selected~ : Bool,
  on_select~ : @minimoon.Cmd,
  disabled? : Bool = false,
) -> MenuItem {
  {
    key,
    label,
    disabled,
    kind: Radio(selected, on_select),
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn menu_submenu(
  key~ : String,
  label~ : String,
  items~ : Array[MenuItem],
  disabled? : Bool = false,
) -> MenuItem {
  {
    key,
    label,
    disabled,
    kind: Branch(items),
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn menu_label(key~ : String, label~ : String) -> MenuItem {
  {
    key,
    label,
    disabled: false,
    kind: Heading,
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
pub fn menu_separator(key~ : String) -> MenuItem {
  {
    key,
    label: "",
    disabled: false,
    kind: Divider,
    presentation: None,
    stamp: @minimoon.nothing(),
  }
}

///|
fn render_menu(
  id : String,
  items : Array[MenuItem],
  expanded : Array[String],
  select : @minimoon.Emit[String],
) -> @minimoon.Node {
  let keys : Set[String] = Set([])
  for item in items {
    guard item.key != "" && !keys.contains(item.key) else {
      abort("menu keys must be unique and nonempty")
    }
    keys.add(item.key)
  }
  ui_container(
    "menu",
    semantics=@minimoon.semantics(role=@minimoon.MenuRole),
    items.map(item => {
      let key = id + "/" + item.key
      let presentation = item.presentation.unwrap_or(
        default_menu_presentation(item.label),
      )
      match item.kind {
        Heading => ui_container("menu-label", [@minimoon.text(item.label)])
        Divider =>
          ui_container(
            "menu-separator",
            semantics=@minimoon.semantics(role=@minimoon.SeparatorRole),
            [],
          )
        Group(children) =>
          ui_container("menu-group", [
            if item.label == "" {
              @minimoon.nothing()
            } else {
              ui_container("menu-label", [@minimoon.text(item.label)])
            },
            render_menu(key, children, expanded, select),
          ])
        Branch(children) => {
          let open = expanded.contains(key)
          ui_container("menu-submenu", [
            @minimoon.button_children(
              disabled=item.disabled,
              event_key=key,
              on_tap=if item.disabled { @minimoon.none } else { select(key) },
              semantics=@minimoon.semantics(
                role=@minimoon.MenuItemRole,
                expanded=open,
              ),
              menu_item_content(presentation, submenu=true),
            ),
            if open {
              render_menu(key, children, expanded, select)
            } else {
              @minimoon.nothing()
            },
          ])
        }
        _ => {
          let (role, checked) = match item.kind {
            Check(checked, _) => (@minimoon.MenuItemCheckboxRole, Some(checked))
            Radio(selected, _) => (@minimoon.MenuItemRadioRole, Some(selected))
            _ => (@minimoon.MenuItemRole, None)
          }
          @minimoon.button_children(
            class="mmui-menu-item" +
              (if presentation.destructive { " mmui-destructive" } else { "" }),
            style=if presentation.inset { "padding-left:32px;" } else { "" },
            disabled=item.disabled,
            event_key=key,
            on_tap=if item.disabled { @minimoon.none } else { select(key) },
            semantics=@minimoon.semantics(role~, checked?),
            menu_item_content(
              presentation,
              checked?,
              radio=item.kind is Radio(_, _),
            ),
          )
        }
      }
    }),
  )
}

///|
pub fn dropdown_menu_controlled(
  context : UiContext,
  id~ : String,
  trigger_label~ : String,
  items~ : @minimoon.Val[Array[MenuItem]],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  context_menu? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (expanded, emit) = menu_dispatch(id, items, on_change(false), open~)
  let content = @minimoon.Val::view2(items, expanded, (items, expanded) => {
    render_menu(id, items, expanded, emit)
  })
  overlay_controlled(
    context,
    id~,
    title=trigger_label,
    trigger_label~,
    content~,
    open~,
    on_change~,
    kind=if context_menu { ContextSurface } else { PopoverSurface },
  )
}

///|
pub fn dropdown_menu(
  context : UiContext,
  id~ : String,
  trigger_label~ : String,
  items~ : @minimoon.Val[Array[MenuItem]],
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  dropdown_menu_controlled(
    context,
    id~,
    trigger_label~,
    items~,
    open~,
    on_change=emit.map(value => _ => value),
  )
}

///|
pub fn context_menu(
  context : UiContext,
  id~ : String,
  trigger_label~ : String,
  items~ : @minimoon.Val[Array[MenuItem]],
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(false)
  dropdown_menu_controlled(
    context,
    id~,
    trigger_label~,
    items~,
    open~,
    on_change=emit.map(value => _ => value),
    context_menu=true,
  )
}

///|
pub(all) struct MenuGroup {
  key : String
  label : String
  items : @minimoon.Val[Array[MenuItem]]
}

///|
pub fn menubar(
  context : UiContext,
  id~ : String,
  groups~ : Array[MenuGroup],
) -> @minimoon.Val[@minimoon.Node] {
  let initial : String? = None
  let (selected, emit) = @minimoon.create_variable(initial)
  stack(
    groups.map(group => {
      dropdown_menu_controlled(
        context,
        id=id + "-" + group.key,
        trigger_label=group.label,
        items=group.items,
        open=selected.map(value => value == Some(group.key)),
        on_change=emit.map(open => {
          _ => if open { Some(group.key) } else { None }
        }),
      )
    }),
  ).map(content => ui_container("menubar", [content]))
}
