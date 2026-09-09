///|
fn action(
  key : String,
  command : @minimoon.Cmd,
  label : String,
) -> @minimoon.Node {
  @minimoon.button(
    class="demo-action",
    event_key="request_lifecycle/" + key,
    on_tap=command,
    label,
  )
}

///|
fn scene(
  context : @minimoon.PageContext,
  input : String,
  deps : @application.Deps,
) -> @minimoon.Val[@minimoon.Node] {
  let (name, rename) = @minimoon.create_variable(input)
  let (visible, _) = @minimoon.create_state(
    false,
    update=(_, visible : Bool, _) => @minimoon.no_cmd(visible),
    subscriptions=(_, emit) => {
      @minimoon.Sub::batch([
        context.on_show(emit(true)),
        context.on_hide(emit(false)),
      ])
    },
  )
  // Identical domain logic, independent owner: this request belongs to this page.
  let (fetch, send) = @minimoon.create_state(
    @application.initial_fetch(),
    update=@application.update_fetch,
  )
  let marker = name.view(name => {
    @shell.card(
      "给当前页面做个标记",
      section="request-lifecycle-state",
      [
        @minimoon.input(
          class="demo-input",
          value=name,
          placeholder="修改后打开编辑页，再返回",
          event_key="request_lifecycle/name",
          on_input=rename.map(value => _ => value),
        ),
        @minimoon.p("页内标记：" + name),
      ],
    )
  })
  let request = fetch.view(fetch => {
    @shell.card("页面拥有的请求", section="page-request-probe", [
      @minimoon.p(
        "启动约 2 秒的公共请求，再立即打开或替换为编辑页。隐藏保留，卸载取消。",
      ),
      action("request", send(@application.Load), "启动页面请求"),
      @minimoon.p(
        data_section="request-output",
        class="demo-output",
        "request: " +
        (if fetch.label.has_prefix("loaded HTTP ") {
          "loaded · HTTP " + fetch.label["loaded HTTP ".length():].to_owned()
        } else {
          fetch.label
        }),
      ),
    ])
  })
  let navigation = visible.view(visible => {
    @shell.card("对照隐藏与卸载", section="navigation-controls", [
      @minimoon.p(
        "打开保留，替换卸载；编辑页可观察 App 请求。",
      ),
      @minimoon.div(class="demo-actions", [
        action(
          "open-editor",
          @minimoon.navigate_to(
            @minimoon.route("pages/draft_editor/draft_editor").with_query([
              @minimoon.query("from", "request_lifecycle"),
            ]),
          ),
          "打开编辑页（保留本页）",
        ),
        action(
          "replace-editor",
          @minimoon.redirect_to(
            @minimoon.route("pages/draft_editor/draft_editor").with_query([
              @minimoon.query("from", "redirect"),
            ]),
          ),
          "替换为编辑页（卸载本页）",
        ),
        action(
          "back",
          @minimoon.navigate_back_or(
            fallback=@minimoon.route("pages/showcase/showcase"),
          ),
          "返回",
        ),
      ]),
      @minimoon.p(
        data_section="lifecycle-state",
        "visible: " + visible.to_string(),
      ),
    ])
  })
  let shared = @shared_app.request_panel(context, deps)
  let notes = @shell.technical_notes("request_lifecycle", [
    "NavigateTo 隐藏，RedirectTo 卸载并取消页内请求。", "同一请求状态机，由页面或 App 分别创建并持有。",
  ])
  marker.view6(request, navigation, shared, context.layout(), notes, (
    marker,
    request,
    navigation,
    shared,
    layout,
    notes,
  ) => {
    @shell.frame(layout, "请求生命周期", "request-lifecycle-page", [
      @shell.hero(
        "离开页面，请求会怎样？", "隐藏保留 · 卸载取消 · 应用继续",
        "request-lifecycle-intro",
      ),
      @minimoon.div(class="demo-body", [
        marker, request, shared, navigation, notes,
      ]),
    ])
  })
}

///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page_with_input(
    id="request_lifecycle",
    route=@minimoon.route("pages/request_lifecycle/request_lifecycle"),
    title="请求生命周期",
    preview_input=() => "Minimoon",
    decode_input=fields => Ok(fields.get("name").unwrap_or("Minimoon")),
    capabilities=[
      @minimoon.Request,
      @minimoon.NavigateTo,
      @minimoon.RedirectTo,
      @minimoon.NavigateBack,
      @minimoon.SwitchTab,
    ],
    build=(context, input) => scene(context, input, deps),
  )
}
