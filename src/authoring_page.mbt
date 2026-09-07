///|
priv struct GraphMessage(Cmd)

///|
struct PageRuntime(@renderer.PageRuntime, @val.Graph)

///|
struct PageContext {
  graph : @val.Graph
}

///|
pub(all) enum PageLifecycleHook {
  Load
  Show
  Hide
  Unload
  PullDownRefresh
  ReachBottom
} derive(Eq)

///|
fn PageLifecycleHook::host_name(self : PageLifecycleHook) -> String {
  match self {
    Load => "onLoad"
    Show => "onShow"
    Hide => "onHide"
    Unload => "onUnload"
    PullDownRefresh => "onPullDownRefresh"
    ReachBottom => "onReachBottom"
  }
}

///|
pub fn PageContext::every(
  self : PageContext,
  key~ : String,
  interval_ms~ : Int,
  command~ : Cmd,
) -> Sub {
  let _ = self
  Sub(@val.every(key, interval_ms, command.0))
}

///|
pub fn PageContext::lifecycle(
  self : PageContext,
  hook : PageLifecycleHook,
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
pub fn PageContext::on_load(self : PageContext, command : Cmd) -> Sub {
  self.lifecycle(Load, _ => Ok(command))
}

///|
pub fn PageContext::on_show(self : PageContext, command : Cmd) -> Sub {
  self.lifecycle(Show, _ => Ok(command))
}

///|
pub fn PageContext::on_hide(self : PageContext, command : Cmd) -> Sub {
  self.lifecycle(Hide, _ => Ok(command))
}

///|
pub fn PageContext::on_unload(self : PageContext, command : Cmd) -> Sub {
  self.lifecycle(Unload, _ => Ok(command))
}

///|
pub fn PageContext::on_pull_down_refresh(
  self : PageContext,
  command : Cmd,
) -> Sub {
  self.lifecycle(PullDownRefresh, _ => Ok(command))
}

///|
pub fn PageContext::on_reach_bottom(self : PageContext, command : Cmd) -> Sub {
  self.lifecycle(ReachBottom, _ => Ok(command))
}

///|
fn lifecycle_subscription_command(
  subscription : @val.Sub,
  hook : String,
  payload : Json,
) -> Result[Cmd, DecodeError] {
  match subscription {
    @val.SubNone | @val.SubEvery(_, _, _) => Ok(none)
    @val.SubBatch(subscriptions) => {
      let commands : Array[Cmd] = []
      for subscription in subscriptions {
        match lifecycle_subscription_command(subscription, hook, payload) {
          Ok(command) => commands.push(command)
          Err(error) => return Err(error)
        }
      }
      Ok(batch(commands))
    }
    @val.SubLifecycle(expected, decode) =>
      if expected == hook {
        match decode(payload) {
          Ok(command) => Ok(Cmd(command))
          Err(error) => Err(decode_error(error.message()))
        }
      } else {
        Ok(none)
      }
  }
}

///|
fn collect_intervals(
  subscription : @val.Sub,
  entries : Array[@renderer.HostSubscription[GraphMessage]],
) -> Unit {
  match subscription {
    @val.SubNone | @val.SubLifecycle(_, _) => ()
    @val.SubBatch(subscriptions) =>
      for subscription in subscriptions {
        collect_intervals(subscription, entries)
      }
    @val.SubEvery(key, interval_ms, command) =>
      entries.push(
        @renderer.every(key~, interval_ms~, msg=GraphMessage(command)),
      )
  }
}

///|
fn graph_subscriptions(
  graph : @val.Graph,
) -> @renderer.Subscriptions[GraphMessage] {
  let entries : Array[@renderer.HostSubscription[GraphMessage]] = []
  graph.run(fn() { collect_intervals(graph.current_subscriptions(), entries) })
  @renderer.subscriptions(entries)
}

///|
fn collect_runtime_commands(
  command : Cmd,
  output : Array[@runtime.Cmd[GraphMessage]],
) -> Unit {
  match command.0 {
    @val.CmdNone => ()
    @val.CmdMessage(run) => collect_runtime_commands(Cmd(run()), output)
    @val.CmdBatch(commands) =>
      for command in commands {
        collect_runtime_commands(Cmd(command), output)
      }
    @val.CmdEffect(start) =>
      output.push(
        @runtime.local_effect((emit, finish) => {
          start(command => emit(GraphMessage(Cmd(command))), finish)
        }),
      )
    @val.CmdHostEffect(capability, payload, resolve) =>
      output.push(
        @runtime.host_effect(
          @runtime.host_effect_request(capability, payload),
          outcome => {
            let converted = match outcome {
              @runtime.HostEffectOk(payload) => @val.HostOk(payload)
              @runtime.HostEffectErr(phase, message, payload) =>
                @val.HostErr(phase, message, payload)
            }
            GraphMessage(Cmd(resolve(converted)))
          },
        ),
      )
    @val.CmdNavigateTo(url) => output.push(@runtime.navigate_to_cmd(url))
    @val.CmdRedirectTo(url) => output.push(@runtime.redirect_to_cmd(url))
    @val.CmdNavigateBack(delta) =>
      output.push(@runtime.navigate_back_cmd(delta))
    @val.CmdNavigateBackOrRedirect(delta, fallback) =>
      output.push(@runtime.navigate_back_or_redirect_cmd(delta, fallback))
  }
}

///|
fn graph_command_has_runtime_work(command : @val.Cmd) -> Bool {
  match command {
    @val.CmdNone => false
    @val.CmdBatch(commands) => {
      for command in commands {
        if graph_command_has_runtime_work(command) {
          return true
        }
      }
      false
    }
    _ => true
  }
}

///|
fn graph_update(
  graph : @val.Graph,
  message : GraphMessage,
  epoch : Int,
) -> (Int, @runtime.Cmd[GraphMessage]) {
  graph.begin()
  let commands : Array[@runtime.Cmd[GraphMessage]] = []
  graph.run(fn() { collect_runtime_commands(message.0, commands) })
  let revision = graph.candidate_revision()
  if revision == epoch {
    graph.commit()
  }
  // A dynamic branch may register state init commands while projection pulls
  // the graph. Drain them only after that candidate commits, in a new update.
  commands.push(
    @runtime.local_effect((emit, finish) => {
      let pending = graph.take_initial_command()
      if graph_command_has_runtime_work(pending) {
        emit(GraphMessage(Cmd(pending)))
      }
      finish()
      fn() {  }
    }),
  )
  (revision, @runtime.cmd_batch(commands))
}

///|
fn input_fields(payload : Json) -> Result[Map[String, String], DecodeError] {
  match payload {
    Object(fields) => {
      let output : Map[String, String] = Map([])
      for name, value in fields {
        output[name] = match value {
          String(text) => text
          value => value.stringify()
        }
      }
      Ok(output)
    }
    _ => Err(decode_error("page input payload must be an object"))
  }
}

///|
struct Page {
  id : String
  route : String
  title : String
  make_program : () -> (@renderer.PageProgram[Int, GraphMessage], @val.Graph)
}

///|
pub fn Page::id(self : Page) -> String {
  self.id
}

///|
pub fn Page::route(self : Page) -> String {
  self.route
}

///|
pub fn Page::title(self : Page) -> String {
  self.title
}

///|
pub fn Page::initial_tree(self : Page) -> Json {
  let (program, graph) = (self.make_program)()
  let value = program.initial_tree()
  graph.dispose()
  value
}

///|
pub fn Page::contract(self : Page) -> String {
  let (program, graph) = (self.make_program)()
  let value = program.contract()
  graph.dispose()
  value
}

///|
pub fn Page::contract_json(self : Page) -> Json {
  let (program, graph) = (self.make_program)()
  let value = program.contract_json()
  graph.dispose()
  value
}

///|
pub fn Page::wxml(self : Page) -> String {
  let (program, graph) = (self.make_program)()
  let value = program.wxml()
  graph.dispose()
  value
}

///|
pub fn Page::create_runtime(self : Page) -> PageRuntime {
  let (program, graph) = (self.make_program)()
  let runtime = program.create_runtime()
  graph.attach_shared_runtime(capture_shared_wake(), fn() {
    ignore(runtime.dispose())
  })
  PageRuntime(runtime, graph)
}

///|
pub fn PageRuntime::page_id(self : PageRuntime) -> String {
  self.0.page_id()
}

///|
pub fn PageRuntime::mount(self : PageRuntime) -> String {
  self.0.mount()
}

///|
pub fn PageRuntime::dispatch(
  self : PageRuntime,
  event_key : String,
  payload_json : String,
) -> String {
  self.0.dispatch(event_key, payload_json)
}

///|
pub fn PageRuntime::dispatch_batch(
  self : PageRuntime,
  events_json : String,
) -> String {
  self.0.dispatch_batch(events_json)
}

///|
pub fn PageRuntime::lifecycle(
  self : PageRuntime,
  hook : String,
  payload_json : String,
) -> String {
  if hook == "onHide" {
    self.1.set_shared_visible(false)
  }
  if hook == "onShow" {
    self.1.set_shared_visible(true)
  }
  if hook == "$minimoon:shared" {
    return self.0.refresh()
  }
  self.0.lifecycle(hook, payload_json)
}

///|
pub fn PageRuntime::resolve_effect(
  self : PageRuntime,
  request_id : String,
  phase : String,
  payload_json : String,
) -> String {
  self.0.resolve_effect(request_id, phase, payload_json)
}

///|
pub fn PageRuntime::subscription(
  self : PageRuntime,
  key : String,
  payload_json : String,
) -> String {
  self.0.subscription(key, payload_json)
}

///|
pub fn PageRuntime::snapshot(self : PageRuntime) -> String {
  self.0.snapshot()
}

///|
pub fn PageRuntime::dispose(self : PageRuntime) -> String {
  self.0.dispose()
}

///|
pub fn runtime_api_version() -> Int {
  @renderer.runtime_api_version()
}

///|
fn[Input : Eq] make_page(
  id : String,
  route : Route,
  title : String,
  capabilities : Array[Capability],
  decode_input : (Map[String, String]) -> Result[Input, DecodeError],
  build : (PageContext, Val[Input]) -> Val[Node],
) -> Page {
  guard !route.has_query() else {
    abort("Page route must not contain query parameters")
  }
  let route_path = route.path()
  let initial_input = match decode_input(Map([])) {
    Ok(value) => value
    Err(error) => abort("default page input failed: " + error.message())
  }
  let make_program = fn() {
    let graph = @val.Graph::new()
    let built = graph.build(fn() {
      let input = graph.create_input(initial_input)
      let root = build({ graph, }, Val(input.0))
      (root, input.1)
    })
    let root = built.0
    let set_input = built.1
    let lifecycle_events = [
      Load,
      Show,
      Hide,
      Unload,
      PullDownRefresh,
      ReachBottom,
    ].map(hook => {
      let core_hook = @renderer.page_lifecycle_hook(hook.host_name())
      @renderer.lifecycle_event(core_hook, payload => {
        let lifecycle_message = @val.CmdMessage(fn() {
          match
            lifecycle_subscription_command(
              graph.current_subscriptions(),
              hook.host_name(),
              payload,
            ) {
            Ok(command) => command.0
            Err(_) => none.0
          }
        })
        let command = if hook == Load {
          match input_fields(payload) {
            Ok(fields) =>
              match decode_input(fields) {
                Ok(value) => batch([set_input.emit(value), lifecycle_message])
                Err(error) =>
                  return Err(@renderer.decode_error(error.message()))
              }
            Err(error) => return Err(@renderer.decode_error(error.message()))
          }
        } else if hook == Show {
          batch([
            Cmd(@val.CmdMessage(fn() { graph.refresh_shared() })),
            lifecycle_message,
          ])
        } else {
          lifecycle_message
        }
        Ok(GraphMessage(command))
      })
    })
    let program = @renderer.page_program(
      id~,
      route=route_path,
      title~,
      model=0,
      update=(epoch, message) => graph_update(graph, message, epoch),
      projection_guard=(previous, next) => previous != next,
      view=(events, _) => {
        graph.run(fn() {
          events.on_candidate_commit(fn() { graph.commit() })
          events.on_candidate_rollback(fn() { graph.rollback() })
          events.on_scope_cleanup("$minimoon:graph", fn() { graph.dispose() })
          materialize(root.0.read(), events)
        })
      },
      capabilities=capabilities.map(capability => capability.to_core()),
      lifecycle=lifecycle_events,
      init=GraphMessage(graph.take_initial_command()),
      subscriptions=_ => graph_subscriptions(graph),
      refresh=GraphMessage(
        Cmd(@val.CmdMessage(fn() { graph.refresh_shared() })),
      ),
    )
    (program, graph)
  }
  { id, route: route_path, title, make_program, }
}

///|
pub fn page(
  id~ : String,
  route~ : Route,
  title~ : String,
  capabilities? : Array[Capability] = [],
  build~ : (PageContext) -> Val[Node],
) -> Page {
  make_page(id, route, title, capabilities, _ => Ok(()), (context, _) => {
    build(context)
  })
}

///|
/// Build the common Elm-style page shape directly. The application-facing
/// `view` remains model-first, while subscriptions can use the page-owned
/// lifecycle context without an extra wrapper function.
pub fn[Model : Eq, Msg] elmish_page(
  id~ : String,
  route~ : Route,
  title~ : String,
  model~ : Model,
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  view~ : (Model, Emit[Msg]) -> Node,
  capabilities? : Array[Capability] = [],
  init? : (Emit[Msg]) -> Cmd,
  subscriptions? : (PageContext, Model, Emit[Msg]) -> Sub,
) -> Page {
  page(id~, route~, title~, capabilities~, build=context => {
    let page_subscriptions = subscriptions.map(build => {
      (current : Model, emit : Emit[Msg]) => build(context, current, emit)
    })
    let (value, emit) = create_state_with_init(
      init=emit => (model, init.map(build => build(emit)).unwrap_or(none)),
      update~,
      subscriptions?=page_subscriptions,
    )
    value.view(current => view(current, emit))
  })
}

///|
pub fn[Input : Eq] page_with_input(
  id~ : String,
  route~ : Route,
  title~ : String,
  capabilities? : Array[Capability] = [],
  decode_input~ : (Map[String, String]) -> Result[Input, DecodeError],
  build~ : (PageContext, Val[Input]) -> Val[Node],
) -> Page {
  make_page(id, route, title, capabilities, decode_input, build)
}
