///|
using @components {
  accordion_item,
  accordion_item_with_input,
  accordion_multiple_controlled,
  accordion_multiple_controlled_with_input,
  accordion_multiple_with_input,
  accordion_single,
  accordion_single_controlled,
  accordion_single_controlled_with_input,
  accordion_single_with_input,
  dialog,
  dialog_controlled_with_input,
  dialog_spec,
  dialog_spec_with_input,
  dialog_with_input,
  disclosure,
  disclosure_controlled_with_input,
  disclosure_spec,
  disclosure_spec_with_input,
  disclosure_with_input,
  dropdown,
  dropdown_spec,
  menu_checkbox_item,
  menu_item,
  menu_label,
  menu_radio_item,
  menu_separator,
  menu_state,
  menu_submenu,
  sheet,
  sheet_controlled_with_input,
  sheet_spec,
  sheet_spec_with_input,
  sheet_with_input,
  tab_item,
  tab_item_with_input,
  tabs,
  tabs_controlled,
  tabs_controlled_with_input,
  tabs_with_input,
}

///|
test "headless disclosure, accordion, and tabs own state and semantics" {
  let page = @minimoon.page(
    id="headless_components",
    route=@minimoon.route("pages/headless-components/headless-components"),
    title="Headless components",
    build=_ => {
      let disclosure = disclosure(
        disclosure_spec(
          id="details",
          label="Details",
          panel=@minimoon.p("Disclosure panel"),
        ),
      )
      let accordion = accordion_single(
        id="faq",
        label="Frequently asked questions",
        collapsible=false,
        items=[
          accordion_item(
            key="one",
            label="Question one",
            panel=@minimoon.p("Answer one"),
          ),
          accordion_item(
            key="two",
            label="Question two",
            panel=@minimoon.p("Answer two"),
          ),
        ],
      )
      let tabs = tabs(id="guide", label="Guide sections", items=[
        tab_item(key="intro", label="Intro", panel=@minimoon.p("Intro panel")),
        tab_item(key="api", label="API", panel=@minimoon.p("API panel")),
      ])
      @minimoon.Val::view3(disclosure, accordion, tabs, (a, b, c) => {
        @minimoon.div([a, b, c])
      })
    },
  )
  let runtime = @testing.mount(page)
  let disclosure = runtime.within(@testing.by_section("disclosure"))
  let accordion = runtime.within(
    @testing.all([
      @testing.by_section("accordion"),
      @testing.by_label("Frequently asked questions"),
    ]),
  )
  let tabs = runtime.within(
    @testing.all([
      @testing.by_section("tabs-list"),
      @testing.by_role("tablist"),
      @testing.by_label("Guide sections"),
      @testing.by_prop("ariaOrientation", Json::string("horizontal")),
    ]),
  )
  assert_true(accordion.query(@testing.by_text("Answer one")) is Some(_))
  assert_true(disclosure.query(@testing.by_text("Disclosure panel")) is None)
  let _ = disclosure.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Details")]),
  )
  assert_true(disclosure.query(@testing.by_text("Disclosure panel")) is Some(_))

  let before = runtime.snapshot()
  assert_eq(
    accordion.tap(
      @testing.all([
        @testing.by_role("button"),
        @testing.by_text("Question one"),
      ]),
    ),
    "[]",
  )
  assert_eq(runtime.snapshot(), before)
  let _ = accordion.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Question two")]),
  )
  assert_true(accordion.query(@testing.by_text("Answer two")) is Some(_))
  let _ = tabs.tap(
    @testing.all([@testing.by_role("tab"), @testing.by_text("API")]),
  )
  assert_true(runtime.query(@testing.by_text("API panel")) is Some(_))
  assert_true(
    tabs
    .get(@testing.all([@testing.by_role("tab"), @testing.by_text("API")]))
    .prop("ariaSelected") ==
    Some(Json::boolean(true)),
  )
  let selected_before = runtime.snapshot()
  assert_eq(
    tabs.tap(@testing.all([@testing.by_role("tab"), @testing.by_text("API")])),
    "[]",
  )
  assert_eq(runtime.snapshot(), selected_before)
  let _ = runtime.dispose()
}

///|
test "controlled single, multiple, and tabs delegate typed state" {
  let page = @minimoon.page(
    id="controlled_components",
    route=@minimoon.route("pages/controlled-components/controlled-components"),
    title="Controlled components",
    build=_ => {
      let initial_open_key : String? = None
      let (open_key, update_open_key) = @minimoon.create_variable(
        initial_open_key,
      )
      let initial_open_keys : Array[String] = []
      let (open_keys, update_open_keys) = @minimoon.create_variable(
        initial_open_keys,
      )
      let initial_selected : String? = Some("missing")
      let (selected_key, update_selected_key) = @minimoon.create_variable(
        initial_selected,
      )
      let items = [
        accordion_item(
          key="one",
          label="Controlled accordion one",
          panel=@minimoon.p("Controlled accordion panel one"),
        ),
        accordion_item(
          key="two",
          label="Controlled accordion two",
          panel=@minimoon.p("Controlled accordion panel two"),
        ),
      ]
      let single = accordion_single_controlled(
        id="controlled-single",
        label="Controlled single accordion",
        items~,
        open_key~,
        on_change=update_open_key.map(value => _ => value),
      )
      let multiple = accordion_multiple_controlled(
        id="controlled-multiple",
        label="Controlled multiple accordion",
        items~,
        open_keys~,
        on_change=update_open_keys.map(value => _ => value),
      )
      let tabs = tabs_controlled(
        id="controlled-tabs",
        label="Controlled tab sections",
        items=[
          tab_item(
            key="one",
            label="Controlled tab one",
            panel=@minimoon.p("Controlled tab panel one"),
          ),
          tab_item(
            key="two",
            label="Controlled tab two",
            panel=@minimoon.p("Controlled tab panel two"),
          ),
        ],
        selected_key~,
        on_change=update_selected_key.map(value => _ => value),
      )
      @minimoon.Val::view3(single, multiple, tabs, (a, b, c) => {
        @minimoon.div([a, b, c])
      })
    },
  )
  let runtime = @testing.mount(page)
  let single = runtime.within(@testing.by_id("controlled-single"))
  let multiple = runtime.within(@testing.by_id("controlled-multiple"))
  let tabs = runtime.within(@testing.by_id("controlled-tabs"))
  assert_true(
    runtime.query(@testing.by_text("Controlled tab panel one")) is None,
  )
  assert_true(
    tabs.query(
      @testing.all([
        @testing.by_role("tablist"),
        @testing.by_label("Controlled tab sections"),
      ]),
    )
    is Some(_),
  )
  let _ = single.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Controlled accordion one"),
    ]),
  )
  assert_true(
    single.query(@testing.by_text("Controlled accordion panel one")) is Some(_),
  )
  let _ = multiple.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Controlled accordion one"),
    ]),
  )
  let _ = multiple.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Controlled accordion two"),
    ]),
  )
  assert_true(
    multiple.query(@testing.by_text("Controlled accordion panel one"))
    is Some(_),
  )
  assert_true(
    multiple.query(@testing.by_text("Controlled accordion panel two"))
    is Some(_),
  )
  let _ = tabs.tap(
    @testing.all([
      @testing.by_role("tab"),
      @testing.by_text("Controlled tab two"),
    ]),
  )
  assert_true(
    tabs.query(@testing.by_text("Controlled tab panel two")) is Some(_),
  )
  let _ = runtime.dispose()
}

///|
test "dialog, sheet, and dropdown expose native modal and menu state" {
  let page = @minimoon.page(
    id="overlay_components",
    route=@minimoon.route("pages/overlay-components/overlay-components"),
    title="Overlay components",
    build=_ => {
      let dialog = dialog(
        dialog_spec(
          id="dialog",
          title="Confirm action",
          description="This action is reversible.",
          trigger_label="Open dialog",
          content=close => {
            @minimoon.button(
              on_tap=close,
              event_key="dialog/content-close",
              "Finish",
            )
          },
        ),
      )
      let sheet = sheet(
        sheet_spec(
          id="sheet",
          title="Filters",
          trigger_label="Open sheet",
          side=Left,
          content=_ => @minimoon.p("Sheet content"),
        ),
      )
      let dropdown = dropdown(
        dropdown_spec(id="menu", trigger_label="Actions", items=[
          menu_label(key="label", label="Preferences"),
          menu_checkbox_item(key="check", label="Compact mode"),
          menu_radio_item(
            key="light",
            label="Light",
            group="theme",
            value="light",
          ),
          menu_separator(key="separator"),
          menu_submenu(key="more", label="More", items=[
            menu_item(key="about", label="About"),
          ]),
        ]),
      )
      @minimoon.Val::view3(dialog, sheet, dropdown, (a, b, c) => {
        @minimoon.div([a, b, c])
      })
    },
  )
  let runtime = @testing.mount(page)
  let dialog = runtime.within(@testing.by_id("dialog"))
  let sheet = runtime.within(@testing.by_id("sheet"))
  let dropdown = runtime.within(@testing.by_id("menu"))
  let _ = dialog.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Open dialog")]),
  )
  let surface = dialog.get(
    @testing.all([
      @testing.by_role("dialog"),
      @testing.by_section("dialog-surface"),
    ]),
  )
  assert_true(surface.prop("ariaModal") == Some(Json::boolean(true)))
  let _ = dialog.tap(
    @testing.all([@testing.by_kind("button"), @testing.by_text("Finish")]),
  )
  assert_true(dialog.query(@testing.by_text("Confirm action")) is None)
  let _ = dialog.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Open dialog")]),
  )
  let _ = dialog.tap(@testing.by_section("dialog-overlay"))
  assert_true(dialog.query(@testing.by_text("Confirm action")) is None)

  let _ = sheet.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Open sheet")]),
  )
  assert_true(sheet.query(@testing.by_text("Sheet content")) is Some(_))
  assert_true(sheet.query(@testing.by_section("sheet-overlay")) is Some(_))
  assert_true(
    sheet.query(
      @testing.all([
        @testing.by_role("dialog"),
        @testing.by_section("sheet-surface"),
      ]),
    )
    is Some(_),
  )
  let _ = sheet.tap(
    @testing.all([@testing.by_kind("button"), @testing.by_text("Close")]),
  )
  assert_true(sheet.query(@testing.by_text("Sheet content")) is None)

  let _ = dropdown.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Actions")]),
  )
  let menu = dropdown.within(@testing.by_id("menu-menu"))
  assert_true(
    dropdown.get(@testing.by_role("menu")).prop("ariaLabelledBy") ==
    Some(Json::string("menu-trigger")),
  )
  let _ = menu.tap(
    @testing.all([
      @testing.by_role("menuitemcheckbox"),
      @testing.by_text("Compact mode"),
    ]),
  )
  assert_true(
    menu
    .get(
      @testing.all([
        @testing.by_role("menuitemcheckbox"),
        @testing.by_text("Compact mode"),
      ]),
    )
    .prop("ariaChecked") ==
    Some(Json::boolean(true)),
  )
  let _ = menu.tap(
    @testing.all([@testing.by_role("menuitemradio"), @testing.by_text("Light")]),
  )
  assert_true(
    menu
    .get(
      @testing.all([
        @testing.by_role("menuitemradio"),
        @testing.by_text("Light"),
      ]),
    )
    .prop("ariaChecked") ==
    Some(Json::boolean(true)),
  )
  let _ = menu.tap(
    @testing.all([@testing.by_role("menuitem"), @testing.by_text("More")]),
  )
  assert_true(menu.query(@testing.by_text("About")) is Some(_))
  let _ = menu.tap(
    @testing.all([@testing.by_role("menuitem"), @testing.by_text("About")]),
  )
  assert_true(dropdown.query(@testing.by_text("Preferences")) is None)
  let _ = dropdown.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Actions")]),
  )
  let _ = dropdown.tap(@testing.by_section("dropdown-dismiss"))
  assert_true(dropdown.query(@testing.by_text("Preferences")) is None)
  let _ = runtime.dispose()
}

///|
fn assert_scoped_tap_noop(
  runtime : @testing.TestRuntime,
  scope : @testing.TestScope,
  selector : @testing.Selector,
) -> Unit raise {
  let before = runtime.snapshot()
  assert_eq(scope.tap(selector), "[]")
  assert_eq(runtime.snapshot(), before)
}

///|
test "disabled and already-selected component actions are semantic no-ops" {
  let page = @minimoon.page(
    id="component_noops",
    route=@minimoon.route("pages/component-noops/component-noops"),
    title="Component no-ops",
    build=_ => {
      let accordion = accordion_single(id="disabled-accordion", disabled=true, items=[
        accordion_item(
          key="one",
          label="Disabled accordion item",
          panel=@minimoon.p("Disabled accordion panel"),
        ),
      ])
      let tabs = tabs(id="disabled-tabs", disabled=true, items=[
        tab_item(
          key="one",
          label="Disabled tab",
          panel=@minimoon.p("Disabled tab panel"),
        ),
      ])
      let disabled_dialog_node = dialog(
        dialog_spec(
          id="disabled-dialog",
          title="Disabled dialog",
          trigger_label="Open disabled dialog",
          disabled=true,
          content=_ => @minimoon.p("Disabled dialog content"),
        ),
      )
      let disabled_sheet_node = sheet(
        sheet_spec(
          id="disabled-sheet",
          title="Disabled sheet",
          trigger_label="Open disabled sheet",
          disabled=true,
          content=_ => @minimoon.p("Disabled sheet content"),
        ),
      )
      let disabled_dropdown_node = dropdown(
        dropdown_spec(
          id="disabled-menu",
          trigger_label="Open disabled menu",
          disabled=true,
          items=[menu_item(key="action", label="Unused")],
        ),
      )
      let entries = dropdown(
        dropdown_spec(id="entry-menu", trigger_label="Entry menu", items=[
          menu_item(key="action", label="Disabled action", disabled=true),
          menu_item(key="keep", label="Keep menu open", close_on_select=false),
          menu_checkbox_item(
            key="check",
            label="Disabled checkbox",
            disabled=true,
          ),
          menu_radio_item(
            key="light",
            label="Selected radio",
            group="theme",
            value="light",
          ),
          menu_radio_item(
            key="dark",
            label="Disabled radio",
            group="theme",
            value="dark",
            disabled=true,
          ),
          menu_submenu(key="more", label="Disabled submenu", disabled=true, items=[
            menu_item(key="nested", label="Nested"),
          ]),
        ]),
        initial_state=menu_state(open=true, radio_values=[("theme", "light")]),
      )
      let locked_dialog = dialog(
        dialog_spec(
          id="locked-dialog",
          title="Locked overlay dialog",
          trigger_label="Open locked dialog",
          close_on_overlay=false,
          content=_ => @minimoon.p("Locked content"),
        ),
        initially_open=true,
      )
      @minimoon.Val::view7(
        accordion,
        tabs,
        disabled_dialog_node,
        disabled_sheet_node,
        disabled_dropdown_node,
        entries,
        locked_dialog,
        (a, b, c, d, e, f, g) => @minimoon.div([a, b, c, d, e, f, g]),
      )
    },
  )
  let runtime = @testing.mount(page)
  let cases : Array[(@testing.TestScope, @testing.Selector)] = [
    (
      runtime.within(@testing.by_id("disabled-accordion")),
      @testing.all([
        @testing.by_role("button"),
        @testing.by_text("Disabled accordion item"),
        @testing.by_prop("disabled", Json::boolean(true)),
        @testing.by_prop("ariaDisabled", Json::boolean(true)),
      ]),
    ),
    (
      runtime.within(@testing.by_id("disabled-tabs")),
      @testing.all([
        @testing.by_role("tab"),
        @testing.by_text("Disabled tab"),
        @testing.by_prop("disabled", Json::boolean(true)),
        @testing.by_prop("ariaDisabled", Json::boolean(true)),
      ]),
    ),
    (
      runtime.within(@testing.by_id("disabled-dialog")),
      @testing.all([
        @testing.by_role("button"),
        @testing.by_text("Open disabled dialog"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
    ),
    (
      runtime.within(@testing.by_id("disabled-sheet")),
      @testing.all([
        @testing.by_role("button"),
        @testing.by_text("Open disabled sheet"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
    ),
    (
      runtime.within(@testing.by_id("disabled-menu")),
      @testing.all([
        @testing.by_role("button"),
        @testing.by_text("Open disabled menu"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
    ),
  ]
  for action in cases {
    assert_scoped_tap_noop(runtime, action.0, action.1)
  }

  let entries = runtime.within(@testing.by_id("entry-menu"))
  for
    selector in [
      @testing.all([
        @testing.by_role("menuitem"),
        @testing.by_text("Disabled action"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
      @testing.all([
        @testing.by_role("menuitemcheckbox"),
        @testing.by_text("Disabled checkbox"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
      @testing.all([
        @testing.by_role("menuitemradio"),
        @testing.by_text("Selected radio"),
        @testing.by_prop("ariaChecked", Json::boolean(true)),
      ]),
      @testing.all([
        @testing.by_role("menuitemradio"),
        @testing.by_text("Disabled radio"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
      @testing.all([
        @testing.by_role("menuitem"),
        @testing.by_text("Disabled submenu"),
        @testing.by_prop("disabled", Json::boolean(true)),
      ]),
      @testing.all([
        @testing.by_role("menuitem"),
        @testing.by_text("Keep menu open"),
      ]),
    ] {
    assert_scoped_tap_noop(runtime, entries, selector)
  }
  assert_true(entries.query(@testing.by_role("menu")) is Some(_))

  let locked = runtime.within(@testing.by_id("locked-dialog"))
  assert_true(
    locked.query(
      @testing.all([
        @testing.by_section("dialog-overlay"),
        @testing.by_event("tap"),
      ]),
    )
    is None,
  )
  assert_true(locked.query(@testing.by_text("Locked content")) is Some(_))
  let _ = runtime.dispose()
}

///|
test "panic duplicate accordion keys remain invalid" {
  let page = @minimoon.page(
    id="duplicate_accordion",
    route=@minimoon.route("pages/duplicate-accordion/duplicate-accordion"),
    title="Duplicate accordion",
    build=_ => {
      accordion_single(id="duplicate", items=[
        accordion_item(key="same", label="One", panel=@minimoon.p("One")),
        accordion_item(key="same", label="Two", panel=@minimoon.p("Two")),
      ])
    },
  )
  let _ = @testing.mount(page)
}

///|
test "panic duplicate tab keys remain invalid" {
  let page = @minimoon.page(
    id="duplicate_tabs",
    route=@minimoon.route("pages/duplicate-tabs/duplicate-tabs"),
    title="Duplicate tabs",
    build=_ => {
      tabs(id="duplicate", items=[
        tab_item(key="same", label="One", panel=@minimoon.p("One")),
        tab_item(key="same", label="Two", panel=@minimoon.p("Two")),
      ])
    },
  )
  let _ = @testing.mount(page)
}

///|
test "panic duplicate nested menu keys remain invalid" {
  let page = @minimoon.page(
    id="duplicate_menu",
    route=@minimoon.route("pages/duplicate-menu/duplicate-menu"),
    title="Duplicate menu",
    build=_ => {
      dropdown(
        dropdown_spec(id="duplicate", trigger_label="Duplicate", items=[
          menu_item(key="same", label="One"),
          menu_submenu(key="more", label="More", items=[
            menu_item(key="same", label="Nested"),
          ]),
        ]),
      )
    },
  )
  let _ = @testing.mount(page)
}

///|
test "input-aware accordion preserves nested state while its panel is hidden" {
  let builds = Ref(0)
  let panel_renders = Ref(0)
  let page = @minimoon.page(
    id="input_accordion",
    route=@minimoon.route("pages/input-accordion/input-accordion"),
    title="Input accordion",
    build=_ => {
      builds.val += 1
      let (count, update_count) = @minimoon.create_variable(0)
      let child = count.view(value => {
        @minimoon.button(
          on_tap=update_count(current => current + 1),
          event_key="nested-child/increment",
          "Nested count: " + value.to_string(),
        )
      })
      let accordion = accordion_single_with_input(
        id="input-accordion",
        items=[
          accordion_item_with_input(key="nested", label="Nested child", panel=node => {
            panel_renders.val += 1
            node
          }),
        ],
        input=child,
        initial_open_key="nested",
      )
      accordion.map(node => {
        @minimoon.div([
          @minimoon.button(
            on_tap=update_count(current => current + 1),
            event_key="outside-child/increment",
            "Increment while hidden",
          ),
          node,
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  assert_eq(builds.val, 1)
  assert_true(runtime.query(@testing.by_text("Nested count: 0")) is Some(_))
  let initial_renders = panel_renders.val
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Nested count: 0"),
    ]),
  )
  assert_true(runtime.query(@testing.by_text("Nested count: 1")) is Some(_))
  assert_true(panel_renders.val > initial_renders)
  let accordion = runtime.within(@testing.by_id("input-accordion"))
  let _ = accordion.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Nested child")]),
  )
  assert_true(runtime.query(@testing.by_text("Nested count: 1")) is None)
  let hidden_renders = panel_renders.val
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Increment while hidden"),
    ]),
  )
  assert_eq(panel_renders.val, hidden_renders)
  let _ = accordion.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Nested child")]),
  )
  assert_true(runtime.query(@testing.by_text("Nested count: 2")) is Some(_))
  assert_eq(builds.val, 1)
  let _ = runtime.dispose()
}

///|
test "input-aware controlled slots retain selection and multiple expansion" {
  let first_tab_renders = Ref(0)
  let second_tab_renders = Ref(0)
  let page = @minimoon.page(
    id="controlled_input_slots",
    route=@minimoon.route("pages/controlled-input-slots/controlled-input-slots"),
    title="Controlled input slots",
    build=_ => {
      let (input, update_input) = @minimoon.create_variable("initial")
      let (expanded, update_expanded) = @minimoon.create_variable(true)
      let initial_open_keys : Array[String] = ["one", "two"]
      let (open_keys, update_open_keys) = @minimoon.create_variable(
        initial_open_keys,
      )
      let initial_selected : String? = Some("one")
      let (selected_key, update_selected_key) = @minimoon.create_variable(
        initial_selected,
      )
      let disclosure = disclosure_controlled_with_input(
        disclosure_spec_with_input(
          id="input-disclosure",
          label="Input disclosure",
          panel=value => @minimoon.p("Disclosure: " + value),
        ),
        input~,
        expanded~,
        on_change=update_expanded.map(value => _ => value),
      )
      let multiple = accordion_multiple_controlled_with_input(
        id="input-multiple",
        items=[
          accordion_item_with_input(key="one", label="Input one", panel=value => {
            @minimoon.p("Multiple one: " + value)
          }),
          accordion_item_with_input(key="two", label="Input two", panel=value => {
            @minimoon.p("Multiple two: " + value)
          }),
        ],
        input~,
        open_keys~,
        on_change=update_open_keys.map(value => _ => value),
      )
      let tabs = tabs_controlled_with_input(
        id="input-tabs",
        items=[
          tab_item_with_input(key="one", label="Input tab one", panel=value => {
            first_tab_renders.val += 1
            @minimoon.p("Tab one: " + value)
          }),
          tab_item_with_input(key="two", label="Input tab two", panel=value => {
            second_tab_renders.val += 1
            @minimoon.p("Tab two: " + value)
          }),
        ],
        input~,
        selected_key~,
        on_change=update_selected_key.map(value => _ => value),
      )
      @minimoon.Val::view3(disclosure, multiple, tabs, (a, b, c) => {
        @minimoon.div([
          @minimoon.button(
            on_tap=update_input(_ => "updated"),
            event_key="controlled-input/update",
            "Update input",
          ),
          a,
          b,
          c,
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  assert_true(runtime.query(@testing.by_text("Disclosure: initial")) is Some(_))
  assert_true(
    runtime.query(@testing.by_text("Multiple one: initial")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Multiple two: initial")) is Some(_),
  )
  assert_true(runtime.query(@testing.by_text("Tab one: initial")) is Some(_))
  assert_eq(second_tab_renders.val, 0)
  let disclosure = runtime.within(@testing.by_id("input-disclosure"))
  let _ = disclosure.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Input disclosure"),
    ]),
  )
  assert_true(runtime.query(@testing.by_text("Disclosure: initial")) is None)
  let _ = disclosure.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Input disclosure"),
    ]),
  )
  assert_true(runtime.query(@testing.by_text("Disclosure: initial")) is Some(_))
  let multiple = runtime.within(@testing.by_id("input-multiple"))
  let _ = multiple.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Input one")]),
  )
  assert_true(runtime.query(@testing.by_text("Multiple one: initial")) is None)
  assert_true(
    runtime.query(@testing.by_text("Multiple two: initial")) is Some(_),
  )
  let _ = multiple.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Input one")]),
  )
  assert_true(
    runtime.query(@testing.by_text("Multiple one: initial")) is Some(_),
  )
  let first_before_select = first_tab_renders.val
  let tabs = runtime.within(@testing.by_id("input-tabs"))
  let _ = tabs.tap(
    @testing.all([@testing.by_role("tab"), @testing.by_text("Input tab two")]),
  )
  assert_eq(first_tab_renders.val, first_before_select)
  assert_true(runtime.query(@testing.by_text("Tab two: initial")) is Some(_))
  let second_before_input = second_tab_renders.val
  let _ = runtime.tap(
    @testing.all([@testing.by_kind("button"), @testing.by_text("Update input")]),
  )
  assert_true(runtime.query(@testing.by_text("Disclosure: updated")) is Some(_))
  assert_true(
    runtime.query(@testing.by_text("Multiple one: updated")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Multiple two: updated")) is Some(_),
  )
  assert_true(runtime.query(@testing.by_text("Tab two: updated")) is Some(_))
  assert_true(runtime.query(@testing.by_text("Tab one: updated")) is None)
  assert_eq(first_tab_renders.val, first_before_select)
  assert_true(second_tab_renders.val > second_before_input)
  let _ = runtime.dispose()
}

///|
test "input-aware controlled modal content closes from the latest render" {
  let dialog_renders = Ref(0)
  let sheet_renders = Ref(0)
  let page = @minimoon.page(
    id="controlled_input_modals",
    route=@minimoon.route(
      "pages/controlled-input-modals/controlled-input-modals",
    ),
    title="Controlled input modals",
    build=_ => {
      let (input, update_input) = @minimoon.create_variable("initial")
      let (dialog_open, update_dialog_open) = @minimoon.create_variable(true)
      let (sheet_open, update_sheet_open) = @minimoon.create_variable(true)
      let dialog = dialog_controlled_with_input(
        dialog_spec_with_input(
          id="input-dialog",
          title="Input dialog",
          trigger_label="Open input dialog",
          content=(close, value) => {
            dialog_renders.val += 1
            @minimoon.button(
              on_tap=close,
              event_key="input-dialog/content-close",
              "Dialog content: " + value,
            )
          },
        ),
        input~,
        open=dialog_open,
        on_change=update_dialog_open.map(value => _ => value),
      )
      let sheet = sheet_controlled_with_input(
        sheet_spec_with_input(
          id="input-sheet",
          title="Input sheet",
          trigger_label="Open input sheet",
          content=(close, value) => {
            sheet_renders.val += 1
            @minimoon.button(
              on_tap=close,
              event_key="input-sheet/content-close",
              "Sheet content: " + value,
            )
          },
        ),
        input~,
        open=sheet_open,
        on_change=update_sheet_open.map(value => _ => value),
      )
      dialog.view2(sheet, (dialog_node, sheet_node) => {
        @minimoon.div([
          @minimoon.button(
            on_tap=update_input(value => {
              if value == "initial" {
                "latest"
              } else {
                "after-close"
              }
            }),
            event_key="modal-input/update",
            "Update modal input",
          ),
          dialog_node,
          sheet_node,
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  assert_true(
    runtime.query(@testing.by_text("Dialog content: initial")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Sheet content: initial")) is Some(_),
  )
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Update modal input"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Dialog content: latest")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Sheet content: latest")) is Some(_),
  )
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Dialog content: latest"),
    ]),
  )
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Sheet content: latest"),
    ]),
  )
  assert_true(runtime.query(@testing.by_text("Dialog content: latest")) is None)
  assert_true(runtime.query(@testing.by_text("Sheet content: latest")) is None)
  let dialog = runtime.within(@testing.by_id("input-dialog"))
  let sheet = runtime.within(@testing.by_id("input-sheet"))
  let _ = dialog.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Open input dialog"),
    ]),
  )
  let _ = sheet.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Open input sheet"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Dialog content: latest")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Sheet content: latest")) is Some(_),
  )
  let _ = dialog.tap(@testing.by_section("dialog-overlay"))
  let _ = sheet.tap(@testing.by_section("sheet-overlay"))
  assert_true(runtime.query(@testing.by_text("Dialog content: latest")) is None)
  assert_true(runtime.query(@testing.by_text("Sheet content: latest")) is None)
  let dialog_hidden_renders = dialog_renders.val
  let sheet_hidden_renders = sheet_renders.val
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Update modal input"),
    ]),
  )
  assert_eq(dialog_renders.val, dialog_hidden_renders)
  assert_eq(sheet_renders.val, sheet_hidden_renders)
  let _ = runtime.dispose()
}

///|
test "input-aware self-owned slots normalize and retain their own state" {
  let page = @minimoon.page(
    id="self_owned_input_slots",
    route=@minimoon.route("pages/self-owned-input-slots/self-owned-input-slots"),
    title="Self-owned input slots",
    build=_ => {
      let (input, update_input) = @minimoon.create_variable("initial")
      let disclosure = disclosure_with_input(
        disclosure_spec_with_input(
          id="self-disclosure",
          label="Self disclosure",
          panel=value => @minimoon.p("Self disclosure panel: " + value),
        ),
        input~,
      )
      let multiple = accordion_multiple_with_input(
        id="self-multiple",
        items=[
          accordion_item_with_input(key="one", label="Self one", panel=value => {
            @minimoon.p("Self multiple one: " + value)
          }),
          accordion_item_with_input(key="two", label="Self two", panel=value => {
            @minimoon.p("Self multiple two: " + value)
          }),
        ],
        input~,
        initial_open_keys=["missing", "two", "two"],
      )
      let tabs = tabs_with_input(
        id="self-tabs",
        items=[
          tab_item_with_input(
            key="disabled",
            label="Self disabled tab",
            disabled=true,
            panel=value => @minimoon.p("Disabled tab: " + value),
          ),
          tab_item_with_input(key="two", label="Self tab two", panel=value => {
            @minimoon.p("Self tab panel two: " + value)
          }),
          tab_item_with_input(key="three", label="Self tab three", panel=value => {
            @minimoon.p("Self tab panel three: " + value)
          }),
        ],
        input~,
        initial_selected_key="missing",
      )
      let dialog = dialog_with_input(
        dialog_spec_with_input(
          id="self-dialog",
          title="Self dialog",
          trigger_label="Open self dialog",
          content=(close, value) => {
            @minimoon.button(
              on_tap=close,
              event_key="self-dialog/content-close",
              "Self dialog content: " + value,
            )
          },
        ),
        input~,
      )
      let sheet = sheet_with_input(
        sheet_spec_with_input(
          id="self-sheet",
          title="Self sheet",
          trigger_label="Open self sheet",
          content=(_, value) => @minimoon.p("Self sheet content: " + value),
        ),
        input~,
      )
      @minimoon.Val::view5(disclosure, multiple, tabs, dialog, sheet, (
        disclosure,
        multiple,
        tabs,
        dialog,
        sheet,
      ) => {
        @minimoon.div([
          @minimoon.button(
            on_tap=update_input(_ => "latest"),
            event_key="self-input/update",
            "Update self input",
          ),
          disclosure,
          multiple,
          tabs,
          dialog,
          sheet,
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  assert_true(
    runtime.query(@testing.by_text("Self disclosure panel: initial")) is None,
  )
  assert_true(
    runtime.query(@testing.by_text("Self multiple one: initial")) is None,
  )
  assert_true(
    runtime.query(@testing.by_text("Self multiple two: initial")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Self tab panel two: initial")) is Some(_),
  )
  assert_true(runtime.query(@testing.by_text("Disabled tab: initial")) is None)
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Update self input"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self multiple two: latest")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Self tab panel two: latest")) is Some(_),
  )

  let disclosure = runtime.within(@testing.by_id("self-disclosure"))
  let _ = disclosure.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Self disclosure"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self disclosure panel: latest")) is Some(_),
  )

  let multiple = runtime.within(@testing.by_id("self-multiple"))
  let _ = multiple.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Self one")]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self multiple one: latest")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Self multiple two: latest")) is Some(_),
  )
  let _ = multiple.tap(
    @testing.all([@testing.by_role("button"), @testing.by_text("Self two")]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self multiple two: latest")) is None,
  )

  let tabs = runtime.within(@testing.by_id("self-tabs"))
  assert_scoped_tap_noop(
    runtime,
    tabs,
    @testing.all([
      @testing.by_role("tab"),
      @testing.by_text("Self disabled tab"),
    ]),
  )
  let _ = tabs.tap(
    @testing.all([@testing.by_role("tab"), @testing.by_text("Self tab three")]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self tab panel three: latest")) is Some(_),
  )
  assert_true(
    runtime.query(@testing.by_text("Self tab panel two: latest")) is None,
  )

  let dialog = runtime.within(@testing.by_id("self-dialog"))
  let _ = dialog.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Open self dialog"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self dialog content: latest")) is Some(_),
  )
  let _ = dialog.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Self dialog content: latest"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self dialog content: latest")) is None,
  )

  let sheet = runtime.within(@testing.by_id("self-sheet"))
  let _ = sheet.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Open self sheet"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Self sheet content: latest")) is Some(_),
  )
  let _ = sheet.tap(@testing.by_section("sheet-overlay"))
  assert_true(
    runtime.query(@testing.by_text("Self sheet content: latest")) is None,
  )
  let _ = runtime.dispose()
}

///|
test "input-aware controlled single accordion delegates exact state" {
  let page = @minimoon.page(
    id="controlled_single_input",
    route=@minimoon.route(
      "pages/controlled-single-input/controlled-single-input",
    ),
    title="Controlled single input",
    build=_ => {
      let (input, update_input) = @minimoon.create_variable("initial")
      let initial_open : String? = Some("one")
      let (open_key, update_open_key) = @minimoon.create_variable(initial_open)
      let accordion = accordion_single_controlled_with_input(
        id="controlled-input-single",
        items=[
          accordion_item_with_input(key="one", label="Controlled one", panel=value => {
            @minimoon.p("Controlled one panel: " + value)
          }),
          accordion_item_with_input(key="two", label="Controlled two", panel=value => {
            @minimoon.p("Controlled two panel: " + value)
          }),
          accordion_item_with_input(
            key="disabled",
            label="Controlled disabled",
            disabled=true,
            panel=value => @minimoon.p("Controlled disabled panel: " + value),
          ),
        ],
        input~,
        open_key~,
        on_change=update_open_key.map(value => _ => value),
        collapsible=false,
      )
      accordion.map(accordion => {
        @minimoon.div([
          @minimoon.button(
            on_tap=update_input(_ => "latest"),
            event_key="controlled-single-input/update",
            "Update controlled single input",
          ),
          accordion,
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  let accordion = runtime.within(@testing.by_id("controlled-input-single"))
  assert_true(
    runtime.query(@testing.by_text("Controlled one panel: initial")) is Some(_),
  )
  assert_scoped_tap_noop(
    runtime,
    accordion,
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Controlled one"),
    ]),
  )
  assert_scoped_tap_noop(
    runtime,
    accordion,
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Controlled disabled"),
    ]),
  )
  let _ = accordion.tap(
    @testing.all([
      @testing.by_role("button"),
      @testing.by_text("Controlled two"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Controlled one panel: initial")) is None,
  )
  assert_true(
    runtime.query(@testing.by_text("Controlled two panel: initial")) is Some(_),
  )
  let _ = runtime.tap(
    @testing.all([
      @testing.by_kind("button"),
      @testing.by_text("Update controlled single input"),
    ]),
  )
  assert_true(
    runtime.query(@testing.by_text("Controlled two panel: latest")) is Some(_),
  )
  let _ = runtime.dispose()
}

///|
test "panic duplicate input-aware accordion keys remain invalid" {
  let page = @minimoon.page(
    id="duplicate_input_accordion",
    route=@minimoon.route(
      "pages/duplicate-input-accordion/duplicate-input-accordion",
    ),
    title="Duplicate input accordion",
    build=_ => {
      accordion_single_with_input(
        id="duplicate",
        input=@minimoon.Val::constant("input"),
        items=[
          accordion_item_with_input(key="same", label="One", panel=value => {
            @minimoon.p(value)
          }),
          accordion_item_with_input(key="same", label="Two", panel=value => {
            @minimoon.p(value)
          }),
        ],
      )
    },
  )
  let _ = @testing.mount(page)
}

///|
test "panic duplicate input-aware tab keys remain invalid" {
  let page = @minimoon.page(
    id="duplicate_input_tabs",
    route=@minimoon.route("pages/duplicate-input-tabs/duplicate-input-tabs"),
    title="Duplicate input tabs",
    build=_ => {
      tabs_with_input(id="duplicate", input=@minimoon.Val::constant("input"), items=[
        tab_item_with_input(key="same", label="One", panel=value => {
          @minimoon.p(value)
        }),
        tab_item_with_input(key="same", label="Two", panel=value => {
          @minimoon.p(value)
        }),
      ])
    },
  )
  let _ = @testing.mount(page)
}
