///|
fn form_batch(keys : Array[String]) -> String {
  Json::array(
    keys.map(key => {
      Json::object({ "key": Json::string(key), "payload": Json::empty_object() })
    }),
  ).stringify()
}

///|
test "multiple ToggleGroup merges same-frame option taps" {
  let runtime = form_test_page(_ => {
      toggle_group(
        id="group",
        multiple=true,
        options=@minimoon.Val::constant([
          choice_option(key="a", label="A"),
          choice_option(key="b", label="B"),
        ]),
      )
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(form_batch(["group/a", "group/b"]))
  assert_false(dispatched.contains("RuntimeError"))
  assert_eq(runtime.snapshot().split("\"ariaSelected\":true").length(), 3)
}

///|
test "multiple Accordion merges same-frame panel taps" {
  let runtime = form_test_page(_ => {
      accordion(
        id="accordion",
        multiple=true,
        items=@minimoon.Val::constant([
          panel(key="a", title="A", content=@minimoon.text("First")),
          panel(key="b", title="B", content=@minimoon.text("Second")),
        ]),
      )
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(
    form_batch(["accordion/a", "accordion/b"]),
  )
  assert_false(dispatched.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("\"text\":\"First\""))
  assert_true(runtime.snapshot().contains("\"text\":\"Second\""))
}

///|
test "repeated same-frame Toggle taps cancel each other" {
  let runtime = form_test_page(_ => {
      toggle(
        id="toggle",
        content=@minimoon.Val::constant(@minimoon.text("Toggle")),
      )
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(
    form_batch(["toggle/toggle", "toggle/toggle"]),
  )
  assert_false(dispatched.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("\"ariaSelected\":false"))
}

///|
test "controlled ToggleGroup reads parent state after each batch request" {
  let runtime = form_test_page(_ => {
      let (value, update) = @minimoon.create_variable([])
      toggle_group_controlled(
        id="group",
        multiple=true,
        value~,
        on_change=update.map(value => _ => value),
        options=@minimoon.Val::constant([
          choice_option(key="a", label="A"),
          choice_option(key="b", label="B"),
        ]),
      )
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(
    form_batch(["group/a", "group/b", "group/a"]),
  )
  assert_false(dispatched.contains("RuntimeError"))
  assert_eq(runtime.snapshot().split("\"ariaSelected\":true").length(), 2)
  let dispatched = runtime.dispatch_batch(form_batch(["group/b", "group/b"]))
  assert_false(dispatched.contains("RuntimeError"))
  assert_eq(runtime.snapshot().split("\"ariaSelected\":true").length(), 2)
}

///|
test "same-frame external option change prevents stale ToggleGroup activation" {
  let runtime = form_test_page(_ => {
      let (options, update) = @minimoon.create_variable([
        choice_option(key="a", label="A"),
        choice_option(key="b", label="B"),
      ])
      toggle_group(id="group", options~, multiple=true).map(node => {
        @minimoon.div([
          button(
            event_key="disable",
            on_tap=update(options => {
              options.map(option => { ..option, disabled: true, })
            }),
            "Disable",
          ),
          node,
        ])
      })
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(form_batch(["disable", "group/a"]))
  assert_false(dispatched.contains("RuntimeError"))
  assert_false(runtime.snapshot().contains("\"ariaSelected\":true"))
}

///|
test "repeated same-frame Accordion and Collapsible taps close again" {
  let runtime = form_test_page(_ => {
      stack([
        accordion(
          id="accordion",
          multiple=true,
          items=@minimoon.Val::constant([
            panel(
              key="a",
              title="A",
              content=@minimoon.text("Accordion secret"),
            ),
          ]),
        ),
        collapsible(
          id="collapse",
          title="Collapse",
          content=@minimoon.Val::constant(@minimoon.text("Collapsible secret")),
        ),
      ])
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(
    form_batch([
      "accordion/a", "accordion/a", "collapse/toggle", "collapse/toggle",
    ]),
  )
  assert_false(dispatched.contains("RuntimeError"))
  assert_false(runtime.snapshot().contains("\"text\":\"Accordion secret\""))
  assert_false(runtime.snapshot().contains("\"text\":\"Collapsible secret\""))
}

///|
test "OTP completion observes the preceding input in the same frame" {
  let runtime = form_test_page(_ => {
      let (completed, update) = @minimoon.create_variable(0)
      let otp = input_otp(
        id="otp",
        length=4,
        on_complete=update.map(_ => count => count + 1),
      )
      @minimoon.Val::map2(otp, completed, (otp, count) => {
        @minimoon.div([otp, @minimoon.text("Completed:" + count.to_string())])
      })
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(
    Json::array(
      ["1234", "5678"].map(value => {
        Json::object({
          "key": Json::string("otp/input"),
          "payload": Json::object({
            "detail": Json::object({ "value": Json::string(value) }),
          }),
        })
      }),
    ).stringify(),
  )
  assert_false(dispatched.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("\"text\":\"Completed:1\""))
}

///|
test "native choice keys are checked against current options after frame decode" {
  let runtime = form_test_page(_ => {
      let (options, update_options) = @minimoon.create_variable([
        choice_option(key="a", label="A"),
        choice_option(key="b", label="B"),
      ])
      let (changes, update_changes) = @minimoon.create_variable(0)
      let on_change = update_changes.map((_ : String) => count => count + 1)
      let controls = stack([
        radio_group_controlled(
          id="radio",
          options~,
          value=@minimoon.Val::constant("b"),
          on_change~,
        ),
        native_select_controlled(
          id="picker",
          options~,
          value=@minimoon.Val::constant("b"),
          on_change~,
        ),
      ])
      @minimoon.Val::map2(controls, changes, (controls, changes) => {
        @minimoon.div([
          button(
            event_key="remove",
            on_tap=update_options(options => {
              options.filter(option => option.key != "a")
            }),
            "Remove A",
          ),
          controls,
          @minimoon.text("Changes:" + changes.to_string()),
        ])
      })
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(
    "[{\"key\":\"remove\",\"payload\":{}},{\"key\":\"radio/change\",\"payload\":{\"detail\":{\"value\":\"a\"}}},{\"key\":\"picker/change\",\"payload\":{\"detail\":{\"value\":0}}}]",
  )
  assert_false(dispatched.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("\"text\":\"Changes:0\""))
}

///|
test "Tabs reject a panel removed earlier in the same frame" {
  let runtime = form_test_page(_ => {
      let (items, update_items) = @minimoon.create_variable([
        panel(key="a", title="A", content=@minimoon.text("A panel")),
        panel(key="b", title="B", content=@minimoon.text("B panel")),
      ])
      let (changes, update_changes) = @minimoon.create_variable(0)
      let tabs = tabs_controlled(
        id="tabs",
        items~,
        selected=@minimoon.Val::constant(Some("b")),
        on_change=update_changes.map((_ : String?) => count => count + 1),
      )
      @minimoon.Val::map2(tabs, changes, (tabs, changes) => {
        @minimoon.div([
          button(
            event_key="remove",
            on_tap=update_items(items => items.filter(item => item.key != "a")),
            "Remove A",
          ),
          tabs,
          @minimoon.text("Changes:" + changes.to_string()),
        ])
      })
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  let dispatched = runtime.dispatch_batch(form_batch(["remove", "tabs/a"]))
  assert_false(dispatched.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("\"text\":\"Changes:0\""))
}
