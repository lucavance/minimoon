///|
pub fn program(_deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="interaction",
    route=@minimoon.route("pages/interaction/interaction"),
    title="交互",
    build=context => {
      let controls = @interaction_scene.scene(context)
      let composition = @composition.scene()
      let notes = @shell.technical_notes("interaction", [
        "Tab 切换保留各自状态。", "核心组件使用 minimal-v2；完整目录见 UI Showcase。",
        "运行实验验证卸载与身份。",
      ])
      controls.view4(composition, context.layout(), notes, (
        controls,
        composition,
        layout,
        notes,
      ) => {
        @shell.frame(layout, "交互", "interaction-page", [
          @shell.hero(
            "轻触，感受变化", "原生控件 · 局部状态 · 组件组合",
            "interaction-intro",
          ),
          @minimoon.div(class="demo-body", [
            controls,
            composition,
            @shell.card(
              "深入状态与渲染",
              section="interaction-runtime-entry",
              [
                @minimoon.p(
                  "观察重排、焦点、异步完成与页面卸载。",
                ),
                @minimoon.navigator(
                  target=@minimoon.route("pages/runtime_lab/runtime_lab").with_query([
                      @minimoon.query("instance", "interaction"),
                    ],
                  ),
                  class="demo-action",
                  "状态与渲染实验",
                ),
              ],
            ),
            notes,
          ]),
        ])
      })
    },
  )
}
