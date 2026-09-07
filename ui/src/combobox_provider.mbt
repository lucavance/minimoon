///|
pub fn combobox_provider_controlled(
  context : UiContext,
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  state~ : @minimoon.Val[ComboboxState],
  on_change~ : @minimoon.Emit[ComboboxState],
  multiple? : Bool = false,
  disabled? : Bool = false,
  invalid? : Bool = false,
  required? : Bool = false,
  placeholder? : String = "Choose",
  empty_text? : String = "No results",
  on_query_change? : @minimoon.Emit[String],
  on_values_change? : @minimoon.Emit[Array[String]],
  on_open_change? : @minimoon.Emit[Bool],
  filter? : (ChoiceOption, String) -> Bool = (option, query) => {
    option.label.to_lower().contains(query.to_lower()) ||
    option.key.to_lower().contains(query.to_lower())
  },
  render? : (ComboboxScope) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  let update = combobox_dispatch(
    context,
    options,
    state,
    on_change,
    multiple~,
    disabled~,
    on_query_change?,
    on_values_change?,
    on_open_change?,
  )
  let bounds = floating_bounds(
    context,
    id,
    state.map(state => state.open && !disabled),
    @headless.BottomStart,
  )
  @minimoon.Val::view4(options, state, bounds, context.visible, (
    options,
    state,
    bounds,
    visible,
  ) => {
    validate_choices(options)
    let show = update(SetOpen(true))
    let scope = ComboboxScope::{
      id,
      state,
      options,
      filtered_options: options.filter(option => filter(option, state.query)),
      disabled,
      invalid,
      required,
      visible,
      bounds,
      update,
      show,
    }
    match render {
      Some(render) => render(scope)
      None => {
        let filtered = options.filter(option => filter(option, state.query))
        let chips = state.values.map(value => {
          combobox_chip(
            scope,
            value~,
            @minimoon.text(select_value(options, value, placeholder=value)),
          )
        })
        ui_container("combobox", id~, [
          combobox_trigger(
            scope,
            label=if state.values.is_empty() {
              placeholder
            } else {
              state.values
              .map(key => select_value(options, key, placeholder=key))
              .join(", ")
            },
          ),
          ui_container("combobox-chips", chips),
          if state.open && visible && !disabled {
            @minimoon.layer(id=id + "-layer", [
              @minimoon.tap_view(
                event_key=id + "/dismiss",
                on_tap=update(SetOpen(false)),
                class="mmui-overlay",
                style="position:fixed;inset:0;",
                @minimoon.nothing(),
              ),
              ui_container(
                "surface",
                id=id + "-surface",
                style=surface_style(PopoverSurface, bounds),
                [
                  combobox_input(scope),
                  combobox_clear(scope),
                  ui_container(
                    "combobox-list",
                    semantics=@minimoon.semantics(role=@minimoon.ListboxRole),
                    filtered.map(option => {
                      combobox_item(
                        scope,
                        value=option.key,
                        disabled=option.disabled,
                        @minimoon.text(option.label),
                      )
                    }),
                  ),
                  if filtered.is_empty() {
                    @minimoon.text(empty_text)
                  } else {
                    @minimoon.nothing()
                  },
                ],
              ),
            ])
          } else {
            @minimoon.nothing()
          },
        ])
      }
    }
  })
}

///|
pub fn combobox_provider(
  context : UiContext,
  id~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  initial? : ComboboxState = combobox_state(),
  multiple? : Bool = false,
  disabled? : Bool = false,
  invalid? : Bool = false,
  required? : Bool = false,
  on_query_change? : @minimoon.Emit[String],
  on_values_change? : @minimoon.Emit[Array[String]],
  on_open_change? : @minimoon.Emit[Bool],
  render? : (ComboboxScope) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  let (state, emit) = @minimoon.create_variable(initial)
  combobox_provider_controlled(
    context,
    id~,
    options~,
    state~,
    on_change=emit.map(value => _ => value),
    multiple~,
    disabled~,
    invalid~,
    required~,
    on_query_change?,
    on_values_change?,
    on_open_change?,
    render?,
  )
}

///|
pub fn[C : @minimoon.IsChildren] combobox_content(
  scope : ComboboxScope,
  children : C,
) -> @minimoon.Node {
  if scope.state.open && scope.visible && !scope.disabled {
    @minimoon.layer(id=scope.id + "-layer", [
      @minimoon.tap_view(
        class="mmui-overlay",
        style="position:fixed;inset:0;",
        event_key=scope.id + "/dismiss",
        on_tap=scope.close(),
        @minimoon.nothing(),
      ),
      ui_container(
        "surface",
        id=scope.id + "-surface",
        style=surface_style(PopoverSurface, scope.bounds),
        children.to_nodes(),
      ),
    ])
  } else {
    @minimoon.nothing()
  }
}

///|
pub fn[C : @minimoon.IsChildren] combobox_empty(
  children : C,
  visible? : Bool = true,
) -> @minimoon.Node {
  if visible {
    ui_container("combobox-empty", children.to_nodes())
  } else {
    @minimoon.nothing()
  }
}
