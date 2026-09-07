///|
fn native_json(raw : String) -> Json {
  @json.parse(raw) catch {
    _ => abort("invalid test JSON")
  }
}

///|
fn native_request(commands : String) -> String {
  guard native_json(commands) is Array(commands) else {
    abort("commands must be an array")
  }
  for command in commands {
    if command is Object(fields) &&
      fields.get("capability") is Some(String("minimoon.measureNodes")) &&
      fields.get("request_id") is Some(String(id)) {
      return id
    }
  }
  abort("missing measurement command: " + Json::array(commands).stringify())
}

///|
fn native_touch(
  x : Double,
  y : Double,
  time : Double,
  pointer? : Int = 1,
) -> String {
  let point = Json::object({
    "identifier": Json::number(pointer.to_double()),
    "clientX": Json::number(x),
    "clientY": Json::number(y),
    "pageX": Json::number(x),
    "pageY": Json::number(y),
  })
  Json::object({
    "timeStamp": Json::number(time),
    "touches": Json::array([point]),
    "changedTouches": Json::array([point]),
  }).stringify()
}

///|
fn native_rect(id : String, width : Double, height : Double) -> Json {
  Json::object({
    "id": Json::string(id),
    "left": Json::number(0.0),
    "top": Json::number(0.0),
    "right": Json::number(width),
    "bottom": Json::number(height),
    "width": Json::number(width),
    "height": Json::number(height),
  })
}

///|
fn native_resolve(
  runtime : @minimoon.PageRuntime,
  command : String,
  nodes : Array[Json],
) -> String {
  runtime.resolve_effect(
    native_request(command),
    "success",
    Json::object({ "nodes": Json::array(nodes) }).stringify(),
  )
}

///|
fn native_prop_in(value : Json, id : String, key : String) -> Json? {
  if value is Object(fields) {
    if fields.get("props") is Some(Object(props)) &&
      props.get("id") is Some(String(node_id)) &&
      node_id == id {
      return props.get(key)
    }
    if fields.get("tree") is Some(tree) {
      return native_prop_in(tree, id, key)
    }
    if fields.get("children") is Some(Array(children)) {
      for child in children {
        if native_prop_in(child, id, key) is Some(value) {
          return Some(value)
        }
      }
    }
  }
  None
}

///|
fn native_prop(
  runtime : @minimoon.PageRuntime,
  id : String,
  key : String,
) -> Json? {
  native_prop_in(native_json(runtime.snapshot()), id, key)
}

///|
test "drawer uses four-sided measured drag, pointer identity, and cancellation" {
  for side in [Top, Right, Bottom, Left] {
    let runtime = @minimoon.page(
      id="drawer_test",
      route=@minimoon.route("pages/drawer/index"),
      title="Drawer",
      capabilities=[@minimoon.MeasureNodes],
      build=page => {
        root(page, context => {
          drawer(
            context,
            id="drawer",
            title="Drawer",
            trigger_label="Open",
            content=@minimoon.Val::constant(@minimoon.text("Content")),
            side~,
            initially_open=true,
          )
        })
      },
    ).create_runtime()
    let _ = runtime.mount()
    let start = runtime.dispatch(
      "drawer/drag/touchstart",
      native_touch(100.0, 100.0, 0.0),
    )
    let _ = native_resolve(runtime, start, [
      native_rect("drawer-surface", 240.0, 400.0),
    ])
    let sign = if side == Top || side == Left { -1.0 } else { 1.0 }
    let x = 100.0 +
      (if side == Left || side == Right { sign * 120.0 } else { 0.0 })
    let y = 100.0 +
      (if side == Top || side == Bottom { sign * 120.0 } else { 0.0 })
    let before = runtime.snapshot()
    let _ = runtime.dispatch(
      "drawer/drag/touchmove",
      native_touch(x, y, 250.0, pointer=2),
    )
    assert_eq(runtime.snapshot(), before)
    let _ = runtime.dispatch("drawer/drag/touchmove", native_touch(x, y, 250.0))
    assert_true(runtime.snapshot().contains("120px)"))
    let _ = runtime.dispatch(
      "drawer/drag/touchcancel",
      native_touch(x, y, 251.0, pointer=2),
    )
    assert_true(runtime.snapshot().contains("120px)"))
    let _ = runtime.dispatch(
      "drawer/drag/touchcancel",
      native_touch(x, y, 251.0),
    )
    assert_false(runtime.snapshot().contains("120px)"))
    let start = runtime.dispatch(
      "drawer/drag/touchstart",
      native_touch(100.0, 100.0, 500.0),
    )
    let _ = native_resolve(runtime, start, [
      native_rect("drawer-surface", 240.0, 400.0),
    ])
    let _ = runtime.dispatch("drawer/drag/touchend", native_touch(x, y, 1000.0))
    assert_true(native_prop(runtime, "drawer-surface", "style") is None)
    let _ = runtime.dispatch("drawer/trigger", "{}")
    let start = runtime.dispatch(
      "drawer/drag/touchstart",
      native_touch(100.0, 100.0, 1100.0),
    )
    let _ = native_resolve(runtime, start, [
      native_rect("drawer-surface", 240.0, 400.0),
    ])
    let _ = runtime.dispatch(
      "drawer/drag/touchmove",
      native_touch(x, y, 1150.0),
    )
    let _ = runtime.lifecycle("onHide", "{}")
    let _ = runtime.lifecycle("onShow", "{}")
    assert_false(runtime.snapshot().contains("120px)"))
    let pending = runtime.dispatch(
      "drawer/drag/touchstart",
      native_touch(0.0, 0.0, 1200.0),
    )
    let _ = runtime.dispatch("drawer/close", "{}")
    let _ = native_resolve(runtime, pending, [
      native_rect("drawer-surface", 240.0, 400.0),
    ])
    assert_true(native_prop(runtime, "drawer-surface", "style") is None)
    let _ = runtime.dispose()
  }
}

///|
test "resizable preserves constraints and restores cancelled native gestures" {
  let panes = [
    resizable_pane(
      key="a",
      content=@minimoon.text("A"),
      minimum=10.0,
      maximum=80.0,
    ),
    resizable_pane(
      key="b",
      content=@minimoon.text("B"),
      minimum=20.0,
      maximum=70.0,
    ),
    resizable_pane(
      key="c",
      content=@minimoon.text("C"),
      minimum=10.0,
      maximum=50.0,
    ),
  ]
  assert_eq(resize_sizes(panes, [40.0, 40.0, 20.0]), [40.0, 40.0, 20.0])
  let normalized = resize_sizes(panes, [])
  assert_true(
    (normalized[0] + normalized[1] + normalized[2] - 100.0).abs() < 0.000001,
  )
  for orientation in [Horizontal, Vertical] {
    let runtime = @minimoon.page(
      id="resize_test",
      route=@minimoon.route("pages/resize/index"),
      title="Resize",
      capabilities=[@minimoon.MeasureNodes],
      build=page => {
        root(page, context => {
          resizable(
            context,
            id="resize",
            panes=@minimoon.Val::constant(panes),
            initial_sizes=[40.0, 40.0, 20.0],
            orientation~,
          )
        })
      },
    ).create_runtime()
    let _ = runtime.mount()
    let start = runtime.dispatch(
      "resize-handle-0/touchstart",
      native_touch(0.0, 0.0, 0.0),
    )
    let _ = native_resolve(runtime, start, [native_rect("resize", 488.0, 488.0)])
    let _ = runtime.dispatch(
      "resize-handle-0/touchmove",
      native_touch(
        if orientation == Horizontal {
          40.0
        } else {
          0.0
        },
        if orientation == Vertical {
          40.0
        } else {
          0.0
        },
        100.0,
      ),
    )
    assert_true(runtime.snapshot().contains("flex:50 1 0%"))
    assert_true(runtime.snapshot().contains("flex:30 1 0%"))
    let _ = runtime.dispatch(
      "resize-handle-0/touchcancel",
      native_touch(40.0, 40.0, 101.0),
    )
    assert_false(runtime.snapshot().contains("flex:50 1 0%"))
    let _ = runtime.dispatch("resize-handle-0/increase", "{}")
    assert_true(runtime.snapshot().contains("flex:45 1 0%"))
    assert_true(runtime.snapshot().contains("flex:35 1 0%"))
    let _ = runtime.dispose()
  }
}

///|
test "message scroller follows only at end and preserves fractional history offsets" {
  assert_true(messages_prepended(["a", "b"], ["old", "a", "b"]))
  assert_false(messages_prepended(["a", "b"], ["a", "b", "new"]))
  let runtime = @minimoon.page(
    id="messages_test",
    route=@minimoon.route("pages/messages/index"),
    title="Messages",
    capabilities=[@minimoon.MeasureNodes],
    build=page => {
      root(page, context => {
        let (items, update) = @minimoon.create_variable([
          message_item(key="a", content=@minimoon.text("A")),
          message_item(key="b", content=@minimoon.text("B")),
        ])
        stack([
          @minimoon.Val::constant(
            @minimoon.fragment([
              @minimoon.button(
                on_tap=update(items => {
                  let next = items.copy()
                  next.push(
                    message_item(key="new", content=@minimoon.text("New")),
                  )
                  next
                }),
                event_key="append",
                "Append",
              ),
              @minimoon.button(
                on_tap=update(items => {
                  let next = [
                    message_item(key="old", content=@minimoon.text("Old")),
                  ]
                  for item in items {
                    next.push(item)
                  }
                  next
                }),
                event_key="prepend",
                "Prepend",
              ),
            ]),
          ),
          message_scroller(context, id="messages", items~),
        ])
      })
    },
  ).create_runtime()
  let mount = runtime.mount()
  let _ = native_resolve(runtime, mount, [
    native_rect("messages-viewport", 300.0, 200.0),
    native_rect("messages-content", 300.0, 600.5),
  ])
  assert_eq(
    native_prop(runtime, "messages-viewport", "scrollTop"),
    Some(Json::number(400.5)),
  )
  let _ = runtime.dispatch(
    "messages/scroll", "{\"detail\":{\"scrollLeft\":0,\"scrollTop\":100.25,\"scrollHeight\":600.5,\"scrollWidth\":300,\"deltaX\":0,\"deltaY\":-300.25}}",
  )
  let append = runtime.dispatch("append", "{}")
  let _ = native_resolve(runtime, append, [
    native_rect("messages-viewport", 300.0, 200.0),
    native_rect("messages-content", 300.0, 700.5),
  ])
  assert_eq(
    native_prop(runtime, "messages-viewport", "scrollTop"),
    Some(Json::number(100.25)),
  )
  let prepend = runtime.dispatch("prepend", "{}")
  let _ = native_resolve(runtime, prepend, [
    native_rect("messages-viewport", 300.0, 200.0),
    native_rect("messages-content", 300.0, 800.75),
  ])
  assert_eq(
    native_prop(runtime, "messages-viewport", "scrollTop"),
    Some(Json::number(200.5)),
  )
  let _ = runtime.dispatch("messages/end", "{}")
  assert_eq(
    native_prop(runtime, "messages-viewport", "scrollTop"),
    Some(Json::number(600.75)),
  )
  let _ = runtime.dispose()
}

///|
test "RTL resizable inverts horizontal movement and hide restores the initial pair" {
  let runtime = @minimoon.page(
    id="resize_rtl",
    route=@minimoon.route("pages/resize/rtl"),
    title="Resize RTL",
    capabilities=[@minimoon.MeasureNodes],
    build=page => {
      root(page, context => {
        resizable(
          context,
          id="rtl",
          direction=@theme.Rtl,
          panes=@minimoon.Val::constant([
            resizable_pane(key="a", content=@minimoon.text("A")),
            resizable_pane(key="a/handle", content=@minimoon.text("B")),
          ]),
          initial_sizes=[50.0, 50.0],
        )
      })
    },
  ).create_runtime()
  let _ = runtime.mount()
  let start = runtime.dispatch(
    "rtl-handle-0/touchstart",
    native_touch(100.0, 0.0, 0.0),
  )
  let _ = native_resolve(runtime, start, [native_rect("rtl", 444.0, 300.0)])
  let _ = runtime.dispatch(
    "rtl-handle-0/touchmove",
    native_touch(60.0, 0.0, 100.0),
  )
  assert_true(runtime.snapshot().contains("flex:60 1 0%"))
  let _ = runtime.dispatch(
    "rtl-handle-0/touchcancel",
    native_touch(60.0, 0.0, 101.0, pointer=9),
  )
  assert_true(runtime.snapshot().contains("flex:60 1 0%"))
  let _ = runtime.lifecycle("onHide", "{}")
  assert_false(runtime.snapshot().contains("flex:60 1 0%"))
  let _ = runtime.dispose()
}

///|
test "carousel vertical mode reaches native swiper props" {
  let runtime = @minimoon.page(
    id="vertical_carousel",
    route=@minimoon.route("pages/carousel/vertical"),
    title="Carousel",
    build=_ => {
      carousel(
        id="slides",
        vertical=true,
        items=@minimoon.Val::constant([
          panel(key="one", title="One", content=@minimoon.text("One")),
        ]),
      )
    },
  ).create_runtime()
  let _ = runtime.mount()
  assert_eq(
    native_prop(runtime, "slides-swiper", "vertical"),
    Some(Json::boolean(true)),
  )
  let _ = runtime.dispose()
}
