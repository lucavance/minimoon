///|
/// Renderer protocol v7 patch operations stay private to the MiniApp
/// renderer. Applications continue to author only Model, Msg, update, and
/// view; they never construct host mutations themselves.
priv enum TreePatchOp {
  SetTreeField(Array[Json], Json)
  SpliceTreeChildren(Array[Json], Int, Int, Array[Json])
  MoveTreeChild(Array[Json], Int, Int, String, Json)
}

///|
priv enum TreeDiffResult {
  TreeDiffOk(Array[TreePatchOp])
  TreeDiffUnsafe
}

///|
priv enum TreeChildrenKind {
  KeyedChildren
  UnkeyedChildren
  EmptyChildren
  InvalidChildren
}

///|
let tree_scalar_fields : Array[String] = ["text", "props", "events"]

///|
fn tree_path_copy(path : Array[Json]) -> Array[Json] {
  path.map(token => token)
}

///|
fn tree_path_field(path : Array[Json], field : String) -> Array[Json] {
  let next = tree_path_copy(path)
  next.push(Json::string(field))
  next
}

///|
fn tree_path_child(path : Array[Json], index : Int) -> Array[Json] {
  let next = tree_path_field(path, "children")
  next.push(Json::number(index.to_double(), repr=index.to_string()))
  next
}

///|
fn tree_node_string(node : Json, field : String) -> String? {
  match node {
    Object(fields) =>
      match fields.get(field) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
fn tree_node_field(node : Json, field : String) -> Json? {
  match node {
    Object(fields) => fields.get(field)
    _ => None
  }
}

///|
fn tree_node_children(node : Json) -> Array[Json]? {
  match node {
    Object(fields) =>
      match fields.get("children") {
        Some(Array(children)) => Some(children)
        _ => None
      }
    _ => None
  }
}

///|
fn tree_node_shape_matches(left : Json, right : Json) -> Bool {
  tree_node_string(left, "kind") == tree_node_string(right, "kind") &&
  tree_node_string(left, "identity") == tree_node_string(right, "identity")
}

///|
fn tree_child_identity(child : Json) -> String? {
  tree_node_string(child, "identity")
}

///|
fn tree_children_kind(children : Array[Json]) -> TreeChildrenKind {
  if children.length() == 0 {
    return EmptyChildren
  }
  let keyed = Ref(true)
  let unkeyed = Ref(true)
  let identities : Set[String] = Set([])
  for child in children {
    match tree_child_identity(child) {
      Some(identity) => {
        if !identity.has_prefix("k:") {
          keyed.val = false
        }
        if !identity.has_prefix("i:") {
          unkeyed.val = false
        }
        if identities.contains(identity) {
          return InvalidChildren
        }
        identities.add(identity)
      }
      None => return InvalidChildren
    }
  }
  if keyed.val {
    KeyedChildren
  } else if unkeyed.val {
    UnkeyedChildren
  } else {
    InvalidChildren
  }
}

///|
fn keyed_lis_identities_with_work(
  working : Array[String],
  next : Array[String],
) -> (Array[String], Int) {
  let positions : Map[String, Int] = Map([])
  for index = 0; index < working.length(); index = index + 1 {
    positions[working[index]] = index
  }
  let sequence_ids : Array[String] = []
  let sequence_positions : Array[Int] = []
  for identity in next {
    match positions.get(identity) {
      Some(position) => {
        sequence_ids.push(identity)
        sequence_positions.push(position)
      }
      None => ()
    }
  }
  if sequence_ids.length() == 0 {
    return ([], 0)
  }
  let previous = Array::makei(sequence_ids.length(), _ => -1)
  let tails : Array[Int] = []
  let tail_indices : Array[Int] = []
  let comparisons = Ref(0)
  for index = 0; index < sequence_ids.length(); index = index + 1 {
    let position = sequence_positions[index]
    let mut low = 0
    let mut high = tails.length()
    while low < high {
      comparisons.val += 1
      let middle = low + (high - low) / 2
      if tails[middle] < position {
        low = middle + 1
      } else {
        high = middle
      }
    }
    if low > 0 {
      previous[index] = tail_indices[low - 1]
    }
    if low == tails.length() {
      tails.push(position)
      tail_indices.push(index)
    } else {
      tails[low] = position
      tail_indices[low] = index
    }
  }
  let keep : Array[String] = []
  let cursor = Ref(tail_indices[tail_indices.length() - 1])
  while cursor.val >= 0 {
    keep.push(sequence_ids[cursor.val])
    cursor.val = previous[cursor.val]
  }
  (keep, comparisons.val)
}

///|
fn reindex_string_positions(
  values : Array[String],
  positions : Map[String, Int],
  start : Int,
) -> Unit {
  for index = start; index < values.length(); index = index + 1 {
    positions[values[index]] = index
  }
}

///|
fn append_tree_patch_ops(
  target : Array[TreePatchOp],
  source : Array[TreePatchOp],
) -> Unit {
  for op in source {
    target.push(op)
  }
}

///|
fn diff_unkeyed_children(
  old_children : Array[Json],
  next_children : Array[Json],
  path : Array[Json],
  ops : Array[TreePatchOp],
) -> Bool {
  if old_children.length() == next_children.length() {
    for index = 0; index < old_children.length(); index = index + 1 {
      let old_child = old_children[index]
      let next_child = next_children[index]
      if old_child != next_child {
        if tree_node_shape_matches(old_child, next_child) {
          guard diff_tree_node(
            old_child,
            next_child,
            tree_path_child(path, index),
            ops,
          ) else {
            return false
          }
        } else {
          ops.push(
            SpliceTreeChildren(tree_path_field(path, "children"), index, 1, [
              next_child,
            ]),
          )
        }
      }
    }
    return true
  }
  let prefix = Ref(0)
  let common = if old_children.length() < next_children.length() {
    old_children.length()
  } else {
    next_children.length()
  }
  while prefix.val < common &&
        old_children[prefix.val] == next_children[prefix.val] {
    prefix.val = prefix.val + 1
  }
  let items : Array[Json] = []
  for index = prefix.val; index < next_children.length(); index = index + 1 {
    items.push(next_children[index])
  }
  ops.push(
    SpliceTreeChildren(
      tree_path_field(path, "children"),
      prefix.val,
      old_children.length() - prefix.val,
      items,
    ),
  )
  true
}
