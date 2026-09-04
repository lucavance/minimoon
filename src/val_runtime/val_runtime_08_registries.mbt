///|
struct GraphGeneration(@slotmap.Id) derive(Eq)

///|
priv struct StateAddress {
  graph : GraphGeneration
  state : @slotmap.Id
}

///|
priv struct StateStore {
  dispatch : (@any.Any) -> Cmd
}

///|
struct StateRegistry {
  slots : Ref[@slotmap.SlotMap[StateStore]]
  live : Ref[Int]
}

///|
fn StateRegistry::new() -> StateRegistry {
  { slots: Ref(SlotMap()), live: Ref(0), }
}

///|
fn StateRegistry::reserve(self : StateRegistry) -> @slotmap.Id {
  self.slots.val.allocate()
}

///|
fn StateRegistry::install(
  self : StateRegistry,
  id : @slotmap.Id,
  dispatch : (@any.Any) -> Cmd,
) -> Unit {
  guard self.slots.val.get(id) is None else {
    abort("state store slot is already occupied")
  }
  self.slots.val[id] = { dispatch, }
  self.live.val += 1
}

///|
fn StateRegistry::remove(self : StateRegistry, id : @slotmap.Id) -> Unit {
  if self.slots.val.get(id) is Some(_) {
    self.slots.val.free(id)
    self.live.val -= 1
  }
}

///|
fn StateRegistry::dispatch(
  self : StateRegistry,
  id : @slotmap.Id,
  payload : @any.Any,
) -> Cmd {
  match self.slots.val.get(id) {
    Some(store) => (store.dispatch)(payload)
    None => CmdNone
  }
}

///|
fn StateRegistry::reset(self : StateRegistry) -> Unit {
  self.slots.val = SlotMap()
  self.live.val = 0
}

///|
struct SubscriptionRegistry {
  slots : Ref[@slotmap.SlotMap[SubscriptionProvider]]
  order : Ref[Array[@slotmap.Id]]
}

///|
fn SubscriptionRegistry::new() -> SubscriptionRegistry {
  { slots: Ref(SlotMap()), order: Ref([]), }
}

///|
fn SubscriptionRegistry::register(
  self : SubscriptionRegistry,
  build : () -> Sub,
) -> @slotmap.Id {
  let id = self.slots.val.allocate_with(_ => { active: Ref(true), build, })
  self.order.val.push(id)
  id
}

///|
fn SubscriptionRegistry::set_visible(
  self : SubscriptionRegistry,
  id : @slotmap.Id,
  visible : Bool,
) -> Unit {
  match self.slots.val.get(id) {
    Some(provider) => provider.active.val = visible
    None => ()
  }
}

///|
fn SubscriptionRegistry::remove(
  self : SubscriptionRegistry,
  id : @slotmap.Id,
) -> Unit {
  guard self.slots.val.get(id) is Some(_) else { return }
  self.slots.val.free(id)
  match self.order.val.search(id) {
    Some(index) => ignore(self.order.val.remove(index))
    None =>
      abort("live subscription provider is missing from registration order")
  }
}

///|
fn SubscriptionRegistry::current(self : SubscriptionRegistry) -> Sub {
  let output : Array[Sub] = []
  for id in self.order.val {
    guard self.slots.val.get(id) is Some(provider) else {
      abort("subscription registration order contains a stale provider")
    }
    if provider.active.val {
      output.push((provider.build)())
    }
  }
  SubBatch(output)
}

///|
fn SubscriptionRegistry::reset(self : SubscriptionRegistry) -> Unit {
  self.slots.val = SlotMap()
  self.order.val = []
}

///|
let graph_generations : @slotmap.SlotMap[Unit] = SlotMap()

///|
fn allocate_graph_generation() -> GraphGeneration {
  GraphGeneration(graph_generations.allocate_with(_ => ()))
}

///|
fn release_graph_generation(generation : GraphGeneration) -> Unit {
  if graph_generations.get(generation.0) is Some(_) {
    graph_generations.free(generation.0)
  }
}

///|
fn Graph::reserve_state_address(self : Graph) -> StateAddress {
  { graph: self.generation, state: self.state_registry.reserve(), }
}

///|
fn Graph::install_state_store(
  self : Graph,
  address : StateAddress,
  dispatch : (@any.Any) -> Cmd,
) -> Unit {
  guard address.graph == self.generation else {
    abort("state store address belongs to another graph generation")
  }
  self.state_registry.install(address.state, dispatch)
  @duplix.on_cleanup(fn() { self.state_registry.remove(address.state) })
}

///|
fn dispatch_state_message(address : StateAddress, payload : @any.Any) -> Cmd {
  match ambient_graph.val {
    Some(graph) if !graph.disposed.val && graph.generation == address.graph =>
      graph.state_registry.dispatch(address.state, payload)
    _ => CmdNone
  }
}

///|
fn[Msg] state_emit(address : StateAddress) -> Emit[Msg] {
  Emit(message => {
    let payload = @any.erase(message)
    CmdMessage(fn() { dispatch_state_message(address, payload) })
  })
}
