///|
pub fn program(_deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="showcase",
    route=@minimoon.route("pages/showcase/showcase"),
    title="Minimoon Studio",
    capabilities=[@minimoon.SwitchTab],
    build=context => {
      let (count, change_count) = @minimoon.create_variable(0)
      let (visits, _) = @minimoon.create_state(
        0,
        update=(visits, delta : Int, _) => @minimoon.no_cmd(visits + delta),
        subscriptions=(_, emit) => context.on_show(emit(1)),
      )
      let counter = count.view(count => {
        @shell.card("从一次交互开始", section="showcase-transaction", [
          @minimoon.p(
            class="demo-muted",
            "轻触按钮，看状态与界面同步。",
          ),
          @minimoon.h1(class="demo-value", count.to_string()),
          @minimoon.div(class="demo-actions", [
            @minimoon.button(
              class="demo-action",
              event_key="showcase/increment",
              on_tap=change_count(value => value + 1),
              "+1",
            ),
            @minimoon.button(
              class="demo-action",
              event_key="showcase/reset",
              on_tap=change_count(_ => 0),
              "重置",
            ),
          ]),
          @minimoon.p(class="demo-muted", "state updates: " + count.to_string()),
        ])
      })
      let notes = @shell.technical_notes(
        "showcase",
        [
          "Model → Val → transactional diff → Skyline host", "Tab 切换保留页内状态；深入实验从各栏目进入。",
        ],
        extra=visits.view(visits => {
          @minimoon.p("page visits: " + visits.to_string())
        }),
      )
      counter.view3(context.layout(), notes, (counter, layout, notes) => {
        @shell.frame(layout, "Minimoon", "showcase-page", [
          @shell.hero(
            "Minimoon Studio",
            "用 MoonBit 构建原生 Skyline 小程序",
            "showcase-hero",
            home=true,
          ),
          @minimoon.div(class="demo-body", [
            counter,
            @shell.card("探索原生体验", [
              @minimoon.p(
                class="demo-muted",
                "交互体验控件，平台连接微信，应用展示跨页协作。",
              ),
              @minimoon.div(class="demo-actions", [
                tab("interaction", "交互"),
                tab("platform", "平台"),
                tab("application", "应用"),
              ]),
            ]),
            notes,
          ]),
        ])
      })
    },
  )
}

///|
fn tab(name : String, label : String) -> @minimoon.Node {
  @minimoon.button(
    class="demo-action",
    event_key="showcase/tab-" + name,
    on_tap=@minimoon.switch_tab(@minimoon.route("pages/" + name + "/" + name)),
    label,
  )
}
