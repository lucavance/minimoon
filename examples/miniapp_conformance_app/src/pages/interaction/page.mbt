///|
/// Reuse the ordinary Lab builder, never a Lab runtime or its live state.
pub fn program(_deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="interaction",
    route=@minimoon.route("pages/interaction/interaction"),
    title="交互",
    capabilities=[@minimoon.NavigateBack, @minimoon.RedirectTo],
    build=context => @lab.scene(context, "tab", concise=true),
  )
}
