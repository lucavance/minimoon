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
      @minimoon.h1(class="demo-card-title", "状态与结构"),
      @minimoon.p(
        class="demo-muted",
        "计数、分支、重排：分别观察 set、splice、move。",
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
      @minimoon.p("启动后重新聚焦输入，等待 10 秒。"),
      @minimoon.p("重置保留原生输入身份。"),
      @minimoon.div(class="demo-actions", [items]),
      @minimoon.p("hello:" + model.name),
      @minimoon.p("input event:" + model.focus_status),
      notes,
      @minimoon.p("selected:" + model.selected),
    ],
  )
}

///|
fn async_section(emit : @minimoon.Emit[Msg], model : Model) -> @minimoon.Node {
  @minimoon.div(
    id="runtime-async",
    data_section="runtime-async",
    class="demo-card",
    [
      @minimoon.h1(class="demo-card-title", "异步与释放"),
      @minimoon.p(
        "启动后等待自动完成；再次启动并立即返回，卸载后不得更新。",
      ),
      @minimoon.div(class="demo-actions", [
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
      ]),
      @minimoon.p("delay probe:" + model.delay_probe_status),
      @minimoon.p("perform probe:" + model.perform_probe_status),
      @minimoon.p("attempt probe:" + model.attempt_probe_status),
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
      @minimoon.h1(class="demo-card-title", "组件身份与释放"),
      @minimoon.p(
        class="demo-muted",
        "重排保留，移除释放，恢复新建。",
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
      @minimoon.h1(class="demo-card-title", "原生身份与受控值"),
      @minimoon.p(
        class="demo-muted",
        "同步结构前后，原生身份与逻辑选项不变。",
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
        target=@minimoon.route("pages/runtime_lab/runtime_lab").with_query([
          @minimoon.query("instance", "secondary"),
        ]),
        class="demo-action",
        "打开第二个独立实验实例",
      ),
    ],
  )
}

///|
fn view(
  model : Model,
  emit : @minimoon.Emit[Msg],
  nodes : @vector.Vector[@minimoon.Node],
  instance : String,
  layout : @minimoon.PageLayout,
  notes : @minimoon.Node,
) -> @minimoon.Node {
  let content = @shell.frame(
    layout,
    "状态与渲染实验",
    "runtime-lab-page",
    scroll_target=model.scroll_target,
    on_scroll=emit.map(value => Scrolled(value)),
    scroll_key="controls/scroll",
    [
      @shell.hero(
        "观察状态如何保留与销毁", "重排、同步、异步与真实卸载",
        "runtime-lab-intro",
      ),
      @minimoon.div(class="demo-body", [
        @shell.card("独立实验实例", section="runtime-instance", [
          @minimoon.p("instance: " + instance),
          @minimoon.p("page ticks: " + model.ticks.to_string()),
          @minimoon.p("scroll top: " + model.scroll_top.to_string()),
          @minimoon.p("按组操作，返回验证真实卸载。"),
          @minimoon.div(class="demo-actions", [
            action(
              emit,
              "controls/jump-dynamic",
              Jump("dynamic-lab"),
              "状态与结构",
            ),
            action(
              emit,
              "controls/jump-components",
              Jump("component-lab"),
              "组件生命周期",
            ),
            action(
              emit,
              "controls/jump-controls",
              Jump("control-lab"),
              "原生身份",
            ),
            action(
              emit,
              "controls/jump-async",
              Jump("runtime-async"),
              "异步与释放",
            ),
            action(emit, "runtime_lab/back", BackToStudio, "返回"),
          ]),
        ]),
        dynamic_section(emit, model),
        control_section(emit, model),
        component_section(emit, model, nodes),
        async_section(emit, model),
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
  let notes = @shell.technical_notes("runtime_lab", [
    "keyed 重排只移动 C，输入焦点与选区不变。", "重置仅 scalar set；结构同步保留逻辑选项。",
    "观察渲染统计：无重试、超时或调度失败。",
  ])
  model.view4(card_nodes, context.layout(), notes, (model, nodes, layout, notes) => {
    view(model, emit, nodes, name, layout, notes)
  })
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
    id="runtime_lab",
    route=@minimoon.route("pages/runtime_lab/runtime_lab"),
    title="状态与渲染实验",
    preview_input=() => "primary",
    capabilities=[@minimoon.NavigateBack, @minimoon.SwitchTab],
    decode_input~,
    build=(context, input) => app(context, input, probe_scheduler),
  )
}
