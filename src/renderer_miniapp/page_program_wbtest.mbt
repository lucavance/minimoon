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
