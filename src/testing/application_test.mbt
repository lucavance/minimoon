///|
fn input_lifecycle_page() -> @minimoon.Page {
  @minimoon.page_with_input(
    id="typed_test",
    route=@minimoon.route("pages/typed_test/index"),
    title="Typed test",
    preview_input=() => "preview",
    decode_input=fields => {
      match fields.get("name") {
        Some(name) => Ok(name)
        None => Err(@minimoon.decode_error("name is required"))
      }
    },
    build=(context, name) => {
      let (events, _) = @minimoon.create_state_with_init(
        init=emit => (name + ":", emit("ready")),
        update=(events, event : String, _) => {
          @minimoon.no_cmd(events + event + ";")
        },
        subscriptions=(_, emit) => {
          @minimoon.Sub::batch([
            context.on_load(emit("load")),
            context.on_show(emit("show")),
          ])
        },
      )
      events.view(events => @minimoon.div(id="events", events))
    },
  )
}

///|
test "mount uses actual input and Load Show Ready ordering" {
  let runtime = mount(input_lifecycle_page(), input={ "name": "actual" })
  assert_eq(
    runtime.get(by_id("events")).text_content(),
    "actual:load;show;ready;",
  )
  runtime.quiesce()
  assert_eq(
    runtime.get(by_id("events")).text_content(),
    "actual:load;show;ready;",
  )
  let _ = runtime.dispose()
  assert_eq(runtime.dispose(), "[]")
}

///|
test "input decoding failures are catchable test failures not preview fallback" {
  let error = try {
    let _ = mount(input_lifecycle_page())
    "unexpected success"
  } catch {
    Failure(message) => message
    error => error.to_string()
  }
  assert_true(error.contains("typed_test"))
  assert_true(error.contains("name is required"))
  let app = launch(@minimoon.app(build=_ => ()))
  let error = try {
    let _ = app.mount(_ => input_lifecycle_page())
    "unexpected success"
  } catch {
    Failure(message) => message
    error => error.to_string()
  }
  assert_true(error.contains("App page typed_test"))
  let valid = app.mount(_ => input_lifecycle_page(), input={
    "name": "after-failure",
  })
  assert_eq(
    valid.get(by_id("events")).text_content(),
    "after-failure:load;show;ready;",
  )
  let _ = app.dispose()
}

///|
fn shared_test_app() -> @minimoon.App[
  (@minimoon.Shared[Int], @minimoon.Emit[Int]),
] {
  @minimoon.app(build=context => {
    context.create_state(
      0,
      update=(value, delta : Int, _) => @minimoon.no_cmd(value + delta),
      subscriptions=(_, emit) => {
        @minimoon.Sub::batch([
          context.on_launch(emit(10)),
          context.on_show(emit(20)),
        ])
      },
    )
  })
}

///|
fn shared_test_page(
  deps : (@minimoon.Shared[Int], @minimoon.Emit[Int]),
  id : String,
) -> @minimoon.Page {
  @minimoon.page(
    id~,
    route=@minimoon.route("pages/" + id + "/index"),
    title=id,
    build=context => {
      let value = context.bind(deps.0)
      let (visibility, _) = @minimoon.create_state(
        "new",
        update=(_, visibility : String, _) => @minimoon.no_cmd(visibility),
        subscriptions=(_, emit) => {
          @minimoon.Sub::batch([
            context.on_show(emit("shown")),
            context.on_hide(emit("hidden")),
          ])
        },
      )
      @minimoon.Val::view2(value, visibility, (value, visibility) => {
        @minimoon.div(id="shared-root", [
          @minimoon.div(id="count", value.to_string()),
          @minimoon.div(id="visibility", visibility),
          @minimoon.button(id="increment", on_tap=(deps.1)(1), "+"),
        ])
      })
    },
  )
}

///|
test "launch and page quiesce settle the App inbox and all visible shared pages" {
  let app = launch(shared_test_app())
  let first = app.mount(deps => shared_test_page(deps, "first"))
  let second = app.mount(deps => shared_test_page(deps, "second"))
  assert_eq(first.get(by_id("count")).text_content(), "30")
  assert_eq(second.get(by_id("count")).text_content(), "30")
  assert_eq(first.get(by_id("visibility")).text_content(), "shown")
  let scope = second.within(by_id("shared-root"))
  let _ = first.tap(by_id("increment"))
  first.quiesce()
  assert_eq(first.get(by_id("count")).text_content(), "31")
  assert_eq(scope.get(by_id("count")).text_content(), "31")
  let _ = first.lifecycle("onHide")
  let _ = second.tap(by_id("increment"))
  second.quiesce()
  assert_eq(second.get(by_id("count")).text_content(), "32")
  assert_eq(first.get(by_id("count")).text_content(), "31")
  let _ = first.lifecycle("onShow")
  app.quiesce()
  assert_eq(first.get(by_id("count")).text_content(), "32")
  let _ = app.dispose()
}

///|
test "disposing one page retains App state and disposing the App is idempotent" {
  let app = launch(shared_test_app())
  let first = app.mount(deps => shared_test_page(deps, "first"))
  let second = app.mount(deps => shared_test_page(deps, "second"))
  let _ = first.tap(by_id("increment"))
  let _ = first.dispose()
  second.quiesce()
  assert_eq(second.get(by_id("count")).text_content(), "31")
  let _ = second.tap(by_id("increment"))
  app.quiesce()
  assert_eq(second.get(by_id("count")).text_content(), "32")
  let _ = app.dispose()
  app.dispose()
  assert_eq(first.dispose(), "[]")
  assert_eq(second.tap(by_id("increment")), "[]")
  app.quiesce()
  let error = try {
    let _ = app.mount(deps => shared_test_page(deps, "late"))
    "unexpected success"
  } catch {
    Failure(message) => message
    error => error.to_string()
  }
  assert_true(error.contains("disposed TestApp"))
}

///|
test "quiesce leaves future ticks and unresolved host requests pending" {
  let runtime = mount(
    @minimoon.page(
      id="pending",
      route=@minimoon.route("pages/pending/index"),
      title="Pending",
      capabilities=[@minimoon.Request],
      build=context => {
        let (count, _) = @minimoon.create_state_with_init(
          init=emit => {
            (
              0,
              @minimoon.request("https://example.com/pending", _ => emit(100)),
            )
          },
          update=(count, delta : Int, _) => @minimoon.no_cmd(count + delta),
          subscriptions=(_, emit) => {
            context.every(key="tick", interval_ms=1, command=emit(1))
          },
        )
        count.view(count => @minimoon.div(id="pending-count", count.to_string()))
      },
    ),
  )
  runtime.quiesce(max_steps=1)
  assert_eq(runtime.get(by_id("pending-count")).text_content(), "0")
  let _ = runtime.tick("tick")
  runtime.quiesce()
  assert_eq(runtime.get(by_id("pending-count")).text_content(), "1")
  assert_true(runtime.dispose().contains("CancelEffect"))
}
