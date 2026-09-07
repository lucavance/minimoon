///|
pub fn calendar_controlled(
  id~ : String,
  month~ : @minimoon.Val[@headless.CalendarDate],
  on_month_change~ : @minimoon.Emit[@headless.CalendarDate],
  selected~ : @minimoon.Val[@headless.DateSelection],
  on_change~ : @minimoon.Emit[@headless.DateSelection],
  disabled_date? : (@headless.CalendarDate) -> Bool = _ => false,
  week_start? : Int = 0,
  today? : @headless.CalendarDate,
  show_outside_days? : Bool = true,
  disabled? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  guard week_start >= 0 && week_start <= 6 else {
    abort("calendar week_start must be between 0 and 6")
  }
  let dispatch = form_dispatch(
    @minimoon.Val::map2(month, selected, (month, selected) => (month, selected)),
    (input, request : CalendarRequest) => {
      if disabled {
        return @minimoon.none
      }
      let (month, selected) = input
      match request {
        Choose(date) =>
          if disabled_date(date) {
            @minimoon.none
          } else {
            on_change(selected.choose(date))
          }
        ShiftMonth(delta) => {
          let next = month.add_months(delta)
          if next == month {
            @minimoon.none
          } else {
            on_month_change(next)
          }
        }
      }
    },
  )
  @minimoon.Val::view2(month, selected, (month, selected) => {
    let first = @headless.calendar_date(
      year=month.year,
      month=month.month,
      day=1,
    )
    let offset = (first.weekday() - week_start + 7) % 7
    let first_ordinal = first.ordinal() - offset
    let cells : Array[@minimoon.Node] = []
    for index = 0; index < 42; index = index + 1 {
      let ordinal = first_ordinal + index
      if ordinal < 1 || ordinal > 3652059 {
        cells.push(
          @minimoon.div(
            class="mmui-calendar-empty",
            style="width:14.2857%;min-height:36px;",
            semantics=@minimoon.semantics(hidden=true),
            @minimoon.nothing(),
          ),
        )
        continue
      }
      let date = first.add_days(index - offset)
      let outside = date.month != month.month || date.year != month.year
      if outside && !show_outside_days {
        cells.push(
          @minimoon.div(
            class="mmui-calendar-empty",
            style="width:14.2857%;min-height:36px;",
            semantics=@minimoon.semantics(hidden=true),
            @minimoon.nothing(),
          ),
        )
        continue
      }
      let disabled = disabled || disabled_date(date)
      cells.push(
        @minimoon.button(
          class="mmui-calendar-day" +
            (if selected.contains(date) { " mmui-selected" } else { "" }) +
            (if today == Some(date) { " mmui-calendar-today" } else { "" }) +
            (if outside { " mmui-calendar-outside" } else { "" }),
          style="width:14.2857%;",
          disabled~,
          event_key=id + "/date/" + index.to_string(),
          on_tap=if disabled { @minimoon.none } else { dispatch(Choose(date)) },
          semantics=@minimoon.semantics(
            label=date.iso(),
            selected=selected.contains(date),
            disabled~,
          ),
          date.day.to_string(),
        ),
      )
    }
    ui_container("calendar", id~, [
      ui_container("calendar-header", [
        @minimoon.button(
          event_key=id + "/previous",
          disabled=disabled || (month.year == 1 && month.month == 1),
          on_tap=if disabled || (month.year == 1 && month.month == 1) {
            @minimoon.none
          } else {
            dispatch(ShiftMonth(-1))
          },
          "Previous month",
        ),
        @minimoon.text(month.year.to_string() + "-" + month.month.to_string()),
        @minimoon.button(
          event_key=id + "/next",
          disabled=disabled || (month.year == 9999 && month.month == 12),
          on_tap=if disabled || (month.year == 9999 && month.month == 12) {
            @minimoon.none
          } else {
            dispatch(ShiftMonth(1))
          },
          "Next month",
        ),
      ]),
      ui_container(
        "calendar-weekdays",
        style="display:flex;",
        [0, 1, 2, 3, 4, 5, 6].map(index => {
          @minimoon.div(
            style="width:14.2857%;text-align:center;",
            ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][(
              index + week_start
            ) %
            7],
          )
        }),
      ),
      ui_container("calendar-grid", style="display:flex;flex-wrap:wrap;", cells),
    ])
  })
}

///|
pub fn calendar(
  id~ : String,
  initial_month~ : @headless.CalendarDate,
  initial_selected? : @headless.DateSelection = @headless.Single(None),
  disabled_date? : (@headless.CalendarDate) -> Bool = _ => false,
  week_start? : Int = 0,
  today? : @headless.CalendarDate,
  show_outside_days? : Bool = true,
  disabled? : Bool = false,
  on_select? : @minimoon.Emit[@headless.DateSelection],
  on_month_change? : @minimoon.Emit[@headless.CalendarDate],
) -> @minimoon.Val[@minimoon.Node] {
  let (month, set_month) = @minimoon.create_variable(initial_month)
  let (selected, set_selected) = @minimoon.create_variable(initial_selected)
  calendar_controlled(
    id~,
    month~,
    on_month_change=@minimoon.Emit(value => {
      @minimoon.batch([
        set_month(_ => value),
        on_month_change.map(emit => emit(value)).unwrap_or(@minimoon.none),
      ])
    }),
    selected~,
    on_change=@minimoon.Emit(value => {
      @minimoon.batch([
        set_selected(_ => value),
        on_select.map(emit => emit(value)).unwrap_or(@minimoon.none),
      ])
    }),
    disabled_date~,
    week_start~,
    today?,
    show_outside_days~,
    disabled~,
  )
}
