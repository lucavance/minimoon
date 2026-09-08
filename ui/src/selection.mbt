///|
pub fn select_option(
  key~ : String,
  label~ : String,
  disabled? : Bool = false,
  group? : String = "",
) -> ChoiceOption {
  choice_option(key~, label~, disabled~, group~)
}

///|
pub fn native_select_option(
  key~ : String,
  label~ : String,
  disabled? : Bool = false,
  group? : String = "",
) -> ChoiceOption {
  choice_option(key~, label~, disabled~, group~)
}

///|
pub fn native_select_optgroup(
  label~ : String,
  options : Array[ChoiceOption],
) -> Array[ChoiceOption] {
  options.map(option => { ..option, group: label, })
}

///|
pub fn select_value(
  options : Array[ChoiceOption],
  value : String,
  placeholder? : String = "Select…",
) -> String {
  for option in options {
    if option.key == value {
      return option.label
    }
  }
  placeholder
}

///|
pub fn[C : @minimoon.IsChildren] select_item(
  on_tap~ : @minimoon.Cmd,
  selected? : Bool = false,
  disabled? : Bool = false,
  id? : String = "",
  children : C,
) -> @minimoon.Node {
  @minimoon.tap_view(
    id~,
    on_tap=if disabled { @minimoon.none } else { on_tap },
    class="mmui-select-item " +
      (if selected { "mmui-selected " } else { "" }) +
      (if disabled { "mmui-disabled" } else { "" }),
    semantics=@minimoon.semantics(
      role=@minimoon.OptionRole,
      selected~,
      disabled~,
    ),
    children,
  )
}

///|
pub fn select_trigger(
  on_tap~ : @minimoon.Cmd,
  value~ : String,
  id~ : String,
  expanded? : Bool = false,
  disabled? : Bool = false,
  invalid? : Bool = false,
  required? : Bool = false,
  content? : @minimoon.Node,
) -> @minimoon.Node {
  @minimoon.button_children(
    id~,
    on_tap=if disabled { @minimoon.none } else { on_tap },
    disabled~,
    class="mmui-select-trigger",
    semantics=@minimoon.semantics(
      role=@minimoon.ComboboxRole,
      expanded~,
      disabled~,
      invalid~,
      required~,
      has_popup="listbox",
    ),
    content.unwrap_or(@minimoon.text(value)),
  )
}

///|
/// Select uses a page-owned native layer; application must declare MeasureNodes.
pub fn select_controlled(
  context : UiContext,
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  placeholder? : String = "Select…",
  disabled? : Bool = false,
  open? : @minimoon.Val[Bool],
  initially_open? : Bool = false,
  on_open_change? : @minimoon.Emit[Bool],
  invalid? : Bool = false,
  required? : Bool = false,
  placement? : @headless.Placement = @headless.BottomStart,
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
  render_option? : (ChoiceOption, Bool) -> @minimoon.Node,
  render_value? : (String, Array[ChoiceOption]) -> @minimoon.Node,
  render_content? : (Array[@minimoon.Node]) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  validate_measured_id(id)
  guard open is None || on_open_change is Some(_) else {
    abort("controlled Select open requires on_open_change")
  }
  let (owned_open, update_open) = @minimoon.create_variable(initially_open)
  let open = open.unwrap_or(owned_open)
  let change_open = @minimoon.Emit((next : Bool) => {
    @minimoon.batch([
      update_open(_ => next),
      on_open_change.map(emit => emit(next)).unwrap_or(@minimoon.none),
    ])
  })
  let bounds = floating_bounds(
    context,
    id,
    open.map(open => open && !disabled),
    placement,
    side_offset~,
    align_offset~,
    surface_id=id + "-panel",
  )
  let _ = @minimoon.create_state(
    (),
    update=(_, _message : Unit, _) => @minimoon.no_cmd(()),
    subscriptions=(_, _) => context.page.on_hide(change_open(false)),
  )
  let show = change_open(true)
  let choose = form_dispatch(
    @minimoon.Val::map3(options, open, context.visible, (options, open, visible) => {
      (options, open, visible)
    }),
    (current, key : String) => {
      let (options, open, visible) = current
      if open &&
        visible &&
        !disabled &&
        options.any(option => option.key == key && !option.disabled) {
        @minimoon.batch([on_change(key), change_open(false)])
      } else {
        @minimoon.none
      }
    },
  )
  @minimoon.Val::view5(options, value, open, bounds, context.visible, (
    options,
    value,
    open,
    bounds,
    visible,
  ) => {
    validate_choices(options)
    let rows : Array[@minimoon.Node] = []
    let mut group = ""
    for option in options {
      if option.group != "" && option.group != group {
        rows.push(select_label(option.group))
        group = option.group
      }
      rows.push(
        select_item(
          id=id + "-option-" + option.key,
          selected=option.key == value,
          disabled=disabled || option.disabled,
          on_tap=choose(option.key),
          match render_option {
            Some(render) => render(option, option.key == value)
            None =>
              @minimoon.fragment([
                @minimoon.text(option.label),
                @minimoon.text(if option.key == value { "✓" } else { "" }),
              ])
          },
        ),
      )
    }
    ui_container(
      "select",
      [
        select_trigger(
          id=id + "-trigger",
          on_tap=show,
          value=select_value(options, value, placeholder~),
          expanded=open,
          disabled~,
          invalid~,
          required~,
          content?=render_value.map(render => render(value, options)),
        ),
        if open && visible && !disabled {
          @minimoon.layer(id=id + "-layer", [
            @minimoon.tap_view(
              class="mmui-overlay",
              style="position:fixed;top:0;left:0;right:0;bottom:0;",
              on_tap=change_open(false),
              @minimoon.nothing(),
            ),
            @minimoon.scroll_view(
              id=id + "-panel",
              class="mmui-select-panel",
              scroll_y=true,
              style=surface_style(PopoverSurface, bounds),
              match render_content {
                Some(render) => render(rows)
                None => select_content(rows)
              },
            ),
          ])
        } else {
          @minimoon.nothing()
        },
      ],
      id~,
    )
  })
}

///|
pub fn select_scroll_up_button(
  on_scroll~ : @minimoon.Cmd,
  disabled? : Bool = false,
) -> @minimoon.Node {
  button(on_tap=on_scroll, disabled~, variant=Ghost, label="Scroll up", "↑")
}

///|
pub fn select_scroll_down_button(
  on_scroll~ : @minimoon.Cmd,
  disabled? : Bool = false,
) -> @minimoon.Node {
  button(on_tap=on_scroll, disabled~, variant=Ghost, label="Scroll down", "↓")
}

///|
fn validate_measured_id(id : String) -> Unit {
  guard id != "" else { abort("measured component id must not be empty") }
  for character in id.iter() {
    guard (character >= 'a' && character <= 'z') ||
      (character >= 'A' && character <= 'Z') ||
      (character >= '0' && character <= '9') ||
      character == '_' ||
      character == '-' else {
      abort(
        "measured component id must contain only letters, digits, underscore or hyphen",
      )
    }
  }
}

///|
pub fn select(
  context : UiContext,
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  initial_value? : String = "",
  placeholder? : String = "Select…",
  disabled? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  select_controlled(
    context,
    id~,
    options~,
    value~,
    on_change=update.map(value => _ => value),
    placeholder~,
    disabled~,
  )
}

///|
pub fn input_group_control(content : @minimoon.Node) -> @minimoon.Node {
  ui_container("input-group-control", [content])
}

///|
pub fn input_group_input(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  options? : InputOptions = input_options(),
) -> @minimoon.Val[@minimoon.Node] {
  input_with_focus(id~, value~, on_input=on_change, options~).map(
    input_group_control,
  )
}

///|
pub fn input_group_textarea(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  options? : InputOptions = input_options(),
) -> @minimoon.Val[@minimoon.Node] {
  textarea_with_focus(id~, value~, on_input=on_change, options~).map(
    input_group_control,
  )
}
