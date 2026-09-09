///|
pub fn program(deps : @app_state.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="application",
    route=@minimoon.route("pages/application/application"),
    title="应用",
    capabilities=[@minimoon.NavigateTo],
    build=context => {
      let shared = @shared_app.panel(context, deps)
      let notes = @shell.technical_notes("application", [
        "Shared/Emit 属于 App，页面各自持有局部状态。", "页面卸载不取消 App 请求，清除忽略旧回复。",
        "echo 仅在内存中保留。",
      ])
      shared.view3(context.layout(), notes, (shared, layout, notes) => {
        @shell.frame(layout, "应用", "application-page", [
          @shell.hero(
            "一起变化，各自独立", "App-owned state · Page-owned lifetime",
            "application-intro",
          ),
          @minimoon.div(class="demo-body", [
            shared,
            @shell.card("草稿与结果", [
              @minimoon.p(
                class="demo-muted",
                "在独立页面完成校验与 echo，返回后查看共享结果。",
              ),
              @minimoon.button(
                class="demo-action",
                event_key="application/open-editor",
                on_tap=@minimoon.navigate_to(
                  @minimoon.route("pages/draft_editor/draft_editor").with_query([
                      @minimoon.query("from", "application"),
                    ],
                  ),
                ),
                "编辑草稿",
              ),
            ]),
            @shell.card("请求生命周期对照", [
              @minimoon.p(
                class="demo-muted",
                "Tab 切换保留页面；探针页返回和替换会真正卸载。",
              ),
              @minimoon.button(
                class="demo-action",
                event_key="application/open-request-lifecycle",
                on_tap=@minimoon.navigate_to(
                  @minimoon.route("pages/request_lifecycle/request_lifecycle").with_query([
                      @minimoon.query("name", "Application"),
                    ],
                  ),
                ),
                "请求生命周期实验",
              ),
            ]),
            notes,
          ]),
        ])
      })
    },
  )
}
