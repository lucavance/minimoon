///|
fn layer_test_json(raw : String) -> Json {
  @json.parse(raw) catch {
    _ => abort("invalid JSON")
  }
}

///|
fn layer_test_find(value : Json, id : String) -> Json? {
  if value is Object(fields) {
    if fields.get("props") is Some(Object(props)) &&
      props.get("id") == Some(Json::string(id)) {
      return Some(value)
    }
    if fields.get("tree") is Some(tree) {
      return layer_test_find(tree, id)
    }
    if fields.get("children") is Some(Array(children)) {
      for child in children {
        if layer_test_find(child, id) is Some(found) {
          return Some(found)
        }
      }
    }
  }
  None
}

///|
fn layer_test_children(value : Json) -> Array[Json] {
  guard value is Object(fields) &&
    fields.get("children") is Some(Array(children)) else {
    abort("node children required")
  }
  children
}

///|
fn layer_test_event(runtime : PageRuntime, id : String) -> String {
  guard layer_test_find(layer_test_json(runtime.snapshot()), id)
    is Some(Object(fields)) &&
    fields.get("events") is Some(Object(events)) &&
    events.get("tap") is Some(String(key)) else {
    abort("missing tap")
  }
  key
}

///|
test "layers lift nested surfaces parent first outside clipped containers and preserve event bindings" {
  let runtime = page(
    id="layer_test",
    route=route("pages/layers/index"),
    title="Layers",
    build=_ => {
      let (value, emit) = create_variable(0)
      value.view(value => {
        layer_root(id="root", [
          div(id="clipped", style="overflow:hidden;", [
            text("body"),
            layer(id="parent", [
              button(
                id="parent-action",
                on_tap=emit(value => value + 1),
                "parent",
              ),
              layer(
                id="child",
                button(
                  event_key="child-action",
                  on_tap=emit(value => value + 10),
                  "child",
                ),
              ),
            ]),
          ]),
          layer(id="sibling", text("sibling")),
          text("value:" + value.to_string()),
        ])
      })
    },
  ).create_runtime()
  let _ = runtime.mount()
  let snapshot = layer_test_json(runtime.snapshot())
  let clipped = layer_test_find(snapshot, "clipped").unwrap()
  assert_true(layer_test_find(clipped, "parent") is None)
  let root = layer_test_find(snapshot, "root").unwrap()
  let layers = layer_test_children(layer_test_children(root).last().unwrap())
  assert_eq(layers.length(), 3)
  assert_true(layer_test_find(layers[0], "parent") is Some(_))
  assert_true(layer_test_find(layers[0], "child") is None)
  assert_true(layer_test_find(layers[1], "child") is Some(_))
  assert_true(layer_test_find(layers[2], "sibling") is Some(_))
  let implicit = layer_test_event(runtime, "parent-action")
  assert_true(implicit.contains("k:parent"))
  let _ = runtime.dispatch(implicit, "{}")
  let _ = runtime.dispatch("child-action", "{}")
  assert_true(runtime.snapshot().contains("value:11"))
  let _ = runtime.dispose()
}

///|
test "panic duplicate nested layer IDs are rejected" {
  let _ = layer_root([
    layer(id="same", text("first")),
    div(layer(id="same", text("second"))),
  ])
}

///|
test "keyed layer reordering preserves local state and disposal cancels saved emits and subscriptions" {
  let saved : Ref[Emit[Unit]?] = Ref(None)
  let runtime = page(
    id="layer_lifetime",
    route=route("pages/layer-lifetime/index"),
    title="Layer lifetime",
    build=page => {
      let (keys, set_keys) = create_variable(["a", "b"])
      let rows = keys
        .map(keys => @vector.from_array(keys))
        .assoc_by(
          (key, _) => {
            let (count, emit) = create_state_with_init(
              init=emit => {
                if key == "a" {
                  saved.val = Some(emit)
                }
                no_cmd(0)
              },
              update=(count, _ : Unit, _) => no_cmd(count + 1),
              subscriptions=(_, emit) => {
                page.every(
                  key="layer-clock/" + key,
                  interval_ms=1000,
                  command=emit(()),
                )
              },
            )
            count.view(count => {
              layer(
                id="layer-" + key,
                button(
                  id="action-" + key,
                  on_tap=emit(()),
                  key + ":" + count.to_string(),
                ),
              )
            })
          },
          by=key => key,
        )
      Val::view2(keys, rows, (_, rows) => {
        layer_root([
          button(
            event_key="reverse",
            on_tap=set_keys(_ => ["b", "a"]),
            "reverse",
          ),
          button(event_key="remove", on_tap=set_keys(_ => ["b"]), "remove"),
          button(
            event_key="restore",
            on_tap=set_keys(_ => ["a", "b"]),
            "restore",
          ),
          button(
            event_key="late",
            on_tap=saved.val.map(emit => emit(())).unwrap_or(none),
            "late",
          ),
          fragment(rows.to_array()),
        ])
      })
    },
  ).create_runtime()
  let _ = runtime.mount()
  let implicit = layer_test_event(runtime, "action-a")
  let _ = runtime.dispatch(implicit, "{}")
  assert_true(runtime.snapshot().contains("a:1"))
  let _ = runtime.dispatch("reverse", "{}")
  assert_eq(layer_test_event(runtime, "action-a"), implicit)
  let _ = runtime.dispatch(implicit, "{}")
  assert_true(runtime.snapshot().contains("a:2"))
  let commands = runtime.dispatch("remove", "{}")
  assert_true(commands.contains("layer-clock/a"))
  let before = runtime.snapshot()
  let _ = runtime.dispatch("late", "{}")
  let _ = runtime.subscription("layer-clock/a", "{}")
  assert_eq(runtime.snapshot(), before)
  let _ = runtime.dispatch("restore", "{}")
  assert_true(runtime.snapshot().contains("a:0"))
  let _ = runtime.dispose()
}
