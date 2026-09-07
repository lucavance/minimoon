///|
test "application local async completion survives page unload and drops after app disposal" {
  let callback : Ref[((@val.Cmd) -> Unit)?] = Ref(None)
  let cancellations = Ref(0)
  let definition = app(build=context => {
    context.create_state_with_init(
      init=_ => {
        (
          0,
          Cmd(
            @val.CmdEffect((send, _finish) => {
              callback.val = Some(send)
              fn() { cancellations.val += 1 }
            }),
          ),
        )
      },
      update=(value : Int, delta : Int, _) => (value + delta, none),
    )
  })
  let app = definition.create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let first = app.create_page(shared_counter_page(app.deps(), "async_one"))
  ignore(first.dispose())
  assert_eq(cancellations.val, 0)
  let send = callback.val.unwrap()
  send((app.deps().1)(3).0)
  ignore(app.flush())
  let second = app.create_page(shared_counter_page(app.deps(), "async_two"))
  assert_true(second.snapshot().contains("shared:3"))
  ignore(app.dispose())
  assert_eq(cancellations.val, 1)
  send((app.deps().1)(20).0)
  assert_eq(app.flush(), "[]")
  assert_eq(cancellations.val, 1)
  assert_eq(app.driver.owner.page_count(), 0)
}

///|
fn application_request_id(commands : String) -> String {
  let value = @json.parse(commands) catch { _ => abort("invalid command JSON") }
  if value is Array(commands) {
    for command in commands {
      if command is Object(fields) &&
        fields.get("type") == Some(Json::string("InvokeCapability")) &&
        fields.get("request_id") is Some(String(id)) {
        return id
      }
    }
  }
  abort("application did not issue a request")
}

///|
test "application HTTP is independent of page capabilities visibility and lifetime" {
  let definition = app(capabilities=[Request], build=context => {
    context.create_state(0, update=(_, msg : Int, emit) => {
      if msg == -1 {
        (
          0,
          request("https://httpbingo.org/get", result => {
            emit(
              match result {
                Ok(result) => result.status_code
                Err(_) => -2
              },
            )
          }),
        )
      } else {
        (msg, none)
      }
    })
  })
  let app = definition.create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let first = app.create_page(shared_counter_page(app.deps(), "http_one"))
  let id = application_request_id(app.dispatch((app.deps().1)(-1)))
  ignore(first.dispose())
  ignore(app.lifecycle("onHide", "{}"))
  assert_true(
    app.resolve_effect(id, "success", "{").contains("invalid_host_payload"),
  )
  ignore(
    app.resolve_effect(id, "success", "{\"statusCode\":201,\"data\":null}"),
  )
  ignore(app.resolve_effect(id, "success", "{\"statusCode\":500}"))
  let second = app.create_page(shared_counter_page(app.deps(), "http_two"))
  assert_true(second.snapshot().contains("shared:201"))
  let pending = application_request_id(app.dispatch((app.deps().1)(-1)))
  assert_true(app.dispose().contains("CancelEffect"))
  assert_eq(
    app.resolve_effect(pending, "success", "{\"statusCode\":200}"),
    "[]",
  )
}

///|
test "application commit survives a rejected page projection and the page can recover" {
  let app = shared_counter_app().create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let definition = page(
    id="reject_shared",
    route=route("pages/reject_shared/reject_shared"),
    title="reject_shared",
    build=context => {
      context
      .bind(deps.0)
      .view(value => {
        if value == 1 {
          div([
            button(on_tap=none, event_key="duplicate", "a"),
            button(on_tap=none, event_key="duplicate", "b"),
          ])
        } else {
          p("shared:" + value.to_string())
        }
      })
    },
  )
  let failing = app.create_page(definition)
  ignore(failing.mount())
  ignore(app.dispatch((deps.1)(1)))
  assert_true(failing.refresh().contains("RuntimeError"))
  assert_true(failing.snapshot().contains("shared:0"))
  let observer = app.create_page(shared_counter_page(deps, "committed"))
  assert_true(observer.snapshot().contains("shared:1"))
  ignore(app.dispatch((deps.1)(1)))
  ignore(failing.refresh())
  assert_true(failing.snapshot().contains("shared:2"))
  ignore(app.dispose())
}

///|
test "shared bindings leave no registered pages after repeated reuse" {
  let app = shared_counter_app().create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let definition = shared_counter_page(app.deps(), "repeated")
  for _index = 0; _index < 200; _index = _index + 1 {
    let page = app.create_page(definition)
    ignore(page.mount())
    ignore(page.dispose())
    assert_eq(app.driver.owner.page_count(), 0)
  }
  ignore(app.dispose())
}

///|
test "application state machines with different models and messages compose independently" {
  let definition = app(build=context => {
    let count = context.create_pure_state(0, update=(value, delta : Int) => {
      value + delta
    })
    let label = context.create_pure_state("initial", update=(_, value : String) => {
      value + ""
    })
    (count, label)
  })
  let app = definition.create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let page = app.create_page(
    page(id="domains", route=route("pages/domains/domains"), title="domains", build=context => {
      context
      .bind(deps.0.0)
      .view2(context.bind(deps.1.0), (count, label) => {
        p(count.to_string() + ":" + label)
      })
    }),
  )
  ignore(app.dispatch(batch([(deps.0.1)(2), (deps.1.1)("ready")])))
  ignore(page.refresh())
  assert_true(page.snapshot().contains("2:ready"))
  ignore(app.dispose())
}
