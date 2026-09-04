///|
struct MenuState {
  open : Bool
  submenu_path : Array[String]
  checked_keys : Array[String]
  radio_values : Array[(String, String)]
} derive(Eq)

///|
pub fn menu_state(
  open? : Bool = false,
  checked_keys? : Array[String] = [],
  radio_values? : Array[(String, String)] = [],
) -> MenuState {
  let checked : Array[String] = []
  for key in checked_keys {
    guard key != "" else { abort("menu checked key must not be empty") }
    if !checked.contains(key) {
      checked.push(key)
    }
  }
  let radios : Array[(String, String)] = []
  for entry in radio_values {
    let (group, value) = entry
    guard group != "" else { abort("menu radio group must not be empty") }
    guard value != "" else { abort("menu radio value must not be empty") }
    let next : Array[(String, String)] = []
    for current in radios {
      if current.0 != group {
        next.push(current)
      }
    }
    next.push((group, value))
    radios.clear()
    for current in next {
      radios.push(current)
    }
  }
  { open, submenu_path: [], checked_keys: checked, radio_values: radios, }
}

///|
pub fn MenuState::is_open(self : MenuState) -> Bool {
  self.open
}

///|
pub fn MenuState::with_open(self : MenuState, open : Bool) -> MenuState {
  { ..self, open, submenu_path: if open { self.submenu_path } else { [] }, }
}

///|
pub fn MenuState::is_checked(self : MenuState, key : String) -> Bool {
  self.checked_keys.contains(key)
}

///|
pub fn MenuState::radio_value(self : MenuState, group : String) -> String? {
  for entry in self.radio_values {
    if entry.0 == group {
      return Some(entry.1)
    }
  }
  None
}

///|
enum MenuEntry {
  Action(String, String, @minimoon.Cmd, Bool, Bool)
  Label(String, String)
  Separator(String)
  Checkbox(String, String, @minimoon.Cmd, Bool)
  Radio(String, String, String, String, @minimoon.Cmd, Bool)
  Submenu(String, String, Array[MenuEntry], Bool)
}

///|
pub fn menu_item(
  key~ : String,
  label~ : String,
  on_select? : @minimoon.Cmd = @minimoon.none,
  disabled? : Bool = false,
  close_on_select? : Bool = true,
) -> MenuEntry {
  guard key != "" else { abort("menu item key must not be empty") }
  guard label != "" else { abort("menu item label must not be empty") }
  Action(key, label, on_select, disabled, close_on_select)
}

///|
pub fn menu_label(key~ : String, label~ : String) -> MenuEntry {
  guard key != "" else { abort("menu label key must not be empty") }
  guard label != "" else { abort("menu label must not be empty") }
  Label(key, label)
}

///|
pub fn menu_separator(key~ : String) -> MenuEntry {
  guard key != "" else { abort("menu separator key must not be empty") }
  Separator(key)
}

///|
pub fn menu_checkbox_item(
  key~ : String,
  label~ : String,
  on_select? : @minimoon.Cmd = @minimoon.none,
  disabled? : Bool = false,
) -> MenuEntry {
  guard key != "" else { abort("menu checkbox key must not be empty") }
  guard label != "" else { abort("menu checkbox label must not be empty") }
  Checkbox(key, label, on_select, disabled)
}

///|
pub fn menu_radio_item(
  key~ : String,
  label~ : String,
  group~ : String,
  value~ : String,
  on_select? : @minimoon.Cmd = @minimoon.none,
  disabled? : Bool = false,
) -> MenuEntry {
  guard key != "" else { abort("menu radio key must not be empty") }
  guard label != "" else { abort("menu radio label must not be empty") }
  guard group != "" else { abort("menu radio group must not be empty") }
  guard value != "" else { abort("menu radio value must not be empty") }
  Radio(key, label, group, value, on_select, disabled)
}

///|
pub fn menu_submenu(
  key~ : String,
  label~ : String,
  items~ : Array[MenuEntry],
  disabled? : Bool = false,
) -> MenuEntry {
  guard key != "" else { abort("submenu key must not be empty") }
  guard label != "" else { abort("submenu label must not be empty") }
  Submenu(key, label, items, disabled)
}

///|
fn MenuEntry::key(self : MenuEntry) -> String {
  match self {
    Action(key, _, _, _, _)
    | Label(key, _)
    | Separator(key)
    | Checkbox(key, _, _, _)
    | Radio(key, _, _, _, _, _)
    | Submenu(key, _, _, _) => key
  }
}

///|
fn validate_menu_entries(
  entries : Array[MenuEntry],
  keys : Set[String],
) -> Unit {
  for entry in entries {
    let key = entry.key()
    guard !keys.contains(key) else { abort("duplicate menu entry key: " + key) }
    keys.add(key)
    match entry {
      Submenu(_, _, children, _) => validate_menu_entries(children, keys)
      _ => ()
    }
  }
}

///|
pub(all) enum MenuPlacement {
  BottomStart
  BottomEnd
  TopStart
  TopEnd
} derive(Eq, Debug)

///|
fn MenuPlacement::class_name(self : MenuPlacement) -> String {
  match self {
    BottomStart => "dropdown--bottom-start"
    BottomEnd => "dropdown--bottom-end"
    TopStart => "dropdown--top-start"
    TopEnd => "dropdown--top-end"
  }
}

///|
struct MenuSpec {
  id : String
  trigger_label : String
  items : Array[MenuEntry]
  placement : MenuPlacement
  disabled : Bool
  root_class : String
  trigger_class : String
  dismiss_class : String
  content_class : String
  item_class : String
  label_class : String
  separator_class : String
  submenu_trigger_class : String
  submenu_content_class : String
}

///|
pub fn dropdown_spec(
  id~ : String,
  trigger_label~ : String,
  items~ : Array[MenuEntry],
  placement? : MenuPlacement = BottomStart,
  disabled? : Bool = false,
  root_class? : String = "",
  trigger_class? : String = "",
  dismiss_class? : String = "",
  content_class? : String = "",
  item_class? : String = "",
  label_class? : String = "",
  separator_class? : String = "",
  submenu_trigger_class? : String = "",
  submenu_content_class? : String = "",
) -> MenuSpec {
  guard id != "" else { abort("dropdown id must not be empty") }
  guard trigger_label != "" else {
    abort("dropdown trigger label must not be empty")
  }
  validate_menu_entries(items, Set([]))
  {
    id,
    trigger_label,
    items,
    placement,
    disabled,
    root_class,
    trigger_class,
    dismiss_class,
    content_class,
    item_class,
    label_class,
    separator_class,
    submenu_trigger_class,
    submenu_content_class,
  }
}
