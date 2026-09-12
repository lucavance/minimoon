///|
fn retained_keyed_tree(
  root_id : Int,
  count : Int,
  changed_index? : Int = -1,
  reverse? : Bool = false,
) -> @ui.Node {
  let children : Array[@ui.KeyedNode] = []
  for offset = 0; offset < count; offset = offset + 1 {
    let index = if reverse { count - offset - 1 } else { offset }
    let node_id = if index == changed_index {
      100000 + index
    } else {
      1000 + index
    }
    let text = if index == changed_index {
      "changed-" + index.to_string()
    } else {
      "value-" + index.to_string()
    }
    children.push(
      @ui.keyed(
        "key-" + index.to_string(),
        @ui.retained(node_id, @ui.text(text)),
      ),
    )
  }
  @ui.retained(root_id, @ui.keyed_fragment(children))
}

///|
test "retained normalization visits only changed nodes and commits cache transactionally" {
  let events : Map[String, PageEvent[Unit]] = Map([])
  let entries : Ref[Map[String, NormalizedCacheEntry]] = Ref(Map([]))
  let roots : Ref[Array[String]] = Ref([])
  let initial = normalize_miniapp_tree_cached_checked(
    retained_keyed_tree(1, 2000),
    events,
    entries.val,
  ).unwrap()
  assert_eq(initial.work.node_visits, 2001)
  assert_eq(initial.work.cache_hits, 0)
  assert_eq(initial.updates.length(), 2001)
  commit_normalized_candidate(initial, entries, roots)
  assert_eq(entries.val.length(), 2001)

  let unchanged = normalize_miniapp_tree_cached_checked(
    retained_keyed_tree(1, 2000),
    events,
    entries.val,
  ).unwrap()
  assert_eq(unchanged.work.node_visits, 0)
  assert_eq(unchanged.work.cache_hits, 1)
  assert_eq(unchanged.updates.length(), 0)

  let changed = normalize_miniapp_tree_cached_checked(
    retained_keyed_tree(2, 2000, changed_index=777),
    events,
    entries.val,
  ).unwrap()
  assert_eq(changed.work.node_visits, 2)
  assert_eq(changed.work.cache_hits, 1999)
  assert_eq(changed.updates.length(), 2)
  assert_eq(changed.tree.stringify().contains("changed-777"), true)
  commit_normalized_candidate(changed, entries, roots)
  assert_eq(entries.val.length(), 2001)

  let reordered = normalize_miniapp_tree_cached_checked(
    retained_keyed_tree(3, 2000, changed_index=777, reverse=true),
    events,
    entries.val,
  ).unwrap()
  assert_eq(reordered.work.node_visits, 1)
  assert_eq(reordered.work.cache_hits, 2000)
  assert_eq(reordered.updates.length(), 1)
  commit_normalized_candidate(reordered, entries, roots)
  assert_eq(entries.val.length(), 2001)
}

///|
fn retained_shape_tree(
  root_id : Int,
  a : @ui.Node?,
  last? : Bool = false,
) -> @ui.Node {
  let children = [
    @ui.keyed("b", @ui.retained(2, @ui.text("B"))),
    @ui.keyed("c", @ui.retained(3, @ui.text("C"))),
  ]
  if a is Some(a) {
    children.insert(if last { 2 } else { 0 }, @ui.keyed("a", a))
  }
  @ui.retained(root_id, @ui.keyed_fragment(children))
}

///|
test "retained keyed shape changes reuse siblings and prune removed descendants" {
  let events : Map[String, PageEvent[Unit]] = Map([])
  let event_list : Array[PageEvent[Unit]] = []
  let entries : Ref[Map[String, NormalizedCacheEntry]] = Ref(Map([]))
  let roots : Ref[Array[String]] = Ref([])
  let a_path = keyed_normalization_path("root", "a")
  let a_child_path = indexed_normalization_path(a_path, 0)
  let b_key = retained_cache_key(2, keyed_normalization_path("root", "b"))
  let c_key = retained_cache_key(3, keyed_normalization_path("root", "c"))
  let shapes = [
    @ui.retained(10, @ui.nothing()),
    @ui.retained(20, @ui.fragment([])),
    @ui.retained(
      30,
      @ui.fragment([@ui.retained(31, @ui.text("fragment child"))]),
    ),
    @ui.retained(40, @ui.text("plain text")),
    @ui.retained(
      50,
      @ui.element("view", children=[@ui.retained(51, @ui.text("view child"))]),
    ),
  ]
  for index = 0; index < shapes.length(); index = index + 1 {
    let a_id = (index + 1) * 10
    let nested_count = if index == 2 || index == 4 { 1 } else { 0 }
    let source = retained_shape_tree(100 + index * 3, Some(shapes[index]))
    let candidate = normalize_miniapp_tree_cached_checked(
      source,
      events,
      entries.val,
    ).unwrap()
    assert_eq(
      candidate.tree,
      normalize_miniapp_tree_checked(source, event_list).unwrap(),
    )
    assert_eq(candidate.work.cache_hits, if index == 0 { 0 } else { 2 })
    assert_eq(
      candidate.work.node_visits,
      (if index == 0 { 4 } else { 2 }) + nested_count,
    )
    commit_normalized_candidate(candidate, entries, roots)
    assert_eq(entries.val.length(), 4 + nested_count)
    assert_true(entries.val.contains(retained_cache_key(a_id, a_path)))
    assert_true(entries.val.contains(b_key))
    assert_true(entries.val.contains(c_key))
    if index > 0 {
      assert_eq(
        entries.val.contains(retained_cache_key(a_id - 10, a_path)),
        false,
      )
    }
    if index == 3 {
      assert_eq(
        entries.val.contains(retained_cache_key(31, a_child_path)),
        false,
      )
    }

    for offset in [1, 2] {
      let reordered = retained_shape_tree(
        100 + index * 3 + offset,
        Some(shapes[index]),
        last=offset == 1,
      )
      let candidate = normalize_miniapp_tree_cached_checked(
        reordered,
        events,
        entries.val,
      ).unwrap()
      assert_eq(
        candidate.tree,
        normalize_miniapp_tree_checked(reordered, event_list).unwrap(),
      )
      assert_eq(candidate.work.node_visits, 1)
      assert_eq(candidate.work.cache_hits, 3)
      commit_normalized_candidate(candidate, entries, roots)
      assert_eq(entries.val.length(), 4 + nested_count)
      if nested_count == 1 {
        assert_true(
          entries.val.contains(retained_cache_key(a_id + 1, a_child_path)),
        )
      }
    }
  }

  let removed = retained_shape_tree(200, None)
  let candidate = normalize_miniapp_tree_cached_checked(
    removed,
    events,
    entries.val,
  ).unwrap()
  assert_eq(
    candidate.tree,
    normalize_miniapp_tree_checked(removed, event_list).unwrap(),
  )
  assert_eq(candidate.work.node_visits, 1)
  assert_eq(candidate.work.cache_hits, 2)
  commit_normalized_candidate(candidate, entries, roots)
  assert_eq(entries.val.length(), 3)
  assert_eq(entries.val.contains(retained_cache_key(50, a_path)), false)
  assert_eq(entries.val.contains(retained_cache_key(51, a_child_path)), false)
  assert_true(entries.val.contains(b_key))
  assert_true(entries.val.contains(c_key))

  let remounted = retained_shape_tree(
    201,
    Some(
      @ui.retained(
        60,
        @ui.fragment([@ui.retained(61, @ui.text("remounted child"))]),
      ),
    ),
    last=true,
  )
  let candidate = normalize_miniapp_tree_cached_checked(
    remounted,
    events,
    entries.val,
  ).unwrap()
  assert_eq(
    candidate.tree,
    normalize_miniapp_tree_checked(remounted, event_list).unwrap(),
  )
  assert_eq(candidate.work.node_visits, 3)
  assert_eq(candidate.work.cache_hits, 2)
  commit_normalized_candidate(candidate, entries, roots)
  assert_eq(entries.val.length(), 5)
  assert_true(entries.val.contains(retained_cache_key(60, a_path)))
  assert_true(entries.val.contains(retained_cache_key(61, a_child_path)))
  assert_true(entries.val.contains(b_key))
  assert_true(entries.val.contains(c_key))
}

///|
test "rejected retained normalization leaves the committed cache authoritative" {
  let events : Map[String, PageEvent[Unit]] = Map([])
  let entries : Ref[Map[String, NormalizedCacheEntry]] = Ref(Map([]))
  let roots : Ref[Array[String]] = Ref([])
  let initial = normalize_miniapp_tree_cached_checked(
    retained_keyed_tree(10, 8),
    events,
    entries.val,
  ).unwrap()
  commit_normalized_candidate(initial, entries, roots)
  let committed_entries = entries.val.length()
  let committed_roots = roots.val.copy()
  let rejected = normalize_miniapp_tree_cached_checked(
    @ui.retained(
      11,
      @ui.element("unsupported", children=[
        @ui.retained(999999, @ui.text("candidate")),
      ]),
    ),
    events,
    entries.val,
  )
  assert_eq(rejected is Err(_), true)
  assert_eq(entries.val.length(), committed_entries)
  assert_eq(roots.val, committed_roots)
}

///|
test "initial contract tree reads do not rerun the page view" {
  let renders = Ref(0)
  let program = simple_page_program(
    id="initial_tree",
    route="pages/initial_tree/initial_tree",
    title="Initial tree",
    model=0,
    update=(current, _message : Unit) => current,
    view=(_, current) => {
      renders.val += 1
      @ui.text(current.to_string())
    },
  )
  let after_create = renders.val
  assert_eq(
    program.initial_tree(),
    Json::object({
      "kind": Json::string("text"),
      "identity": Json::string("root"),
      "text": Json::string("0"),
      "props": Json::empty_object(),
      "events": Json::empty_object(),
      "children": Json::array([]),
    }),
  )
  let _ = program.initial_tree()
  let _ = program.contract_json()
  assert_eq(renders.val, after_create)
}
