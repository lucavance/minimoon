///|
/// A headless application owns a graph and an addressable command inbox.
/// Addresses, rather than owner closures, are captured by public emitters.
pub struct Application {
  address : @slotmap.Id
  graph : Graph
  messages : Array[Cmd]
  pages : Array[Graph]
  wake : Ref[() -> Unit]
  started : Ref[Bool]
  building : Ref[Bool]
  disposed : Ref[Bool]
}

///|
let applications : @slotmap.SlotMap[Application] = SlotMap()

///|
let ambient_application : Ref[Application?] = Ref(None)

///|
pub fn Application::new() -> Application {
  let address = applications.allocate()
  let graph = ambient_application.protect(None, Graph::new)
  let owner = {
    address,
    graph,
    messages: [],
    pages: [],
    wake: Ref(fn() { () }),
    started: Ref(false),
    building: Ref(false),
    disposed: Ref(false),
  }
  applications[address] = owner
  owner
}

///|
pub fn[A] Application::build(self : Application, build : () -> A) -> A {
  guard !self.is_disposed() else { abort("application is disposed") }
  self.building.protect(true, () => self.graph.build(build))
}

///|
pub fn[A] Application::with_pages(self : Application, build : () -> A) -> A {
  guard !self.is_disposed() else { abort("application is disposed") }
  ambient_application.protect(Some(self), build)
}

///|
pub fn Application::graph(self : Application) -> Graph {
  self.graph
}

///|
pub fn Application::is_disposed(self : Application) -> Bool {
  self.disposed.val
}

///|
pub fn Application::set_wake(self : Application, wake : () -> Unit) -> Unit {
  self.wake.val = wake
}

///|
pub fn Application::start(self : Application) -> Unit {
  guard !self.is_disposed() && !self.started.val else { return }
  self.started.val = true
  self.enqueue(self.graph.take_initial_command())
}

///|
pub fn Application::enqueue(self : Application, command : Cmd) -> Unit {
  guard !self.is_disposed() else { return }
  match command {
    CmdNone => ()
    CmdBatch(commands) =>
      for command in commands {
        self.enqueue(command)
      }
    _ => {
      self.messages.push(command)
      if self.started.val {
        (self.wake.val)()
      }
    }
  }
}

///|
pub fn Application::next(self : Application) -> Cmd? {
  if !self.started.val || self.is_disposed() || self.messages.is_empty() {
    None
  } else {
    Some(self.messages.remove(0))
  }
}

///|
pub fn Application::pending_count(self : Application) -> Int {
  self.messages.length()
}

///|
pub fn Application::page_count(self : Application) -> Int {
  self.pages.length()
}

///|
pub fn Application::publish(self : Application) -> Unit {
  for page in self.pages.copy() {
    page.notify_shared()
  }
}

///|
pub fn Application::dispose(self : Application) -> Unit {
  guard !self.is_disposed() else { return }
  // Invalidate address delivery before invoking any user cleanup.
  self.disposed.val = true
  applications.free(self.address)
  self.started.val = false
  self.wake.val = fn() { () }
  self.messages.clear()
  for page in self.pages.copy() {
    (page.shared_dispose.val)()
    page.dispose()
  }
  self.pages.clear()
  self.graph.dispose()
}

///|
fn addressed_command(address : @slotmap.Id, command : Cmd) -> Cmd {
  CmdMessage(fn() {
    let deliver = fn() {
      if applications.get(address) is Some(owner) {
        owner.enqueue(command)
      }
    }
    match ambient_graph.val {
      Some(graph) if graph.transaction_active.val =>
        graph.enlist(deliver, fn() { () })
      _ => deliver()
    }
    CmdNone
  })
}

///|
fn[Msg] application_emit(address : @slotmap.Id, emit : Emit[Msg]) -> Emit[Msg] {
  Emit(message => addressed_command(address, emit.emit(message)))
}

///|
pub fn[Model : Eq, Msg] Application::create_state_with_init(
  self : Application,
  init : (Emit[Msg]) -> (Model, Cmd),
  update : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions : ((Model, Emit[Msg]) -> Sub)?,
) -> (Shared[Model], Emit[Msg]) {
  guard self.building.val &&
    ambient_graph.val is Some(graph) &&
    graph.generation == self.graph.generation else {
    abort("application state must be created in its application builder")
  }
  let address = self.address
  let (value, emit) = create_state_with_init(
    init=emit => init(application_emit(address, emit)),
    update=(model, msg, emit) => {
      update(model, msg, application_emit(address, emit))
    },
    subscriptions?=subscriptions.map(build => {
      (model, emit) => build(model, application_emit(address, emit))
    }),
  )
  ({ address, value, }, application_emit(address, emit))
}
