///|
pub fn[C : @minimoon.IsChildren] field_set(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "field-set",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] field_legend(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("field-legend", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] field_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "field-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] field_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("field-content", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] field_title(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("field-title", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] field_description(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("field-description", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] field_error(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "field-error",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.AlertRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] field_separator(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("field-separator", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] input_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "input-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] input_group_addon(
  align? : AddonAlign = InlineStart,
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  let alignment = match align {
    InlineStart => "mmui-addon-inline-start"
    InlineEnd => "mmui-addon-inline-end"
    BlockStart => "mmui-addon-block-start"
    BlockEnd => "mmui-addon-block-end"
  }
  ui_container(
    "input-group-addon",
    children.to_nodes(),
    id~,
    class=class + " " + alignment,
    style~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] input_group_text(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("input-group-text", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] input_otp_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "input-otp-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] progress_track(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("progress-track", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] progress_label(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("progress-label", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] select_group(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "select-group",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] select_label(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("select-label", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] select_content(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "select-content",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.ListboxRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] form_item(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("form-item", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] form_control(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("form-control", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] form_description(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container("form-description", children.to_nodes(), id~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] form_message(
  id? : String = "",
  class? : String = "",
  style? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "form-message",
    children.to_nodes(),
    id~,
    class~,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.AlertRole),
  )
}
