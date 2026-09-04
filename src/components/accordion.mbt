///|
struct AccordionItem {
  key : String
  label : String
  panel : @minimoon.Node
  disabled : Bool
}

///|
pub fn accordion_item(
  key~ : String,
  label~ : String,
  panel~ : @minimoon.Node,
  disabled? : Bool = false,
) -> AccordionItem {
  guard key != "" else { abort("accordion item key must not be empty") }
  guard label != "" else { abort("accordion item label must not be empty") }
  { key, label, panel, disabled, }
}

///|
fn validate_accordion_items(items : Array[AccordionItem]) -> Unit {
  let keys : Set[String] = Set([])
  for item in items {
    guard !keys.contains(item.key) else {
      abort("duplicate accordion item key: " + item.key)
    }
    keys.add(item.key)
  }
}

///|
fn enabled_accordion_key(items : Array[AccordionItem], key : String) -> Bool {
  for item in items {
    if item.key == key {
      return !item.disabled
    }
  }
  false
}

///|
fn first_enabled_accordion_key(items : Array[AccordionItem]) -> String? {
  for item in items {
    if !item.disabled {
      return Some(item.key)
    }
  }
  None
}

///|
fn normalized_single_key(
  items : Array[AccordionItem],
  requested : String?,
  collapsible : Bool,
) -> String? {
  match requested {
    Some(key) if enabled_accordion_key(items, key) => Some(key)
    _ => if collapsible { None } else { first_enabled_accordion_key(items) }
  }
}

///|
fn accordion_root(
  id : String,
  items : Array[AccordionItem],
  expanded : (String) -> Bool,
  toggle : (AccordionItem, Bool) -> @minimoon.Cmd,
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
              toggle(item, is_expanded)
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
              [item.panel],
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
pub fn accordion_single_controlled(
  id~ : String,
  items~ : Array[AccordionItem],
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
  validate_accordion_items(items)
  open_key.map(current => {
    accordion_root(
      id,
      items,
      key => current == Some(key),
      (item, is_expanded) => {
        if is_expanded {
          if collapsible {
            on_change(None)
          } else {
            @minimoon.none
          }
        } else {
          on_change(Some(item.key))
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
pub fn accordion_single(
  id~ : String,
  items~ : Array[AccordionItem],
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
  validate_accordion_items(items)
  let (open_key, update_open_key) = @minimoon.create_variable(
    normalized_single_key(items, initial_open_key, collapsible),
  )
  accordion_single_controlled(
    id~,
    items~,
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
fn canonical_open_keys(
  items : Array[AccordionItem],
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
fn toggled_open_keys(
  items : Array[AccordionItem],
  current : Array[String],
  key : String,
) -> Array[String] {
  let requested = if current.contains(key) {
    current.filter(value => value != key)
  } else {
    [..current, key]
  }
  canonical_open_keys(items, requested)
}

///|
pub fn accordion_multiple_controlled(
  id~ : String,
  items~ : Array[AccordionItem],
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
  validate_accordion_items(items)
  open_keys.map(current => {
    accordion_root(
      id,
      items,
      key => current.contains(key),
      (item, _) => on_change(toggled_open_keys(items, current, item.key)),
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
pub fn accordion_multiple(
  id~ : String,
  items~ : Array[AccordionItem],
  initial_open_keys? : Array[String] = [],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
  root_class? : String = "",
  item_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  validate_accordion_items(items)
  let (open_keys, update_open_keys) = @minimoon.create_variable(
    canonical_open_keys(items, initial_open_keys),
  )
  accordion_multiple_controlled(
    id~,
    items~,
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
