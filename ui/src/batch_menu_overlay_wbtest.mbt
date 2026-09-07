///|
fn root_batch(keys : Array[String]) -> String {
  Json::array(
    keys.map(key => {
      Json::object({ "key": Json::string(key), "payload": Json::empty_object() })
    }),
  ).stringify()
}

///|
test "closed confirmation command menu and toast reject queued duplicate actions" {
  let runtime = advanced_native_page(context => {
    let (count, emit) = @minimoon.create_variable(0)
    stack([
      alert_dialog(
        context,
        id="once-alert",
        title="Confirm",
        trigger_label="Open",
        content=@minimoon.Val::constant(@minimoon.nothing()),
        on_confirm=emit(value => value + 1),
      ),
      command_dialog(
        context,
        id="once-command",
        title="Command",
        trigger_label="Open",
        on_value_select=emit.map(_ => value => value + 10),
        render=scope => {
          command_item(
            scope,
            value="run",
            on_click=emit(value => value + 100),
            @minimoon.text("Run"),
          )
        },
      ),
      dropdown_menu(
        context,
        id="once-menu",
        trigger_label="Menu",
        items=@minimoon.Val::constant([
          menu_item(
            key="run",
            label="Run",
            on_select=emit(value => value + 100000),
          ),
        ]),
      ),
      @minimoon.Val::constant(
        @minimoon.button(
          event_key="once-notify",
          on_tap=toast(
            context,
            toast_notice(
              id="once-toast",
              title="Notice",
              action_label="Act",
              action=emit(value => value + 1000),
              on_close=emit(value => value + 10000),
            ),
          ),
          "Notify",
        ),
      ),
      toaster(context),
      count.map(value => {
        @minimoon.div(
          id="once-count",
          data_section=value.to_string(),
          value.to_string(),
        )
      }),
    ])
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch("once-alert/trigger", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["once-alert/confirm", "once-alert/confirm"]),
  )
  assert_eq(
    native_prop(runtime, "once-count", "section"),
    Some(Json::string("1")),
  )
  let _ = runtime.dispatch("once-command/trigger", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["once-command/item/run", "once-command/item/run"]),
  )
  assert_eq(
    native_prop(runtime, "once-count", "section"),
    Some(Json::string("111")),
  )
  let _ = runtime.dispatch("once-notify", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["toast/once-toast/action", "toast/once-toast/action"]),
  )
  assert_eq(
    native_prop(runtime, "once-count", "section"),
    Some(Json::string("11111")),
  )
  let _ = runtime.dispatch("once-menu/trigger", "{}")
  let _ = runtime.dispatch_batch(root_batch(["once-menu/run", "once-menu/run"]))
  assert_eq(
    native_prop(runtime, "once-count", "section"),
    Some(Json::string("111111")),
  )
  let _ = runtime.dispose()
}

///|
test "both single combobox APIs reject another predecoded choice after closing" {
  let runtime = advanced_native_page(context => {
    let (simple, change_simple) = @minimoon.create_variable("")
    let (state, change_state) = @minimoon.create_variable(combobox_state())
    let options = @minimoon.Val::constant([
      choice_option(key="a", label="A"),
      choice_option(key="b", label="B"),
    ])
    stack([
      combobox_controlled(
        context,
        id="once-simple",
        label="Simple",
        options~,
        value=simple,
        on_change=change_simple.map(value => _ => value),
      ),
      combobox_provider_controlled(
        context,
        id="once-provider",
        options~,
        state~,
        on_change=change_state.map(value => _ => value),
      ),
      simple.map(value => {
        @minimoon.div(id="simple-value", data_section=value, value)
      }),
      state.map(state => {
        @minimoon.div(
          id="provider-value",
          data_section=state.values.join(","),
          state.values.join(","),
        )
      }),
    ])
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch("once-simple/trigger", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["once-simple/option/a", "once-simple/option/b"]),
  )
  assert_eq(
    native_prop(runtime, "simple-value", "section"),
    Some(Json::string("a")),
  )
  let _ = runtime.dispatch("once-provider/open", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["once-provider/option/a", "once-provider/option/b"]),
  )
  assert_eq(
    native_prop(runtime, "provider-value", "section"),
    Some(Json::string("a")),
  )
  let _ = runtime.dispose()
}

///|
test "menu dispatch observes current checked state across one native event batch" {
  let runtime = advanced_native_page(context => {
    let (checked, emit) = @minimoon.create_variable(false)
    let items = checked.map(checked => {
      [
        menu_checkbox_item(
          key="check",
          label="Check",
          checked~,
          on_change=emit.map(value => _ => value),
        ),
        menu_submenu(key="branch", label="Branch", items=[
          menu_item(key="leaf", label="Leaf", on_select=@minimoon.none),
        ]),
      ]
    })
    dropdown_menu(context, id="batch-menu", trigger_label="Menu", items~)
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch("batch-menu/trigger", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["batch-menu/check", "batch-menu/check"]),
  )
  assert_false(runtime.snapshot().contains("\"ariaChecked\":true"))
  let _ = runtime.dispatch_batch(
    root_batch(["batch-menu/branch", "batch-menu/branch"]),
  )
  assert_false(runtime.snapshot().contains("\"text\":\"Leaf\""))
  let _ = runtime.dispose()
}

///|
test "overlay toggles and action guards read current open state in native batches" {
  let runtime = advanced_native_page(context => {
    let (count, emit) = @minimoon.create_variable(0)
    stack([
      overlay_provider(context, id="batch-overlay", force_mount=true, render=scope => {
        @minimoon.fragment([
          overlay_trigger(scope, "Toggle"),
          overlay_content(scope, [
            overlay_action(scope, "Action", on_tap=emit(value => value + 1)),
            overlay_title(scope, "Overlay"),
          ]),
        ])
      }),
      count.map(value => @minimoon.div(id="action-count", value.to_string())),
    ])
  })
  let _ = runtime.mount()
  let _ = runtime.dispatch_batch(
    root_batch(["batch-overlay/trigger", "batch-overlay/trigger"]),
  )
  assert_eq(
    native_prop(runtime, "batch-overlay-surface", "ariaHidden"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.dispatch("batch-overlay/trigger", "{}")
  let _ = runtime.dispatch_batch(
    root_batch(["batch-overlay/action", "batch-overlay/action"]),
  )
  assert_true(runtime.snapshot().contains("\"text\":\"1\""))
  assert_false(runtime.snapshot().contains("\"text\":\"2\""))
  assert_eq(
    native_prop(runtime, "batch-overlay-surface", "ariaHidden"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.dispose()
}
