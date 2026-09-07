///|
/// Touch-native compound sidebar adapted from RUI b1291945 (MIT).
pub(all) enum SidebarSide {
  SidebarLeft
  SidebarRight
} derive(Eq, Debug)

///|
pub(all) enum SidebarVariant {
  SidebarDefault
  SidebarFloating
  SidebarInset
} derive(Eq, Debug)

///|
pub(all) enum SidebarCollapsible {
  SidebarOffcanvas
  SidebarIcon
  SidebarFixed
} derive(Eq, Debug)

///|
pub(all) enum SidebarMenuButtonSize {
  SidebarMenuSm
  SidebarMenuDefault
  SidebarMenuLg
} derive(Eq, Debug)

///|
pub(all) enum SidebarMenuButtonVariant {
  SidebarMenuButtonDefault
  SidebarMenuButtonOutline
} derive(Eq, Debug)

///|
pub(all) struct SidebarState {
  collapsed : Bool
  mobile_open : Bool
  width : Double
} derive(Eq, Debug)

///|
pub fn sidebar_state(
  collapsed? : Bool = false,
  mobile_open? : Bool = false,
  width? : Double = 256.0,
) -> SidebarState {
  guard width > 0.0 && width - width == 0.0 else {
    abort("sidebar width must be finite and positive")
  }
  { collapsed, mobile_open, width, }
}

///|
priv struct SidebarRailDrag {
  pointer : Int
  start : Double
  initial : Double
  minimum : Double
  maximum : Double
  side : SidebarSide
  moved : Bool
} derive(Eq)

///|
priv struct SidebarTooltip {
  id : String
  side : Side
  align : Alignment
  gap : Double
  offset : Double
  bounds : @headless.Bounds?
} derive(Eq)

///|
priv struct SidebarTransient {
  token : Int
  drag : SidebarRailDrag?
  suppress_tap : Bool
  tooltip : SidebarTooltip?
} derive(Eq)

///|
priv enum SidebarMsg {
  SetCollapsed(Bool)
  SetMobile(Bool)
  ToggleCollapsed
  ToggleMobile
  SetWidth(Double)
  RailTap
  RailStart(SidebarSide, Double, Double, @minimoon.TouchDetail)
  RailMove(@minimoon.TouchDetail)
  RailEnd(@minimoon.TouchDetail)
  RailCancel(@minimoon.TouchDetail)
  Hide
  ClearTransient
  ShowTooltip(SidebarTooltip)
  CloseTooltip
  TooltipMeasured(Int, Result[Array[@minimoon.NodeRect?], @minimoon.HostError])
}

///|
struct SidebarScope {
  id : String
  state : SidebarState
  visible : Bool
  transient : SidebarTransient
  send : @minimoon.Emit[SidebarMsg]
}

///|
/// Explicit rendering context replaces browser ancestor lookup and CSS selectors.
struct SidebarSurfaceScope {
  owner : SidebarScope
  side : SidebarSide
  variant : SidebarVariant
  collapsible : SidebarCollapsible
  mobile : Bool
}

///|
pub fn sidebar_is_collapsed(scope : SidebarScope) -> Bool {
  scope.state.collapsed
}

///|
pub fn sidebar_is_mobile_open(scope : SidebarScope) -> Bool {
  scope.state.mobile_open
}

///|
pub fn sidebar_width(scope : SidebarScope) -> Double {
  scope.state.width
}

///|
pub fn sidebar_expand(scope : SidebarScope) -> @minimoon.Cmd {
  (scope.send)(SetCollapsed(false))
}

///|
pub fn sidebar_collapse(scope : SidebarScope) -> @minimoon.Cmd {
  (scope.send)(SetCollapsed(true))
}

///|
pub fn sidebar_open_mobile(scope : SidebarScope) -> @minimoon.Cmd {
  (scope.send)(SetMobile(true))
}

///|
pub fn sidebar_close_mobile(scope : SidebarScope) -> @minimoon.Cmd {
  (scope.send)(SetMobile(false))
}

///|
pub fn sidebar_set_width(scope : SidebarScope, width : Double) -> @minimoon.Cmd {
  guard width > 0.0 && width - width == 0.0 else {
    abort("sidebar width must be finite and positive")
  }
  (scope.send)(SetWidth(width))
}

///|
fn sidebar_tooltip_bounds(
  tip : SidebarTooltip,
  anchor : @minimoon.NodeRect,
  surface : @minimoon.NodeRect,
  window : @minimoon.NodeRect,
) -> @headless.Bounds {
  let horizontal = tip.side == Left || tip.side == Right
  let mut left = match tip.side {
    Left => anchor.left - surface.width - tip.gap
    Right => anchor.right + tip.gap
    _ => anchor.left
  }
  let mut top = match tip.side {
    Top => anchor.top - surface.height - tip.gap
    Bottom => anchor.bottom + tip.gap
    _ => anchor.top
  }
  if horizontal {
    if left < window.left {
      left = anchor.right + tip.gap
    } else if left + surface.width > window.right {
      left = anchor.left - surface.width - tip.gap
    }
    top = (match tip.align {
        Start => anchor.top
        Center => anchor.top + (anchor.height - surface.height) / 2.0
        End => anchor.bottom - surface.height
      }) +
      tip.offset
  } else {
    if top < window.top {
      top = anchor.bottom + tip.gap
    } else if top + surface.height > window.bottom {
      top = anchor.top - surface.height - tip.gap
    }
    left = (match tip.align {
        Start => anchor.left
        Center => anchor.left + (anchor.width - surface.width) / 2.0
        End => anchor.right - surface.width
      }) +
      tip.offset
  }
  {
    left: left
    .max(window.left)
    .min((window.right - surface.width).max(window.left)),
    top: top
    .max(window.top)
    .min((window.bottom - surface.height).max(window.top)),
    width: surface.width.min(window.width),
    height: surface.height.min(window.height),
  }
}
