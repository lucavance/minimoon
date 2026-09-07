///|
test "shared bindings in cached branches resume with latest state" {
  let app = shared_counter_app().create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let definition = page(
    id="branches",
    route=route("pages/branches/branches"),
    title="branches",
    build=context => {
      let (visible, toggle) = create_pure_state(true, update=(visible, _ : Unit) => {
        !visible
      })
      let branch = visible.enumerate_by(
        (initial, _) => {
          if initial {
            context.bind(deps.0).view(value => p("shared:" + value.to_string()))
          } else {
            Val::constant(p("hidden"))
          }
        },
        by=value => value.to_string(),
      )
      branch.view(node => {
        div([button(on_tap=toggle(()), event_key="toggle", "toggle"), node])
      })
    },
  )
  let page = app.create_page(definition)
  ignore(page.mount())
  ignore(page.dispatch("toggle", "{}"))
  ignore(app.dispatch((deps.1)(4)))
  assert_eq(page.refresh(), "[]")
  ignore(page.dispatch("toggle", "{}"))
  assert_true(page.snapshot().contains("shared:4"))
  for _index = 0; _index < 100; _index = _index + 1 {
    ignore(page.dispatch("toggle", "{}"))
  }
  ignore(app.dispose())
  assert_eq(app.driver.owner.page_count(), 0)
}

///|
test "panic shared values cannot bind to another application" {
  let first = shared_counter_app().create_runtime()
  let second = shared_counter_app().create_runtime()
  defer ignore(first.dispose())
  defer ignore(second.dispose())
  ignore(second.create_page(shared_counter_page(first.deps(), "foreign")))
}

///|
test "panic shared values cannot bind to an unattached page" {
  let app = shared_counter_app().create_runtime()
  defer ignore(app.dispose())
  ignore(shared_counter_page(app.deps(), "unattached").create_runtime())
}

///|
test "panic shared values cannot bind after their application is disposed" {
  let first = shared_counter_app().create_runtime()
  let deps = first.deps()
  ignore(first.dispose())
  let second = shared_counter_app().create_runtime()
  defer ignore(second.dispose())
  ignore(second.create_page(shared_counter_page(deps, "obsolete")))
}
