///|
test "calendar Gregorian endpoints have unique dates and inert placeholders" {
  for
    date in [
      @headless.calendar_date(year=1, month=1, day=1),
      @headless.calendar_date(year=9999, month=12, day=31),
    ] {
    let runtime = @testing.mount(
      component_page(_ => calendar(id="bounds", initial_month=date, today=date)),
    )
    assert_eq(runtime.query_all(@testing.by_label(date.iso())).length(), 1)
    let event = if date.year == 1 { "previous" } else { "next" }
    let before = runtime.snapshot()
    let _ = runtime.tap(@testing.by_event_key("bounds/" + event))
    assert_eq(runtime.snapshot(), before)
    assert_true(
      runtime
      .get(@testing.by_label(date.iso()))
      .prop("className")
      .unwrap_or(Json::null())
      .stringify()
      .contains("mmui-calendar-today"),
    )
    let _ = runtime.dispose()
  }
}

///|
test "calendar hides outside days and whole disabled calendar is inert" {
  let runtime = @testing.mount(
    component_page(_ => {
      calendar(
        id="disabled",
        initial_month=@headless.calendar_date(year=2024, month=2, day=1),
        show_outside_days=false,
        disabled=true,
        week_start=1,
      )
    }),
  )
  assert_true(runtime.query(@testing.by_label("2024-01-31")) is None)
  assert_true(runtime.query(@testing.by_label("2024-03-01")) is None)
  let before = runtime.snapshot()
  let _ = runtime.tap(@testing.by_label("2024-02-15"))
  let _ = runtime.tap(@testing.by_event_key("disabled/next"))
  assert_eq(runtime.snapshot(), before)
}

///|
test "date picker presets update controlled value label and open callback" {
  let date = @headless.calendar_date(year=2026, month=9, day=7)
  let runtime = @testing.mount(
    component_page(context => {
      let (selected, change) = @minimoon.create_variable(@headless.Single(None))
      let (open, change_open) = @minimoon.create_variable(false)
      let picker = date_picker_controlled(
        context,
        id="picker",
        label="Choose",
        initial_month=date,
        selected~,
        on_change=change.map(value => _ => value),
        open~,
        on_open_change=change_open.map(value => _ => value),
        presets=[date_picker_preset(label="Today", value=date)],
        format_value=value => {
          if value is @headless.Single(Some(value)) {
            "Chosen " + value.iso()
          } else {
            "Choose"
          }
        },
      )
      @minimoon.Val::view2(picker, open, (picker, open) => {
        @minimoon.div([picker, @minimoon.p(id="open-state", open.to_string())])
      })
    }),
  )
  let _ = runtime.tap(@testing.by_id("picker-trigger"))
  assert_eq(runtime.get(@testing.by_id("open-state")).text_content(), "true")
  let _ = runtime.tap(@testing.by_event_key("picker/preset/0"))
  assert_eq(
    runtime.get(@testing.by_id("picker-trigger")).text_content(),
    "Chosen 2026-09-07",
  )
  assert_eq(runtime.get(@testing.by_id("open-state")).text_content(), "false")
  assert_true(runtime.query(@testing.by_id("picker-surface")) is None)
}

///|
test "date range picker keeps incomplete selection open and closes completed range" {
  let runtime = @testing.mount(
    component_page(context => {
      let (selected, change) = @minimoon.create_variable(
        @headless.Range(None, None),
      )
      date_range_picker(
        context,
        id="range",
        label="Range",
        initial_month=@headless.calendar_date(year=2026, month=9, day=1),
        selected~,
        on_change=change.map(value => _ => value),
      )
    }),
  )
  let _ = runtime.tap(@testing.by_id("range-trigger"))
  let _ = runtime.tap(@testing.by_label("2026-09-07"))
  assert_true(runtime.query(@testing.by_id("range-surface")) is Some(_))
  let _ = runtime.tap(@testing.by_label("2026-09-09"))
  assert_true(runtime.query(@testing.by_id("range-surface")) is None)
  assert_eq(
    runtime.get(@testing.by_id("range-trigger")).text_content(),
    "2026-09-07 – 2026-09-09",
  )
}

///|
test "data table numeric sorting visibility and searchable fields are independent" {
  let runtime = @testing.mount(
    component_page(_ => {
      data_table(
        id="numbers",
        rows=@minimoon.Val::constant([10, 2, 1]),
        row_key=value => value.to_string(),
        selectable=false,
        columns=[
          data_column(
            key="number",
            label="Number",
            text=value => value.to_string(),
            numeric_value=value => value.to_double(),
            hideable=false,
          ),
          data_column(
            key="secret",
            label="Secret",
            text=_ => "hidden-query",
            searchable=false,
          ),
        ],
      )
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("numbers/sort/number"))
  let rows = runtime.query_all(@testing.by_role("row"))
  assert_true(rows[1].text_content().has_prefix("1"))
  assert_true(rows[2].text_content().has_prefix("2"))
  assert_true(rows[3].text_content().has_prefix("10"))
  assert_true(
    runtime.query(@testing.by_event_key("numbers/column/number")) is None,
  )
  let _ = runtime.tap(@testing.by_event_key("numbers/column/secret"))
  assert_true(
    runtime.query(@testing.by_event_key("numbers/sort/secret")) is None,
  )
  let _ = runtime.input(@testing.by_event_key("numbers/filter"), "hidden-query")
  assert_eq(runtime.query_all(@testing.by_role("row")).length(), 1)
}

///|
test "data table explicit comparator overrides numeric projection" {
  let runtime = @testing.mount(
    component_page(_ => {
      data_table(
        id="compare",
        rows=@minimoon.Val::constant([1, 2, 10]),
        row_key=value => value.to_string(),
        selectable=false,
        columns=[
          data_column(
            key="n",
            label="N",
            text=value => value.to_string(),
            numeric_value=value => value.to_double(),
            compare=(a, b) => b.compare(a),
          ),
        ],
      )
    }),
  )
  let _ = runtime.tap(@testing.by_event_key("compare/sort/n"))
  assert_eq(runtime.query_all(@testing.by_role("row"))[1].text_content(), "10")
}

///|
test "native table spans use actual two-dimensional geometry" {
  let runtime = @testing.mount(
    component_page(_ => {
      @minimoon.Val::constant(
        table_spanning(columns=3, row_height=40, rows=[
          [
            table_span_head("Both", colspan=2),
            table_span_head("Tall", rowspan=2),
          ],
          [table_span_cell("Left"), table_span_cell("Right")],
        ]),
      )
    }),
  )
  let heads = runtime.query_all(@testing.by_role("columnheader"))
  assert_true(
    heads[0]
    .prop("style")
    .unwrap_or(Json::null())
    .stringify()
    .contains("width:66.666"),
  )
  assert_true(
    heads[1]
    .prop("style")
    .unwrap_or(Json::null())
    .stringify()
    .contains("height:80px"),
  )
  let cells = runtime.query_all(@testing.by_role("cell"))
  assert_true(
    cells[1]
    .prop("style")
    .unwrap_or(Json::null())
    .stringify()
    .contains("left:33.333"),
  )
  assert_eq(runtime.query_all(@testing.by_role("row")).length(), 2)
}

///|
test "chart supports native indicators legend positions and inactive tooltip" {
  let runtime = @testing.mount(
    component_page(_ => {
      @minimoon.Val::constant(
        chart_container([
          chart_tooltip_content(active=false, "Invisible"),
          chart_tooltip_content([
            chart_tooltip_item(label="Dot", value="1", indicator=ChartDot),
            chart_tooltip_item(label="Line", value="2", indicator=ChartLine),
            chart_tooltip_item(label="Dashed", value="3", indicator=ChartDashed),
          ]),
          chart_legend(position=LegendTop, chart_legend_item(label="Top")),
        ]),
      )
    }),
  )
  assert_true(runtime.query(@testing.by_text("Invisible")) is None)
  assert_true(runtime.snapshot().contains("border-left:1.5px dashed"))
  assert_true(runtime.snapshot().contains("padding-bottom:12px"))
  assert_eq(
    runtime.get(@testing.by_role("status")).prop("ariaLive"),
    Some(Json::string("polite")),
  )
}
