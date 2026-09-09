///|
pub struct Model {
  visits : Int
  draft : @application.Draft
  epoch : Int
  save_status : String
  validation : String
} derive(Eq)

///|
struct DraftEcho {
  json : @application.Draft
} derive(@json.FromJson)

///|
pub enum Msg {
  PageShown
  Back
  DraftTitle(String)
  DraftNote(String)
  SaveDraft
  DraftSaved(Int, Result[DraftEcho, Error])
}

///|
fn save_error(error : Error) -> String {
  match error {
    @http.BadStatus(response) =>
      "Public API returned HTTP " + response.status_code.to_string()
    @http.RequestError(_) => "Public API request failed; retry when available."
    _ => "Public API response did not match the draft schema."
  }
}

///|
fn update(
  current : Model,
  message : Msg,
  emit : @minimoon.Emit[Msg],
  deps : @application.Deps,
) -> (Model, @minimoon.Cmd) {
  match message {
    PageShown => @minimoon.no_cmd({ ..current, visits: current.visits + 1, })
    Back =>
      @minimoon.with_cmd(
        current,
        @minimoon.navigate_back_or(
          fallback=@minimoon.route("pages/showcase/showcase"),
        ),
      )
    DraftTitle(title) =>
      @minimoon.no_cmd({
        ..current,
        draft: { ..current.draft, title, },
        epoch: current.epoch + 1,
        save_status: "editing",
        validation: "",
      })
    DraftNote(note) =>
      @minimoon.no_cmd({
        ..current,
        draft: { ..current.draft, note, },
        epoch: current.epoch + 1,
        save_status: "editing",
        validation: "",
      })
    SaveDraft => {
      let epoch = current.epoch + 1
      let title = current.draft.title.trim().to_owned()
      if title == "" {
        return @minimoon.no_cmd({
          ..current,
          epoch,
          save_status: "invalid",
          validation: "Title is required.",
        })
      }
      let draft : @application.Draft = { ..current.draft, title, }
      @minimoon.with_cmd(
        { ..current, draft, epoch, save_status: "saving", validation: "", },
        @http.post("https://httpbingo.org/post", timeout_ms=10000)
        .with_json(draft)
        .expect_json(emit.map(result => DraftSaved(epoch, result))),
      )
    }
    DraftSaved(epoch, result) => {
      if epoch != current.epoch {
        return @minimoon.no_cmd(current)
      }
      match result {
        Ok(echo) if echo.json == current.draft =>
          @minimoon.with_cmd(
            {
              ..current,
              save_status: "echoed (not persistent)",
              validation: "",
            },
            (deps.save_echo)(echo.json),
          )
        Ok(_) =>
          @minimoon.no_cmd({
            ..current,
            save_status: "failed",
            validation: "Echo did not match the submitted draft.",
          })
        Err(error) =>
          @minimoon.no_cmd({
            ..current,
            save_status: "failed",
            validation: save_error(error),
          })
      }
    }
  }
}

///|
fn draft_panel(current : Model, emit : @minimoon.Emit[Msg]) -> @minimoon.Node {
  @minimoon.div(data_section="draft-form", class="demo-stack", [
    @minimoon.p("公开 API 仅回显提交内容，不会持久保存。"),
    @minimoon.input(
      value=current.draft.title,
      on_input=emit.map(value => DraftTitle(value)),
      event_key="draft_editor/draft-title",
      placeholder="草稿标题（必填）",
      class="demo-input",
    ),
    @minimoon.input(
      value=current.draft.note,
      on_input=emit.map(value => DraftNote(value)),
      event_key="draft_editor/draft-note",
      placeholder="补充说明",
      class="demo-input",
    ),
    @minimoon.button(
      on_tap=emit(SaveDraft),
      event_key="draft_editor/save-draft",
      class="demo-action",
      "发送草稿并查看回显",
    ),
    @minimoon.p("Draft save: " + current.save_status),
    @minimoon.p(current.validation),
  ])
}

///|
fn app(
  context : @minimoon.PageContext,
  source : String,
  deps : @application.Deps,
) -> @minimoon.Val[@minimoon.Node] {
  let (model, emit) = @minimoon.create_state(
    {
      visits: 0,
      draft: { title: "", note: "", },
      epoch: 0,
      save_status: "idle",
      validation: "",
    },
    update=(current, message, emit) => update(current, message, emit, deps),
    subscriptions=(_, emit) => context.on_show(emit(PageShown)),
  )
  let notes = @shell.technical_notes(
    "draft_editor",
    [
      "来源：" + source + "；from 参数在页面创建前校验。",
      "编辑或卸载拒绝旧回复，仅成功回显进入 App。",
      "返回保留上一页，直接进入则回首页。",
    ],
    extra=model.view(model => @minimoon.p("visits: " + model.visits.to_string())),
  )
  let editor = model.view(current => {
    @shell.card("草稿编辑", section="draft-editor", [
      @minimoon.p(
        class="demo-muted",
        "输入标题与说明，提交成功后回到应用查看共享结果。",
      ),
      draft_panel(current, emit),
      @minimoon.button(
        class="demo-action",
        on_tap=emit(Back),
        event_key="Back",
        "返回",
      ),
    ])
  })
  editor.view4(@shared_app.observer(context, deps), context.layout(), notes, (
    editor,
    shared_panel,
    layout,
    notes,
  ) => {
    @shell.frame(layout, "草稿编辑", "draft-editor-page", [
      @shell.hero(
        "编辑一份草稿", "校验、发送，再返回应用查看结果", "draft-editor-intro",
      ),
      @minimoon.div(class="demo-body", [editor, shared_panel, notes]),
    ])
  })
}

///|
fn decode_input(
  fields : Map[String, String],
) -> Result[String, @minimoon.DecodeError] {
  match fields.get("from") {
    Some(source) if source != "" => Ok(source)
    _ =>
      Err(
        @minimoon.decode_error(
          "draft_editor requires a non-empty from parameter",
        ),
      )
  }
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
    preview_input=() => "preview",
    decode_input~,
    build=(context, input) => app(context, input, deps),
  )
}
