///|
pub fn checkbox_controlled(
  name? : String = "",
  id~ : String,
  checked~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  label? : String = "",
  disabled? : Bool = false,
  indeterminate? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  checked.map(value => {
    @minimoon.checkbox_group(
      name~,
      id~,
      class="mmui-checkbox" +
        (if indeterminate { " mmui-indeterminate" } else { "" }) +
        (if invalid { " mmui-invalid" } else { "" }),
      event_key=id + "/change",
      on_change=@minimoon.Emit(values => {
        if disabled || read_only {
          @minimoon.none
        } else {
          on_change(values.contains(id))
        }
      }),
      [
        @minimoon.checkbox(
          value=id,
          checked=value && !indeterminate,
          disabled=disabled || read_only,
          id=id + "-control",
          [@minimoon.text(label)],
        ),
        if indeterminate {
          @minimoon.span(class="mmui-checkbox-mixed", "−")
        } else {
          @minimoon.nothing()
        },
      ],
    )
  })
}

///|
pub fn checkbox(
  name? : String = "",
  id~ : String,
  initially_checked? : Bool = false,
  label? : String = "",
  disabled? : Bool = false,
  indeterminate? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  checkbox_state(
    name~,
    id~,
    initial=if indeterminate {
      Indeterminate
    } else if initially_checked {
      Checked
    } else {
      Unchecked
    },
    label~,
    disabled~,
    read_only~,
    invalid~,
  )
}

///|
pub fn switch_controlled(
  name? : String = "",
  id~ : String,
  checked~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  label? : String = "",
  disabled? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
  size? : Size = Medium,
) -> @minimoon.Val[@minimoon.Node] {
  checked.map(value => {
    @minimoon.switch(
      name~,
      id~,
      class="mmui-switch " +
        size_class(size) +
        (if read_only { " mmui-readonly" } else { "" }) +
        (if invalid { " mmui-invalid" } else { "" }),
      event_key=id + "/change",
      checked=value,
      disabled=disabled || read_only,
      on_change=if disabled || read_only {
        @minimoon.Emit(_ => @minimoon.none)
      } else {
        on_change
      },
      semantics=@minimoon.semantics(
        role=@minimoon.SwitchRole,
        label~,
        checked=value,
        disabled~,
        invalid~,
      ),
    )
  })
}

///|
pub fn switch(
  name? : String = "",
  id~ : String,
  initially_checked? : Bool = false,
  label? : String = "",
  disabled? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
  size? : Size = Medium,
) -> @minimoon.Val[@minimoon.Node] {
  let (checked, update) = @minimoon.create_variable(initially_checked)
  switch_controlled(
    name~,
    id~,
    checked~,
    on_change=update.map(value => _ => value),
    label~,
    disabled~,
    read_only~,
    invalid~,
    size~,
  )
}

///|
pub fn radio_group_controlled(
  name? : String = "",
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  let change = form_dispatch(options, (options, key : String) => {
    if !disabled && options.any(option => option.key == key && !option.disabled) {
      on_change(key)
    } else {
      @minimoon.none
    }
  })
  @minimoon.Val::map2(options, value, (options, selected) => {
    validate_choices(options)
    @minimoon.radio_group(
      name~,
      id~,
      class="mmui-radio-group " + orientation_class(orientation),
      event_key=id + "/change",
      on_change=change,
      options.map(option => {
        @minimoon.radio(
          value=option.key,
          checked=option.key == selected,
          disabled=disabled || option.disabled,
          id=id + "-" + option.key,
          class="mmui-radio-group-item",
          option.label,
        )
      }),
    )
  })
}

///|
pub fn radio_group(
  name? : String = "",
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  initial_value? : String = "",
  disabled? : Bool = false,
  orientation? : Orientation = Vertical,
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  radio_group_controlled(
    name~,
    id~,
    options~,
    value~,
    on_change=update.map(value => _ => value),
    disabled~,
    orientation~,
  )
}

///|
pub fn native_select_controlled(
  name? : String = "",
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  placeholder? : String = "Select…",
  disabled? : Bool = false,
  invalid? : Bool = false,
  required? : Bool = false,
  size? : Size = Medium,
) -> @minimoon.Val[@minimoon.Node] {
  let change = form_dispatch(options, (options, key : String) => {
    if !disabled && options.any(option => option.key == key && !option.disabled) {
      on_change(key)
    } else {
      @minimoon.none
    }
  })
  @minimoon.Val::map2(options, value, (options, selected) => {
    validate_choices(options)
    let enabled = options.filter(option => !option.disabled)
    let mut index = 0
    let mut text = placeholder
    for i, option in enabled {
      if option.key == selected {
        index = i
        text = option.label
      }
    }
    @minimoon.picker_selector(
      name~,
      id~,
      class="mmui-native-select " +
        size_class(size) +
        (if invalid { " mmui-invalid" } else { "" }),
      event_key=id + "/change",
      disabled=disabled || enabled.is_empty(),
      options=enabled.map(option => option.label),
      selected=index,
      on_change=@minimoon.Emit(index => {
        if disabled || index < 0 || index >= enabled.length() {
          @minimoon.none
        } else {
          change(enabled[index].key)
        }
      }),
      @minimoon.div(
        semantics=@minimoon.semantics(
          role=@minimoon.ComboboxRole,
          disabled~,
          invalid~,
          required~,
        ),
        text,
      ),
    )
  })
}

///|
pub fn native_select(
  name? : String = "",
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  initial_value? : String = "",
  placeholder? : String = "Select…",
  disabled? : Bool = false,
  invalid? : Bool = false,
  required? : Bool = false,
  size? : Size = Medium,
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  native_select_controlled(
    name~,
    id~,
    options~,
    value~,
    on_change=update.map(value => _ => value),
    placeholder~,
    disabled~,
    invalid~,
    required~,
    size~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] radio_group_root(
  on_change~ : @minimoon.Emit[String],
  name? : String = "",
  id? : String = "",
  orientation? : Orientation = Vertical,
  children : C,
) -> @minimoon.Node {
  @minimoon.radio_group(
    name~,
    on_change~,
    id~,
    class="mmui-radio-group " + orientation_class(orientation),
    children,
  )
}

///|
pub fn radio_group_item(
  value~ : String,
  checked? : Bool = false,
  disabled? : Bool = false,
  label? : String = "",
  id? : String = "",
) -> @minimoon.Node {
  @minimoon.radio(
    value~,
    checked~,
    disabled~,
    id~,
    class="mmui-radio-group-item",
    label,
  )
}
