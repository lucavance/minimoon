// Derived from moonbit-community/rabbita v0.13.1 (6392a57), Apache-2.0.
// Modified by Minimoon for isolated page roots and reversible visibility.

///|
let global_scopes : @slotmap.SlotMap[Scope] = SlotMap()

///|
let root_scope : @slotmap.Id = global_scopes.allocate_with(id => {
  id,
  parent: None,
  sub_scopes: Set([]),
  cleanups: [],
  visibility: [],
  local_visible: true,
  effective_visible: true,
})

///|
let current_scope : Ref[@slotmap.Id] = Ref(root_scope)

///|
/// A root scope owned by one mounted Minimoon page graph.
pub struct RootScope {
  id : @slotmap.Id
  disposed : Ref[Bool]
}

///|
pub fn RootScope::new() -> RootScope {
  {
    id: global_scopes.allocate_with(id => {
      id,
      parent: None,
      sub_scopes: Set([]),
      cleanups: [],
      visibility: [],
      local_visible: true,
      effective_visible: true,
    }),
    disposed: Ref(false),
  }
}

///|
pub fn[A] RootScope::run(self : RootScope, f : () -> A) -> A {
  guard !self.disposed.val else { abort("incremental root scope is disposed") }
  current_scope.protect(self.id, f)
}

///|
pub fn RootScope::dispose(self : RootScope) -> Unit {
  if self.disposed.val {
    return
  }
  self.disposed.val = true
  if global_scopes.get(self.id) is Some(scope) {
    scope.dispose()
  }
}

///|
fn get_scope() -> Scope {
  global_scopes[current_scope.val]
}

///|
priv struct Scope {
  id : @slotmap.Id
  parent : @slotmap.Id?
  sub_scopes : Set[@slotmap.Id]
  cleanups : Array[() -> Unit]
  visibility : Array[(Bool) -> Unit]
  mut local_visible : Bool
  mut effective_visible : Bool
}

///|
fn[A] with_scope(f : (@slotmap.Id) -> A) -> A {
  let parent = get_scope()
  let id = global_scopes.allocate_with(id => {
    id,
    parent: Some(current_scope.val),
    sub_scopes: Set([]),
    cleanups: [],
    visibility: [],
    local_visible: true,
    effective_visible: parent.effective_visible,
  })
  let result = current_scope.protect(id, () => f(id))
  if global_scopes.get(current_scope.val) is Some(scope) {
    scope.sub_scopes.add(id)
  }
  result
}

///|
pub fn on_cleanup(f : () -> Unit) -> Unit {
  get_scope().cleanups.push(f)
}

///|
pub fn on_visibility(f : (Bool) -> Unit) -> Unit {
  let scope = get_scope()
  scope.visibility.push(f)
  // Registrants start active. A child built below a hidden ancestor must be
  // inactive immediately, without adding initial shown callbacks elsewhere.
  if !scope.effective_visible {
    f(false)
  }
}

///|
fn Scope::refresh_visibility(self : Scope, parent_visible : Bool) -> Unit {
  let visible = self.local_visible && parent_visible
  if self.effective_visible == visible {
    return
  }
  self.effective_visible = visible
  for callback in self.visibility {
    callback(visible)
  }
  for id in self.sub_scopes {
    if global_scopes.get(id) is Some(scope) {
      scope.refresh_visibility(visible)
    }
  }
}

///|
fn set_scope_visible(id : @slotmap.Id, visible : Bool) -> Unit {
  if global_scopes.get(id) is Some(scope) {
    scope.local_visible = visible
    let parent_visible = match scope.parent {
      Some(parent) => global_scopes[parent].effective_visible
      None => true
    }
    scope.refresh_visibility(parent_visible)
  }
}

///|
pub fn cleanup() -> Unit {
  global_scopes[root_scope].dispose()
}

///|
fn Scope::dispose(self : Self) -> Unit {
  for id in self.sub_scopes {
    if global_scopes.get(id) is Some(scope) {
      scope.dispose()
    }
  }

  for cleanup in self.cleanups {
    cleanup()
  }

  if self.parent is Some(p) {
    global_scopes[p].sub_scopes.remove(self.id)
  }

  global_scopes.free(self.id)
}
