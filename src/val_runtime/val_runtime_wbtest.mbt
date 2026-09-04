///|
fn run_message(graph : Graph, command : Cmd) -> Cmd {
  let mut current = command
  while true {
    match current {
      CmdMessage(run) => current = graph.run(run)
      other => return other
    }
  }
  none
}

///|
test "decode errors and mapped emitters preserve values" {
  let error = decode_error("invalid payload")
  assert_eq(error.message(), "invalid payload")
  let received : Ref[Int?] = Ref(None)
  let numbers = Emit(value => {
    received.val = Some(value)
    none
  })
  let strings = numbers.map((value : String) => value.length())
  let _ = strings.emit("moon")
  assert_eq(received.val, Some(4))
}

///|
test "graph state helpers commit atomically and dispose idempotently" {
  let graph = Graph::new()
  let (count, increment) = graph.build(fn() {
    create_pure_state(1, update=(current, step) => current + step)
  })
  let (name, rename) = graph.build(fn() { create_variable("moon") })
  assert_eq(graph.run(fn() { count.read() }), 1)
  assert_eq(graph.run(fn() { name.read() }), "moon")

  graph.begin()
  let _ = run_message(graph, increment.emit(2))
  let _ = run_message(graph, rename.emit(_ => "mini"))
  assert_eq(graph.candidate_revision(), 1)
  assert_eq(graph.run(fn() { count.read() }), 3)
  assert_eq(graph.run(fn() { name.read() }), "mini")
  graph.commit()
  assert_eq(graph.run(fn() { count.read() }), 3)

  graph.begin()
  let _ = run_message(graph, increment.emit(4))
  graph.rollback()
  assert_eq(graph.run(fn() { count.read() }), 3)
  graph.dispose()
  graph.dispose()
}

///|
test "dynamic branch initial commands follow candidate transactions" {
  let graph = Graph::new()
  let (root, set_source) = graph.build(fn() {
    let (sibling, increment_sibling) = create_pure_state(0, update=(
      current,
      step,
    ) => current + step)
    let (source, set_source) = graph.create_input("a")
    let branch = source.switch_by(
      (initial, _input) => {
        let (branch_state, _send) : (Val[String], Emit[Unit]) = create_state_with_init(
          init=_ => (initial, increment_sibling.emit(1)),
          update=(current, _message, _) => (current, none),
        )
        branch_state
      },
      by=value => value,
    )
    (
      Val::map2(branch, sibling, (tag, count) => tag + ":" + count.to_string()),
      set_source,
    )
  })

  assert_eq(graph.run(fn() { root.read() }), "a:0")
  match graph.take_initial_command() {
    CmdBatch(commands) => assert_eq(commands.length(), 1)
    _ => fail("initial branch must enqueue one command")
  }

  graph.begin()
  let _ = run_message(graph, set_source.emit("b"))
  assert_eq(graph.run(fn() { root.read() }), "b:0")
  graph.rollback()
  match graph.take_initial_command() {
    CmdBatch(commands) => assert_eq(commands.length(), 0)
    _ => fail("rolled back branch must not enqueue its initial command")
  }
  assert_eq(graph.run(fn() { root.read() }), "a:0")

  graph.begin()
  let _ = run_message(graph, set_source.emit("b"))
  assert_eq(graph.run(fn() { root.read() }), "b:0")
  graph.commit()
  match graph.take_initial_command() {
    CmdBatch(commands) => assert_eq(commands.length(), 1)
    _ => fail("committed branch must enqueue one initial command")
  }
  graph.dispose()
}

///|
test "resource runs one initial load and records its completion" {
  let graph = Graph::new()
  let resolvers : Ref[Array[Emit[Result[Int, Error]]]] = Ref([])
  let resource = graph.build(fn() {
    create_resource(emit => {
      resolvers.val.push(emit)
      none
    })
  })
  assert_true(graph.run(fn() { resource.read() }) is Pending)
  assert_eq(resolvers.val.length(), 1)
  match graph.take_initial_command() {
    CmdBatch(commands) => assert_eq(commands.length(), 1)
    _ => fail("resource must register one initial command")
  }
  graph.begin()
  let _ = run_message(graph, resolvers.val[0].emit(Ok(7)))
  graph.commit()
  assert_true(graph.run(fn() { resource.read() }) is Loaded(7))
  assert_eq(resolvers.val.length(), 1)
  graph.dispose()
}

///|
test "resource keeps the first committed terminal completion" {
  let graph = Graph::new()
  let resolver : Ref[Emit[Result[Int, Error]]?] = Ref(None)
  let resource = graph.build(fn() {
    create_resource(emit => {
      resolver.val = Some(emit)
      none
    })
  })
  let complete = resolver.val.unwrap()

  graph.begin()
  let _ = run_message(graph, complete.emit(Ok(7)))
  let _ = run_message(
    graph,
    complete.emit(Err(Failure::Failure("late failure"))),
  )
  graph.commit()
  assert_true(graph.run(fn() { resource.read() }) is Loaded(7))

  let revision = graph.candidate_revision()
  graph.begin()
  let _ = run_message(graph, complete.emit(Ok(9)))
  let _ = run_message(
    graph,
    complete.emit(Err(Failure::Failure("later failure"))),
  )
  assert_eq(graph.candidate_revision(), revision)
  graph.commit()
  assert_true(graph.run(fn() { resource.read() }) is Loaded(7))
  graph.dispose()
}

///|
test "resource failure wins when it is the first committed completion" {
  let graph = Graph::new()
  let resolver : Ref[Emit[Result[Int, Error]]?] = Ref(None)
  let resource = graph.build(fn() {
    create_resource(emit => {
      resolver.val = Some(emit)
      none
    })
  })
  let complete = resolver.val.unwrap()

  graph.begin()
  let _ = run_message(
    graph,
    complete.emit(Err(Failure::Failure("first failure"))),
  )
  let _ = run_message(graph, complete.emit(Ok(7)))
  graph.commit()
  assert_true(graph.run(fn() { resource.read() }) is Failed(_))
  graph.dispose()
}

///|
test "rolled back resource completion leaves the resource pending" {
  let graph = Graph::new()
  let resolver : Ref[Emit[Result[Int, Error]]?] = Ref(None)
  let resource = graph.build(fn() {
    create_resource(emit => {
      resolver.val = Some(emit)
      none
    })
  })
  let complete = resolver.val.unwrap()

  graph.begin()
  let _ = run_message(graph, complete.emit(Ok(7)))
  assert_true(graph.run(fn() { resource.read() }) is Loaded(7))
  graph.rollback()
  assert_true(graph.run(fn() { resource.read() }) is Pending)

  graph.begin()
  let _ = run_message(
    graph,
    complete.emit(Err(Failure::Failure("committed failure"))),
  )
  graph.commit()
  assert_true(graph.run(fn() { resource.read() }) is Failed(_))
  graph.dispose()
}

///|
test "disposed resource ignores a late completion" {
  let graph = Graph::new()
  let resolver : Ref[Emit[Result[Int, Error]]?] = Ref(None)
  let _resource = graph.build(fn() {
    create_resource(emit => {
      resolver.val = Some(emit)
      none
    })
  })
  let complete = resolver.val.unwrap()
  graph.dispose()

  let mut command = complete.emit(Ok(7))
  while command is CmdMessage(_) {
    match command {
      CmdMessage(run) => command = run()
      _ => ()
    }
  }
  assert_true(command is CmdNone)
}

///|
test "status equality compares loaded values and normalizes failures" {
  let pending : Status[Int] = Pending
  let failed_a : Status[Int] = Failed(Failure::Failure("a"))
  let failed_b : Status[Int] = Failed(Failure::Failure("b"))
  assert_true(pending == Pending)
  assert_true(Loaded(2) == Loaded(2))
  assert_false(Loaded(2) == Loaded(3))
  assert_true(failed_a == failed_b)
  assert_false(pending == Loaded(0))
  assert_eq(Enumerate::tag(pending), "pending")
  assert_eq(Enumerate::tag(Loaded(2)), "loaded")
  assert_eq(Enumerate::tag(failed_a), "failed")
}
