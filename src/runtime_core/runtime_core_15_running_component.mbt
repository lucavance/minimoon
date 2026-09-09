///|
pub fn[Model, Msg] RunningComponent::context(
  self : RunningComponent[Model, Msg],
) -> ComponentContext {
  self.context
}

///|
pub fn[Model, Msg] RunningComponent::model(
  self : RunningComponent[Model, Msg],
) -> Model {
  self.model.val
}

///|
pub fn[Model, Msg] RunningComponent::render(
  self : RunningComponent[Model, Msg],
) -> @ui.Node {
  (self.view)(self.model.val, msg => message(msg))
}

///|
pub fn[Model, Msg] RunningComponent::render_to_string(
  self : RunningComponent[Model, Msg],
) -> String {
  @ui.render_to_string(self.render())
}

///|
pub fn[Model, Msg] RunningComponent::mount(
  self : RunningComponent[Model, Msg],
) -> ContextWriteResult {
  if self.context.is_disposed() {
    return ContextDisposed
  }
  if self.context.is_mounted() {
    return ContextWriteOk
  }
  let result : Ref[ContextWriteResult] = Ref(ContextWriteOk)
  self.context.batch(fn() {
    let mount_result = self.context.mount()
    let state_result = match (self.project)(self.model.val) {
      Ok(payload) => self.context.update_state(payload)
      Err(error) =>
        self.context.emit(RuntimeError(self.context.id, "invalid_view", error))
    }
    match mount_result {
      ContextDisposed => result.val = ContextDisposed
      ContextWriteOk => ()
    }
    match state_result {
      ContextDisposed => result.val = ContextDisposed
      ContextWriteOk => ()
    }
  })
  result.val
}

///|
pub fn[Model, Msg] RunningComponent::dispatch(
  self : RunningComponent[Model, Msg],
  msg : Msg,
) -> ContextWriteResult {
  if self.context.is_disposed() {
    return ContextDisposed
  }
  let result : Ref[ContextWriteResult] = Ref(ContextWriteOk)
  self.context.batch(fn() {
    let (model, cmd) = (self.update)(self.model.val, msg)
    let should_project = match self.projection_guard {
      Some(predicate) => predicate(self.model.val, model)
      None => true
    }
    if !should_project {
      self.model.val = model
      self.run_cmd(cmd, result)
      return
    }
    match (self.project)(model) {
      Err(error) =>
        match
          self.context.emit(
            RuntimeError(self.context.id, "invalid_view", error),
          ) {
          ContextDisposed => result.val = ContextDisposed
          ContextWriteOk => ()
        }
      Ok(payload) => {
        self.model.val = model
        let state_result = self.context.update_state(payload)
        match state_result {
          ContextDisposed => result.val = ContextDisposed
          ContextWriteOk => ()
        }
        self.run_cmd(cmd, result)
      }
    }
  })
  result.val
}

///|
pub fn[Model, Msg] RunningComponent::resolve_host_effect(
  self : RunningComponent[Model, Msg],
  request_id : EffectRequestId,
  outcome : HostEffectOutcome,
) -> EffectResolveResult {
  if self.context.is_disposed() {
    return EffectContextDisposed
  }
  match self.pending_effects.get(request_id) {
    Some(pending) => {
      self.pending_effects.remove(request_id)
      let _ = self.dispatch((pending.resolve)(outcome))
      EffectResolved
    }
    None => EffectUnknownRequest
  }
}

///|
pub fn[Model, Msg] RunningComponent::pending_effect_count(
  self : RunningComponent[Model, Msg],
) -> Int {
  self.pending_effects.length()
}

///|
pub fn[Model, Msg] RunningComponent::pending_local_effect_count(
  self : RunningComponent[Model, Msg],
) -> Int {
  self.pending_local_effects.length()
}

///|
pub fn[Model, Msg] RunningComponent::pending_local_message_count(
  self : RunningComponent[Model, Msg],
) -> Int {
  self.pending_local_messages.length()
}

///|
pub fn[Model, Msg] RunningComponent::drain_local_messages(
  self : RunningComponent[Model, Msg],
  through~ : Int,
) -> ContextWriteResult {
  if self.context.is_disposed() {
    self.pending_local_messages.clear()
    return ContextDisposed
  }
  let messages : Array[Msg] = []
  let retained : Array[PendingLocalMessage[Msg]] = []
  for pending in self.pending_local_messages {
    if pending.sequence <= through {
      messages.push(pending.message)
    } else {
      retained.push(pending)
    }
  }
  self.pending_local_messages.clear()
  for pending in retained {
    self.pending_local_messages.push(pending)
  }
  let result : Ref[ContextWriteResult] = Ref(ContextWriteOk)
  for message in messages {
    match self.dispatch(message) {
      ContextDisposed => result.val = ContextDisposed
      ContextWriteOk => ()
    }
  }
  result.val
}

///|
pub fn[Model, Msg] RunningComponent::transition(
  self : RunningComponent[Model, Msg],
  transition : (Model) -> Model,
) -> ContextWriteResult {
  if self.context.is_disposed() {
    return ContextDisposed
  }
  let result : Ref[ContextWriteResult] = Ref(ContextWriteOk)
  self.context.batch(fn() {
    let model = transition(self.model.val)
    let should_project = match self.projection_guard {
      Some(predicate) => predicate(self.model.val, model)
      None => true
    }
    if !should_project {
      self.model.val = model
      return
    }
    match (self.project)(model) {
      Err(error) =>
        match
          self.context.emit(
            RuntimeError(self.context.id, "invalid_view", error),
          ) {
          ContextDisposed => result.val = ContextDisposed
          ContextWriteOk => ()
        }
      Ok(payload) => {
        self.model.val = model
        let state_result = self.context.update_state(payload)
        match state_result {
          ContextDisposed => result.val = ContextDisposed
          ContextWriteOk => ()
        }
      }
    }
  })
  result.val
}

///|
pub fn[Model, Msg] RunningComponent::dispose(
  self : RunningComponent[Model, Msg],
) -> ContextWriteResult {
  self.pending_local_messages.clear()
  let local_cancellations = self.pending_local_effects.values().to_array()
  self.pending_local_effects.clear()
  for cancel in local_cancellations {
    cancel()
  }
  for request_id, _ in self.pending_effects {
    let _ = self.context.emit(CancelEffect(self.context.id, request_id))
  }
  let result = self.context.dispose()
  self.pending_effects.clear()
  result
}

///|
fn[Model, Msg] RunningComponent::run_cmd(
  self : RunningComponent[Model, Msg],
  cmd : Cmd[Msg],
  result : Ref[ContextWriteResult],
) -> Unit {
  match cmd {
    CmdNone => ()
    CmdMessage(msg) =>
      match self.dispatch(msg) {
        ContextDisposed => result.val = ContextDisposed
        ContextWriteOk => ()
      }
    CmdBatch(commands) =>
      for command in commands {
        self.run_cmd(command, result)
      }
    CmdLocalEffect(start) => {
      let effect_id = self.next_local_effect_id.val
      self.next_local_effect_id.val = effect_id + 1
      let active = Ref(true)
      let start_returned = Ref(false)
      self.pending_local_effects[effect_id] = fn() { active.val = false }
      let emit = fn(msg) {
        if active.val && !self.context.is_disposed() {
          if start_returned.val {
            self.next_local_message_sequence.val += 1
            let sequence = self.next_local_message_sequence.val
            self.pending_local_messages.push({ sequence, message: msg, })
            (self.wake_async)(sequence)
          } else {
            let _ = self.dispatch(msg)
          }
        }
      }
      let finish = fn() {
        if active.val {
          active.val = false
          self.pending_local_effects.remove(effect_id)
        }
      }
      let cancel = start(emit, finish)
      start_returned.val = true
      if active.val && self.pending_local_effects.contains(effect_id) {
        self.pending_local_effects[effect_id] = fn() {
          if active.val {
            active.val = false
            cancel()
          }
        }
      }
    }
    CmdHostEffect(request, resolve) => {
      let sequence = self.next_effect_request_id.val
      self.next_effect_request_id.val = sequence + 1
      let request_id = self.context.id + ":" + sequence.to_string()
      self.pending_effects[request_id] = { resolve, }
      match
        self.context.emit(
          InvokeCapability(
            self.context.id,
            request_id,
            request.capability,
            request.payload,
          ),
        ) {
        ContextDisposed => {
          self.pending_effects.remove(request_id)
          result.val = ContextDisposed
        }
        ContextWriteOk => ()
      }
    }
    CmdNavigateTo(url) =>
      match self.context.emit(NavigateTo(url)) {
        ContextDisposed => result.val = ContextDisposed
        ContextWriteOk => ()
      }
    CmdRedirectTo(url) =>
      match self.context.emit(RedirectTo(url)) {
        ContextDisposed => result.val = ContextDisposed
        ContextWriteOk => ()
      }
    CmdNavigateBack(delta) =>
      match self.context.emit(NavigateBack(delta)) {
        ContextDisposed => result.val = ContextDisposed
        ContextWriteOk => ()
      }
    CmdSwitchTab(url) =>
      match self.context.emit(SwitchTab(url)) {
        ContextDisposed => result.val = ContextDisposed
        ContextWriteOk => ()
      }
    CmdNavigateBackOrRedirect(delta, fallback) =>
      match self.context.emit(NavigateBackOrRedirect(delta, fallback)) {
        ContextDisposed => result.val = ContextDisposed
        ContextWriteOk => ()
      }
  }
}
