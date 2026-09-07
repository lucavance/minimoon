///|
/// Compound content slots adapted from RUI 0.1.1 (MIT); content remains application-owned.
pub fn[C : @minimoon.IsChildren] alert_title(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "alert-title",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] alert_description(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("alert-description", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] alert_action(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("alert-action", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] avatar_fallback(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("avatar-fallback", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] avatar_badge(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("avatar-badge", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] avatar_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "avatar-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] avatar_group_count(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("avatar-group-count", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] breadcrumb_list(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("breadcrumb-list", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] breadcrumb_item(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("breadcrumb-item", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] breadcrumb_page(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("breadcrumb-page", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] bubble_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("bubble-group", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] bubble_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("bubble-content", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] bubble_reactions(
  side? : ReactionSide = ReactionBottom,
  alignment? : Alignment = Start,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "bubble-reactions",
    children.to_nodes(),
    id~,
    class=class +
      (if side == ReactionTop {
        " mmui-reactions-top"
      } else {
        " mmui-reactions-bottom"
      }) +
      (match alignment {
        Start => " mmui-start"
        Center => " mmui-center"
        End => " mmui-end"
      }),
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] button_group_text(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("button-group-text", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] card_header(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("card-header", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] card_title(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "card-title",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] card_description(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("card-description", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] card_action(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("card-action", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] card_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("card-content", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] card_footer(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("card-footer", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] empty(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("empty", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] empty_header(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("empty-header", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] empty_media(
  variant? : MediaVariant = PlainMedia,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "empty-media",
    children.to_nodes(),
    id~,
    class=class + " " + media_class(variant),
    style~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] empty_title(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "empty-title",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] empty_description(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("empty-description", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] empty_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("empty-content", children.to_nodes(), id~, class~, style~)
}
