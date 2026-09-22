///|
fn lifecycle_test_effect(run : () -> Unit) -> Cmd {
  Cmd(
    @val.CmdEffect((_, finish) => {
      run()
      finish()
      fn() { () }
    }),
  )
}

///|
fn lifecycle_test_error(runtime : PageRuntime, output : String) -> Unit raise {
  assert_eq(
    @json.parse(output),
    Json::array([
      Json::object({
        "type": Json::string("RuntimeError"),
        "component_id": Json::string(runtime.page_id()),
        "code": Json::string("lifecycle_decode_failed"),
        "message": Json::string("rejected lifecycle"),
      }),
    ]),
  )
}

///|
test "page lifecycle decode failures reject sibling commands and preserve diagnostics" {
  let hooks : Array[PageLifecycleHook] = [
    Show,
    Hide,
    Unload,
    PullDownRefresh,
    ReachBottom,
  ]
  for hook in hooks {
    let reject = Ref(true)
    let decodes = Ref(0)
    let effects = Ref(0)
    let runtime = page(
        id="lifecycle_decode",
        route=route("pages/lifecycle/decode"),
        title="Lifecycle decode",
        build=context => {
          let (count, _) = create_state(
            0,
            update=(count, _ : Unit, _) => {
              (count + 1, lifecycle_test_effect(fn() { effects.val += 1 }))
            },
            subscriptions=(_, emit) => {
              Sub::batch([
                context.lifecycle(hook, _ => Ok(emit(()))),
                context.lifecycle(hook, _ => {
                  decodes.val += 1
                  if reject.val {
                    Err(decode_error("rejected lifecycle"))
                  } else {
                    Ok(none)
                  }
                }),
              ])
            },
          )
          count.view(value => text(value.to_string()))
        },
      )
      .create_runtime()
      .unwrap()
    ignore(runtime.lifecycle("onLoad", "{}"))
    ignore(runtime.mount())
    let before = runtime.snapshot()
    lifecycle_test_error(runtime, runtime.lifecycle(hook.host_name(), "{}"))
    assert_eq(decodes.val, 1)
    assert_eq(effects.val, 0)
    assert_eq(runtime.snapshot(), before)
    reject.val = false
    let accepted = runtime.lifecycle(hook.host_name(), "{}")
    assert_false(accepted.contains("RuntimeError"))
    assert_eq(decodes.val, 2)
    assert_eq(effects.val, 1)
    assert_true(runtime.snapshot().contains("\"text\":\"1\""))
    ignore(runtime.dispose())
    assert_eq(runtime.lifecycle(hook.host_name(), "{}"), "[]")
  }
}

///|
test "rejected Load remains retryable and does not consume boot or init commands" {
  let reject = Ref(true)
  let starts = Ref(0)
  let runtime = page(
      id="lifecycle_load",
      route=route("pages/lifecycle/load"),
      title="Lifecycle load",
      build=context => {
        let (count, _) = create_state_with_init(
          init=_ => (0, lifecycle_test_effect(fn() { starts.val += 1 })),
          update=(count, _ : Unit, _) => no_cmd(count + 1),
          subscriptions=(_, emit) => {
            Sub::batch([
              context.on_load(emit(())),
              context.lifecycle(Load, _ => {
                if reject.val {
                  Err(decode_error("rejected lifecycle"))
                } else {
                  Ok(none)
                }
              }),
            ])
          },
        )
        count.view(value => text(value.to_string()))
      },
    )
    .create_runtime()
    .unwrap()
  defer ignore(runtime.dispose())
  let before = runtime.snapshot()
  lifecycle_test_error(runtime, runtime.lifecycle("onLoad", "{}"))
  assert_eq(runtime.snapshot(), before)
  assert_eq(starts.val, 0)
  assert_true(runtime.mount().contains("page_not_loaded"))
  assert_true(runtime.lifecycle("onShow", "{}").contains("page_not_loaded"))
  assert_true(runtime.dispatch("missing", "{}").contains("page_not_loaded"))
  assert_false(runtime.has_ready_work())
  reject.val = false
  let accepted = runtime.lifecycle("onLoad", "{}")
  assert_false(accepted.contains("RuntimeError"))
  assert_true(accepted.contains("ReplaceViewTree"))
  assert_true(accepted.contains("\"base_revision\":0"))
  assert_true(accepted.contains("\"revision\":1"))
  assert_true(runtime.snapshot().contains("\"text\":\"1\""))
  assert_eq(starts.val, 0)
  ignore(runtime.mount())
  assert_eq(starts.val, 1)
  assert_eq(runtime.mount(), "[]")
  assert_true(runtime.lifecycle("onLoad", "{}").contains("duplicate_page_load"))
  assert_eq(starts.val, 1)
}

///|
test "Show decoders observe staged layout and shared state and failure rolls both back" {
  let application = app(build=context => {
    context.create_pure_state(0, update=(count, delta : Int) => count + delta)
  }).create_runtime()
  defer ignore(application.dispose())
  ignore(application.lifecycle("onLaunch", "{}"))
  let reject = Ref(false)
  let observed : Array[(String, Int)] = []
  let inputs : Ref[Val[(PageLayout, Int)]?] = Ref(None)
  let definition = page(
    id="lifecycle_show",
    route=route("pages/lifecycle/show"),
    title="Lifecycle show",
    build=context => {
      let input = Val::map2(
        context.layout(),
        context.bind(application.deps().0),
        (layout, shared) => (layout, shared),
      )
      inputs.val = Some(input)
      let (shows, _) = create_state_with_input(
        input~,
        init=(_, _) => no_cmd(0),
        update=(count, _, _ : Unit, _) => no_cmd(count + 1),
        subscriptions=(_, input, emit) => {
          Sub::batch([
            context.on_show(emit(())),
            context.lifecycle(Show, _ => {
              observed.push((test_layout_width(input.0), input.1))
              if reject.val {
                Err(decode_error("rejected lifecycle"))
              } else {
                Ok(none)
              }
            }),
          ])
        },
      )
      Val::view2(input, shows, (input, shows) => {
        text(
          "width:" +
          test_layout_width(input.0) +
          " shared:" +
          input.1.to_string() +
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
  ignore(runtime.mount())
  ignore(runtime.lifecycle("onShow", "{}"))
  ignore(runtime.lifecycle("onHide", "{}"))
  let before = runtime.snapshot()
  assert_eq(runtime.update_layout(test_layout(420.0)), "[]")
  ignore(application.dispatch((application.deps().1)(7)))
  assert_eq(runtime.flush(), "[]")
  reject.val = true
  lifecycle_test_error(runtime, runtime.lifecycle("onShow", "{}"))
  assert_eq(observed, [("375", 0), ("420", 7)])
  assert_eq(runtime.snapshot(), before)
  assert_eq(
    runtime.1.run(() => inputs.val.unwrap().0.read()),
    (test_layout(375.0), 0),
  )
  // Visibility follows the host even though this Show's graph writes rolled back.
  assert_true(runtime.has_ready_work())
  reject.val = false
  let accepted = runtime.lifecycle(
    "$minimoon:layout-show",
    ToJson::to_json(test_layout(430.0)).stringify(),
  )
  assert_false(accepted.contains("RuntimeError"))
  assert_eq(accepted.split("\"base_revision\":").length(), 2)
  assert_eq(observed, [("375", 0), ("420", 7), ("430", 7)])
  assert_true(runtime.snapshot().contains("width:430 shared:7 shows:2"))
}

///|
test "rejected Hide still defers shared and layout updates until the host shows the page" {
  let application = app(build=context => {
    context.create_pure_state(0, update=(count, delta : Int) => count + delta)
  }).create_runtime()
  defer ignore(application.dispose())
  ignore(application.lifecycle("onLaunch", "{}"))
  let definition = page(
    id="lifecycle_hide",
    route=route("pages/lifecycle/hide"),
    title="Lifecycle hide",
    build=context => {
      let (_, _) = create_state((), update=(_, _ : Unit, _) => no_cmd(()), subscriptions=(
        _,
        _,
      ) => context.lifecycle(Hide, _ => Err(decode_error("rejected lifecycle"))))
      Val::view2(context.layout(), context.bind(application.deps().0), (
        layout,
        shared,
      ) => {
        text(
          "width:" + test_layout_width(layout) + " shared:" + shared.to_string(),
        )
      })
    },
  )
  let runtime = application
    .create_page(definition, layout=test_layout(375.0))
    .unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  let before = runtime.snapshot()
  lifecycle_test_error(runtime, runtime.lifecycle("onHide", "{}"))
  assert_eq(runtime.update_layout(test_layout(420.0)), "[]")
  ignore(application.dispatch((application.deps().1)(9)))
  assert_false(runtime.has_ready_work())
  assert_eq(runtime.flush(), "[]")
  assert_eq(runtime.snapshot(), before)
  let shown = runtime.lifecycle("onShow", "{}")
  assert_false(shown.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("width:420 shared:9"))
}

///|
test "lifecycle decode rollback discards dynamically prepared scope init effects" {
  let reject = Ref(false)
  let started : Array[String] = []
  let runtime = page(
      id="lifecycle_dynamic",
      route=route("pages/lifecycle/dynamic"),
      title="Lifecycle dynamic",
      build=context => {
        let width = context
          .layout()
          .switch_by(
            (layout, _) => {
              let width = test_layout_width(layout)
              let (value, _) = create_state_with_init(
                init=_ => {
                  (width, lifecycle_test_effect(fn() { started.push(width) }))
                },
                update=(_, width : String, _) => no_cmd(width),
              )
              value
            },
            by=test_layout_width,
          )
        let (shows, _) = create_state_with_input(
          input=width,
          init=(_, _) => no_cmd(0),
          update=(count, _, _ : Unit, _) => no_cmd(count + 1),
          subscriptions=(_, _, emit) => {
            Sub::batch([
              context.on_show(emit(())),
              context.lifecycle(Show, _ => {
                if reject.val {
                  Err(decode_error("rejected lifecycle"))
                } else {
                  Ok(none)
                }
              }),
            ])
          },
        )
        Val::view2(width, shows, (width, shows) => {
          text("width:" + width + " shows:" + shows.to_string())
        })
      },
    )
    .create_runtime(layout=test_layout(375.0))
    .unwrap()
  defer ignore(runtime.dispose())
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  assert_eq(started, ["375"])
  ignore(runtime.lifecycle("onHide", "{}"))
  let before = runtime.snapshot()
  ignore(runtime.update_layout(test_layout(400.0)))
  reject.val = true
  lifecycle_test_error(runtime, runtime.lifecycle("onShow", "{}"))
  assert_eq(runtime.snapshot(), before)
  assert_eq(started, ["375"])
  reject.val = false
  let accepted = runtime.lifecycle(
    "$minimoon:layout-show",
    ToJson::to_json(test_layout(410.0)).stringify(),
  )
  assert_false(accepted.contains("RuntimeError"))
  assert_true(runtime.snapshot().contains("width:410 shows:1"))
  assert_eq(started, ["375", "410"])
  ignore(runtime.flush())
  assert_eq(started, ["375", "410"])
}
