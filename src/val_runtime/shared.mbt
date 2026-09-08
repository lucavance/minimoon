///|
pub struct Shared[T] {
  address : @slotmap.Id
  value : Val[T]
}

///|
struct SharedBinding {
  active : Ref[Bool]
  refresh : () -> Cmd
  changed : () -> Bool
}

///|
pub fn Graph::attach_shared_runtime(
  self : Graph,
  wake : () -> Unit,
  dispose : () -> Unit,
) -> Unit {
  self.shared_wake.val = wake
  self.shared_dispose.val = dispose
  match self.application.val {
    Some(owner) =>
      if !owner.pages.any(page => page.generation == self.generation) {
        owner.pages.push(self)
      }
    None => ()
  }
}

///|
fn Graph::detach_application(self : Graph) -> Unit {
  if self.application.val is Some(owner) {
    if owner.pages.search_by(page => page.generation == self.generation)
      is Some(index) {
      ignore(owner.pages.remove(index))
    }
  }
  self.application.val = None
  self.shared_bindings.val = SlotMap()
  self.shared_binding_order.clear()
  self.shared_wake.val = fn() { () }
  self.shared_dispose.val = fn() { () }
}

///|
pub fn Graph::set_shared_visible(self : Graph, visible : Bool) -> Unit {
  self.shared_visible.val = visible
}

///|
fn Graph::notify_shared(self : Graph) -> Unit {
  if self.has_shared_changes() {
    (self.shared_wake.val)()
  }
}

///|
pub fn Graph::has_shared_changes(self : Graph) -> Bool {
  guard !self.disposed.val && self.shared_visible.val else { return false }
  for id in self.shared_binding_order {
    let binding = self.shared_bindings.val[id]
    if binding.active.val && (binding.changed)() {
      return true
    }
  }
  false
}

///|
pub fn Graph::refresh_shared(self : Graph) -> Cmd {
  guard !self.disposed.val && self.shared_visible.val else { return CmdNone }
  let commands : Array[Cmd] = []
  for id in self.shared_binding_order {
    let binding = self.shared_bindings.val[id]
    if binding.active.val {
      commands.push((binding.refresh)())
    }
  }
  batch(commands)
}

///|
pub fn[T : Eq, U : Eq] Graph::select_shared(
  self : Graph,
  shared : Shared[T],
  select : (T) -> U,
) -> Val[U] {
  guard ambient_graph.val is Some(graph) && graph.generation == self.generation else {
    abort("shared values must be bound while building their page")
  }
  guard applications.get(shared.address) is Some(owner) else {
    abort("shared value belongs to a disposed application")
  }
  guard self.application.val is Some(expected) &&
    expected.address == shared.address else {
    abort("shared value belongs to another application or an unattached page")
  }
  let sample = fn() { owner.graph.run(() => select(shared.value.read())) }
  let (value, slot) = self.state_slot(sample())
  let address = self.reserve_state_address()
  let emit : Emit[U] = state_emit(address)
  self.install_state_store(address, payload => {
    let next : U = payload.into()
    slot.stage(next)
    CmdNone
  })
  let active = Ref(true)
  let binding = self.shared_bindings.val.allocate_with(_ => {
    active,
    refresh: fn() { emit.emit(sample()) },
    changed: fn() { sample() != slot.current() },
  })
  self.shared_binding_order.push(binding)
  @duplix.on_visibility(visible => {
    active.val = visible
    if visible {
      self.enqueue_initial_command(CmdMessage(fn() { self.refresh_shared() }))
    }
  })
  @duplix.on_cleanup(fn() {
    active.val = false
    if self.shared_bindings.val.get(binding) is Some(_) {
      self.shared_bindings.val.free(binding)
      if self.shared_binding_order.search(binding) is Some(index) {
        ignore(self.shared_binding_order.remove(index))
      }
    }
  })
  value
}
