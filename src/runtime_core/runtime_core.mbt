///|
pub type PureUpdate[Model, Msg] = (Model, Msg) -> Model

///|
pub type Update[Model, Msg] = (Model, Msg) -> (Model, Cmd[Msg])

///|
pub type Emit[Msg] = (Msg) -> Cmd[Msg]

///|
pub type CommandView[Model, Msg] = (Model, Emit[Msg]) -> @ui.Node

///|
pub type ComponentId = String

///|
pub type EventKey = String

///|
pub type HostPayload = String

///|
pub type CheckedStateProjector[Model] = (Model) -> Result[HostPayload, String]

///|
pub type ProjectionGuard[Model] = (Model, Model) -> Bool

///|
pub type SubscriptionKey = String

///|
pub type EffectRequestId = String

///|
pub type EffectCapability = String

///|
pub struct HostEffectRequest {
  capability : EffectCapability
  payload : HostPayload
}

///|
pub(all) enum HostEffectOutcome {
  HostEffectOk(HostPayload)
  HostEffectErr(String, String, HostPayload)
} derive(Debug, Eq)

///|
pub(all) enum EffectResolveResult {
  EffectResolved
  EffectUnknownRequest
  EffectAlreadyResolved
  EffectContextDisposed
} derive(Debug, Eq)

///|
pub enum Cmd[Msg] {
  CmdNone
  CmdMessage(Msg)
  CmdBatch(Array[Cmd[Msg]])
  CmdLocalEffect(((Msg) -> Unit, () -> Unit) -> () -> Unit)
  CmdHostEffect(HostEffectRequest, (HostEffectOutcome) -> Msg)
  CmdNavigateTo(String)
  CmdRedirectTo(String)
  CmdSwitchTab(String)
  CmdNavigateBack(Int)
  CmdNavigateBackOrRedirect(Int, String)
}

///|
pub enum RuntimeCommand {
  ReplaceViewTree(ComponentId, Int, Int, HostPayload)
  PatchViewTree(ComponentId, Int, Int, HostPayload)
  RuntimeError(ComponentId, String, String)
  InvokeCapability(ComponentId, EffectRequestId, EffectCapability, HostPayload)
  NavigateTo(String)
  RedirectTo(String)
  SwitchTab(String)
  NavigateBack(Int)
  NavigateBackOrRedirect(Int, String)
  StartSubscription(ComponentId, SubscriptionKey, Int)
  StopSubscription(ComponentId, SubscriptionKey)
  CancelEffect(ComponentId, EffectRequestId)
  EmitHostEvent(ComponentId, EventKey, HostPayload)
  MountContext(ComponentId)
  DisposeContext(ComponentId)
}

///|
pub struct RuntimeCommandBatchDiagnostics {
  command_count : Int
  state_update_count : Int
  effect_count : Int
  event_count : Int
  lifecycle_count : Int
  payload_size : Int
  warning : String
  breakdown : String
  description : String
}

///|
pub enum ContextWriteResult {
  ContextWriteOk
  ContextDisposed
}

///|
pub enum ComponentLifecycleState {
  ComponentCreated
  ComponentMounted
  ComponentDisposed
}

///|
pub fn replace_view_tree(
  component_id : ComponentId,
  tree : HostPayload,
  base_revision? : Int = 0,
  revision? : Int = 1,
) -> RuntimeCommand {
  guard base_revision >= 0 && revision == base_revision + 1 else {
    abort("invalid renderer revision transition")
  }
  ReplaceViewTree(component_id, base_revision, revision, tree)
}

///|
pub fn patch_view_tree(
  component_id : ComponentId,
  ops : HostPayload,
  base_revision? : Int = 0,
  revision? : Int = 1,
) -> RuntimeCommand {
  guard base_revision >= 0 && revision == base_revision + 1 else {
    abort("invalid renderer revision transition")
  }
  PatchViewTree(component_id, base_revision, revision, ops)
}

///|
pub fn runtime_error(
  component_id : ComponentId,
  code : String,
  message : String,
) -> RuntimeCommand {
  RuntimeError(component_id, code, message)
}

///|
pub fn navigate_to_command(url : String) -> RuntimeCommand {
  NavigateTo(url)
}

///|
pub fn redirect_to_command(url : String) -> RuntimeCommand {
  RedirectTo(url)
}

///|
pub fn switch_tab_command(url : String) -> RuntimeCommand {
  SwitchTab(url)
}

///|
fn valid_navigate_back_delta(delta : Int) -> Bool {
  delta >= 1
}

///|
fn checked_navigate_back_delta(delta : Int) -> Int {
  guard valid_navigate_back_delta(delta) else {
    abort("MiniApp navigateBack delta must be at least 1")
  }
  delta
}

///|
pub fn navigate_back_command(delta : Int) -> RuntimeCommand {
  NavigateBack(checked_navigate_back_delta(delta))
}

///|
pub fn navigate_back_or_redirect_command(
  delta : Int,
  fallback : String,
) -> RuntimeCommand {
  guard fallback != "" else {
    abort("MiniApp navigation fallback must not be empty")
  }
  NavigateBackOrRedirect(checked_navigate_back_delta(delta), fallback)
}

///|
pub fn start_subscription_command(
  component_id : ComponentId,
  key : SubscriptionKey,
  interval_ms : Int,
) -> RuntimeCommand {
  guard key != "" && interval_ms > 0 else { abort("invalid host subscription") }
  StartSubscription(component_id, key, interval_ms)
}

///|
pub fn stop_subscription_command(
  component_id : ComponentId,
  key : SubscriptionKey,
) -> RuntimeCommand {
  StopSubscription(component_id, key)
}

///|
pub fn emit_host_event(
  component_id : ComponentId,
  event_key : EventKey,
  payload : HostPayload,
) -> RuntimeCommand {
  EmitHostEvent(component_id, event_key, payload)
}

///|
pub fn mount_context(component_id : ComponentId) -> RuntimeCommand {
  MountContext(component_id)
}

///|
pub fn dispose_context(component_id : ComponentId) -> RuntimeCommand {
  DisposeContext(component_id)
}

///|
pub fn runtime_command_diagnostics(
  commands : Array[RuntimeCommand],
) -> RuntimeCommandBatchDiagnostics {
  let state_update_count : Ref[Int] = Ref(0)
  let effect_count : Ref[Int] = Ref(0)
  let event_count : Ref[Int] = Ref(0)
  let lifecycle_count : Ref[Int] = Ref(0)
  let payload_size : Ref[Int] = Ref(0)
  for command in commands {
    match command {
      ReplaceViewTree(_, _, _, payload) => {
        state_update_count.val = state_update_count.val + 1
        payload_size.val = payload_size.val + payload.length()
      }
      PatchViewTree(_, _, _, writes) => {
        state_update_count.val = state_update_count.val + 1
        payload_size.val = payload_size.val + writes.length()
      }
      RuntimeError(_, code, message) =>
        payload_size.val = payload_size.val + code.length() + message.length()
      InvokeCapability(_, _, capability, payload) => {
        effect_count.val = effect_count.val + 1
        payload_size.val = payload_size.val +
          capability.length() +
          payload.length()
      }
      NavigateTo(url) | RedirectTo(url) | SwitchTab(url) =>
        payload_size.val = payload_size.val + url.length()
      NavigateBack(delta) =>
        payload_size.val = payload_size.val + delta.to_string().length()
      NavigateBackOrRedirect(delta, fallback) =>
        payload_size.val = payload_size.val +
          delta.to_string().length() +
          fallback.length()
      StartSubscription(_, key, interval_ms) => {
        lifecycle_count.val = lifecycle_count.val + 1
        payload_size.val = payload_size.val +
          key.length() +
          interval_ms.to_string().length()
      }
      StopSubscription(_, key) | CancelEffect(_, key) => {
        lifecycle_count.val = lifecycle_count.val + 1
        payload_size.val = payload_size.val + key.length()
      }
      EmitHostEvent(_, _, payload) => {
        event_count.val = event_count.val + 1
        payload_size.val = payload_size.val + payload.length()
      }
      MountContext(_) | DisposeContext(_) =>
        lifecycle_count.val = lifecycle_count.val + 1
    }
  }
  {
    command_count: commands.length(),
    state_update_count: state_update_count.val,
    effect_count: effect_count.val,
    event_count: event_count.val,
    lifecycle_count: lifecycle_count.val,
    payload_size: payload_size.val,
    warning: runtime_command_payload_warning(payload_size.val),
    breakdown: describe_runtime_command_breakdown(commands),
    description: describe_runtime_commands(commands),
  }
}

///|
pub fn RuntimeCommand::schema_json(self : RuntimeCommand) -> String {
  match self {
    ReplaceViewTree(component_id, base_revision, revision, payload) =>
      "{\"type\":\"ReplaceViewTree\",\"component_id\":" +
      component_id.escape() +
      ",\"base_revision\":" +
      base_revision.to_string() +
      ",\"revision\":" +
      revision.to_string() +
      ",\"tree\":" +
      payload +
      "}"
    PatchViewTree(component_id, base_revision, revision, ops) =>
      "{\"type\":\"PatchViewTree\",\"component_id\":" +
      component_id.escape() +
      ",\"base_revision\":" +
      base_revision.to_string() +
      ",\"revision\":" +
      revision.to_string() +
      ",\"ops\":" +
      ops +
      "}"
    RuntimeError(component_id, code, message) =>
      "{\"type\":\"RuntimeError\",\"component_id\":" +
      component_id.escape() +
      ",\"code\":" +
      code.escape() +
      ",\"message\":" +
      message.escape() +
      "}"
    InvokeCapability(component_id, request_id, capability, payload) =>
      "{\"type\":\"InvokeCapability\",\"component_id\":" +
      component_id.escape() +
      ",\"request_id\":" +
      request_id.escape() +
      ",\"capability\":" +
      capability.escape() +
      ",\"payload\":" +
      payload +
      "}"
    NavigateTo(url) => "{\"type\":\"NavigateTo\",\"url\":" + url.escape() + "}"
    RedirectTo(url) => "{\"type\":\"RedirectTo\",\"url\":" + url.escape() + "}"
    SwitchTab(url) => "{\"type\":\"SwitchTab\",\"url\":" + url.escape() + "}"
    NavigateBack(delta) =>
      "{\"type\":\"NavigateBack\",\"delta\":" + delta.to_string() + "}"
    NavigateBackOrRedirect(delta, fallback) =>
      "{\"type\":\"NavigateBackOrRedirect\",\"delta\":" +
      delta.to_string() +
      ",\"fallback\":" +
      fallback.escape() +
      "}"
    StartSubscription(component_id, key, interval_ms) =>
      "{\"type\":\"StartSubscription\",\"component_id\":" +
      component_id.escape() +
      ",\"key\":" +
      key.escape() +
      ",\"interval_ms\":" +
      interval_ms.to_string() +
      "}"
    StopSubscription(component_id, key) =>
      "{\"type\":\"StopSubscription\",\"component_id\":" +
      component_id.escape() +
      ",\"key\":" +
      key.escape() +
      "}"
    CancelEffect(component_id, request_id) =>
      "{\"type\":\"CancelEffect\",\"component_id\":" +
      component_id.escape() +
      ",\"request_id\":" +
      request_id.escape() +
      "}"
    EmitHostEvent(component_id, event_key, payload) =>
      "{\"type\":\"EmitHostEvent\",\"component_id\":" +
      component_id.escape() +
      ",\"event_key\":" +
      event_key.escape() +
      ",\"payload\":" +
      payload +
      "}"
    MountContext(component_id) =>
      "{\"type\":\"MountContext\",\"component_id\":" +
      component_id.escape() +
      "}"
    DisposeContext(component_id) =>
      "{\"type\":\"DisposeContext\",\"component_id\":" +
      component_id.escape() +
      "}"
  }
}

///|
/// Return the exact encoded byte length without allocating the complete
/// command JSON. Tree selection uses this to avoid building a rejected
/// replacement wrapper.
pub fn RuntimeCommand::schema_json_size(self : RuntimeCommand) -> Int {
  match self {
    ReplaceViewTree(component_id, base_revision, revision, payload) =>
      "{\"type\":\"ReplaceViewTree\",\"component_id\":".length() +
      component_id.escape().length() +
      ",\"base_revision\":".length() +
      base_revision.to_string().length() +
      ",\"revision\":".length() +
      revision.to_string().length() +
      ",\"tree\":".length() +
      payload.length() +
      1
    PatchViewTree(component_id, base_revision, revision, ops) =>
      "{\"type\":\"PatchViewTree\",\"component_id\":".length() +
      component_id.escape().length() +
      ",\"base_revision\":".length() +
      base_revision.to_string().length() +
      ",\"revision\":".length() +
      revision.to_string().length() +
      ",\"ops\":".length() +
      ops.length() +
      1
    _ => self.schema_json().length()
  }
}

///|
pub fn runtime_commands_json(commands : Array[RuntimeCommand]) -> String {
  "[" + commands.map(command => command.schema_json()).join(",") + "]"
}

///|
pub fn ContextWriteResult::is_ok(self : ContextWriteResult) -> Bool {
  match self {
    ContextWriteOk => true
    ContextDisposed => false
  }
}

///|
pub fn ContextWriteResult::is_disposed(self : ContextWriteResult) -> Bool {
  match self {
    ContextDisposed => true
    ContextWriteOk => false
  }
}
