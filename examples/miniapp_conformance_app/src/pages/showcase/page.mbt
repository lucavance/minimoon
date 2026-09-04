///|
pub struct Model {
  updates : Int
  visits : Int
} derive(Eq)

///|
pub enum Msg {
  Increment
  Reset
  PageShown
  OpenConsole
  OpenLab
  OpenDetails
}

///|
fn update(model : Model, message : Msg) -> (Model, @minimoon.Cmd) {
  match message {
    Increment => @minimoon.no_cmd({ ..model, updates: model.updates + 1, })
    Reset => @minimoon.no_cmd({ ..model, updates: 0, })
    PageShown => @minimoon.no_cmd({ ..model, visits: model.visits + 1, })
    OpenConsole =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/home/home").with_query([
            @minimoon.query("name", "Studio"),
          ]),
        ),
      )
    OpenLab =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/lab/lab").with_query([
            @minimoon.query("instance", "showcase"),
          ]),
        ),
      )
    OpenDetails =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/details/details").with_query([
            @minimoon.query("from", "showcase"),
          ]),
        ),
      )
  }
}

///|
fn action(
  emit : @minimoon.Emit[Msg],
  key : String,
  message : Msg,
  label : String,
  tone : String,
) -> @minimoon.Node {
  @minimoon.button(
    on_tap=emit(message),
    event_key=key,
    class="rounded-[10rpx] " +
      tone +
      " px-[20rpx] py-[12rpx] text-[24rpx] font-semibold text-white",
    style="margin: 0; display: flex; align-items: center; justify-content: center; box-sizing: border-box; line-height: 1.2; min-height: 0;",
    label,
  )
}

///|
fn route_card(
  emit : @minimoon.Emit[Msg],
  key : String,
  message : Msg,
  title : String,
  detail : String,
  tone : String,
) -> @minimoon.Node {
  @minimoon.div(
    class="rounded-[16rpx] bg-white px-[24rpx] py-[20rpx]",
    style="width: 100%; box-sizing: border-box; box-shadow: 0 12rpx 32rpx rgba(15, 23, 42, 0.10);",
    [
      @minimoon.h1(class="text-[30rpx] font-semibold text-slate-800", title),
      @minimoon.p(
        class="mt-[8rpx] text-[24rpx] text-slate-600",
        style="line-height: 1.5;",
        detail,
      ),
      @minimoon.div(class="mt-[16rpx]", [
        action(emit, key, message, "进入 / Open", tone),
      ]),
    ],
  )
}

///|
fn view(model : Model, emit : @minimoon.Emit[Msg]) -> @minimoon.Node {
  @minimoon.scroll_view(
    class="box-border h-[100vh] bg-slate-700 px-[24rpx] pb-[40rpx] pt-[72rpx] text-white",
    style="background: linear-gradient(145deg, #020617 0%, #1e1b4b 52%, #0f172a 100%);",
    scroll_y=true,
    data_section="showcase-page",
    [
      @minimoon.div(
        class="rounded-[16rpx] border border-sky-200 px-[24rpx] py-[20rpx]",
        data_section="showcase-hero",
        style="background: rgba(15, 23, 42, 0.82); box-shadow: 0 20rpx 48rpx rgba(2, 6, 23, 0.35);",
        [
          @minimoon.p(
            class="text-[24rpx] font-semibold text-white",
            "MOONBIT × WECHAT SKYLINE",
          ),
          @minimoon.h1(
            class="mt-[12rpx] text-[36rpx] font-semibold text-white",
            style="font-size: 48rpx;",
            "Minimoon Studio",
          ),
          @minimoon.p(
            class="mt-[12rpx] text-[28rpx] text-white",
            style="line-height: 1.5;",
            "用 MoonBit 构建原生 Skyline 小程序",
          ),
          @minimoon.p(
            class="mt-[8rpx] text-[24rpx] text-white",
            style="line-height: 1.5; opacity: 0.78;",
            "Typed state · Transactional Val · Runtime API v" +
            @minimoon.runtime_api_version().to_string(),
          ),
        ],
      ),
      @minimoon.div(
        class="mt-[20rpx] rounded-[16rpx] bg-white px-[24rpx] py-[20rpx] text-slate-800",
        data_section="showcase-transaction",
        style="width: 100%; box-sizing: border-box;",
        [
          @minimoon.p(
            class="text-[24rpx] font-semibold text-sky-700",
            "LIVE STATE / 实时状态",
          ),
          @minimoon.h1(
            class="mt-[8rpx] text-[30rpx] font-semibold text-slate-800",
            "一次事件，一次事务",
          ),
          @minimoon.p(
            class="mt-[8rpx] text-[24rpx] text-slate-500",
            "One event updates state and the host-visible tree.",
          ),
          @minimoon.div(
            class="mt-[16rpx] flex items-center rounded-[12rpx] bg-slate-100 px-[20rpx] py-[16rpx]",
            style="justify-content: space-between;",
            [
              @minimoon.div([
                @minimoon.p(
                  class="text-[24rpx] text-slate-500",
                  "state updates: " + model.updates.to_string(),
                ),
                @minimoon.h1(
                  class="text-[36rpx] font-semibold text-sky-700",
                  model.updates.to_string(),
                ),
              ]),
              @minimoon.div(class="flex gap-[10rpx]", [
                action(
                  emit,
                  "showcase/increment",
                  Increment,
                  "+1",
                  "bg-indigo-600",
                ),
                action(emit, "showcase/reset", Reset, "Reset", "bg-slate-700"),
              ]),
            ],
          ),
          @minimoon.p(
            class="mt-[12rpx] text-[24rpx] text-slate-500",
            "page visits: " + model.visits.to_string(),
          ),
        ],
      ),
      @minimoon.div(
        class="mt-[20rpx] flex flex-col gap-[12rpx]",
        data_section="showcase-routes",
        [
          route_card(
            emit,
            "showcase/open-console",
            OpenConsole,
            "01 能力控制台 / Capability Console",
            "状态、查询输入、wx.* 能力与命令式导航。",
            "bg-sky-600",
          ),
          route_card(
            emit,
            "showcase/open-lab",
            OpenLab,
            "02 增量运行实验室 / Runtime Lab",
            "结构 diff、局部组件、原生控件与实例隔离。",
            "bg-violet-600",
          ),
          route_card(
            emit,
            "showcase/open-details",
            OpenDetails,
            "03 页面生命周期 / Lifecycle Details",
            "独立页面状态、查询参数与栈感知返回。",
            "bg-emerald-600",
          ),
        ],
      ),
      @minimoon.div(
        class="mt-[20rpx] rounded-[16rpx] bg-white px-[24rpx] py-[20rpx] text-[24rpx] text-slate-700",
        data_section="showcase-architecture",
        style="line-height: 1.5;",
        "架构路径 / Architecture\nModel → Val → transactional diff → Skyline host",
      ),
    ],
  )
}

///|
pub fn program() -> @minimoon.Page {
  @minimoon.elmish_page(
    id="showcase",
    route=@minimoon.route("pages/showcase/showcase"),
    title="Minimoon Studio",
    model={ updates: 0, visits: 0, },
    update=(current, message, _) => update(current, message),
    view~,
    capabilities=[@minimoon.NavigateTo],
    subscriptions=(context, _, emit) => context.on_show(emit(PageShown)),
  )
}
