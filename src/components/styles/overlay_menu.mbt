///|
pub fn dialog_spec(
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : (@minimoon.Cmd) -> @minimoon.Node,
  description? : String = "",
  close_label? : String = "Close",
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
) -> @headless.DialogSpec {
  @headless.dialog_spec(
    id~,
    title~,
    trigger_label~,
    content~,
    description~,
    close_label~,
    disabled~,
    close_on_overlay~,
    root_class="mm-dialog",
    trigger_class="mm-dialog__trigger",
    overlay_class="mm-overlay",
    surface_class="mm-dialog__surface",
    title_class="mm-dialog__title",
    description_class="mm-dialog__description",
    close_class="mm-dialog__close",
  )
}

///|
pub fn dialog(
  spec : @headless.DialogSpec,
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.dialog(spec, initially_open~)
}

///|
pub fn dialog_controlled(
  spec : @headless.DialogSpec,
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.dialog_controlled(spec, open~, on_change~)
}

///|
pub(all) enum SheetSide {
  Top
  Right
  Bottom
  Left
} derive(Eq, Debug)

///|
fn SheetSide::headless(self : SheetSide) -> @headless.SheetSide {
  match self {
    Top => @headless.Top
    Right => @headless.Right
    Bottom => @headless.Bottom
    Left => @headless.Left
  }
}

///|
pub fn sheet_spec(
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : (@minimoon.Cmd) -> @minimoon.Node,
  side? : SheetSide = Right,
  description? : String = "",
  close_label? : String = "Close",
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
) -> @headless.SheetSpec {
  @headless.sheet_spec(
    id~,
    title~,
    trigger_label~,
    content~,
    side=side.headless(),
    description~,
    close_label~,
    disabled~,
    close_on_overlay~,
    root_class="mm-sheet",
    trigger_class="mm-sheet__trigger",
    overlay_class="mm-overlay",
    surface_class="mm-sheet__surface",
    title_class="mm-sheet__title",
    description_class="mm-sheet__description",
    close_class="mm-sheet__close",
  )
}

///|
pub fn sheet(
  spec : @headless.SheetSpec,
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.sheet(spec, initially_open~)
}

///|
pub fn sheet_controlled(
  spec : @headless.SheetSpec,
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.sheet_controlled(spec, open~, on_change~)
}

///|
pub fn[Input] dialog_spec_with_input(
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : (@minimoon.Cmd, Input) -> @minimoon.Node,
  description? : String = "",
  close_label? : String = "Close",
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
) -> @headless.DialogSpecWithInput[Input] {
  @headless.dialog_spec_with_input(
    id~,
    title~,
    trigger_label~,
    content~,
    description~,
    close_label~,
    disabled~,
    close_on_overlay~,
    root_class="mm-dialog",
    trigger_class="mm-dialog__trigger",
    overlay_class="mm-overlay",
    surface_class="mm-dialog__surface",
    title_class="mm-dialog__title",
    description_class="mm-dialog__description",
    close_class="mm-dialog__close",
  )
}

///|
pub fn[Input : Eq] dialog_with_input(
  spec : @headless.DialogSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.dialog_with_input(spec, input~, initially_open~)
}

///|
pub fn[Input : Eq] dialog_controlled_with_input(
  spec : @headless.DialogSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.dialog_controlled_with_input(spec, input~, open~, on_change~)
}

///|
pub fn[Input] sheet_spec_with_input(
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : (@minimoon.Cmd, Input) -> @minimoon.Node,
  side? : SheetSide = Right,
  description? : String = "",
  close_label? : String = "Close",
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
) -> @headless.SheetSpecWithInput[Input] {
  @headless.sheet_spec_with_input(
    id~,
    title~,
    trigger_label~,
    content~,
    side=side.headless(),
    description~,
    close_label~,
    disabled~,
    close_on_overlay~,
    root_class="mm-sheet",
    trigger_class="mm-sheet__trigger",
    overlay_class="mm-overlay",
    surface_class="mm-sheet__surface",
    title_class="mm-sheet__title",
    description_class="mm-sheet__description",
    close_class="mm-sheet__close",
  )
}

///|
pub fn[Input : Eq] sheet_with_input(
  spec : @headless.SheetSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.sheet_with_input(spec, input~, initially_open~)
}

///|
pub fn[Input : Eq] sheet_controlled_with_input(
  spec : @headless.SheetSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.sheet_controlled_with_input(spec, input~, open~, on_change~)
}

///|
pub fn menu_state(
  open? : Bool = false,
  checked_keys? : Array[String] = [],
  radio_values? : Array[(String, String)] = [],
) -> @headless.MenuState {
  @headless.menu_state(open~, checked_keys~, radio_values~)
}

///|
pub fn menu_item(
  key~ : String,
  label~ : String,
  on_select? : @minimoon.Cmd = @minimoon.none,
  disabled? : Bool = false,
  close_on_select? : Bool = true,
) -> @headless.MenuEntry {
  @headless.menu_item(key~, label~, on_select~, disabled~, close_on_select~)
}

///|
pub fn menu_label(key~ : String, label~ : String) -> @headless.MenuEntry {
  @headless.menu_label(key~, label~)
}

///|
pub fn menu_separator(key~ : String) -> @headless.MenuEntry {
  @headless.menu_separator(key~)
}

///|
pub fn menu_checkbox_item(
  key~ : String,
  label~ : String,
  on_select? : @minimoon.Cmd = @minimoon.none,
  disabled? : Bool = false,
) -> @headless.MenuEntry {
  @headless.menu_checkbox_item(key~, label~, on_select~, disabled~)
}

///|
pub fn menu_radio_item(
  key~ : String,
  label~ : String,
  group~ : String,
  value~ : String,
  on_select? : @minimoon.Cmd = @minimoon.none,
  disabled? : Bool = false,
) -> @headless.MenuEntry {
  @headless.menu_radio_item(key~, label~, group~, value~, on_select~, disabled~)
}

///|
pub fn menu_submenu(
  key~ : String,
  label~ : String,
  items~ : Array[@headless.MenuEntry],
  disabled? : Bool = false,
) -> @headless.MenuEntry {
  @headless.menu_submenu(key~, label~, items~, disabled~)
}

///|
pub(all) enum MenuPlacement {
  BottomStart
  BottomEnd
  TopStart
  TopEnd
} derive(Eq, Debug)

///|
fn MenuPlacement::headless(self : MenuPlacement) -> @headless.MenuPlacement {
  match self {
    BottomStart => @headless.BottomStart
    BottomEnd => @headless.BottomEnd
    TopStart => @headless.TopStart
    TopEnd => @headless.TopEnd
  }
}

///|
pub fn dropdown_spec(
  id~ : String,
  trigger_label~ : String,
  items~ : Array[@headless.MenuEntry],
  placement? : MenuPlacement = BottomStart,
  disabled? : Bool = false,
) -> @headless.MenuSpec {
  @headless.dropdown_spec(
    id~,
    trigger_label~,
    items~,
    placement=placement.headless(),
    disabled~,
    root_class="mm-dropdown",
    trigger_class="mm-dropdown__trigger",
    dismiss_class="mm-dismiss",
    content_class="mm-dropdown__content",
    item_class="mm-dropdown__item",
    label_class="mm-dropdown__label",
    separator_class="mm-dropdown__separator",
    submenu_trigger_class="mm-dropdown__submenu-trigger",
    submenu_content_class="mm-dropdown__submenu-content",
  )
}

///|
pub fn dropdown(
  spec : @headless.MenuSpec,
  initial_state? : @headless.MenuState = @headless.menu_state(),
) -> @minimoon.Val[@minimoon.Node] {
  @headless.dropdown(spec, initial_state~)
}

///|
pub fn dropdown_controlled(
  spec : @headless.MenuSpec,
  state~ : @minimoon.Val[@headless.MenuState],
  on_change~ : @minimoon.Emit[@headless.MenuState],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.dropdown_controlled(spec, state~, on_change~)
}
