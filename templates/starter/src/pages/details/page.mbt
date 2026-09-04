///|
pub struct Model {
  enabled : Bool
  visits : Int
} derive(Eq)

///|
pub enum Msg {
  Toggle
  PageShown
  Back
}

///|
fn view(
  model : Model,
  emit : @minimoon.Emit[Msg],
  source : String,
) -> @minimoon.Node {
  @minimoon.div(
    class="min-h-[100vh] bg-slate-100 px-[40rpx] pt-[120rpx] text-slate-800",
    [
      @minimoon.div(
        class="rounded-[16rpx] bg-white px-[28rpx] py-[24rpx]",
        data_section="starter-details",
        [
          @minimoon.h1(
            class="text-[40rpx] font-semibold text-violet-700",
            "Details",
          ),
          @minimoon.p(class="mt-[12rpx] text-[26rpx]", "from: " + source),
          @minimoon.p(
            class="mt-[12rpx] text-[26rpx]",
            "enabled: " + model.enabled.to_string(),
          ),
          @minimoon.p(
            class="mt-[12rpx] text-[26rpx]",
            "page visits: " + model.visits.to_string(),
          ),
          @minimoon.div(class="mt-[20rpx] flex gap-[12rpx]", [
            @minimoon.button(
              on_tap=emit(Toggle),
              event_key="details/toggle",
              class="rounded-[10rpx] bg-emerald-600 px-[24rpx] py-[14rpx] text-white",
              "Toggle",
            ),
            @minimoon.button(
              on_tap=emit(Back),
              event_key="details/back",
              class="rounded-[10rpx] bg-sky-600 px-[24rpx] py-[14rpx] text-white",
              "Back",
            ),
          ]),
        ],
      ),
    ],
  )
}

///|
fn app(
  context : @minimoon.PageContext,
  source : @minimoon.Val[String],
) -> @minimoon.Val[@minimoon.Node] {
  let (model, emit) = @minimoon.create_state(
    { enabled: false, visits: 0 },
    update=(current, message, _) => {
      match message {
        Toggle => @minimoon.no_cmd({ ..current, enabled: !current.enabled })
        PageShown =>
          @minimoon.no_cmd({ ..current, visits: current.visits + 1 })
        Back =>
          @minimoon.with_cmd(
            current,
            @minimoon.navigate_back_or(
              fallback=@minimoon.route("pages/home/home"),
            ),
          )
      }
    },
    subscriptions=(_, emit) => context.on_show(emit(PageShown)),
  )
  model.view2(source, (current, value) => {
    view(current, emit, value)
  })
}

///|
fn decode_input(
  fields : Map[String, String],
) -> Result[String, @minimoon.DecodeError] {
  Ok(fields.get("from").unwrap_or("Home"))
}

///|
pub fn program() -> @minimoon.Page {
  @minimoon.page_with_input(
    id="details",
    route=@minimoon.route("pages/details/details"),
    title="Details",
    capabilities=[@minimoon.NavigateBack, @minimoon.RedirectTo],
    decode_input~,
    build=app,
  )
}
