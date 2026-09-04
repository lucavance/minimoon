///|
struct AccordionItemWithInput[Input] {
  key : String
  label : String
  panel : (Input) -> @minimoon.Node
  disabled : Bool
}

///|
pub fn[Input] accordion_item_with_input(
  key~ : String,
  label~ : String,
  panel~ : (Input) -> @minimoon.Node,
  disabled? : Bool = false,
) -> AccordionItemWithInput[Input] {
  guard key != "" else { abort("accordion item key must not be empty") }
  guard label != "" else { abort("accordion item label must not be empty") }
  { key, label, panel, disabled, }
}

///|
fn[Input] validate_accordion_items_with_input(
  items : Array[AccordionItemWithInput[Input]],
) -> Unit {
  let keys : Set[String] = Set([])
  for item in items {
    guard !keys.contains(item.key) else {
      abort("duplicate accordion item key: " + item.key)
    }
    keys.add(item.key)
  }
}

///|
fn[Input] enabled_accordion_key_with_input(
  items : Array[AccordionItemWithInput[Input]],
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
fn[Input] first_enabled_accordion_key_with_input(
  items : Array[AccordionItemWithInput[Input]],
) -> String? {
  for item in items {
    if !item.disabled {
      return Some(item.key)
    }
  }
  None
}

///|
fn[Input] normalized_single_key_with_input(
  items : Array[AccordionItemWithInput[Input]],
  requested : String?,
  collapsible : Bool,
) -> String? {
  match requested {
    Some(key) if enabled_accordion_key_with_input(items, key) => Some(key)
    _ =>
      if collapsible {
        None
      } else {
        first_enabled_accordion_key_with_input(items)
      }
  }
}

///|
fn[Input] accordion_root_with_input(
  id : String,
  items : Array[AccordionItemWithInput[Input]],
  input : Input,
  expanded : (String) -> Bool,
  toggle : (String, Bool) -> @minimoon.Cmd,
  label : String,
  disabled : Bool,
  orientation : Orientation,
  root_class : String,
  item_class : String,
  trigger_class : String,
  panel_class : String,
) -> @minimoon.Node {
  let entries : Array[@minimoon.KeyedNode] = []
  for item in items {
    let is_expanded = expanded(item.key)
    let trigger_id = id + "-" + item.key + "-trigger"
    let panel_id = id + "-" + item.key + "-panel"
    let is_disabled = disabled || item.disabled
    entries.push(
      @minimoon.keyed(
        item.key,
        @minimoon.div(class=item_class, data_section="accordion-item", [
          @minimoon.button(
            id=trigger_id,
            class=trigger_class,
            event_key=id + "/" + item.key + "/toggle",
            on_tap=if is_disabled {
              @minimoon.none
            } else {
              toggle(item.key, is_expanded)
            },
            disabled=is_disabled,
            semantics=@minimoon.semantics(
              role=@minimoon.ButtonRole,
              expanded=is_expanded,
              disabled=is_disabled,
              controls=panel_id,
            ),
            item.label,
          ),
          if is_expanded {
            @minimoon.div(
              id=panel_id,
              class=panel_class,
              data_section="accordion-panel",
              semantics=@minimoon.semantics(
                role=@minimoon.RegionRole,
                labelled_by=trigger_id,
              ),
              [(item.panel)(input)],
            )
          } else {
            @minimoon.nothing()
          },
        ]),
      ),
    )
  }
  @minimoon.div(
    id~,
    class=root_class,
    data_section="accordion",
    semantics=@minimoon.semantics(
      role=@minimoon.GroupRole,
      label~,
      disabled~,
      orientation=orientation.semantic_name(),
    ),
    [@minimoon.keyed_fragment(entries)],
  )
}

///|
pub fn[Input : Eq] accordion_single_controlled_with_input(
  id~ : String,
  items~ : Array[AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  open_key~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  label? : String = "",
  collapsible? : Bool = true,
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
  root_class? : String = "",
  item_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  guard id != "" else { abort("accordion id must not be empty") }
  validate_accordion_items_with_input(items)
  open_key.view2(input, (current, value) => {
    accordion_root_with_input(
      id,
      items,
      value,
      key => current == Some(key),
      (key, is_expanded) => {
        if is_expanded {
          if collapsible {
            on_change(None)
          } else {
            @minimoon.none
          }
        } else {
          on_change(Some(key))
        }
      },
      label,
      disabled,
      orientation,
      root_class,
      item_class,
      trigger_class,
      panel_class,
    )
  })
}

///|
pub fn[Input : Eq] accordion_single_with_input(
  id~ : String,
  items~ : Array[AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  initial_open_key? : String,
  label? : String = "",
  collapsible? : Bool = true,
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
  root_class? : String = "",
  item_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  validate_accordion_items_with_input(items)
  let (open_key, update_open_key) = @minimoon.create_variable(
    normalized_single_key_with_input(items, initial_open_key, collapsible),
  )
  accordion_single_controlled_with_input(
    id~,
    items~,
    input~,
    open_key~,
    on_change=update_open_key.map(value => _ => value),
    label~,
    collapsible~,
    disabled~,
    orientation~,
    root_class~,
    item_class~,
    trigger_class~,
    panel_class~,
  )
}

///|
fn[Input] canonical_open_keys_with_input(
  items : Array[AccordionItemWithInput[Input]],
  requested : Array[String],
) -> Array[String] {
  let result : Array[String] = []
  for item in items {
    if requested.contains(item.key) {
      result.push(item.key)
    }
  }
  result
}

///|
fn[Input] toggled_open_keys_with_input(
  items : Array[AccordionItemWithInput[Input]],
  current : Array[String],
  key : String,
) -> Array[String] {
  let requested = if current.contains(key) {
    current.filter(value => value != key)
  } else {
    [..current, key]
  }
  canonical_open_keys_with_input(items, requested)
}

///|
pub fn[Input : Eq] accordion_multiple_controlled_with_input(
  id~ : String,
  items~ : Array[AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  open_keys~ : @minimoon.Val[Array[String]],
  on_change~ : @minimoon.Emit[Array[String]],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
  root_class? : String = "",
  item_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  guard id != "" else { abort("accordion id must not be empty") }
  validate_accordion_items_with_input(items)
  open_keys.view2(input, (current, value) => {
    accordion_root_with_input(
      id,
      items,
      value,
      key => current.contains(key),
      (key, _) => on_change(toggled_open_keys_with_input(items, current, key)),
      label,
      disabled,
      orientation,
      root_class,
      item_class,
      trigger_class,
      panel_class,
    )
  })
}

///|
pub fn[Input : Eq] accordion_multiple_with_input(
  id~ : String,
  items~ : Array[AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  initial_open_keys? : Array[String] = [],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
  root_class? : String = "",
  item_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  validate_accordion_items_with_input(items)
  let (open_keys, update_open_keys) = @minimoon.create_variable(
    canonical_open_keys_with_input(items, initial_open_keys),
  )
  accordion_multiple_controlled_with_input(
    id~,
    items~,
    input~,
    open_keys~,
    on_change=update_open_keys.map(value => _ => value),
    label~,
    disabled~,
    orientation~,
    root_class~,
    item_class~,
    trigger_class~,
    panel_class~,
  )
}
