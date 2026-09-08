///|
using @styles {
  accordion_item_with_input,
  accordion_multiple_controlled_with_input,
  accordion_multiple_with_input,
  accordion_single_controlled_with_input,
  accordion_single_with_input,
  dialog_controlled_with_input,
  dialog_spec_with_input,
  dialog_with_input,
  disclosure_controlled_with_input,
  disclosure_spec_with_input,
  disclosure_with_input,
  sheet_controlled_with_input,
  sheet_spec_with_input,
  sheet_with_input,
  tab_item_with_input,
  tabs_controlled_with_input,
  tabs_with_input,
}

///|
test "styled input-aware components preserve the minimal v1 class contract" {
  let page = @minimoon.page(
    id="styled_input_slots",
    route=@minimoon.route("pages/styled-input-slots/styled-input-slots"),
    title="Styled input slots",
    build=_ => {
      let input = @minimoon.Val::constant("styled")
      let disclosure = disclosure_with_input(
        disclosure_spec_with_input(
          id="styled-disclosure",
          label="Styled disclosure",
          panel=value => @minimoon.p(value),
        ),
        input~,
        initially_expanded=true,
      )
      let accordion = accordion_single_with_input(
        id="styled-accordion",
        items=[
          accordion_item_with_input(key="one", label="Styled accordion", panel=value => {
            @minimoon.p(value)
          }),
        ],
        input~,
        initial_open_key="one",
      )
      let tabs = tabs_with_input(
        id="styled-tabs",
        items=[
          tab_item_with_input(key="one", label="Styled tab", panel=value => {
            @minimoon.p(value)
          }),
        ],
        input~,
      )
      let dialog = dialog_with_input(
        dialog_spec_with_input(
          id="styled-dialog",
          title="Styled dialog",
          trigger_label="Open styled dialog",
          content=(_, value) => @minimoon.p(value),
        ),
        input~,
        initially_open=true,
      )
      let sheet = sheet_with_input(
        sheet_spec_with_input(
          id="styled-sheet",
          title="Styled sheet",
          trigger_label="Open styled sheet",
          side=Left,
          content=(_, value) => @minimoon.p(value),
        ),
        input~,
        initially_open=true,
      )
      @minimoon.Val::view5(disclosure, accordion, tabs, dialog, sheet, (
        a,
        b,
        c,
        d,
        e,
      ) => @minimoon.div([a, b, c, d, e]))
    },
  )
  let runtime = page.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  let _ = runtime.mount()
  let snapshot = runtime.snapshot()
  assert_true(snapshot.contains("mm-disclosure__panel"))
  assert_true(snapshot.contains("mm-accordion__panel"))
  assert_true(snapshot.contains("mm-tabs__tab--active"))
  assert_true(snapshot.contains("mm-dialog__surface"))
  assert_true(snapshot.contains("mm-sheet__surface sheet--left"))
}

///|
test "styled controlled and multiple input variants preserve classes" {
  let page = @minimoon.page(
    id="styled_controlled_input_slots",
    route=@minimoon.route(
      "pages/styled-controlled-input-slots/styled-controlled-input-slots",
    ),
    title="Styled controlled input slots",
    build=_ => {
      let input = @minimoon.Val::constant("styled")
      let (expanded, update_expanded) = @minimoon.create_variable(true)
      let initial_open_key : String? = Some("one")
      let (open_key, update_open_key) = @minimoon.create_variable(
        initial_open_key,
      )
      let initial_open_keys : Array[String] = ["one"]
      let (open_keys, update_open_keys) = @minimoon.create_variable(
        initial_open_keys,
      )
      let initial_selected : String? = Some("one")
      let (selected, update_selected) = @minimoon.create_variable(
        initial_selected,
      )
      let (dialog_open, update_dialog_open) = @minimoon.create_variable(true)
      let (sheet_open, update_sheet_open) = @minimoon.create_variable(true)
      let disclosure = disclosure_controlled_with_input(
        disclosure_spec_with_input(
          id="styled-controlled-disclosure",
          label="Styled controlled disclosure",
          panel=value => @minimoon.p(value),
        ),
        input~,
        expanded~,
        on_change=update_expanded.map(value => _ => value),
      )
      let accordion_items = [
        accordion_item_with_input(key="one", label="Styled one", panel=value => {
          @minimoon.p(value)
        }),
      ]
      let single = accordion_single_controlled_with_input(
        id="styled-controlled-single",
        items=accordion_items,
        input~,
        open_key~,
        on_change=update_open_key.map(value => _ => value),
      )
      let multiple = accordion_multiple_with_input(
        id="styled-owned-multiple",
        items=accordion_items,
        input~,
        initial_open_keys=["one"],
      )
      let controlled_multiple = accordion_multiple_controlled_with_input(
        id="styled-controlled-multiple",
        items=accordion_items,
        input~,
        open_keys~,
        on_change=update_open_keys.map(value => _ => value),
        orientation=Horizontal,
      )
      let tabs = tabs_controlled_with_input(
        id="styled-controlled-tabs",
        items=[
          tab_item_with_input(key="one", label="Styled tab", panel=value => {
            @minimoon.p(value)
          }),
        ],
        input~,
        selected_key=selected,
        on_change=update_selected.map(value => _ => value),
        orientation=Vertical,
      )
      let dialog = dialog_controlled_with_input(
        dialog_spec_with_input(
          id="styled-controlled-dialog",
          title="Styled controlled dialog",
          trigger_label="Open styled controlled dialog",
          content=(_, value) => @minimoon.p(value),
        ),
        input~,
        open=dialog_open,
        on_change=update_dialog_open.map(value => _ => value),
      )
      let sheet = sheet_controlled_with_input(
        sheet_spec_with_input(
          id="styled-controlled-sheet",
          title="Styled controlled sheet",
          trigger_label="Open styled controlled sheet",
          side=Left,
          content=(_, value) => @minimoon.p(value),
        ),
        input~,
        open=sheet_open,
        on_change=update_sheet_open.map(value => _ => value),
      )
      @minimoon.Val::view7(
        disclosure,
        single,
        multiple,
        controlled_multiple,
        tabs,
        dialog,
        sheet,
        (a, b, c, d, e, f, g) => @minimoon.div([a, b, c, d, e, f, g]),
      )
    },
  )
  let runtime = page.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  let _ = runtime.mount()
  let snapshot = runtime.snapshot()
  assert_true(snapshot.contains("styled-controlled-disclosure"))
  assert_true(snapshot.contains("styled-controlled-single"))
  assert_true(snapshot.contains("styled-owned-multiple"))
  assert_true(snapshot.contains("styled-controlled-multiple"))
  assert_true(snapshot.contains("styled-controlled-tabs"))
  assert_true(snapshot.contains("styled-controlled-dialog"))
  assert_true(snapshot.contains("styled-controlled-sheet"))
  assert_true(snapshot.contains("mm-disclosure__panel"))
  assert_true(snapshot.contains("mm-accordion__panel"))
  assert_true(snapshot.contains("mm-tabs__tab--active"))
  assert_true(snapshot.contains("\"ariaOrientation\":\"horizontal\""))
  assert_true(snapshot.contains("\"ariaOrientation\":\"vertical\""))
  assert_true(snapshot.contains("mm-dialog__surface"))
  assert_true(snapshot.contains("mm-sheet__surface sheet--left"))
  let _ = runtime.dispose()
}
