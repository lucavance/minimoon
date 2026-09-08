///|
/// A type-erased resident page instance. The application Model and Msg types
/// remain captured by these closures and never cross the MiniApp host boundary.
pub struct PageRuntime {
  page_id : String
  mount : () -> String
  dispatch : (String, String) -> String
  dispatch_batch : (String) -> String
  lifecycle : (String, String) -> String
  resolve_effect : (String, String, String) -> String
  subscription : (String, String) -> String
  snapshot : () -> String
  dispose : () -> String
  refresh : () -> String
  flush : () -> String
  has_ready_work : () -> Bool
}

///|
pub fn runtime_api_version() -> Int {
  @versions.runtime_api_version()
}

///|
#cfg(target="js")
extern "js" fn capture_runtime_wake_v12() -> (Int) -> Unit =
  #|() => typeof globalThis.__minimoonRuntimeWakeV12 === "function" ? globalThis.__minimoonRuntimeWakeV12 : (_through) => {}

///|
#cfg(not(target="js"))
fn capture_runtime_wake_v12() -> (Int) -> Unit {
  _ => ()
}

///|
pub fn PageRuntime::page_id(self : PageRuntime) -> String {
  self.page_id
}

///|
pub fn PageRuntime::mount(self : PageRuntime) -> String {
  (self.mount)()
}

///|
pub fn PageRuntime::dispatch(
  self : PageRuntime,
  event_key : String,
  payload_json : String,
) -> String {
  (self.dispatch)(event_key, payload_json)
}

///|
pub fn PageRuntime::dispatch_batch(
  self : PageRuntime,
  events_json : String,
) -> String {
  (self.dispatch_batch)(events_json)
}

///|
pub fn PageRuntime::lifecycle(
  self : PageRuntime,
  hook : String,
  payload_json : String,
) -> String {
  (self.lifecycle)(hook, payload_json)
}

///|
pub fn PageRuntime::resolve_effect(
  self : PageRuntime,
  request_id : String,
  phase : String,
  payload_json : String,
) -> String {
  (self.resolve_effect)(request_id, phase, payload_json)
}

///|
pub fn PageRuntime::subscription(
  self : PageRuntime,
  key : String,
  payload_json : String,
) -> String {
  (self.subscription)(key, payload_json)
}

///|
pub fn PageRuntime::snapshot(self : PageRuntime) -> String {
  (self.snapshot)()
}

///|
pub fn PageRuntime::dispose(self : PageRuntime) -> String {
  (self.dispose)()
}

///|
pub fn PageRuntime::flush(self : PageRuntime) -> String {
  (self.flush)()
}

///|
pub fn PageRuntime::has_ready_work(self : PageRuntime) -> Bool {
  (self.has_ready_work)()
}

///|
priv enum HostJsonResult {
  HostJsonOk(Json)
  HostJsonError(String)
}

///|
fn parse_host_json(raw : String) -> HostJsonResult {
  HostJsonOk(@json.parse(if raw.trim() == "" { "{}" } else { raw })) catch {
    error => HostJsonError("invalid JSON host payload: \{error}")
  }
}

///|
fn runtime_error_json(
  component_id : String,
  code : String,
  message : String,
) -> String {
  @runtime.runtime_commands_json([
    @runtime.runtime_error(component_id, code, message),
  ])
}

///|
fn page_lifecycle_hook_or_none(name : String) -> PageLifecycleHook? {
  match name {
    "onLoad" => Some(page_lifecycle_hook("onLoad"))
    "onShow" => Some(page_lifecycle_hook("onShow"))
    "onHide" => Some(page_lifecycle_hook("onHide"))
    "onUnload" => Some(page_lifecycle_hook("onUnload"))
    "onPullDownRefresh" => Some(page_lifecycle_hook("onPullDownRefresh"))
    "onReachBottom" => Some(page_lifecycle_hook("onReachBottom"))
    _ => None
  }
}

///|
fn[Model, Msg] decode_page_inputs(
  program : PageProgram[Model, Msg],
  payload : Json,
) -> Result[Array[Msg], MiniappDecodeError] {
  let messages : Array[Msg] = []
  match payload {
    Object(fields) =>
      for input in program.inputs {
        match fields.get(input.name) {
          Some(String(value)) =>
            match (input.decode)(value) {
              Ok(msg) => messages.push(msg)
              Err(error) => return Err(error)
            }
          Some(value) =>
            match (input.decode)(value.stringify()) {
              Ok(msg) => messages.push(msg)
              Err(error) => return Err(error)
            }
          None => ()
        }
      }
    _ => ()
  }
  Ok(messages)
}

///|
fn host_effect_error(payload : Json, fallback : String) -> String {
  match payload {
    Object(fields) =>
      match fields.get("error") {
        Some(String(error)) => error
        Some(error) => error.stringify()
        None => fallback
      }
    _ => fallback
  }
}

///|
fn host_effect_value(payload : Json, payload_json : String) -> String {
  match payload {
    Object(fields) =>
      match fields.get("value") {
        Some(String(value)) => value
        Some(value) => value.stringify()
        None => payload_json
      }
    _ => payload_json
  }
}

///|
pub fn[Model, Msg] PageProgram::wxml(self : PageProgram[Model, Msg]) -> String {
  dynamic_page_wxml(self.id)
}

///|
pub fn[Model, Msg] PageProgram::contract_json(
  self : PageProgram[Model, Msg],
) -> Json {
  let contract_version = @versions.app_contract_version()
  let runtime_version = @versions.runtime_api_version()
  let renderer_version = @versions.renderer_protocol_version()
  Json::object({
    "schemaVersion": Json::number(
      contract_version.to_double(),
      repr=contract_version.to_string(),
    ),
    "runtimeApiVersion": Json::number(
      runtime_version.to_double(),
      repr=runtime_version.to_string(),
    ),
    "rendererProtocolVersion": Json::number(
      renderer_version.to_double(),
      repr=renderer_version.to_string(),
    ),
    "id": Json::string(self.id),
    "route": Json::string(self.route),
    "title": Json::string(self.title),
    "initialTree": self.initial_tree(),
    "capabilities": Json::array(
      self.capabilities.map(capability => Json::string(capability.name())),
    ),
    "lifecycle": Json::array(
      self.lifecycle.map(event => Json::string(event.hook.host_name())),
    ),
    "inputs": Json::array(self.inputs.map(input => Json::string(input.name))),
  })
}

///|
pub fn[Model, Msg] PageProgram::contract(
  self : PageProgram[Model, Msg],
) -> String {
  self.contract_json().stringify()
}
