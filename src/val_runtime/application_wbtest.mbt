///|
test "application disposal frees page bindings stores subscriptions and registry addresses" {
  for _cycle = 0; _cycle < 100; _cycle = _cycle + 1 {
    let owner = Application::new()
    let address = owner.address
    let shared = owner.build(fn() {
        owner.create_state_with_init(
          _ => (0, none),
          (model, msg : Int, _) => (model + msg, none),
          Some((_, emit) => every("tick", 1000, emit.emit(1))),
        )
      }).0
    let page = owner.with_pages(Graph::new)
    let value = page.build(() => page.select_shared(shared, value => value + 0))
    page.attach_shared_runtime(fn() { () }, fn() { () })
    assert_eq(page.run(() => value.read()), 0)
    assert_eq(owner.page_count(), 1)
    assert_eq(page.shared_binding_order.length(), 1)
    assert_eq(page.state_store_count_for_test(), 1)
    assert_eq(owner.graph.state_store_count_for_test(), 1)
    assert_eq(owner.graph.subscription_provider_count_for_test(), 1)
    owner.dispose()
    assert_true(applications.get(address) is None)
    assert_eq(owner.page_count(), 0)
    assert_eq(page.shared_binding_order.length(), 0)
    assert_eq(page.state_store_count_for_test(), 0)
    assert_eq(owner.graph.state_store_count_for_test(), 0)
    assert_eq(owner.graph.subscription_provider_count_for_test(), 0)
    assert_true(page.disposed.val)
    owner.dispose()
  }
}
