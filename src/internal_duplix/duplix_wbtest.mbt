///|
priv struct DynamicTestInput {
  tag : String
  value : Int
} derive(Eq)

///|
test "switch keeps same-tag input reactive and rolls candidate scope back" {
  let root = RootScope::new()
  let builds = Ref(0)
  let visibility = Ref("")
  let cleaned = Ref("")
  let (output, set_source) = root.run(fn() {
    let (source, set_source) = input({ tag: "a", value: 1, })
    let output = source.switch_by(
      (initial, current) => {
        builds.val += 1
        on_visibility(visible => {
          let state = if visible { ":shown;" } else { ":hidden;" }
          visibility.val = visibility.val + initial.tag + state
        })
        on_cleanup(fn() { cleaned.val = cleaned.val + initial.tag })
        current.map(value => initial.tag + ":" + value.value.to_string())
      },
      by=value => value.tag,
    )
    (output, set_source)
  })

  assert_eq(root.run(fn() { output.read() }), "a:1")
  set_source({ tag: "a", value: 2, })
  assert_eq(root.run(fn() { output.read() }), "a:2")
  assert_eq(builds.val, 1)

  let input_rollbacks : Array[() -> Unit] = []
  set_source({ tag: "a", value: 9, })
  assert_eq(
    root.run(fn() {
      transaction((_commit, rollback) => input_rollbacks.push(rollback), fn() {
        output.read()
      })
    }),
    "a:9",
  )
  for rollback in input_rollbacks.rev() {
    rollback()
  }
  set_source({ tag: "a", value: 2, })
  assert_eq(root.run(fn() { output.read() }), "a:2")

  let rollbacks : Array[() -> Unit] = []
  set_source({ tag: "b", value: 3, })
  let candidate = root.run(fn() {
    transaction((_commit, rollback) => rollbacks.push(rollback), fn() {
      output.read()
    })
  })
  assert_eq(candidate, "b:3")
  assert_eq(visibility.val, "a:hidden;")
  for rollback in rollbacks.rev() {
    rollback()
  }
  assert_eq(visibility.val, "a:hidden;a:shown;")
  assert_eq(cleaned.val, "b")

  set_source({ tag: "a", value: 2, })
  assert_eq(root.run(fn() { output.read() }), "a:2")
  set_source({ tag: "b", value: 4, })
  assert_eq(root.run(fn() { output.read() }), "b:4")
  assert_eq(cleaned.val, "ba")
  root.dispose()
  assert_eq(cleaned.val, "bab")
}

///|
test "enumerate caches state and only exposes the active branch" {
  let root = RootScope::new()
  let builds = Ref(0)
  let a_visible = Ref(true)
  let b_visible = Ref(true)
  let c_visible = Ref(true)
  let a_cleaned = Ref(0)
  let b_cleaned = Ref(0)
  let c_cleaned = Ref(0)
  let set_a_local : Ref[((Int) -> Unit)?] = Ref(None)
  let set_b_local : Ref[((Int) -> Unit)?] = Ref(None)
  let (output, set_source) = root.run(fn() {
    let (source, set_source) = input({ tag: "a", value: 1, })
    let output = source.enumerate_by(
      (initial, current) => {
        builds.val += 1
        let (local_state, set_local) = input(0)
        match initial.tag {
          "a" => set_a_local.val = Some(set_local)
          "b" => set_b_local.val = Some(set_local)
          _ => ()
        }
        on_visibility(visible => {
          match initial.tag {
            "a" => a_visible.val = visible
            "b" => b_visible.val = visible
            _ => c_visible.val = visible
          }
        })
        on_cleanup(fn() {
          match initial.tag {
            "a" => a_cleaned.val += 1
            "b" => b_cleaned.val += 1
            _ => c_cleaned.val += 1
          }
        })
        current.map2(local_state, (value, local_value) => {
          initial.tag +
          ":" +
          value.value.to_string() +
          ":" +
          local_value.to_string()
        })
      },
      by=value => value.tag,
    )
    (output, set_source)
  })

  assert_eq(root.run(fn() { output.read() }), "a:1:0")
  match set_a_local.val {
    Some(set_local) => set_local(7)
    None => fail("missing a local state")
  }
  assert_eq(root.run(fn() { output.read() }), "a:1:7")

  set_source({ tag: "b", value: 2, })
  assert_eq(root.run(fn() { output.read() }), "b:2:0")
  assert_eq(a_visible.val, false)
  assert_eq(b_visible.val, true)
  match set_b_local.val {
    Some(set_local) => set_local(9)
    None => fail("missing b local state")
  }

  set_source({ tag: "a", value: 3, })
  assert_eq(root.run(fn() { output.read() }), "a:3:7")
  assert_eq(builds.val, 2)
  assert_eq(a_visible.val, true)
  assert_eq(b_visible.val, false)

  let rollbacks : Array[() -> Unit] = []
  set_source({ tag: "c", value: 4, })
  assert_eq(
    root.run(fn() {
      transaction((_commit, rollback) => rollbacks.push(rollback), fn() {
        output.read()
      })
    }),
    "c:4:0",
  )
  assert_eq(a_visible.val, false)
  for rollback in rollbacks.rev() {
    rollback()
  }
  assert_eq(a_visible.val, true)
  assert_eq(c_cleaned.val, 1)

  set_source({ tag: "a", value: 3, })
  assert_eq(root.run(fn() { output.read() }), "a:3:7")
  assert_eq(a_cleaned.val, 0)
  assert_eq(b_cleaned.val, 0)
  root.dispose()
  assert_eq(a_cleaned.val, 1)
  assert_eq(b_cleaned.val, 1)
  assert_eq(c_cleaned.val, 1)
}

///|
test "bounded enumerate evicts committed LRU state and restores rollback" {
  let root = RootScope::new()
  let builds = Ref(0)
  let cleaned : Map[String, Int] = Map([])
  let set_a_local : Ref[((Int) -> Unit)?] = Ref(None)
  let (output, set_source) = root.run(fn() {
    let (source, set_source) = input({ tag: "a", value: 1, })
    let output = source.enumerate_bounded_by(
      capacity=2,
      (initial, current) => {
        builds.val += 1
        let (local_node, set_local) = input(0)
        if initial.tag == "a" {
          set_a_local.val = Some(set_local)
        }
        on_cleanup(fn() {
          cleaned[initial.tag] = cleaned.get(initial.tag).unwrap_or(0) + 1
        })
        current.map2(local_node, (value, local_value) => {
          value.tag +
          ":" +
          value.value.to_string() +
          ":" +
          local_value.to_string()
        })
      },
      by=value => value.tag,
    )
    (output, set_source)
  })

  assert_eq(root.run(fn() { output.read() }), "a:1:0")
  match set_a_local.val {
    Some(set_local) => set_local(7)
    None => fail("missing bounded a local state")
  }
  set_source({ tag: "b", value: 2, })
  assert_eq(root.run(fn() { output.read() }), "b:2:0")
  set_source({ tag: "a", value: 3, })
  assert_eq(root.run(fn() { output.read() }), "a:3:7")

  let rollbacks : Array[() -> Unit] = []
  set_source({ tag: "c", value: 4, })
  assert_eq(
    root.run(fn() {
      transaction((_commit, rollback) => rollbacks.push(rollback), fn() {
        output.read()
      })
    }),
    "c:4:0",
  )
  for rollback in rollbacks.rev() {
    rollback()
  }
  assert_eq(cleaned.get("c"), Some(1))
  assert_eq(cleaned.get("b"), None)
  set_source({ tag: "a", value: 3, })
  assert_eq(root.run(fn() { output.read() }), "a:3:7")

  set_source({ tag: "c", value: 5, })
  assert_eq(root.run(fn() { output.read() }), "c:5:0")
  assert_eq(cleaned.get("b"), Some(1))
  set_source({ tag: "b", value: 6, })
  assert_eq(root.run(fn() { output.read() }), "b:6:0")
  assert_eq(builds.val, 5)
  assert_eq(cleaned.get("a"), Some(1))
  root.dispose()
  assert_eq(cleaned.get("b"), Some(2))
  assert_eq(cleaned.get("c"), Some(2))
}

///|
test "bounded enumerate retains capacity across ten thousand committed tags" {
  let root = RootScope::new()
  let live = Ref(0)
  let disposed = Ref(0)
  let (output, set_source) = root.run(fn() {
    let (source, set_source) = input(0)
    let output = source.enumerate_bounded_by(
      capacity=8,
      (initial, current) => {
        live.val += 1
        on_cleanup(fn() {
          live.val -= 1
          disposed.val += 1
        })
        current.map(value => initial.to_string() + ":" + value.to_string())
      },
      by=value => value.to_string(),
    )
    (output, set_source)
  })
  assert_eq(root.run(fn() { output.read() }), "0:0")
  for tag = 1; tag < 10000; tag = tag + 1 {
    set_source(tag)
    assert_eq(
      root.run(fn() { output.read() }),
      tag.to_string() + ":" + tag.to_string(),
    )
    assert_eq(live.val <= 8, true)
  }
  assert_eq(live.val, 8)
  assert_eq(disposed.val, 9992)
  root.dispose()
  assert_eq(live.val, 0)
  assert_eq(disposed.val, 10000)
}
