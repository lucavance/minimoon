///|
pub struct Model {
  updates : Int
  visits : Int
} derive(Eq)

///|
pub enum Msg {
  Increment
  Reset
  PageShown
  OpenConsole
  OpenLab
  OpenDetails
  OpenInteraction
  OpenCapabilities
  OpenApplication
}

///|
fn update(model : Model, message : Msg) -> (Model, @minimoon.Cmd) {
  match message {
    OpenInteraction =>
      @minimoon.with_cmd(
        model,
        @minimoon.switch_tab(@minimoon.route("pages/interaction/interaction")),
      )
    OpenCapabilities =>
      @minimoon.with_cmd(
        model,
        @minimoon.switch_tab(@minimoon.route("pages/capabilities/capabilities")),
      )
    OpenApplication =>
      @minimoon.with_cmd(
        model,
        @minimoon.switch_tab(@minimoon.route("pages/application/application")),
      )
    Increment => @minimoon.no_cmd({ ..model, updates: model.updates + 1, })
    Reset => @minimoon.no_cmd({ ..model, updates: 0, })
    PageShown => @minimoon.no_cmd({ ..model, visits: model.visits + 1, })
    OpenConsole =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/capability_probe/capability_probe").with_query([
              @minimoon.query("name", "Studio"),
            ],
          ),
        ),
      )
    OpenLab =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/lab/lab").with_query([
            @minimoon.query("instance", "showcase"),
          ]),
        ),
      )
    OpenDetails =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/details/details").with_query([
            @minimoon.query("from", "showcase"),
          ]),
        ),
      )
  }
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
fn view(
  model : Model,
  emit : @minimoon.Emit[Msg],
  layout : @minimoon.PageLayout,
  notes : @minimoon.Node,
) -> @minimoon.Node {
  @shell.frame(layout, "Minimoon", "showcase-page", [
    @shell.hero(
      "Minimoon Studio",
      "用 MoonBit 构建原生 Skyline 小程序",
      "showcase-hero",
      home=true,
    ),
    @minimoon.div(class="demo-body", [
      @shell.card("从一次交互开始", section="showcase-transaction", [
        @minimoon.p(
          class="demo-muted",
          "轻触按钮，看状态与界面同步。",
        ),
        @minimoon.h1(class="demo-value", model.updates.to_string()),
        @minimoon.div(class="demo-actions", [
          action(emit, "showcase/increment", Increment, "+1"),
          action(emit, "showcase/reset", Reset, "Reset"),
        ]),
        @minimoon.p(
          class="demo-muted",
          "state updates: " + model.updates.to_string(),
        ),
      ]),
      @shell.card("探索原生体验", [
        @minimoon.p(
          class="demo-muted",
          "交互、平台能力与应用状态，按需展开。",
        ),
        @minimoon.div(class="demo-actions", [
          action(emit, "showcase/tab-interaction", OpenInteraction, "交互"),
          action(emit, "showcase/tab-capabilities", OpenCapabilities, "能力"),
          action(emit, "showcase/tab-application", OpenApplication, "应用"),
        ]),
      ]),
      @shell.card("页面栈体验", section="showcase-routes", [
        @minimoon.p(
          class="demo-muted",
          "独立页面可以带参进入、返回与卸载。",
        ),
        @minimoon.div(class="demo-actions", [
          action(emit, "showcase/open-console", OpenConsole, "能力验证"),
          action(emit, "showcase/open-lab", OpenLab, "交互探针"),
          action(emit, "showcase/open-details", OpenDetails, "编辑详情"),
        ]),
        @minimoon.p(
          class="demo-muted",
          "page visits: " + model.visits.to_string(),
        ),
      ]),
      notes,
    ]),
  ])
}

///|
pub fn program(_deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="showcase",
    route=@minimoon.route("pages/showcase/showcase"),
    title="Minimoon Studio",
    capabilities=[@minimoon.NavigateTo, @minimoon.SwitchTab],
    build=context => {
      let (model, emit) = @minimoon.create_state(
        { updates: 0, visits: 0, },
        update=(current, message, _) => update(current, message),
        subscriptions=(_, emit) => context.on_show(emit(PageShown)),
      )
      let notes = @shell.technical_notes("showcase", [
        "Model → Val → transactional diff → Skyline host", "Rapid taps are lossless; native Tab switches keep page-local state.",
        "The separate stack probes retain real navigation and unload checks.",
      ])
      model.view3(context.layout(), notes, (model, layout, notes) => {
        view(model, emit, layout, notes)
      })
    },
  )
}
