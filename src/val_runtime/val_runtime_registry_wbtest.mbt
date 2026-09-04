///|
fn Graph::state_store_count_for_test(self : Graph) -> Int {
  self.state_registry.live.val
}

///|
fn Graph::subscription_provider_count_for_test(self : Graph) -> Int {
  self.subscriptions.order.val.length()
}

///|
fn collect_subscription_keys(subscription : Sub) -> Array[String] {
  let keys : Array[String] = []
  fn collect(subscription : Sub) {
    match subscription {
      SubNone | SubLifecycle(_, _) => ()
      SubEvery(key, _, _) => keys.push(key)
      SubBatch(entries) =>
        for entry in entries {
          collect(entry)
        }
    }
  }

  collect(subscription)
  keys
}

///|
test "subscription registry preserves order and rejects stale slot callbacks" {
  let registry = SubscriptionRegistry::new()
  let first = registry.register(fn() { every("a", 1000, none) })
  let stale = registry.register(fn() { every("b", 1000, none) })
  let third = registry.register(fn() { every("c", 1000, none) })
  registry.remove(stale)
  let replacement = registry.register(fn() { every("d", 1000, none) })
  registry.set_visible(stale, false)
  registry.remove(stale)
  assert_eq(collect_subscription_keys(registry.current()), ["a", "c", "d"])
  registry.remove(first)
  registry.remove(third)
  registry.remove(replacement)
  assert_eq(collect_subscription_keys(registry.current()), [])
}

///|
test "state init commands dispatch through the installed generational store" {
  let graph = Graph::new()
  let state = graph.build(fn() {
    create_state_with_init(init=emit => (0, emit.emit(2)), update=(
      current,
      step,
      _,
    ) => (current + step, none)).0
  })
  assert_eq(graph.state_store_count_for_test(), 1)
  graph.begin()
  match graph.take_initial_command() {
    CmdBatch(commands) =>
      for command in commands {
        let _ = run_message(graph, command)
      }
    _ => fail("state init command must be batched")
  }
  graph.commit()
  assert_eq(graph.run(fn() { state.read() }), 2)
  graph.dispose()
  assert_eq(graph.state_store_count_for_test(), 0)
}

///|
test "committed and rejected switch branches reclaim stores and subscriptions" {
  let graph = Graph::new()
  let (branch, set_source) = graph.build(fn() {
    let (source, set_source) = graph.create_input(0)
    let branch = source.switch_by(
      (initial, _input) => {
        let (state, _) : (Val[Int], Emit[Unit]) = create_state(
          0,
          update=(current, _, _) => (current, none),
          subscriptions=(_, _) => {
            every("branch/" + initial.to_string(), 1000, none)
          },
        )
        state
      },
      by=value => value.to_string(),
    )
    (branch, set_source)
  })
  assert_eq(graph.run(fn() { branch.read() }), 0)
  assert_eq(graph.state_store_count_for_test(), 2)
  assert_eq(graph.subscription_provider_count_for_test(), 1)

  for tag = 1; tag < 10000; tag = tag + 1 {
    graph.begin()
    let _ = run_message(graph, set_source.emit(tag))
    assert_eq(graph.run(fn() { branch.read() }), 0)
    graph.commit()
    assert_eq(graph.state_store_count_for_test(), 2)
    assert_eq(graph.subscription_provider_count_for_test(), 1)
  }

  for tag = 10000; tag < 11000; tag = tag + 1 {
    graph.begin()
    let _ = run_message(graph, set_source.emit(tag))
    assert_eq(graph.run(fn() { branch.read() }), 0)
    assert_eq(graph.state_store_count_for_test(), 3)
    assert_eq(graph.subscription_provider_count_for_test(), 2)
    graph.rollback()
    assert_eq(graph.state_store_count_for_test(), 2)
    assert_eq(graph.subscription_provider_count_for_test(), 1)
  }

  graph.dispose()
  assert_eq(graph.state_store_count_for_test(), 0)
  assert_eq(graph.subscription_provider_count_for_test(), 0)
}

///|
test "state commands are isolated by graph generation" {
  let left = Graph::new()
  let (left_state, left_emit) = left.build(fn() {
    create_pure_state(0, update=(current, step) => current + step)
  })
  let right = Graph::new()
  let (right_state, _right_emit) = right.build(fn() {
    create_pure_state(0, update=(current, step) => current + step)
  })

  let stale_command = left_emit.emit(7)
  right.begin()
  let result = run_message(right, stale_command)
  right.commit()
  assert_true(result is CmdNone)
  assert_eq(left.run(fn() { left_state.read() }), 0)
  assert_eq(right.run(fn() { right_state.read() }), 0)

  left.dispose()
  let replacement = Graph::new()
  let replacement_state = replacement.build(fn() {
    create_pure_state(0, update=(current, step) => current + step).0
  })
  replacement.begin()
  let reused_result = run_message(replacement, stale_command)
  replacement.commit()
  assert_true(reused_result is CmdNone)
  assert_eq(replacement.run(fn() { replacement_state.read() }), 0)

  right.dispose()
  replacement.dispose()
}

///|
test "state command thunks reject missing and disposed ambient graphs" {
  let graph = Graph::new()
  let emit = graph.build(fn() {
    create_pure_state(0, update=(current, step) => current + step).1
  })
  let command = emit.emit(3)
  let thunk = match command {
    CmdMessage(run) => run
    _ => fail("state emit must create a deferred message command")
  }
  graph.dispose()
  assert_true(thunk() is CmdNone)
  assert_true(ambient_graph.protect(Some(graph), fn() { thunk() }) is CmdNone)
}

///|
test "stale state generations cannot update a replacement branch" {
  let graph = Graph::new()
  let emitters : Ref[Array[Emit[Int]]] = Ref([])
  let (branch, set_source) = graph.build(fn() {
    let (source, set_source) = graph.create_input("a")
    let branch = source.switch_by(
      (_initial, _input) => {
        let (state, emit) = create_pure_state(0, update=(current, step) => {
          current + step
        })
        emitters.val.push(emit)
        state
      },
      by=value => value,
    )
    (branch, set_source)
  })
  assert_eq(graph.run(fn() { branch.read() }), 0)
  let stale_command = emitters.val[0].emit(9)

  graph.begin()
  let _ = run_message(graph, set_source.emit("b"))
  assert_eq(graph.run(fn() { branch.read() }), 0)
  graph.commit()
  assert_eq(graph.state_store_count_for_test(), 2)

  graph.begin()
  let result = run_message(graph, stale_command)
  graph.commit()
  assert_true(result is CmdNone)
  assert_eq(graph.run(fn() { branch.read() }), 0)
  graph.dispose()
}

///|
test "bounded enumeration evicts graph stores and subscriptions on commit" {
  let graph = Graph::new()
  let (branch, set_source) = graph.build(fn() {
    let (source, set_source) = graph.create_input(0)
    let branch = source.enumerate_bounded_by(
      capacity=2,
      build=(initial, _input) => {
        let (state, _) : (Val[Int], Emit[Unit]) = create_state(
          initial,
          update=(current, _, _) => (current, none),
          subscriptions=(_, _) => {
            every("bounded/" + initial.to_string(), 1000, none)
          },
        )
        state
      },
      by=value => value.to_string(),
    )
    (branch, set_source)
  })
  assert_eq(graph.run(fn() { branch.read() }), 0)
  assert_eq(graph.state_store_count_for_test(), 2)
  assert_eq(graph.subscription_provider_count_for_test(), 1)

  for tag = 1; tag < 100; tag = tag + 1 {
    graph.begin()
    let _ = run_message(graph, set_source.emit(tag))
    assert_eq(graph.run(fn() { branch.read() }), tag)
    graph.commit()
    assert_eq(graph.state_store_count_for_test(), 3)
    assert_eq(graph.subscription_provider_count_for_test(), 2)
  }

  graph.dispose()
  assert_eq(graph.state_store_count_for_test(), 0)
  assert_eq(graph.subscription_provider_count_for_test(), 0)
}
