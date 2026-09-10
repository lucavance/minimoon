///|
priv struct Input {
  source : String
  intent : @application.Intent?
}

///|
priv enum Msg {
  Send(@application.Buffer)
  Finished(Int, Result[@application.DraftEcho, Error])
}

///|
fn decode_input(
  fields : Map[String, String],
) -> Result[Input, @minimoon.DecodeError] {
  guard fields.get("from") is Some(source) && source != "" else {
    return Err(
      @minimoon.decode_error("draft_editor requires a non-empty from parameter"),
    )
  }
  let intent = match fields.get("mode").unwrap_or("resume") {
    "resume" => None
    "new" => Some(@application.New)
    "edit" => {
      let id = @strconv.parse_int(fields.get("id").unwrap_or("")) catch {
        _ =>
          return Err(
            @minimoon.decode_error("draft_editor requires a positive id"),
          )
      }
      if id <= 0 {
        return Err(
          @minimoon.decode_error("draft_editor requires a positive id"),
        )
      }
      Some(@application.Open(id))
    }
    _ => return Err(@minimoon.decode_error("unknown editor mode"))
  }
  Ok({ source, intent, })
}

///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page_with_input(
    id="draft_editor",
    route=@minimoon.route("pages/draft_editor/draft_editor"),
    title="草稿编辑",
    capabilities=[
      @minimoon.NavigateBack,
      @minimoon.SwitchTab,
      @minimoon.Request,
    ],
    preview_input=() => { source: "preview", intent: None, },
    decode_input~,
    build=(context, input) => {
      let (work, _) = @minimoon.create_state_with_init(
        init=_ => {
          (
            (),
            match input.intent {
              Some(intent) => (deps.send)(@application.Choose(intent))
              None => @minimoon.none
            },
          )
        },
        update=(_, _ : Unit, _) => @minimoon.no_cmd(()),
      )
      let model = context.bind(deps.work)
      let (page_echo, send) = @minimoon.create_state(
        @application.initial_echo(),
        update=(current, message : Msg, emit) => {
          match message {
            Send(buffer) => {
              if current.status == @application.EchoLoading {
                return @minimoon.no_cmd(current)
              }
              match @application.validate(buffer.draft) {
                Err(message) =>
                  @minimoon.no_cmd({
                    ..current,
                    revision: buffer.revision,
                    status: @application.EchoFailed(message),
                  })
                Ok(draft) => {
                  let token = current.token + 1
                  @minimoon.with_cmd(
                    {
                      token,
                      revision: buffer.revision,
                      submitted: draft,
                      status: @application.EchoLoading,
                    },
                    @application.echo_request(
                      draft,
                      emit.map(result => Finished(token, result)),
                    ),
                  )
                }
              }
            }
            Finished(token, result) =>
              @minimoon.no_cmd(
                @application.finish_echo(
                  current,
                  token,
                  current.revision,
                  result,
                ),
              )
          }
        },
      )
      let notes = @shell.technical_notes(
        "draft_editor",
        [
          "来源：" + input.source,
          "隐藏保留页面请求，卸载取消；后台发送由 App 持有。",
        ],
        extra=page_echo.view2(model, (echo, model) => {
          @minimoon.div(class="demo-stack", [
            @workbench.action(
              "draft_editor/page-send",
              "本页试发",
              send(Send(model.buffer)),
              disabled=echo.status == @application.EchoLoading,
            ),
            @workbench.echo_panel(echo, model.buffer.revision),
          ])
        }),
      )
      model.view4(context.layout(), notes, work, (model, layout, notes, _) => {
        @shell.frame(
          layout,
          "草稿编辑",
          "draft-editor-page",
          scroll_target=if model.confirm is Some(_) {
            "work-confirmation"
          } else {
            ""
          },
          [
            @shell.hero(
              "把想法写下来", "手动保存到本地，联机仅作回显",
              "draft-editor-intro",
            ),
            @minimoon.div(class="demo-body", [
              @workbench.confirmation(model, deps.send),
              @shell.card("草稿编辑", section="draft-editor", [
                @minimoon.input(
                  value=model.buffer.draft.title,
                  maxlength=-1,
                  on_input=deps.send.map(value => @application.Title(value)),
                  event_key="draft_editor/draft-title",
                  placeholder="标题（必填，最多 80 字）",
                  class="demo-input",
                ),
                @minimoon.textarea(
                  value=model.buffer.draft.note,
                  on_input=deps.send.map(value => @application.Note(value)),
                  input_key="draft_editor/draft-note",
                  maxlength=-1,
                  placeholder="正文（最多 2000 字）",
                  class="demo-input",
                  style="height:240rpx;width:100%;",
                ),
                @workbench.action(
                  "draft_editor/save-draft",
                  "保存到本地",
                  (deps.send)(@application.Save),
                  disabled=model.storage != @application.Ready ||
                    model.confirm is Some(_),
                ),
              ]),
              @workbench.status(model, deps.send),
              @shell.card("联机回显", [
                @minimoon.p(
                  "发送至公开 httpbingo.org，请勿输入隐私或敏感信息。回显不等于云端保存。",
                ),
                @workbench.action(
                  "work/send",
                  "后台发送",
                  (deps.send)(@application.Send),
                  disabled=model.echo.status == @application.EchoLoading,
                ),
                @minimoon.p(
                  @application.echo_label(model.echo, model.buffer.revision),
                ),
                @workbench.action(
                  "draft_editor/online",
                  "查看联机结果",
                  @minimoon.switch_tab(@minimoon.route("pages/online/online")),
                ),
              ]),
              @workbench.action(
                "Back",
                "返回",
                @minimoon.navigate_back_or(
                  fallback=@minimoon.route("pages/workbench/workbench"),
                ),
              ),
              notes,
            ]),
          ],
        )
      })
    },
  )
}
