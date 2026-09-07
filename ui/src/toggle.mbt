///|
pub fn toggle_controlled(
  id~ : String,
  pressed~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  content~ : @minimoon.Val[@minimoon.Node],
  disabled? : Bool = false,
  variant? : ButtonVariant = Ghost,
  size? : Size = Medium,
  invalid? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let tap = form_dispatch(pressed, (current, _ : Unit) => {
    if disabled {
      @minimoon.none
    } else {
      on_change(!current)
    }
  })
  @minimoon.Val::map2(pressed, content, (selected, node) => {
    @minimoon.button_children(
      id~,
      event_key=id + "/toggle",
      disabled~,
      class="mmui-toggle " +
        size_class(size) +
        (if invalid { " mmui-invalid " } else { " " }) +
        (if selected { "mmui-selected" } else { "" }) +
        (if variant == Outline { " mmui-outline" } else { "" }),
      semantics=@minimoon.semantics(
        role=@minimoon.ButtonRole,
        selected~,
        disabled~,
        invalid~,
      ),
      on_tap=tap(()),
      [node],
    )
  })
}

///|
pub fn toggle(
  id~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  initially_pressed? : Bool = false,
  disabled? : Bool = false,
  variant? : ButtonVariant = Ghost,
  size? : Size = Medium,
  invalid? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (pressed, update) = @minimoon.create_variable(initially_pressed)
  toggle_controlled(
    id~,
    pressed~,
    on_change=update.map(value => _ => value),
    content~,
    disabled~,
    variant~,
    size~,
    invalid~,
  )
}

///|
pub fn toggle_group_controlled(
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  value~ : @minimoon.Val[Array[String]],
  on_change~ : @minimoon.Emit[Array[String]],
  multiple? : Bool = false,
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
  variant? : ButtonVariant = Ghost,
  size? : Size = Medium,
  spacing? : Int = 0,
  render? : (ChoiceOption, Bool) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  let tap = form_dispatch(
    @minimoon.Val::map2(options, value, (options, value) => (options, value)),
    (current, key : String) => {
      let (options, selected) = current
      validate_choices(options)
      if disabled ||
        !options.any(option => option.key == key && !option.disabled) {
        return @minimoon.none
      }
      let selected = normalize_toggle_keys(options, selected, multiple)
      let next = if selected.contains(key) {
        selected.filter(value => value != key)
      } else if multiple {
        let next = selected.copy()
        next.push(key)
        next
      } else {
        [key]
      }
      on_change(next)
    },
  )
  @minimoon.Val::map2(options, value, (options, selected) => {
    validate_choices(options)
    let selected = normalize_toggle_keys(options, selected, multiple)
    ui_container(
      "toggle-group",
      options.map(option => {
        let active = selected.contains(option.key)
        @minimoon.button_children(
          id=id + "-" + option.key,
          class="mmui-toggle " +
            size_class(size) +
            (if variant == Outline { " mmui-outline" } else { "" }) +
            (if active { " mmui-selected" } else { "" }),
          event_key=id + "/" + option.key,
          disabled=disabled || option.disabled,
          semantics=@minimoon.semantics(
            role=@minimoon.ButtonRole,
            selected=active,
            disabled=disabled || option.disabled,
          ),
          on_tap=if disabled || option.disabled {
            @minimoon.none
          } else {
            tap(option.key)
          },
          match render {
            Some(render) => render(option, active)
            None => @minimoon.text(option.label)
          },
        )
      }),
      id~,
      class=orientation_class(orientation),
      style="gap:" + spacing.max(0).to_string() + "px;",
      semantics=@minimoon.semantics(role=@minimoon.GroupRole),
    )
  })
}

///|
pub fn toggle_group(
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  initial_value? : Array[String] = [],
  multiple? : Bool = false,
  disabled? : Bool = false,
  orientation? : Orientation = Horizontal,
  variant? : ButtonVariant = Ghost,
  size? : Size = Medium,
  spacing? : Int = 0,
  render? : (ChoiceOption, Bool) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  toggle_group_controlled(
    id~,
    options~,
    value~,
    on_change=update.map(value => _ => value),
    multiple~,
    disabled~,
    orientation~,
    variant~,
    size~,
    spacing~,
    render?,
  )
}

///|
pub fn[C : @minimoon.IsChildren] toggle_group_item(
  on_tap~ : @minimoon.Cmd,
  pressed? : Bool = false,
  disabled? : Bool = false,
  id? : String = "",
  children : C,
) -> @minimoon.Node {
  @minimoon.button_children(
    on_tap=if disabled { @minimoon.none } else { on_tap },
    id~,
    disabled~,
    class="mmui-toggle " + (if pressed { "mmui-selected" } else { "" }),
    semantics=@minimoon.semantics(
      role=@minimoon.ButtonRole,
      selected=pressed,
      disabled~,
    ),
    children,
  )
}
