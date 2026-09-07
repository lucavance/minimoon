///|
pub(all) struct ComboboxState {
  values : Array[String]
  query : String
  open : Bool
} derive(Eq, Debug)

///|
pub fn combobox_state(
  values? : Array[String] = [],
  query? : String = "",
  open? : Bool = false,
) -> ComboboxState {
  { values, query, open, }
}

///|
struct ComboboxScope {
  id : String
  state : ComboboxState
  options : Array[ChoiceOption]
  filtered_options : Array[ChoiceOption]
  disabled : Bool
  invalid : Bool
  required : Bool
  visible : Bool
  bounds : @headless.Bounds?
  update : @minimoon.Emit[ComboboxIntent]
  show : @minimoon.Cmd
}

///|
pub fn ComboboxScope::state(self : ComboboxScope) -> ComboboxState {
  self.state
}

///|
pub fn ComboboxScope::options(
  self : ComboboxScope,
  filtered? : Bool = true,
) -> Array[ChoiceOption] {
  if filtered {
    self.filtered_options
  } else {
    self.options
  }
}

///|
pub fn ComboboxScope::close(self : ComboboxScope) -> @minimoon.Cmd {
  (self.update)(SetOpen(false))
}

///|
pub fn ComboboxScope::open(self : ComboboxScope) -> @minimoon.Cmd {
  self.show
}

///|
pub fn ComboboxScope::choose(
  self : ComboboxScope,
  value : String,
) -> @minimoon.Cmd {
  (self.update)(Choose(value))
}

///|
pub fn ComboboxScope::remove(
  self : ComboboxScope,
  value : String,
) -> @minimoon.Cmd {
  (self.update)(Remove(value))
}

///|
pub fn combobox_input(
  scope : ComboboxScope,
  placeholder? : String = "Search",
) -> @minimoon.Node {
  @minimoon.input(
    id=scope.id + "-input",
    event_key=scope.id + "/query",
    value=scope.state.query,
    disabled=scope.disabled,
    on_input=@minimoon.Emit(query => {
      if scope.disabled {
        @minimoon.none
      } else {
        (scope.update)(SetQuery(query))
      }
    }),
    placeholder~,
    semantics=@minimoon.semantics(
      role=@minimoon.ComboboxRole,
      invalid=scope.invalid,
      required=scope.required,
      expanded=scope.state.open,
    ),
  )
}

///|
pub fn combobox_chips_input(
  scope : ComboboxScope,
  placeholder? : String = "Search",
) -> @minimoon.Node {
  combobox_input(scope, placeholder~)
}

///|
pub fn combobox_trigger(
  scope : ComboboxScope,
  label? : String = "Choose",
) -> @minimoon.Node {
  @minimoon.button(
    id=scope.id + "-trigger",
    event_key=scope.id + "/open",
    on_tap=scope.show,
    disabled=scope.disabled,
    semantics=@minimoon.semantics(
      expanded=scope.state.open,
      has_popup="listbox",
    ),
    label,
  )
}

///|
pub fn combobox_clear(
  scope : ComboboxScope,
  label? : String = "Clear",
) -> @minimoon.Node {
  @minimoon.button(
    event_key=scope.id + "/clear",
    disabled=scope.disabled,
    on_tap=if scope.disabled { @minimoon.none } else { (scope.update)(Clear) },
    label,
  )
}

///|
pub fn[C : @minimoon.IsChildren] combobox_chip(
  scope : ComboboxScope,
  value~ : String,
  children : C,
  removable? : Bool = true,
) -> @minimoon.Node {
  ui_container("combobox-chip", [
    @minimoon.fragment(children.to_nodes()),
    if removable {
      @minimoon.button(
        event_key=scope.id + "/remove/" + value,
        disabled=scope.disabled,
        on_tap=scope.remove(value),
        "Remove",
      )
    } else {
      @minimoon.nothing()
    },
  ])
}

///|
pub fn[C : @minimoon.IsChildren] combobox_item(
  scope : ComboboxScope,
  value~ : String,
  children : C,
  disabled? : Bool = false,
) -> @minimoon.Node {
  @minimoon.button_children(
    event_key=scope.id + "/option/" + value,
    disabled=disabled || scope.disabled,
    on_tap=if disabled { @minimoon.none } else { scope.choose(value) },
    semantics=@minimoon.semantics(
      role=@minimoon.OptionRole,
      selected=scope.state.values.contains(value),
    ),
    children,
  )
}

///|
pub fn combobox_value(
  scope : ComboboxScope,
  placeholder? : String = "",
) -> @minimoon.Node {
  let labels = scope.state.values.map(key => {
    select_value(scope.options, key, placeholder=key)
  })
  @minimoon.text(
    if labels.is_empty() {
      placeholder
    } else {
      labels.join(", ")
    },
  )
}

///|
pub fn combobox_option(
  value~ : String,
  label~ : String,
  disabled? : Bool = false,
) -> ChoiceOption {
  choice_option(key=value, label~, disabled~)
}
