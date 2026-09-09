///|
struct CardEntry {
  id : String
  props : @card.Props
} derive(Eq)

///|
struct Item {
  id : String
  label : String
  event_key : String
} derive(Eq)

///|
struct Slide {
  id : String
  label : String
} derive(Eq)

///|
pub struct Model {
  cards : Array[CardEntry]
  checked : Array[String]
  radio : String
  picker_options : Array[String]
  picker : Int
  slides : Array[Slide]
  slide : Int
  native_reconciled : Bool
  scroll_top : Double
  scroll_target : String
  ticks : Int
  count : Int
  expanded : Bool
  name : String
  focus_status : String
  focus_reorder_armed : Bool
  delay_probe_status : String
  perform_probe_status : String
  attempt_probe_status : String
  notes : Array[String]
  items : Array[Item]
  selected : String
  replace_root : Bool
} derive(Eq)

///|
pub enum Msg {
  ReorderCards
  RemoveSecondary
  RestoreSecondary
  Checked(Array[String])
  Radio(String)
  Picked(Int)
  Slid(Int)
  Scrolled(@minimoon.ScrollDetail)
  Jump(String)
  Tick
  Increment
  Toggle
  AddNote
  RemoveNote
  ReorderItems
  ArmFocusedReorder
  StartDelayProbe
  StartAsyncProbes
  DelayProbeCompleted
  PerformProbeCompleted(String)
  AttemptProbeCompleted(String)
  Rename(String)
  ResetControlledInput
  InputFocused(String)
  InputBlurred(String)
  InputConfirmed(String)
  ReconcileNativeControls
  Select(String)
  ForceReplace
  BackToStudio
}

///|
fn primary_card() -> CardEntry {
  {
    id: "primary",
    props: @card.props(
      id="primary-card",
      title="Primary card",
      pulse_step=1,
      tone="border-sky-200 bg-sky-50",
    ),
  }
}

///|
fn secondary_card() -> CardEntry {
  {
    id: "secondary",
    props: @card.props(
      id="secondary-card",
      title="Secondary card",
      pulse_step=2,
      tone="border-amber-200 bg-amber-50",
    ),
  }
}

///|
fn initial_model() -> Model {
  {
    cards: [primary_card(), secondary_card()],
    checked: ["typed"],
    radio: "moonbit",
    picker_options: ["MoonBit", "Skyline", "ArkUI"],
    picker: 0,
    slides: [
      { id: "first", label: "Swiper page 1", },
      { id: "second", label: "Swiper page 2", },
    ],
    slide: 0,
    native_reconciled: false,
    scroll_top: 0.0,
    scroll_target: "",
    ticks: 0,
    count: 0,
    expanded: false,
    name: "Minimoon",
    focus_status: "idle",
    focus_reorder_armed: false,
    delay_probe_status: "idle",
    perform_probe_status: "idle",
    attempt_probe_status: "idle",
    notes: ["note-0"],
    items: [
      { id: "a", label: "Item A", event_key: "dynamic/select-a", },
      { id: "b", label: "Item B", event_key: "dynamic/select-b", },
      { id: "c", label: "Item C", event_key: "dynamic/select-c", },
    ],
    selected: "",
    replace_root: false,
  }
}

///|
fn card_index(cards : Array[CardEntry], key : String) -> Int? {
  for index, card in cards {
    if card.id == key {
      return Some(index)
    }
  }
  None
}

///|
fn string_index(values : Array[String], expected : String) -> Int? {
  for index, value in values {
    if value == expected {
      return Some(index)
    }
  }
  None
}

///|
fn slide_index(slides : Array[Slide], expected : String) -> Int? {
  for index, slide in slides {
    if slide.id == expected {
      return Some(index)
    }
  }
  None
}

///|
fn update(model : Model, msg : Msg) -> Model {
  match msg {
    ReorderCards => {
      let cards = model.cards.copy()
      if cards.length() >= 2 {
        let first = cards[0]
        cards[0] = cards[1]
        cards[1] = first
      }
      { ..model, cards, }
    }
    RemoveSecondary => {
      let cards : Array[CardEntry] = []
      for card in model.cards {
        if card.id != "secondary" {
          cards.push(card)
        }
      }
      { ..model, cards, }
    }
    RestoreSecondary => {
      let cards = model.cards.copy()
      if card_index(cards, "secondary") is None {
        cards.push(secondary_card())
      }
      { ..model, cards, }
    }
    Checked(checked) => { ..model, checked, }
    Radio(radio) => { ..model, radio, }
    Picked(picker) => { ..model, picker, }
    Slid(slide) => { ..model, slide, }
    Scrolled(detail) =>
      { ..model, scroll_top: detail.scroll_top, scroll_target: "", }
    Jump(scroll_target) => { ..model, scroll_target, }
    Tick => { ..model, ticks: model.ticks + 1, }
    Increment => { ..model, count: model.count + 1, }
    Toggle => { ..model, expanded: !model.expanded, }
    AddNote => {
      let notes = model.notes.map(note => note)
      notes.push("note-" + notes.length().to_string())
      { ..model, notes, }
    }
    RemoveNote => {
      let notes : Array[String] = []
      if model.notes.length() > 0 {
        for index = 0; index < model.notes.length() - 1; index = index + 1 {
          notes.push(model.notes[index])
        }
      }
      { ..model, notes, }
    }
    ReorderItems => {
      let items = if model.items.length() == 3 {
        [model.items[2], model.items[0], model.items[1]]
      } else {
        model.items
      }
      { ..model, items, focus_reorder_armed: false, }
    }
    ArmFocusedReorder => { ..model, focus_reorder_armed: true, }
    StartDelayProbe => { ..model, delay_probe_status: "running:600ms", }
    StartAsyncProbes =>
      {
        ..model,
        perform_probe_status: "running:250ms",
        attempt_probe_status: "running:400ms",
      }
    DelayProbeCompleted => { ..model, delay_probe_status: "completed:600ms", }
    PerformProbeCompleted(value) =>
      { ..model, perform_probe_status: "succeeded:250ms:" + value, }
    AttemptProbeCompleted(value) => { ..model, attempt_probe_status: value, }
    Rename(name) => { ..model, name, }
    ResetControlledInput =>
      { ..model, name: "Minimoon", focus_status: "reset", }
    InputFocused(value) => { ..model, focus_status: "focus:" + value, }
    InputBlurred(value) => { ..model, focus_status: "blur:" + value, }
    InputConfirmed(value) => { ..model, focus_status: "confirm:" + value, }
    ReconcileNativeControls => {
      guard !model.native_reconciled else { model }
      let selected_option = model.picker_options[model.picker]
      let picker_options = ["Skyline", "ArkUI", "MoonBit"]
      let picker = string_index(picker_options, selected_option).unwrap_or(0)
      let selected_slide = model.slides[model.slide].id
      let slides = [model.slides[1], model.slides[0]]
      let slide = slide_index(slides, selected_slide).unwrap_or(0)
      let items = [model.items[2], model.items[0], model.items[1]]
      {
        ..model,
        picker_options,
        picker,
        slides,
        slide,
        native_reconciled: true,
        name: "Minimoon",
        focus_status: "reconciled",
        items,
        focus_reorder_armed: false,
      }
    }
    Select(selected) => { ..model, selected, }
    ForceReplace => { ..model, replace_root: !model.replace_root, }
    BackToStudio => model
  }
}

///|
async fn[T, E : Error] suspend_probe(
  callback : ((T) -> Unit, (E) -> Unit) -> Unit,
) -> T raise E = "%async.suspend"

///|
extern "js" fn resume_probe_after(
  resolve : (Unit) -> Unit,
  milliseconds : Int,
) -> Unit =
  #| (resolve, milliseconds) => { setTimeout(() => resolve(0), milliseconds) }

///|
async fn wait_for_probe(
  milliseconds : Int,
  schedule : ((Unit) -> Unit, Int) -> Unit,
) -> Unit noraise {
  suspend_probe(fn(resolve, _reject : (Failure) -> Unit) {
    schedule(resolve, milliseconds)
  }) catch {
    _ => ()
  }
}

///|
fn async_probe_command(
  emit : @minimoon.Emit[Msg],
  schedule : ((Unit) -> Unit, Int) -> Unit,
) -> @minimoon.Cmd {
  @minimoon.batch([
    @minimoon.perform(emit.map(value => PerformProbeCompleted(value)), async fn() noraise {
      wait_for_probe(250, schedule)
      "ready"
    }),
    @minimoon.attempt(
      emit.map(result => {
        match result {
          Ok(value) => AttemptProbeCompleted("unexpected:" + value)
          Err(_) => AttemptProbeCompleted("failed:400ms:planned")
        }
      }),
      async fn() -> String {
        wait_for_probe(400, schedule)
        raise Failure::Failure("planned async probe failure")
      },
    ),
  ])
}

///|
fn action(
  emit : @minimoon.Emit[Msg],
  key : String,
  message : Msg,
  label : String,
) -> @minimoon.Node {
  @minimoon.button(
    on_tap=emit(message),
    event_key=key,
    class="demo-action",
    label,
  )
}

///|
fn dynamic_section(emit : @minimoon.Emit[Msg], model : Model) -> @minimoon.Node {
  let notes = @minimoon.fragment(
    model.notes.map(note => @minimoon.p(class="text-[24rpx]", note)),
  )
  let focus_probe = [
    @minimoon.keyed(
      "focus-probe",
      @minimoon.input(
        value=model.name,
        on_input=emit.map(value => Rename(value)),
        event_key="dynamic/name",
        on_focus=emit.map(detail => InputFocused(detail.value)),
        focus_key="dynamic/name-focus",
        on_blur=emit.map(detail => InputBlurred(detail.value)),
        blur_key="dynamic/name-blur",
        on_confirm=emit.map(value => InputConfirmed(value)),
        confirm_key="dynamic/name-confirm",
        placeholder="Type a name",
        class="demo-input",
      ),
    ),
  ]
  for item in model.items {
    focus_probe.push(
      @minimoon.keyed(
        item.id,
        @minimoon.button(
          on_tap=emit(Select(item.id)),
          event_key=item.event_key,
          class="demo-action",
          item.label,
        ),
      ),
    )
  }
  let items = @minimoon.keyed_fragment(focus_probe)
  @minimoon.div(
    id="dynamic-lab",
    data_section="dynamic-lab",
    class="demo-card",
    [
      @minimoon.h1(class="demo-card-title", "动态渲染 / Dynamic renderer"),
      @minimoon.p(
        class="demo-muted",
        "Expected: set, splice, keyed move, and full replacement remain interactive.",
      ),
      @minimoon.p("count:" + model.count.to_string()),
      @minimoon.div(class="demo-actions", [
        action(emit, "dynamic/increment", Increment, "Increment"),
        action(emit, "dynamic/toggle", Toggle, "Toggle branch"),
        action(emit, "dynamic/add-note", AddNote, "Add row"),
        action(emit, "dynamic/remove-note", RemoveNote, "Remove row"),
        action(emit, "dynamic/reorder", ReorderItems, "Reorder keyed rows"),
        action(
          emit,
          "dynamic/reset-controlled-input",
          ResetControlledInput,
          "Reset controlled input",
        ),
        action(
          emit,
          "dynamic/arm-focused-reorder",
          ArmFocusedReorder,
          "Arm focused reorder (10s)",
        ),
        action(
          emit,
          "dynamic/start-delay",
          StartDelayProbe,
          "Start delay probe",
        ),
        action(
          emit,
          "dynamic/start-async",
          StartAsyncProbes,
          "Start async probes",
        ),
        action(emit, "dynamic/replace-root", ForceReplace, "Replace root"),
      ]),
      if model.expanded {
        @minimoon.div(
          class="mt-[12rpx] bg-emerald-50 px-[16rpx] py-[12rpx]",
          "expanded branch",
        )
      } else {
        @minimoon.fragment([
          @minimoon.p(class="mt-[12rpx] text-slate-500", "collapsed branch"),
        ])
      },
      @minimoon.p(
        "focused reorder probe: arm, refocus the input, then wait 10s",
      ),
      @minimoon.p("controlled input reset keeps the keyed native identity"),
      @minimoon.p("delay probe:" + model.delay_probe_status),
      @minimoon.p("perform probe:" + model.perform_probe_status),
      @minimoon.p("attempt probe:" + model.attempt_probe_status),
      @minimoon.div(class="demo-actions", [items]),
      @minimoon.p("hello:" + model.name),
      @minimoon.p("input event:" + model.focus_status),
      notes,
      @minimoon.p("selected:" + model.selected),
    ],
  )
}

///|
fn component_section(
  emit : @minimoon.Emit[Msg],
  model : Model,
  card_nodes : @vector.Vector[@minimoon.Node],
) -> @minimoon.Node {
  let rendered_cards = []
  for index = 0; index < model.cards.length(); index = index + 1 {
    rendered_cards.push(
      @minimoon.keyed(model.cards[index].id, card_nodes[index]),
    )
  }
  @minimoon.div(
    id="component-lab",
    data_section="component-lab",
    class="demo-card",
    [
      @minimoon.h1(class="demo-card-title", "局部组件 / Local components"),
      @minimoon.p(
        class="demo-muted",
        "Expected: reorder preserves state; removal disposes subscriptions.",
      ),
      @minimoon.div(class="demo-actions", [
        action(emit, "controls/reorder-cards", ReorderCards, "Reorder cards"),
        action(
          emit,
          "controls/remove-secondary",
          RemoveSecondary,
          "Remove secondary",
        ),
        action(
          emit,
          "controls/restore-secondary",
          RestoreSecondary,
          "Restore secondary",
        ),
      ]),
      @minimoon.keyed_fragment(rendered_cards),
    ],
  )
}

///|
fn control_section(emit : @minimoon.Emit[Msg], model : Model) -> @minimoon.Node {
  let options = model.picker_options
  let slides = @minimoon.keyed_fragment(
    model.slides.map(slide => {
      @minimoon.keyed(
        slide.id,
        @minimoon.swiper_item(
          item_id=slide.id,
          @minimoon.div(class="h-[120rpx] bg-sky-50", slide.label),
        ),
      )
    }),
  )
  @minimoon.div(
    id="control-lab",
    data_section="control-lab",
    class="demo-card",
    [
      @minimoon.h1(class="demo-card-title", "原生控件 / Native controls"),
      @minimoon.p(
        class="demo-muted",
        "Expected: every control updates independently without console errors.",
      ),
      @minimoon.checkbox_group(
        on_change=emit.map(value => Checked(value)),
        event_key="controls/checked",
        class="mt-[12rpx]",
        [
          @minimoon.checkbox(
            value="typed",
            checked=model.checked.contains("typed"),
            "typed",
          ),
          @minimoon.checkbox(
            value="scoped",
            checked=model.checked.contains("scoped"),
            "scoped",
          ),
        ],
      ),
      @minimoon.radio_group(
        on_change=emit.map(value => Radio(value)),
        event_key="controls/radio",
        class="mt-[12rpx]",
        [
          @minimoon.radio(
            value="moonbit",
            checked=model.radio == "moonbit",
            "MoonBit",
          ),
          @minimoon.radio(
            value="miniapp",
            checked=model.radio == "miniapp",
            "MiniApp",
          ),
        ],
      ),
      action(
        emit,
        "controls/reconcile-native",
        ReconcileNativeControls,
        "Reconcile controlled native values",
      ),
      @minimoon.picker_selector(
        id="control-picker",
        options~,
        selected=model.picker,
        on_change=emit.map(value => Picked(value)),
        event_key="controls/picker",
        class="mt-[12rpx]",
        "picker: " + options[model.picker],
      ),
      @minimoon.p("current swiper page: " + (model.slide + 1).to_string()),
      @minimoon.swiper(
        current=model.slide,
        circular=!model.native_reconciled,
        on_change=emit.map(value => Slid(value)),
        event_key="controls/slide",
        class="mt-[12rpx] h-[240rpx]",
        [slides],
      ),
      @minimoon.p(
        "native reconcile:" +
        (if model.native_reconciled { "completed" } else { "ready" }),
      ),
      @minimoon.navigator(
        target=@minimoon.route("pages/lab/lab").with_query([
          @minimoon.query("instance", "secondary"),
        ]),
        class="demo-action",
        "Open isolated Lab instance",
      ),
    ],
  )
}

///|
fn content_navigation_section(content : @minimoon.Node) -> @minimoon.Node {
  @minimoon.div(
    id="content-navigation-lab",
    data_section="content-navigation-lab",
    class="demo-card",
    [
      @minimoon.h1(class="demo-card-title", "内容导航 / Content navigation"),
      @minimoon.p(
        class="demo-muted",
        "Expected: minimal-v2 overlays, menus, and semantic state stay aligned after every interaction.",
      ),
      @minimoon.div(class="mt-[12rpx]", [content]),
    ],
  )
}

///|
fn view(
  model : Model,
  emit : @minimoon.Emit[Msg],
  card_nodes : @vector.Vector[@minimoon.Node],
  instance : String,
  content_navigation : @minimoon.Node,
  layout : @minimoon.PageLayout,
  notes : @minimoon.Node,
  diagnostics : Bool,
  toggle_diagnostics : @minimoon.Emit[(Bool) -> Bool],
  concise : Bool,
) -> @minimoon.Node {
  let content = @shell.frame(
    layout,
    "交互",
    "lab-page",
    scroll_target=model.scroll_target,
    on_scroll=emit.map(value => Scrolled(value)),
    scroll_key="controls/scroll",
    [
      @shell.hero(
        if concise {
          "轻触，感受变化"
        } else {
          "增量运行实验室"
        },
        "Controls · Local state · Native identity",
        "lab-intro",
      ),
      @minimoon.div(class="demo-body", [
        if !concise {
          @shell.card("独立页面探针", [
            @minimoon.p("instance: " + instance),
            @minimoon.p("page ticks: " + model.ticks.to_string()),
            @minimoon.p("scroll top: " + model.scroll_top.to_string()),
            action(emit, "lab/back-studio", BackToStudio, "返回首页 / Back"),
            @minimoon.div(class="demo-actions", [
              action(
                emit,
                "controls/jump-dynamic",
                Jump("dynamic-lab"),
                "Dynamic",
              ),
              action(
                emit,
                "controls/jump-components",
                Jump("component-lab"),
                "Components",
              ),
              action(
                emit,
                "controls/jump-controls",
                Jump("control-lab"),
                "Controls",
              ),
              action(
                emit,
                "controls/jump-content-navigation",
                Jump("content-navigation-lab"),
                "Navigation",
              ),
            ]),
          ])
        } else {
          @minimoon.nothing()
        },
        if diagnostics {
          dynamic_section(emit, model)
        } else {
          @minimoon.nothing()
        },
        control_section(emit, model),
        component_section(emit, model, card_nodes),
        content_navigation_section(content_navigation),
        if concise {
          @shell.card("继续探索", [
            @minimoon.button(
              class="demo-note-toggle",
              event_key="interaction/toggle-probes",
              on_tap=toggle_diagnostics(value => !value),
              if diagnostics {
                "收起运行探针 −"
              } else {
                "展开运行探针 +"
              },
            ),
            @minimoon.navigator(
              target=@minimoon.route("pages/lab/lab").with_query([
                @minimoon.query("instance", "interaction"),
              ]),
              class="demo-action",
              "打开独立探针页",
            ),
          ])
        } else {
          @minimoon.nothing()
        },
        notes,
      ]),
    ],
  )
  if model.replace_root {
    @minimoon.fragment([content])
  } else {
    content
  }
}

///|
fn app(
  context : @minimoon.PageContext,
  name : String,
  probe_scheduler : ((Unit) -> Unit, Int) -> Unit,
  concise? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (model, emit) = @minimoon.create_state(
    initial_model(),
    update=(current, message, emit) => {
      match message {
        BackToStudio =>
          @minimoon.with_cmd(
            current,
            @minimoon.navigate_back_or(
              fallback=@minimoon.route("pages/showcase/showcase"),
            ),
          )
        StartDelayProbe =>
          @minimoon.with_cmd(
            update(current, message),
            @minimoon.delay(emit(DelayProbeCompleted), 600),
          )
        StartAsyncProbes =>
          @minimoon.with_cmd(
            update(current, message),
            async_probe_command(emit, probe_scheduler),
          )
        _ => @minimoon.no_cmd(update(current, message))
      }
    },
    subscriptions=(current, emit) => {
      if current.focus_reorder_armed {
        context.every(
          key="lab/focused-keyed-reorder",
          interval_ms=10000,
          command=emit(ReorderItems),
        )
      } else {
        context.every(key="lab/page-tick", interval_ms=2000, command=emit(Tick))
      }
    },
  )
  let cards = model.map(current => @vector.from_array(current.cards))
  let card_nodes = cards.assoc_by(
    (key, card) => @card.card(context, key, card.map(entry => entry.props)),
    by=card => card.id,
  )
  let (reactive_count, increment_reactive_count) = @minimoon.create_pure_state(
    0,
    update=(current, _message : Unit) => current + 1,
  )
  let disclosure = @components.disclosure(
    @components.disclosure_spec(
      id="conformance-disclosure",
      label="Disclosure trigger",
      panel=@minimoon.p("Disclosure panel content"),
    ),
  )
  let accordion = @components.accordion_single(
    id="conformance-accordion",
    label="Single accordion",
    collapsible=false,
    items=[
      @components.accordion_item(
        key="first",
        label="Accordion first",
        panel=@minimoon.p("Accordion first panel"),
      ),
      @components.accordion_item(
        key="second",
        label="Accordion second",
        panel=@minimoon.p("Accordion second panel"),
      ),
    ],
  )
  let accordion_multiple = @components.accordion_multiple(
    id="conformance-accordion-multiple",
    label="Multiple accordion",
    initial_open_keys=["first"],
    items=[
      @components.accordion_item(
        key="first",
        label="Multiple first",
        panel=@minimoon.p("Multiple first panel"),
      ),
      @components.accordion_item(
        key="second",
        label="Multiple second",
        panel=@minimoon.p("Multiple second panel"),
      ),
    ],
  )
  let reactive_accordion = @components.accordion_single_with_input(
    id="conformance-reactive-accordion",
    label="Reactive accordion",
    input=reactive_count,
    items=[
      @components.accordion_item_with_input(
        key="counter",
        label="Reactive counter",
        panel=count => {
          @minimoon.div([
            @minimoon.p("reactive counter:" + count.to_string()),
            @minimoon.button(
              on_tap=increment_reactive_count(()),
              event_key="conformance-reactive-counter/increment",
              "Increment reactive child",
            ),
          ])
        },
      ),
    ],
  )
  let tabs = @components.tabs(
    id="conformance-tabs",
    label="Conformance tab sections",
    items=[
      @components.tab_item(
        key="overview",
        label="Overview tab",
        panel=@minimoon.p("Overview tab panel"),
      ),
      @components.tab_item(
        key="details",
        label="Details tab",
        panel=@minimoon.p("Details tab panel"),
      ),
    ],
  )
  let dialog = @components.dialog(
    @components.dialog_spec(
      id="conformance-dialog",
      title="Conformance dialog",
      description="Modal semantics and overlay dismissal.",
      trigger_label="Open dialog",
      content=close => {
        @minimoon.button(
          on_tap=close,
          event_key="conformance-dialog/content-close",
          "Close from content",
        )
      },
    ),
  )
  let sheet = @components.sheet(
    @components.sheet_spec(
      id="conformance-sheet",
      title="Conformance sheet",
      trigger_label="Open sheet",
      side=@components.Bottom,
      content=_ => @minimoon.p("Sheet panel content"),
    ),
  )
  let dropdown = @components.dropdown(
    @components.dropdown_spec(
      id="conformance-menu",
      trigger_label="Open menu",
      placement=@components.TopStart,
      items=[
        @components.menu_label(key="preferences", label="Preferences"),
        @components.menu_checkbox_item(key="compact", label="Compact mode"),
        @components.menu_radio_item(
          key="theme-light",
          label="Light theme",
          group="theme",
          value="light",
        ),
        @components.menu_radio_item(
          key="theme-dark",
          label="Dark theme",
          group="theme",
          value="dark",
        ),
        @components.menu_separator(key="menu-separator"),
        @components.menu_submenu(key="more", label="More actions", items=[
          @components.menu_item(key="about", label="About Minimoon"),
        ]),
      ],
    ),
  )
  let content_navigation = @minimoon.Val::view8(
    disclosure,
    accordion,
    accordion_multiple,
    reactive_accordion,
    tabs,
    dialog,
    sheet,
    dropdown,
    (
      disclosure,
      accordion,
      accordion_multiple,
      reactive_accordion,
      tabs,
      dialog,
      sheet,
      dropdown,
    ) => {
      @minimoon.div([
        disclosure, accordion, accordion_multiple, reactive_accordion, tabs, dialog,
        sheet, dropdown,
      ])
    },
  )
  let notes = @shell.technical_notes("lab", [
    "The focused reorder moves only C; the same keyed input retains cursor and selection.",
    "Controlled reset uses scalar sets only; native reconciliation updates ranges and selected indexes together.",
    "Run the independent Lab page to verify same-route instances and real unload cancellation.",
  ])
  let (diagnostics, toggle_diagnostics) = @minimoon.create_variable(!concise)
  @minimoon.Val::view6(
    model,
    card_nodes,
    content_navigation,
    context.layout(),
    notes,
    diagnostics,
    (current, nodes, content_navigation, layout, notes, diagnostics) => {
      view(
        current, emit, nodes, name, content_navigation, layout, notes, diagnostics,
        toggle_diagnostics, concise,
      )
    },
  )
}

///|
pub fn scene(
  context : @minimoon.PageContext,
  instance : String,
  concise? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  app(context, instance, resume_probe_after, concise~)
}

///|
fn decode_input(
  fields : Map[String, String],
) -> Result[String, @minimoon.DecodeError] {
  Ok(fields.get("instance").unwrap_or("primary"))
}

///|
pub fn program(_deps : @application.Deps) -> @minimoon.Page {
  program_with_probe_scheduler(resume_probe_after)
}

///|
fn program_with_probe_scheduler(
  probe_scheduler : ((Unit) -> Unit, Int) -> Unit,
) -> @minimoon.Page {
  @minimoon.page_with_input(
    id="lab",
    route=@minimoon.route("pages/lab/lab"),
    title="Runtime Lab",
    preview_input=() => "primary",
    capabilities=[@minimoon.NavigateBack, @minimoon.SwitchTab],
    decode_input~,
    build=(context, input) => app(context, input, probe_scheduler),
  )
}
