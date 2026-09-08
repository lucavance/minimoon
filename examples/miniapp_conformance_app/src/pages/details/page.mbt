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
  @minimoon.div(data_section="draft-editor", [
    @minimoon.p("Public API echo demo — not persistent storage"),
    @minimoon.input(
      value=current.draft.title,
      on_input=emit.map(value => DraftTitle(value)),
      event_key="details/draft-title",
      placeholder="Draft title (required)",
      class="mt-[8rpx] rounded-[10rpx] bg-slate-100 px-[20rpx] py-[12rpx]",
    ),
    @minimoon.input(
      value=current.draft.note,
      on_input=emit.map(value => DraftNote(value)),
      event_key="details/draft-note",
      placeholder="Draft note",
      class="mt-[8rpx] rounded-[10rpx] bg-slate-100 px-[20rpx] py-[12rpx]",
    ),
    @minimoon.button(
      on_tap=emit(SaveDraft),
      event_key="details/save-draft",
      class="mt-[16rpx] rounded-[10rpx] bg-blue-700 px-[20rpx] py-[12rpx] text-white",
      "Send draft to public echo API",
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
  model.view2(@application.panel(context, deps), (current, shared_panel) => {
    @minimoon.div(
      class="min-h-[100vh] bg-slate-700 px-[32rpx] pt-[96rpx] text-white",
      style="background: linear-gradient(145deg, #020617 0%, #172554 58%, #0f172a 100%);",
      [
        @minimoon.div(
          class="rounded-[16rpx] border border-sky-200 bg-white px-[32rpx] py-[28rpx] text-slate-800",
          data_section="details-card",
          style="width: 100%; max-width: calc(100vw - 64rpx); box-sizing: border-box; box-shadow: 0 24rpx 64rpx rgba(2, 6, 23, 0.28);",
          [
            @minimoon.p(
              class="text-[24rpx] font-semibold text-sky-700",
              "03 · PAGE LIFECYCLE",
            ),
            @minimoon.h1(
              class="mt-[8rpx] text-[36rpx] font-semibold text-sky-700",
              "页面生命周期",
            ),
            @minimoon.p(
              class="mt-[8rpx] block text-[24rpx] font-semibold text-slate-500",
              "Lifecycle Details",
            ),
            @minimoon.p(
              class="mt-[16rpx] block text-[26rpx] text-slate-600",
              "Independent page state generated by Minimoon / 独立页面状态",
            ),
            @minimoon.p(
              class="mt-[8rpx] block text-[24rpx] text-slate-500",
              "from: " + source,
            ),
            @minimoon.p(class="mt-[8rpx] block text-[24rpx] text-slate-500", [
              @minimoon.text("visits: " + current.visits.to_string()),
            ]),
            draft_panel(current, emit),
            @minimoon.button(
              on_tap=emit(Back),
              event_key="Back",
              class="mt-[16rpx] min-w-[280rpx] rounded-[10rpx] bg-blue-700 px-[20rpx] py-[12rpx] text-[24rpx] leading-none text-white",
              style="margin-left: 0; margin-right: 0; display: flex; align-items: center; justify-content: center; box-sizing: border-box; line-height: 1; min-height: 0;",
              "返回 / Back",
            ),
            shared_panel,
          ],
        ),
      ],
    )
  })
}

///|
fn decode_input(
  fields : Map[String, String],
) -> Result[String, @minimoon.DecodeError] {
  match fields.get("from") {
    Some(source) if source != "" => Ok(source)
    _ =>
      Err(@minimoon.decode_error("details requires a non-empty from parameter"))
  }
}

///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page_with_input(
    id="details",
    route=@minimoon.route("pages/details/details"),
    title="Lifecycle Details",
    capabilities=[
      @minimoon.NavigateBack,
      @minimoon.RedirectTo,
      @minimoon.Request,
    ],
    preview_input=() => "preview",
    decode_input~,
    build=(context, input) => app(context, input, deps),
  )
}
