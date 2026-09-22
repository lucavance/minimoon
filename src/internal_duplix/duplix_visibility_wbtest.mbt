///|
test "ancestor visibility preserves nested local choices and sends only transitions" {
  let root = RootScope::new()
  let events : Array[String] = []
  let cleaned = Ref(0)
  let (parent, hidden, active, grandchild) = root.run(fn() {
    with_scope(parent => {
      on_cleanup(fn() { cleaned.val += 1 })
      on_visibility(visible => events.push("parent:" + visible.to_string()))
      let hidden = with_scope(id => {
        on_cleanup(fn() { cleaned.val += 1 })
        on_visibility(visible => events.push("hidden:" + visible.to_string()))
        id
      })
      let (active, grandchild) = with_scope(id => {
        on_cleanup(fn() { cleaned.val += 1 })
        on_visibility(visible => events.push("active:" + visible.to_string()))
        let child = with_scope(child => {
          on_cleanup(fn() { cleaned.val += 1 })
          on_visibility(visible => {
            events.push("grandchild:" + visible.to_string())
          })
          child
        })
        (id, child)
      })
      (parent, hidden, active, grandchild)
    })
  })
  assert_eq(events, [])
  set_scope_visible(hidden, false)
  set_scope_visible(parent, false)
  let hidden_events = events.length()
  set_scope_visible(parent, false)
  assert_eq(events.length(), hidden_events)
  assert_false(global_scopes[hidden].effective_visible)
  assert_false(global_scopes[active].effective_visible)
  assert_false(global_scopes[grandchild].effective_visible)
  set_scope_visible(parent, true)
  assert_false(global_scopes[hidden].effective_visible)
  assert_true(global_scopes[active].effective_visible)
  assert_true(global_scopes[grandchild].effective_visible)
  assert_false(events.contains("hidden:true"))
  let restored_events = events.length()
  set_scope_visible(parent, true)
  assert_eq(events.length(), restored_events)
  root.dispose()
  root.dispose()
  assert_eq(cleaned.val, 4)
  for id in [parent, hidden, active, grandchild] {
    assert_true(global_scopes.get(id) is None)
  }
}

///|
test "children created below a hidden parent start inactive and retain local changes" {
  let root = RootScope::new()
  let events : Array[Bool] = []
  let (parent, child) = root.run(fn() {
    with_scope(parent => {
      set_scope_visible(parent, false)
      let child = with_scope(child => {
        on_visibility(visible => events.push(visible))
        child
      })
      (parent, child)
    })
  })
  assert_eq(events, [false])
  set_scope_visible(child, false)
  set_scope_visible(child, true)
  assert_eq(events, [false])
  set_scope_visible(child, false)
  set_scope_visible(parent, true)
  assert_eq(events, [false])
  set_scope_visible(child, true)
  assert_eq(events, [false, true])
  root.dispose()
}
