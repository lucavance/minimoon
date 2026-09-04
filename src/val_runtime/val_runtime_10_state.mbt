///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H : Eq, I] Val::map8(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  h : Val[H],
  map : (A, B, C, D, E, F, G, H) -> I,
) -> Val[I] {
  Val(a.0.map8(b.0, c.0, d.0, e.0, f.0, g.0, h.0, map))
}

///|
pub fn[
  A : Eq,
  B : Eq,
  C : Eq,
  D : Eq,
  E : Eq,
  F : Eq,
  G : Eq,
  H : Eq,
  I : Eq,
  J,
] Val::map9(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  h : Val[H],
  i : Val[I],
  map : (A, B, C, D, E, F, G, H, I) -> J,
) -> Val[J] {
  Val(a.0.map9(b.0, c.0, d.0, e.0, f.0, g.0, h.0, i.0, map))
}

///|
pub fn[K : Hash + Eq, V : Eq, C : Eq] Val::assoc(
  self : Val[Vector[(K, V)]],
  build : (K, Val[V]) -> Val[C],
) -> Val[Vector[C]] {
  Val(self.0.assoc((key, value) => build(key, Val(value)).0))
}

///|
pub fn[K : Hash + Eq, V : Eq, C : Eq] Val::assoc_by(
  self : Val[Vector[V]],
  build : (K, Val[V]) -> Val[C],
  by~ : (V) -> K,
) -> Val[Vector[C]] {
  Val(self.0.assoc_by((key, value) => build(key, Val(value)).0, by~))
}

///|
pub fn[E : @duplix.Enumerate + Eq, C : Eq] Val::switch(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
) -> Val[C] {
  Val(self.0.switch((initial, input) => build(initial, Val(input)).0))
}

///|
pub fn[E : Eq, C : Eq] Val::switch_by(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
  by~ : (E) -> String,
) -> Val[C] {
  Val(self.0.switch_by((initial, input) => build(initial, Val(input)).0, by~))
}

///|
pub fn[E : @duplix.Enumerate + Eq, C : Eq] Val::enumerate(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
) -> Val[C] {
  Val(self.0.enumerate((initial, input) => build(initial, Val(input)).0))
}

///|
pub fn[E : Eq, C : Eq] Val::enumerate_by(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
  by~ : (E) -> String,
) -> Val[C] {
  Val(
    self.0.enumerate_by((initial, input) => build(initial, Val(input)).0, by~),
  )
}

///|
pub fn[E : Eq, C : Eq] Val::enumerate_bounded_by(
  self : Val[E],
  capacity~ : Int,
  build~ : (E, Val[E]) -> Val[C],
  by~ : (E) -> String,
) -> Val[C] {
  Val(
    self.0.enumerate_bounded_by(
      capacity~,
      (initial, input) => build(initial, Val(input)).0,
      by~,
    ),
  )
}

///|
pub fn[A : Eq] Val::read(self : Val[A]) -> A {
  self.0.read()
}

///|
priv struct StateSlot[Model] {
  graph : Graph
  committed : Ref[Model]
  candidate : Ref[Model?]
  write : (Model) -> Unit
  active : Ref[Bool]
  enlisted : Ref[Bool]
}

///|
fn[Model] StateSlot::current(self : StateSlot[Model]) -> Model {
  match self.candidate.val {
    Some(value) => value
    None => self.committed.val
  }
}

///|
fn[Model : Eq] StateSlot::stage(self : StateSlot[Model], next : Model) -> Unit {
  if !self.active.val {
    return
  }
  let current = self.current()
  if next == current {
    return
  }
  let was_changed = current != self.committed.val
  if !self.enlisted.val {
    self.enlisted.val = true
    self.graph.enlist(
      fn() {
        match self.candidate.val {
          Some(value) => self.committed.val = value
          None => ()
        }
        self.candidate.val = None
        self.enlisted.val = false
      },
      fn() {
        self.candidate.val = None
        self.enlisted.val = false
        (self.write)(self.committed.val)
      },
    )
  }
  self.candidate.val = Some(next)
  let is_changed = next != self.committed.val
  if was_changed != is_changed {
    self.graph.pending_changes.val += if is_changed { 1 } else { -1 }
  }
  (self.write)(next)
}

///|
fn[Model : Eq] Graph::state_slot(
  self : Graph,
  initial : Model,
) -> (Val[Model], StateSlot[Model]) {
  let (node, write) = @duplix.input(initial)
  let slot = {
    graph: self,
    committed: Ref(initial),
    candidate: Ref(None),
    write,
    active: Ref(true),
    enlisted: Ref(false),
  }
  @duplix.on_visibility(visible => slot.active.val = visible)
  @duplix.on_cleanup(fn() { slot.active.val = false })
  (Val(node), slot)
}

///|
pub fn[Model : Eq] Graph::create_input(
  self : Graph,
  initial : Model,
) -> (Val[Model], Emit[Model]) {
  let (value, slot) = self.state_slot(initial)
  let address = self.reserve_state_address()
  let emit : Emit[Model] = state_emit(address)
  self.install_state_store(address, payload => {
    let next : Model = payload.into()
    slot.stage(next)
    CmdNone
  })
  (value, emit)
}

///|
fn current_graph() -> Graph {
  ambient_graph.val.unwrap_or_else(fn() {
    abort("state must be created while building a Minimoon page")
  })
}

///|
fn register_subscription(build : () -> Sub) -> Unit {
  let graph = current_graph()
  let id = graph.subscriptions.register(build)
  @duplix.on_visibility(visible => graph.subscriptions.set_visible(id, visible))
  @duplix.on_cleanup(fn() { graph.subscriptions.remove(id) })
}

///|
pub fn[Model : Eq, Msg] create_state(
  initial : Model,
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Val[Model], Emit[Msg]) {
  let graph = current_graph()
  let (value, slot) = graph.state_slot(initial)
  let address = graph.reserve_state_address()
  let emit : Emit[Msg] = state_emit(address)
  graph.install_state_store(address, payload => {
    if !slot.active.val {
      return CmdNone
    }
    let msg : Msg = payload.into()
    let (next, command) = update(slot.current(), msg, emit)
    slot.stage(next)
    command
  })
  match subscriptions {
    Some(build) => register_subscription(() => build(slot.current(), emit))
    None => ()
  }
  (value, emit)
}

///|
pub fn[Model : Eq, Msg] create_pure_state(
  initial : Model,
  update~ : (Model, Msg) -> Model,
) -> (Val[Model], Emit[Msg]) {
  create_state(initial, update=(model, msg, _) => (update(model, msg), CmdNone))
}

///|
pub fn[Model : Eq, Msg] create_state_with_init(
  init~ : (Emit[Msg]) -> (Model, Cmd),
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Val[Model], Emit[Msg]) {
  let graph = current_graph()
  let address = graph.reserve_state_address()
  let emit : Emit[Msg] = state_emit(address)
  let (initial, initial_command) = init(emit)
  let (value, slot) = graph.state_slot(initial)
  graph.install_state_store(address, payload => {
    if !slot.active.val {
      return CmdNone
    }
    let msg : Msg = payload.into()
    let (next, command) = update(slot.current(), msg, emit)
    slot.stage(next)
    command
  })
  match subscriptions {
    Some(build) => register_subscription(() => build(slot.current(), emit))
    None => ()
  }
  graph.enqueue_initial_command(initial_command)
  (value, emit)
}

///|
pub fn[Model : Eq, Msg, Input : Eq] create_state_with_input(
  init~ : (Emit[Msg], Input) -> (Model, Cmd),
  update~ : (Model, Input, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Input, Emit[Msg]) -> Sub,
  input~ : Val[Input],
) -> (Val[Model], Emit[Msg]) {
  let graph = current_graph()
  let address = graph.reserve_state_address()
  let emit : Emit[Msg] = state_emit(address)
  let (initial, initial_command) = init(emit, input.read())
  let (value, slot) = graph.state_slot(initial)
  graph.install_state_store(address, payload => {
    if !slot.active.val {
      return CmdNone
    }
    let msg : Msg = payload.into()
    let (next, command) = update(slot.current(), input.read(), msg, emit)
    slot.stage(next)
    command
  })
  match subscriptions {
    Some(build) =>
      register_subscription(() => build(slot.current(), input.read(), emit))
    None => ()
  }
  graph.enqueue_initial_command(initial_command)
  (value, emit)
}

///|
pub fn[Model : Eq] create_variable(
  initial : Model,
) -> (Val[Model], Emit[(Model) -> Model]) {
  create_pure_state(initial, update=(model, transform) => transform(model))
}

///|
pub enum Status[T] {
  Pending
  Loaded(T)
  Failed(Error)
}

///|
pub impl[T : Eq] Eq for Status[T] with fn equal(left, right) {
  match (left, right) {
    (Pending, Pending) | (Failed(_), Failed(_)) => true
    (Loaded(a), Loaded(b)) => a == b
    _ => false
  }
}

///|
/// Creates a one-shot resource. Only the first completion committed while the
/// resource is pending can select its terminal status; later completions are
/// ignored.
pub fn[T : Eq] create_resource(
  load : (Emit[Result[T, Error]]) -> Cmd,
) -> Val[Status[T]] {
  let (status, _) : (Val[Status[T]], Emit[Result[T, Error]]) = create_state_with_init(
    init=emit => (Pending, load(emit)),
    update=(current, result, _) => {
      match current {
        Pending => {
          let next = match result {
            Ok(value) => Loaded(value)
            Err(error) => Failed(error)
          }
          (next, CmdNone)
        }
        Loaded(_) | Failed(_) => (current, CmdNone)
      }
    },
  )
  status
}

///|
pub impl[T] @duplix.Enumerate for Status[T] with fn tag(self) {
  match self {
    Pending => "pending"
    Loaded(_) => "loaded"
    Failed(_) => "failed"
  }
}

///|
pub using @duplix {trait Enumerate}
