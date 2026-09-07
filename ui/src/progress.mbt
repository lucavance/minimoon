///|
pub fn progress(
  value~ : Double,
  min? : Double = 0.0,
  max? : Double = 100.0,
  label? : String = "Progress",
  indeterminate? : Bool = false,
  show_value? : Bool = false,
) -> @minimoon.Node {
  guard value == value && value > -1.0e100 && value < 1.0e100 else {
    abort("progress value must be finite")
  }
  guard min > -1.0e100 && max > min && max < 1.0e100 else {
    abort("progress range must be finite and increasing")
  }
  let percent = (((value - min) / (max - min)).clamp(min=0.0, max=1.0) * 100.0).to_int()
  @minimoon.progress(
    percent~,
    class="mmui-progress",
    show_info=show_value,
    active=indeterminate,
    semantics=@minimoon.semantics(
      role=@minimoon.ProgressbarRole,
      label~,
      value_min=0,
      value_max=100,
      value_now=percent,
      busy=indeterminate,
    ),
  )
}

///|
pub fn progress_indicator(
  value~ : Double,
  min? : Double = 0.0,
  max? : Double = 100.0,
) -> @minimoon.Node {
  progress(value~, min~, max~)
}

///|
pub fn progress_value(
  value~ : Double,
  min? : Double = 0.0,
  max? : Double = 100.0,
  text? : String,
) -> @minimoon.Node {
  guard min > -1.0e100 && max > min && max < 1.0e100 else {
    abort("progress range must be finite and increasing")
  }
  @minimoon.span(
    class="mmui-progress-value",
    text.unwrap_or(
      (((value - min) / (max - min)).clamp(min=0.0, max=1.0) * 100.0)
      .to_int()
      .to_string() +
      "%",
    ),
  )
}
