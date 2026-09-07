///|
pub(all) struct Panel {
  key : String
  title : String
  content : @minimoon.Node
  disabled : Bool
  icon : @minimoon.Node?
  trigger : @minimoon.Node?
} derive(Eq)

///|
pub fn panel(
  key~ : String,
  title~ : String,
  content~ : @minimoon.Node,
  disabled? : Bool = false,
  icon? : @minimoon.Node,
  trigger? : @minimoon.Node,
) -> Panel {
  guard key != "" else { abort("panel key must not be empty") }
  { key, title, content, disabled, icon, trigger, }
}

///|
pub fn collapsible_controlled(
  id~ : String,
  title~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
  disabled? : Bool = false,
  force_mount? : Bool = false,
  show_indicator? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let tap = form_dispatch(open, (current, _ : Unit) => {
    if disabled {
      @minimoon.none
    } else {
      on_change(!current)
    }
  })
  @minimoon.Val::view2(open, content, (open, content) => {
    ui_container("collapsible", id~, [
      @minimoon.button(
        on_tap=tap(()),
        disabled~,
        event_key=id + "/toggle",
        semantics=@minimoon.semantics(expanded=open, controls=id + "-content"),
        title +
        (if show_indicator { if open { " −" } else { " +" } } else { "" }),
      ),
      if open || force_mount {
        ui_container(
          "collapsible-content",
          id=id + "-content",
          style=if open { "" } else { "display:none;" },
          semantics=@minimoon.semantics(hidden=!open),
          [content],
        )
      } else {
        @minimoon.nothing()
      },
    ])
  })
}

///|
pub fn collapsible(
  id~ : String,
  title~ : String,
  content~ : @minimoon.Val[@minimoon.Node],
  initially_open? : Bool = false,
  disabled? : Bool = false,
  force_mount? : Bool = false,
  show_indicator? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, emit) = @minimoon.create_variable(initially_open)
  collapsible_controlled(
    id~,
    title~,
    content~,
    open~,
    on_change=emit.map(value => _ => value),
    disabled~,
    force_mount~,
    show_indicator~,
  )
}

///|
pub fn accordion_controlled(
  id~ : String,
  items~ : @minimoon.Val[Array[Panel]],
  open_keys~ : @minimoon.Val[Array[String]],
  on_change~ : @minimoon.Emit[Array[String]],
  multiple? : Bool = false,
  collapsible? : Bool = true,
  disabled? : Bool = false,
  force_mount? : Bool = false,
  show_indicator? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let tap = form_dispatch(
    @minimoon.Val::map2(items, open_keys, (items, keys) => (items, keys)),
    (current, key : String) => {
      let (items, keys) = current
      validate_panels(items)
      if disabled || !items.any(item => item.key == key && !item.disabled) {
        return @minimoon.none
      }
      let keys = normalize_panel_keys(items, keys, multiple)
      let next = if keys.contains(key) && collapsible {
        keys.filter(value => value != key)
      } else if keys.contains(key) {
        keys
      } else if multiple {
        let next = keys.copy()
        next.push(key)
        next
      } else {
        [key]
      }
      on_change(next)
    },
  )
  @minimoon.Val::view2(items, open_keys, (items, keys) => {
    validate_panels(items)
    let keys = normalize_panel_keys(items, keys, multiple)
    ui_container(
      "accordion",
      id~,
      items.map(item => {
        let open = keys.contains(item.key)
        ui_container("accordion-item", id=id + "-" + item.key, [
          @minimoon.button_children(
            id=id + "-trigger-" + item.key,
            disabled=disabled || item.disabled,
            event_key=id + "/" + item.key,
            on_tap=if disabled || item.disabled {
              @minimoon.none
            } else {
              tap(item.key)
            },
            semantics=@minimoon.semantics(
              expanded=open,
              controls=id + "-panel-" + item.key,
            ),
            [
              panel_trigger(item),
              if show_indicator {
                @minimoon.text(if open { "−" } else { "+" })
              } else {
                @minimoon.nothing()
              },
            ],
          ),
          if open || force_mount {
            ui_container(
              "accordion-panel",
              id=id + "-panel-" + item.key,
              style=if open { "" } else { "display:none;" },
              semantics=@minimoon.semantics(
                role=@minimoon.RegionRole,
                labelled_by=id + "-trigger-" + item.key,
                hidden=!open,
              ),
              [item.content],
            )
          } else {
            @minimoon.nothing()
          },
        ])
      }),
    )
  })
}

///|
pub fn accordion(
  id~ : String,
  items~ : @minimoon.Val[Array[Panel]],
  initial_open_keys? : Array[String] = [],
  multiple? : Bool = false,
  collapsible? : Bool = true,
  disabled? : Bool = false,
  force_mount? : Bool = false,
  show_indicator? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let (keys, emit) = @minimoon.create_variable(initial_open_keys)
  accordion_controlled(
    id~,
    items~,
    open_keys=keys,
    on_change=emit.map(value => _ => value),
    multiple~,
    collapsible~,
    disabled~,
    force_mount~,
    show_indicator~,
  )
}

///|
pub fn tabs_controlled(
  id~ : String,
  items~ : @minimoon.Val[Array[Panel]],
  selected~ : @minimoon.Val[String?],
  on_change~ : @minimoon.Emit[String?],
  vertical? : Bool = false,
  force_mount? : Bool = false,
  list_variant? : TabsListVariant = TabsDefault,
) -> @minimoon.Val[@minimoon.Node] {
  let change = form_dispatch(items, (items, key : String) => {
    if items.any(item => item.key == key && !item.disabled) {
      on_change(Some(key))
    } else {
      @minimoon.none
    }
  })
  @minimoon.Val::view2(items, selected, (items, selected) => {
    validate_panels(items)
    let selected = valid_tab_selection(items, selected)
    let triggers = items.map(item => {
      @minimoon.button_children(
        id=id + "-tab-" + item.key,
        class="mmui-tab",
        disabled=item.disabled,
        event_key=id + "/" + item.key,
        on_tap=if item.disabled { @minimoon.none } else { change(item.key) },
        semantics=@minimoon.semantics(
          role=@minimoon.TabRole,
          selected=selected == Some(item.key),
          controls=id + "-panel-" + item.key,
        ),
        panel_trigger(item),
      )
    })
    let panels = items
      .filter(item => force_mount || selected == Some(item.key))
      .map(item => {
        ui_container(
          "tab-panel",
          id=id + "-panel-" + item.key,
          style=if selected == Some(item.key) { "" } else { "display:none;" },
          semantics=@minimoon.semantics(
            role=@minimoon.TabPanelRole,
            labelled_by=id + "-tab-" + item.key,
            hidden=selected != Some(item.key),
          ),
          [item.content],
        )
      })
    ui_container("tabs", id~, [
      ui_container(
        "tab-list",
        class=(if vertical { "mmui-vertical" } else { "mmui-horizontal" }) +
          (if list_variant == TabsLine {
            " mmui-tabs-line"
          } else {
            " mmui-tabs-default"
          }),
        semantics=@minimoon.semantics(
          role=@minimoon.TabListRole,
          orientation=if vertical { "vertical" } else { "horizontal" },
        ),
        triggers,
      ),
      @minimoon.fragment(panels),
    ])
  })
}

///|
pub fn tabs(
  id~ : String,
  items~ : @minimoon.Val[Array[Panel]],
  initial_selected? : String,
  vertical? : Bool = false,
  force_mount? : Bool = false,
  list_variant? : TabsListVariant = TabsDefault,
) -> @minimoon.Val[@minimoon.Node] {
  let (selected, emit) = @minimoon.create_variable(initial_selected)
  tabs_controlled(
    id~,
    items~,
    selected~,
    on_change=emit.map(value => _ => value),
    vertical~,
    force_mount~,
    list_variant~,
  )
}
