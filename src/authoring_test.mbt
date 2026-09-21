///|
priv enum CounterMessage {
  Increment
}

///|
test "Val page commits one typed event transaction" {
  let definition = @minimoon.page(
    id="val_counter",
    route=@minimoon.route("pages/val_counter/val_counter"),
    title="Val Counter",
    build=_ => {
      let (count, emit) = @minimoon.create_pure_state(0, update=(value, message) => {
        match message {
          Increment => value + 1
        }
      })
      count.view(value => {
        @minimoon.button(on_tap=emit(Increment), value.to_string())
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
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
  SurfaceScroll(@minimoon.ScrollDetail)
}

///|
test "public page metadata, lifecycle helpers, and control decoders compose" {
  let definition = @minimoon.page(
    id="surface",
    route=@minimoon.route("pages/surface/surface"),
    title="Surface",
    build=context => {
      let (model, emit) = @minimoon.create_state(
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
          @minimoon.no_cmd(model + increment)
        },
        subscriptions=(_, emit) => {
          @minimoon.Sub::batch([
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
        @minimoon.div([
          @minimoon.nothing(),
          @minimoon.span("count:" + count.to_string()),
          @minimoon.image(src="/asset.png", alt="asset"),
          @minimoon.input(
            value="",
            on_input=emit.map(value => SurfaceText(value)),
            event_key="surface/input",
          ),
          @minimoon.switch(
            checked=false,
            on_change=emit.map(value => SurfaceBool(value)),
            event_key="surface/switch",
          ),
          @minimoon.checkbox_group(
            on_change=emit.map(value => SurfaceStrings(value)),
            event_key="surface/checks",
            [@minimoon.checkbox(value="one", "One")],
          ),
          @minimoon.radio_group(
            on_change=emit.map(value => SurfaceText(value)),
            event_key="surface/radio",
            [@minimoon.radio(value="one", "One")],
          ),
          @minimoon.scroll_view(
            scroll_y=true,
            on_scroll=emit.map(value => SurfaceScroll(value)),
            scroll_key="surface/scroll",
            on_upper=emit(SurfaceLifecycle),
            upper_key="surface/upper",
            on_lower=emit(SurfaceLifecycle),
            lower_key="surface/lower",
            [@minimoon.text("scroll")],
          ),
          @minimoon.textarea(
            value="",
            on_input=emit.map(value => SurfaceText(value)),
            input_key="surface/textarea",
            on_confirm=emit.map(value => SurfaceText(value)),
            confirm_key="surface/confirm",
          ),
          @minimoon.picker_date(
            value="2026-09-04",
            on_change=emit.map(value => SurfaceText(value)),
            event_key="surface/date",
            @minimoon.text("Date"),
          ),
          @minimoon.picker_time(
            value="12:00",
            on_change=emit.map(value => SurfaceText(value)),
            event_key="surface/time",
            @minimoon.text("Time"),
          ),
          @minimoon.picker_region(
            value=["Shanghai"],
            on_change=emit.map(value => SurfaceStrings(value)),
            event_key="surface/region",
            @minimoon.text("Region"),
          ),
          @minimoon.picker_selector(
            options=["a", "b"],
            selected=0,
            on_change=emit.map(value => SurfaceIndex(value)),
            event_key="surface/picker",
            @minimoon.text("Picker"),
          ),
          @minimoon.swiper([
            @minimoon.swiper_item(item_id="first", @minimoon.text("First")),
          ]),
        ])
      })
    },
  )
  assert_eq(definition.id(), "surface")
  assert_eq(definition.route(), "pages/surface/surface")
  assert_eq(definition.title(), "Surface")
  assert_true(definition.contract_json().stringify().contains("surface"))
  let runtime = definition.create_runtime().unwrap()
  assert_eq(runtime.page_id(), "surface")
  assert_true(runtime.lifecycle("onLoad", "{}").contains("ReplaceViewTree"))
  let _ = runtime.mount()
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
  let definition = @minimoon.page(
    id="val_map_arities",
    route=@minimoon.route("pages/val_map_arities/val_map_arities"),
    title="Val Map Arities",
    build=_ => {
      let (a, update_a) = @minimoon.create_variable(1)
      let b = @minimoon.Val::constant(2)
      let c = @minimoon.Val::constant(3)
      let d = @minimoon.Val::constant(4)
      let e = @minimoon.Val::constant(5)
      let f = @minimoon.Val::constant(6)
      let g = @minimoon.Val::constant(7)
      let h = @minimoon.Val::constant(8)
      let i = @minimoon.Val::constant(9)
      let two = @minimoon.Val::map2(a, b, (a, b) => a + b)
      let three = @minimoon.Val::map3(a, b, c, (a, b, c) => a + b + c)
      let four = @minimoon.Val::map4(a, b, c, d, (a, b, c, d) => a + b + c + d)
      let five = @minimoon.Val::map5(a, b, c, d, e, (a, b, c, d, e) => {
        a + b + c + d + e
      })
      let six = @minimoon.Val::map6(a, b, c, d, e, f, (a, b, c, d, e, f) => {
        a + b + c + d + e + f
      })
      let seven = @minimoon.Val::map7(a, b, c, d, e, f, g, (a, b, c, d, e, f, g) => {
        a + b + c + d + e + f + g
      })
      let eight = @minimoon.Val::map8(a, b, c, d, e, f, g, h, (
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
      ) => a + b + c + d + e + f + g + h)
      let nine = @minimoon.Val::map9(a, b, c, d, e, f, g, h, i, (
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
      let view2 = @minimoon.Val::view2(a, b, (a, b) => {
        @minimoon.p("view2:" + (a + b).to_string())
      })
      let view3 = @minimoon.Val::view3(a, b, c, (a, b, c) => {
        @minimoon.p("view3:" + (a + b + c).to_string())
      })
      let view4 = @minimoon.Val::view4(a, b, c, d, (a, b, c, d) => {
        @minimoon.p("view4:" + (a + b + c + d).to_string())
      })
      let view5 = @minimoon.Val::view5(a, b, c, d, e, (a, b, c, d, e) => {
        @minimoon.p("view5:" + (a + b + c + d + e).to_string())
      })
      let view6 = @minimoon.Val::view6(a, b, c, d, e, f, (a, b, c, d, e, f) => {
        @minimoon.p("view6:" + (a + b + c + d + e + f).to_string())
      })
      let view7 = @minimoon.Val::view7(a, b, c, d, e, f, g, (
        a,
        b,
        c,
        d,
        e,
        f,
        g,
      ) => @minimoon.p("view7:" + (a + b + c + d + e + f + g).to_string()))
      let view8 = @minimoon.Val::view8(a, b, c, d, e, f, g, h, (
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
      ) => @minimoon.p("view8:" + (a + b + c + d + e + f + g + h).to_string()))
      let view9 = @minimoon.Val::view9(a, b, c, d, e, f, g, h, i, (
        a,
        b,
        c,
        d,
        e,
        f,
        g,
        h,
        i,
      ) => {
        @minimoon.p("view9:" + (a + b + c + d + e + f + g + h + i).to_string())
      })
      let total = @minimoon.Val::map8(
        two,
        three,
        four,
        five,
        six,
        seven,
        eight,
        nine,
        (two, three, four, five, six, seven, eight, nine) => {
          two + three + four + five + six + seven + eight + nine
        },
      )
      @minimoon.Val::map9(
        view2,
        view3,
        view4,
        view5,
        view6,
        view7,
        view8,
        view9,
        total,
        (view2, view3, view4, view5, view6, view7, view8, view9, total) => {
          @minimoon.fragment([
            @minimoon.button(
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
            @minimoon.p("map-total:" + total.to_string()),
          ])
        },
      )
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
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
  let definition = @minimoon.page(
    id="val_root_composition",
    route=@minimoon.route("pages/val_root_composition/val_root_composition"),
    title="Val Root Composition",
    build=_ => {
      let entries = @minimoon.Val::constant(
        @vector.from_array([("a", 1), ("b", 2)]),
      )
      let rows = entries.assoc((key, value) => {
        value.view(current => @minimoon.p(key + ":" + current.to_string()))
      })
      let active = @minimoon.Val::constant("a")
      let branch = active.enumerate_bounded_by(
        capacity=2,
        build=(initial, current) => {
          current.view(value => @minimoon.p(initial + ":" + value))
        },
        by=value => value,
      )
      @minimoon.Val::map2(rows, branch, (rows, branch) => {
        @minimoon.fragment([..rows.to_array(), branch])
      })
    },
  )
  let snapshot = definition.create_runtime().unwrap().snapshot()
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
  let definition = @minimoon.elmish_page(
    id="elmish_surface",
    route=@minimoon.route("pages/elmish-surface/elmish-surface"),
    title="Elmish surface",
    model=0,
    update=(model, message, _) => {
      match message {
        ElmishIncrement | ElmishShown => @minimoon.no_cmd(model + 1)
      }
    },
    view=(model, emit) => {
      @minimoon.button(
        on_tap=emit(ElmishIncrement),
        event_key="elmish/increment",
        model.to_string(),
      )
    },
    subscriptions=(context, _, emit) => context.on_show(emit(ElmishShown)),
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
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
  let definition = @minimoon.page(
    id="native_input_surface",
    route=@minimoon.route("pages/native-input/native-input"),
    title="Native input",
    build=_ => {
      let (model, emit) = @minimoon.create_pure_state("idle", update=(
        model,
        message,
      ) => {
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
        @minimoon.div([
          @minimoon.input(
            value=model,
            on_input=Emit(_ => @minimoon.none),
            event_key="native/input",
            on_focus=emit.map(detail => NativeFocused(detail.value)),
            focus_key="native/focus",
            on_blur=emit.map(detail => NativeBlurred(detail.value)),
            blur_key="native/blur",
            on_confirm=emit.map(value => NativeConfirmed(value)),
            confirm_key="native/confirm",
          ),
          @minimoon.textarea(
            value=model,
            on_input=Emit(_ => @minimoon.none),
            input_key="native/textarea-input",
            on_blur=emit.map(detail => NativeTextareaBlurred(detail.cursor)),
            blur_key="native/textarea-blur",
          ),
          @minimoon.tap_view(
            on_tap=emit(NativeTapped),
            event_key="native/tap-view",
            semantics=@minimoon.semantics(
              role=MenuItemCheckboxRole,
              checked=true,
              modal=true,
              described_by="native-description",
              orientation="vertical",
              has_popup="menu",
            ),
            @minimoon.text("tap surface"),
          ),
        ])
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
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
  let definition = @minimoon.page(
    id="val_init",
    route=@minimoon.route("pages/val_init/val_init"),
    title="Val Init",
    build=_ => {
      let (count, emit) = @minimoon.create_state_with_init(
        init=emit => @minimoon.with_cmd(0, emit(Increment)),
        update=(current, message, _) => {
          match message {
            Increment => @minimoon.no_cmd(current + 1)
          }
        },
      )
      count.view(value => {
        @minimoon.button(on_tap=emit(Increment), value.to_string())
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  let _ = runtime.mount()
  inspect(runtime.snapshot().contains("\"text\":\"1\""), content="true")
}

///|
test "Eq-equal Val input skips graph projection and host writes" {
  let renders = Ref(0)
  let definition = @minimoon.page(
    id="val_noop",
    route=@minimoon.route("pages/val_noop/val_noop"),
    title="Val No-op",
    build=_ => {
      let (value, emit) = @minimoon.create_pure_state(7, update=(
        current,
        _message : Unit,
      ) => current + 0)
      value.view(current => {
        renders.val += 1
        @minimoon.button(
          on_tap=emit(()),
          event_key="set-same",
          current.to_string(),
        )
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
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
fn transactional_row(
  key : String,
  _input : @minimoon.Val[String],
) -> @minimoon.Val[@minimoon.Node] {
  let (count, emit) = @minimoon.create_pure_state(0, update=(current, message) => {
    match message {
      IncrementRow => current + 1
      RemoveFirst => current
    }
  })
  count.view(value => {
    @minimoon.button(
      on_tap=emit(IncrementRow),
      event_key=key + "/increment",
      key + ":" + value.to_string(),
    )
  })
}

///|
test "failed assoc candidate restores removed branch state and handlers" {
  let definition = @minimoon.page(
    id="val_assoc_transaction",
    route=@minimoon.route("pages/val_assoc_transaction/val_assoc_transaction"),
    title="Val Assoc Transaction",
    build=_ => {
      let (keys, emit) = @minimoon.create_pure_state(["a", "b"], update=(
        current,
        message,
      ) => {
        match message {
          RemoveFirst => ["b"]
          IncrementRow => current
        }
      })
      let entries = keys.map(values => @vector.from_array(values))
      let rows = entries.assoc_by(transactional_row, by=value => value)
      @minimoon.Val::map2(keys, rows, (values, rows) => {
        let children = [
          @minimoon.button(
            on_tap=emit(RemoveFirst),
            event_key="remove-first",
            "remove first",
          ),
          @minimoon.fragment(rows.to_array()),
        ]
        if values.length() == 1 {
          children.push(
            @minimoon.button(
              on_tap=@minimoon.none,
              event_key="invalid-duplicate",
              "duplicate 1",
            ),
          )
          children.push(
            @minimoon.button(
              on_tap=@minimoon.none,
              event_key="invalid-duplicate",
              "duplicate 2",
            ),
          )
        }
        @minimoon.div(children)
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  let _ = runtime.mount()
  let _ = runtime.dispatch("a/increment", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"a:1\""), content="true")
  let rejected = runtime.dispatch("remove-first", "{}")
  inspect(rejected.contains("invalid_view"), content="true")
  let _ = runtime.dispatch("a/increment", "{}")
  inspect(runtime.snapshot().contains("\"text\":\"a:2\""), content="true")
}

///|
priv enum KeyedLifetimeShape {
  Empty
  EmptyFragment
  Fragment
  View
} derive(Eq)

///|
priv struct KeyedLifetimeRowSpec {
  shape : KeyedLifetimeShape
  version : Int
} derive(Eq)

///|
fn keyed_lifetime_find(value : Json, id : String) -> Json? {
  if value is Object(fields) {
    if fields.get("props") is Some(Object(props)) &&
      props.get("id") == Some(Json::string(id)) {
      return Some(value)
    }
    if fields.get("tree") is Some(tree) {
      return keyed_lifetime_find(tree, id)
    }
    if fields.get("children") is Some(Array(children)) {
      for child in children {
        if keyed_lifetime_find(child, id) is Some(found) {
          return Some(found)
        }
      }
    }
  }
  None
}

///|
fn keyed_lifetime_texts(value : Json) -> Array[String] {
  let result = []
  if value is Object(fields) {
    for field in ["text", "value"] {
      if fields.get(field) is Some(String(value)) && value != "" {
        result.push(value)
      }
    }
    if fields.get("children") is Some(Array(children)) {
      for child in children {
        result.append(keyed_lifetime_texts(child))
      }
    }
  }
  result
}

///|
fn keyed_lifetime_snapshot_texts(
  runtime : @minimoon.PageRuntime,
  id : String,
) -> Array[String] {
  let snapshot = @json.parse(runtime.snapshot()) catch {
    _ => abort("invalid runtime snapshot")
  }
  keyed_lifetime_texts(keyed_lifetime_find(snapshot, id).unwrap())
}

///|
test "keyed empty rows preserve local state on moves and refresh or dispose event handlers" {
  let scopes : Map[String, Int] = Map([])
  let renders : Map[String, Int] = Map([])
  let definition = @minimoon.page(
    id="keyed_lifetime",
    route=@minimoon.route("pages/keyed-lifetime/index"),
    title="Keyed lifetime",
    build=_ => {
      let a : KeyedLifetimeRowSpec = { shape: Fragment, version: 1, }
      let b : KeyedLifetimeRowSpec = { shape: View, version: 1, }
      let (entries, set_entries) = @minimoon.create_variable(
        @vector.from_array([("a", a), ("b", b)]),
      )
      let (selected, set_selected) = @minimoon.create_variable("none")
      let rows = entries.assoc((key, input) => {
        scopes[key] = scopes.get(key).unwrap_or(0) + 1
        let (count, set_count) = @minimoon.create_variable(0)
        @minimoon.Val::map2(input, count, (spec, count) => {
          renders[key] = renders.get(key).unwrap_or(0) + 1
          let node = match spec.shape {
            Empty => @minimoon.nothing()
            EmptyFragment => @minimoon.fragment([])
            Fragment | View => {
              let pick = @minimoon.button(
                on_tap=@minimoon.batch([
                  set_count(current => current + 1),
                  set_selected(_ => key + ":v" + spec.version.to_string()),
                ]),
                event_key="row-" + key + "-pick",
                key +
                ":v" +
                spec.version.to_string() +
                ":count" +
                count.to_string(),
              )
              if spec.shape == Fragment {
                @minimoon.fragment([pick])
              } else {
                @minimoon.div([pick])
              }
            }
          }
          (key, node)
        })
      })
      let controls = @minimoon.div([
        @minimoon.button(
          event_key="rows-reverse",
          on_tap=set_entries(_ => @vector.from_array([("b", b), ("a", a)])),
          "reverse",
        ),
        @minimoon.button(
          event_key="rows-evolve",
          on_tap=set_entries(_ => {
            @vector.from_array([("a", { shape: View, version: 2, }), ("b", b)])
          }),
          "evolve and move",
        ),
        @minimoon.button(
          event_key="rows-empty-fragment",
          on_tap=set_entries(_ => {
            @vector.from_array([
              ("b", b),
              ("a", { shape: EmptyFragment, version: 3, }),
            ])
          }),
          "empty fragment and move",
        ),
        @minimoon.button(
          event_key="rows-show",
          on_tap=set_entries(_ => {
            @vector.from_array([
              ("a", { shape: Fragment, version: 4, }),
              ("b", b),
            ])
          }),
          "show and move",
        ),
        @minimoon.button(
          event_key="rows-empty",
          on_tap=set_entries(_ => {
            @vector.from_array([("b", b), ("a", { shape: Empty, version: 5, })])
          }),
          "empty and move",
        ),
        @minimoon.button(
          event_key="rows-remove",
          on_tap=set_entries(_ => @vector.from_array([("b", b)])),
          "remove",
        ),
        @minimoon.button(
          event_key="rows-restore",
          on_tap=set_entries(_ => {
            @vector.from_array([("a", { shape: View, version: 6, }), ("b", b)])
          }),
          "restore",
        ),
      ])
      @minimoon.Val::view2(rows, selected, (rows, selected) => {
        @minimoon.div([
          controls,
          @minimoon.p(id="selected-row", selected),
          @minimoon.div(
            id="keyed-rows",
            @minimoon.keyed_fragment(
              rows.to_array().map(entry => @minimoon.keyed(entry.0, entry.1)),
            ),
          ),
        ])
      })
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  let _ = runtime.mount()
  // Contract previews may also build scopes; measure only the mounted runtime.
  let mounted_scopes = (scopes["a"], scopes["b"])
  let mounted_renders = (renders["a"], renders["b"])
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v1:count0", "b:v1:count0",
  ])
  let _ = runtime.dispatch("row-a-pick", "{}")
  let _ = runtime.dispatch("row-b-pick", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v1:count1", "b:v1:count1",
  ])
  assert_eq(
    (renders["a"], renders["b"]),
    (mounted_renders.0 + 1, mounted_renders.1 + 1),
  )
  let before_reorder = (renders["a"], renders["b"])
  let _ = runtime.dispatch("rows-reverse", "{}")
  assert_eq((scopes["a"], scopes["b"]), mounted_scopes)
  assert_eq((renders["a"], renders["b"]), before_reorder)
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "b:v1:count1", "a:v1:count1",
  ])
  let _ = runtime.dispatch("row-a-pick", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "selected-row"), ["a:v1"])
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "b:v1:count1", "a:v1:count2",
  ])
  let before_evolve = renders["a"]
  let _ = runtime.dispatch("rows-evolve", "{}")
  assert_eq((scopes["a"], scopes["b"]), mounted_scopes)
  assert_eq((renders["a"], renders["b"]), (before_evolve + 1, before_reorder.1))
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v2:count2", "b:v1:count1",
  ])
  let _ = runtime.dispatch("row-a-pick", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "selected-row"), ["a:v2"])
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v2:count3", "b:v1:count1",
  ])
  let _ = runtime.dispatch("rows-empty-fragment", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "b:v1:count1",
  ])
  let empty_fragment_snapshot = runtime.snapshot()
  assert_true(runtime.dispatch("row-a-pick", "{}").contains("unknown_event"))
  assert_eq(runtime.snapshot(), empty_fragment_snapshot)
  let _ = runtime.dispatch("rows-show", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v4:count3", "b:v1:count1",
  ])
  let _ = runtime.dispatch("row-a-pick", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "selected-row"), ["a:v4"])
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v4:count4", "b:v1:count1",
  ])
  let _ = runtime.dispatch("rows-empty", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "b:v1:count1",
  ])
  let empty_snapshot = runtime.snapshot()
  assert_true(runtime.dispatch("row-a-pick", "{}").contains("unknown_event"))
  assert_eq(runtime.snapshot(), empty_snapshot)
  assert_eq((scopes["a"], scopes["b"]), mounted_scopes)
  let _ = runtime.dispatch("rows-remove", "{}")
  let removed_snapshot = runtime.snapshot()
  assert_true(runtime.dispatch("row-a-pick", "{}").contains("unknown_event"))
  assert_eq(runtime.snapshot(), removed_snapshot)
  let before_restore = renders["a"]
  let _ = runtime.dispatch("rows-restore", "{}")
  assert_eq(
    (scopes["a"], scopes["b"]),
    (mounted_scopes.0 + 1, mounted_scopes.1),
  )
  assert_eq(renders["a"], before_restore + 1)
  assert_eq(renders["b"], before_reorder.1)
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v6:count0", "b:v1:count1",
  ])
  let _ = runtime.dispatch("row-a-pick", "{}")
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "selected-row"), ["a:v6"])
  assert_eq(keyed_lifetime_snapshot_texts(runtime, "keyed-rows"), [
    "a:v6:count1", "b:v1:count1",
  ])
  let _ = runtime.dispose()
}

///|
test "semantics stay typed in the normalized tree and shared WXML" {
  let definition = @minimoon.page(
    id="semantic_surface",
    route=@minimoon.route("pages/semantic-surface/semantic-surface"),
    title="Semantic surface",
    build=_ => {
      @minimoon.Val::constant(
        @minimoon.div(
          semantics=@minimoon.semantics(role=NavigationRole, label="Primary"),
          [
            @minimoon.button(
              id="semantic-trigger",
              on_tap=@minimoon.none,
              semantics=@minimoon.semantics(
                role=ButtonRole,
                expanded=false,
                controls="semantic-panel",
              ),
              "Toggle",
            ),
          ],
        ),
      )
    },
  )
  let snapshot = definition.create_runtime().unwrap().snapshot()
  assert_true(snapshot.contains("\"role\":\"navigation\""))
  assert_true(snapshot.contains("\"ariaLabel\":\"Primary\""))
  assert_true(snapshot.contains("\"ariaExpanded\":false"))
  assert_true(snapshot.contains("\"ariaControls\":\"semantic-panel\""))
  let wxml = definition.wxml()
  assert_true(wxml.contains("minimoon.templates.wxml"))
}
