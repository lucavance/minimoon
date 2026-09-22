///|
fn keyed_growth_sequences() -> Array[Array[String]] {
  let output : Array[Array[String]] = []
  fn visit(prefix : Array[String], remaining : Array[String]) -> Unit {
    output.push(prefix.copy())
    for index, identity in remaining {
      let next = prefix.copy()
      next.push(identity)
      let rest = remaining.copy()
      ignore(rest.remove(index))
      visit(next, rest)
    }
  }
  visit([], ["a", "b", "c", "d"])
  output
}

///|
fn keyed_growth_tree(
  identities : Array[String],
  version : Int,
  reshape : Bool,
) -> Json {
  patch_test_node(
    "fragment",
    "root",
    "",
    identities.map(identity => {
      let children = if reshape && (identity == "b" || identity == "d") {
        [patch_test_node("text", "i:0", "nested-" + identity, [])]
      } else {
        []
      }
      let node = patch_test_node(
        if children.is_empty() {
          "text"
        } else {
          "view"
        },
        "k:" + identity,
        identity + ":" + version.to_string(),
        children,
      )
      if node is Object(fields) {
        fields["props"] = { "class": "version-" + version.to_string() }
      }
      node
    }),
  )
}

///|
fn assert_valid_keyed_patch(
  old_tree : Json,
  next_tree : Json,
  ops : Array[TreePatchOp],
) -> Unit raise {
  let mut shadow = old_tree
  for op in ops {
    match op {
      SetTreeField(_, _) => ()
      SpliceTreeChildren(path, index, delete_count, _) => {
        guard patch_test_resolve(shadow, path) is Array(children) else {
          fail("splice must address an array")
        }
        assert_true(index >= 0 && index <= children.length())
        assert_true(
          delete_count >= 0 && index + delete_count <= children.length(),
        )
      }
      MoveTreeChild(path, from, to, identity, item) => {
        guard patch_test_resolve(shadow, path) is Array(children) else {
          fail("move must address an array")
        }
        assert_true(from >= 0 && from < children.length())
        assert_true(to >= 0 && to < children.length() && from != to)
        assert_eq(tree_child_identity(children[from]), Some(identity))
        assert_eq(tree_child_identity(item), Some(identity))
      }
    }
    shadow = patch_test_apply(shadow, [op])
  }
  assert_eq(shadow, next_tree)
}

///|
test "keyed diff reconstructs every pair of four-identity ordered subsets" {
  let sequences = keyed_growth_sequences()
  assert_eq(sequences.length(), 65)
  let mut pairs = 0
  for old_ids in sequences {
    for next_ids in sequences {
      pairs += 1
      for reshape in [false, true] {
        let old_tree = keyed_growth_tree(old_ids, 0, false)
        let next_tree = keyed_growth_tree(next_ids, 1, reshape)
        let ops = patch_test_diff(old_tree, next_tree)
        assert_valid_keyed_patch(old_tree, next_tree, ops)
      }
    }
  }
  assert_eq(pairs, 4225)
}

///|
test "keyed growth preserves the structural write budget boundary" {
  let empty = patch_test_node("fragment", "root", "", [])
  let accepted = patch_test_node(
    "fragment",
    "root",
    "",
    patch_test_numbered_children(32),
  )
  let ops = patch_test_diff(empty, accepted)
  assert_eq(tree_patch_host_write_cost(ops), 32)
  assert_valid_keyed_patch(empty, accepted, ops)
  let replaced = patch_test_node(
    "fragment",
    "root",
    "",
    patch_test_numbered_children(33),
  )
  assert_true(diff_miniapp_trees(empty, replaced) is TreeDiffUnsafe)
}

///|
test "large keyed collections accept bounded additions at both ends" {
  for count in [100, 500, 2000] {
    let old_children = patch_test_numbered_children(count)
    let next_children = [
      patch_test_numbered_child(count, "new head 1"),
      patch_test_numbered_child(count + 1, "new head 2"),
      ..old_children,
      patch_test_numbered_child(count + 2, "new tail 1"),
      patch_test_numbered_child(count + 3, "new tail 2"),
    ]
    let old_tree = patch_test_node("fragment", "root", "", old_children)
    let next_tree = patch_test_node("fragment", "root", "", next_children)
    let ops = patch_test_diff(old_tree, next_tree)
    assert_eq(tree_patch_host_write_cost(ops), 4)
    assert_valid_keyed_patch(old_tree, next_tree, ops)
  }
}
