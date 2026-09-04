///|
pub struct Model {
  count : Int
  name : String
  visits : Int
} derive(Eq)

///|
pub enum Msg {
  Increment
  Decrement
  NameInput(String)
  OpenDetails
  PageShown
}

///|
fn update(
  model : Model,
  msg : Msg,
) -> (Model, @minimoon.Cmd) {
  match msg {
    Increment => @minimoon.no_cmd({ ..model, count: model.count + 1 })
    Decrement => @minimoon.no_cmd({ ..model, count: model.count - 1 })
    NameInput(name) => @minimoon.no_cmd({ ..model, name, })
    OpenDetails =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/details/details").with_query([
            @minimoon.query("from", model.name),
          ]),
        ),
      )
    PageShown => @minimoon.no_cmd({ ..model, visits: model.visits + 1 })
  }
}

///|
fn view(model : Model, emit : @minimoon.Emit[Msg]) -> @minimoon.Node {
  @minimoon.div(
    class="min-h-[100vh] bg-slate-100 px-[40rpx] pt-[120rpx] text-slate-800",
    [
      @minimoon.h1(
        class="text-[40rpx] font-semibold text-sky-700",
        "Hello " + model.name,
      ),
      @minimoon.p(
        class="mt-[12rpx] text-[26rpx] text-slate-600",
        "page visits: " + model.visits.to_string(),
      ),
      @minimoon.div(
        class="mt-[20rpx] rounded-[16rpx] bg-white px-[28rpx] py-[24rpx]",
        data_section="starter-home",
        [
          @minimoon.p(
            class="text-[56rpx] font-semibold text-sky-700",
            model.count.to_string(),
          ),
          @minimoon.div(class="mt-[16rpx] flex gap-[12rpx]", [
            @minimoon.button(
              on_tap=emit(Decrement),
              event_key="home/decrement",
              class="rounded-[10rpx] bg-slate-700 px-[24rpx] py-[12rpx] text-white",
              "-1",
            ),
            @minimoon.button(
              on_tap=emit(Increment),
              event_key="home/increment",
              class="rounded-[10rpx] bg-sky-600 px-[24rpx] py-[12rpx] text-white",
              "+1",
            ),
          ]),
          @minimoon.input(
            value=model.name,
            on_input=emit.map(value => NameInput(value)),
            event_key="home/name",
            placeholder="Your name",
            class="mt-[20rpx] rounded-[10rpx] bg-slate-100 px-[20rpx] py-[14rpx]",
          ),
          @minimoon.button(
            on_tap=emit(OpenDetails),
            event_key="home/open-details",
            class="mt-[20rpx] rounded-[10rpx] bg-violet-600 px-[24rpx] py-[14rpx] text-white",
            "Open details",
          ),
        ],
      ),
    ],
  )
}

///|
pub fn program() -> @minimoon.Page {
  @minimoon.elmish_page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    model={ count: 0, name: "Minimoon", visits: 0 },
    update=(current, message, _) => update(current, message),
    view~,
    capabilities=[@minimoon.NavigateTo],
    subscriptions=(context, _, emit) => context.on_show(emit(PageShown)),
  )
}
