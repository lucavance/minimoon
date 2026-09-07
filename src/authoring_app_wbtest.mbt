///|
fn shared_counter_app() -> App[(Shared[Int], Emit[Int])] {
  app(build=context => {
    context.create_pure_state(0, update=(count, delta) => count + delta)
  })
}

///|
fn shared_counter_page(deps : (Shared[Int], Emit[Int]), id : String) -> Page {
  page(id~, route=route("pages/" + id + "/" + id), title=id, build=context => {
    let count = context.bind(deps.0)
    let (page_count, emit_local) = create_pure_state(0, update=(
      count,
      delta : Int,
    ) => count + delta)
    Val::view2(count, page_count, (count, page_count) => {
      div([
        p("shared:" + count.to_string()),
        p("local:" + page_count.to_string()),
        button(on_tap=(deps.1)(1), event_key="shared", "shared"),
        button(on_tap=emit_local(1), event_key="local", "local"),
      ])
    })
  })
}

///|
test "application values share between page instances while local state is isolated" {
  let app = shared_counter_app().create_runtime()
  assert_eq(app.lifecycle("onLaunch", "{}"), "[]")
  let page = shared_counter_page(app.deps(), "one")
  let first = app.create_page(page)
  let second = app.create_page(page)
  ignore(first.mount())
  ignore(second.mount())
  ignore(first.dispatch("shared", "{}"))
  assert_true(second.snapshot().contains("shared:0"))
  ignore(app.flush())
  ignore(first.refresh())
  ignore(second.refresh())
  assert_true(first.snapshot().contains("shared:1"))
  assert_true(second.snapshot().contains("shared:1"))
  ignore(first.dispatch("local", "{}"))
  assert_true(first.snapshot().contains("local:1"))
  assert_true(second.snapshot().contains("local:0"))
  assert_eq(app.driver.owner.page_count(), 2)
  ignore(first.dispose())
  assert_eq(app.driver.owner.page_count(), 1)
  ignore(app.dispatch((app.deps().1)(2)))
  ignore(second.refresh())
  assert_true(second.snapshot().contains("shared:3"))
  ignore(second.dispose())
  assert_eq(app.driver.owner.page_count(), 0)
  let again = app.create_page(page)
  assert_true(again.snapshot().contains("shared:3"))
  ignore(app.dispose())
  assert_eq(app.dispose(), "[]")
  assert_eq(again.dispatch("shared", "{}"), "[]")
}

///|
test "page disposal does not cancel a committed application message" {
  let app = shared_counter_app().create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let first = app.create_page(shared_counter_page(app.deps(), "first"))
  ignore(first.mount())
  ignore(first.dispatch("shared", "{}"))
  ignore(first.dispose())
  ignore(app.flush())
  let second = app.create_page(shared_counter_page(app.deps(), "second"))
  assert_true(second.snapshot().contains("shared:1"))
  ignore(app.dispose())
}

///|
test "application inbox requests another wake after its bounded drain" {
  let app = shared_counter_app().create_runtime()
  defer ignore(app.dispose())
  ignore(app.lifecycle("onLaunch", "{}"))
  let page = app.create_page(shared_counter_page(app.deps(), "burst"))
  ignore(page.mount())
  let wakes = Ref(0)
  app.driver.owner.set_wake(fn() { wakes.val += 1 })
  for _index = 0; _index < 3000; _index = _index + 1 {
    ignore(page.dispatch("shared", "{}"))
  }
  assert_eq(app.driver.owner.pending_count(), 3000)
  wakes.val = 0
  ignore(app.flush())
  assert_eq(app.driver.owner.pending_count(), 952)
  assert_eq(wakes.val, 1)
  ignore(page.refresh())
  assert_true(page.snapshot().contains("shared:2048"))
  ignore(app.flush())
  assert_eq(app.driver.owner.pending_count(), 0)
  assert_eq(wakes.val, 1)
  ignore(page.refresh())
  assert_true(page.snapshot().contains("shared:3000"))
  ignore(app.flush())
  assert_eq(wakes.val, 1)
}

///|
test "application initialization is launch-only and previews do not dispatch" {
  let starts = Ref(0)
  let definition = app(build=context => {
    context.create_state_with_init(
      init=emit => {
        (
          0,
          Cmd(
            @val.CmdEffect((send, finish) => {
              starts.val += 1
              send(emit(1).0)
              finish()
              fn() { () }
            }),
          ),
        )
      },
      update=(model : Int, delta : Int, _) => (model + delta, none),
    )
  })
  let contract = definition.preview(deps => {
    shared_counter_page(deps, "preview").contract()
  })
  assert_true(contract.contains("shared:0"))
  assert_eq(starts.val, 0)
  let app = definition.create_runtime()
  assert_eq(starts.val, 0)
  ignore(app.lifecycle("onLaunch", "{}"))
  assert_eq(starts.val, 1)
  ignore(app.lifecycle("onLaunch", "{}"))
  assert_eq(starts.val, 1)
  let page = app.create_page(shared_counter_page(app.deps(), "started"))
  assert_true(page.snapshot().contains("shared:1"))
  ignore(app.dispose())
}

///|
test "independent applications reject obsolete delivery after disposal" {
  let first = shared_counter_app().create_runtime()
  let second = shared_counter_app().create_runtime()
  ignore(first.lifecycle("onLaunch", "{}"))
  ignore(second.lifecycle("onLaunch", "{}"))
  let old = first.deps().1
  ignore(first.dispatch(old(12)))
  let second_page = second.create_page(
    shared_counter_page(second.deps(), "second"),
  )
  assert_true(second_page.snapshot().contains("shared:0"))
  ignore(first.dispose())
  ignore(second.dispatch(old(100)))
  ignore(second_page.refresh())
  assert_true(second_page.snapshot().contains("shared:0"))
  ignore(second.dispose())
}

///|
test "shared projection equality suppresses renderer work and hidden pages catch up" {
  let app = shared_counter_app().create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let projected = page(
    id="projection",
    route=route("pages/projection/projection"),
    title="projection",
    build=context => {
      context
      .select(deps.0, value => value / 10)
      .view(value => p("tens:" + value.to_string()))
    },
  )
  let page = app.create_page(projected)
  ignore(page.mount())
  ignore(app.dispatch((deps.1)(1)))
  assert_eq(page.refresh(), "[]")
  ignore(page.lifecycle("onHide", "{}"))
  ignore(app.dispatch((deps.1)(20)))
  assert_eq(page.refresh(), "[]")
  assert_true(page.snapshot().contains("tens:0"))
  ignore(page.lifecycle("onShow", "{}"))
  assert_true(page.snapshot().contains("tens:2"))
  ignore(app.dispose())
}

///|
test "rejected page transactions do not publish application commands" {
  let app = shared_counter_app().create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let broken = elmish_page(
    id="broken",
    route=route("pages/broken/broken"),
    title="broken",
    model=false,
    update=(_, _msg : Unit, _) => (true, (deps.1)(100)),
    view=(broken, emit) => {
      if broken {
        div([
          button(on_tap=none, event_key="duplicate", "a"),
          button(on_tap=none, event_key="duplicate", "b"),
        ])
      } else {
        button(on_tap=emit(()), event_key="break", "break")
      }
    },
  )
  let page = app.create_page(broken)
  ignore(page.mount())
  assert_true(page.dispatch("break", "{}").contains("RuntimeError"))
  assert_eq(app.driver.owner.pending_count(), 0)
  ignore(app.flush())
  let observer = app.create_page(shared_counter_page(deps, "observer"))
  assert_true(observer.snapshot().contains("shared:0"))
  ignore(app.dispose())
}

///|
test "application timers pause in background and release on disposal" {
  let definition = app(build=context => {
    context.create_state(
      0,
      update=(count, delta : Int, _) => (count + delta, none),
      subscriptions=(_, emit) => {
        context.every(key="tick", interval_ms=1000, command=emit(1))
      },
    )
  })
  let app = definition.create_runtime()
  assert_eq(app.lifecycle("onLaunch", "{}"), "[]")
  assert_true(app.lifecycle("onShow", "{}").contains("StartSubscription"))
  assert_eq(app.lifecycle("onShow", "{}"), "[]")
  ignore(app.subscription("tick"))
  assert_true(app.lifecycle("onHide", "{}").contains("StopSubscription"))
  ignore(app.subscription("tick"))
  let page = app.create_page(shared_counter_page(app.deps(), "timer"))
  assert_true(page.snapshot().contains("shared:1"))
  assert_true(app.lifecycle("onShow", "{}").contains("StartSubscription"))
  assert_true(app.dispose().contains("StopSubscription"))
}
