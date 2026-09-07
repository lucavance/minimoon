///|
/// Each opening owns its measurement state and effect. Closing disposes that
/// scope, so an old asynchronous result cannot position a reopened surface.
fn floating_bounds(
  context : UiContext,
  id : String,
  open : @minimoon.Val[Bool],
  placement : @headless.Placement,
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
  surface_id? : String,
) -> @minimoon.Val[@headless.Bounds?] {
  @minimoon.Val::map2(open, context.visible, (open, visible) => open && visible).switch_by(
    (active, _) => {
      if !active {
        return @minimoon.Val::constant(None)
      }
      let (bounds, _) = @minimoon.create_state_with_init(
        init=emit => {
          let initial : @headless.Bounds? = None
          (
            initial,
            @minimoon.measure_nodes(
              [
                id + "-trigger",
                surface_id.unwrap_or(id + "-surface"),
                "mmui-viewport",
              ],
              emit,
            ),
          )
        },
        update=(
          previous,
          result : Result[Array[@minimoon.NodeRect?], @minimoon.HostError],
          _,
        ) => {
          @minimoon.no_cmd(
            match result {
              Ok([Some(anchor), Some(surface), Some(viewport)]) =>
                Some(
                  @headless.place(
                    rect_bounds(anchor),
                    rect_bounds(surface),
                    rect_bounds(viewport),
                    placement,
                    gap=side_offset,
                    align_offset~,
                  ),
                )
              _ => previous
            },
          )
        },
      )
      bounds
    },
    by=active => if active { "open" } else { "closed" },
  )
}
