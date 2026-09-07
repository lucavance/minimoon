///|
fn data_batch(keys : Array[String]) -> String {
  Json::array(
    keys.map(key => {
      Json::object({ "key": Json::string(key), "payload": Json::empty_object() })
    }),
  ).stringify()
}

///|
fn data_batch_output(id~ : String, value~ : String) -> @minimoon.Node {
  @minimoon.input(id~, value~, on_input=@minimoon.Emit(_ => @minimoon.none))
}

///|
test "calendar multiple selection retains both dates from a decoded event batch" {
  let runtime = advanced_native_page(_ => {
    calendar(
      id="multi",
      initial_month=@headless.calendar_date(year=2026, month=9, day=1),
      initial_selected=@headless.Multiple([]),
    )
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(data_batch(["multi/date/8", "multi/date/10"]))
  assert_eq(runtime.snapshot().split("\"ariaSelected\":true").length(), 3)
  let _ = runtime.dispatch_batch(data_batch(["multi/date/8", "multi/date/10"]))
  assert_eq(runtime.snapshot().split("\"ariaSelected\":true").length(), 1)
  let _ = runtime.dispose()
}

///|
test "controlled calendar completes range using the latest selection within a batch" {
  let runtime = advanced_native_page(_ => {
    let (month, set_month) = @minimoon.create_variable(
      @headless.calendar_date(year=2026, month=9, day=1),
    )
    let (selected, change) = @minimoon.create_variable(
      @headless.Range(None, None),
    )
    let view = calendar_controlled(
      id="range",
      month~,
      on_month_change=set_month.map(value => _ => value),
      selected~,
      on_change=change.map(value => _ => value),
    )
    @minimoon.Val::view2(view, selected, (view, selected) => {
      @minimoon.div([
        view,
        data_batch_output(
          id="selection",
          value=selection_label(selected, "none"),
        ),
      ])
    })
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(data_batch(["range/date/8", "range/date/10"]))
  assert_eq(
    native_prop(runtime, "selection", "value"),
    Some(Json::string("2026-09-07 – 2026-09-09")),
  )
  let _ = runtime.dispose()
}

///|
test "calendar relative month navigation applies each action and clamps Gregorian boundaries" {
  let runtime = advanced_native_page(_ => {
    calendar(
      id="months",
      initial_month=@headless.calendar_date(year=2026, month=9, day=1),
    )
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(data_batch(["months/next", "months/next"]))
  assert_true(runtime.snapshot().contains("\"text\":\"2026-11\""))
  let _ = runtime.dispose()
  let boundary = advanced_native_page(_ => {
    calendar(
      id="bounds",
      initial_month=@headless.calendar_date(year=9999, month=11, day=1),
    )
  })
  let _ = boundary.mount()
  let _ = boundary.dispatch_batch(data_batch(["bounds/next", "bounds/next"]))
  assert_true(boundary.snapshot().contains("\"text\":\"9999-12\""))
  let _ = boundary.dispose()
}

///|
test "date picker completes a batched range and closes only after the second choice" {
  let runtime = advanced_native_page(context => {
    let (selected, change) = @minimoon.create_variable(
      @headless.Range(None, None),
    )
    let view = date_picker(
      context,
      id="picker",
      label="Pick",
      initial_month=@headless.calendar_date(year=2026, month=9, day=1),
      selected~,
      on_change=change.map(value => _ => value),
      initially_open=true,
    )
    @minimoon.Val::view2(view, selected, (view, selected) => {
      @minimoon.div([
        view,
        data_batch_output(
          id="selection",
          value=selection_label(selected, "none"),
        ),
      ])
    })
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    data_batch([
      "picker-calendar/date/8", "picker-calendar/date/10", "picker-calendar/date/11",
    ]),
  )
  assert_eq(
    native_prop(runtime, "selection", "value"),
    Some(Json::string("2026-09-07 – 2026-09-09")),
  )
  assert_eq(native_prop(runtime, "picker-surface", "className"), None)
  let _ = runtime.dispose()
}

///|
fn data_batch_table(page_size : Int) -> @minimoon.PageRuntime {
  advanced_native_page(_ => {
    let (state, change) = @minimoon.create_variable(table_state(page_size~))
    let view = data_table_controlled(
      id="table",
      rows=@minimoon.Val::constant([1, 2, 3, 4]),
      columns=[
        data_column(key="number", label="Number", text=value => {
          value.to_string()
        }),
      ],
      row_key=value => value.to_string(),
      state~,
      on_change=change.map(value => _ => value),
    )
    @minimoon.Val::view2(view, state, (view, state) => {
      @minimoon.div([
        view,
        data_batch_output(
          id="sort",
          value=state.sort_key + ":" + state.descending.to_string(),
        ),
        data_batch_output(id="selection", value=state.selected_keys.join(",")),
        data_batch_output(id="columns", value=state.hidden_columns.join(",")),
        data_batch_output(id="page", value=state.page.to_string()),
        data_batch_output(id="query", value=state.query),
      ])
    })
  })
}

///|
test "data table batched sorting row toggles and visibility use latest controlled state" {
  let runtime = data_batch_table(10)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    data_batch([
      "table/sort/number", "table/sort/number", "table/select/1", "table/select/2",
      "table/column/number", "table/column/number",
    ]),
  )
  assert_eq(
    native_prop(runtime, "sort", "value"),
    Some(Json::string("number:true")),
  )
  assert_eq(
    native_prop(runtime, "selection", "value"),
    Some(Json::string("1,2")),
  )
  assert_eq(native_prop(runtime, "columns", "value"), Some(Json::string("")))
  let _ = runtime.dispose()
}

///|
test "data table repeated next actions advance and clamp within the current filtered rows" {
  let runtime = data_batch_table(1)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(data_batch(["table/next", "table/next"]))
  assert_eq(native_prop(runtime, "page", "value"), Some(Json::string("2")))
  let _ = runtime.dispatch_batch(data_batch(["table/next", "table/next"]))
  assert_eq(native_prop(runtime, "page", "value"), Some(Json::string("3")))
  let _ = runtime.dispose()
}

///|
test "data table filtering and row selection preserve each other's batched state" {
  let runtime = data_batch_table(10)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    Json::array([
      Json::object({
        "key": Json::string("table/select/1"),
        "payload": Json::empty_object(),
      }),
      Json::object({
        "key": Json::string("table/filter"),
        "payload": Json::object({
          "detail": Json::object({ "value": Json::string("2") }),
        }),
      }),
      Json::object({
        "key": Json::string("table/select/2"),
        "payload": Json::empty_object(),
      }),
    ]).stringify(),
  )
  assert_eq(native_prop(runtime, "query", "value"), Some(Json::string("2")))
  assert_eq(
    native_prop(runtime, "selection", "value"),
    Some(Json::string("1,2")),
  )
  let _ = runtime.dispose()
}

///|
test "data table page step observes a filter entered earlier in the same batch" {
  let runtime = data_batch_table(1)
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    Json::array([
      Json::object({
        "key": Json::string("table/filter"),
        "payload": Json::object({
          "detail": Json::object({ "value": Json::string("2") }),
        }),
      }),
      Json::object({
        "key": Json::string("table/next"),
        "payload": Json::empty_object(),
      }),
    ]).stringify(),
  )
  assert_eq(native_prop(runtime, "query", "value"), Some(Json::string("2")))
  assert_eq(native_prop(runtime, "page", "value"), Some(Json::string("0")))
  let _ = runtime.dispose()
}

///|
test "pagination next steps are relative to the current page within a batch" {
  let runtime = advanced_native_page(_ => {
    let (page, change) = @minimoon.create_variable(0)
    let view = pagination_controlled(
      id="pages",
      page~,
      total=@minimoon.Val::constant(30),
      on_change=change.map(value => _ => value),
    )
    @minimoon.Val::view2(view, page, (view, page) => {
      @minimoon.div([view, data_batch_output(id="page", value=page.to_string())])
    })
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(data_batch(["pages/next", "pages/next"]))
  assert_eq(native_prop(runtime, "page", "value"), Some(Json::string("2")))
  let _ = runtime.dispatch_batch(
    data_batch(["pages/previous", "pages/previous"]),
  )
  assert_eq(native_prop(runtime, "page", "value"), Some(Json::string("0")))
  let _ = runtime.dispose()
}
