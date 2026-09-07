///|
/// Explicit caller-owned date choices; no system clock or browser date object.
pub struct DatePickerPreset {
  label : String
  value : @headless.DateSelection
} derive(Eq, Debug)

///|
pub fn date_picker_preset(
  label~ : String,
  value~ : @headless.CalendarDate,
) -> DatePickerPreset {
  { label, value: @headless.Single(Some(value)), }
}

///|
pub fn date_range_picker_preset(
  label~ : String,
  start~ : @headless.CalendarDate,
  end~ : @headless.CalendarDate,
) -> DatePickerPreset {
  let value = if start.ordinal() <= end.ordinal() {
    @headless.Range(Some(start), Some(end))
  } else {
    @headless.Range(Some(end), Some(start))
  }
  { label, value, }
}

///|
fn selection_label(
  value : @headless.DateSelection,
  placeholder : String,
) -> String {
  match value {
    @headless.Single(Some(date)) => date.iso()
    @headless.Multiple(dates) if !dates.is_empty() =>
      dates.map(date => date.iso()).join(", ")
    @headless.Range(Some(start), Some(end)) => start.iso() + " – " + end.iso()
    @headless.Range(Some(start), None) => start.iso() + " – …"
    _ => placeholder
  }
}

///|
fn selection_start(value : @headless.DateSelection) -> @headless.CalendarDate? {
  match value {
    @headless.Single(date) | @headless.Range(date, _) => date
    @headless.Multiple(dates) => dates.get(0)
  }
}

///|
fn selection_enabled(
  value : @headless.DateSelection,
  disabled_date : (@headless.CalendarDate) -> Bool,
) -> Bool {
  match value {
    @headless.Single(Some(date)) => !disabled_date(date)
    @headless.Multiple(dates) => dates.all(date => !disabled_date(date))
    @headless.Range(Some(start), end) =>
      !disabled_date(start) &&
      end.map(date => !disabled_date(date)).unwrap_or(true)
    _ => true
  }
}

///|
fn selection_complete(value : @headless.DateSelection) -> Bool {
  match value {
    @headless.Single(Some(_)) | @headless.Range(Some(_), Some(_)) => true
    _ => false
  }
}

///|
pub fn date_picker_controlled(
  context : UiContext,
  id~ : String,
  label~ : String,
  initial_month~ : @headless.CalendarDate,
  selected~ : @minimoon.Val[@headless.DateSelection],
  on_change~ : @minimoon.Emit[@headless.DateSelection],
  open~ : @minimoon.Val[Bool],
  on_open_change~ : @minimoon.Emit[Bool],
  disabled_date? : (@headless.CalendarDate) -> Bool = _ => false,
  disabled? : Bool = false,
  today? : @headless.CalendarDate,
  show_outside_days? : Bool = true,
  week_start? : Int = 0,
  presets? : Array[DatePickerPreset] = [],
  format_value? : (@headless.DateSelection) -> String,
  close_on_select? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let (month, set_month) = @minimoon.create_variable(initial_month)
  let active = @minimoon.Val::map2(open, context.visible, (open, visible) => {
    open && visible
  })
  let choose = form_dispatch(active, (active, value : @headless.DateSelection) => {
    if !active || disabled || !selection_enabled(value, disabled_date) {
      return @minimoon.none
    }
    @minimoon.batch([
      on_change(value),
      selection_start(value)
      .map(date => set_month(_ => date))
      .unwrap_or(@minimoon.none),
      if close_on_select && selection_complete(value) {
        on_open_change(false)
      } else {
        @minimoon.none
      },
    ])
  })
  let change_month = form_dispatch(active, (
    active,
    value : @headless.CalendarDate,
  ) => if active && !disabled { set_month(_ => value) } else { @minimoon.none })
  let calendar = calendar_controlled(
    id=id + "-calendar",
    month~,
    on_month_change=change_month,
    selected~,
    on_change=choose,
    disabled_date~,
    disabled~,
    today?,
    show_outside_days~,
    week_start~,
  )
  let preset_nodes = presets.mapi((index, preset) => {
    button(
      disabled=disabled || !selection_enabled(preset.value, disabled_date),
      on_tap=choose(preset.value),
      event_key=id + "/preset/" + index.to_string(),
      preset.label,
    )
  })
  let content = calendar.map(calendar => {
    ui_container("date-picker-content", [
      ui_container("date-picker-presets", preset_nodes),
      calendar,
    ])
  })
  let trigger_label_value = selected.map(value => {
    format_value
    .map(format => format(value))
    .unwrap_or(selection_label(value, label))
  })
  overlay_controlled(
    context,
    id~,
    title=label,
    trigger_label=label,
    trigger_label_value~,
    content~,
    open~,
    on_change=on_open_change,
    kind=PopoverSurface,
    disabled~,
  )
}

///|
pub fn date_picker(
  context : UiContext,
  id~ : String,
  label~ : String,
  initial_month~ : @headless.CalendarDate,
  selected~ : @minimoon.Val[@headless.DateSelection],
  on_change~ : @minimoon.Emit[@headless.DateSelection],
  disabled_date? : (@headless.CalendarDate) -> Bool = _ => false,
  disabled? : Bool = false,
  today? : @headless.CalendarDate,
  show_outside_days? : Bool = true,
  week_start? : Int = 0,
  presets? : Array[DatePickerPreset] = [],
  format_value? : (@headless.DateSelection) -> String,
  initially_open? : Bool = false,
  on_open_change? : @minimoon.Emit[Bool],
  close_on_select? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, set_open) = @minimoon.create_variable(initially_open && !disabled)
  date_picker_controlled(
    context,
    id~,
    label~,
    initial_month~,
    selected~,
    on_change~,
    open~,
    on_open_change=@minimoon.Emit(value => {
      @minimoon.batch([
        set_open(_ => value),
        on_open_change.map(emit => emit(value)).unwrap_or(@minimoon.none),
      ])
    }),
    disabled_date~,
    disabled~,
    today?,
    show_outside_days~,
    week_start~,
    presets~,
    format_value?,
    close_on_select~,
  )
}

///|
/// Range values use the same typed DateSelection as Calendar; incomplete ranges stay open.
pub fn date_range_picker(
  context : UiContext,
  id~ : String,
  label~ : String,
  initial_month~ : @headless.CalendarDate,
  selected~ : @minimoon.Val[@headless.DateSelection],
  on_change~ : @minimoon.Emit[@headless.DateSelection],
  disabled_date? : (@headless.CalendarDate) -> Bool = _ => false,
  disabled? : Bool = false,
  presets? : Array[DatePickerPreset] = [],
  format_value? : (@headless.DateSelection) -> String,
  on_open_change? : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  date_picker(
    context,
    id~,
    label~,
    initial_month~,
    selected~,
    on_change~,
    disabled_date~,
    disabled~,
    presets~,
    format_value?,
    on_open_change?,
  )
}
