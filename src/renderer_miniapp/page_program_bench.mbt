///|
fn performance_tree_node(
  identity : String,
  text : String,
  children : Array[Json],
) -> Json {
  Json::object({
    "kind": Json::string(
      if children.length() == 0 {
        "text"
      } else {
        "fragment"
      },
    ),
    "identity": Json::string(identity),
    "text": Json::string(text),
    "props": Json::empty_object(),
    "events": Json::empty_object(),
    "children": Json::array(children),
  })
}

///|
fn performance_tree(
  count : Int,
  changed_index? : Int = -1,
  rotate? : Bool = false,
) -> Json {
  let children : Array[Json] = []
  for offset = 0; offset < count; offset = offset + 1 {
    let index = if rotate { (offset + 1) % count } else { offset }
    children.push(
      performance_tree_node(
        "k:item-" + index.to_string(),
        if index == changed_index {
          "changed"
        } else {
          "value-" + index.to_string()
        },
        [],
      ),
    )
  }
  performance_tree_node("root", "", children)
}

///|
fn bench_scalar_diff(b : @bench.T, count : Int) -> Unit {
  let old_tree = performance_tree(count)
  let next_tree = performance_tree(count, changed_index=count / 2)
  b.bench(fn() { b.keep(diff_miniapp_trees(old_tree, next_tree)) })
}

///|
fn bench_keyed_reorder(b : @bench.T, count : Int) -> Unit {
  let old_tree = performance_tree(count)
  let next_tree = performance_tree(count, rotate=true)
  b.bench(fn() { b.keep(diff_miniapp_trees(old_tree, next_tree)) })
}

///|
fn quadratic_keyed_lis_reference(
  working : Array[String],
  next : Array[String],
) -> Array[String] {
  let sequence_ids : Array[String] = []
  let positions : Array[Int] = []
  for identity in next {
    for index = 0; index < working.length(); index = index + 1 {
      if working[index] == identity {
        sequence_ids.push(identity)
        positions.push(index)
        break
      }
    }
  }
  if positions.length() == 0 {
    return []
  }
  let lengths = Array::makei(positions.length(), _ => 1)
  let previous = Array::makei(positions.length(), _ => -1)
  let best = Ref(0)
  for index = 0; index < positions.length(); index = index + 1 {
    for before = 0; before < index; before = before + 1 {
      if positions[before] < positions[index] &&
        lengths[before] + 1 > lengths[index] {
        lengths[index] = lengths[before] + 1
        previous[index] = before
      }
    }
    if lengths[index] > lengths[best.val] {
      best.val = index
    }
  }
  let keep : Array[String] = []
  let cursor = Ref(best.val)
  while cursor.val >= 0 {
    keep.push(sequence_ids[cursor.val])
    cursor.val = previous[cursor.val]
  }
  keep
}

///|
fn performance_identities(count : Int, rotate : Bool) -> Array[String] {
  Array::makei(count, offset => {
    let index = if rotate { (offset + 1) % count } else { offset }
    "item-" + index.to_string()
  })
}

///|
fn bench_quadratic_lis_reference(b : @bench.T, count : Int) -> Unit {
  let working = performance_identities(count, false)
  let next = performance_identities(count, true)
  b.bench(fn() { b.keep(quadratic_keyed_lis_reference(working, next)) })
}

///|
fn bench_indexed_lis(b : @bench.T, count : Int) -> Unit {
  let working = performance_identities(count, false)
  let next = performance_identities(count, true)
  b.bench(fn() { b.keep(keyed_lis_identities_with_work(working, next)) })
}

///|
fn performance_program_with_guard(
  count : Int,
  projection_guard? : @runtime.ProjectionGuard[Int],
) -> PageProgram[Int, Int] {
  page_program(
    id="perf_" + count.to_string(),
    route="pages/perf_" + count.to_string() + "/perf_" + count.to_string(),
    title="Performance " + count.to_string(),
    model=0,
    update=(model, _) => @runtime.no_cmd(model),
    projection_guard?,
    view=(events, _) => {
      let children : Array[@ui.KeyedNode] = []
      for index = 0; index < count; index = index + 1 {
        let event = events.tap("event-" + index.to_string(), index)
        children.push(
          @ui.keyed(
            "item-" + index.to_string(),
            @ui.element("button", attrs=[@ui.attr("on_click", event.key())], children=[
              @ui.text("item-" + index.to_string()),
            ]),
          ),
        )
      }
      @ui.keyed_fragment(children)
    },
  )
}

///|
fn performance_program(count : Int) -> PageProgram[Int, Int] {
  performance_program_with_guard(count, projection_guard=(previous, next) => {
    previous != next
  })
}

///|
fn bench_event_lookup(b : @bench.T, count : Int) -> Unit {
  let program = performance_program(count)
  let key = "event-" + (count - 1).to_string()
  let payload = Json::empty_object()
  b.bench(fn() { b.keep(program.decode_event(key, payload)) })
}

///|
fn bench_noop_dispatch(b : @bench.T, count : Int) -> Unit {
  let runtime = performance_program(count).create_runtime()
  let _ = runtime.mount()
  let key = "event-" + (count - 1).to_string()
  b.bench(fn() { b.keep(runtime.dispatch(key, "{}")) })
  let _ = runtime.dispose()
}

///|
fn bench_unsuppressed_noop_dispatch(b : @bench.T, count : Int) -> Unit {
  let runtime = performance_program_with_guard(count).create_runtime()
  let _ = runtime.mount()
  let key = "event-" + (count - 1).to_string()
  b.bench(fn() { b.keep(runtime.dispatch(key, "{}")) })
  let _ = runtime.dispose()
}

///|
fn bench_create_mount(b : @bench.T, count : Int) -> Unit {
  let program = performance_program(count)
  b.bench(fn() {
    let runtime = program.create_runtime()
    b.keep(runtime.mount())
    b.keep(runtime.dispose())
  })
}

///|
fn performance_retained_tree(
  root_id : Int,
  count : Int,
  changed_index? : Int = -1,
) -> @ui.Node {
  let children : Array[@ui.KeyedNode] = []
  for index = 0; index < count; index = index + 1 {
    children.push(
      @ui.keyed(
        "item-" + index.to_string(),
        @ui.retained(
          if index == changed_index {
            100000 + index
          } else {
            1000 + index
          },
          @ui.text(if index == changed_index { "changed" } else { "value" }),
        ),
      ),
    )
  }
  @ui.retained(root_id, @ui.keyed_fragment(children))
}

///|
fn bench_full_normalization(b : @bench.T, count : Int) -> Unit {
  let events : Array[PageEvent[Unit]] = []
  let candidate = performance_retained_tree(2, count, changed_index=count / 2)
  b.bench(fn() { b.keep(normalize_miniapp_tree_checked(candidate, events)) })
}

///|
fn bench_retained_normalization(b : @bench.T, count : Int) -> Unit {
  let events : Map[String, PageEvent[Unit]] = Map([])
  let entries : Ref[Map[String, NormalizedCacheEntry]] = Ref(Map([]))
  let roots : Ref[Array[String]] = Ref([])
  let initial = normalize_miniapp_tree_cached_checked(
    performance_retained_tree(1, count),
    events,
    entries.val,
  ).unwrap()
  commit_normalized_candidate(initial, entries, roots)
  let candidate = performance_retained_tree(2, count, changed_index=count / 2)
  b.bench(fn() {
    b.keep(
      normalize_miniapp_tree_cached_checked(candidate, events, entries.val),
    )
  })
}

///|
test "scalar diff 100 nodes" (b : @bench.T) {
  bench_scalar_diff(b, 100)
}

///|
test "scalar diff 500 nodes" (b : @bench.T) {
  bench_scalar_diff(b, 500)
}

///|
test "scalar diff 2000 nodes" (b : @bench.T) {
  bench_scalar_diff(b, 2000)
}

///|
test "keyed reorder 100 nodes" (b : @bench.T) {
  bench_keyed_reorder(b, 100)
}

///|
test "keyed reorder 500 nodes" (b : @bench.T) {
  bench_keyed_reorder(b, 500)
}

///|
test "keyed reorder 2000 nodes" (b : @bench.T) {
  bench_keyed_reorder(b, 2000)
}

///|
test "event lookup 100 bindings" (b : @bench.T) {
  bench_event_lookup(b, 100)
}

///|
test "event lookup 500 bindings" (b : @bench.T) {
  bench_event_lookup(b, 500)
}

///|
test "event lookup 2000 bindings" (b : @bench.T) {
  bench_event_lookup(b, 2000)
}

///|
test "no-op dispatch 100 nodes" (b : @bench.T) {
  bench_noop_dispatch(b, 100)
}

///|
test "no-op dispatch 500 nodes" (b : @bench.T) {
  bench_noop_dispatch(b, 500)
}

///|
test "no-op dispatch 2000 nodes" (b : @bench.T) {
  bench_noop_dispatch(b, 2000)
}

///|
test "create mount 100 nodes" (b : @bench.T) {
  bench_create_mount(b, 100)
}

///|
test "create mount 500 nodes" (b : @bench.T) {
  bench_create_mount(b, 500)
}

///|
test "create mount 2000 nodes" (b : @bench.T) {
  bench_create_mount(b, 2000)
}

///|
test "full normalization 100 nodes" (b : @bench.T) {
  bench_full_normalization(b, 100)
}

///|
test "full normalization 500 nodes" (b : @bench.T) {
  bench_full_normalization(b, 500)
}

///|
test "full normalization 2000 nodes" (b : @bench.T) {
  bench_full_normalization(b, 2000)
}

///|
test "retained leaf normalization 100 nodes" (b : @bench.T) {
  bench_retained_normalization(b, 100)
}

///|
test "retained leaf normalization 500 nodes" (b : @bench.T) {
  bench_retained_normalization(b, 500)
}

///|
test "retained leaf normalization 2000 nodes" (b : @bench.T) {
  bench_retained_normalization(b, 2000)
}

///|
test "quadratic keyed LIS reference 100 nodes" (b : @bench.T) {
  bench_quadratic_lis_reference(b, 100)
}

///|
test "quadratic keyed LIS reference 500 nodes" (b : @bench.T) {
  bench_quadratic_lis_reference(b, 500)
}

///|
test "quadratic keyed LIS reference 2000 nodes" (b : @bench.T) {
  bench_quadratic_lis_reference(b, 2000)
}

///|
test "indexed keyed LIS 100 nodes" (b : @bench.T) {
  bench_indexed_lis(b, 100)
}

///|
test "indexed keyed LIS 500 nodes" (b : @bench.T) {
  bench_indexed_lis(b, 500)
}

///|
test "indexed keyed LIS 2000 nodes" (b : @bench.T) {
  bench_indexed_lis(b, 2000)
}

///|
test "unsuppressed no-op reference 100 nodes" (b : @bench.T) {
  bench_unsuppressed_noop_dispatch(b, 100)
}

///|
test "unsuppressed no-op reference 500 nodes" (b : @bench.T) {
  bench_unsuppressed_noop_dispatch(b, 500)
}

///|
test "unsuppressed no-op reference 2000 nodes" (b : @bench.T) {
  bench_unsuppressed_noop_dispatch(b, 2000)
}
