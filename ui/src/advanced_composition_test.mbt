///|
test "compound overlay preserves rich trigger actions and reports dismissal reasons" {
  let runtime = @testing.mount(
    component_page(context => {
      let (events, emit) = @minimoon.create_variable("")
      stack([
        overlay_provider(
          context,
          id="rich",
          force_mount=true,
          on_close=emit.map(reason => {
            previous => {
              previous +
              (match reason {
                Action => "Action"
                Backdrop => "Backdrop"
                _ => "Other"
              })
            }
          }),
          render=scope => {
            @minimoon.fragment([
              overlay_trigger(
                scope,
                @minimoon.text("Rich trigger"),
                on_tap=emit(previous => previous + "tap"),
              ),
              overlay_content(
                scope,
                [
                  overlay_title(scope, "Title"),
                  overlay_description(scope, "Description"),
                  overlay_footer(
                    overlay_action(
                      scope,
                      "Apply",
                      on_tap=emit(previous => previous + "action"),
                    ),
                  ),
                ],
                show_close=false,
              ),
            ])
          },
        ),
        events.map(events => @minimoon.div(id="events", events)),
      ])
    }),
  )
  assert_eq(
    runtime.get(@testing.by_id("rich-surface")).prop("ariaHidden"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.tap(@testing.by_event_key("rich/trigger"))
  assert_eq(runtime.get(@testing.by_id("events")).text_content(), "tap")
  assert_eq(
    runtime.get(@testing.by_id("rich-surface")).prop("ariaHidden"),
    Some(Json::boolean(false)),
  )
  assert_true(runtime.query(@testing.by_event_key("rich/close")) is None)
  let _ = runtime.tap(@testing.by_event_key("rich/action"))
  assert_eq(
    runtime.get(@testing.by_id("events")).text_content(),
    "tapactionAction",
  )
  let _ = runtime.tap(@testing.by_event_key("rich/trigger"))
  let _ = runtime.tap(@testing.by_event_key("rich/dismiss"))
  assert_true(
    runtime.get(@testing.by_id("events")).text_content().has_suffix("Backdrop"),
  )
}

///|
test "rich grouped menu honors per-item close policy and controlled menubar" {
  let runtime = @testing.mount(
    component_page(context => {
      let (value, emit) = @minimoon.create_variable((None : String?))
      let items = @minimoon.Val::constant([
        menu_group(key="group", label="Group", items=[
          menu_customize(
            menu_item(key="keep", label="Keep", on_select=@minimoon.none),
            content=@minimoon.text("Rich item"),
            shortcut="Hint",
            inset=true,
            close_on_select=false,
          ),
          menu_customize(
            menu_checkbox_item(
              key="close",
              label="Check",
              checked=false,
              on_change=@minimoon.Emit(_ => @minimoon.none),
            ),
            destructive=true,
            close_on_select=true,
          ),
        ]),
      ])
      stack([
        menubar_controlled(
          context,
          id="bar",
          groups=[
            { key: "a", label: "A", items, },
            { key: "b", label: "B", items, },
          ],
          value~,
          on_value_change=emit.map(value => _ => value),
        ),
        @minimoon.Val::constant(
          @minimoon.button(
            event_key="select-a",
            on_tap=emit(_ => Some("a")),
            "Select A",
          ),
        ),
      ])
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("select-a"))
  assert_true(runtime.query(@testing.by_id("bar-a-surface")) is Some(_))
  let _ = runtime.tap(@testing.by_event_key("bar-a/group/keep"))
  assert_true(
    runtime.get(@testing.by_id("bar-a-surface")).text_content().contains("Hint"),
  )
  let _ = runtime.tap(@testing.by_event_key("bar-b/trigger"))
  assert_true(runtime.query(@testing.by_id("bar-a-surface")) is None)
  let _ = runtime.tap(@testing.by_event_key("bar-b/group/close"))
  assert_true(runtime.query(@testing.by_id("bar-b-surface")) is None)
}

///|
test "multi combobox preserves query, removes chips, clears and reports changes" {
  let runtime = @testing.mount(
    component_page(context => {
      let (state, emit) = @minimoon.create_variable(combobox_state())
      let (events, log) = @minimoon.create_variable("")
      stack([
        combobox_provider_controlled(
          context,
          id="multi",
          options=@minimoon.Val::constant([
            combobox_option(value="one", label="First"),
            combobox_option(value="two", label="Second"),
            combobox_option(value="lock", label="Locked", disabled=true),
          ]),
          state~,
          on_change=emit.map(next => _ => next),
          multiple=true,
          filter=(option, query) => query == "" || option.key == query,
          on_query_change=log.map(query => {
            previous => previous + "q:" + query + ";"
          }),
          on_values_change=log.map(values => {
            previous => previous + "v:" + values.join(",") + ";"
          }),
        ),
        state.map(state => @minimoon.div(id="values", state.values.join(","))),
        events.map(events => @minimoon.div(id="log", events)),
      ])
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("multi/open"))
  let _ = runtime.tap(@testing.by_event_key("multi/option/one"))
  let _ = runtime.tap(@testing.by_event_key("multi/option/two"))
  let _ = runtime.tap(@testing.by_event_key("multi/option/lock"))
  assert_eq(runtime.get(@testing.by_id("values")).text_content(), "one,two")
  assert_true(runtime.query(@testing.by_id("multi-surface")) is Some(_))
  let _ = runtime.input(@testing.by_event_key("multi/query"), "one")
  assert_true(runtime.query(@testing.by_event_key("multi/option/two")) is None)
  let _ = runtime.tap(@testing.by_event_key("multi/remove/one"))
  assert_eq(runtime.get(@testing.by_id("values")).text_content(), "two")
  let _ = runtime.tap(@testing.by_event_key("multi/clear"))
  assert_eq(runtime.get(@testing.by_id("values")).text_content(), "")
  assert_true(
    runtime.get(@testing.by_id("log")).text_content().contains("q:one;"),
  )
}

///|
test "command provider filters keywords keeps forced items and invokes selection" {
  let runtime = @testing.mount(
    component_page(_ => {
      let (selected, emit) = @minimoon.create_variable("")
      stack([
        command_provider(
          id="commands",
          on_value_select=emit.map(value => _ => value),
          render=scope => {
            @minimoon.fragment([
              command_input(scope),
              command_list([
                command_item(
                  scope,
                  value="save",
                  keywords=["persist"],
                  @minimoon.text("Save"),
                ),
                command_item(
                  scope,
                  value="always",
                  force_mount=true,
                  @minimoon.text("Always"),
                ),
                command_item(
                  scope,
                  value="disabled",
                  keywords=["persist"],
                  disabled=true,
                  @minimoon.text("Disabled"),
                ),
              ]),
            ])
          },
        ),
        selected.map(value => @minimoon.div(id="selected", value)),
      ])
    }),
  )
  let _ = runtime.input(@testing.by_event_key("commands/query"), "PERSIST")
  assert_true(
    runtime.query(@testing.by_event_key("commands/item/save")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_event_key("commands/item/always")) is Some(_),
  )
  let _ = runtime.tap(@testing.by_event_key("commands/item/disabled"))
  assert_eq(runtime.get(@testing.by_id("selected")).text_content(), "")
  let _ = runtime.tap(@testing.by_event_key("commands/item/save"))
  assert_eq(runtime.get(@testing.by_id("selected")).text_content(), "save")
  let _ = runtime.input(@testing.by_event_key("commands/query"), "unmatched")
  assert_true(
    runtime.query(@testing.by_event_key("commands/item/save")) is None,
  )
}
