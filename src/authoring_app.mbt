///|
/// An optional application definition. Constructing it does not run effects.
struct App[Deps] {
  build : (AppContext) -> Deps
  capabilities : Array[Capability]
}

///|
struct AppContext(@val.Application)

///|
/// A read-only application value. Bind it to a page before composing a view.
struct Shared[T](@val.Shared[T])

///|
struct AppRuntime[Deps] {
  driver : AppDriver
  dependencies : Deps
}

///|
pub fn[Deps] App::capabilities(self : App[Deps]) -> Array[Capability] {
  self.capabilities.copy()
}

///|
pub fn[Deps] app(
  build~ : (AppContext) -> Deps,
  capabilities? : Array[Capability] = [],
) -> App[Deps] {
  for capability in capabilities {
    guard capability is (Request | Login | GetStorage | SetStorage) else {
      abort("unsupported application capability: " + capability.name())
    }
  }
  { build, capabilities: capabilities.copy(), }
}

///|
pub fn[Deps] App::create_runtime(self : App[Deps]) -> AppRuntime[Deps] {
  let owner = @val.Application::new()
  let driver = AppDriver::new(owner, self.capabilities)
  let dependencies = owner.build(() => (self.build)(AppContext(owner)))
  { driver, dependencies, }
}

///|
/// Inspect initial page contracts without launching effects or subscriptions.
pub fn[Deps, A] App::preview(self : App[Deps], inspect : (Deps) -> A) -> A {
  let runtime = self.create_runtime()
  defer ignore(runtime.dispose())
  runtime.driver.owner.with_pages(() => inspect(runtime.deps()))
}

///|
pub fn[Deps] AppRuntime::deps(self : AppRuntime[Deps]) -> Deps {
  self.dependencies
}

///|
pub fn[Deps] AppRuntime::create_page(
  self : AppRuntime[Deps],
  page : Page,
  input? : Map[String, String] = Map([]),
  layout? : PageLayout = PageLayout::unavailable(),
) -> Result[PageRuntime, DecodeError] {
  self.driver.owner.with_pages(() => page.create_runtime(input~, layout~))
}

///|
pub fn[Model : Eq, Msg] AppContext::create_state_with_init(
  self : AppContext,
  init~ : (Emit[Msg]) -> (Model, Cmd),
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Shared[Model], Emit[Msg]) {
  let (value, emit) = self.0.create_state_with_init(
    emit => {
      let (model, cmd) = init(wrap_emit(emit))
      (model, cmd.0)
    },
    (model, msg, emit) => {
      let (next, cmd) = update(model, msg, wrap_emit(emit))
      (next, cmd.0)
    },
    subscriptions.map(build => (model, emit) => build(model, wrap_emit(emit)).0),
  )
  (Shared(value), wrap_emit(emit))
}

///|
pub fn[Model : Eq, Msg] AppContext::create_state(
  self : AppContext,
  initial : Model,
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Shared[Model], Emit[Msg]) {
  self.create_state_with_init(
    init=_ => (initial, none),
    update~,
    subscriptions?,
  )
}

///|
pub fn[Model : Eq, Msg] AppContext::create_pure_state(
  self : AppContext,
  initial : Model,
  update~ : (Model, Msg) -> Model,
) -> (Shared[Model], Emit[Msg]) {
  self.create_state(initial, update=(model, msg, _) => {
    (update(model, msg), none)
  })
}

///|
pub fn[T : Eq] PageContext::bind(
  self : PageContext,
  shared : Shared[T],
) -> Val[T] {
  self.select(shared, value => value)
}

///|
pub fn[T : Eq, U : Eq] PageContext::select(
  self : PageContext,
  shared : Shared[T],
  select : (T) -> U,
) -> Val[U] {
  Val(self.graph.select_shared(shared.0, select))
}

///|
pub(all) enum AppLifecycleHook {
  Launch
  Show
  Hide
} derive(Eq)

///|
fn AppLifecycleHook::host_name(self : AppLifecycleHook) -> String {
  match self {
    Launch => "onLaunch"
    Show => "onShow"
    Hide => "onHide"
  }
}

///|
pub fn AppContext::lifecycle(
  self : AppContext,
  hook : AppLifecycleHook,
  decode : (Json) -> Result[Cmd, DecodeError],
) -> Sub {
  let _ = self
  Sub(
    @val.lifecycle(hook.host_name(), payload => {
      match decode(payload) {
        Ok(command) => Ok(command.0)
        Err(error) => Err(@val.decode_error(error.message()))
      }
    }),
  )
}

///|
pub fn AppContext::on_launch(self : AppContext, command : Cmd) -> Sub {
  self.lifecycle(Launch, _ => Ok(command))
}

///|
pub fn AppContext::on_show(self : AppContext, command : Cmd) -> Sub {
  self.lifecycle(Show, _ => Ok(command))
}

///|
pub fn AppContext::on_hide(self : AppContext, command : Cmd) -> Sub {
  self.lifecycle(Hide, _ => Ok(command))
}

///|
pub fn AppContext::every(
  self : AppContext,
  key~ : String,
  interval_ms~ : Int,
  command~ : Cmd,
) -> Sub {
  let _ = self
  Sub(@val.every(key, interval_ms, command.0))
}
