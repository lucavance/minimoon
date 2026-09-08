///|
struct PageProgramTestModel {
  count : Int
  name : String
  ready : Bool
}

///|
enum PageProgramTestMsg {
  Increment
  Rename(String)
  Loaded(String)
  Visible
}

///|
fn page_program_test_fixture(
  model? : PageProgramTestModel = { count: 1, name: "Minimoon", ready: false, },
) -> PageProgram[PageProgramTestModel, PageProgramTestMsg] {
  simple_page_program(
    id="profile",
    route="pages/profile/profile",
    title="Profile",
    model~,
    update=(current, msg) => {
      match msg {
        Increment => { ..current, count: current.count + 1, }
        Rename(name) => { ..current, name, }
        Loaded(value) => {
          let _ = value
          current
        }
        Visible => { ..current, ready: true, }
      }
    },
    view=(events, current) => {
      let _ = events.tap("Increment", Increment)
      let _ = events.input_value("Rename", value => Rename(value))
      @ui.div([
        @ui.h1(current.name),
        @ui.fragment([@ui.text("count: "), @ui.text(current.count.to_string())]),
        @ui.fragment([@ui.text("ready: "), @ui.text(current.ready.to_string())]),
      ])
    },
    capabilities=[
      miniapp_capability("wx.getStorage"),
      miniapp_capability("wx.navigateTo"),
      miniapp_capability("wx.navigateBack"),
    ],
    lifecycle=[
      lifecycle_event(page_lifecycle_hook("onLoad"), payload => {
        Ok(Loaded(event_detail_value(payload)))
      }),
      lifecycle_message(page_lifecycle_hook("onShow"), Visible),
    ],
    inputs=[string_page_input("name", value => Rename(value))],
  )
}

///|
priv struct LatestSubscriptionModel {
  revision : Int
  seen : Int
}

///|
priv enum LatestSubscriptionMsg {
  AdvanceSubscriptionModel
  ObserveSubscription(Int)
}

///|
test "retained host subscription keeps one handle and dispatches its latest message" {
  let program = simple_page_program(
    id="latest_subscription",
    route="pages/latest-subscription/latest-subscription",
    title="Latest subscription",
    model={ revision: 1, seen: 0, },
    update=(model, message) => {
      match message {
        AdvanceSubscriptionModel => { ..model, revision: model.revision + 1, }
        ObserveSubscription(revision) => { ..model, seen: revision, }
      }
    },
    view=(events, model) => {
      let advance = events.tap("advance", AdvanceSubscriptionModel)
      @ui.button(
        on_click=advance.key(),
        model.revision.to_string() + ":" + model.seen.to_string(),
      )
    },
    subscriptions=model => {
      subscriptions([
        every(
          key="retained-clock",
          interval_ms=1000,
          msg=ObserveSubscription(model.revision),
        ),
      ])
    },
  )
  let runtime = program.create_runtime()
  let mounted = runtime.mount()
  assert_true(mounted.contains("StartSubscription"))
  assert_true(mounted.contains("retained-clock"))
  let advanced = runtime.dispatch("advance", "{}")
  assert_false(advanced.contains("StartSubscription"))
  assert_false(advanced.contains("StopSubscription"))
  let _ = runtime.subscription("retained-clock", "{}")
  assert_true(runtime.snapshot().contains("2:2"))
  let disposed = runtime.dispose()
  assert_true(disposed.contains("StopSubscription"))
  assert_true(disposed.contains("retained-clock"))
}

///|
test "host capability and event names round trip comprehensively" {
  for
    name in [
      "wx.login", "wx.getStorage", "wx.setStorage", "wx.request", "wx.showToast",
      "wx.getLocation", "wx.chooseMedia", "wx.requestPayment", "wx.navigateTo", "wx.redirectTo",
      "wx.navigateBack", "custom.echo",
    ] {
    assert_eq(miniapp_capability(name).name(), name)
  }
  for name in ["tap", "input", "change", "submit", "longpress"] {
    assert_eq(page_event_kind(name).host_name(), name)
  }
  let empty : Subscriptions[Unit] = no_subscriptions()
  let _ = empty

  let registry : Events[Unit] = events()
  assert_eq(registry.owner_id(), 0)
  let committed = Ref(false)
  registry.on_candidate_commit(fn() { committed.val = true })
  assert_true(committed.val)
  registry.reject("expected test rejection")
  registry.on_candidate_rollback(fn() {  })
  registry.on_scope_cleanup("test", fn() {  })
  assert_eq(registry.entries().length(), 0)
}

///|
test "typed page program owns route, dynamic tree, view, and capabilities" {
  let program = page_program_test_fixture()
  assert_eq(program.id(), "profile")
  assert_eq(program.route(), "pages/profile/profile")
  assert_eq(program.title(), "Profile")
  assert_eq(
    program.initial_tree().stringify().contains("\"text\":\"Minimoon\""),
    true,
  )
  assert_eq(
    program.capabilities().map(capability => capability.name()).join(","),
    "wx.getStorage,wx.navigateTo,wx.navigateBack",
  )
  assert_eq(
    @ui.render_to_string(program.render()),
    "<div><h1>Minimoon</h1>count: 1ready: false</div>",
  )
  assert_eq(
    program
    .wxml()
    .has_prefix("<import src=\"../../minimoon.templates.wxml\" />"),
    true,
  )
  let contract = program.contract_json()
  match contract {
    Object(fields) => {
      assert_eq(fields["schemaVersion"], Json::number(10.0, repr="10"))
      assert_eq(fields["runtimeApiVersion"], Json::number(12.0, repr="12"))
      assert_eq(fields["rendererProtocolVersion"], Json::number(8.0, repr="8"))
      assert_eq(fields["route"], Json::string("pages/profile/profile"))
      assert_eq(fields.contains("events"), false)
    }
    _ => fail("expected page contract object")
  }
}

///|
test "dynamic tree normalization maps concrete values and typed events" {
  let node = @ui.div(class="page min-h-[100vh]", [
    @ui.h1(class="title", "Minimoon"),
    @ui.input(class="input", attrs=[
      @ui.value_attr("Minimoon"),
      @ui.attr("on_input", "Rename"),
      @ui.attr("placeholder", "Name"),
    ]),
    @ui.button(on_click="Increment", "Save <now>"),
  ])
  let tree = normalize_miniapp_tree(node, [
    tap_event("Increment", Increment),
    input_value_event("Rename", value => Rename(value)),
  ]).stringify()
  assert_eq(tree.contains("\"className\":\"page min-h-_b100vh_B\""), true)
  assert_eq(tree.contains("\"text\":\"Minimoon\""), true)
  assert_eq(tree.contains("\"input\":\"Rename\""), true)
  assert_eq(tree.contains("\"tap\":\"Increment\""), true)
}

///|
test "generated WXML keeps textarea and picker model bindings host-safe" {
  let wxml = dynamic_templates_wxml()
  assert_eq(
    wxml.contains(
      "<textarea wx:elif=\"{{node.kind === 'textarea'}}\" id=\"{{p.id}}\"",
    ),
    true,
  )
  assert_eq(wxml.contains("model:value=\"{{p.value}}\""), true)
  assert_eq(wxml.contains("bind:input=\"__mmDispatchInput\""), true)
  assert_true(wxml.contains("bind:focus=\"__mmDispatchFocus\""))
  assert_true(wxml.contains("bind:blur=\"__mmDispatchBlur\""))
  assert_eq(wxml.contains("bind:change=\"__mmDispatchChange\""), true)
  assert_eq(wxml.contains("</textarea>"), true)
  assert_true(wxml.contains("aria-role=\"{{p.role}}\""))
  assert_true(wxml.contains("aria-expanded=\"{{p.ariaExpanded}}\""))
  assert_true(wxml.contains("aria-checked=\"{{p.ariaChecked}}\""))
  assert_true(wxml.contains("aria-modal=\"{{p.ariaModal}}\""))
  assert_true(wxml.contains("aria-describedby=\"{{p.ariaDescribedBy}}\""))
  assert_true(wxml.contains("aria-labelledby=\"{{p.ariaLabelledBy}}\""))
}

///|
test "generated page WXML imports the shared recursive template" {
  let wxml = dynamic_page_wxml(
    "controls",
    templates_src="../../../minimoon.templates.wxml",
  )
  assert_eq(
    wxml,
    "<import src=\"../../../minimoon.templates.wxml\" />\n" +
    "<template is=\"minimoon_dynamic_node\" data=\"{{node: controls.tree, p: controls.tree.props, e: controls.tree.events}}\" />\n",
  )
  assert_false(wxml.contains("<template name="))
}

///|
test "recursive WXML passes short aliases without dropping node or event bindings" {
  let wxml = dynamic_templates_wxml()
  let calls = wxml.split("is=\"minimoon_dynamic_node\"").length() - 1
  assert_true(calls > 10)
  assert_eq(wxml.split("p: child.props, e: child.events").length() - 1, calls)
  assert_true(wxml.contains("{{node.children}}"))
  assert_true(wxml.contains("{{p.ariaValueNow}}"))
  assert_true(wxml.contains("{{e.touchcancel}}"))
  assert_true(wxml.contains("catchtouchmove=\"__mmDispatchTouchMove\""))
  assert_true(wxml.length() < 20000)
}

///|
enum CurrentEventTestMsg {
  CurrentChanged(Int)
}

///|
enum DecoderEventTestMsg {
  BoolChanged(Bool)
  TextChanged(String)
  StringsChanged(Array[String])
  IndexChanged(Int)
  ScrollChanged(MiniappScrollDetail)
  DecoderTapped
}

///|
fn detail_payload(value : Json) -> Json {
  Json::object({ "detail": Json::object({ "value": value }) })
}

///|
fn scroll_detail_fields() -> Map[String, Json] {
  {
    "scrollLeft": Json::number(1.25, repr="1.25"),
    "scrollTop": Json::number(42.5, repr="42.5"),
    "scrollHeight": Json::number(300.75, repr="300.75"),
    "scrollWidth": Json::number(100.125, repr="100.125"),
    "deltaX": Json::number(-0.5, repr="-0.5"),
    "deltaY": Json::number(5.25, repr="5.25"),
  }
}

///|
test "typed event helpers cover valid, malformed, scoped, and scroll payloads" {
  let registry : Events[DecoderEventTestMsg] = events()
  let bool_event = registry.change_bool("bool", value => BoolChanged(value))
  assert_true(
    bool_event.decode(detail_payload(Json::boolean(true)))
    is Ok(BoolChanged(true)),
  )
  assert_true(bool_event.decode(detail_payload(Json::string("bad"))) is Err(_))
  assert_true(bool_event.decode(Json::string("bad")) is Err(_))

  let text_event = registry.change_string("text", value => TextChanged(value))
  assert_true(
    text_event.decode(detail_payload(Json::string("moon")))
    is Ok(TextChanged("moon")),
  )
  assert_true(
    text_event.decode(detail_payload(Json::number(7.0, repr="7"))) is Err(_),
  )

  let strings_event = registry.change_strings("strings", values => {
    StringsChanged(values)
  })
  assert_true(
    strings_event.decode(
      detail_payload(Json::array([Json::string("a"), Json::string("b")])),
    )
    is Ok(StringsChanged(["a", "b"])),
  )
  assert_true(
    strings_event.decode(
      detail_payload(Json::array([Json::string("a"), Json::number(1.0)])),
    )
    is Err(_),
  )
  assert_true(
    strings_event.decode(detail_payload(Json::string("bad"))) is Err(_),
  )

  let index_event = registry.change_index("index", value => IndexChanged(value))
  assert_true(
    index_event.decode(detail_payload(Json::string("12")))
    is Ok(IndexChanged(12)),
  )
  assert_true(
    index_event.decode(detail_payload(Json::number(3.0, repr="3")))
    is Ok(IndexChanged(3)),
  )
  assert_true(
    index_event.decode(
      detail_payload(Json::number(2147483647.0, repr="2147483647")),
    )
    is Ok(IndexChanged(2147483647)),
  )
  assert_true(
    index_event.decode(detail_payload(Json::string("2147483647")))
    is Ok(IndexChanged(2147483647)),
  )
  assert_true(index_event.decode(detail_payload(Json::string(""))) is Err(_))
  assert_true(index_event.decode(detail_payload(Json::string("1x"))) is Err(_))
  for
    invalid in [
      Json::number(-1.0, repr="-1"),
      Json::number(1.5, repr="1.5"),
      Json::number(2147483648.0, repr="2147483648"),
      Json::string("2147483648"),
      Json::boolean(true),
    ] {
    assert_true(index_event.decode(detail_payload(invalid)) is Err(_))
  }

  let scroll_event = registry.scroll("scroll", value => ScrollChanged(value))
  let scroll_payload = Json::object({
    "detail": Json::object(scroll_detail_fields()),
  })
  match scroll_event.decode(scroll_payload) {
    Ok(ScrollChanged(detail)) => {
      assert_eq(detail.scroll_left, 1.25)
      assert_eq(detail.scroll_top, 42.5)
      assert_eq(detail.scroll_height, 300.75)
      assert_eq(detail.scroll_width, 100.125)
      assert_eq(detail.delta_x, -0.5)
      assert_eq(detail.delta_y, 5.25)
    }
    _ => fail("scroll detail must decode")
  }
  for
    name in [
      "scrollLeft", "scrollTop", "scrollHeight", "scrollWidth", "deltaX", "deltaY",
    ] {
    let fields = scroll_detail_fields()
    fields.remove(name)
    assert_true(
      scroll_event.decode(Json::object({ "detail": Json::object(fields) }))
      is Err(_),
    )
  }
  let wrong_scroll = scroll_detail_fields()
  wrong_scroll["scrollTop"] = Json::string("42.5")
  assert_true(
    scroll_event.decode(Json::object({ "detail": Json::object(wrong_scroll) }))
    is Err(_),
  )
  assert_true(scroll_event.decode(Json::empty_object()) is Err(_))

  let child : Events[DecoderEventTestMsg] = events()
  let _ = child.tap("tap", DecoderTapped)
  registry.include_scoped("child", child, message => message)
  assert_true(registry.entries().any(event => event.key() == "child/tap"))
  registry.include_scoped("", child, message => message)
  registry.include_scoped("bad/scope", child, message => message)
  registry.include_scoped("child", child, message => message)
  let child_subscriptions = subscriptions([
    every(key="tick", interval_ms=10, msg=DecoderTapped),
  ])
  registry.include_scoped_subscriptions("child", child_subscriptions, (
    message : DecoderEventTestMsg,
  ) => message)
}

///|
test "page metadata accessors and boundary decoders are observable" {
  let input = string_page_input("name", value => TextChanged(value))
  assert_eq(input.name(), "name")
  assert_true(input.decode("Mini") is Ok(TextChanged("Mini")))
  let lifecycle = lifecycle_message(
    page_lifecycle_hook("onShow"),
    DecoderTapped,
  )
  assert_true(lifecycle.hook() is Show)
  assert_true(lifecycle.decode(Json::empty_object()) is Ok(DecoderTapped))
  assert_eq(event_detail_value(Json::string("invalid")), "")
  assert_eq(
    event_detail_value(
      Json::object({
        "detail": Json::object({ "value": Json::number(9.0, repr="9") }),
      }),
    ),
    "9",
  )

  let program = page_program_test_fixture()
  assert_eq(program.initial_model().count, 1)
  let _ = program.component()
  assert_eq(program.events().length(), 2)
  assert_eq(program.lifecycle().length(), 2)
  assert_eq(program.inputs().length(), 1)
}

///|
test "page runtime rejects every malformed batch and payload envelope atomically" {
  let runtime = page_program_test_fixture().create_runtime()
  let before = runtime.snapshot()
  for batch in ["{", "{}", "[1]", "[{\"payload\":{}}]", "[{\"key\":1}]"] {
    assert_true(runtime.dispatch_batch(batch).contains("invalid_event_batch"))
    assert_eq(runtime.snapshot(), before)
  }
  assert_true(runtime.lifecycle("onShow", "{").contains("invalid_host_payload"))
  assert_true(
    runtime
    .resolve_effect("missing", "failure", "{")
    .contains("invalid_host_payload"),
  )
}

///|
test "swiper current decoder consumes detail.current rather than picker value" {
  let registry : Events[CurrentEventTestMsg] = events()
  let event = registry.change_current("slide", current => {
    CurrentChanged(current)
  })
  match
    event.decode(
      Json::object({
        "detail": Json::object({ "current": Json::number(1.0, repr="1") }),
      }),
    ) {
    Ok(CurrentChanged(current)) => assert_eq(current, 1)
    _ => fail("expected decoded swiper current index")
  }
  assert_eq(
    event.decode(
      Json::object({
        "detail": Json::object({ "value": Json::number(1.0, repr="1") }),
      }),
    )
    is Err(_),
    true,
  )
  assert_true(
    event.decode(
      Json::object({
        "detail": Json::object({
          "current": Json::number(2147483647.0, repr="2147483647"),
        }),
      }),
    )
    is Ok(CurrentChanged(2147483647)),
  )
  for
    invalid in [
      Json::number(-1.0, repr="-1"),
      Json::number(1.5, repr="1.5"),
      Json::number(2147483648.0, repr="2147483648"),
      Json::string("1"),
    ] {
    assert_true(
      event.decode(
        Json::object({ "detail": Json::object({ "current": invalid }) }),
      )
      is Err(_),
    )
  }
}

///|
test "typed page events decode input payloads without exposing host objects" {
  let program = page_program_test_fixture()
  let payload = Json::object({
    "detail": Json::object({ "value": Json::string("MoonBit") }),
  })
  match program.decode_event("Rename", payload) {
    Ok(Some(Rename(value))) => assert_eq(value, "MoonBit")
    _ => fail("expected decoded Rename message")
  }
  match program.decode_event("Increment", Json::empty_object()) {
    Ok(Some(Increment)) => ()
    _ => fail("expected decoded Increment message")
  }
  assert_eq(
    program.decode_event("Missing", Json::empty_object()) is Ok(None),
    true,
  )
}

///|
test "typed page lifecycle and query inputs decode to application messages" {
  let program = page_program_test_fixture()
  match
    program.decode_lifecycle(
      page_lifecycle_hook("onShow"),
      Json::empty_object(),
    ) {
    Ok(Some(Visible)) => ()
    _ => fail("expected onShow message")
  }
  match program.decode_input("name", "Settings") {
    Ok(Some(Rename(value))) => assert_eq(value, "Settings")
    _ => fail("expected page input message")
  }
  assert_eq(program.decode_input("missing", "value") is Ok(None), true)
}

///|
test "ABI v12 page runtime mounts, dispatches, snapshots, and disposes one page" {
  let runtime = page_program_test_fixture().create_runtime()
  assert_eq(runtime_api_version(), 12)
  assert_eq(runtime.page_id(), "profile")
  assert_eq(
    runtime.mount(),
    "[{\"type\":\"MountContext\",\"component_id\":\"profile\"}]",
  )
  let increment = runtime.dispatch("Increment", "{}")
  assert_eq(increment.contains("\"type\":\"PatchViewTree\""), true)
  assert_eq(increment.contains("\"base_revision\":0"), true)
  assert_eq(increment.contains("\"revision\":1"), true)
  assert_eq(increment.contains("\"op\":\"set\""), true)
  assert_eq(increment.contains("\"value\":\"2\""), true)
  assert_eq(
    runtime
    .dispatch("Rename", "{\"detail\":{\"value\":\"MoonBit\"}}")
    .contains("MoonBit"),
    true,
  )
  assert_eq(runtime.lifecycle("onShow", "{}").contains("true"), true)
  assert_eq(runtime.snapshot().contains("MoonBit"), true)
  assert_eq(
    runtime.dispose(),
    "[{\"type\":\"DisposeContext\",\"component_id\":\"profile\"}]",
  )
  assert_eq(runtime.dispatch("Increment", "{}"), "[]")
}

///|
test "page runtime batches adjacent events into one host-visible revision" {
  let runtime = page_program_test_fixture().create_runtime()
  let _ = runtime.mount()
  let result = runtime.dispatch_batch(
    "[{\"key\":\"Increment\",\"payload\":{}},{\"key\":\"Increment\",\"payload\":{}}]",
  )
  assert_true(result.contains("\"type\":\"PatchViewTree\""))
  assert_true(result.contains("\"revision\":1"))
  assert_true(result.contains("\"value\":\"3\""))
  assert_true(runtime.snapshot().contains("\"text\":\"3\""))
}

///|
test "page runtime predecodes an event batch atomically" {
  let runtime = page_program_test_fixture().create_runtime()
  let _ = runtime.mount()
  let before = runtime.snapshot()
  let rejected = runtime.dispatch_batch(
    "[{\"key\":\"Increment\",\"payload\":{}},{\"key\":\"Rename\",\"payload\":{}}]",
  )
  assert_true(rejected.contains("event_decode_failed"))
  assert_eq(runtime.snapshot(), before)
  let unknown = runtime.dispatch_batch(
    "[{\"key\":\"Increment\",\"payload\":{}},{\"key\":\"Missing\",\"payload\":{}}]",
  )
  assert_true(unknown.contains("unknown_event"))
  assert_eq(runtime.snapshot(), before)
}

///|
test "page runtime rejects event batches above the hard limit" {
  let runtime = page_program_test_fixture().create_runtime()
  let entries = Array::make(
    2049,
    Json::object({
      "key": Json::string("Increment"),
      "payload": Json::empty_object(),
    }),
  )
  let result = runtime.dispatch_batch(Json::array(entries).stringify())
  assert_true(result.contains("event_batch_too_large"))
  assert_true(runtime.snapshot().contains("\"text\":\"1\""))
}

///|
struct HostWriteBudgetModel {
  changed : Bool
}

///|
enum HostWriteBudgetMsg {
  ChangeAll
}

///|
test "renderer v6 replaces when an otherwise safe patch exceeds 32 host writes" {
  let program = simple_page_program(
    id="host_write_budget",
    route="pages/host-write-budget/host-write-budget",
    title="Host write budget",
    model={ changed: false, },
    update=(model, msg) => {
      match msg {
        ChangeAll => {
          let _ = model
          { changed: true, }
        }
      }
    },
    view=(events, model) => {
      let _ = events.tap("ChangeAll", ChangeAll)
      @ui.fragment(
        Array::makei(33, index => {
          @ui.button(
            on_click="ChangeAll",
            (if model.changed { "after " } else { "before " }) +
            index.to_string(),
          )
        }),
      )
    },
  )
  let result = program.create_runtime().dispatch("ChangeAll", "{}")
  assert_eq(result.contains("\"type\":\"ReplaceViewTree\""), true)
  assert_eq(result.contains("\"type\":\"PatchViewTree\""), false)
}

///|
test "ABI v12 rejects malformed payloads and unknown host inputs explicitly" {
  let runtime = page_program_test_fixture().create_runtime()
  let initial = runtime.snapshot()
  assert_eq(
    runtime.dispatch("Increment", "{").contains("invalid_host_payload"),
    true,
  )
  assert_eq(runtime.snapshot(), initial)
  assert_eq(
    runtime.dispatch("Rename", "{}").contains("event_decode_failed"),
    true,
  )
  assert_eq(runtime.snapshot(), initial)
  assert_eq(runtime.dispatch("Missing", "{}").contains("unknown_event"), true)
  assert_eq(runtime.dispatch("", "{"), "[]")
  assert_eq(
    runtime.lifecycle("notAWeChatHook", "{}").contains("unknown_lifecycle"),
    true,
  )
}

///|
test "ABI v12 rejects page input and lifecycle decode failures before Model update" {
  let program = simple_page_program(
    id="decode_boundary",
    route="pages/decode-boundary/decode-boundary",
    title="Decode boundary",
    model={ count: 1, name: "stable", ready: false, },
    update=(model, msg) => {
      match msg {
        Increment => { ..model, count: model.count + 1, }
        Rename(name) => { ..model, name, }
        Loaded(_) => { ..model, name: "loaded", }
        Visible => { ..model, ready: true, }
      }
    },
    view=(_events, model) => @ui.h1(model.name),
    inputs=[page_input("name", _ => Err(decode_error("invalid query")))],
    lifecycle=[
      lifecycle_event(page_lifecycle_hook("onShow"), _ => {
        Err(decode_error("invalid lifecycle"))
      }),
    ],
  )
  let runtime = program.create_runtime()
  let initial = runtime.snapshot()
  assert_eq(
    runtime
    .lifecycle("onLoad", "{\"name\":\"changed\"}")
    .contains("page_input_decode_failed"),
    true,
  )
  assert_eq(runtime.snapshot(), initial)
  assert_eq(
    runtime.lifecycle("onShow", "{}").contains("lifecycle_decode_failed"),
    true,
  )
  assert_eq(runtime.snapshot(), initial)
}

///|
struct InvalidViewModel {
  broken : Bool
}

///|
enum InvalidViewMsg {
  BreakView
}

///|
test "ABI v12 rolls back Model when the next dynamic view is invalid" {
  let program = simple_page_program(
    id="invalid_view",
    route="pages/invalid-view/invalid-view",
    title="Invalid view",
    model={ broken: false, },
    update=(model, msg) => {
      match msg {
        BreakView => {
          let _ = model
          { broken: true, }
        }
      }
    },
    view=(events, model) => {
      let _ = events.tap("BreakView", BreakView)
      if model.broken {
        @ui.keyed_fragment([
          @ui.keyed("duplicate", @ui.text("first")),
          @ui.keyed("duplicate", @ui.text("second")),
        ])
      } else {
        @ui.text("valid")
      }
    },
  )
  let runtime = program.create_runtime()
  let initial = runtime.snapshot()
  let result = runtime.dispatch("BreakView", "{}")
  assert_eq(result.contains("RuntimeError"), true)
  assert_eq(result.contains("invalid_view"), true)
  assert_eq(runtime.snapshot(), initial)
}

///|
struct BranchEventModel {
  visible : Bool
  hidden_hits : Int
}

///|
enum BranchEventMsg {
  ToggleBranch
  HiddenBranchTap
}

///|
test "render-scoped events remove handlers with their dynamic branch" {
  let program = simple_page_program(
    id="branch_events",
    route="pages/branch-events/branch-events",
    title="Branch events",
    model={ visible: true, hidden_hits: 0, },
    update=(model, msg) => {
      match msg {
        ToggleBranch => { ..model, visible: !model.visible, }
        HiddenBranchTap => { ..model, hidden_hits: model.hidden_hits + 1, }
      }
    },
    view=(events, model) => {
      let toggle = events.tap("toggle", ToggleBranch)
      @ui.fragment([
        @ui.button(on_click=toggle.key(), "toggle"),
        if model.visible {
          let hidden = events.tap("hidden", HiddenBranchTap)
          @ui.button(on_click=hidden.key(), "hidden")
        } else {
          @ui.nothing()
        },
        @ui.text(model.hidden_hits.to_string()),
      ])
    },
  )
  let runtime = program.create_runtime()
  let _ = runtime.dispatch("hidden", "{}")
  assert_eq(runtime.snapshot().contains("\"text\":\"1\""), true)
  let _ = runtime.dispatch("toggle", "{}")
  let committed = runtime.snapshot()
  assert_eq(runtime.dispatch("hidden", "{}").contains("unknown_event"), true)
  assert_eq(runtime.snapshot(), committed)
}

///|
test "dynamic tree validation rejects duplicate keyed siblings" {
  let node = @ui.keyed_fragment([
    @ui.keyed("same", @ui.text("first")),
    @ui.keyed("same", @ui.text("second")),
  ])
  let events : Array[PageEvent[InvalidViewMsg]] = []
  match normalize_miniapp_tree_checked(node, events) {
    Err(error) => assert_eq(error.contains("duplicate"), true)
    Ok(_) => fail("expected duplicate keyed sibling error")
  }
}

///|
enum EffectRuntimeMsg {
  StartEffect
  EffectSucceeded(String)
  EffectFailed(String)
}

///|
struct EffectRuntimeModel {
  status : String
}

///|
fn effect_runtime_program() -> PageProgram[EffectRuntimeModel, EffectRuntimeMsg] {
  page_program(
    id="effect",
    route="pages/effect/effect",
    title="Effect",
    model={ status: "idle", },
    update=(_model, msg) => {
      match msg {
        StartEffect =>
          @runtime.with_cmd(
            { status: "pending", },
            @runtime.host_effect(
              @runtime.host_effect_request("wx.login", "{}"),
              outcome => {
                match outcome {
                  @runtime.HostEffectOk(value) => EffectSucceeded(value)
                  @runtime.HostEffectErr(_, error, _) => EffectFailed(error)
                }
              },
            ),
          )
        EffectSucceeded(value) => @runtime.no_cmd({ status: "ok:" + value, })
        EffectFailed(error) => @runtime.no_cmd({ status: "err:" + error, })
      }
    },
    view=(events, model) => {
      let _ = events.tap("StartEffect", StartEffect)
      @ui.h1(model.status)
    },
    capabilities=[miniapp_capability("wx.login")],
  )
}

///|
enum LocalEffectRuntimeMsg {
  StartLocalEffect
  ObserveLocalEffect
  CompleteLocalEffect(String)
}

///|
fn local_effect_runtime_program(
  saved_emit : Ref[((LocalEffectRuntimeMsg) -> Unit)?],
  saved_finish : Ref[(() -> Unit)?],
) -> PageProgram[String, LocalEffectRuntimeMsg] {
  page_program(
    id="local_effect",
    route="pages/local_effect/local_effect",
    title="Local effect",
    model="idle",
    update=(_model, msg) => {
      match msg {
        StartLocalEffect =>
          @runtime.with_cmd(
            "pending",
            @runtime.local_effect((emit, finish) => {
              saved_emit.val = Some(emit)
              saved_finish.val = Some(finish)
              fn() {  }
            }),
          )
        ObserveLocalEffect => @runtime.no_cmd(_model + ">ui")
        CompleteLocalEffect(value) => @runtime.no_cmd(_model + ">" + value)
      }
    },
    view=(events, model) => {
      let _ = events.tap("StartLocalEffect", StartLocalEffect)
      let _ = events.tap("ObserveLocalEffect", ObserveLocalEffect)
      @ui.h1(model)
    },
  )
}

///|
#cfg(target="js")
extern "js" fn install_runtime_wake_v12_for_test(wake : (Int) -> Unit) -> Unit =
  #|(wake) => { globalThis.__minimoonRuntimeWakeV12 = wake }

///|
#cfg(target="js")
extern "js" fn clear_runtime_wake_v12_for_test() -> Unit =
  #|() => { delete globalThis.__minimoonRuntimeWakeV12 }

///|
test "ABI v12 internal drain publishes asynchronous local effect commands" {
  let saved_emit : Ref[((LocalEffectRuntimeMsg) -> Unit)?] = Ref(None)
  let saved_finish : Ref[(() -> Unit)?] = Ref(None)
  let runtime = local_effect_runtime_program(saved_emit, saved_finish).create_runtime()
  let _ = runtime.mount()
  let started = runtime.dispatch("StartLocalEffect", "{}")
  assert_true(started.contains("pending"))
  saved_emit.val.unwrap()(CompleteLocalEffect("first"))
  saved_emit.val.unwrap()(CompleteLocalEffect("second"))
  saved_finish.val.unwrap()()
  assert_true(runtime.snapshot().contains("pending"))
  let invalid = runtime.lifecycle("$minimoon:drain", "{}")
  assert_true(invalid.contains("invalid_internal_drain"))
  assert_true(runtime.snapshot().contains("pending"))
  let first = runtime.lifecycle("$minimoon:drain", "{\"through\":1}")
  assert_true(first.contains("pending>first"))
  assert_true(runtime.snapshot().contains("pending>first"))
  let observed = runtime.dispatch("ObserveLocalEffect", "{}")
  assert_true(observed.contains("pending>first>ui"))
  assert_true(runtime.snapshot().contains("pending>first>ui"))
  let second = runtime.lifecycle("$minimoon:drain", "{\"through\":2}")
  assert_true(second.contains("pending>first>ui>second"))
  assert_true(runtime.snapshot().contains("pending>first>ui>second"))
  assert_eq(runtime.lifecycle("$minimoon:drain", "{\"through\":2}"), "[]")
}

///|
#cfg(target="js")
test "ABI v12 captures one transient host wake for asynchronous local effects" {
  let saved_emit : Ref[((LocalEffectRuntimeMsg) -> Unit)?] = Ref(None)
  let saved_finish : Ref[(() -> Unit)?] = Ref(None)
  let wakes : Ref[Array[Int]] = Ref([])
  install_runtime_wake_v12_for_test(fn(through) { wakes.val.push(through) })
  let runtime = local_effect_runtime_program(saved_emit, saved_finish).create_runtime()
  clear_runtime_wake_v12_for_test()
  let _ = runtime.mount()
  let _ = runtime.dispatch("StartLocalEffect", "{}")
  saved_emit.val.unwrap()(CompleteLocalEffect("first"))
  saved_emit.val.unwrap()(CompleteLocalEffect("second"))
  saved_finish.val.unwrap()()
  assert_eq(wakes.val, [1, 2])
  assert_true(runtime.snapshot().contains("pending"))
  assert_true(
    runtime
    .lifecycle("$minimoon:drain", "{\"through\":1}")
    .contains("pending>first"),
  )
  assert_true(
    runtime
    .lifecycle("$minimoon:drain", "{\"through\":2}")
    .contains("pending>first>second"),
  )
}

///|
test "ABI v12 effect completion resolves the original request ID exactly once" {
  let runtime = effect_runtime_program().create_runtime()
  let _ = runtime.mount()
  let started = runtime.dispatch("StartEffect", "{}")
  assert_eq(started.contains("pending"), true)
  assert_eq(started.contains("InvokeCapability"), true)
  assert_eq(
    runtime
    .resolve_effect("effect:0", "success", "{\"value\":\"code-123\"}")
    .contains("ok:code-123"),
    true,
  )
  assert_eq(
    runtime.resolve_effect("effect:0", "success", "{\"value\":\"again\"}"),
    "[]",
  )
}

///|
test "ABI v12 dispose cancels a pending effect before its context" {
  let runtime = effect_runtime_program().create_runtime()
  let _ = runtime.mount()
  let _ = runtime.dispatch("StartEffect", "{}")
  let disposed = runtime.dispose()
  assert_eq(disposed.contains("CancelEffect"), true)
  assert_eq(disposed.contains("effect:0"), true)
  assert_eq(disposed.contains("DisposeContext"), true)
  assert_eq(
    runtime.resolve_effect("effect:0", "success", "{\"value\":\"late\"}"),
    "[]",
  )
}
