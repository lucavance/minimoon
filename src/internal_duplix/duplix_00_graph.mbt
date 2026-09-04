// Derived from moonbit-community/rabbita v0.13.1 (6392a57), Apache-2.0.
// Modified by Minimoon for page-owned roots and transactional branch caches.

///|
using @vector {type Vector}

///|
/// Stable tags let dynamic branches retain or dispose their local scope.
pub(open) trait Enumerate {
  fn tag(Self) -> String
}

///|
let uuid : Ref[Int] = Ref(0)

///|
let clock : Ref[Double] = Ref(0)

///|
let ambient_transaction : Ref[((() -> Unit, () -> Unit) -> Unit)?] = Ref(None)

///|
pub fn[A] transaction(
  enlist : (() -> Unit, () -> Unit) -> Unit,
  run : () -> A,
) -> A {
  ambient_transaction.protect(Some(enlist), run)
}

///|
fn enlist_transaction(commit : () -> Unit, rollback : () -> Unit) -> Unit {
  match ambient_transaction.val {
    Some(enlist) => enlist(commit, rollback)
    None => commit()
  }
}

///|
fn get_uuid() -> Int {
  uuid.val += 1
  uuid.val
}

///|
/// child1 ---+
///           |----derived----> parent
/// child2 ---+
///
/// parent_expr = child1_expr + child2_expr
priv trait ErasedNode {
  fn get_id(Self) -> Int
  fn childs(Self) -> Array[&ErasedNode]
  fn changed_at(Self) -> Double
  fn dirty_flag(Self) -> DirtyFlag
  fn recompute(Self) -> Unit
}

///|
///       child ---derived---> parent
///
///          Node(parent) ---ref---> Node(child)
///              |                        |
///             ref                      ref
///              |                        |
///              v                        v
///     DirtyFlag(parent) <---ref--- DirtyFlag(child)
struct Node[T] {
  id : Int
  mut value : T?
  mut compute : () -> T
  // Logical clock stamps. Double can represent every integer up to 2^53 - 1
  // exactly. At 60fps, even 100,000 reads per frame would take about 47 years
  // to exhaust that range, so wraparound is not a practical concern here.
  mut changed_at : Double
  mut recomputed_at : Double
  scope : @slotmap.Id
  childs : Array[&ErasedNode]
  dirty_flag : DirtyFlag
}

///|
pub fn[T] constant(x : T) -> Node[T] {
  let dirty_b = { dirty: false, parents: [], id: get_uuid(), }
  {
    id: get_uuid(),
    scope: current_scope.val,
    value: Some(x),
    compute: () => x,
    changed_at: 0,
    recomputed_at: 0,
    childs: [],
    dirty_flag: dirty_b,
  }
}

///|
pub impl[T] Eq for Node[T] with fn equal(a, b) {
  a.id == b.id
}

///|
pub impl[T] Compare for Node[T] with fn compare(a, b) {
  a.id.compare(b.id)
}

///|
impl[T : Eq] ErasedNode for Node[T] with fn get_id(self) {
  self.id
}

///|
impl[T : Eq] ErasedNode for Node[T] with fn changed_at(self) {
  self.changed_at
}

///|
impl[T : Eq] ErasedNode for Node[T] with fn childs(self) {
  self.childs
}

///|
impl[T : Eq] ErasedNode for Node[T] with fn dirty_flag(self) {
  self.dirty_flag
}

///|
extend Node with ErasedNode::{dirty_flag}

///|
impl[T : Eq] ErasedNode for Node[T] with fn recompute(self) {
  current_scope.protect(self.scope, () => {
    match self.value {
      None => {
        let new = (self.compute)()
        self.value = Some(new)
        self.recomputed_at = clock.val
        self.changed_at = self.recomputed_at
        self.dirty_flag().dirty = false
      }
      Some(old) if self.dirty_flag().dirty => {
        if self.childs is [] ||
          self.childs.any(x => x.changed_at() > self.recomputed_at) {
          let new = (self.compute)()
          self.recomputed_at = clock.val
          if !Eq::equal(old, new) {
            self.changed_at = self.recomputed_at
          }
          self.value = Some(new)
        }
        self.dirty_flag().dirty = false
      }
      Some(_) => ()
    }
  })
}

///|
/// DirtyFlag(parent) <--ref--- DirtyFlag(child)
struct DirtyFlag {
  id : Int
  mut dirty : Bool
  parents : Array[DirtyFlag]
}

///|
pub impl Eq for DirtyFlag with fn equal(a, b) {
  a.id == b.id
}

///|
pub impl Compare for DirtyFlag with fn compare(a, b) {
  a.id.compare(b.id)
}

///|
pub fn[T : Eq] input(x : T) -> (Node[T], (T) -> Unit) {
  let node = {
    id: get_uuid(),
    scope: current_scope.val,
    value: None,
    compute: () => x,
    changed_at: 0,
    recomputed_at: 0,
    childs: [],
    dirty_flag: { dirty: true, parents: [], id: get_uuid(), },
  }

  fn write(x : T) {
    node.compute = () => x
    push_dirty(node)
  }

  (node, write)
}

///|
/// child_a ---derived---> parent_b
pub fn[A : Eq, B] Node::map(a : Node[A], f : (A) -> B) -> Node[B] {
  let dirty_b = { dirty: true, parents: [], id: get_uuid(), }
  // a.dirty_flag.parents.push(dirty_b)
  {
    id: get_uuid(),
    scope: current_scope.val,
    value: None,
    compute: () => f(a.value.unwrap()),
    changed_at: 0,
    recomputed_at: 0,
    childs: [a],
    dirty_flag: dirty_b,
  }
}

///|
///         a -----+
///                |----> output
///   b1 or b2 ----+
pub fn[A : Eq, B : Eq] Node::bind(a : Node[A], f : (A) -> Node[B]) -> Node[B] {
  let mut b1_dirty_sub : DirtyFlag? = None
  let output_childs : Array[&ErasedNode] = []
  let output_dirty_flag = { dirty: true, parents: [], id: get_uuid(), }
  fn compute() {
    let b2 = f(a.value.unwrap())
    let branch_changed = b1_dirty_sub is None ||
      (b1_dirty_sub is Some(prev) && prev.id != b2.dirty_flag().id)

    if branch_changed {
      // delete: b1 ---derived---> output
      // add:    b2 ---derived---> output
      if b1_dirty_sub is Some(b1) && b1.id != a.dirty_flag().id {
        if b1.parents.search(output_dirty_flag) is Some(i) {
          ignore(b1.parents.remove(i))
        }
        if output_childs.search_by(x => x.dirty_flag().id == b1.id) is Some(i) {
          ignore(output_childs.remove(i))
        }
      }

      if b2.dirty_flag().id != a.dirty_flag().id {
        b2.dirty_flag().parents.push(output_dirty_flag)
        output_childs.push(b2)
      }
      b1_dirty_sub = Some(b2.dirty_flag())
    }

    b2.internal_read()
  }

  // a ---derived--->output
  // a.dirty_flag.parents.push(output_dirty_flag)
  output_childs.push(a)

  {
    id: get_uuid(),
    scope: current_scope.val,
    value: None,
    compute,
    changed_at: 0,
    recomputed_at: 0,
    childs: output_childs,
    dirty_flag: output_dirty_flag,
  }
}

///|
priv struct DynamicBranch[E, A] {
  mut value : E
  set_value : (E) -> Unit
  result : Node[A]
  scope : @slotmap.Id
}

///|
fn[E : Eq, A] dynamic_branch(
  value : E,
  build : (E, Node[E]) -> Node[A],
) -> DynamicBranch[E, A] {
  with_scope(scope => {
    let (input, set_value) = input(value)
    { value, set_value, result: build(value, input), scope, }
  })
}

///|
fn[E : Eq, A] DynamicBranch::stage_input(
  self : DynamicBranch[E, A],
  value : E,
) -> Unit {
  if self.value != value {
    let previous = self.value
    self.value = value
    (self.set_value)(value)
    enlist_transaction(fn() { () }, fn() {
      self.value = previous
      (self.set_value)(previous)
    })
  }
}

///|
fn[E, A] DynamicBranch::dispose(self : DynamicBranch[E, A]) -> Unit {
  if global_scopes.get(self.scope) is Some(scope) {
    scope.dispose()
  }
}

///|
pub fn[E : Enumerate + Eq, A : Eq] Node::switch(
  a : Node[E],
  f : (E, Node[E]) -> Node[A],
) -> Node[A] {
  a.switch_by(f, by=value => Enumerate::tag(value))
}

///|
pub fn[E : Eq, A : Eq] Node::switch_by(
  a : Node[E],
  f : (E, Node[E]) -> Node[A],
  by~ : (E) -> String,
) -> Node[A] {
  let mut active : (String, DynamicBranch[E, A])? = None
  a.bind(value => {
    let tag = by(value)
    match active {
      None => {
        let created = dynamic_branch(value, f)
        active = Some((tag, created))
        enlist_transaction(fn() { () }, fn() {
          active = None
          created.dispose()
        })
        created.result
      }
      Some((old_tag, branch) as previous) =>
        if tag == old_tag {
          branch.stage_input(value)
          branch.result
        } else {
          let created = dynamic_branch(value, f)
          active = Some((tag, created))
          set_scope_visible(branch.scope, false)
          enlist_transaction(fn() { branch.dispose() }, fn() {
            active = Some(previous)
            set_scope_visible(branch.scope, true)
            created.dispose()
          })
          created.result
        }
    }
  })
}
