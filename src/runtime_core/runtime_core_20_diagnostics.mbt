///|
pub fn RuntimeCommand::describe(self : RuntimeCommand) -> String {
  match self {
    ReplaceViewTree(component_id, base_revision, revision, payload) =>
      "ReplaceViewTree(" +
      component_id +
      ", " +
      base_revision.to_string() +
      "->" +
      revision.to_string() +
      ", " +
      payload +
      ")"
    PatchViewTree(component_id, base_revision, revision, writes) =>
      "PatchViewTree(" +
      component_id +
      ", " +
      base_revision.to_string() +
      "->" +
      revision.to_string() +
      ", " +
      writes +
      ")"
    RuntimeError(component_id, code, message) =>
      "RuntimeError(" + component_id + ", " + code + ", " + message + ")"
    InvokeCapability(component_id, request_id, capability, _) =>
      "InvokeCapability(" +
      component_id +
      ", " +
      request_id +
      ", " +
      capability +
      ")"
    NavigateTo(url) => "NavigateTo(" + url + ")"
    RedirectTo(url) => "RedirectTo(" + url + ")"
    SwitchTab(url) => "SwitchTab(" + url + ")"
    NavigateBack(delta) => "NavigateBack(" + delta.to_string() + ")"
    NavigateBackOrRedirect(delta, fallback) =>
      "NavigateBackOrRedirect(" + delta.to_string() + ", " + fallback + ")"
    StartSubscription(component_id, key, interval_ms) =>
      "StartSubscription(" +
      component_id +
      ", " +
      key +
      ", " +
      interval_ms.to_string() +
      ")"
    StopSubscription(component_id, key) =>
      "StopSubscription(" + component_id + ", " + key + ")"
    CancelEffect(component_id, request_id) =>
      "CancelEffect(" + component_id + ", " + request_id + ")"
    EmitHostEvent(component_id, event_key, payload) =>
      "EmitHostEvent(" + component_id + ", " + event_key + ", " + payload + ")"
    MountContext(component_id) => "MountContext(" + component_id + ")"
    DisposeContext(component_id) => "DisposeContext(" + component_id + ")"
  }
}

///|
pub fn RuntimeCommandBatchDiagnostics::describe(
  self : RuntimeCommandBatchDiagnostics,
) -> String {
  let base = "commands=" +
    self.command_count.to_string() +
    ", state_updates=" +
    self.state_update_count.to_string() +
    ", effects=" +
    self.effect_count.to_string() +
    ", events=" +
    self.event_count.to_string() +
    ", lifecycle=" +
    self.lifecycle_count.to_string() +
    ", payload_size=" +
    self.payload_size.to_string() +
    ", breakdown=" +
    self.breakdown +
    ", " +
    self.description
  if self.warning == "" {
    base
  } else {
    base + ", warning=" + self.warning
  }
}

///|
fn describe_runtime_commands(commands : Array[RuntimeCommand]) -> String {
  let mut result = "["
  for i in 0..<commands.length() {
    if i > 0 {
      result = result + ", "
    }
    result = result + commands[i].describe()
  }
  result + "]"
}

///|
fn describe_runtime_command_breakdown(
  commands : Array[RuntimeCommand],
) -> String {
  let mut result = "["
  for i in 0..<commands.length() {
    if i > 0 {
      result = result + ", "
    }
    result = result + describe_runtime_command_target(commands[i])
  }
  result + "]"
}

///|
fn describe_runtime_command_target(command : RuntimeCommand) -> String {
  match command {
    ReplaceViewTree(component_id, _, _, payload) =>
      "state:" + component_id + "#" + payload.length().to_string()
    PatchViewTree(component_id, _, _, writes) =>
      "patch:" + component_id + "#" + writes.length().to_string()
    RuntimeError(component_id, code, message) =>
      "error:" + component_id + "/" + code + "#" + message.length().to_string()
    InvokeCapability(component_id, request_id, capability, payload) =>
      "effect:" +
      component_id +
      "/" +
      request_id +
      "/" +
      capability +
      "#" +
      payload.length().to_string()
    NavigateTo(url) => "navigate_to#" + url.length().to_string()
    RedirectTo(url) => "redirect_to#" + url.length().to_string()
    SwitchTab(url) => "switch_tab#" + url.length().to_string()
    NavigateBack(delta) =>
      "navigate_back#" + delta.to_string().length().to_string()
    NavigateBackOrRedirect(delta, fallback) =>
      "navigate_back_or#" + delta.to_string() + "/" + fallback
    StartSubscription(component_id, key, interval_ms) =>
      "subscription_start:" +
      component_id +
      "/" +
      key +
      "#" +
      interval_ms.to_string()
    StopSubscription(component_id, key) =>
      "subscription_stop:" + component_id + "/" + key
    CancelEffect(component_id, request_id) =>
      "effect_cancel:" + component_id + "/" + request_id
    EmitHostEvent(component_id, event_key, payload) =>
      "event:" +
      component_id +
      "/" +
      event_key +
      "#" +
      payload.length().to_string()
    MountContext(component_id) => "mount:" + component_id
    DisposeContext(component_id) => "dispose:" + component_id
  }
}

///|
fn runtime_command_payload_warning(payload_size : Int) -> String {
  if payload_size >= 1024 * 1024 {
    "RuntimeCommand payload is at least 1MiB; split component state or use keyed operations"
  } else if payload_size >= 256 * 1024 {
    "RuntimeCommand payload is at least 256KiB; consider keyed operations"
  } else {
    ""
  }
}
