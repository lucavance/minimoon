///|
pub fn RuntimeCommandQueue::new(
  sink : (Array[RuntimeCommand]) -> Unit,
) -> RuntimeCommandQueue {
  { commands: Ref([]), suspend_depth: Ref(0), sink, }
}

///|
pub fn RuntimeCommandQueue::pending_count(self : RuntimeCommandQueue) -> Int {
  self.commands.val.length()
}

///|
pub fn RuntimeCommandQueue::push(
  self : RuntimeCommandQueue,
  command : RuntimeCommand,
) -> Unit {
  self.commands.val.push(command)
  if self.suspend_depth.val == 0 {
    self.flush()
  }
}

///|
pub fn RuntimeCommandQueue::flush(self : RuntimeCommandQueue) -> Unit {
  if self.commands.val.length() == 0 {
    return
  }
  let commands = self.commands.val
  self.commands.val = []
  (self.sink)(commands)
}

///|
pub fn RuntimeCommandQueue::begin_batch(self : RuntimeCommandQueue) -> Unit {
  self.suspend_depth.val = self.suspend_depth.val + 1
}

///|
pub fn RuntimeCommandQueue::end_batch(self : RuntimeCommandQueue) -> Unit {
  if self.suspend_depth.val > 0 {
    self.suspend_depth.val = self.suspend_depth.val - 1
  }
  if self.suspend_depth.val == 0 {
    self.flush()
  }
}

///|
pub fn RuntimeCommandQueue::batch(
  self : RuntimeCommandQueue,
  f : () -> Unit,
) -> Unit {
  self.begin_batch()
  f()
  self.end_batch()
}

///|
pub fn ComponentContext::new(
  id : ComponentId,
  queue : RuntimeCommandQueue,
) -> ComponentContext {
  { id, mounted: Ref(false), disposed: Ref(false), cleanups: Ref([]), queue, }
}

///|
pub fn ComponentContext::id(self : ComponentContext) -> ComponentId {
  self.id
}

///|
pub fn ComponentContext::is_disposed(self : ComponentContext) -> Bool {
  self.disposed.val
}

///|
pub fn ComponentContext::is_mounted(self : ComponentContext) -> Bool {
  self.mounted.val && !self.disposed.val
}

///|
pub fn ComponentContext::lifecycle_state(
  self : ComponentContext,
) -> ComponentLifecycleState {
  if self.disposed.val {
    ComponentDisposed
  } else if self.mounted.val {
    ComponentMounted
  } else {
    ComponentCreated
  }
}

///|
pub fn[T] ComponentContext::run_in_scope(
  _self : ComponentContext,
  f : () -> T,
) -> T {
  f()
}

///|
pub fn ComponentContext::batch(self : ComponentContext, f : () -> Unit) -> Unit {
  self.queue.begin_batch()
  f()
  self.queue.end_batch()
}

///|
pub fn ComponentContext::mount(self : ComponentContext) -> ContextWriteResult {
  if self.disposed.val {
    return ContextDisposed
  }
  if self.mounted.val {
    return ContextWriteOk
  }
  self.mounted.val = true
  self.queue.push(MountContext(self.id))
  ContextWriteOk
}

///|
pub fn ComponentContext::emit(
  self : ComponentContext,
  command : RuntimeCommand,
) -> ContextWriteResult {
  if self.disposed.val {
    return ContextDisposed
  }
  self.queue.push(command)
  ContextWriteOk
}

///|
pub fn ComponentContext::update_state(
  self : ComponentContext,
  payload : HostPayload,
) -> ContextWriteResult {
  self.emit(replace_view_tree(self.id, payload))
}

///|
pub fn ComponentContext::emit_event(
  self : ComponentContext,
  event_key : EventKey,
  payload : HostPayload,
) -> ContextWriteResult {
  self.emit(EmitHostEvent(self.id, event_key, payload))
}

///|
pub fn ComponentContext::on_cleanup(
  self : ComponentContext,
  cleanup : () -> Unit,
) -> ContextWriteResult {
  if self.disposed.val {
    return ContextDisposed
  }
  self.cleanups.val.push(cleanup)
  ContextWriteOk
}

///|
pub fn ComponentContext::dispose(self : ComponentContext) -> ContextWriteResult {
  if self.disposed.val {
    return ContextDisposed
  }
  self.disposed.val = true
  self.mounted.val = false
  let cleanups = self.cleanups.val
  self.cleanups.val = []
  for cleanup in cleanups {
    cleanup()
  }
  self.queue.push(DisposeContext(self.id))
  ContextWriteOk
}

///|
