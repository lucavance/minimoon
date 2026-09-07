///|
/// Compound carousel state uses native swiper physics and typed MiniApp events.
struct CarouselScope {
  id : String
  current : Int
  count : Int
  circular : Bool
  orientation : Orientation
  change : @minimoon.Emit[CarouselRequest]
}

///|
priv enum CarouselRequest {
  Target(Int)
  Step(Int)
}

///|
fn carousel_dispatch(
  count : @minimoon.Val[Int],
  current : @minimoon.Val[Int],
  change : @minimoon.Emit[Int],
  circular : Bool,
) -> @minimoon.Emit[CarouselRequest] {
  let input = @minimoon.Val::map2(count, current, (count, current) => {
    (count.max(0), current)
  })
  let (_, emit) = @minimoon.create_state_with_input(
    input~,
    init=(_, _) => @minimoon.no_cmd(()),
    update=(_, input, request : CarouselRequest, _) => {
      let (count, current) = input
      let current = current.clamp(min=0, max=(count - 1).max(0))
      let next = match request {
        Target(index) => index.clamp(min=0, max=(count - 1).max(0))
        Step(delta) =>
          if count <= 1 {
            current
          } else if circular {
            (current + count + delta) % count
          } else {
            (current + delta).clamp(min=0, max=count - 1)
          }
      }
      ((), if next == current { @minimoon.none } else { change(next) })
    },
  )
  emit
}

///|
pub fn carousel_active_index(scope : CarouselScope) -> Int {
  scope.current
}

///|
pub fn carousel_slide_count(scope : CarouselScope) -> Int {
  scope.count
}

///|
pub fn carousel_orientation(scope : CarouselScope) -> Orientation {
  scope.orientation
}

///|
pub fn carousel_is_looping(scope : CarouselScope) -> Bool {
  scope.circular
}

///|
pub fn carousel_can_previous(scope : CarouselScope) -> Bool {
  scope.count > 1 && (scope.circular || scope.current > 0)
}

///|
pub fn carousel_can_next(scope : CarouselScope) -> Bool {
  scope.count > 1 && (scope.circular || scope.current + 1 < scope.count)
}

///|
pub fn carousel_scroll_to(scope : CarouselScope, index : Int) -> @minimoon.Cmd {
  (scope.change)(Target(index))
}

///|
pub fn carousel_scroll_previous(scope : CarouselScope) -> @minimoon.Cmd {
  (scope.change)(Step(-1))
}

///|
pub fn carousel_scroll_next(scope : CarouselScope) -> @minimoon.Cmd {
  (scope.change)(Step(1))
}

///|
pub fn[Input : Eq] carousel_provider_controlled_with_input(
  id~ : String,
  count~ : @minimoon.Val[Int],
  current~ : @minimoon.Val[Int],
  on_change~ : @minimoon.Emit[Int],
  input~ : @minimoon.Val[Input],
  render~ : (CarouselScope, Input) -> @minimoon.Node,
  circular? : Bool = false,
  orientation? : Orientation = Horizontal,
  aria_label? : String = "Carousel",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  let change = carousel_dispatch(count, current, on_change, circular)
  @minimoon.Val::view3(count, current, input, (count, current, input) => {
    let count = count.max(0)
    let current = current.clamp(min=0, max=(count - 1).max(0))
    let scope = CarouselScope::{
      id,
      count,
      current,
      circular,
      orientation,
      change,
    }
    ui_container(
      "carousel",
      id~,
      class~,
      style="position:relative;min-width:0;" + style,
      semantics=@minimoon.semantics(role=@minimoon.RegionRole, label=aria_label),
      [render(scope, input)],
    )
  })
}

///|
pub fn carousel_provider_controlled(
  id~ : String,
  count~ : @minimoon.Val[Int],
  current~ : @minimoon.Val[Int],
  on_change~ : @minimoon.Emit[Int],
  render~ : (CarouselScope) -> @minimoon.Node,
  circular? : Bool = false,
  orientation? : Orientation = Horizontal,
  aria_label? : String = "Carousel",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  carousel_provider_controlled_with_input(
    id~,
    count~,
    current~,
    on_change~,
    input=@minimoon.Val::constant(()),
    render=(scope, _) => render(scope),
    circular~,
    orientation~,
    aria_label~,
    class~,
    style~,
  )
}

///|
pub fn[Input : Eq] carousel_provider_with_input(
  id~ : String,
  count~ : @minimoon.Val[Int],
  input~ : @minimoon.Val[Input],
  render~ : (CarouselScope, Input) -> @minimoon.Node,
  default_index? : Int = 0,
  on_change? : @minimoon.Emit[Int],
  circular? : Bool = false,
  orientation? : Orientation = Horizontal,
  aria_label? : String = "Carousel",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  let (index, emit) = @minimoon.create_state_with_input(
    input=count,
    init=(_, count) => {
      @minimoon.no_cmd(default_index.clamp(min=0, max=(count - 1).max(0)))
    },
    update=(old, count, requested : Int, _) => {
      let next = requested.clamp(min=0, max=(count - 1).max(0))
      (
        next,
        if next == old {
          @minimoon.none
        } else {
          on_change.map(emit => emit(next)).unwrap_or(@minimoon.none)
        },
      )
    },
  )
  let watch = count.switch_by(
    (count, _) => {
      let (_, _) = @minimoon.create_state_with_input(
        input=index,
        init=(_, index) => {
          (
            (),
            if index >= count.max(0) {
              emit((count - 1).max(0))
            } else {
              @minimoon.none
            },
          )
        },
        update=(_, _, _ : Unit, _) => @minimoon.no_cmd(()),
      )
      @minimoon.Val::constant(@minimoon.nothing())
    },
    by=count => count.to_string(),
  )
  let content = carousel_provider_controlled_with_input(
    id~,
    count~,
    current=index,
    on_change=emit,
    input~,
    render~,
    circular~,
    orientation~,
    aria_label~,
    class~,
    style~,
  )
  @minimoon.Val::view2(content, watch, (content, watch) => {
    @minimoon.fragment([content, watch])
  })
}

///|
pub fn carousel_provider(
  id~ : String,
  count~ : @minimoon.Val[Int],
  render~ : (CarouselScope) -> @minimoon.Node,
  default_index? : Int = 0,
  on_change? : @minimoon.Emit[Int],
  circular? : Bool = false,
  orientation? : Orientation = Horizontal,
  aria_label? : String = "Carousel",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Val[@minimoon.Node] {
  carousel_provider_with_input(
    id~,
    count~,
    input=@minimoon.Val::constant(()),
    render=(scope, _) => render(scope),
    default_index~,
    on_change?,
    circular~,
    orientation~,
    aria_label~,
    class~,
    style~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] carousel_content(
  scope : CarouselScope,
  children : C,
  id? : String,
  autoplay? : Bool = false,
  interval? : Int = 5000,
  height? : String = "200px",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  @minimoon.swiper(
    id=id.unwrap_or(scope.id + "-swiper"),
    event_key=scope.id + "/change",
    current=scope.current,
    circular=scope.circular,
    vertical=scope.orientation == Vertical,
    autoplay=autoplay && scope.count > 1,
    interval~,
    on_change=@minimoon.Emit(index => carousel_scroll_to(scope, index)),
    class="mmui-carousel-content " + class,
    style="height:" + height + ";" + style,
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] carousel_item(
  scope : CarouselScope,
  index~ : Int,
  children : C,
  key? : String,
  aria_label? : String,
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  guard index >= 0 && index < scope.count else {
    abort("carousel item index must be within slide count")
  }
  @minimoon.swiper_item(
    item_id=key.unwrap_or(index.to_string()),
    ui_container(
      "carousel-item",
      class~,
      style="height:100%;box-sizing:border-box;" + style,
      semantics=@minimoon.semantics(
        role=@minimoon.GroupRole,
        label=aria_label.unwrap_or(
          "Slide " + (index + 1).to_string() + " of " + scope.count.to_string(),
        ),
        selected=index == scope.current,
        hidden=index != scope.current,
      ),
      children.to_nodes(),
    ),
  )
}

///|
pub fn carousel_items(
  scope : CarouselScope,
  items~ : Array[Panel],
  autoplay? : Bool = false,
  interval? : Int = 5000,
  height? : String = "200px",
  class? : String = "",
  style? : String = "",
) -> @minimoon.Node {
  guard items.length() == scope.count else {
    abort("carousel items must match slide count")
  }
  let slides : Array[@minimoon.Node] = []
  for index, item in items {
    slides.push(carousel_item(scope, index~, key=item.key, item.content))
  }
  carousel_content(scope, slides, autoplay~, interval~, height~, class~, style~)
}

///|
pub fn[C : @minimoon.IsChildren] carousel_previous(
  scope : CarouselScope,
  children : C,
  disabled? : Bool = false,
  aria_label? : String = "Previous slide",
  class? : String = "",
) -> @minimoon.Node {
  let disabled = disabled || !carousel_can_previous(scope)
  @minimoon.button_children(
    disabled~,
    event_key=scope.id + "/previous",
    class="mmui-carousel-previous " + class,
    semantics=@minimoon.semantics(label=aria_label),
    on_tap=if disabled {
      @minimoon.none
    } else {
      carousel_scroll_previous(scope)
    },
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] carousel_next(
  scope : CarouselScope,
  children : C,
  disabled? : Bool = false,
  aria_label? : String = "Next slide",
  class? : String = "",
) -> @minimoon.Node {
  let disabled = disabled || !carousel_can_next(scope)
  @minimoon.button_children(
    disabled~,
    event_key=scope.id + "/next",
    class="mmui-carousel-next " + class,
    semantics=@minimoon.semantics(label=aria_label),
    on_tap=if disabled { @minimoon.none } else { carousel_scroll_next(scope) },
    children,
  )
}
