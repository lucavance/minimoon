///|
pub fn[Input : Eq] navigation_menu_provider_controlled_with_input(
  context : UiContext,
  id~ : String,
  input~ : @minimoon.Val[Input],
  value~ : @minimoon.Val[String?],
  on_value_change~ : @minimoon.Emit[String?],
  render~ : (NavigationMenuScope, Input) -> @minimoon.Node,
  viewport? : Bool = true,
  aria_label? : String = "Main navigation",
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
) -> @minimoon.Val[@minimoon.Node] {
  let (_, toggle) = @minimoon.create_state_with_input(
    input=value,
    init=(_, _) => @minimoon.no_cmd(()),
    update=(_, current, key : String, _) => {
      ((), on_value_change(if current == Some(key) { None } else { Some(key) }))
    },
  )
  let (bounds, set_bounds) = @minimoon.create_variable(NavigationBounds::{
    value: None,
    bounds: None,
  })
  let _ = @minimoon.create_state(
    (),
    update=(_, _ : Unit, _) => @minimoon.no_cmd(()),
    subscriptions=(_, _) => context.page.on_hide(on_value_change(None)),
  )
  let watcher = value.switch_by(
    (active, _) => {
      if active is Some(active) {
        let (_, _) = @minimoon.create_state_with_init(
          init=emit => {
            (
              (),
              @minimoon.measure_nodes(
                [
                  navigation_part_id(id, active, "trigger"),
                  if viewport {
                    id + "-viewport"
                  } else {
                    navigation_part_id(id, active, "content")
                  },
                  "mmui-viewport",
                ],
                emit,
              ),
            )
          },
          update=(
            _,
            result : Result[Array[@minimoon.NodeRect?], @minimoon.HostError],
            _,
          ) => {
            let placement = match result {
              Ok([Some(anchor), Some(surface), Some(window)]) => {
                let placed = @headless.place(
                  rect_bounds(anchor),
                  rect_bounds(surface),
                  rect_bounds(window),
                  @headless.BottomStart,
                  gap=side_offset,
                )
                NavigationBounds::{
                  value: Some(active),
                  bounds: Some({
                    ..placed,
                    left: (placed.left + align_offset)
                    .max(window.left)
                    .min((window.right - placed.width).max(window.left)),
                  }),
                }
              }
              _ => NavigationBounds::{ value: Some(active), bounds: None, }
            }
            ((), set_bounds(_ => placement))
          },
        )
      }
      @minimoon.Val::constant(@minimoon.nothing())
    },
    by=active => active.map(value => "value:" + value).unwrap_or("closed"),
  )
  let rendered = @minimoon.Val::view4(value, input, bounds, context.visible, (
    active,
    input,
    placement,
    visible,
  ) => {
    let scope = NavigationMenuScope::{
      id,
      value: if visible {
        active
      } else {
        None
      },
      viewport,
      bounds: if placement.value == active {
        placement.bounds
      } else {
        None
      },
      change: on_value_change,
      toggle,
      contents: Ref(None),
      chrome: Ref(None),
      keys: Set([]),
    }
    let content = render(scope, input)
    let shared = if viewport && visible && scope.contents.val is Some(content) {
      navigation_surface(
        scope,
        id + "-viewport",
        @minimoon.fragment([
          content,
          scope.chrome.val.unwrap_or(@minimoon.nothing()),
        ]),
      )
    } else {
      @minimoon.nothing()
    }
    ui_container(
      "navigation-menu-root",
      id~,
      semantics=@minimoon.semantics(
        role=@minimoon.NavigationRole,
        label=aria_label,
      ),
      [content, shared],
    )
  })
  @minimoon.Val::view2(rendered, watcher, (rendered, watcher) => {
    @minimoon.fragment([rendered, watcher])
  })
}

///|
pub fn navigation_menu_provider_controlled(
  context : UiContext,
  id~ : String,
  value~ : @minimoon.Val[String?],
  on_value_change~ : @minimoon.Emit[String?],
  render~ : (NavigationMenuScope) -> @minimoon.Node,
  viewport? : Bool = true,
  aria_label? : String = "Main navigation",
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
) -> @minimoon.Val[@minimoon.Node] {
  navigation_menu_provider_controlled_with_input(
    context,
    id~,
    input=@minimoon.Val::constant(()),
    value~,
    on_value_change~,
    render=(scope, _) => render(scope),
    viewport~,
    aria_label~,
    side_offset~,
    align_offset~,
  )
}

///|
pub fn[Input : Eq] navigation_menu_provider_with_input(
  context : UiContext,
  id~ : String,
  input~ : @minimoon.Val[Input],
  render~ : (NavigationMenuScope, Input) -> @minimoon.Node,
  default_value? : String,
  viewport? : Bool = true,
  on_value_change? : @minimoon.Emit[String?],
  aria_label? : String = "Main navigation",
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
) -> @minimoon.Val[@minimoon.Node] {
  let (value, set_value) = @minimoon.create_variable(default_value)
  navigation_menu_provider_controlled_with_input(
    context,
    id~,
    input~,
    value~,
    on_value_change=@minimoon.Emit(value => {
      @minimoon.batch([
        set_value(_ => value),
        on_value_change.map(emit => emit(value)).unwrap_or(@minimoon.none),
      ])
    }),
    render~,
    viewport~,
    aria_label~,
    side_offset~,
    align_offset~,
  )
}

///|
pub fn navigation_menu_root(
  context : UiContext,
  id~ : String,
  render~ : (NavigationMenuScope) -> @minimoon.Node,
  default_value? : String,
  viewport? : Bool = true,
  on_value_change? : @minimoon.Emit[String?],
  aria_label? : String = "Main navigation",
  side_offset? : Double = 8.0,
  align_offset? : Double = 0.0,
) -> @minimoon.Val[@minimoon.Node] {
  navigation_menu_provider_with_input(
    context,
    id~,
    input=@minimoon.Val::constant(()),
    render=(scope, _) => render(scope),
    default_value?,
    viewport~,
    on_value_change?,
    aria_label~,
    side_offset~,
    align_offset~,
  )
}
