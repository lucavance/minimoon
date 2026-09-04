///|
pub struct RuntimeCommandQueue {
  commands : Ref[Array[RuntimeCommand]]
  suspend_depth : Ref[Int]
  sink : (Array[RuntimeCommand]) -> Unit
}

///|
pub struct ComponentContext {
  id : ComponentId
  mounted : Ref[Bool]
  disposed : Ref[Bool]
  cleanups : Ref[Array[() -> Unit]]
  queue : RuntimeCommandQueue
}

///|
pub struct Component[Model, Msg] {
  model : Model
  update : Update[Model, Msg]
  view : CommandView[Model, Msg]
  project : CheckedStateProjector[Model]
  projection_guard : ProjectionGuard[Model]?
}

///|
pub struct RunningComponent[Model, Msg] {
  context : ComponentContext
  model : Ref[Model]
  update : Update[Model, Msg]
  view : CommandView[Model, Msg]
  project : CheckedStateProjector[Model]
  projection_guard : ProjectionGuard[Model]?
  wake_async : (Int) -> Unit
  next_local_effect_id : Ref[Int]
  pending_local_effects : Map[Int, () -> Unit]
  next_local_message_sequence : Ref[Int]
  pending_local_messages : Array[PendingLocalMessage[Msg]]
  next_effect_request_id : Ref[Int]
  pending_effects : Map[EffectRequestId, PendingHostEffect[Msg]]
}

///|
struct PendingHostEffect[Msg] {
  resolve : (HostEffectOutcome) -> Msg
}

///|
struct PendingLocalMessage[Msg] {
  sequence : Int
  message : Msg
}

///|
pub fn[Msg] none() -> Cmd[Msg] {
  CmdNone
}

///|
pub fn[Msg] message(msg : Msg) -> Cmd[Msg] {
  CmdMessage(msg)
}

///|
pub fn[Msg] cmd_batch(commands : Array[Cmd[Msg]]) -> Cmd[Msg] {
  CmdBatch(commands)
}

///|
pub fn[ChildMsg, ParentMsg] map_cmd(
  cmd : Cmd[ChildMsg],
  map : (ChildMsg) -> ParentMsg,
) -> Cmd[ParentMsg] {
  match cmd {
    CmdNone => CmdNone
    CmdMessage(msg) => CmdMessage(map(msg))
    CmdBatch(commands) =>
      CmdBatch(commands.map(command => map_cmd(command, map)))
    CmdLocalEffect(start) =>
      CmdLocalEffect((emit, finish) => {
        start(message => emit(map(message)), finish)
      })
    CmdHostEffect(request, resolve) =>
      CmdHostEffect(request, outcome => map(resolve(outcome)))
    CmdNavigateTo(url) => CmdNavigateTo(url)
    CmdRedirectTo(url) => CmdRedirectTo(url)
    CmdNavigateBack(delta) => CmdNavigateBack(delta)
    CmdNavigateBackOrRedirect(delta, fallback) =>
      CmdNavigateBackOrRedirect(delta, fallback)
  }
}

///|
/// Run a MoonBit-owned effect only after checked state projection succeeds.
pub fn[Msg] local_effect(
  start : ((Msg) -> Unit, () -> Unit) -> () -> Unit,
) -> Cmd[Msg] {
  CmdLocalEffect(start)
}

///|
pub fn host_effect_request(
  capability : EffectCapability,
  payload : HostPayload,
) -> HostEffectRequest {
  { capability, payload, }
}

///|
pub fn[Msg] host_effect(
  request : HostEffectRequest,
  resolve : (HostEffectOutcome) -> Msg,
) -> Cmd[Msg] {
  CmdHostEffect(request, resolve)
}

///|
pub fn[Msg] navigate_to_cmd(url : String) -> Cmd[Msg] {
  CmdNavigateTo(url)
}

///|
pub fn[Msg] redirect_to_cmd(url : String) -> Cmd[Msg] {
  CmdRedirectTo(url)
}

///|
pub fn[Msg] navigate_back_cmd(delta : Int) -> Cmd[Msg] {
  CmdNavigateBack(checked_navigate_back_delta(delta))
}

///|
pub fn[Msg] navigate_back_or_redirect_cmd(
  delta : Int,
  fallback : String,
) -> Cmd[Msg] {
  guard fallback != "" else {
    abort("MiniApp navigation fallback must not be empty")
  }
  CmdNavigateBackOrRedirect(checked_navigate_back_delta(delta), fallback)
}

///|
pub fn[Model, Msg] no_cmd_update(model : Model) -> (Model, Cmd[Msg]) {
  (model, CmdNone)
}

///|
pub fn[Model, Msg] no_cmd(model : Model) -> (Model, Cmd[Msg]) {
  no_cmd_update(model)
}

///|
pub fn[Model, Msg] with_cmd_update(
  cmd : Cmd[Msg],
  model : Model,
) -> (Model, Cmd[Msg]) {
  (model, cmd)
}

///|
pub fn[Model, Msg] with_cmd(model : Model, cmd : Cmd[Msg]) -> (Model, Cmd[Msg]) {
  with_cmd_update(cmd, model)
}

///|
pub fn[Model, Msg] with_cmds(
  model : Model,
  commands : Array[Cmd[Msg]],
) -> (Model, Cmd[Msg]) {
  with_cmd(model, cmd_batch(commands))
}

///|
pub fn[Model, Msg] with_navigate_to(
  model : Model,
  url : String,
) -> (Model, Cmd[Msg]) {
  with_cmd(model, navigate_to_cmd(url))
}

///|
pub fn[Model, Msg] with_redirect_to(
  model : Model,
  url : String,
) -> (Model, Cmd[Msg]) {
  with_cmd(model, redirect_to_cmd(url))
}

///|
pub fn[Model, Msg] with_navigate_back(
  model : Model,
  delta : Int,
) -> (Model, Cmd[Msg]) {
  with_cmd(model, navigate_back_cmd(delta))
}

///|
pub fn[Model, Msg] checked_component(
  model~ : Model,
  update~ : Update[Model, Msg],
  view~ : CommandView[Model, Msg],
  project~ : CheckedStateProjector[Model],
  projection_guard? : ProjectionGuard[Model],
) -> Component[Model, Msg] {
  { model, update, view, project, projection_guard, }
}

///|
pub fn[Model, Msg] Component::render(self : Component[Model, Msg]) -> @ui.Node {
  (self.view)(self.model, msg => message(msg))
}

///|
pub fn[Model, Msg] Component::with_model(
  self : Component[Model, Msg],
  model : Model,
) -> Component[Model, Msg] {
  {
    model,
    update: self.update,
    view: self.view,
    project: self.project,
    projection_guard: self.projection_guard,
  }
}

///|
pub fn[Model, Msg] Component::run_host(
  self : Component[Model, Msg],
  component_id~ : ComponentId,
  queue~ : RuntimeCommandQueue,
  wake_async? : (Int) -> Unit = _ => (),
) -> RunningComponent[Model, Msg] {
  {
    context: ComponentContext::new(component_id, queue),
    model: Ref(self.model),
    update: self.update,
    view: self.view,
    project: self.project,
    projection_guard: self.projection_guard,
    wake_async,
    next_local_effect_id: Ref(0),
    pending_local_effects: Map([]),
    next_local_message_sequence: Ref(0),
    pending_local_messages: [],
    next_effect_request_id: Ref(0),
    pending_effects: Map([]),
  }
}
