///|
priv enum CounterMessage {
  Increment
}

///|
test "Val page commits one typed event transaction" {
  let definition = page(
    id="val_counter",
    route=route("pages/val_counter/val_counter"),
    title="Val Counter",
    build=_ => {
      let (count, emit) = create_pure_state(0, update=(value, message) => {
        match message {
          Increment => value + 1
        }
      })
      count.view(value => button(on_tap=emit(Increment), value.to_string()))
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  inspect(runtime.snapshot().contains("\"text\":\"0\""), content="true")
  let commands = runtime.dispatch("v/root/tap", "{}")
  inspect(commands.contains("PatchViewTree"), content="true")
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
}

///|
priv enum SurfaceMessage {
  SurfaceLifecycle
  SurfaceText(String)
  SurfaceBool(Bool)
  SurfaceStrings(Array[String])
  SurfaceIndex(Int)
  SurfaceScroll(ScrollDetail)
}

///|
test "public page metadata, lifecycle helpers, and control decoders compose" {
  let definition = page(
    id="surface",
    route=route("pages/surface/surface"),
    title="Surface",
    build=context => {
      let (model, emit) = create_state(
        0,
        update=(model, message : SurfaceMessage, _) => {
          let increment = match message {
            SurfaceLifecycle => 1
            SurfaceText(value) => value.length()
            SurfaceBool(value) => if value { 1 } else { 0 }
            SurfaceStrings(values) => values.length()
            SurfaceIndex(value) => value
            SurfaceScroll(detail) => detail.scroll_top.to_int()
          }
          no_cmd(model + increment)
        },
        subscriptions=(_, emit) => {
          Sub::batch([
            context.on_load(emit(SurfaceLifecycle)),
            context.on_show(emit(SurfaceLifecycle)),
            context.on_hide(emit(SurfaceLifecycle)),
            context.on_unload(emit(SurfaceLifecycle)),
            context.on_pull_down_refresh(emit(SurfaceLifecycle)),
            context.on_reach_bottom(emit(SurfaceLifecycle)),
          ])
        },
      )
      model.view(count => {
        div([
          nothing(),
          span("count:" + count.to_string()),
          image(src="/asset.png", alt="asset"),
          input(
            value="",
            on_input=emit.map(value => SurfaceText(value)),
            event_key="surface/input",
          ),
          switch(
            checked=false,
            on_change=emit.map(value => SurfaceBool(value)),
            event_key="surface/switch",
          ),
          checkbox_group(
            on_change=emit.map(value => SurfaceStrings(value)),
            event_key="surface/checks",
            [checkbox(value="one", "One")],
          ),
          radio_group(
            on_change=emit.map(value => SurfaceText(value)),
            event_key="surface/radio",
            [radio(value="one", "One")],
          ),
          scroll_view(
            scroll_y=true,
            on_scroll=emit.map(value => SurfaceScroll(value)),
            scroll_key="surface/scroll",
            on_upper=emit(SurfaceLifecycle),
            upper_key="surface/upper",
            on_lower=emit(SurfaceLifecycle),
            lower_key="surface/lower",
            [text("scroll")],
          ),
          textarea(
            value="",
            on_input=emit.map(value => SurfaceText(value)),
            input_key="surface/textarea",
            on_confirm=emit.map(value => SurfaceText(value)),
            confirm_key="surface/confirm",
          ),
          picker_date(
            value="2026-09-04",
            on_change=emit.map(value => SurfaceText(value)),
            event_key="surface/date",
            text("Date"),
          ),
          picker_time(
            value="12:00",
            on_change=emit.map(value => SurfaceText(value)),
            event_key="surface/time",
            text("Time"),
          ),
          picker_region(
            value=["Shanghai"],
            on_change=emit.map(value => SurfaceStrings(value)),
            event_key="surface/region",
            text("Region"),
          ),
          picker_selector(
            options=["a", "b"],
            selected=0,
            on_change=emit.map(value => SurfaceIndex(value)),
            event_key="surface/picker",
            text("Picker"),
          ),
          swiper([swiper_item(item_id="first", text("First"))]),
        ])
      })
    },
  )
  assert_eq(definition.id(), "surface")
  assert_eq(definition.route(), "pages/surface/surface")
  assert_eq(definition.title(), "Surface")
  assert_true(definition.contract_json().stringify().contains("surface"))
  let runtime = definition.create_runtime()
  assert_eq(runtime.page_id(), "surface")
  let _ = runtime.mount()
  assert_true(runtime.lifecycle("onLoad", "{}").contains("PatchViewTree"))
  assert_true(
    runtime.lifecycle("onPullDownRefresh", "{}").contains("PatchViewTree"),
  )
  assert_true(
    runtime.lifecycle("onReachBottom", "{}").contains("PatchViewTree"),
  )
  assert_true(
    runtime
    .dispatch("surface/input", "{\"detail\":{}}")
    .contains("event_decode_failed"),
  )
  assert_true(
    runtime
    .dispatch("surface/switch", "{\"detail\":{\"value\":1}}")
    .contains("event_decode_failed"),
  )
  assert_true(runtime.dispatch_batch("{}").contains("invalid_event_batch"))
  let _ = runtime.lifecycle("onUnload", "{}")
}

///|
test "Val map2 through map9 and view2 through view9 remain available" {
  let definition = page(
    id="val_map_arities",
    route=route("pages/val_map_arities/val_map_arities"),
    title="Val Map Arities",
    build=_ => {
      let (a, update_a) = create_variable(1)
      let b = Val::constant(2)
      let c = Val::constant(3)
      let d = Val::constant(4)
      let e = Val::constant(5)
      let f = Val::constant(6)
      let g = Val::constant(7)
      let h = Val::constant(8)
      let i = Val::constant(9)
      let two = Val::map2(a, b, (a, b) => a + b)
      let three = Val::map3(a, b, c, (a, b, c) => a + b + c)
      let four = Val::map4(a, b, c, d, (a, b, c, d) => a + b + c + d)
      let five = Val::map5(a, b, c, d, e, (a, b, c, d, e) => a + b + c + d + e)
      let six = Val::map6(a, b, c, d, e, f, (a, b, c, d, e, f) => {
        a + b + c + d + e + f
      })
      let seven = Val::map7(a, b, c, d, e, f, g, (a, b, c, d, e, f, g) => {
        a + b + c + d + e + f + g
      })
      let eight = Val::map8(a, b, c, d, e, f, g, h, (a, b, c, d, e, f, g, h) => {
        a + b + c + d + e + f + g + h
      })
      let nine = Val::map9(a, b, c, d, e, f, g, h, i, (
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
        i,
      ) => a + b + c + d + e + f + g + h + i)
      let view2 = Val::view2(a, b, (a, b) => p("view2:" + (a + b).to_string()))
      let view3 = Val::view3(a, b, c, (a, b, c) => {
        p("view3:" + (a + b + c).to_string())
      })
      let view4 = Val::view4(a, b, c, d, (a, b, c, d) => {
        p("view4:" + (a + b + c + d).to_string())
      })
      let view5 = Val::view5(a, b, c, d, e, (a, b, c, d, e) => {
        p("view5:" + (a + b + c + d + e).to_string())
      })
      let view6 = Val::view6(a, b, c, d, e, f, (a, b, c, d, e, f) => {
        p("view6:" + (a + b + c + d + e + f).to_string())
      })
      let view7 = Val::view7(a, b, c, d, e, f, g, (a, b, c, d, e, f, g) => {
        p("view7:" + (a + b + c + d + e + f + g).to_string())
      })
      let view8 = Val::view8(a, b, c, d, e, f, g, h, (a, b, c, d, e, f, g, h) => {
        p("view8:" + (a + b + c + d + e + f + g + h).to_string())
      })
      let view9 = Val::view9(a, b, c, d, e, f, g, h, i, (
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
        i,
      ) => p("view9:" + (a + b + c + d + e + f + g + h + i).to_string()))
      let total = Val::map8(two, three, four, five, six, seven, eight, nine, (
        two,
        three,
        four,
        five,
        six,
        seven,
        eight,
        nine,
      ) => two + three + four + five + six + seven + eight + nine)
      Val::map9(view2, view3, view4, view5, view6, view7, view8, view9, total, (
        view2,
        view3,
        view4,
        view5,
        view6,
        view7,
        view8,
        view9,
        total,
      ) => {
        fragment([
          button(
            on_tap=update_a(value => value + 1),
            event_key="map-arities/increment-a",
            "increment a",
          ),
          view2,
          view3,
          view4,
          view5,
          view6,
          view7,
          view8,
          view9,
          p("map-total:" + total.to_string()),
        ])
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  let snapshot = runtime.snapshot()
  assert_true(snapshot.contains("view2:3"))
  assert_true(snapshot.contains("view3:6"))
  assert_true(snapshot.contains("view4:10"))
  assert_true(snapshot.contains("view5:15"))
  assert_true(snapshot.contains("view6:21"))
  assert_true(snapshot.contains("view7:28"))
  assert_true(snapshot.contains("view8:36"))
  assert_true(snapshot.contains("view9:45"))
  assert_true(snapshot.contains("map-total:164"))
  let updated = runtime.dispatch("map-arities/increment-a", "{}")
  assert_true(updated.contains("PatchViewTree"))
  let next = runtime.snapshot()
  assert_true(next.contains("view2:4"))
  assert_true(next.contains("view3:7"))
  assert_true(next.contains("view4:11"))
  assert_true(next.contains("view5:16"))
  assert_true(next.contains("view6:22"))
  assert_true(next.contains("view7:29"))
  assert_true(next.contains("view8:37"))
  assert_true(next.contains("view9:46"))
  assert_true(next.contains("map-total:172"))
}

///|
test "Val assoc and bounded enumeration retain root-owned composition" {
  let definition = page(
    id="val_root_composition",
    route=route("pages/val_root_composition/val_root_composition"),
    title="Val Root Composition",
    build=_ => {
      let entries = Val::constant(@vector.from_array([("a", 1), ("b", 2)]))
      let rows = entries.assoc((key, value) => {
        value.view(current => p(key + ":" + current.to_string()))
      })
      let active = Val::constant("a")
      let branch = active.enumerate_bounded_by(
        capacity=2,
        build=(initial, current) => {
          current.view(value => p(initial + ":" + value))
        },
        by=value => value,
      )
      Val::map2(rows, branch, (rows, branch) => {
        fragment([..rows.to_array(), branch])
      })
    },
  )
  let snapshot = definition.create_runtime().snapshot()
  assert_true(snapshot.contains("a:1"))
  assert_true(snapshot.contains("b:2"))
  assert_true(snapshot.contains("a:a"))
}

///|
priv enum ElmishSurfaceMessage {
  ElmishIncrement
  ElmishShown
}

///|
test "elmish_page keeps view model-first and subscriptions page-aware" {
  let definition = elmish_page(
    id="elmish_surface",
    route=route("pages/elmish-surface/elmish-surface"),
    title="Elmish surface",
    model=0,
    update=(model, message, _) => {
      match message {
        ElmishIncrement | ElmishShown => no_cmd(model + 1)
      }
    },
    view=(model, emit) => {
      button(
        on_tap=emit(ElmishIncrement),
        event_key="elmish/increment",
        model.to_string(),
      )
    },
    subscriptions=(context, _, emit) => context.on_show(emit(ElmishShown)),
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  assert_true(runtime.snapshot().contains("\"text\":\"0\""))
  let _ = runtime.dispatch("elmish/increment", "{}")
  assert_true(runtime.snapshot().contains("\"text\":\"1\""))
  let _ = runtime.lifecycle("onShow", "{}")
  assert_true(runtime.snapshot().contains("\"text\":\"2\""))
}

///|
priv enum NativeInputMessage {
  NativeFocused(String)
  NativeBlurred(String)
  NativeTextareaBlurred(Int)
  NativeConfirmed(String)
  NativeTapped
}

///|
test "input focus boundary, tap views, and extended semantics stay typed" {
  let definition = page(
    id="native_input_surface",
    route=route("pages/native-input/native-input"),
    title="Native input",
    build=_ => {
      let (model, emit) = create_pure_state("idle", update=(model, message) => {
        let next_value = match message {
          NativeFocused(value) => "focus:" + value
          NativeBlurred(value) => "blur:" + value
          NativeTextareaBlurred(cursor) => "textarea-blur:" + cursor.to_string()
          NativeConfirmed(value) => "confirm:" + value
          NativeTapped => "tap"
        }
        if model == next_value {
          model
        } else {
          next_value
        }
      })
      model.view(model => {
        div([
          input(
            value=model,
            on_input=Emit(_ => none),
            event_key="native/input",
            on_focus=emit.map(detail => NativeFocused(detail.value)),
            focus_key="native/focus",
            on_blur=emit.map(detail => NativeBlurred(detail.value)),
            blur_key="native/blur",
            on_confirm=emit.map(value => NativeConfirmed(value)),
            confirm_key="native/confirm",
          ),
          textarea(
            value=model,
            on_input=Emit(_ => none),
            input_key="native/textarea-input",
            on_blur=emit.map(detail => NativeTextareaBlurred(detail.cursor)),
            blur_key="native/textarea-blur",
          ),
          tap_view(
            on_tap=emit(NativeTapped),
            event_key="native/tap-view",
            semantics=semantics(
              role=MenuItemCheckboxRole,
              checked=true,
              modal=true,
              described_by="native-description",
              orientation="vertical",
              has_popup="menu",
            ),
            text("tap surface"),
          ),
        ])
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  let snapshot = runtime.snapshot()
  assert_true(snapshot.contains("\"ariaChecked\":true"))
  assert_true(snapshot.contains("\"ariaModal\":true"))
  assert_true(snapshot.contains("\"ariaHasPopup\":\"menu\""))
  let _ = runtime.dispatch(
    "native/focus", "{\"detail\":{\"value\":\"alpha\",\"height\":40}}",
  )
  assert_true(runtime.snapshot().contains("focus:alpha"))
  let _ = runtime.dispatch("native/blur", "{\"detail\":{\"value\":\"beta\"}}")
  assert_true(runtime.snapshot().contains("blur:beta"))
  let _ = runtime.dispatch(
    "native/textarea-blur", "{\"detail\":{\"value\":\"notes\",\"cursor\":5}}",
  )
  assert_true(runtime.snapshot().contains("textarea-blur:5"))
  let _ = runtime.dispatch(
    "native/confirm", "{\"detail\":{\"value\":\"done\"}}",
  )
  assert_true(runtime.snapshot().contains("confirm:done"))
  let _ = runtime.dispatch("native/tap-view", "{}")
  assert_true(runtime.snapshot().contains("\"value\":\"tap\""))
}

///|
test "create_state_with_init delivers its initial command through Emit" {
  let definition = page(
    id="val_init",
    route=route("pages/val_init/val_init"),
    title="Val Init",
    build=_ => {
      let (count, emit) = create_state_with_init(
        init=emit => with_cmd(0, emit(Increment)),
        update=(current, message, _) => {
          match message {
            Increment => no_cmd(current + 1)
          }
        },
      )
      count.view(value => button(on_tap=emit(Increment), value.to_string()))
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
}

///|
test "Eq-equal Val input skips graph projection and host writes" {
  let renders = Ref(0)
  let definition = page(
    id="val_noop",
    route=route("pages/val_noop/val_noop"),
    title="Val No-op",
    build=_ => {
      let (value, emit) = create_pure_state(7, update=(current, _message : Unit) => {
        current + 0
      })
      value.view(current => {
        renders.val += 1
        button(on_tap=emit(()), event_key="set-same", current.to_string())
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  let before = renders.val
  inspect(runtime.dispatch("set-same", "{}"), content="[]")
  inspect(renders.val == before, content="true")
}

///|
priv enum AssocMessage {
  RemoveFirst
  IncrementRow
}

///|
fn transactional_row(key : String, _input : Val[String]) -> Val[Node] {
  let (count, emit) = create_pure_state(0, update=(current, message) => {
    match message {
      IncrementRow => current + 1
      RemoveFirst => current
    }
  })
  count.view(value => {
    button(
      on_tap=emit(IncrementRow),
      event_key=key + "/increment",
      key + ":" + value.to_string(),
    )
  })
}

///|
test "failed assoc candidate restores removed branch state and handlers" {
  let definition = page(
    id="val_assoc_transaction",
    route=route("pages/val_assoc_transaction/val_assoc_transaction"),
    title="Val Assoc Transaction",
    build=_ => {
      let (keys, emit) = create_pure_state(["a", "b"], update=(current, message) => {
        match message {
          RemoveFirst => ["b"]
          IncrementRow => current
        }
      })
      let entries = keys.map(values => @vector.from_array(values))
      let rows = entries.assoc_by(transactional_row, by=value => value)
      Val::map2(keys, rows, (values, rows) => {
        let children = [
          button(
            on_tap=emit(RemoveFirst),
            event_key="remove-first",
            "remove first",
          ),
          fragment(rows.to_array()),
        ]
        if values.length() == 1 {
          children.push(
            button(on_tap=none, event_key="invalid-duplicate", "duplicate 1"),
          )
          children.push(
            button(on_tap=none, event_key="invalid-duplicate", "duplicate 2"),
          )
        }
        div(children)
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  let _ = runtime.dispatch("a/increment", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"a:1\""), content="true")
  let rejected = runtime.dispatch("remove-first", "{}")
  inspect(rejected.contains("invalid_view"), content="true")
  let _ = runtime.dispatch("a/increment", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"a:2\""), content="true")
}

///|
test "semantics stay typed in the normalized tree and shared WXML" {
  let definition = page(
    id="semantic_surface",
    route=route("pages/semantic-surface/semantic-surface"),
    title="Semantic surface",
    build=_ => {
      Val::constant(
        div(semantics=semantics(role=NavigationRole, label="Primary"), [
          button(
            id="semantic-trigger",
            on_tap=none,
            semantics=semantics(
              role=ButtonRole,
              expanded=false,
              controls="semantic-panel",
            ),
            "Toggle",
          ),
        ]),
      )
    },
  )
  let snapshot = definition.create_runtime().snapshot()
  assert_true(snapshot.contains("\"role\":\"navigation\""))
  assert_true(snapshot.contains("\"ariaLabel\":\"Primary\""))
  assert_true(snapshot.contains("\"ariaExpanded\":false"))
  assert_true(snapshot.contains("\"ariaControls\":\"semantic-panel\""))
  let wxml = definition.wxml()
  assert_true(wxml.contains("minimoon.templates.wxml"))
}
