///|
pub fn[E : Enumerate + Eq, A : Eq] Node::enumerate(
  map : Node[E],
  f : (E, Node[E]) -> Node[A],
) -> Node[A] {
  map.enumerate_by(f, by=value => Enumerate::tag(value))
}

///|
pub fn[E : Eq, A : Eq] Node::enumerate_by(
  map : Node[E],
  f : (E, Node[E]) -> Node[A],
  by~ : (E) -> String,
) -> Node[A] {
  let cache : Map[String, DynamicBranch[E, A]] = Map([])
  let mut active_tag : String? = None
  map.bind(value => {
    let tag = by(value)
    let mut created = false
    let branch = match cache.get(tag) {
      Some(branch) => {
        branch.stage_input(value)
        branch
      }
      None => {
        created = true
        let branch = dynamic_branch(value, f)
        cache.set(tag, branch)
        branch
      }
    }
    match active_tag {
      None => {
        active_tag = Some(tag)
        enlist_transaction(fn() { () }, fn() {
          active_tag = None
          match cache.get(tag) {
            Some(current) if current.scope == branch.scope => cache.remove(tag)
            _ => ()
          }
          branch.dispose()
        })
      }
      Some(previous_tag) if previous_tag == tag => ()
      Some(previous_tag) => {
        let previous = cache[previous_tag]
        active_tag = Some(tag)
        set_scope_visible(previous.scope, false)
        if !created {
          set_scope_visible(branch.scope, true)
        }
        enlist_transaction(fn() { () }, fn() {
          active_tag = Some(previous_tag)
          set_scope_visible(previous.scope, true)
          if created {
            match cache.get(tag) {
              Some(current) if current.scope == branch.scope =>
                cache.remove(tag)
              _ => ()
            }
            branch.dispose()
          } else {
            set_scope_visible(branch.scope, false)
          }
        })
      }
    }
    branch.result
  })
}

///|
/// Retain at most `capacity` committed branches. A new tag replaces the least
/// recently used branch after the candidate transaction commits; rollback
/// restores the previous cache and active scope exactly.
pub fn[E : Eq, A : Eq] Node::enumerate_bounded_by(
  map : Node[E],
  capacity~ : Int,
  f : (E, Node[E]) -> Node[A],
  by~ : (E) -> String,
) -> Node[A] {
  guard capacity > 0 else {
    abort("bounded enumeration capacity must be positive")
  }
  let cache : Map[String, DynamicBranch[E, A]] = Map([])
  let recency : Map[String, Int] = Map([])
  let mut active_tag : String? = None
  let mut use_clock = 0
  map.bind(value => {
    let tag = by(value)
    use_clock += 1
    match cache.get(tag) {
      Some(branch) => {
        branch.stage_input(value)
        let previous_use = recency[tag]
        recency[tag] = use_clock
        match active_tag {
          None => {
            active_tag = Some(tag)
            set_scope_visible(branch.scope, true)
            enlist_transaction(fn() { () }, fn() {
              active_tag = None
              recency[tag] = previous_use
              set_scope_visible(branch.scope, false)
            })
          }
          Some(previous_tag) if previous_tag == tag =>
            enlist_transaction(fn() { () }, fn() { recency[tag] = previous_use })
          Some(previous_tag) => {
            let previous = cache[previous_tag]
            active_tag = Some(tag)
            set_scope_visible(previous.scope, false)
            set_scope_visible(branch.scope, true)
            enlist_transaction(fn() { () }, fn() {
              active_tag = Some(previous_tag)
              recency[tag] = previous_use
              set_scope_visible(branch.scope, false)
              set_scope_visible(previous.scope, true)
            })
          }
        }
        branch.result
      }
      None => {
        let previous_active = active_tag
        let evicted : (String, DynamicBranch[E, A], Int)? = if cache.length() >=
          capacity {
          let victim_tag : Ref[String?] = Ref(None)
          let victim_use = Ref(0)
          for cached_tag, cached_use in recency {
            if victim_tag.val is None || cached_use < victim_use.val {
              victim_tag.val = Some(cached_tag)
              victim_use.val = cached_use
            }
          }
          match victim_tag.val {
            Some(victim_tag) => {
              let victim = cache[victim_tag]
              cache.remove(victim_tag)
              recency.remove(victim_tag)
              Some((victim_tag, victim, victim_use.val))
            }
            None => abort("bounded enumeration cache is inconsistent")
          }
        } else {
          None
        }
        match previous_active {
          Some(previous_tag) =>
            match cache.get(previous_tag) {
              Some(previous) => set_scope_visible(previous.scope, false)
              None =>
                match evicted {
                  Some((victim_tag, victim, _)) if victim_tag == previous_tag =>
                    set_scope_visible(victim.scope, false)
                  _ => abort("bounded enumeration active branch is missing")
                }
            }
          None => ()
        }
        let branch = dynamic_branch(value, f)
        cache[tag] = branch
        recency[tag] = use_clock
        active_tag = Some(tag)
        enlist_transaction(
          fn() {
            match evicted {
              Some((_, victim, _)) => victim.dispose()
              None => ()
            }
          },
          fn() {
            active_tag = previous_active
            match cache.get(tag) {
              Some(current) if current.scope == branch.scope => {
                cache.remove(tag)
                recency.remove(tag)
              }
              _ => ()
            }
            branch.dispose()
            match evicted {
              Some((victim_tag, victim, victim_use)) => {
                cache[victim_tag] = victim
                recency[victim_tag] = victim_use
              }
              None => ()
            }
            match previous_active {
              Some(previous_tag) =>
                match cache.get(previous_tag) {
                  Some(previous) => set_scope_visible(previous.scope, true)
                  None => ()
                }
              None => ()
            }
          },
        )
        branch.result
      }
    }
  })
}

///|
priv struct AssocEntry[V, C] {
  mut value : V
  set_value : (V) -> Unit
  result : Node[C]
  scope : @slotmap.Id
  mut epoch : Int
}

///|
///             node(entries) ---+
///                              |
/// node(v1) --?-> node(c1) -----+
///                              |---> node(vector(c))
/// node(v2) --?-> node(c2) -----+
///   ...                        |
/// node(vN) --?-> node(cN) -----+
fn[K : Hash + Eq, I : Eq, V : Eq, C : Eq] Node::assoc_projected(
  a : Node[Vector[I]],
  f : (K, Node[V]) -> Node[C],
  key_of : (I) -> K,
  value_of : (I) -> V,
) -> Node[Vector[C]] {
  let mut epoch = 0
  let cache : Map[K, AssocEntry[V, C]] = Map([])
  let output_childs : Array[&ErasedNode] = [a]
  let output_dirty_flag = { dirty: true, parents: [], id: get_uuid(), }
  fn compute() {
    epoch += 1
    let active_results : Array[Node[C]] = []
    let entries = a.value.unwrap()
    for item in entries {
      let key = key_of(item)
      let value = value_of(item)
      let entry = if cache.get(key) is Some(entry) {
        if entry.value != value {
          let old_value = entry.value
          entry.value = value
          (entry.set_value)(value)
          enlist_transaction(fn() { () }, fn() {
            entry.value = old_value
            (entry.set_value)(old_value)
          })
        }
        entry.epoch = epoch
        entry
      } else {
        let entry = with_scope(scope => {
          let (value_node, set_value) = input(value)
          let result = f(key, value_node)
          { value, set_value, result, scope, epoch, }
        })
        cache.set(key, entry)
        enlist_transaction(fn() { () }, fn() {
          match cache.get(key) {
            Some(current) if current.scope == entry.scope => cache.remove(key)
            _ => ()
          }
          if entry.result.dirty_flag.parents.search(output_dirty_flag)
            is Some(i) {
            ignore(entry.result.dirty_flag.parents.remove(i))
          }
          if global_scopes.get(entry.scope) is Some(scope) {
            scope.dispose()
          }
        })
        entry
      }
      active_results.push(entry.result)
    }

    let stale_keys : Array[K] = []
    for key, entry in cache {
      if entry.epoch != epoch {
        stale_keys.push(key)
      }
    }
    for key in stale_keys {
      if cache.get(key) is Some(entry) {
        cache.remove(key)
        set_scope_visible(entry.scope, false)
        enlist_transaction(
          fn() {
            if entry.result.dirty_flag.parents.search(output_dirty_flag)
              is Some(i) {
              ignore(entry.result.dirty_flag.parents.remove(i))
            }
            if global_scopes.get(entry.scope) is Some(scope) {
              scope.dispose()
            }
          },
          fn() {
            cache.set(key, entry)
            set_scope_visible(entry.scope, true)
          },
        )
      }
    }

    output_childs.clear()
    output_childs.push(a)
    @vector.from_iter(
      active_results
      .iter()
      .map(result => {
        output_childs.push(result)
        if result.dirty_flag.parents.all(x => x.id != output_dirty_flag.id) {
          result.dirty_flag.parents.push(output_dirty_flag)
        }
        result.internal_read()
      }),
    )
  }

  {
    id: get_uuid(),
    scope: current_scope.val,
    value: None,
    compute,
    recomputed_at: 0,
    changed_at: 0,
    childs: output_childs,
    dirty_flag: output_dirty_flag,
  }
}

///|
pub fn[K : Hash + Eq, V : Eq, C : Eq] Node::assoc(
  a : Node[Vector[(K, V)]],
  f : (K, Node[V]) -> Node[C],
) -> Node[Vector[C]] {
  a.assoc_projected(f, pair => pair.0, pair => pair.1)
}

///|
pub fn[K : Hash + Eq, V : Eq, C : Eq] Node::assoc_by(
  a : Node[Vector[V]],
  f : (K, Node[V]) -> Node[C],
  by~ : (V) -> K,
) -> Node[Vector[C]] {
  a.assoc_projected(f, by, value => value)
}

///|
fn[A : Eq] Node::internal_read(a : Node[A]) -> A {
  pull_value(a)
  a.value.unwrap()
}

///|
pub fn[A : Eq] Node::read(a : Node[A]) -> A {
  clock.val += 1
  a.internal_read()
}

///|
fn pull_value(node : &ErasedNode) -> Unit {
  let stack = [(node, false)]
  let seen = Set([])
  let recomputes = []

  while stack.pop() is Some((x, expanded)) {
    guard x.dirty_flag().dirty else { continue }
    let id = x.get_id()
    if expanded {
      recomputes.push(x)
    } else if !seen.contains(id) {
      seen.add(id)
      stack.push((x, true))

      for child in x.childs() {
        if child.dirty_flag().dirty {
          stack.push((child, false))
        }
      }
    }
  }

  for node in recomputes {
    for child in node.childs() {
      if child.dirty_flag().parents.all(x => x.id != node.dirty_flag().id) {
        child.dirty_flag().parents.push(node.dirty_flag())
      }
    }
    node.recompute()
  }
}

///|
fn push_dirty(node : &ErasedNode) -> Unit {
  let traverses = @queue.Queue([(node.dirty_flag(), false)])
  while traverses.pop() is Some((x, expanded)) {
    if expanded {
      x.parents.clear()
    } else {
      guard !x.dirty else { continue }
      x.dirty = true
      for p in x.parents {
        traverses.push((p, false))
      }
      traverses.push((x, true))
    }
  }
}
