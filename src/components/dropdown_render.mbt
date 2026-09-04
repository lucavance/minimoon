///|
fn state_with_checked(state : MenuState, key : String) -> MenuState {
  let next : Array[String] = []
  for current in state.checked_keys {
    if current != key {
      next.push(current)
    }
  }
  if !state.checked_keys.contains(key) {
    next.push(key)
  }
  { ..state, checked_keys: next, }
}

///|
fn state_with_radio(
  state : MenuState,
  group : String,
  value : String,
) -> MenuState {
  let next : Array[(String, String)] = []
  for entry in state.radio_values {
    if entry.0 != group {
      next.push(entry)
    }
  }
  next.push((group, value))
  { ..state, radio_values: next, }
}

///|
fn path_with(path : Array[String], key : String) -> Array[String] {
  [..path, key]
}

///|
fn path_is_open(current : Array[String], path : Array[String]) -> Bool {
  if current.length() < path.length() {
    return false
  }
  for index = 0; index < path.length(); index = index + 1 {
    if current[index] != path[index] {
      return false
    }
  }
  true
}

///|
fn command_with_state(
  next : MenuState,
  on_change : @minimoon.Emit[MenuState],
  command : @minimoon.Cmd,
) -> @minimoon.Cmd {
  @minimoon.batch([on_change(next), command])
}

///|
fn render_menu_entries(
  spec : MenuSpec,
  entries : Array[MenuEntry],
  state : MenuState,
  on_change : @minimoon.Emit[MenuState],
  parent_path : Array[String],
) -> @minimoon.Node {
  let nodes : Array[@minimoon.KeyedNode] = []
  for entry in entries {
    let key = entry.key()
    let event_prefix = spec.id + "/item/" + key
    let node = match entry {
      Action(_, label, command, disabled, close_on_select) => {
        let next = if close_on_select { state.with_open(false) } else { state }
        @minimoon.button(
          on_tap=if disabled {
            @minimoon.none
          } else {
            command_with_state(next, on_change, command)
          },
          event_key=event_prefix,
          class=spec.item_class,
          disabled~,
          semantics=@minimoon.semantics(role=@minimoon.MenuItemRole, disabled~),
          label,
        )
      }
      Label(_, label) =>
        @minimoon.div(class=spec.label_class, data_section="menu-label", label)
      Separator(_) =>
        @minimoon.div(
          class=spec.separator_class,
          data_section="menu-separator",
          semantics=@minimoon.semantics(
            role=@minimoon.SeparatorRole,
            orientation="horizontal",
          ),
          @minimoon.nothing(),
        )
      Checkbox(_, label, command, disabled) => {
        let checked = state.is_checked(key)
        let next = state_with_checked(state, key)
        @minimoon.button(
          on_tap=if disabled {
            @minimoon.none
          } else {
            command_with_state(next, on_change, command)
          },
          event_key=event_prefix,
          class=spec.item_class,
          disabled~,
          semantics=@minimoon.semantics(
            role=@minimoon.MenuItemCheckboxRole,
            checked~,
            disabled~,
          ),
          label,
        )
      }
      Radio(_, label, group, value, command, disabled) => {
        let checked = state.radio_value(group) == Some(value)
        let next = state_with_radio(state, group, value)
        @minimoon.button(
          on_tap=if disabled || checked {
            @minimoon.none
          } else {
            command_with_state(next, on_change, command)
          },
          event_key=event_prefix,
          class=spec.item_class,
          disabled~,
          semantics=@minimoon.semantics(
            role=@minimoon.MenuItemRadioRole,
            checked~,
            disabled~,
          ),
          label,
        )
      }
      Submenu(_, label, children, disabled) => {
        let child_path = path_with(parent_path, key)
        let submenu_open = path_is_open(state.submenu_path, child_path)
        let trigger_id = spec.id + "-" + key + "-trigger"
        let content_id = spec.id + "-" + key + "-menu"
        let next_path = if submenu_open { parent_path } else { child_path }
        @minimoon.div(data_section="submenu", [
          @minimoon.button(
            id=trigger_id,
            on_tap=if disabled {
              @minimoon.none
            } else {
              on_change({ ..state, submenu_path: next_path, })
            },
            event_key=event_prefix + "/submenu",
            class=spec.submenu_trigger_class,
            disabled~,
            semantics=@minimoon.semantics(
              role=@minimoon.MenuItemRole,
              expanded=submenu_open,
              disabled~,
              controls=content_id,
              has_popup="menu",
            ),
            label,
          ),
          if submenu_open {
            @minimoon.div(
              id=content_id,
              class=spec.submenu_content_class,
              data_section="submenu-content",
              semantics=@minimoon.semantics(
                role=@minimoon.MenuRole,
                labelled_by=trigger_id,
                orientation="vertical",
              ),
              [
                render_menu_entries(
                  spec, children, state, on_change, child_path,
                ),
              ],
            )
          } else {
            @minimoon.nothing()
          },
        ])
      }
    }
    nodes.push(@minimoon.keyed(key, node))
  }
  @minimoon.keyed_fragment(nodes)
}

///|
pub fn dropdown_controlled(
  spec : MenuSpec,
  state~ : @minimoon.Val[MenuState],
  on_change~ : @minimoon.Emit[MenuState],
) -> @minimoon.Val[@minimoon.Node] {
  state.map(current => {
    let trigger_id = spec.id + "-trigger"
    let content_id = spec.id + "-menu"
    @minimoon.div(id=spec.id, class=spec.root_class, data_section="dropdown", [
      @minimoon.button(
        id=trigger_id,
        on_tap=if spec.disabled {
          @minimoon.none
        } else {
          on_change(current.with_open(!current.open))
        },
        event_key=spec.id + "/toggle",
        class=spec.trigger_class,
        disabled=spec.disabled,
        semantics=@minimoon.semantics(
          role=@minimoon.ButtonRole,
          expanded=current.open,
          disabled=spec.disabled,
          controls=content_id,
          has_popup="menu",
        ),
        spec.trigger_label,
      ),
      if current.open {
        @minimoon.fragment([
          @minimoon.tap_view(
            on_tap=on_change(current.with_open(false)),
            event_key=spec.id + "/dismiss",
            class=spec.dismiss_class,
            data_section="dropdown-dismiss",
            @minimoon.nothing(),
          ),
          @minimoon.div(
            id=content_id,
            class=joined_class(spec.content_class, spec.placement.class_name()),
            data_section="dropdown-content",
            semantics=@minimoon.semantics(
              role=@minimoon.MenuRole,
              labelled_by=trigger_id,
              orientation="vertical",
            ),
            [render_menu_entries(spec, spec.items, current, on_change, [])],
          ),
        ])
      } else {
        @minimoon.nothing()
      },
    ])
  })
}

///|
pub fn dropdown(
  spec : MenuSpec,
  initial_state? : MenuState = menu_state(),
) -> @minimoon.Val[@minimoon.Node] {
  let (state, update_state) = @minimoon.create_variable(initial_state)
  dropdown_controlled(
    spec,
    state~,
    on_change=update_state.map(value => _ => value),
  )
}
