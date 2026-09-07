///|
/// RUI 0.1.1 / Rabbita b1291945 native adaptation. MIT, see THIRD_PARTY_NOTICES.md.
pub(all) enum ButtonVariant {
  Default
  Outline
  Secondary
  Ghost
  Destructive
  Link
} derive(Eq, Debug)

///|
pub(all) enum ButtonSize {
  Default
  Xs
  Sm
  Lg
  Icon
  IconXs
  IconSm
  IconLg
} derive(Eq, Debug)

///|
pub(all) enum Tone {
  Default
  Secondary
  Outline
  Destructive
  Muted
  Tinted
  Ghost
  Link
} derive(Eq, Debug)

///|
pub(all) enum ReactionSide {
  ReactionTop
  ReactionBottom
} derive(Eq, Debug)

///|
pub(all) enum MarkerVariant {
  PlainMarker
  SeparatorMarker
  BorderMarker
} derive(Eq, Debug)

///|
pub(all) enum MediaVariant {
  PlainMedia
  IconMedia
  ImageMedia
} derive(Eq, Debug)

///|
pub(all) enum AddonAlign {
  InlineStart
  InlineEnd
  BlockStart
  BlockEnd
} derive(Eq, Debug)

///|
pub(all) enum Size {
  Small
  Medium
  Large
} derive(Eq, Debug)

///|
pub(all) enum Orientation {
  Horizontal
  Vertical
} derive(Eq, Debug)

///|
pub(all) enum Alignment {
  Start
  Center
  End
} derive(Eq, Debug)

///|
fn tone_class(value : Tone) -> String {
  "mmui-" +
  (match value {
    Default => "default"
    Secondary => "secondary"
    Outline => "outline"
    Destructive => "destructive"
    Muted => "muted"
    Tinted => "tinted"
    Ghost => "ghost"
    Link => "link"
  })
}

///|
fn size_class(value : Size) -> String {
  "mmui-" +
  (match value {
    Small => "small"
    Medium => "medium"
    Large => "large"
  })
}

///|
fn media_class(value : MediaVariant) -> String {
  match value {
    PlainMedia => "mmui-media-plain"
    IconMedia => "mmui-media-icon"
    ImageMedia => "mmui-media-image"
  }
}

///|
fn orientation_class(value : Orientation) -> String {
  match value {
    Horizontal => "mmui-horizontal"
    Vertical => "mmui-vertical"
  }
}

///|
pub fn[C : @minimoon.IsChildren] button(
  on_tap? : @minimoon.Cmd = @minimoon.none,
  variant? : ButtonVariant = Default,
  size? : ButtonSize = Default,
  disabled? : Bool = false,
  form_type? : @minimoon.FormButtonType,
  id? : String = "",
  event_key? : String = "",
  class? : String = "",
  style? : String = "",
  label? : String = "",
  children : C,
) -> @minimoon.Node {
  let variant_name = match variant {
    Default => "default"
    Outline => "outline"
    Secondary => "secondary"
    Ghost => "ghost"
    Destructive => "destructive"
    Link => "link"
  }
  let size_name = match size {
    Default => "default"
    Xs => "xs"
    Sm => "sm"
    Lg => "lg"
    Icon => "icon"
    IconXs => "icon-xs"
    IconSm => "icon-sm"
    IconLg => "icon-lg"
  }
  @minimoon.button_children(
    on_tap=if disabled { @minimoon.none } else { on_tap },
    disabled~,
    form_type?,
    id~,
    event_key~,
    class="mmui-button mmui-button-" +
      variant_name +
      " mmui-button-" +
      size_name +
      " " +
      class,
    style~,
    semantics=@minimoon.semantics(role=@minimoon.ButtonRole, label~, disabled~),
    children,
  )
}

///|
pub fn theme(
  value : @minimoon.Val[@theme.Theme],
  content : @minimoon.Val[@minimoon.Node],
) -> @minimoon.Val[@minimoon.Node] {
  @minimoon.Val::map2(value, content, (theme, node) => {
    @minimoon.div(class=theme.class_name(), style=theme.style(), [node])
  })
}

///|
pub fn[C : @minimoon.IsChildren] direction(
  value : @theme.TextDirection,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "direction",
    children.to_nodes(),
    class=match value {
      @theme.Ltr => "mmui-ltr"
      @theme.Rtl => "mmui-rtl"
    },
  )
}

///|
pub fn[C : @minimoon.IsChildren] alert(
  variant? : Tone = Default,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "alert",
    children.to_nodes(),
    id~,
    class=tone_class(variant) + " " + class,
    semantics=@minimoon.semantics(role=@minimoon.AlertRole),
  )
}

///|
pub fn[C : @minimoon.IsChildren] aspect_ratio(
  ratio? : Double = 1.0,
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  guard ratio > 0.0 && ratio < 1000000.0 else {
    abort("aspect ratio must be finite and positive")
  }
  ui_container(
    "aspect-ratio",
    [ui_container("aspect-ratio-content", children.to_nodes())],
    class~,
    style="position:relative;width:100%;padding-top:" +
      (100.0 / ratio).to_string() +
      "%;",
  )
}

///|
pub fn[C : @minimoon.IsChildren] button_group(
  orientation? : Orientation = Horizontal,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "button-group",
    children.to_nodes(),
    class=orientation_class(orientation),
    semantics=@minimoon.semantics(role=@minimoon.GroupRole),
  )
}
