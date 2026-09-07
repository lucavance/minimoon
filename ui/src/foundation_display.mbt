///|
pub fn[C : @minimoon.IsChildren] avatar(
  size? : Size = Medium,
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "avatar",
    children.to_nodes(),
    class=size_class(size) + " " + class,
  )
}

///|
pub fn avatar_image(
  src~ : String,
  alt? : String = "",
  on_load? : @minimoon.Emit[@minimoon.ImageLoadDetail],
  on_error? : @minimoon.Emit[String],
  id? : String = "",
) -> @minimoon.Node {
  @minimoon.image(
    src~,
    alt~,
    on_load?,
    on_error?,
    id~,
    mode=@minimoon.AspectFill,
    class="mmui-avatar-image",
  )
}

///|
/// RUI image lifecycle is scoped by source; late events from an old source are inert.
pub(all) enum AvatarImageStatus {
  AvatarLoading
  AvatarLoaded
  AvatarError
} derive(Eq, Debug)

///|
pub fn[C : @minimoon.IsChildren] avatar_with_fallback(
  src~ : @minimoon.Val[String],
  alt? : String = "",
  size? : Size = Medium,
  id? : String = "",
  on_status_change? : @minimoon.Emit[AvatarImageStatus],
  fallback : C,
) -> @minimoon.Val[@minimoon.Node] {
  let nodes = fallback.to_nodes()
  src.switch_by(
    (source, _) => {
      let initial = if source == "" { AvatarError } else { AvatarLoading }
      let (status, emit) = @minimoon.create_state_with_init(
        init=_ => {
          (
            initial,
            on_status_change
            .map(notify => notify(initial))
            .unwrap_or(@minimoon.none),
          )
        },
        update=(previous, next : AvatarImageStatus, _) => {
          (
            next,
            if previous == next {
              @minimoon.none
            } else {
              on_status_change
              .map(notify => notify(next))
              .unwrap_or(@minimoon.none)
            },
          )
        },
      )
      status.map(status => {
        avatar(size~, [
          if status == AvatarLoaded {
            @minimoon.nothing()
          } else {
            avatar_fallback(nodes)
          },
          if status == AvatarError {
            @minimoon.nothing()
          } else {
            @minimoon.image(
              id~,
              class="mmui-avatar-image",
              mode=@minimoon.AspectFill,
              load_key=if id == "" {
                ""
              } else {
                id + "/image/" + source + "/load"
              },
              error_key=if id == "" {
                ""
              } else {
                id + "/image/" + source + "/error"
              },
              style="position:absolute;left:0;top:0;" +
                (if status == AvatarLoaded { "" } else { "opacity:0;" }),
              src=source,
              alt~,
              on_error=emit.map(_ => AvatarError),
              on_load=emit.map(_ => AvatarLoaded),
            )
          },
        ])
      })
    },
    by=source => "avatar:" + source,
  )
}

///|
pub fn[C : @minimoon.IsChildren] badge(
  variant? : Tone = Default,
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "badge",
    children.to_nodes(),
    class=tone_class(variant) + " " + class,
  )
}

///|
pub fn[C : @minimoon.IsChildren] card(
  size? : Size = Medium,
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "card",
    children.to_nodes(),
    class=size_class(size) + " " + class,
  )
}

///|
pub fn[C : @minimoon.IsChildren] breadcrumb(
  label? : String = "Breadcrumb",
  children : C,
) -> @minimoon.Node {
  ui_container(
    "breadcrumb",
    children.to_nodes(),
    semantics=@minimoon.semantics(role=@minimoon.NavigationRole, label~),
  )
}

///|
pub fn breadcrumb_separator() -> @minimoon.Node {
  @minimoon.span(
    class="mmui-breadcrumb-separator",
    semantics=@minimoon.semantics(hidden=true),
    "/",
  )
}

///|
pub fn breadcrumb_ellipsis() -> @minimoon.Node {
  @minimoon.span(
    class="mmui-breadcrumb-ellipsis",
    semantics=@minimoon.semantics(label="More pages"),
    "…",
  )
}

///|
pub fn[C : @minimoon.IsChildren] bubble(
  variant? : Tone = Secondary,
  alignment? : Alignment = Start,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "bubble",
    children.to_nodes(),
    class=tone_class(variant) +
      " " +
      (match alignment {
        Start => "mmui-start"
        Center => "mmui-center"
        End => "mmui-end"
      }),
  )
}

///|
pub fn[C : @minimoon.IsChildren] item(
  variant? : Tone = Default,
  size? : Size = Medium,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "item",
    children.to_nodes(),
    class=tone_class(variant) + " " + size_class(size),
  )
}

///|
pub fn[C : @minimoon.IsChildren] marker(
  variant? : MarkerVariant = PlainMarker,
  children : C,
) -> @minimoon.Node {
  let nodes = children.to_nodes()
  ui_container(
    "marker",
    if variant == SeparatorMarker {
      [separator(), @minimoon.fragment(nodes), separator()]
    } else {
      nodes
    },
    class=if variant == BorderMarker { "mmui-marker-border" } else { "" },
  )
}

///|
pub fn[C : @minimoon.IsChildren] message(
  alignment? : Alignment = Start,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "message",
    children.to_nodes(),
    class=match alignment {
      Start => "mmui-start"
      Center => "mmui-center"
      End => "mmui-end"
    },
  )
}

///|
pub fn[C : @minimoon.IsChildren] label(
  for_id~ : String,
  required? : Bool = false,
  disabled? : Bool = false,
  children : C,
) -> @minimoon.Node {
  let nodes = children.to_nodes().copy()
  if required {
    nodes.push(@minimoon.span(class="mmui-required", " *"))
  }
  @minimoon.label(
    for_id~,
    class="mmui-label" + (if disabled { " mmui-disabled" } else { "" }),
    nodes,
  )
}

///|
pub fn separator(
  orientation? : Orientation = Horizontal,
  decorative? : Bool = true,
) -> @minimoon.Node {
  ui_container(
    "separator",
    [],
    class=orientation_class(orientation),
    semantics=@minimoon.semantics(
      role=@minimoon.SeparatorRole,
      hidden=decorative,
      orientation=match orientation {
        Horizontal => "horizontal"
        Vertical => "vertical"
      },
    ),
  )
}

///|
pub fn skeleton(
  width? : Int = 100,
  height? : Int = 20,
  round? : Bool = false,
) -> @minimoon.Node {
  guard width >= 0 && height >= 0 else {
    abort("skeleton dimensions must be nonnegative")
  }
  ui_container(
    "skeleton",
    [],
    style="width:" +
      width.to_string() +
      "px;height:" +
      height.to_string() +
      "px;" +
      (if round { "border-radius:9999px;" } else { "" }),
    semantics=@minimoon.semantics(hidden=true),
  )
}

///|
pub fn spinner(
  label? : String = "Loading",
  size? : Size = Medium,
) -> @minimoon.Node {
  ui_container(
    "spinner",
    [@minimoon.text("◌")],
    class=size_class(size),
    semantics=@minimoon.semantics(role=@minimoon.StatusRole, label~, busy=true),
  )
}
