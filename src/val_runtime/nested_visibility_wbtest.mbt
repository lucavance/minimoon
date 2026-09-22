///|
fn commit_visibility_command(
  graph : Graph,
  root : Val[String],
  command : Cmd,
) -> String {
  graph.begin()
  ignore(run_message(graph, command))
  let value = graph.run(() => root.read())
  graph.commit()
  value
}

///|
fn dispatch_visibility_commands(graph : Graph, command : Cmd) -> Unit {
  match command {
    CmdMessage(run) => dispatch_visibility_commands(graph, graph.run(run))
    CmdBatch(commands) =>
      for command in commands {
        dispatch_visibility_commands(graph, command)
      }
    _ => ()
  }
}

///|
test "nested subscriptions and emitters preserve active selection across restore and rollback" {
  // Enumeration, bounded enumeration, and switch share scope visibility but
  // have different cache retention and candidate rollback paths.
  for mode in [0, 1, 2] {
    let graph = Graph::new()
    let emitters : Map[String, Emit[Int]] = Map([])
    let hits : Map[String, Int] = Map([])
    let cleaned = Ref(0)
    let (root, set_outer, set_inner) = graph.build(fn() {
      let (outer, set_outer) = graph.create_input("A")
      let (inner, set_inner) = graph.create_input("a")
      let build = fn(tag : String, _input : Val[String]) -> Val[String] {
        if tag != "A" {
          return Val::constant(tag)
        }
        inner.enumerate_by(
          (tag, _) => {
            @duplix.on_cleanup(fn() { cleaned.val += 1 })
            let (state, emit) = create_state(
              0,
              update=(current, amount : Int, _) => {
                hits[tag] = hits.get(tag).unwrap_or(0) + 1
                (current + amount, none)
              },
              subscriptions=(_, _) => every("inner-tick", 1000, none),
            )
            emitters[tag] = emit
            state.map(count => tag + ":" + count.to_string())
          },
          by=value => value,
        )
      }
      let root = match mode {
        0 => outer.enumerate_by(build, by=value => value)
        1 => outer.enumerate_bounded_by(capacity=2, build~, by=value => value)
        _ => outer.switch_by(build, by=value => value)
      }
      (root, set_outer, set_inner)
    })
    assert_eq(graph.run(() => root.read()), "a:0")
    assert_eq(
      commit_visibility_command(graph, root, set_inner.emit("b")),
      "b:0",
    )
    let stale_a = emitters["a"].emit(10)
    assert_eq(
      commit_visibility_command(graph, root, emitters["b"].emit(2)),
      "b:2",
    )
    assert_eq(collect_subscription_keys(graph.current_subscriptions()), [
      "inner-tick",
    ])
    graph.begin()
    ignore(run_message(graph, set_outer.emit("B")))
    assert_eq(graph.run(() => root.read()), "B")
    assert_eq(collect_subscription_keys(graph.current_subscriptions()), [])
    graph.rollback()
    assert_eq(graph.run(() => root.read()), "b:2")
    assert_eq(collect_subscription_keys(graph.current_subscriptions()), [
      "inner-tick",
    ])
    assert_eq(commit_visibility_command(graph, root, stale_a), "b:2")
    assert_eq(hits.get("a"), None)
    assert_eq(
      commit_visibility_command(graph, root, emitters["b"].emit(1)),
      "b:3",
    )
    if mode != 2 {
      assert_eq(
        commit_visibility_command(graph, root, set_outer.emit("B")),
        "B",
      )
      assert_eq(
        commit_visibility_command(graph, root, set_outer.emit("A")),
        "b:3",
      )
      assert_eq(collect_subscription_keys(graph.current_subscriptions()), [
        "inner-tick",
      ])
      assert_eq(
        commit_visibility_command(graph, root, emitters["a"].emit(10)),
        "b:3",
      )
      assert_eq(hits.get("a"), None)
      assert_eq(cleaned.val, 0)
    }
    if mode == 1 {
      ignore(commit_visibility_command(graph, root, set_outer.emit("B")))
      graph.begin()
      ignore(run_message(graph, set_outer.emit("C")))
      assert_eq(graph.run(() => root.read()), "C")
      graph.rollback()
      assert_eq(graph.run(() => root.read()), "B")
      assert_eq(cleaned.val, 0)
      assert_eq(
        commit_visibility_command(graph, root, set_outer.emit("A")),
        "b:3",
      )
      assert_eq(collect_subscription_keys(graph.current_subscriptions()), [
        "inner-tick",
      ])
      ignore(commit_visibility_command(graph, root, set_outer.emit("B")))
      ignore(commit_visibility_command(graph, root, set_outer.emit("C")))
      assert_eq(cleaned.val, 2)
      assert_eq(graph.subscription_provider_count_for_test(), 0)
      assert_eq(graph.state_store_count_for_test(), 2)
      assert_eq(
        commit_visibility_command(graph, root, set_outer.emit("A")),
        "b:0",
      )
      assert_eq(collect_subscription_keys(graph.current_subscriptions()), [
        "inner-tick",
      ])
    }
    graph.dispose()
    graph.dispose()
    assert_eq(cleaned.val, if mode == 1 { 3 } else { 2 })
    assert_eq(graph.subscription_provider_count_for_test(), 0)
    assert_eq(graph.state_store_count_for_test(), 0)
  }
}

///|
test "nested shared bindings refresh only the effectively visible branch" {
  let owner = Application::new()
  let (value, set_shared) = owner.build(() => owner.graph.create_input(0))
  let shared : Shared[Int] = { address: owner.address, value, }
  let graph = owner.with_pages(Graph::new)
  let samples : Map[String, Int] = Map([])
  let wakes = Ref(0)
  graph.attach_shared_runtime(fn() { wakes.val += 1 }, fn() { () })
  let (root, set_outer, set_inner) = graph.build(fn() {
    let (outer, set_outer) = graph.create_input("A")
    let (inner, set_inner) = graph.create_input("a")
    let root = outer.enumerate_by(
      (tag, _) => {
        if tag != "A" {
          return Val::constant(tag)
        }
        inner.enumerate_by(
          (tag, _) => {
            graph
            .select_shared(shared, value => {
              samples[tag] = samples.get(tag).unwrap_or(0) + 1
              value
            })
            .map(value => tag + ":" + value.to_string())
          },
          by=value => value,
        )
      },
      by=value => value,
    )
    (root, set_outer, set_inner)
  })
  assert_eq(graph.run(() => root.read()), "a:0")
  ignore(commit_visibility_command(graph, root, set_inner.emit("b")))
  ignore(commit_visibility_command(graph, root, set_outer.emit("B")))
  assert_eq(commit_visibility_command(graph, root, set_outer.emit("A")), "b:0")
  graph.begin()
  dispatch_visibility_commands(graph, graph.take_initial_command())
  graph.commit()
  samples.clear()
  owner.graph.begin()
  ignore(run_message(owner.graph, set_shared.emit(1)))
  owner.graph.commit()
  owner.publish()
  assert_eq(wakes.val, 1)
  assert_eq(samples.get("a"), None)
  assert_eq(samples.get("b"), Some(1))
  graph.begin()
  dispatch_visibility_commands(graph, graph.refresh_shared())
  assert_eq(graph.run(() => root.read()), "b:1")
  graph.commit()
  assert_false(graph.has_shared_changes())
  assert_eq(samples.get("a"), None)
  ignore(commit_visibility_command(graph, root, set_outer.emit("B")))
  samples.clear()
  owner.graph.begin()
  ignore(run_message(owner.graph, set_shared.emit(2)))
  owner.graph.commit()
  owner.publish()
  assert_eq(wakes.val, 1)
  assert_true(samples.is_empty())
  ignore(commit_visibility_command(graph, root, set_outer.emit("A")))
  graph.begin()
  dispatch_visibility_commands(graph, graph.take_initial_command())
  assert_eq(graph.run(() => root.read()), "b:2")
  graph.commit()
  assert_eq(samples.get("a"), None)
  graph.begin()
  ignore(run_message(graph, set_outer.emit("B")))
  assert_eq(graph.run(() => root.read()), "B")
  graph.rollback()
  graph.begin()
  dispatch_visibility_commands(graph, graph.take_initial_command())
  assert_eq(graph.run(() => root.read()), "b:2")
  graph.commit()
  assert_eq(samples.get("a"), None)
  assert_eq(graph.shared_binding_order.length(), 2)
  graph.dispose()
  assert_eq(graph.shared_binding_order.length(), 0)
  assert_eq(graph.state_store_count_for_test(), 0)
  assert_eq(owner.page_count(), 0)
  owner.dispose()
}
