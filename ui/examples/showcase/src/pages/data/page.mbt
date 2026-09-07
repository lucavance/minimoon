///|
pub fn program() -> @minimoon.Page {
  @gallery.page("data", "数据与日期 / Data — 8 components", context => {
    let month = @headless.calendar_date(year=2026, month=9, day=7)
    let (date, set_date) = @minimoon.create_variable(@headless.Single(None))
    let (command_result, set_command_result) = @minimoon.create_variable(
      "Choose a command",
    )
    let options = @minimoon.Val::constant([
      @ui.choice_option(key="moonbit", label="MoonBit"),
      @ui.choice_option(key="skyline", label="Skyline"),
      @ui.choice_option(key="unavailable", label="Unavailable", disabled=true),
    ])
    let commands = @minimoon.Val::constant([
      @ui.menu_item(
        key="save",
        label="Save draft",
        on_select=set_command_result(_ => "Draft saved"),
      ),
      @ui.menu_item(
        key="publish",
        label="Publish",
        on_select=set_command_result(_ => "Published"),
      ),
      @ui.menu_item(
        key="disabled",
        label="Disabled action",
        disabled=true,
        on_select=set_command_result(_ => "Must not happen"),
      ),
    ])
    let rows = @minimoon.Val::constant([
      ("one", "MoonBit", 10),
      ("two", "Skyline", 2),
      ("three", "Minimoon", 1),
    ])
    @ui.stack([
      @gallery.sample(
        "Calendar",
        @ui.stack([
          @ui.calendar(
            id="data-calendar",
            initial_month=month,
            today=month,
            show_outside_days=false,
            disabled_date=date => date.weekday() == 0,
          ),
          @ui.calendar(
            id="data-calendar-multiple",
            initial_month=month,
            initial_selected=@headless.Multiple([]),
          ),
          @ui.calendar(
            id="data-calendar-range",
            initial_month=month,
            initial_selected=@headless.Range(None, None),
          ),
        ]),
      ),
      @gallery.display(
        "Chart",
        @ui.chart_container(
          label="Application-owned sample bars",
          style=@ui.chart_style([("first", "#737373"), ("second", "#262626")]),
          [
            @minimoon.div(
              style="display:flex;gap:8px;align-items:flex-end;height:100px;",
              [
                @minimoon.div(
                  style="width:40%;height:60px;background:#737373;",
                  @minimoon.nothing(),
                ),
                @minimoon.div(
                  style="width:40%;height:90px;background:#262626;",
                  @minimoon.nothing(),
                ),
              ],
            ),
            @ui.chart_legend(
              @ui.chart_legend_content([
                @ui.chart_legend_item(label="First", color="#737373"),
                @ui.chart_legend_item(label="Second", color="#262626"),
              ]),
            ),
            @ui.chart_tooltip(
              @ui.chart_tooltip_content([
                @ui.chart_tooltip_label("Example values"),
                @ui.chart_tooltip_item(label="First", value="60"),
                @ui.chart_tooltip_item(
                  label="Second",
                  value="90",
                  indicator=@ui.ChartLine,
                ),
                @ui.chart_tooltip_item(
                  label="Forecast",
                  value="75",
                  indicator=@ui.ChartDashed,
                ),
              ]),
            ),
          ],
        ),
      ),
      @gallery.sample(
        "Combobox",
        @ui.stack([
          @ui.combobox(
            context,
            id="data-combobox",
            label="Choose technology",
            options~,
          ),
          @ui.combobox_provider(
            context,
            id="data-combobox-multiple",
            options~,
            multiple=true,
          ),
        ]),
      ),
      @gallery.sample(
        "Command",
        @ui.stack([
          @ui.command(id="data-command", items=commands),
          @ui.command_dialog(
            context,
            id="data-command-dialog",
            title="Command palette",
            trigger_label="Open command palette",
            on_value_select=set_command_result.map(value => {
              _ => "Selected: " + value
            }),
            render=scope => {
              @minimoon.fragment([
                @ui.command_input(scope),
                @ui.command_list([
                  @ui.command_item(
                    scope,
                    value="save",
                    keywords=["persist", "draft"],
                    @minimoon.text("Save draft (search persist)"),
                  ),
                  @ui.command_item(
                    scope,
                    value="publish",
                    keywords=["release"],
                    @minimoon.text("Publish"),
                  ),
                  @ui.command_item(
                    scope,
                    value="locked",
                    keywords=["release"],
                    disabled=true,
                    @minimoon.text("Disabled action"),
                  ),
                ]),
              ])
            },
          ),
          command_result.map(value => @minimoon.p(value)),
        ]),
      ),
      @gallery.sample(
        "Data Table",
        @ui.data_table(
          id="data-table",
          rows~,
          columns=[
            @ui.data_column(
              key="id",
              label="ID",
              hideable=false,
              searchable=false,
              text=(row : (String, String, Int)) => row.0,
            ),
            @ui.data_column(key="name", label="Name", text=(
              row : (String, String, Int),
            ) => row.1),
            @ui.data_column(
              key="count",
              label="Count",
              text=(row : (String, String, Int)) => row.2.to_string(),
              numeric_value=row => row.2.to_double(),
            ),
          ],
          row_key=row => row.0,
          page_size=2,
        ),
      ),
      @gallery.sample(
        "Date Picker",
        @ui.date_picker(
          context,
          id="data-date-picker",
          label="Pick a date",
          initial_month=month,
          selected=date,
          on_change=set_date.map(value => _ => value),
          today=month,
          presets=[
            @ui.date_picker_preset(label="Reference today", value=month),
            @ui.date_picker_preset(label="Tomorrow", value=month.add_days(1)),
          ],
        ),
      ),
      @gallery.sample(
        "Pagination",
        @ui.pagination(
          id="data-pagination",
          total=@minimoon.Val::constant(77),
          page_size=10,
        ),
      ),
      @gallery.display(
        "Table",
        @minimoon.div([
          @ui.table([
            @ui.table_caption("A simple semantic table"),
            @ui.table_header(
              @ui.table_row([
                @ui.table_head("Framework"),
                @ui.table_head("Target"),
              ]),
            ),
            @ui.table_body(
              @ui.table_row([
                @ui.table_cell("Minimoon"),
                @ui.table_cell("Skyline"),
              ]),
            ),
            @ui.table_footer(
              @ui.table_row([@ui.table_cell("Total"), @ui.table_cell("1")]),
            ),
          ]),
          @ui.table_spanning(columns=3, row_height=48, min_width=300, rows=[
            [
              @ui.table_span_head("Two columns", colspan=2),
              @ui.table_span_head("Two rows", rowspan=2),
            ],
            [@ui.table_span_cell("Left"), @ui.table_span_cell("Right")],
          ]),
        ]),
      ),
    ])
  })
}
