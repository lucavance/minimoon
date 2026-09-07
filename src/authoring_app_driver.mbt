///|
priv struct AppDriver {
  owner : @val.Application
  running : @runtime.RunningComponent[Int, GraphMessage]
  output : Ref[Array[@runtime.RuntimeCommand]]
  launched : Ref[Bool]
  visible : Ref[Bool]
  intervals : Map[String, Int]
  subscription_messages : Map[String, Cmd]
  through : Ref[Int]
}

///|
#cfg(target="js")
extern "js" fn capture_app_wake() -> () -> Unit =
  #|() => typeof globalThis.__minimoonAppWakeV11 === "function" ? globalThis.__minimoonAppWakeV11 : () => {}

///|
#cfg(not(target="js"))
fn capture_app_wake() -> () -> Unit {
  fn() { () }
}

///|
fn AppDriver::new(
  owner : @val.Application,
  capabilities : Array[Capability],
) -> AppDriver {
  let output = Ref([])
  let through = Ref(0)
  let wake = capture_app_wake()
  owner.set_wake(wake)
  let queue = @runtime.RuntimeCommandQueue::new(commands => {
    for command in commands {
      output.val.push(command)
    }
  })
  let component = @runtime.checked_component(
    model=0,
    update=(epoch, message : GraphMessage) => {
      let graph = owner.graph()
      graph.begin()
      let commands : Array[@runtime.Cmd[GraphMessage]] = []
      graph.run(fn() {
        collect_app_commands(message.0.0, capabilities, output, commands)
      })
      graph.commit()
      owner.publish()
      (epoch + 1, @runtime.cmd_batch(commands))
    },
    view=(_, _) => @ui.text(""),
    project=_ => Ok("{}"),
    projection_guard=(_, _) => false,
  )
  let running = component.run_host(component_id="$app", queue~, wake_async=sequence => {
    through.val = sequence
    wake()
  })
  {
    owner,
    running,
    output,
    launched: Ref(false),
    visible: Ref(false),
    intervals: Map([]),
    subscription_messages: Map([]),
    through,
  }
}

///|
fn collect_app_commands(
  command : @val.Cmd,
  capabilities : Array[Capability],
  output : Ref[Array[@runtime.RuntimeCommand]],
  commands : Array[@runtime.Cmd[GraphMessage]],
) -> Unit {
  match command {
    @val.CmdNone => ()
    @val.CmdMessage(run) =>
      collect_app_commands(run(), capabilities, output, commands)
    @val.CmdBatch(batch) =>
      for command in batch {
        collect_app_commands(command, capabilities, output, commands)
      }
    @val.CmdHostEffect(capability, _, resolve) if capability !=
      "minimoon.timeout" &&
      !capabilities.any(allowed => allowed.name() == capability) =>
      collect_app_commands(
        resolve(
          @val.HostErr(
            "failure", "undeclared or unsupported application capability", "{}",
          ),
        ),
        capabilities,
        output,
        commands,
      )
    @val.CmdNavigateTo(_)
    | @val.CmdRedirectTo(_)
    | @val.CmdNavigateBack(_)
    | @val.CmdNavigateBackOrRedirect(_, _) =>
      output.val.push(
        @runtime.runtime_error(
          "$app", "invalid_app_command", "navigation requires a page owner",
        ),
      )
    _ => collect_runtime_commands(Cmd(command), commands)
  }
}

///|
fn AppDriver::drain(self : AppDriver) -> Unit {
  guard self.launched.val && !self.owner.is_disposed() else { return }
  let _ = self.running.drain_local_messages(through=self.through.val)
  for _index = 0; _index < 2048; _index = _index + 1 {
    match self.owner.next() {
      Some(command) => {
        let _ = self.running.dispatch(GraphMessage(Cmd(command)))
      }
      None => break
    }
  }
  self.sync_intervals()
  if self.owner.pending_count() > 0 {
    (self.owner.wake.val)()
  }
}

///|
fn AppDriver::take_commands(self : AppDriver) -> String {
  let commands = self.output.val
  self.output.val = []
  @runtime.runtime_commands_json(commands)
}

///|
fn AppDriver::sync_intervals(self : AppDriver) -> Unit {
  let next : Map[String, (Int, Cmd)] = Map([])
  if self.visible.val && !self.owner.is_disposed() {
    let graph = self.owner.graph()
    graph.run(fn() {
      fn collect(sub : @val.Sub) {
        match sub {
          @val.SubBatch(subs) =>
            for sub in subs {
              collect(sub)
            }
          @val.SubEvery(key, interval, cmd) => {
            guard !next.contains(key) else {
              abort("duplicate application subscription key: " + key)
            }
            next[key] = (interval, Cmd(cmd))
          }
          _ => ()
        }
      }
      collect(graph.current_subscriptions())
    })
  }
  for key in self.intervals.keys().to_array() {
    if next.get(key).map(entry => entry.0) != self.intervals.get(key) {
      self.output.val.push(@runtime.stop_subscription_command("$app", key))
      self.intervals.remove(key)
      self.subscription_messages.remove(key)
    }
  }
  for key, entry in next {
    if !self.intervals.contains(key) {
      self.output.val.push(
        @runtime.start_subscription_command("$app", key, entry.0),
      )
      self.intervals[key] = entry.0
    }
    self.subscription_messages[key] = entry.1
  }
}

///|
pub fn[Deps] AppRuntime::flush(self : AppRuntime[Deps]) -> String {
  self.driver.drain()
  self.driver.take_commands()
}

///|
pub fn[Deps] AppRuntime::dispatch(
  self : AppRuntime[Deps],
  command : Cmd,
) -> String {
  self.driver.owner.enqueue(command.0)
  self.flush()
}

///|
pub fn[Deps] AppRuntime::lifecycle(
  self : AppRuntime[Deps],
  hook : String,
  payload_json : String,
) -> String {
  let driver = self.driver
  guard !driver.owner.is_disposed() else { return "[]" }
  let payload = @json.parse(payload_json) catch {
    _ =>
      return @runtime.runtime_commands_json([
        @runtime.runtime_error(
          "$app", "invalid_app_lifecycle", "invalid lifecycle JSON",
        ),
      ])
  }
  guard hook == "onLaunch" || hook == "onShow" || hook == "onHide" else {
    return @runtime.runtime_commands_json([
      @runtime.runtime_error(
        "$app", "invalid_app_lifecycle", "unknown application lifecycle",
      ),
    ])
  }
  if hook == "onLaunch" {
    guard !driver.launched.val else { return "[]" }
    driver.launched.val = true
    driver.owner.start()
    driver.drain()
  } else {
    guard driver.launched.val else { return "[]" }
    driver.visible.val = hook == "onShow"
  }
  let graph = driver.owner.graph()
  let command = graph.run(fn() {
    lifecycle_subscription_command(graph.current_subscriptions(), hook, payload)
  })
  match command {
    Ok(command) => driver.owner.enqueue(command.0)
    Err(error) =>
      driver.output.val.push(
        @runtime.runtime_error(
          "$app",
          "lifecycle_decode_failed",
          error.message(),
        ),
      )
  }
  self.flush()
}

///|
pub fn[Deps] AppRuntime::resolve_effect(
  self : AppRuntime[Deps],
  request_id : String,
  phase : String,
  payload_json : String,
) -> String {
  guard !self.driver.owner.is_disposed() && phase != "pending" else {
    return "[]"
  }
  let payload = @json.parse(payload_json) catch {
    _ =>
      return @runtime.runtime_commands_json([
        @runtime.runtime_error(
          "$app", "invalid_host_payload", "invalid effect JSON",
        ),
      ])
  }
  let outcome = if phase == "success" {
    @runtime.HostEffectOk(payload_json)
  } else {
    let message = match payload {
      Object(fields) =>
        match fields.get("error") {
          Some(String(message)) => message
          _ => "application host effect failed"
        }
      _ => "application host effect failed"
    }
    @runtime.HostEffectErr(phase, message, payload_json)
  }
  let _ = self.driver.running.resolve_host_effect(request_id, outcome)
  self.flush()
}

///|
pub fn[Deps] AppRuntime::subscription(
  self : AppRuntime[Deps],
  key : String,
) -> String {
  if self.driver.visible.val &&
    self.driver.subscription_messages.get(key) is Some(command) {
    self.driver.owner.enqueue(command.0)
  }
  self.flush()
}

///|
pub fn[Deps] AppRuntime::dispose(self : AppRuntime[Deps]) -> String {
  guard !self.driver.owner.is_disposed() else { return "[]" }
  self.driver.visible.val = false
  self.driver.sync_intervals()
  self.driver.owner.dispose()
  let _ = self.driver.running.dispose()
  self.driver.take_commands()
}
