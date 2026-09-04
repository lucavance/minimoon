///|
struct TabItemWithInput[Input] {
  key : String
  label : String
  panel : (Input) -> @minimoon.Node
  disabled : Bool
}

///|
pub fn[Input] tab_item_with_input(
  key~ : String,
  label~ : String,
  panel~ : (Input) -> @minimoon.Node,
  disabled? : Bool = false,
) -> TabItemWithInput[Input] {
  guard key != "" else { abort("tab key must not be empty") }
  guard label != "" else { abort("tab label must not be empty") }
  { key, label, panel, disabled, }
}

///|
fn[Input] validate_tab_items_with_input(
  items : Array[TabItemWithInput[Input]],
) -> Unit {
  let keys : Set[String] = Set([])
  for item in items {
    guard !keys.contains(item.key) else {
      abort("duplicate tab key: " + item.key)
    }
    keys.add(item.key)
  }
}

///|
fn[Input] enabled_tab_key_with_input(
  items : Array[TabItemWithInput[Input]],
  key : String,
) -> Bool {
  for item in items {
    if item.key == key {
      return !item.disabled
    }
  }
  false
}

///|
fn[Input] first_enabled_tab_key_with_input(
  items : Array[TabItemWithInput[Input]],
) -> String? {
  for item in items {
    if !item.disabled {
      return Some(item.key)
    }
  }
  None
}

///|
fn[Input] normalized_tab_key_with_input(
  items : Array[TabItemWithInput[Input]],
  requested : String?,
) -> String? {
  match requested {
    Some(key) if enabled_tab_key_with_input(items, key) => Some(key)
    _ => first_enabled_tab_key_with_input(items)
  }
}

///|
pub fn[Input : Eq] tabs_controlled_with_input(
  id~ : String,
  items~ : Array[TabItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  selected_key~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
  root_class? : String = "",
  list_class? : String = "",
  tab_class_name? : String = "",
  active_tab_class? : String = "",
  inactive_tab_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  guard id != "" else { abort("tabs id must not be empty") }
  validate_tab_items_with_input(items)
  selected_key.view2(input, (current, value) => {
    let selected_key = match current {
      Some(key) if enabled_tab_key_with_input(items, key) => Some(key)
      _ => None
    }
    let tabs : Array[@minimoon.KeyedNode] = []
    let panels : Array[@minimoon.KeyedNode] = []
    for item in items {
      let selected = selected_key == Some(item.key)
      let tab_id = id + "-" + item.key + "-tab"
      let panel_id = id + "-" + item.key + "-panel"
      let is_disabled = disabled || item.disabled
      tabs.push(
        @minimoon.keyed(
          item.key,
          @minimoon.button(
            id=tab_id,
            class=tab_class(
              selected, tab_class_name, active_tab_class, inactive_tab_class,
            ),
            event_key=id + "/" + item.key + "/select",
            on_tap=if is_disabled || selected {
              @minimoon.none
            } else {
              on_change(Some(item.key))
            },
            disabled=is_disabled,
            semantics=@minimoon.semantics(
              role=@minimoon.TabRole,
              selected~,
              disabled=is_disabled,
              controls=panel_id,
            ),
            item.label,
          ),
        ),
      )
      if selected {
        panels.push(
          @minimoon.keyed(
            item.key,
            @minimoon.div(
              id=panel_id,
              class=panel_class,
              data_section="tabs-panel",
              semantics=@minimoon.semantics(
                role=@minimoon.TabPanelRole,
                labelled_by=tab_id,
              ),
              [(item.panel)(value)],
            ),
          ),
        )
      }
    }
    @minimoon.div(id~, class=root_class, data_section="tabs", [
      @minimoon.div(
        class=list_class,
        data_section="tabs-list",
        semantics=@minimoon.semantics(
          role=@minimoon.TabListRole,
          label~,
          disabled~,
          orientation=orientation.semantic_name(),
        ),
        [@minimoon.keyed_fragment(tabs)],
      ),
      @minimoon.keyed_fragment(panels),
    ])
  })
}

///|
pub fn[Input : Eq] tabs_with_input(
  id~ : String,
  items~ : Array[TabItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  initial_selected_key? : String,
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
  root_class? : String = "",
  list_class? : String = "",
  tab_class_name? : String = "",
  active_tab_class? : String = "",
  inactive_tab_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  validate_tab_items_with_input(items)
  let (selected, update_selected) = @minimoon.create_variable(
    normalized_tab_key_with_input(items, initial_selected_key),
  )
  tabs_controlled_with_input(
    id~,
    items~,
    input~,
    selected_key=selected,
    on_change=update_selected.map(value => _ => value),
    label~,
    disabled~,
    orientation~,
    root_class~,
    list_class~,
    tab_class_name~,
    active_tab_class~,
    inactive_tab_class~,
    panel_class~,
  )
}
