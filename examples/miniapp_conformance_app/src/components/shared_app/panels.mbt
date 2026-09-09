///|
pub fn panel(
  context : @minimoon.PageContext,
  deps : @application.Deps,
) -> @minimoon.Val[@minimoon.Node] {
  context
  .bind(deps.count)
  .view3(
    context.select(deps.fetch, model => model.label),
    context.bind(deps.echoed_draft),
    (count, status, draft) => {
      @minimoon.div(class="demo-card", data_section="application-controls", [
        @minimoon.p(class="demo-card-title", "应用共享状态"),
        @minimoon.p("Application shared count: " + count.to_string()),
        @minimoon.p("Application request: " + status),
        @minimoon.p(
          "Application echoed draft: " +
          (match draft {
            None => "none (not persistent)"
            Some(draft) =>
              draft.title + " / " + draft.note + " (not persistent)"
          }),
        ),
        @minimoon.button(
          class="demo-action",
          on_tap=(deps.change_count)(1),
          event_key="shared/inc",
          "共享计数 +1",
        ),
        @minimoon.button(
          class="demo-action",
          on_tap=(deps.send_fetch)(@application.Load),
          event_key="shared/load",
          "启动应用请求",
        ),
        @minimoon.button(
          class="demo-action",
          on_tap=(deps.send_fetch)(@application.Clear),
          event_key="shared/clear",
          "清除并忽略旧响应",
        ),
      ])
    },
  )
}

///|
pub fn observer(
  context : @minimoon.PageContext,
  deps : @application.Deps,
) -> @minimoon.Val[@minimoon.Node] {
  context
  .bind(deps.count)
  .view2(context.select(deps.fetch, model => model.label), (count, status) => {
    @shell.card("跨页结果", section="application-observer", [
      @minimoon.p("Application shared count: " + count.to_string()),
      @minimoon.button(
        class="demo-action",
        event_key="shared/inc",
        on_tap=(deps.change_count)(1),
        "共享计数 +1",
      ),
      @minimoon.p("Application request: " + status),
      @minimoon.p(class="demo-muted", "完整操作见应用 Tab。"),
    ])
  })
}

///|
pub fn request_panel(
  context : @minimoon.PageContext,
  deps : @application.Deps,
) -> @minimoon.Val[@minimoon.Node] {
  context
  .select(deps.fetch, model => model.label)
  .view(status => {
    @shell.card("应用拥有的请求", section="application-request-probe", [
      @minimoon.p("替换页面后，应用请求仍会完成。"),
      @minimoon.div(class="demo-actions", [
        @minimoon.button(
          class="demo-action",
          event_key="shared/load",
          on_tap=(deps.send_fetch)(@application.Load),
          "启动应用请求",
        ),
        @minimoon.button(
          class="demo-action",
          event_key="shared/clear",
          on_tap=(deps.send_fetch)(@application.Clear),
          "清除并忽略旧响应",
        ),
      ]),
      @minimoon.p("Application request: " + status),
    ])
  })
}
