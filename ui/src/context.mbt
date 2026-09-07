///|
/// Page-owned UI lifetime; created only by `root` inside a Page builder.
struct UiContext {
  page : @minimoon.PageContext
  visible : @minimoon.Val[Bool]
  toasts : ToastQueue
}

///|
pub fn UiContext::visible(self : UiContext) -> @minimoon.Val[Bool] {
  self.visible
}

///|
pub fn root(
  page : @minimoon.PageContext,
  build : (UiContext) -> @minimoon.Val[@minimoon.Node],
  theme? : @minimoon.Val[@theme.Theme] = @minimoon.Val::constant(@theme.theme()),
  toast_limit? : Int = 5,
) -> @minimoon.Val[@minimoon.Node] {
  guard toast_limit > 0 && toast_limit <= 100 else {
    abort("toast limit must be between 1 and 100")
  }
  let (visible, _) = @minimoon.create_state(
    true,
    update=(_, next, _) => @minimoon.no_cmd(next),
    subscriptions=(_, emit) => {
      @minimoon.Sub::batch([page.on_hide(emit(false)), page.on_show(emit(true))])
    },
  )
  let context = UiContext::{
    page,
    visible,
    toasts: create_toast_queue(page, visible, toast_limit),
  }
  @minimoon.Val::view2(theme, build(context), (theme, content) => {
    @minimoon.layer_root(class=theme.class_name(), style=theme.style(), [
      content,
      @minimoon.div(
        id="mmui-viewport",
        style="position:fixed;left:0;top:0;width:100vw;height:100vh;pointer-events:none;",
        semantics=@minimoon.semantics(hidden=true),
        @minimoon.nothing(),
      ),
    ])
  })
}

///|
/// Combine independently owned components without allocating state in a view.
pub fn stack(
  children : Array[@minimoon.Val[@minimoon.Node]],
) -> @minimoon.Val[@minimoon.Node] {
  let mut result = @minimoon.Val::constant(@minimoon.nothing())
  for child in children {
    result = @minimoon.Val::view2(result, child, (left, right) => {
      @minimoon.fragment([left, right])
    })
  }
  result
}
