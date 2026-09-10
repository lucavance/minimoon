///|
pub fn action(
  key : String,
  label : String,
  command : @minimoon.Cmd,
  disabled? : Bool = false,
) -> @minimoon.Node {
  @minimoon.button(
    class="demo-action",
    event_key=key,
    on_tap=command,
    disabled~,
    label,
  )
}

///|
pub fn editor(
  from : String,
  mode? : String = "resume",
  id? : Int,
) -> @minimoon.Cmd {
  let query = [@minimoon.query("from", from), @minimoon.query("mode", mode)]
  if id is Some(id) {
    query.push(@minimoon.query("id", id.to_string()))
  }
  @minimoon.navigate_to(
    @minimoon.route("pages/draft_editor/draft_editor").with_query(query),
  )
}

///|
pub fn status(
  model : @application.Workbench,
  emit : @minimoon.Emit[@application.WorkMsg],
) -> @minimoon.Node {
  @shell.card("本地状态", section="storage-status", [
    @minimoon.p(
      class="demo-output",
      match model.storage {
        @application.Loading => "正在读取本地草稿…"
        @application.Writing => "正在写入本地…"
        _ => model.notice
      },
    ),
    @minimoon.p(
      if @application.dirty(model.buffer) {
        "有未保存修改 · 本次运行内保留，退出小程序后可能丢失。"
      } else if model.buffer.id is Some(_) {
        "当前内容已保存到本地。"
      } else {
        "手动保存 · 重启仅恢复已保存草稿。"
      },
    ),
    if model.storage == @application.ReadFailed {
      @minimoon.div(class="demo-actions", [
        action("work/reload", "重试读取", emit(@application.Reload)),
        action(
          "work/initialize",
          "初始化本地数据…",
          emit(@application.Choose(@application.Initialize)),
        ),
      ])
    } else {
      @minimoon.nothing()
    },
  ])
}

///|
pub fn confirmation(
  model : @application.Workbench,
  emit : @minimoon.Emit[@application.WorkMsg],
) -> @minimoon.Node {
  match model.confirm {
    None => @minimoon.nothing()
    Some(intent) =>
      @minimoon.div(
        id="work-confirmation",
        @shell.card("请确认", section="work-confirmation", [
          @minimoon.p(
            match intent {
              @application.New | @application.Open(_) =>
                "当前有未保存修改。丢弃这些修改并切换草稿？"
              @application.Delete(_) =>
                "删除这条本地草稿？若正在编辑它，未保存内容也将清除。"
              @application.ClearAll =>
                "清空工作台的全部草稿及当前输入？不会清除其他小程序数据。"
              @application.Initialize =>
                "初始化将覆盖工作台存储键中的原数据，无法撤销。已有草稿请先取消并重试读取。"
            },
          ),
          @minimoon.div(class="demo-actions", [
            action("work/confirm", "确认", emit(@application.Confirm)),
            action("work/cancel", "取消", emit(@application.Cancel)),
          ]),
        ]),
      )
  }
}

///|
pub fn echo_panel(
  echo : @application.EchoModel,
  revision : Int,
) -> @minimoon.Node {
  @shell.card("最近一次联机回显", section="work-echo", [
    @minimoon.p(@application.echo_label(echo, revision)),
    if echo.status != @application.EchoIdle {
      @minimoon.p(
        class="demo-output",
        "发送快照：" + echo.submitted.title + " / " + echo.submitted.note,
      )
    } else {
      @minimoon.nothing()
    },
    match echo.status {
      @application.EchoOk(draft) if echo.revision == revision =>
        @minimoon.div(data_section="typed-echo", [
          @minimoon.p(class="demo-output", "标题：" + draft.title),
          @minimoon.p(class="demo-output", "正文：" + draft.note),
        ])
      _ => @minimoon.nothing()
    },
    @minimoon.p(
      class="demo-muted",
      "公开 API 回显不等于云端保存；不会修改本地草稿。",
    ),
  ])
}
