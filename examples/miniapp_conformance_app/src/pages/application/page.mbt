///|
pub fn program(deps : @app_state.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="application",
    route=@minimoon.route("pages/application/application"),
    title="应用",
    capabilities=[@minimoon.NavigateTo],
    build=context => {
      let shared = @app_state.panel(context, deps)
      let notes = @shell.technical_notes("application", [
        "Shared and Emit belong to this App; each page retains its own local model.",
        "App-owned requests survive page unload; Clear rejects old replies.", "The echo is held in memory only, not persisted to a server or storage.",
      ])
      shared.view3(context.layout(), notes, (shared, layout, notes) => {
        @shell.frame(layout, "应用", "application-page", [
          @shell.hero(
            "一起变化，各自独立", "App-owned state · Page-owned lifetime",
            "application-intro",
          ),
          @minimoon.div(class="demo-body", [
            shared,
            @shell.card("编辑一份草稿", [
              @minimoon.p(
                class="demo-muted",
                "在独立页面完成校验与 echo，返回后查看共享结果。",
              ),
              @minimoon.button(
                class="demo-action",
                event_key="application/open-details",
                on_tap=@minimoon.navigate_to(
                  @minimoon.route("pages/details/details").with_query([
                    @minimoon.query("from", "application"),
                  ]),
                ),
                "打开编辑详情",
              ),
            ]),
            @shell.card("验证页面所有权", [
              @minimoon.p(
                class="demo-muted",
                "Tab 切换保留页面；探针页返回和替换会真正卸载。",
              ),
              @minimoon.button(
                class="demo-action",
                event_key="application/open-capability-probe",
                on_tap=@minimoon.navigate_to(
                  @minimoon.route("pages/capability_probe/capability_probe").with_query([
                      @minimoon.query("name", "Application"),
                    ],
                  ),
                ),
                "打开能力验证",
              ),
            ]),
            notes,
          ]),
        ])
      })
    },
  )
}
