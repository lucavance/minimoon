///|
pub fn[C : @minimoon.IsChildren] combobox_chips(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("combobox-chips", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] combobox_collection(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("combobox-collection", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] combobox_group(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("combobox-group", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] combobox_label(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("combobox-label", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] combobox_list(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("combobox-list", id~, class~, style~, children.to_nodes())
}

///|
pub fn combobox_separator() -> @minimoon.Node {
  ui_container(
    "combobox-separator",
    semantics=@minimoon.semantics(role=@minimoon.SeparatorRole),
    [],
  )
}

///|
pub fn[C : @minimoon.IsChildren] command_list(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("command-list", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] command_shortcut(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("command-shortcut", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] command_empty(
  children : C,
  visible~ : Bool,
) -> @minimoon.Node {
  if visible {
    ui_container("command-empty", children.to_nodes())
  } else {
    @minimoon.nothing()
  }
}

///|
pub fn[C : @minimoon.IsChildren] command_group(
  children : C,
  heading? : String = "",
) -> @minimoon.Node {
  ui_container("command-group", [
    @minimoon.text(heading),
    @minimoon.fragment(children.to_nodes()),
  ])
}

///|
pub fn command_separator() -> @minimoon.Node {
  ui_container(
    "command-separator",
    semantics=@minimoon.semantics(role=@minimoon.SeparatorRole),
    [],
  )
}

///|
pub fn[C : @minimoon.IsChildren] command_dialog_trigger(
  scope : CommandScope,
  children : C,
  disabled? : Bool = false,
) -> @minimoon.Node {
  @minimoon.button_children(
    event_key=scope.id + "/open",
    disabled~,
    on_tap=if disabled { @minimoon.none } else { scope.show },
    children,
  )
}

///|
pub fn CommandScope::matches(
  self : CommandScope,
  value : String,
  keywords? : Array[String] = [],
) -> Bool {
  !self.should_filter || (self.filter)(value, self.query, keywords)
}
