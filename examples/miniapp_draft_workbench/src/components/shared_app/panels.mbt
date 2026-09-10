///|
pub fn panel(
  context : @minimoon.PageContext,
  deps : @application.Deps,
) -> @minimoon.Val[@minimoon.Node] {
  context
  .bind(deps.count)
  .view2(context.select(deps.fetch, model => model.label), (count, status) => {
    @minimoon.div(class="demo-card", data_section="application-controls", [
      @minimoon.p(class="demo-card-title", "应用共享状态"),
      @minimoon.p("Application shared count: " + count.to_string()),
      @minimoon.p("Application request: " + status),
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
  })
}
