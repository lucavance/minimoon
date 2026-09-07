///|
pub fn[C : @minimoon.IsChildren] badge_link(
  on_tap~ : @minimoon.Cmd,
  variant? : Tone = Default,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant=Link,
    class="mmui-badge-link " + class,
    badge(variant~, children),
  )
}

///|
pub fn[C : @minimoon.IsChildren] breadcrumb_link(
  on_tap~ : @minimoon.Cmd,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant=Link,
    class="mmui-breadcrumb-link " + class,
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] bubble_content_link(
  on_tap~ : @minimoon.Cmd,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant=Link,
    class="mmui-bubble-content-link " + class,
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] bubble_content_button(
  on_tap~ : @minimoon.Cmd,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant=Link,
    class="mmui-bubble-content-button " + class,
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] item_link(
  on_tap~ : @minimoon.Cmd,
  variant? : Tone = Default,
  size? : Size = Medium,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant=Link,
    class="mmui-item-link " + class,
    item(variant~, size~, children),
  )
}

///|
pub fn[C : @minimoon.IsChildren] marker_link(
  on_tap~ : @minimoon.Cmd,
  variant? : MarkerVariant = PlainMarker,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant=Link,
    class="mmui-marker-link " + class,
    marker(variant~, children),
  )
}

///|
pub fn[C : @minimoon.IsChildren] input_group_button(
  variant? : ButtonVariant = Ghost,
  size? : ButtonSize = Sm,
  on_tap~ : @minimoon.Cmd,
  disabled? : Bool = false,
  id? : String = "",
  class? : String = "",
  children : C,
) -> @minimoon.Node {
  button(
    on_tap~,
    disabled~,
    id~,
    variant~,
    size~,
    class="mmui-input-group-button " + class,
    children,
  )
}

///|
pub fn button_group_separator(
  orientation? : Orientation = Vertical,
) -> @minimoon.Node {
  separator(orientation~)
}

///|
pub fn item_separator() -> @minimoon.Node {
  separator()
}

///|
pub fn input_otp_separator() -> @minimoon.Node {
  @minimoon.span(class="mmui-input-otp-separator", "−")
}

///|
pub fn select_separator() -> @minimoon.Node {
  separator()
}
