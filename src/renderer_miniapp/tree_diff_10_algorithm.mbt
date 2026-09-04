///|
fn diff_keyed_children(
  old_children : Array[Json],
  next_children : Array[Json],
  path : Array[Json],
  ops : Array[TreePatchOp],
) -> Bool {
  let old_ids : Array[String] = []
  let next_ids : Array[String] = []
  let old_indices : Map[String, Int] = Map([])
  let next_indices : Map[String, Int] = Map([])
  let next_id_set : Set[String] = Set([])
  for child in old_children {
    match tree_child_identity(child) {
      Some(identity) => {
        old_indices[identity] = old_ids.length()
        old_ids.push(identity)
      }
      None => return false
    }
  }
  for child in next_children {
    match tree_child_identity(child) {
      Some(identity) => {
        next_indices[identity] = next_ids.length()
        next_id_set.add(identity)
        next_ids.push(identity)
      }
      None => return false
    }
  }
  let structure : Array[TreePatchOp] = []
  let working = old_ids.map(identity => identity)
  let working_positions : Map[String, Int] = Map([])
  reindex_string_positions(working, working_positions, 0)
  let structure_cost = Ref(0)
  for index = old_ids.length() - 1; index >= 0; index = index - 1 {
    if !next_id_set.contains(old_ids[index]) {
      structure.push(
        SpliceTreeChildren(tree_path_field(path, "children"), index, 1, []),
      )
      structure_cost.val += 1
      if structure_cost.val > 32 {
        return false
      }
      working_positions.remove(old_ids[index])
      let _ = working.remove(index)
      reindex_string_positions(working, working_positions, index)
    }
  }
  let keep : Set[String] = Set([])
  let (keep_identities, _) = keyed_lis_identities_with_work(working, next_ids)
  for identity in keep_identities {
    keep.add(identity)
  }
  let moved : Set[String] = Set([])
  let inserted : Set[String] = Set([])
  for target = next_ids.length() - 1; target >= 0; target = target - 1 {
    let identity = next_ids[target]
    let current = working_positions.get(identity).unwrap_or(-1)
    if current < 0 {
      structure.push(
        SpliceTreeChildren(tree_path_field(path, "children"), target, 0, [
          next_children[target],
        ]),
      )
      structure_cost.val += 1
      if structure_cost.val > 32 {
        return false
      }
      working.insert(target, identity)
      inserted.add(identity)
      reindex_string_positions(working, working_positions, target)
    } else if !keep.contains(identity) && current != target {
      structure.push(
        MoveTreeChild(
          tree_path_field(path, "children"),
          current,
          target,
          identity,
          next_children[target],
        ),
      )
      structure_cost.val += 2
      if structure_cost.val > 32 {
        return false
      }
      let value = working.remove(current)
      working.insert(target, value)
      moved.add(identity)
      let start = if current < target { current } else { target }
      reindex_string_positions(working, working_positions, start)
    }
  }
  guard working == next_ids else { return false }
  for identity in next_ids {
    if !moved.contains(identity) && !inserted.contains(identity) {
      let old_index = old_indices.get(identity).unwrap_or(-1)
      let next_index = next_indices.get(identity).unwrap_or(-1)
      guard old_index >= 0 && next_index >= 0 else { return false }
      let old_child = old_children[old_index]
      let next_child = next_children[next_index]
      if old_child != next_child &&
        tree_node_shape_matches(old_child, next_child) {
        guard diff_tree_node(
          old_child,
          next_child,
          tree_path_child(path, old_index),
          ops,
        ) else {
          return false
        }
      }
    }
  }
  append_tree_patch_ops(ops, structure)
  for target = 0; target < next_children.length(); target = target + 1 {
    let identity = next_ids[target]
    let old_index = old_indices.get(identity).unwrap_or(-1)
    if old_index >= 0 &&
      !moved.contains(identity) &&
      !inserted.contains(identity) &&
      !tree_node_shape_matches(old_children[old_index], next_children[target]) {
      ops.push(
        SpliceTreeChildren(tree_path_field(path, "children"), target, 1, [
          next_children[target],
        ]),
      )
    }
  }
  true
}

///|
fn diff_tree_children(
  old_children : Array[Json],
  next_children : Array[Json],
  path : Array[Json],
  ops : Array[TreePatchOp],
) -> Bool {
  let old_kind = tree_children_kind(old_children)
  let next_kind = tree_children_kind(next_children)
  match (old_kind, next_kind) {
    (InvalidChildren, _) | (_, InvalidChildren) => false
    (EmptyChildren, EmptyChildren) => true
    (KeyedChildren, KeyedChildren) =>
      diff_keyed_children(old_children, next_children, path, ops)
    (UnkeyedChildren, UnkeyedChildren) =>
      diff_unkeyed_children(old_children, next_children, path, ops)
    (EmptyChildren, KeyedChildren) | (KeyedChildren, EmptyChildren) =>
      diff_keyed_children(old_children, next_children, path, ops)
    (EmptyChildren, UnkeyedChildren) | (UnkeyedChildren, EmptyChildren) =>
      diff_unkeyed_children(old_children, next_children, path, ops)
    _ => {
      ops.push(
        SpliceTreeChildren(
          tree_path_field(path, "children"),
          0,
          old_children.length(),
          next_children.map(child => child),
        ),
      )
      true
    }
  }
}

///|
fn diff_tree_node(
  old_tree : Json,
  next_tree : Json,
  path : Array[Json],
  ops : Array[TreePatchOp],
) -> Bool {
  guard tree_node_shape_matches(old_tree, next_tree) else { return false }
  for field in tree_scalar_fields {
    match
      (tree_node_field(old_tree, field), tree_node_field(next_tree, field)) {
      (Some(old_value), Some(next_value)) if old_value != next_value =>
        ops.push(SetTreeField(tree_path_field(path, field), next_value))
      (Some(_), Some(_)) => ()
      _ => return false
    }
  }
  match (tree_node_children(old_tree), tree_node_children(next_tree)) {
    (Some(old_children), Some(next_children)) =>
      diff_tree_children(old_children, next_children, path, ops)
    _ => false
  }
}

///|
fn diff_miniapp_trees(old_tree : Json, next_tree : Json) -> TreeDiffResult {
  if old_tree == next_tree {
    return TreeDiffOk([])
  }
  let ops : Array[TreePatchOp] = []
  if diff_tree_node(old_tree, next_tree, [], ops) {
    TreeDiffOk(ops)
  } else {
    TreeDiffUnsafe
  }
}

///|
fn TreePatchOp::host_write_cost(self : TreePatchOp) -> Int {
  match self {
    SetTreeField(_, _) => 1
    SpliceTreeChildren(_, _, _, _) => 1
    MoveTreeChild(_, _, _, _, _) => 2
  }
}

///|
fn tree_patch_host_write_cost(ops : Array[TreePatchOp]) -> Int {
  let total = Ref(0)
  for op in ops {
    total.val = total.val + op.host_write_cost()
  }
  total.val
}

///|
fn should_use_tree_patch(
  patch_bytes : Int,
  replace_bytes : Int,
  host_write_cost : Int,
) -> Bool {
  patch_bytes * 4 <= replace_bytes * 3 && host_write_cost <= 32
}

///|
fn TreePatchOp::to_json(self : TreePatchOp) -> Json {
  match self {
    SetTreeField(path, value) =>
      Json::object({
        "op": Json::string("set"),
        "path": Json::array(path),
        "value": value,
      })
    SpliceTreeChildren(path, index, delete_count, items) =>
      Json::object({
        "op": Json::string("splice"),
        "path": Json::array(path),
        "index": Json::number(index.to_double(), repr=index.to_string()),
        "delete_count": Json::number(
          delete_count.to_double(),
          repr=delete_count.to_string(),
        ),
        "items": Json::array(items),
      })
    MoveTreeChild(path, from, to, identity, item) =>
      Json::object({
        "op": Json::string("move"),
        "path": Json::array(path),
        "from": Json::number(from.to_double(), repr=from.to_string()),
        "to": Json::number(to.to_double(), repr=to.to_string()),
        "identity": Json::string(identity),
        "item": item,
      })
  }
}

///|
fn tree_patch_ops_json(ops : Array[TreePatchOp]) -> String {
  Json::array(ops.map(op => op.to_json())).stringify()
}
