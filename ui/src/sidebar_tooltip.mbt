///|
/// Long press and the adjacent Help action replace hover, without nested buttons.
pub fn[C : @minimoon.IsChildren] sidebar_menu_button_with_tooltip(
  scope : SidebarSurfaceScope,
  id~ : String,
  tooltip~ : String,
  children : C,
  target? : @minimoon.Route,
  is_active? : Bool = false,
  variant? : SidebarMenuButtonVariant = SidebarMenuButtonDefault,
  size? : SidebarMenuButtonSize = SidebarMenuDefault,
  disabled? : Bool = false,
  aria_label? : String = "",
  on_tap? : @minimoon.Cmd,
  icon? : @minimoon.Node,
  tooltip_side? : Side = Right,
  tooltip_align? : Alignment = Center,
  tooltip_side_offset? : Double = 4.0,
  tooltip_align_offset? : Double = 0.0,
  tooltip_show_arrow? : Bool = true,
  class? : String = "",
) -> @minimoon.Node {
  let eligible = sidebar_icon_only(scope) && !disabled && scope.owner.visible
  let show = if eligible {
    (scope.owner.send)(
      ShowTooltip({
        id,
        side: tooltip_side,
        align: tooltip_align,
        gap: tooltip_side_offset,
        offset: tooltip_align_offset,
        bounds: None,
      }),
    )
  } else {
    @minimoon.none
  }
  let button = sidebar_menu_button(
    scope,
    id~,
    event_key=id + "/action",
    children,
    target?,
    is_active~,
    variant~,
    size~,
    disabled~,
    aria_label=if aria_label == "" { tooltip } else { aria_label },
    on_tap?,
    icon?,
    class~,
  )
  let tip = match scope.owner.transient.tooltip {
    Some(tip) if tip.id == id && eligible =>
      @minimoon.layer(id=id + "-tooltip-layer", [
        @minimoon.tap_view(
          on_tap=(scope.owner.send)(CloseTooltip),
          event_key=id + "/tooltip-dismiss",
          style="position:fixed;left:0;right:0;top:0;bottom:0;",
          @minimoon.nothing(),
        ),
        ui_container(
          "sidebar-tooltip",
          id=id + "-tooltip",
          class="mmui-surface",
          style=surface_style(TooltipSurface, tip.bounds),
          semantics=@minimoon.semantics(role=@minimoon.TooltipRole),
          [
            if tooltip_show_arrow {
              @minimoon.span(semantics=@minimoon.semantics(hidden=true), "◆")
            } else {
              @minimoon.nothing()
            },
            @minimoon.text(tooltip),
            @minimoon.button(
              on_tap=(scope.owner.send)(CloseTooltip),
              event_key=id + "/tooltip-close",
              "Close",
            ),
          ],
        ),
      ])
    _ => @minimoon.nothing()
  }
  @minimoon.fragment([
    @minimoon.touch_view(
      on_long_press=@minimoon.Emit(_ => show),
      event_key=id + "/hint",
      button,
    ),
    if eligible {
      @minimoon.button(
        on_tap=show,
        event_key=id + "/help",
        semantics=@minimoon.semantics(label="Explain " + tooltip),
        "?",
      )
    } else {
      @minimoon.nothing()
    },
    tip,
  ])
}
