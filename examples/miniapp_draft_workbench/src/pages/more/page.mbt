///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="more",
    route=@minimoon.route("pages/more/more"),
    title="更多",
    capabilities=[@minimoon.NavigateTo],
    build=context => {
      context
      .bind(deps.work)
      .view2(context.layout(), (model, layout) => {
        @shell.frame(
          layout,
          "更多",
          "more-page",
          scroll_target=if model.confirm is Some(_) {
            "work-confirmation"
          } else {
            ""
          },
          [
            @shell.hero(
              "简单，也有边界", "Minimoon Draft Workbench", "more-hero",
            ),
            @minimoon.div(class="demo-body", [
              @shell.card("数据管理", section="work-data-management", [
                @minimoon.p(
                  "草稿只保存在当前设备。手动保存，重启恢复；未保存输入仅在本次运行内保留。",
                ),
                @minimoon.p(
                  "不提供账号、云存储或同步。App 请求继续仅指实例仍存活。",
                ),
                @workbench.action(
                  "work/clear",
                  "清空全部本地草稿…",
                  (deps.send)(@application.Choose(@application.ClearAll)),
                  disabled=model.storage != @application.Ready,
                ),
              ]),
              @workbench.status(model, deps.send),
              @workbench.confirmation(model, deps.send),
              @shell.card("三分钟体验", [
                @minimoon.p(
                  "① 新建“周末计划”，填写“去公园走走”，保存后从列表再次编辑。",
                ),
                @minimoon.p(
                  "② 重启确认本地恢复；后台发送，返回联机页看回显。",
                ),
                @minimoon.p(
                  "③ 发送后修改输入，对比本页试发退出后的取消。断网仍可完成第一条路径。",
                ),
              ]),
              @shell.card(
                "能力实验室",
                section="work-laboratory",
                [
                  @minimoon.p(
                    "核心框架 conformance 验收；技术用例不代表额外业务功能。",
                  ),
                  ..[
                    ("interaction", "交互与组件"),
                    ("platform", "平台与 HTTP"),
                    ("request_lifecycle", "请求生命周期"),
                    ("runtime_lab", "状态与渲染"),
                  ].map(entry => {
                    @workbench.action(
                      "more/" + entry.0,
                      entry.1,
                      @minimoon.navigate_to(
                        @minimoon.route("pages/" + entry.0 + "/" + entry.0),
                      ),
                    )
                  }),
                ],
              ),
            ]),
          ],
        )
      })
    },
  )
}
