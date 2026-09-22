///|
fn nested_visibility_command_count(raw : String, kind : String) -> Int raise {
  match @json.parse(raw) {
    Array(commands) =>
      commands
      .filter(command => {
        match command {
          { "type": String(actual), .. } => actual == kind
          _ => false
        }
      })
      .length()
    _ => fail("runtime response must be a command array")
  }
}

///|
test "nested cached page branches reuse one timer and restore it after rejected renders" {
  let definition = @minimoon.page(
    id="nested_visibility",
    route=@minimoon.route("pages/nested_visibility/index"),
    title="Nested visibility",
    build=context => {
      let (outer, set_outer) = @minimoon.create_variable("A")
      let (inner, set_inner) = @minimoon.create_variable("a")
      let branch = outer.enumerate_by(
        (tag, _) => {
          if tag != "A" {
            return @minimoon.Val::constant(@minimoon.text(tag))
          }
          inner.enumerate_by(
            (tag, _) => {
              let (count, _) = @minimoon.create_state(
                0,
                update=(current, _ : Unit, _) => @minimoon.no_cmd(current + 1),
                subscriptions=(_, emit) => {
                  context.every(
                    key="nested-clock",
                    interval_ms=1000,
                    command=emit(()),
                  )
                },
              )
              count.view(value => @minimoon.text(tag + ":" + value.to_string()))
            },
            by=value => value,
          )
        },
        by=value => value,
      )
      @minimoon.Val::view2(outer, branch, (outer, branch) => {
        let children = [
          @minimoon.button(
            event_key="inner-b",
            on_tap=set_inner(_ => "b"),
            "Inner B",
          ),
          @minimoon.button(event_key="away", on_tap=set_outer(_ => "B"), "Away"),
          @minimoon.button(event_key="back", on_tap=set_outer(_ => "A"), "Back"),
          @minimoon.button(
            event_key="reject",
            on_tap=set_outer(_ => "invalid"),
            "Reject",
          ),
          branch,
        ]
        if outer == "invalid" {
          children.push(
            @minimoon.button(
              event_key="duplicate",
              on_tap=@minimoon.none,
              "One",
            ),
          )
          children.push(
            @minimoon.button(
              event_key="duplicate",
              on_tap=@minimoon.none,
              "Two",
            ),
          )
        }
        @minimoon.div(children)
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  assert_eq(
    nested_visibility_command_count(runtime.mount(), "StartSubscription"),
    1,
  )
  ignore(runtime.subscription("nested-clock", "{}"))
  assert_true(runtime.snapshot().contains("a:1"))
  let inner = runtime.dispatch("inner-b", "{}")
  assert_false(inner.contains("RuntimeError"))
  assert_eq(nested_visibility_command_count(inner, "StartSubscription"), 0)
  assert_eq(nested_visibility_command_count(inner, "StopSubscription"), 0)
  ignore(runtime.subscription("nested-clock", "{}"))
  assert_true(runtime.snapshot().contains("b:1"))
  assert_eq(
    nested_visibility_command_count(
      runtime.dispatch("away", "{}"),
      "StopSubscription",
    ),
    1,
  )
  let restored = runtime.dispatch("back", "{}")
  assert_false(restored.contains("RuntimeError"))
  assert_eq(nested_visibility_command_count(restored, "StartSubscription"), 1)
  ignore(runtime.subscription("nested-clock", "{}"))
  assert_true(runtime.snapshot().contains("b:2"))
  let rejected = runtime.dispatch("reject", "{}")
  assert_true(rejected.contains("invalid_view"))
  assert_eq(nested_visibility_command_count(rejected, "StartSubscription"), 0)
  assert_eq(nested_visibility_command_count(rejected, "StopSubscription"), 0)
  ignore(runtime.subscription("nested-clock", "{}"))
  assert_true(runtime.snapshot().contains("b:3"))
  assert_eq(
    nested_visibility_command_count(runtime.dispose(), "StopSubscription"),
    1,
  )
}
