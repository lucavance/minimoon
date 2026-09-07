///|
fn toast_position_style(position : ToastPosition) -> String {
  let top = position is ToastTopLeft ||
    position is ToastTopCenter ||
    position is ToastTopRight
  let left = position is ToastTopLeft || position is ToastBottomLeft
  let center = position is ToastTopCenter || position is ToastBottomCenter
  "position:fixed;width:360px;max-width:calc(100vw - 24px);" +
  (if top { "top:12px;bottom:auto;" } else { "bottom:24px;top:auto;" }) +
  (if center {
    "left:50%;right:auto;transform:translateX(-50%);"
  } else if left {
    "left:12px;right:auto;"
  } else {
    "right:12px;left:auto;"
  })
}

///|
fn toast_variant_style(variant : ToastVariant, rich : Bool) -> String {
  match variant {
    ToastDefault => ""
    ToastDestructive =>
      "border-color:var(--mmui-destructive);color:var(--mmui-destructive);" +
      (if rich { "background:var(--mmui-muted);" } else { "" })
    ToastSuccess =>
      if rich {
        "border-color:#16a34a;color:#166534;background:#f0fdf4;"
      } else {
        "border-color:#16a34a;"
      }
  }
}

///|
pub fn dismiss_all_toasts(context : UiContext) -> @minimoon.Cmd {
  (context.toasts.emit)(Clear)
}

///|
pub fn[C : @minimoon.IsChildren] toast_surface(
  children : C,
  variant? : ToastVariant = ToastDefault,
  open? : Bool = true,
  id? : String = "",
) -> @minimoon.Node {
  if open {
    ui_container(
      "toast",
      id~,
      style=toast_variant_style(variant, false),
      semantics=@minimoon.semantics(role=@minimoon.StatusRole, live="polite"),
      children.to_nodes(),
    )
  } else {
    @minimoon.nothing()
  }
}

///|
pub fn toast_title(text : String) -> @minimoon.Node {
  ui_container("toast-title", [@minimoon.text(text)])
}

///|
pub fn toast_description(text : String) -> @minimoon.Node {
  ui_container("toast-description", [@minimoon.text(text)])
}

///|
pub fn[C : @minimoon.IsChildren] toast_action(
  on_tap~ : @minimoon.Cmd,
  children : C,
) -> @minimoon.Node {
  @minimoon.button_children(on_tap~, class="mmui-toast-action", children)
}

///|
pub fn toast_close(
  context : UiContext,
  id~ : String,
  label? : String = "Dismiss",
) -> @minimoon.Node {
  @minimoon.button(
    on_tap=dismiss_toast(context, id),
    class="mmui-toast-close",
    label,
  )
}
