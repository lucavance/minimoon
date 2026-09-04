///|
priv struct SwitchInput {
  tag : String
  value : Int
} derive(Eq)

///|
priv enum SwitchParentMessage {
  UpdateSameTag
  ShowInvalid
  ShowB
  ShowA
}

///|
priv enum SwitchLocalMessage {
  IncrementSwitchLocal
}

///|
test "switch keeps same-tag state reactive and rolls rejected branches back" {
  let definition = page(
    id="val_switch_transaction",
    route=route("pages/val_switch_transaction/val_switch_transaction"),
    title="Val Switch Transaction",
    build=_ => {
      let initial : SwitchInput = { tag: "a", value: 1, }
      let (source, emit_source) = create_pure_state(initial, update=(
        _current : SwitchInput,
        message,
      ) => {
        match message {
          UpdateSameTag => { tag: "a", value: 2, }
          ShowInvalid => { tag: "invalid", value: 3, }
          ShowB => { tag: "b", value: 4, }
          ShowA => { tag: "a", value: 5, }
        }
      })
      let branch = source.switch_by(
        (initial, input) => {
          let (count, emit_count) = create_pure_state(0, update=(
            value,
            _message,
          ) => value + 1)
          Val::map2(input, count, (current, count_value) => {
            button(
              on_tap=emit_count(IncrementSwitchLocal),
              event_key="switch-local",
              initial.tag +
              ":" +
              current.value.to_string() +
              ":" +
              count_value.to_string(),
            )
          })
        },
        by=value => value.tag,
      )
      Val::map2(source, branch, (current, branch) => {
        let children = [
          button(
            on_tap=emit_source(UpdateSameTag),
            event_key="switch-same",
            "same tag",
          ),
          button(
            on_tap=emit_source(ShowInvalid),
            event_key="switch-invalid",
            "invalid",
          ),
          button(on_tap=emit_source(ShowB), event_key="switch-b", "show b"),
          button(on_tap=emit_source(ShowA), event_key="switch-a", "show a"),
          branch,
        ]
        if current.tag == "invalid" {
          children.push(
            button(on_tap=none, event_key="duplicate", "duplicate one"),
          )
          children.push(
            button(on_tap=none, event_key="duplicate", "duplicate two"),
          )
        }
        div(children)
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  assert_eq(runtime.snapshot().contains("a:1:0"), true)
  let _ = runtime.dispatch("switch-local", "{}")
  assert_eq(runtime.snapshot().contains("a:1:1"), true)
  let _ = runtime.dispatch("switch-same", "{}")
  assert_eq(runtime.snapshot().contains("a:2:1"), true)

  let rejected = runtime.dispatch("switch-invalid", "{}")
  assert_eq(rejected.contains("invalid_view"), true)
  assert_eq(runtime.snapshot().contains("a:2:1"), true)
  let _ = runtime.dispatch("switch-local", "{}")
  assert_eq(runtime.snapshot().contains("a:2:2"), true)

  let _ = runtime.dispatch("switch-b", "{}")
  assert_eq(runtime.snapshot().contains("b:4:0"), true)
  let _ = runtime.dispatch("switch-a", "{}")
  assert_eq(runtime.snapshot().contains("a:5:0"), true)
}

///|
priv enum BranchInitSourceMessage {
  BranchInitShowInvalid
  BranchInitShowB
}

///|
priv enum BranchInitSiblingMessage {
  BranchMounted
  IncrementSibling
}

///|
test "dynamic branch init runs after commit and preserves graph invalidation" {
  let definition = page(
    id="val_branch_init_transaction",
    route=route("pages/val_branch_init_transaction/val_branch_init_transaction"),
    title="Val Branch Init Transaction",
    build=_ => {
      let (sibling, emit_sibling) = create_pure_state(0, update=(
        current,
        message,
      ) => {
        match message {
          BranchMounted | IncrementSibling => current + 1
        }
      })
      let (source, emit_source) = create_pure_state("a", update=(
        _current,
        message,
      ) => {
        match message {
          BranchInitShowInvalid => "invalid"
          BranchInitShowB => "b"
        }
      })
      let branch = source.switch_by(
        (initial, input) => {
          let (branch_state, _emit_branch) = create_state_with_init(
            init=(_emit : Emit[Unit]) => {
              with_cmd(initial, emit_sibling(BranchMounted))
            },
            update=(current, _message : Unit, _) => no_cmd(current),
          )
          Val::map2(input, branch_state, (current, mounted_tag) => {
            p("branch:" + current + ":" + mounted_tag)
          })
        },
        by=value => value,
      )
      Val::map3(source, sibling, branch, (current, sibling_count, branch) => {
        let children = [
          button(
            on_tap=emit_source(BranchInitShowB),
            event_key="branch-init/show-b",
            "show b",
          ),
          button(
            on_tap=emit_source(BranchInitShowInvalid),
            event_key="branch-init/show-invalid",
            "show invalid",
          ),
          button(
            on_tap=emit_sibling(IncrementSibling),
            event_key="branch-init/increment-sibling",
            "increment sibling",
          ),
          p("state:" + current + ":" + sibling_count.to_string()),
          branch,
        ]
        if current == "invalid" {
          children.push(
            button(
              on_tap=none,
              event_key="branch-init/duplicate",
              "duplicate one",
            ),
          )
          children.push(
            button(
              on_tap=none,
              event_key="branch-init/duplicate",
              "duplicate two",
            ),
          )
        }
        div(children)
      })
    },
  )
  let runtime = definition.create_runtime()
  assert_true(runtime.snapshot().contains("\"revision\":0"))
  assert_true(runtime.snapshot().contains("state:a:0"))

  let mounted = runtime.mount()
  assert_eq(mounted.split("\"base_revision\":").length(), 2)
  assert_true(runtime.snapshot().contains("\"revision\":1"))
  assert_true(runtime.snapshot().contains("state:a:1"))

  let show_b = runtime.dispatch("branch-init/show-b", "{}")
  assert_eq(show_b.split("\"base_revision\":").length(), 2)
  assert_true(show_b.contains("\"base_revision\":1"))
  assert_true(show_b.contains("\"revision\":2"))
  assert_true(runtime.snapshot().contains("state:b:2"))

  let incremented = runtime.dispatch("branch-init/increment-sibling", "{}")
  assert_true(incremented.contains("\"revision\":3"))
  assert_true(runtime.snapshot().contains("state:b:3"))

  let committed = runtime.snapshot()
  let rejected = runtime.dispatch("branch-init/show-invalid", "{}")
  assert_true(rejected.contains("invalid_view"))
  assert_eq(rejected.split("\"base_revision\":").length(), 1)
  assert_eq(runtime.snapshot(), committed)

  let after_rollback = runtime.dispatch("branch-init/increment-sibling", "{}")
  assert_eq(after_rollback.split("\"base_revision\":").length(), 2)
  assert_true(after_rollback.contains("\"revision\":4"))
  assert_true(runtime.snapshot().contains("state:b:4"))
}

///|
priv struct EnumerateInput {
  tag : String
  value : Int
} derive(Eq)

///|
priv enum EnumerateParentMessage {
  ShowEnumerateA
  ShowEnumerateB
}

///|
priv enum EnumerateLocalMessage {
  EnumeratePulse
}

///|
test "enumerate preserves tagged state and pauses inactive subscriptions" {
  let builds = Ref(0)
  let definition = page(
    id="val_enumerate_cache",
    route=route("pages/val_enumerate_cache/val_enumerate_cache"),
    title="Val Enumerate Cache",
    build=context => {
      let initial : EnumerateInput = { tag: "a", value: 1, }
      let (source, emit_source) = create_pure_state(initial, update=(
        _current : EnumerateInput,
        message,
      ) => {
        match message {
          ShowEnumerateA => { tag: "a", value: 3, }
          ShowEnumerateB => { tag: "b", value: 2, }
        }
      })
      let branch = source.enumerate_by(
        (initial, input) => {
          builds.val += 1
          let (count, emit_count) = create_state(
            0,
            update=(value, _message, _) => no_cmd(value + 1),
            subscriptions=(_, emit) => {
              context.every(
                key="enumerate/" + initial.tag,
                interval_ms=1000,
                command=emit(EnumeratePulse),
              )
            },
          )
          Val::map2(input, count, (current, count_value) => {
            button(
              on_tap=emit_count(EnumeratePulse),
              event_key="enumerate-local",
              initial.tag +
              ":" +
              current.value.to_string() +
              ":" +
              count_value.to_string(),
            )
          })
        },
        by=value => value.tag,
      )
      Val::map2(source, branch, (_current, branch) => {
        div([
          button(
            on_tap=emit_source(ShowEnumerateA),
            event_key="enumerate-a",
            "show a",
          ),
          button(
            on_tap=emit_source(ShowEnumerateB),
            event_key="enumerate-b",
            "show b",
          ),
          branch,
        ])
      })
    },
  )
  let runtime = definition.create_runtime()
  let mounted = runtime.mount()
  assert_eq(mounted.contains("enumerate/a"), true)
  let _ = runtime.subscription("enumerate/a", "{}")
  assert_eq(runtime.snapshot().contains("a:1:1"), true)

  let show_b = runtime.dispatch("enumerate-b", "{}")
  assert_eq(show_b.contains("StopSubscription"), true)
  assert_eq(show_b.contains("enumerate/a"), true)
  assert_eq(show_b.contains("StartSubscription"), true)
  assert_eq(show_b.contains("enumerate/b"), true)
  let _ = runtime.subscription("enumerate/b", "{}")
  assert_eq(runtime.snapshot().contains("b:2:1"), true)

  let show_a = runtime.dispatch("enumerate-a", "{}")
  assert_eq(show_a.contains("enumerate/b"), true)
  assert_eq(show_a.contains("enumerate/a"), true)
  assert_eq(runtime.snapshot().contains("a:3:1"), true)
  assert_eq(builds.val, 2)
}

///|
priv enum PageInputMessage {
  PageInputTick
}

///|
test "state with input initializes once and reads the latest page input" {
  let definition = page_with_input(
    id="val_page_input",
    route=route("pages/val_page_input/val_page_input"),
    title="Val Page Input",
    decode_input=fields => {
      Ok(
        match fields.get("step") {
          Some("3") => 3
          Some(_) => 2
          None => 1
        },
      )
    },
    build=(context, input) => {
      let (count, _emit_count) = create_state_with_input(
        input~,
        init=(_emit, initial_input) => no_cmd(initial_input),
        update=(current, current_input, _message, _) => {
          no_cmd(current + current_input)
        },
        subscriptions=(_, current_input, emit) => {
          context.every(
            key="page-input-clock",
            interval_ms=current_input * 1000,
            command=emit(PageInputTick),
          )
        },
      )
      count.view(value => p("input count:" + value.to_string()))
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.lifecycle("onLoad", "{\"step\":\"3\"}")
  let mounted = runtime.mount()
  assert_eq(mounted.contains("\"interval_ms\":3000"), true)
  assert_eq(runtime.snapshot().contains("input count:1"), true)
  let _ = runtime.subscription("page-input-clock", "{}")
  assert_eq(runtime.snapshot().contains("input count:4"), true)
}

///|
fn resource_label(status : Status[String]) -> String {
  match status {
    Pending => "pending"
    Loaded(value) => "loaded:" + value
    Failed(error) => "failed:" + error.to_string()
  }
}

///|
test "resource runs one initial command and records success or failure" {
  let success_loads = Ref(0)
  let success = page(
    id="val_resource_success",
    route=route("pages/val_resource_success/val_resource_success"),
    title="Val Resource Success",
    build=_ => {
      let status = create_resource(emit => {
        success_loads.val += 1
        emit(Ok("ready"))
      })
      status.view(status => p(resource_label(status)))
    },
  )
  let success_runtime = success.create_runtime()
  assert_eq(success_runtime.snapshot().contains("pending"), true)
  let _ = success_runtime.mount()
  assert_eq(success_runtime.snapshot().contains("loaded:ready"), true)
  assert_eq(success_loads.val, 1)

  let failure = page(
    id="val_resource_failure",
    route=route("pages/val_resource_failure/val_resource_failure"),
    title="Val Resource Failure",
    build=_ => {
      let status = create_resource(emit => {
        let error : Error = Failure::Failure("offline")
        emit(Err(error))
      })
      status.view(status => p(resource_label(status)))
    },
  )
  let failure_runtime = failure.create_runtime()
  assert_eq(failure_runtime.snapshot().contains("pending"), true)
  let _ = failure_runtime.mount()
  assert_eq(failure_runtime.snapshot().contains("failed:"), true)
  assert_eq(failure_runtime.snapshot().contains("offline"), true)
}

///|
priv enum ResourceScopeMessage {
  DisposeResourceScope
}

///|
test "resource completion from a disposed branch is ignored" {
  let saved_emit : Ref[Emit[Result[String, Error]]?] = Ref(None)
  let definition = page(
    id="val_resource_scope",
    route=route("pages/val_resource_scope/val_resource_scope"),
    title="Val Resource Scope",
    build=_ => {
      let (visible, emit_visible) = create_pure_state(true, update=(
        _current,
        _message : ResourceScopeMessage,
      ) => false)
      let branch = visible.switch_by(
        (initial, _input) => {
          if initial {
            let status = create_resource(resource_emit => {
              saved_emit.val = Some(resource_emit)
              none
            })
            status.view(status => p(resource_label(status)))
          } else {
            Val::constant(p("resource scope disposed"))
          }
        },
        by=value => value.to_string(),
      )
      Val::map2(visible, branch, (_visible, branch) => {
        let complete = match saved_emit.val {
          Some(resource_emit) => resource_emit(Ok("late"))
          None => none
        }
        div([
          button(
            on_tap=emit_visible(DisposeResourceScope),
            event_key="resource-dispose",
            "dispose resource",
          ),
          button(
            on_tap=complete,
            event_key="resource-complete",
            "complete resource",
          ),
          branch,
        ])
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  assert_eq(runtime.snapshot().contains("pending"), true)
  let _ = runtime.dispatch("resource-dispose", "{}")
  assert_eq(runtime.snapshot().contains("resource scope disposed"), true)
  assert_eq(runtime.dispatch("resource-complete", "{}"), "[]")
  assert_eq(runtime.snapshot().contains("loaded:late"), false)
  assert_eq(runtime.snapshot().contains("resource scope disposed"), true)
}
