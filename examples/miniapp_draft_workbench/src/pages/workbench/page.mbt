///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="workbench",
    route=@minimoon.route("pages/workbench/workbench"),
    title="Minimoon 草稿工作台",
    capabilities=[@minimoon.NavigateTo, @minimoon.SwitchTab],
    build=context => {
      context
      .bind(deps.work)
      .view2(context.layout(), (model, layout) => {
        @shell.frame(
          layout,
          "草稿工作台",
          "workbench-page",
          scroll_target=if model.confirm is Some(_) {
            "work-confirmation"
          } else {
            ""
          },
          [
            @shell.hero(
              "留住一个想法",
              "本地保存 · 联机回显 · 跨页继续",
              "workbench-hero",
              home=true,
            ),
            @minimoon.div(class="demo-body", [
              @shell.card("工作台", section="workbench-overview", [
                @minimoon.h1(
                  class="demo-value",
                  if model.storage
                    is (@application.Loading | @application.ReadFailed) {
                    "—"
                  } else {
                    model.store.records.length().to_string()
                  },
                ),
                @minimoon.p("条已保存草稿"),
                @minimoon.p(
                  class="demo-output",
                  "当前编辑：" +
                  (if model.buffer.draft.title == "" {
                    "未命名草稿"
                  } else {
                    model.buffer.draft.title
                  }),
                ),
                @minimoon.div(class="demo-actions", [
                  @work_ui.action(
                    "workbench/new",
                    "新建草稿",
                    @work_ui.editor("workbench", mode="new"),
                    disabled=model.storage != @application.Ready,
                  ),
                  @work_ui.action(
                    "workbench/resume",
                    "继续编辑",
                    @work_ui.editor("workbench"),
                  ),
                  @work_ui.action(
                    "workbench/drafts",
                    "查看已保存草稿",
                    @minimoon.switch_tab(@minimoon.route("pages/drafts/drafts")),
                  ),
                ]),
              ]),
              @work_ui.status(model, deps.send),
              @work_ui.confirmation(model, deps.send),
            ]),
          ],
        )
      })
    },
  )
}
