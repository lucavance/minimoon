///|
/// Native attachment states and slots adapted from RUI 0.1.1 (MIT).
pub(all) enum AttachmentState {
  AttachmentIdle
  AttachmentUploading
  AttachmentProcessing
  AttachmentError
  AttachmentDone
} derive(Eq, Debug)

///|
pub(all) enum AttachmentSize {
  AttachmentDefaultSize
  AttachmentSm
  AttachmentXs
} derive(Eq, Debug)

///|
pub fn[C : @minimoon.IsChildren] attachment(
  children : C,
  state? : AttachmentState = AttachmentDone,
  size? : AttachmentSize = AttachmentDefaultSize,
  orientation? : Orientation = Horizontal,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  let state_class = match state {
    AttachmentIdle => "mmui-attachment-idle"
    AttachmentUploading => "mmui-attachment-uploading"
    AttachmentProcessing => "mmui-attachment-processing"
    AttachmentError => "mmui-attachment-error"
    AttachmentDone => "mmui-attachment-done"
  }
  let size_class = match size {
    AttachmentDefaultSize => "mmui-attachment-default"
    AttachmentSm => "mmui-attachment-sm"
    AttachmentXs => "mmui-attachment-xs"
  }
  ui_container(
    "attachment",
    id~,
    class=state_class +
      " " +
      size_class +
      " " +
      orientation_class(orientation) +
      " " +
      class,
    style~,
    semantics=@minimoon.semantics(
      role=@minimoon.GroupRole,
      busy=state == AttachmentUploading || state == AttachmentProcessing,
      invalid=state == AttachmentError,
    ),
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] attachment_group(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  @minimoon.scroll_view(
    id~,
    class="mmui-attachment-group " + class,
    style~,
    scroll_x=true,
    scroll_y=false,
    children,
  )
}

///|
/// Supply a native image URL or rich icon/content; image loading remains native.
pub fn attachment_media(
  src? : String = "",
  alt? : String = "",
  variant? : MediaVariant = ImageMedia,
  content? : @minimoon.Node,
  error? : Bool = false,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "attachment-media",
    id~,
    class=(if variant == ImageMedia {
        "mmui-attachment-image"
      } else {
        "mmui-attachment-icon"
      }) +
      (if error { " mmui-attachment-error" } else { "" }) +
      " " +
      class,
    style~,
    [
      content.unwrap_or(
        if src == "" {
          @minimoon.text("▧")
        } else {
          @minimoon.image(
            src~,
            alt~,
            mode=@minimoon.AspectFit,
            class="mmui-attachment-image-content",
          )
        },
      ),
    ],
  )
}

///|
pub fn[C : @minimoon.IsChildren] attachment_content(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("attachment-content", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] attachment_title(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("attachment-title", id~, class~, style~, children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] attachment_description(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container(
    "attachment-description",
    id~,
    class~,
    style~,
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] attachment_actions(
  children : C,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  ui_container("attachment-actions", id~, class~, style~, children.to_nodes())
}

///|
pub fn attachment_action(
  label~ : String,
  on_tap~ : @minimoon.Cmd,
  content? : @minimoon.Node,
  variant? : ButtonVariant = Ghost,
  size? : ButtonSize = IconSm,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  button(
    on_tap~,
    variant~,
    size~,
    disabled~,
    label~,
    id~,
    class="mmui-attachment-action " + class,
    style~,
    content.unwrap_or(@minimoon.text(label)),
  )
}

///|
pub fn attachment_trigger(
  label~ : String,
  on_tap~ : @minimoon.Cmd,
  content? : @minimoon.Node,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  attachment_action(
    label~,
    on_tap~,
    content?,
    disabled~,
    id~,
    class~,
    style~,
    size=Default,
  )
}

///|
pub fn[C : @minimoon.IsChildren] attachment_trigger_link(
  target~ : @minimoon.Route,
  disabled? : Bool = false,
  label? : String = "",
  id? : String = "",
  children : C,
) -> @minimoon.Node {
  if disabled {
    @minimoon.div(
      id~,
      class="mmui-attachment-trigger mmui-disabled",
      semantics=@minimoon.semantics(
        role=@minimoon.ButtonRole,
        label~,
        disabled=true,
      ),
      children,
    )
  } else {
    @minimoon.navigator(target~, id~, class="mmui-attachment-trigger", children)
  }
}
