///|
fn test_layout(width : Double) -> PageLayout {
  {
    window: Some({
      window_width: width,
      window_height: 720.0,
      screen_width: width,
      screen_height: 812.0,
      screen_top: 0.0,
      status_bar_height: 44.0,
      safe_area: Some({ left: 0.0, top: 44.0, width, height: 734.0, }),
    }),
    menu_button: Some({
      left: width - 97.0,
      top: 48.0,
      width: 87.0,
      height: 32.0,
    }),
  }
}

///|
fn test_layout_width(layout : PageLayout) -> String {
  match layout.window {
    Some(window) => window.window_width.to_int().to_string()
    None => "unknown"
  }
}

///|
test "layout is injected before build separately from route input and inert preview" {
  let starts = Ref(0)
  let definition = page_with_input(
    id="layout_input",
    route=route("pages/layout/input"),
    title="Layout",
    preview_input=() => "preview",
    decode_input=fields => {
      guard fields.length() == 1 && fields.contains("id") else {
        return Err(decode_error("layout must not be mixed with route input"))
      }
      Ok(fields["id"])
    },
    build=(context, input) => {
      let (_, _) = create_state_with_init(
        init=_ => {
          (
            (),
            Cmd(
              @val.CmdEffect((_, finish) => {
                starts.val += 1
                finish()
                fn() { () }
              }),
            ),
          )
        },
        update=(_, _message : Unit, _) => no_cmd(()),
      )
      context
      .layout()
      .view(layout => {
        div("input:" + input + " width:" + test_layout_width(layout))
      })
    },
  )
  assert_true(
    definition
    .initial_tree()
    .stringify()
    .contains("input:preview width:unknown"),
  )
  assert_true(
    definition
    .initial_tree(layout=test_layout(375.0))
    .stringify()
    .contains("width:375"),
  )
  assert_eq(starts.val, 0)
  let runtime = definition
    .create_runtime(input={ "id": "actual" }, layout=test_layout(390.0))
    .unwrap()
  defer ignore(runtime.dispose())
  assert_eq(starts.val, 0)
  assert_true(
    runtime.update_layout(test_layout(400.0)).contains("page_not_loaded"),
  )
  let load = runtime.lifecycle("onLoad", "{\"id\":\"actual\"}")
  assert_true(load.contains("input:actual width:390"))
  assert_true(load.contains("\"base_revision\":0"))
  assert_true(load.contains("\"revision\":1"))
  assert_false(load.contains("unknown"))
  assert_eq(runtime.update_layout(test_layout(390.0)), "[]")
  assert_eq(
    runtime.lifecycle(
      "$minimoon:layout-show",
      ToJson::to_json(test_layout(390.0)).stringify(),
    ),
    "[]",
  )
  ignore(runtime.mount())
  assert_eq(starts.val, 1)
}

///|
test "hidden layout keeps the latest value and Show merges it with shared state" {
  let application = app(build=context => {
    context.create_pure_state(0, update=(n, d : Int) => n + d)
  }).create_runtime()
  defer ignore(application.dispose())
  ignore(application.lifecycle("onLaunch", "{}"))
  let definition = page(
    id="layout_shared",
    route=route("pages/layout/shared"),
    title="Shared layout",
    build=context => {
      let shared = context.bind(application.deps().0)
      let (shows, _) = create_state(
        0,
        update=(n, _ : Unit, _) => no_cmd(n + 1),
        subscriptions=(_, emit) => context.on_show(emit(())),
      )
      Val::view3(context.layout(), shared, shows, (layout, count, shows) => {
        div(
          "width:" +
          test_layout_width(layout) +
          " shared:" +
          count.to_string() +
          " shows:" +
          shows.to_string(),
        )
      })
    },
  )
  let runtime = application
    .create_page(definition, layout=test_layout(375.0))
    .unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.lifecycle("onShow", "{}"))
  let before = runtime.snapshot()
  ignore(runtime.lifecycle("onHide", "{}"))
  assert_eq(runtime.update_layout(test_layout(390.0)), "[]")
  assert_eq(runtime.update_layout(test_layout(420.0)), "[]")
  ignore(application.dispatch((application.deps().1)(7)))
  assert_eq(runtime.flush(), "[]")
  assert_eq(runtime.has_ready_work(), false)
  assert_eq(runtime.snapshot(), before)
  let shown = runtime.lifecycle("onShow", "{}")
  assert_eq(shown.split("\"base_revision\":").length(), 2)
  assert_true(runtime.snapshot().contains("width:420 shared:7 shows:2"))
  assert_eq(runtime.update_layout(PageLayout::unavailable()), "[]")
  ignore(runtime.dispose())
  assert_eq(runtime.update_layout(test_layout(390.0)), "[]")
  assert_eq(runtime.lifecycle("$minimoon:layout-show", "{}"), "[]")
}

///|
test "rejected layout projection rolls back its Val and accepts a later reading" {
  let observed : Ref[Val[PageLayout]?] = Ref(None)
  let definition = page(
    id="layout_rollback",
    route=route("pages/layout/rollback"),
    title="Rollback",
    build=context => {
      let layout = context.layout()
      observed.val = Some(layout)
      layout.view(layout => {
        if test_layout_width(layout) == "400" {
          div([
            button(on_tap=none, event_key="same", "a"),
            button(on_tap=none, event_key="same", "b"),
          ])
        } else {
          div("width:" + test_layout_width(layout))
        }
      })
    },
  )
  let runtime = definition.create_runtime(layout=test_layout(375.0)).unwrap()
  defer ignore(runtime.dispose())
  ignore(runtime.lifecycle("onLoad", "{}"))
  let before = runtime.snapshot()
  assert_true(
    runtime.update_layout(test_layout(400.0)).contains("RuntimeError"),
  )
  assert_eq(runtime.snapshot(), before)
  assert_eq(
    runtime.1.run(() => observed.val.unwrap().0.read()),
    test_layout(375.0),
  )
  assert_false(runtime.has_ready_work())
  assert_eq(runtime.update_layout(test_layout(375.0)), "[]")
  assert_false(
    runtime.update_layout(test_layout(410.0)).contains("RuntimeError"),
  )
  assert_true(runtime.snapshot().contains("width:410"))
}

///|
test "rejected Show rolls back layout shared projection and Show messages together" {
  let application = app(build=context => {
    context.create_pure_state(0, update=(n, d : Int) => n + d)
  }).create_runtime()
  defer ignore(application.dispose())
  ignore(application.lifecycle("onLaunch", "{}"))
  let definition = page(
    id="layout_show_rollback",
    route=route("pages/layout/show_rollback"),
    title="Show rollback",
    build=context => {
      let shared = context.bind(application.deps().0)
      let (shows, _) = create_state(
        0,
        update=(count, _ : Unit, _) => no_cmd(count + 1),
        subscriptions=(_, emit) => context.on_show(emit(())),
      )
      Val::view3(context.layout(), shared, shows, (layout, count, shows) => {
        if test_layout_width(layout) == "400" {
          div([
            button(on_tap=none, event_key="same", "a"),
            button(on_tap=none, event_key="same", "b"),
          ])
        } else {
          div(
            "width:" +
            test_layout_width(layout) +
            " shared:" +
            count.to_string() +
            " shows:" +
            shows.to_string(),
          )
        }
      })
    },
  )
  let runtime = application
    .create_page(definition, layout=test_layout(375.0))
    .unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  let before = runtime.snapshot()
  ignore(runtime.lifecycle("onHide", "{}"))
  ignore(runtime.update_layout(test_layout(400.0)))
  ignore(application.dispatch((application.deps().1)(5)))
  assert_true(runtime.lifecycle("onShow", "{}").contains("RuntimeError"))
  assert_eq(runtime.snapshot(), before)
  let recovery = runtime.lifecycle(
    "$minimoon:layout-show",
    ToJson::to_json(test_layout(410.0)).stringify(),
  )
  assert_false(recovery.contains("RuntimeError"))
  assert_eq(recovery.split("\"base_revision\":").length(), 2)
  assert_true(runtime.snapshot().contains("width:410 shared:5 shows:1"))
}

///|
test "layout decoding validates geometry and keeps unknown facts explicit" {
  let expected = test_layout(375.0)
  assert_eq(PageLayout::from_json(ToJson::to_json(expected)), expected)
  for
    value in [
      Json::null(),
      Json::array([]),
      Json::string("invalid"),
      Json::empty_object(),
    ] {
    assert_eq(PageLayout::from_json(value), PageLayout::unavailable())
  }
  let window = expected.window.unwrap()
  let invalid : PageLayout = {
    window: Some({ ..window, screen_top: 900.0, }),
    menu_button: Some({ left: 0.0, top: 0.0, width: 0.0, height: 0.0, }),
  }
  assert_eq(
    PageLayout::from_json(ToJson::to_json(invalid)),
    PageLayout::unavailable(),
  )
  assert_eq(merge_layout(invalid, expected), expected)
  let no_safe_area = {
    ..expected,
    window: Some({
      ..window,
      safe_area: Some({ left: 0.0, top: 44.0, width: 1000.0, height: 50.0, }),
    }),
  }
  assert_eq(
    PageLayout::from_json(ToJson::to_json(no_safe_area)).window.unwrap().safe_area,
    None,
  )
  assert_eq(merge_layout(no_safe_area, expected), expected)
  let missing_safe_area = {
    ..expected,
    window: Some({ ..window, safe_area: None, }),
  }
  assert_eq(merge_layout(missing_safe_area, expected), expected)
  let smaller = test_layout(320.0)
  let changed_without_safe = {
    ..smaller,
    window: Some({ ..smaller.window.unwrap(), safe_area: None, }),
  }
  assert_eq(
    merge_layout(changed_without_safe, expected).window.unwrap().safe_area,
    None,
  )
  let out_of_bounds = {
    ..expected,
    menu_button: Some({ left: 370.0, top: 48.0, width: 87.0, height: 32.0, }),
  }
  assert_eq(
    PageLayout::from_json(ToJson::to_json(out_of_bounds)).menu_button,
    None,
  )
}

///|
test "layout decoding rejects every missing nonnumeric and out-of-range dimension" {
  let expected = test_layout(375.0)
  for
    key in [
      "window_width", "window_height", "screen_width", "screen_height", "screen_top",
      "status_bar_height",
    ] {
    for
      invalid in [
        Json::null(),
        Json::string("375"),
        Json::number(-1.0),
        Json::number(1000001.0),
      ] {
      let encoded = ToJson::to_json(expected)
      guard layout_json_field(encoded, "window") is Object(fields) else {
        abort("test window is missing")
      }
      fields[key] = invalid
      assert_eq(PageLayout::from_json(encoded).window, None)
      fields.remove(key)
      assert_eq(PageLayout::from_json(encoded).window, None)
    }
  }
  for key in ["left", "top", "width", "height"] {
    for
      invalid in [
        Json::null(),
        Json::string("32"),
        Json::number(-1.0),
        Json::number(1000001.0),
      ] {
      let encoded = ToJson::to_json(expected)
      guard layout_json_field(encoded, "menu_button") is Object(fields) else {
        abort("test menu button is missing")
      }
      fields[key] = invalid
      assert_eq(PageLayout::from_json(encoded).menu_button, None)
      fields.remove(key)
      assert_eq(PageLayout::from_json(encoded).menu_button, None)
    }
  }
}
