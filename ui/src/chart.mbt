///|
pub(all) enum ChartIndicator {
  ChartDot
  ChartLine
  ChartDashed
} derive(Eq, Debug)

///|
pub(all) enum ChartLegendPosition {
  LegendTop
  LegendBottom
} derive(Eq, Debug)

///|
pub fn[C : @minimoon.IsChildren] chart_container(
  children : C,
  id? : String = "",
  label? : String = "Chart",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "chart",
    id~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.RegionRole, label~),
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] chart_tooltip(
  children : C,
  visible? : Bool = true,
) -> @minimoon.Node {
  if visible {
    ui_container("chart-tooltip", children.to_nodes())
  } else {
    @minimoon.nothing()
  }
}

///|
pub fn chart_style(colors : Array[(String, String)]) -> String {
  let parts : Array[String] = []
  for entry in colors {
    let (key, color) = entry
    guard key != "" &&
      key
      .iter()
      .all(c => (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-') else {
      abort("chart color key must be a CSS identifier")
    }
    guard color.has_prefix("#") &&
      (color.length() == 4 || color.length() == 7 || color.length() == 9) else {
      abort("chart color must be hexadecimal")
    }
    let chars = color.iter().collect()
    for index = 1; index < chars.length(); index = index + 1 {
      guard "0123456789abcdefABCDEF".contains(chars[index].to_string()) else {
        abort("chart color must be hexadecimal")
      }
    }
    parts.push("--mmui-chart-" + key + ":" + color)
  }
  parts.join(";")
}

///|
pub fn[C : @minimoon.IsChildren] chart_tooltip_content(
  children : C,
  active? : Bool = true,
) -> @minimoon.Node {
  if !active {
    return @minimoon.nothing()
  }
  ui_container(
    "chart-tooltip-content",
    semantics=@minimoon.semantics(role=@minimoon.StatusRole, live="polite"),
    children.to_nodes(),
  )
}

///|
pub fn chart_tooltip_label(label : String) -> @minimoon.Node {
  ui_container("chart-tooltip-label", [@minimoon.text(label)])
}

///|
pub fn chart_tooltip_item(
  label~ : String,
  value~ : String,
  color? : String = "#737373",
  indicator? : ChartIndicator = ChartDot,
) -> @minimoon.Node {
  let style = match indicator {
    ChartDot => "width:10px;height:10px;border-radius:2px;background:" + color
    ChartLine =>
      "width:4px;min-height:16px;align-self:stretch;background:" + color
    ChartDashed => "width:0;height:16px;border-left:1.5px dashed " + color
  }
  ui_container("chart-tooltip-item", [
    @minimoon.div(
      style=style + ";flex-shrink:0;",
      semantics=@minimoon.semantics(hidden=true),
      @minimoon.nothing(),
    ),
    @minimoon.text(label + ": " + value),
  ])
}

///|
pub fn[C : @minimoon.IsChildren] chart_legend(
  children : C,
  position? : ChartLegendPosition = LegendBottom,
) -> @minimoon.Node {
  ui_container(
    "chart-legend",
    style=legend_spacing(position),
    children.to_nodes(),
  )
}

///|
fn legend_spacing(position : ChartLegendPosition) -> String {
  match position {
    LegendTop => "padding-bottom:12px;"
    LegendBottom => "padding-top:12px;"
  }
}

///|
pub fn[C : @minimoon.IsChildren] chart_legend_content(
  children : C,
  position? : ChartLegendPosition = LegendBottom,
) -> @minimoon.Node {
  ui_container(
    "chart-legend-content",
    style=legend_spacing(position),
    children.to_nodes(),
  )
}

///|
pub fn chart_legend_item(
  label~ : String,
  color? : String = "#737373",
) -> @minimoon.Node {
  ui_container("chart-legend-item", [
    @minimoon.span(style="color:" + color, "●"),
    @minimoon.text(label),
  ])
}
