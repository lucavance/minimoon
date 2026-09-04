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
}

///|
pub fn runtime_api_version() -> Int {
  @versions.runtime_api_version()
}

///|
#cfg(target="js")
extern "js" fn capture_runtime_wake_v10() -> (Int) -> Unit =
  #|() => typeof globalThis.__minimoonRuntimeWakeV10 === "function" ? globalThis.__minimoonRuntimeWakeV10 : (_through) => {}

///|
#cfg(not(target="js"))
fn capture_runtime_wake_v10() -> (Int) -> Unit {
  _ => ()
}

///|
pub fn[Model, Msg] PageProgram::create_runtime(
  self : PageProgram[Model, Msg],
) -> PageRuntime {
  let commands : Ref[Array[@runtime.RuntimeCommand]] = Ref([])
  let initial_tree = self.initial_tree()
  let host_tree : Ref[String] = Ref(initial_tree.stringify())
  let host_tree_json : Ref[Json] = Ref(initial_tree)
  let host_revision = Ref(0)
  let queue = @runtime.RuntimeCommandQueue::new(batch => {
    for command in batch {
      commands.val.push(command)
    }
  })
  let wake_async = capture_runtime_wake_v10()
  let running = self.component.run_host(
    component_id=self.id,
    queue~,
    wake_async~,
  )
  let mounted = Ref(false)
  let active_subscription_intervals : Map[String, Int] = Map([])
  let subscription_messages : Map[String, Msg] = Map([])
  let sync_subscriptions = fn() {
    if !mounted.val {
      return
    }
    let next = self.active_subscriptions.val
    let next_intervals : Map[String, Int] = Map([])
    for entry in next {
      next_intervals[entry.key] = entry.interval_ms
    }
    let previous_keys = active_subscription_intervals.keys().to_array()
    for key in previous_keys {
      let keep = next_intervals.get(key) ==
        active_subscription_intervals.get(key)
      if !keep {
        commands.val.push(@runtime.stop_subscription_command(self.id, key))
        active_subscription_intervals.remove(key)
        subscription_messages.remove(key)
      }
    }
    for entry in next {
      if !active_subscription_intervals.contains(entry.key) {
        commands.val.push(
          @runtime.start_subscription_command(
            self.id,
            entry.key,
            entry.interval_ms,
          ),
        )
        active_subscription_intervals[entry.key] = entry.interval_ms
      }
      subscription_messages[entry.key] = entry.msg
    }
  }
  let take_commands = fn() {
    let output = commands.val
    commands.val = []
    let tree_requested = Ref(false)
    let rest : Array[@runtime.RuntimeCommand] = []
    for command in output {
      match command {
        @runtime.ReplaceViewTree(component_id, _, _, _) if component_id ==
          self.id => tree_requested.val = true
        _ => rest.push(command)
      }
    }
    let batch : Array[@runtime.RuntimeCommand] = []
    if tree_requested.val {
      let next_tree = self.active_tree.val
      match diff_miniapp_trees(host_tree_json.val, next_tree) {
        TreeDiffOk(ops) if ops.length() > 0 => {
          let payload = next_tree.stringify()
          let next_revision = host_revision.val + 1
          let replace = @runtime.replace_view_tree(
            self.id,
            payload,
            base_revision=host_revision.val,
            revision=next_revision,
          )
          let patch = @runtime.patch_view_tree(
            self.id,
            tree_patch_ops_json(ops),
            base_revision=host_revision.val,
            revision=next_revision,
          )
          if should_use_tree_patch(
              patch.schema_json_size(),
              replace.schema_json_size(),
              tree_patch_host_write_cost(ops),
            ) {
            batch.push(patch)
          } else {
            batch.push(replace)
          }
          host_tree.val = payload
          host_tree_json.val = next_tree
          host_revision.val = next_revision
        }
        TreeDiffUnsafe => {
          let payload = next_tree.stringify()
          let next_revision = host_revision.val + 1
          batch.push(
            @runtime.replace_view_tree(
              self.id,
              payload,
              base_revision=host_revision.val,
              revision=next_revision,
            ),
          )
          host_tree.val = payload
          host_tree_json.val = next_tree
          host_revision.val = next_revision
        }
        TreeDiffOk(_) => host_tree_json.val = next_tree
      }
    }
    for command in rest {
      batch.push(command)
    }
    @runtime.runtime_commands_json(batch)
  }
  {
    page_id: self.id,
    mount: fn() {
      match self.init {
        Some(message) => {
          let _ = running.dispatch(message)
        }
        None => ()
      }
      let _ = running.mount()
      mounted.val = true
      sync_subscriptions()
      take_commands()
    },
    dispatch: fn(event_key, payload_json) {
      // The generic WXML template may observe a bubbled host tap on a node
      // without a Minimoon event. Empty keys are structural no-ops; non-empty
      // unknown keys remain protocol errors.
      if event_key == "" {
        return "[]"
      }
      match parse_host_json(payload_json) {
        HostJsonError(error) =>
          runtime_error_json(self.id, "invalid_host_payload", error)
        HostJsonOk(payload) =>
          match self.decode_event(event_key, payload) {
            Ok(Some(msg)) => {
              let _ = running.dispatch(msg)
              sync_subscriptions()
              take_commands()
            }
            Ok(None) =>
              runtime_error_json(
                self.id,
                "unknown_event",
                "unknown page event: " + event_key,
              )
            Err(error) =>
              runtime_error_json(
                self.id,
                "event_decode_failed",
                error.message(),
              )
          }
      }
    },
    dispatch_batch: fn(events_json) {
      match parse_host_json(events_json) {
        HostJsonError(error) =>
          runtime_error_json(self.id, "invalid_event_batch", error)
        HostJsonOk(value) => {
          let entries = match value {
            Array(entries) => entries
            _ =>
              return runtime_error_json(
                self.id,
                "invalid_event_batch",
                "event batch must be a JSON array",
              )
          }
          if entries.length() > 2048 {
            return runtime_error_json(
              self.id,
              "event_batch_too_large",
              "event batch exceeds the 2048 entry limit",
            )
          }
          // Decode the complete batch before dispatching any message. A bad
          // entry therefore cannot leave application state partially updated.
          let messages : Array[Msg] = []
          for index = 0; index < entries.length(); index = index + 1 {
            let fields = match entries[index] {
              Object(fields) => fields
              _ =>
                return runtime_error_json(
                  self.id,
                  "invalid_event_batch",
                  "event batch entry " +
                  index.to_string() +
                  " must be an object",
                )
            }
            let event_key = match fields.get("key") {
              Some(String(key)) => key
              _ =>
                return runtime_error_json(
                  self.id,
                  "invalid_event_batch",
                  "event batch entry " +
                  index.to_string() +
                  " has no string key",
                )
            }
            let payload = fields.get("payload").unwrap_or(Json::empty_object())
            if event_key != "" {
              match self.decode_event(event_key, payload) {
                Ok(Some(msg)) => messages.push(msg)
                Ok(None) =>
                  return runtime_error_json(
                    self.id,
                    "unknown_event",
                    "unknown page event at batch entry " +
                    index.to_string() +
                    ": " +
                    event_key,
                  )
                Err(error) =>
                  return runtime_error_json(
                    self.id,
                    "event_decode_failed",
                    "event batch entry " +
                    index.to_string() +
                    ": " +
                    error.message(),
                  )
              }
            }
          }
          for message in messages {
            let _ = running.dispatch(message)
          }
          sync_subscriptions()
          take_commands()
        }
      }
    },
    lifecycle: fn(hook_name, payload_json) {
      if hook_name == "$minimoon:drain" {
        match parse_host_json(payload_json) {
          HostJsonOk(Object(fields)) if fields.length() == 1 =>
            match fields.get("through") {
              Some(Number(value, ..)) => {
                if value >= 0.0 && value <= 2147483647.0 {
                  let through = value.to_int()
                  if value == through.to_double() {
                    let _ = running.drain_local_messages(through~)
                    sync_subscriptions()
                    return take_commands()
                  }
                }
                return runtime_error_json(
                  self.id,
                  "invalid_internal_drain",
                  "internal drain through must be a non-negative integer",
                )
              }
              _ =>
                return runtime_error_json(
                  self.id,
                  "invalid_internal_drain",
                  "internal drain payload must contain exactly one through integer",
                )
            }
          HostJsonOk(_) =>
            return runtime_error_json(
              self.id,
              "invalid_internal_drain",
              "internal drain payload must contain exactly one through integer",
            )
          HostJsonError(error) =>
            return runtime_error_json(self.id, "invalid_internal_drain", error)
        }
      }
      match parse_host_json(payload_json) {
        HostJsonError(error) =>
          runtime_error_json(self.id, "invalid_host_payload", error)
        HostJsonOk(payload) => {
          let hook = match page_lifecycle_hook_or_none(hook_name) {
            Some(hook) => hook
            None =>
              return runtime_error_json(
                self.id,
                "unknown_lifecycle",
                "unknown page lifecycle: " + hook_name,
              )
          }
          let messages : Array[Msg] = []
          if hook_name == "onLoad" {
            match decode_page_inputs(self, payload) {
              Ok(inputs) =>
                for msg in inputs {
                  messages.push(msg)
                }
              Err(error) =>
                return runtime_error_json(
                  self.id,
                  "page_input_decode_failed",
                  error.message(),
                )
            }
          }
          match self.decode_lifecycle(hook, payload) {
            Ok(Some(msg)) => messages.push(msg)
            Ok(None) => ()
            Err(error) =>
              return runtime_error_json(
                self.id,
                "lifecycle_decode_failed",
                error.message(),
              )
          }
          for msg in messages {
            let _ = running.dispatch(msg)
          }
          sync_subscriptions()
          take_commands()
        }
      }
    },
    resolve_effect: fn(request_id, phase, payload_json) {
      if phase != "pending" {
        match parse_host_json(payload_json) {
          HostJsonError(error) =>
            return runtime_error_json(self.id, "invalid_host_payload", error)
          HostJsonOk(payload) => {
            let outcome = if phase == "success" {
              @runtime.HostEffectOk(host_effect_value(payload, payload_json))
            } else {
              @runtime.HostEffectErr(
                phase,
                host_effect_error(payload, phase),
                payload_json,
              )
            }
            let _ = running.resolve_host_effect(request_id, outcome)
            sync_subscriptions()
          }
        }
      }
      take_commands()
    },
    subscription: fn(key, _payload_json) {
      match subscription_messages.get(key) {
        Some(msg) => {
          let _ = running.dispatch(msg)
          sync_subscriptions()
          take_commands()
        }
        None =>
          runtime_error_json(
            self.id,
            "unknown_subscription",
            "unknown page subscription: " + key,
          )
      }
    },
    snapshot: fn() {
      "{\"revision\":" +
      host_revision.val.to_string() +
      ",\"tree\":" +
      host_tree.val +
      "}"
    },
    dispose: fn() {
      for key in active_subscription_intervals.keys() {
        commands.val.push(@runtime.stop_subscription_command(self.id, key))
      }
      active_subscription_intervals.clear()
      subscription_messages.clear()
      mounted.val = false
      for _, cleanup in self.active_scope_cleanups.val {
        cleanup()
      }
      self.active_scope_cleanups.val.clear()
      let _ = running.dispose()
      take_commands()
    },
  }
}
