///|
pub(all) enum Orientation {
  Horizontal
  Vertical
} derive(Eq, Debug)

///|
fn Orientation::headless(self : Orientation) -> @headless.Orientation {
  match self {
    Horizontal => @headless.Horizontal
    Vertical => @headless.Vertical
  }
}

///|
pub fn disclosure_spec(
  id~ : String,
  label~ : String,
  panel~ : @minimoon.Node,
) -> @headless.DisclosureSpec {
  @headless.disclosure_spec(
    id~,
    label~,
    panel~,
    root_class="mm-disclosure",
    trigger_class="mm-disclosure__trigger",
    panel_class="mm-disclosure__panel",
  )
}

///|
pub fn disclosure(
  spec : @headless.DisclosureSpec,
  initially_expanded? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.disclosure(spec, initially_expanded~)
}

///|
pub fn disclosure_controlled(
  spec : @headless.DisclosureSpec,
  expanded~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.disclosure_controlled(spec, expanded~, on_change~)
}

///|
pub fn accordion_item(
  key~ : String,
  label~ : String,
  panel~ : @minimoon.Node,
  disabled? : Bool = false,
) -> @headless.AccordionItem {
  @headless.accordion_item(key~, label~, panel~, disabled~)
}

///|
pub fn accordion_single(
  id~ : String,
  items~ : Array[@headless.AccordionItem],
  initial_open_key? : String,
  label? : String = "",
  collapsible? : Bool = true,
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_single(
    id~,
    items~,
    initial_open_key?,
    label~,
    collapsible~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn accordion_single_controlled(
  id~ : String,
  items~ : Array[@headless.AccordionItem],
  open_key~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  label? : String = "",
  collapsible? : Bool = true,
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_single_controlled(
    id~,
    items~,
    open_key~,
    on_change~,
    label~,
    collapsible~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn accordion_multiple(
  id~ : String,
  items~ : Array[@headless.AccordionItem],
  initial_open_keys? : Array[String] = [],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_multiple(
    id~,
    items~,
    initial_open_keys~,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn accordion_multiple_controlled(
  id~ : String,
  items~ : Array[@headless.AccordionItem],
  open_keys~ : @minimoon.Val[Array[String]],
  on_change~ : @minimoon.Emit[Array[String]],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_multiple_controlled(
    id~,
    items~,
    open_keys~,
    on_change~,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn tab_item(
  key~ : String,
  label~ : String,
  panel~ : @minimoon.Node,
  disabled? : Bool = false,
) -> @headless.TabItem {
  @headless.tab_item(key~, label~, panel~, disabled~)
}

///|
pub fn tabs(
  id~ : String,
  items~ : Array[@headless.TabItem],
  initial_selected_key? : String,
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.tabs(
    id~,
    items~,
    initial_selected_key?,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-tabs",
    list_class="mm-tabs__list",
    tab_class_name="mm-tabs__tab",
    active_tab_class="mm-tabs__tab--active",
    inactive_tab_class="mm-tabs__tab--inactive",
    panel_class="mm-tabs__panel",
  )
}

///|
pub fn tabs_controlled(
  id~ : String,
  items~ : Array[@headless.TabItem],
  selected_key~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.tabs_controlled(
    id~,
    items~,
    selected_key~,
    on_change~,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-tabs",
    list_class="mm-tabs__list",
    tab_class_name="mm-tabs__tab",
    active_tab_class="mm-tabs__tab--active",
    inactive_tab_class="mm-tabs__tab--inactive",
    panel_class="mm-tabs__panel",
  )
}

///|
pub fn[Input] disclosure_spec_with_input(
  id~ : String,
  label~ : String,
  panel~ : (Input) -> @minimoon.Node,
) -> @headless.DisclosureSpecWithInput[Input] {
  @headless.disclosure_spec_with_input(
    id~,
    label~,
    panel~,
    root_class="mm-disclosure",
    trigger_class="mm-disclosure__trigger",
    panel_class="mm-disclosure__panel",
  )
}

///|
pub fn[Input : Eq] disclosure_with_input(
  spec : @headless.DisclosureSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  initially_expanded? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.disclosure_with_input(spec, input~, initially_expanded~)
}

///|
pub fn[Input : Eq] disclosure_controlled_with_input(
  spec : @headless.DisclosureSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  expanded~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  @headless.disclosure_controlled_with_input(
    spec,
    input~,
    expanded~,
    on_change~,
  )
}

///|
pub fn[Input] accordion_item_with_input(
  key~ : String,
  label~ : String,
  panel~ : (Input) -> @minimoon.Node,
  disabled? : Bool = false,
) -> @headless.AccordionItemWithInput[Input] {
  @headless.accordion_item_with_input(key~, label~, panel~, disabled~)
}

///|
pub fn[Input : Eq] accordion_single_with_input(
  id~ : String,
  items~ : Array[@headless.AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  initial_open_key? : String,
  label? : String = "",
  collapsible? : Bool = true,
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_single_with_input(
    id~,
    items~,
    input~,
    initial_open_key?,
    label~,
    collapsible~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn[Input : Eq] accordion_single_controlled_with_input(
  id~ : String,
  items~ : Array[@headless.AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  open_key~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  label? : String = "",
  collapsible? : Bool = true,
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_single_controlled_with_input(
    id~,
    items~,
    input~,
    open_key~,
    on_change~,
    label~,
    collapsible~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn[Input : Eq] accordion_multiple_with_input(
  id~ : String,
  items~ : Array[@headless.AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  initial_open_keys? : Array[String] = [],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_multiple_with_input(
    id~,
    items~,
    input~,
    initial_open_keys~,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn[Input : Eq] accordion_multiple_controlled_with_input(
  id~ : String,
  items~ : Array[@headless.AccordionItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  open_keys~ : @minimoon.Val[Array[String]],
  on_change~ : @minimoon.Emit[Array[String]],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.accordion_multiple_controlled_with_input(
    id~,
    items~,
    input~,
    open_keys~,
    on_change~,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-accordion",
    item_class="mm-accordion__item",
    trigger_class="mm-accordion__trigger",
    panel_class="mm-accordion__panel",
  )
}

///|
pub fn[Input] tab_item_with_input(
  key~ : String,
  label~ : String,
  panel~ : (Input) -> @minimoon.Node,
  disabled? : Bool = false,
) -> @headless.TabItemWithInput[Input] {
  @headless.tab_item_with_input(key~, label~, panel~, disabled~)
}

///|
pub fn[Input : Eq] tabs_with_input(
  id~ : String,
  items~ : Array[@headless.TabItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  initial_selected_key? : String,
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.tabs_with_input(
    id~,
    items~,
    input~,
    initial_selected_key?,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-tabs",
    list_class="mm-tabs__list",
    tab_class_name="mm-tabs__tab",
    active_tab_class="mm-tabs__tab--active",
    inactive_tab_class="mm-tabs__tab--inactive",
    panel_class="mm-tabs__panel",
  )
}

///|
pub fn[Input : Eq] tabs_controlled_with_input(
  id~ : String,
  items~ : Array[@headless.TabItemWithInput[Input]],
  input~ : @minimoon.Val[Input],
  selected_key~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  label? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
) -> @minimoon.Val[@minimoon.Node] {
  @headless.tabs_controlled_with_input(
    id~,
    items~,
    input~,
    selected_key~,
    on_change~,
    label~,
    disabled~,
    orientation=orientation.headless(),
    root_class="mm-tabs",
    list_class="mm-tabs__list",
    tab_class_name="mm-tabs__tab",
    active_tab_class="mm-tabs__tab--active",
    inactive_tab_class="mm-tabs__tab--inactive",
    panel_class="mm-tabs__panel",
  )
}
