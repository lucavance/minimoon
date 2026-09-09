///|
/// Inject host layout without changing route input or creating a new page.
/// Hidden pages apply it together with their next onShow transaction.
pub fn TestRuntime::update_layout(
  self : TestRuntime,
  layout : @minimoon.PageLayout,
) -> String {
  self.runtime.update_layout(layout)
}
