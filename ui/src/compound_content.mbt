///|
pub fn[C : @minimoon.IsChildren] item_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "item-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] item_media(
  variant? : MediaVariant = PlainMedia,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "item-media",
    children.to_nodes(),
    id~,
    class=class + " " + media_class(variant),
    style~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] item_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("item-content", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] item_title(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("item-title", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] item_description(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("item-description", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] item_actions(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "item-actions",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] item_header(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("item-header", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] item_footer(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("item-footer", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] kbd(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("kbd", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] kbd_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "kbd-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] marker_icon(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("marker-icon", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] marker_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("marker-content", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] message_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("message-group", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] message_avatar(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("message-avatar", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] message_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("message-content", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] message_header(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("message-header", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] message_footer(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("message-footer", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] typography_h1(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "typography-h1",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] typography_h2(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "typography-h2",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] typography_h3(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "typography-h3",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] typography_h4(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "typography-h4",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] typography_p(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("typography-p", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] typography_blockquote(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "typography-blockquote",
    children.to_nodes(),
    id~,
    class~,
    style~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] typography_list(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("typography-list", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] typography_inline_code(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "typography-inline-code",
    children.to_nodes(),
    id~,
    class~,
    style~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] typography_lead(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("typography-lead", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] typography_large(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("typography-large", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] typography_small(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("typography-small", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] typography_muted(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("typography-muted", children.to_nodes(), id~, class~, style~)
}
