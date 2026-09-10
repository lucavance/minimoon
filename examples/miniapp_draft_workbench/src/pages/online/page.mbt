///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="online",
    route=@minimoon.route("pages/online/online"),
    title="联机",
    capabilities=[@minimoon.NavigateTo],
    build=context => {
      context
      .bind(deps.work)
      .view2(context.layout(), (model, layout) => {
        @shell.frame(layout, "联机", "online-page", [
          @shell.hero(
            "发送，再看见回应", "App 持有请求 · 离开编辑页后仍可完成",
            "online-hero",
          ),
          @minimoon.div(class="demo-body", [
            @shell.card("发送当前草稿", [
              @minimoon.p(
                class="demo-output",
                model.buffer.draft.title + " / " + model.buffer.draft.note,
              ),
              @minimoon.p(
                "将发送至公开 " +
                @application.echo_base_url() +
                "；请勿输入隐私或敏感信息。",
              ),
              @minimoon.div(class="demo-actions", [
                @workbench.action(
                  "work/send",
                  if model.echo.status is @application.EchoFailed(_) &&
                    model.echo.revision == model.buffer.revision {
                    "重试"
                  } else {
                    "发送当前内容"
                  },
                  (deps.send)(@application.Send),
                  disabled=model.echo.status == @application.EchoLoading,
                ),
                @workbench.action(
                  "online/edit",
                  "继续编辑",
                  @workbench.editor("online"),
                ),
              ]),
              @minimoon.p(model.notice),
            ]),
            @workbench.echo_panel(model.echo, model.buffer.revision),
          ]),
        ])
      })
    },
  )
}
