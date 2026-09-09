///|
/// Same capability scenario, with a distinct page-owned model and effects.
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="capabilities",
    route=@minimoon.route("pages/capabilities/capabilities"),
    title="能力",
    capabilities=@home.capabilities(),
    build=context => @home.scene(context, "Minimoon", deps, concise=true),
  )
}
