///|
pub fn combobox_controlled(
  context : UiContext,
  id~ : String,
  label~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
) -> @minimoon.Val[@minimoon.Node] {
  let (query, set_query) = @minimoon.create_variable("")
  let (open, set_open) = @minimoon.create_variable(false)
  let choose = form_dispatch(
    @minimoon.Val::map2(options, open, (options, open) => (options, open)),
    (input, key : String) => {
      let (options, open) = input
      if open && options.any(option => option.key == key && !option.disabled) {
        @minimoon.batch([on_change(key), set_open(_ => false)])
      } else {
        @minimoon.none
      }
    },
  )
  let content = @minimoon.Val::view3(query, options, value, (
    query,
    options,
    value,
  ) => {
    let results = options.filter(option => {
      query == "" || option.label.contains(query) || option.key.contains(query)
    })
    ui_container("combobox", [
      @minimoon.input(
        value=query,
        on_input=set_query.map(value => _ => value),
        event_key=id + "/search",
        placeholder="Search",
      ),
      ui_container(
        "combobox-list",
        semantics=@minimoon.semantics(role=@minimoon.ListboxRole),
        results.map(option => {
          @minimoon.button(
            disabled=option.disabled,
            event_key=id + "/option/" + option.key,
            on_tap=if option.disabled {
              @minimoon.none
            } else {
              choose(option.key)
            },
            semantics=@minimoon.semantics(
              role=@minimoon.OptionRole,
              selected=value == option.key,
            ),
            option.label,
          )
        }),
      ),
      if results.is_empty() {
        @minimoon.text("No results")
      } else {
        @minimoon.nothing()
      },
    ])
  })
  overlay_controlled(
    context,
    id~,
    title=label,
    trigger_label=label,
    content~,
    open~,
    on_change=set_open.map(value => _ => value),
    kind=PopoverSurface,
  )
}

///|
pub fn combobox(
  context : UiContext,
  id~ : String,
  label~ : String,
  options~ : @minimoon.Val[Array[ChoiceOption]],
  initial_value? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  let (value, emit) = @minimoon.create_variable(initial_value)
  combobox_controlled(
    context,
    id~,
    label~,
    options~,
    value~,
    on_change=emit.map(value => _ => value),
  )
}

///|
pub fn command(
  id~ : String,
  items~ : @minimoon.Val[Array[MenuItem]],
  placeholder? : String = "Search commands",
) -> @minimoon.Val[@minimoon.Node] {
  let (query, emit_query) = @minimoon.create_variable("")
  let results = @minimoon.Val::map2(items, query, (items, query) => {
    items.filter(item => query == "" || item.label.contains(query))
  })
  let (expanded, emit_expanded) = menu_dispatch(
    id + "/results",
    results,
    @minimoon.none,
  )
  @minimoon.Val::view3(items, query, expanded, (items, query, expanded) => {
    let results = items.filter(item => query == "" || item.label.contains(query))
    ui_container("command", id~, [
      @minimoon.input(
        value=query,
        on_input=emit_query.map(value => _ => value),
        event_key=id + "/search",
        placeholder~,
      ),
      render_menu(id + "/results", results, expanded, emit_expanded),
      if results.is_empty() {
        @minimoon.text("No results")
      } else {
        @minimoon.nothing()
      },
    ])
  })
}
