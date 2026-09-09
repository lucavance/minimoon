///|
using @vector {type Vector}

///|
pub struct DecodeError {
  message : String
}

///|
pub fn decode_error(message : String) -> DecodeError {
  guard message != "" else { abort("decode error must not be empty") }
  { message, }
}

///|
pub fn DecodeError::message(self : DecodeError) -> String {
  self.message
}

///|
pub(all) enum HostOutcome {
  HostOk(String)
  HostErr(String, String, String)
}

///|
pub(all) enum Cmd {
  CmdNone
  CmdMessage(() -> Cmd)
  CmdBatch(Array[Cmd])
  CmdEffect(((Cmd) -> Unit, () -> Unit) -> () -> Unit)
  CmdHostEffect(String, String, (HostOutcome) -> Cmd)
  CmdNavigateTo(String)
  CmdRedirectTo(String)
  CmdSwitchTab(String)
  CmdNavigateBack(Int)
  CmdNavigateBackOrRedirect(Int, String)
}

///|
pub(all) struct Emit[Msg]((Msg) -> Cmd)

///|
pub fn[Msg] Emit::emit(self : Emit[Msg], message : Msg) -> Cmd {
  (self.0)(message)
}

///|
pub fn[A, B] Emit::map(self : Emit[A], map : (B) -> A) -> Emit[B] {
  Emit(value => self.emit(map(value)))
}

///|
pub let none : Cmd = CmdNone

///|
pub fn batch(commands : Array[Cmd]) -> Cmd {
  CmdBatch(commands)
}

///|
pub fn host_effect(
  capability : String,
  payload : String,
  resolve : (HostOutcome) -> Cmd,
) -> Cmd {
  CmdHostEffect(capability, payload, resolve)
}

///|
pub fn navigate_to(url : String) -> Cmd {
  CmdNavigateTo(url)
}

///|
pub fn redirect_to(url : String) -> Cmd {
  CmdRedirectTo(url)
}

///|
pub fn switch_tab(url : String) -> Cmd {
  CmdSwitchTab(url)
}

///|
pub fn navigate_back(delta : Int) -> Cmd {
  guard delta >= 1 else {
    abort("MiniApp navigateBack delta must be at least 1")
  }
  CmdNavigateBack(delta)
}

///|
pub fn navigate_back_or_redirect(delta : Int, fallback : String) -> Cmd {
  guard delta >= 1 else {
    abort("MiniApp navigateBack delta must be at least 1")
  }
  guard fallback != "" else {
    abort("MiniApp navigation fallback must not be empty")
  }
  CmdNavigateBackOrRedirect(delta, fallback)
}

///|
pub(all) enum Sub {
  SubNone
  SubBatch(Array[Sub])
  SubEvery(String, Int, Cmd)
  SubLifecycle(String, (Json) -> Result[Cmd, DecodeError])
}

///|
pub fn sub_batch(subscriptions : Array[Sub]) -> Sub {
  SubBatch(subscriptions)
}

///|
pub let no_sub : Sub = SubNone

///|
pub fn every(key : String, interval_ms : Int, command : Cmd) -> Sub {
  guard key != "" else { abort("subscription key must not be empty") }
  guard interval_ms > 0 else { abort("subscription interval must be positive") }
  SubEvery(key, interval_ms, command)
}

///|
pub fn lifecycle(
  hook : String,
  decode : (Json) -> Result[Cmd, DecodeError],
) -> Sub {
  SubLifecycle(hook, decode)
}

///|
priv struct SubscriptionProvider {
  active : Ref[Bool]
  build : () -> Sub
}

///|
pub struct Graph {
  generation : GraphGeneration
  root_scope : @duplix.RootScope
  transaction_active : Ref[Bool]
  revision : Ref[Int]
  pending_changes : Ref[Int]
  commits : Ref[Array[() -> Unit]]
  rollbacks : Ref[Array[() -> Unit]]
  state_registry : StateRegistry
  subscriptions : SubscriptionRegistry
  initial_commands : Ref[Array[Cmd]]
  disposed : Ref[Bool]
  application : Ref[Application?]
  shared_bindings : Ref[@slotmap.SlotMap[SharedBinding]]
  shared_binding_order : Array[@slotmap.Id]
  shared_visible : Ref[Bool]
  shared_wake : Ref[() -> Unit]
  shared_dispose : Ref[() -> Unit]
}

///|
let ambient_graph : Ref[Graph?] = Ref(None)

///|
pub fn Graph::new() -> Graph {
  {
    generation: allocate_graph_generation(),
    root_scope: @duplix.RootScope::new(),
    transaction_active: Ref(false),
    revision: Ref(0),
    pending_changes: Ref(0),
    commits: Ref([]),
    rollbacks: Ref([]),
    state_registry: StateRegistry::new(),
    subscriptions: SubscriptionRegistry::new(),
    initial_commands: Ref([]),
    disposed: Ref(false),
    application: Ref(ambient_application.val),
    shared_bindings: Ref(SlotMap()),
    shared_binding_order: [],
    shared_visible: Ref(true),
    shared_wake: Ref(fn() { () }),
    shared_dispose: Ref(fn() { () }),
  }
}

///|
pub fn[A] Graph::build(self : Graph, build : () -> A) -> A {
  guard !self.disposed.val else { abort("incremental graph is disposed") }
  self.root_scope.run(() => ambient_graph.protect(Some(self), build))
}

///|
pub fn[A] Graph::run(self : Graph, run : () -> A) -> A {
  guard !self.disposed.val else { abort("incremental graph is disposed") }
  self.root_scope.run(() => {
    ambient_graph.protect(Some(self), fn() {
      if self.transaction_active.val {
        @duplix.transaction(
          (commit, rollback) => self.enlist(commit, rollback),
          run,
        )
      } else {
        run()
      }
    })
  })
}

///|
pub fn Graph::begin(self : Graph) -> Unit {
  guard !self.disposed.val else { abort("incremental graph is disposed") }
  guard !self.transaction_active.val else {
    abort("incremental graph transaction is already active")
  }
  self.commits.val = []
  self.rollbacks.val = []
  self.pending_changes.val = 0
  self.transaction_active.val = true
}

///|
pub fn Graph::candidate_revision(self : Graph) -> Int {
  self.revision.val + (if self.pending_changes.val > 0 { 1 } else { 0 })
}

///|
fn Graph::enlist(
  self : Graph,
  commit : () -> Unit,
  rollback : () -> Unit,
) -> Unit {
  guard self.transaction_active.val else {
    abort("state updates require an active graph transaction")
  }
  self.commits.val.push(commit)
  self.rollbacks.val.push(rollback)
}

///|
pub fn Graph::commit(self : Graph) -> Unit {
  if !self.transaction_active.val {
    return
  }
  let callbacks = self.commits.val
  self.commits.val = []
  self.rollbacks.val = []
  self.transaction_active.val = false
  if self.pending_changes.val > 0 {
    self.revision.val += 1
  }
  self.pending_changes.val = 0
  for callback in callbacks {
    callback()
  }
}

///|
pub fn Graph::rollback(self : Graph) -> Unit {
  if !self.transaction_active.val {
    return
  }
  let callbacks = self.rollbacks.val
  self.commits.val = []
  self.rollbacks.val = []
  self.transaction_active.val = false
  self.pending_changes.val = 0
  for callback in callbacks.rev() {
    callback()
  }
}

///|
pub fn Graph::dispose(self : Graph) -> Unit {
  if self.disposed.val {
    return
  }
  self.rollback()
  self.disposed.val = true
  self.detach_application()
  self.root_scope.dispose()
  self.pending_changes.val = 0
  self.state_registry.reset()
  self.subscriptions.reset()
  self.initial_commands.val = []
  release_graph_generation(self.generation)
}

///|
pub fn Graph::take_initial_command(self : Graph) -> Cmd {
  let commands = self.initial_commands.val
  self.initial_commands.val = []
  batch(commands)
}

///|
fn Graph::enqueue_initial_command(self : Graph, command : Cmd) -> Unit {
  if self.transaction_active.val {
    self.enlist(fn() { self.initial_commands.val.push(command) }, fn() { () })
  } else {
    self.initial_commands.val.push(command)
  }
}

///|
pub fn Graph::current_subscriptions(self : Graph) -> Sub {
  self.subscriptions.current()
}

///|
pub struct Val[A](@duplix.Node[A])

///|
pub fn[A] Val::constant(value : A) -> Val[A] {
  Val(@duplix.constant(value))
}

///|
pub fn[A : Eq, B] Val::map(self : Val[A], map : (A) -> B) -> Val[B] {
  Val(self.0.map1(map))
}

///|
pub fn[A : Eq, B : Eq, C] Val::map2(
  a : Val[A],
  b : Val[B],
  map : (A, B) -> C,
) -> Val[C] {
  Val(a.0.map2(b.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D] Val::map3(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  map : (A, B, C) -> D,
) -> Val[D] {
  Val(a.0.map3(b.0, c.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E] Val::map4(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  map : (A, B, C, D) -> E,
) -> Val[E] {
  Val(a.0.map4(b.0, c.0, d.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F] Val::map5(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  map : (A, B, C, D, E) -> F,
) -> Val[F] {
  Val(a.0.map5(b.0, c.0, d.0, e.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G] Val::map6(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  map : (A, B, C, D, E, F) -> G,
) -> Val[G] {
  Val(a.0.map6(b.0, c.0, d.0, e.0, f.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H] Val::map7(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  map : (A, B, C, D, E, F, G) -> H,
) -> Val[H] {
  Val(a.0.map7(b.0, c.0, d.0, e.0, f.0, g.0, map))
}
