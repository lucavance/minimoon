///|
using @test {assert_eq}

///|
fn patch_test_node(
  kind : String,
  identity : String,
  text : String,
  children : Array[Json],
) -> Json {
  Json::object({
    "kind": Json::string(kind),
    "identity": Json::string(identity),
    "text": Json::string(text),
    "props": Json::empty_object(),
    "events": Json::empty_object(),
    "children": Json::array(children),
  })
}

///|
fn patch_test_index(token : Json) -> Int {
  match token {
    Number(value, ..) => value.to_int()
    _ => abort("expected numeric tree path token")
  }
}

///|
fn patch_test_resolve(root : Json, path : Array[Json]) -> Json {
  let current = Ref(root)
  for token in path {
    current.val = match (current.val, token) {
      (Object(fields), String(key)) => fields[key]
      (Array(items), Number(value, ..)) => items[value.to_int()]
      _ => abort("invalid patch test path")
    }
  }
  current.val
}

///|
fn patch_test_set(root : Json, path : Array[Json], value : Json) -> Unit {
  guard path.length() > 0 else { abort("patch test path must not be empty") }
  let parent_path : Array[Json] = []
  for index = 0; index < path.length() - 1; index = index + 1 {
    parent_path.push(path[index])
  }
  let parent = patch_test_resolve(root, parent_path)
  match (parent, path[path.length() - 1]) {
    (Object(fields), String(key)) => fields[key] = value
    (Array(items), token) => items[patch_test_index(token)] = value
    _ => abort("invalid patch test assignment")
  }
}

///|
fn patch_test_apply(old_tree : Json, ops : Array[TreePatchOp]) -> Json {
  let tree = @json.parse(old_tree.stringify()) catch {
    err => abort("could not clone patch test tree: \{err}")
  }
  for op in ops {
    match op {
      SetTreeField(path, value) => patch_test_set(tree, path, value)
      SpliceTreeChildren(path, index, delete_count, items) =>
        match patch_test_resolve(tree, path) {
          Array(target) => {
            for removed = 0; removed < delete_count; removed = removed + 1 {
              let _ = target.remove(index)
            }
            for offset = 0; offset < items.length(); offset = offset + 1 {
              target.insert(index + offset, items[offset])
            }
          }
          _ => abort("splice target must be an array")
        }
      MoveTreeChild(path, from, to, _identity, item) =>
        match patch_test_resolve(tree, path) {
          Array(target) => {
            let _ = target.remove(from)
            target.insert(to, item)
          }
          _ => abort("move target must be an array")
        }
    }
  }
  tree
}

///|
fn patch_test_diff(old_tree : Json, next_tree : Json) -> Array[TreePatchOp] {
  match diff_miniapp_trees(old_tree, next_tree) {
    TreeDiffOk(ops) => ops
    TreeDiffUnsafe => abort("expected a safe tree diff")
  }
}

///|
fn patch_test_numbered_child(index : Int, text : String) -> Json {
  patch_test_node("button", "k:" + index.to_string(), text, [])
}

///|
fn patch_test_numbered_children(count : Int) -> Array[Json] {
  Array::makei(count, index => {
    patch_test_numbered_child(index, index.to_string())
  })
}

///|
fn patch_test_focused_input(value : String) -> Json {
  Json::object({
    "kind": Json::string("input"),
    "identity": Json::string("k:focus-probe"),
    "text": Json::string(""),
    "props": Json::object({ "value": Json::string(value) }),
    "events": Json::object({ "input": Json::string("dynamic/name") }),
    "children": Json::array([]),
  })
}

///|
test "renderer v6 scalar patch reconstructs the exact next tree" {
  let old_tree = patch_test_node("view", "root", "", [
    patch_test_node("text", "i:0", "A", []),
  ])
  let next_tree = patch_test_node("view", "root", "", [
    patch_test_node("text", "i:0", "B", []),
  ])
  let ops = patch_test_diff(old_tree, next_tree)
  assert_eq(ops.length(), 1)
  assert_eq(tree_patch_host_write_cost(ops), 1)
  assert_eq(tree_patch_ops_json(ops).contains("\"op\":\"set\""), true)
  assert_eq(patch_test_apply(old_tree, ops), next_tree)
}

///|
test "renderer v6 keyed LIS diff emits a move and preserves exact order" {
  let old_tree = patch_test_node("fragment", "root", "", [
    patch_test_node("button", "k:a", "A", []),
    patch_test_node("button", "k:b", "B", []),
    patch_test_node("button", "k:c", "C", []),
  ])
  let next_tree = patch_test_node("fragment", "root", "", [
    patch_test_node("button", "k:c", "C", []),
    patch_test_node("button", "k:a", "A", []),
    patch_test_node("button", "k:b", "B", []),
  ])
  let ops = patch_test_diff(old_tree, next_tree)
  assert_eq(tree_patch_ops_json(ops).contains("\"op\":\"move\""), true)
  assert_eq(tree_patch_host_write_cost(ops), 2)
  assert_eq(patch_test_apply(old_tree, ops), next_tree)
}

///|
test "keyed focus probe moves only the nonfocused identity" {
  let old_tree = patch_test_node("fragment", "root", "", [
    patch_test_focused_input("Minimoon cursor probe"),
    patch_test_node("button", "k:a", "A", []),
    patch_test_node("button", "k:b", "B", []),
    patch_test_node("button", "k:c", "C", []),
  ])
  let next_tree = patch_test_node("fragment", "root", "", [
    patch_test_focused_input("Minimoon cursor probe"),
    patch_test_node("button", "k:c", "C", []),
    patch_test_node("button", "k:a", "A", []),
    patch_test_node("button", "k:b", "B", []),
  ])
  let ops = patch_test_diff(old_tree, next_tree)
  assert_eq(ops.length(), 1)
  match ops[0] {
    MoveTreeChild(_, from, to, identity, _) => {
      assert_eq(from, 3)
      assert_eq(to, 1)
      assert_eq(identity, "k:c")
    }
    _ => fail("expected exactly one keyed move")
  }
  let encoded = tree_patch_ops_json(ops)
  assert_eq(encoded.contains("k:focus-probe"), false)
  assert_eq(tree_patch_host_write_cost(ops), 2)
  assert_eq(patch_test_apply(old_tree, ops), next_tree)
}

///|
test "renderer v6 keyed diff composes remove insert move and nested set" {
  let old_tree = patch_test_node("fragment", "root", "", [
    patch_test_node("button", "k:a", "A", []),
    patch_test_node("button", "k:b", "B", []),
    patch_test_node("button", "k:c", "C", []),
    patch_test_node("button", "k:d", "D", []),
  ])
  let next_tree = patch_test_node("fragment", "root", "", [
    patch_test_node("button", "k:d", "D updated", []),
    patch_test_node("button", "k:b", "B moved", []),
    patch_test_node("button", "k:e", "E inserted", []),
  ])
  let ops = patch_test_diff(old_tree, next_tree)
  let encoded = tree_patch_ops_json(ops)
  assert_eq(encoded.contains("\"op\":\"set\""), true)
  assert_eq(encoded.contains("\"op\":\"splice\""), true)
  assert_eq(encoded.contains("\"op\":\"move\""), true)
  assert_eq(patch_test_apply(old_tree, ops), next_tree)
}

///|
test "renderer v6 unkeyed length change replaces only the changed tail" {
  let old_tree = patch_test_node("fragment", "root", "", [
    patch_test_node("text", "i:0", "A", []),
  ])
  let next_tree = patch_test_node("fragment", "root", "", [
    patch_test_node("text", "i:0", "A", []),
    patch_test_node("text", "i:1", "B", []),
  ])
  let ops = patch_test_diff(old_tree, next_tree)
  assert_eq(tree_patch_ops_json(ops).contains("\"op\":\"splice\""), true)
  assert_eq(patch_test_apply(old_tree, ops), next_tree)
}

///|
test "renderer v6 rejects a root shape change" {
  let old_tree = patch_test_node("view", "root", "", [])
  let next_tree = patch_test_node("fragment", "root", "", [])
  assert_eq(diff_miniapp_trees(old_tree, next_tree) is TreeDiffUnsafe, true)
}

///|
test "renderer v6 patch policy accepts the exact 25 percent boundary" {
  assert_eq(should_use_tree_patch(75, 100, 32), true)
  assert_eq(should_use_tree_patch(76, 100, 1), false)
  assert_eq(should_use_tree_patch(1, 100, 33), false)
}

///|
test "keyed LIS work stays n log n through two thousand identities" {
  for count in [100, 500, 2000] {
    let identities = Array::makei(count, index => "k:" + index.to_string())
    let (keep, comparisons) = keyed_lis_identities_with_work(
      identities, identities,
    )
    assert_eq(keep.length(), count)
    assert_eq(comparisons <= count * 12, true)
  }
}

///|
test "keyed rotation reconstructs 100 500 and 2000 child trees" {
  for count in [100, 500, 2000] {
    let old_children = patch_test_numbered_children(count)
    let next_children : Array[Json] = [old_children[count - 1]]
    for index = 0; index < count - 1; index = index + 1 {
      next_children.push(old_children[index])
    }
    let old_tree = patch_test_node("fragment", "root", "", old_children)
    let next_tree = patch_test_node("fragment", "root", "", next_children)
    let ops = patch_test_diff(old_tree, next_tree)
    assert_eq(tree_patch_host_write_cost(ops), 2)
    assert_eq(patch_test_apply(old_tree, ops), next_tree)
  }
}

///|
test "large keyed reverse exits through the bounded replacement policy" {
  let old_children = patch_test_numbered_children(2000)
  let next_children : Array[Json] = []
  for index = old_children.length() - 1; index >= 0; index = index - 1 {
    next_children.push(old_children[index])
  }
  let old_tree = patch_test_node("fragment", "root", "", old_children)
  let next_tree = patch_test_node("fragment", "root", "", next_children)
  assert_eq(diff_miniapp_trees(old_tree, next_tree) is TreeDiffUnsafe, true)
}
