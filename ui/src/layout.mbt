///|
pub fn carousel_controlled(
  id~ : String,
  items~ : @minimoon.Val[Array[Panel]],
  current~ : @minimoon.Val[Int],
  on_change~ : @minimoon.Emit[Int],
  autoplay? : Bool = false,
  circular? : Bool = false,
  vertical? : Bool = false,
  interval? : Int = 5000,
) -> @minimoon.Val[@minimoon.Node] {
  let dispatch = carousel_dispatch(
    items.map(items => items.length()),
    current,
    on_change,
    circular,
  )
  @minimoon.Val::view2(items, current, (items, current) => {
    let current = current.clamp(min=0, max=(items.length() - 1).max(0))
    ui_container("carousel", id~, [
      @minimoon.swiper(
        id=id + "-swiper",
        current~,
        autoplay~,
        circular~,
        vertical~,
        interval~,
        on_change~,
        event_key=id + "/change",
        items.map(item => @minimoon.swiper_item(item_id=item.key, item.content)),
      ),
      ui_container("carousel-controls", [
        @minimoon.button(
          disabled=items.is_empty() || (!circular && current == 0),
          event_key=id + "/previous",
          on_tap=if items.is_empty() || (!circular && current == 0) {
            @minimoon.none
          } else {
            dispatch(Step(-1))
          },
          "Previous slide",
        ),
        @minimoon.button(
          disabled=items.is_empty() ||
            (!circular && current + 1 == items.length()),
          event_key=id + "/next",
          on_tap=if items.is_empty() ||
            (!circular && current + 1 == items.length()) {
            @minimoon.none
          } else {
            dispatch(Step(1))
          },
          "Next slide",
        ),
      ]),
    ])
  })
}

///|
pub fn carousel(
  id~ : String,
  items~ : @minimoon.Val[Array[Panel]],
  autoplay? : Bool = false,
  circular? : Bool = false,
  vertical? : Bool = false,
  interval? : Int = 5000,
) -> @minimoon.Val[@minimoon.Node] {
  let (current, emit) = @minimoon.create_variable(0)
  carousel_controlled(
    id~,
    items~,
    current~,
    on_change=emit.map(value => _ => value),
    autoplay~,
    circular~,
    vertical~,
    interval~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] scroll_area(
  children : C,
  id? : String = "",
  horizontal? : Bool = false,
  vertical? : Bool = true,
  height? : Int = 320,
  on_scroll? : @minimoon.Emit[@minimoon.ScrollDetail],
  on_upper? : @minimoon.Cmd,
  on_lower? : @minimoon.Cmd,
) -> @minimoon.Node {
  @minimoon.scroll_view(
    id~,
    class="mmui-scroll-area",
    scroll_x=horizontal,
    scroll_y=vertical,
    style="height:" + height.max(0).to_string() + "px;",
    on_scroll?,
    on_upper?,
    on_lower?,
    children,
  )
}

///|
pub(all) struct NavigationItem {
  key : String
  label : String
  target : @minimoon.Route
}

///|
pub fn navigation_menu(
  items : Array[NavigationItem],
  id? : String = "",
) -> @minimoon.Node {
  ui_container(
    "navigation-menu",
    id~,
    semantics=@minimoon.semantics(role=@minimoon.NavigationRole),
    items.map(item => {
      @minimoon.navigator(
        id=id + "-" + item.key,
        target=item.target,
        class="mmui-navigation-link",
        item.label,
      )
    }),
  )
}

///|
pub fn sidebar_controlled(
  id~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  collapsed~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  label? : String = "Navigation",
  width? : Int = 256,
) -> @minimoon.Val[@minimoon.Node] {
  @minimoon.Val::view2(content, collapsed, (content, collapsed) => {
    ui_container(
      "sidebar",
      id~,
      style="width:" +
        (if collapsed { 56 } else { width.max(56) }).to_string() +
        "px;",
      semantics=@minimoon.semantics(role=@minimoon.NavigationRole, label~),
      [
        @minimoon.button(
          event_key=id + "/toggle",
          on_tap=on_change(!collapsed),
          semantics=@minimoon.semantics(expanded=!collapsed),
          if collapsed {
            "Expand"
          } else {
            "Collapse"
          },
        ),
        if collapsed {
          @minimoon.nothing()
        } else {
          content
        },
      ],
    )
  })
}

///|
pub fn sidebar(
  id~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  initially_collapsed? : Bool = false,
  label? : String = "Navigation",
  width? : Int = 256,
) -> @minimoon.Val[@minimoon.Node] {
  let (collapsed, emit) = @minimoon.create_variable(initially_collapsed)
  sidebar_controlled(
    id~,
    content~,
    collapsed~,
    on_change=emit.map(value => _ => value),
    label~,
    width~,
  )
}
