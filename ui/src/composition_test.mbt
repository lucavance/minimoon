///|
fn component_page(
  build : (UiContext) -> @minimoon.Val[@minimoon.Node],
) -> @minimoon.Page {
  @minimoon.page(
    id="ui_composition",
    route=@minimoon.route("pages/ui_composition/ui_composition"),
    title="UI composition",
    capabilities=[@minimoon.MeasureNodes],
    build=page => root(page, build),
  )
}

///|
test "dialog content stays reactive and layers escape scrolling parents" {
  let runtime = @testing.mount(
    component_page(context => {
      let (count, emit) = @minimoon.create_variable(0)
      let content = count.map(value => {
        @minimoon.div([
          @minimoon.text("Count " + value.to_string()),
          @minimoon.button(
            on_tap=emit(value => value + 1),
            event_key="dialog/increment",
            "Increment",
          ),
        ])
      })
      dialog(context, id="modal", title="Modal", trigger_label="Open", content~).map(node => {
          @minimoon.scroll_view(id="scroller", scroll_y=true, node)
        },
      )
    }),
  )
  let _ = runtime.tap(@testing.by_id("modal-trigger"))
  assert_true(runtime.query(@testing.by_id("modal-surface")) is Some(_))
  assert_true(
    runtime
    .within(@testing.by_id("scroller"))
    .query(@testing.by_id("modal-surface"))
    is None,
  )
  let _ = runtime.tap(@testing.by_event_key("dialog/increment"))
  assert_true(
    runtime
    .get(@testing.by_id("modal-surface"))
    .text_content()
    .contains("Count 1"),
  )
  let _ = runtime.lifecycle("onHide")
  assert_true(runtime.query(@testing.by_id("modal-surface")) is None)
  let _ = runtime.lifecycle("onShow")
  assert_true(
    runtime
    .get(@testing.by_id("modal-surface"))
    .text_content()
    .contains("Count 1"),
  )
  let _ = runtime.tap(@testing.by_event_key("modal/close"))
  assert_true(runtime.query(@testing.by_id("modal-surface")) is None)
  let _ = runtime.dispose()
}

///|
test "accordion multiple state and tabs react to replaced content" {
  let runtime = @testing.mount(
    component_page(_ => {
      let (count, emit) = @minimoon.create_variable(0)
      let items = count.map(count => {
        [
          panel(
            key="one",
            title="One",
            content=@minimoon.text("Value " + count.to_string()),
          ),
          panel(key="two", title="Two", content=@minimoon.text("Second")),
          panel(
            key="locked",
            title="Locked",
            content=@minimoon.text("Forbidden"),
            disabled=true,
          ),
        ]
      })
      stack([
        accordion(id="accordion", items~, multiple=true),
        tabs(id="tabs", items~, initial_selected="one"),
        @minimoon.Val::constant(
          @minimoon.button(
            on_tap=emit(value => value + 1),
            event_key="update",
            "Update",
          ),
        ),
      ])
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("accordion/one"))
  let _ = runtime.tap(@testing.by_event_key("accordion/two"))
  let _ = runtime.tap(@testing.by_event_key("accordion/locked"))
  assert_true(runtime.query(@testing.by_text("Forbidden")) is None)
  let _ = runtime.tap(@testing.by_event_key("update"))
  assert_true(
    runtime
    .get(@testing.by_id("accordion-panel-one"))
    .text_content()
    .contains("Value 1"),
  )
  assert_true(
    runtime
    .get(@testing.by_id("tabs-panel-one"))
    .text_content()
    .contains("Value 1"),
  )
  let _ = runtime.tap(@testing.by_event_key("tabs/two"))
  assert_true(runtime.query(@testing.by_id("tabs-panel-one")) is None)
}

///|
test "menu checkbox and submenu state update without closing parent" {
  let runtime = @testing.mount(
    component_page(context => {
      let (checked, emit) = @minimoon.create_variable(false)
      let items = checked.map(checked => {
        [
          menu_checkbox_item(
            key="check",
            label="Check",
            checked~,
            on_change=emit.map(value => _ => value),
          ),
          menu_submenu(key="more", label="More", items=[
            menu_item(key="done", label="Done", on_select=@minimoon.none),
          ]),
        ]
      })
      dropdown_menu(context, id="menu", trigger_label="Menu", items~)
    }),
  )
  let _ = runtime.tap(@testing.by_id("menu-trigger"))
  let _ = runtime.tap(@testing.by_event_key("menu/check"))
  assert_eq(
    runtime.get(@testing.by_event_key("menu/check")).prop("ariaChecked"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.tap(@testing.by_event_key("menu/more"))
  let _ = runtime.tap(@testing.by_event_key("menu/more/done"))
  assert_true(runtime.query(@testing.by_id("menu-surface")) is None)
}

///|
test "calendar range and disabled dates are independent across page instances" {
  let page = component_page(_ => {
    calendar(
      id="calendar",
      initial_month=@headless.calendar_date(year=2024, month=2, day=1),
      initial_selected=@headless.Range(None, None),
      disabled_date=date => date.day == 10,
    )
  })
  let a = @testing.mount(page)
  let b = @testing.mount(page)
  let _ = a.tap(@testing.by_label("2024-02-20"))
  let _ = a.tap(@testing.by_label("2024-02-15"))
  assert_eq(
    a.get(@testing.by_label("2024-02-18")).prop("ariaSelected"),
    Some(Json::boolean(true)),
  )
  assert_eq(
    b.get(@testing.by_label("2024-02-18")).prop("ariaSelected"),
    Some(Json::boolean(false)),
  )
  let before = a.snapshot()
  let _ = a.tap(@testing.by_label("2024-02-10"))
  assert_eq(a.snapshot(), before)
  let _ = a.dispose()
  let _ = b.dispose()
}

///|
test "data table sorts filters pages and preserves selected row keys" {
  let runtime = @testing.mount(
    component_page(_ => {
      data_table(
        id="table",
        rows=@minimoon.Val::constant(["Two", "Ten", "One"]),
        columns=[data_column(key="name", label="Name", text=value => value)],
        row_key=value => value,
        page_size=2,
      )
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("table/sort/name"))
  let rows = runtime.query_all(@testing.by_role("row"))
  assert_true(rows[1].text_content().contains("One"))
  assert_true(rows[2].text_content().contains("Ten"))
  let _ = runtime.tap(@testing.by_event_key("table/select/One"))
  let _ = runtime.tap(@testing.by_event_key("table/next"))
  assert_true(
    runtime.query(@testing.by_event_key("table/select/Two")) is Some(_),
  )
  let _ = runtime.input(@testing.by_event_key("table/filter"), "One")
  assert_eq(
    runtime.get(@testing.by_event_key("table/select/One")).prop("ariaChecked"),
    Some(Json::boolean(true)),
  )
}

///|
test "combobox filters and command invokes only enabled action" {
  let runtime = @testing.mount(
    component_page(context => {
      let (count, emit) = @minimoon.create_variable(0)
      stack([
        combobox(
          context,
          id="combo",
          label="Choose",
          options=@minimoon.Val::constant([
            choice_option(key="one", label="One"),
            choice_option(key="two", label="Two"),
          ]),
        ),
        command(
          id="cmd",
          items=@minimoon.Val::constant([
            menu_item(
              key="run",
              label="Run",
              on_select=emit(value => value + 1),
            ),
            menu_item(
              key="locked",
              label="Locked",
              on_select=emit(value => value + 10),
              disabled=true,
            ),
          ]),
        ),
        count.map(value => @minimoon.div(id="count", value.to_string())),
      ])
    }),
  )
  let _ = runtime.tap(@testing.by_id("combo-trigger"))
  let _ = runtime.input(@testing.by_event_key("combo/search"), "Two")
  assert_true(runtime.query(@testing.by_event_key("combo/option/one")) is None)
  let _ = runtime.tap(@testing.by_event_key("combo/option/two"))
  assert_true(runtime.query(@testing.by_id("combo-surface")) is None)
  let _ = runtime.tap(@testing.by_event_key("cmd/results/locked"))
  let _ = runtime.tap(@testing.by_event_key("cmd/results/run"))
  assert_eq(runtime.get(@testing.by_id("count")).text_content(), "1")
}

///|
test "toast and sonner share page queue with timer pause dismiss and limits" {
  let runtime = @testing.mount(
    component_page(context => {
      stack([
        @minimoon.Val::constant(
          @minimoon.button(
            event_key="notify",
            on_tap=toast(
              context,
              toast_notice(id="notice", title="Saved", duration_ms=500),
            ),
            "Notify",
          ),
        ),
        sonner(context),
      ])
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("notify"))
  assert_true(runtime.query(@testing.by_id("notice")) is Some(_))
  let _ = runtime.tick("mmui-toast-clock")
  let _ = runtime.lifecycle("onHide")
  assert_true(runtime.query(@testing.by_id("notice")) is None)
  let _ = runtime.lifecycle("onShow")
  assert_true(runtime.query(@testing.by_id("notice")) is Some(_))
  let _ = runtime.tick("mmui-toast-clock")
  assert_true(runtime.query(@testing.by_id("notice")) is None)
  let _ = runtime.tap(@testing.by_event_key("notify"))
  let _ = runtime.tap(@testing.by_event_key("toast/notice/dismiss"))
  assert_true(runtime.query(@testing.by_id("notice")) is None)
}
