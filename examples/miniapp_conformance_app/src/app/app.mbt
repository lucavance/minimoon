///|
pub struct FetchModel {
  epoch : Int
  label : String
} derive(Eq)

///|
pub enum FetchMsg {
  Load
  Clear
  Finished(Int, Result[@minimoon.RequestResult, @minimoon.HostError])
}

///|
pub struct Deps {
  count : @minimoon.Shared[Int]
  change_count : @minimoon.Emit[Int]
  fetch : @minimoon.Shared[FetchModel]
  send_fetch : @minimoon.Emit[FetchMsg]
}

///|
pub fn program() -> @minimoon.App[Deps] {
  @minimoon.app(capabilities=[@minimoon.Request], build=context => {
    let (count, change_count) = context.create_pure_state(0, update=(
      count,
      delta : Int,
    ) => count + delta)
    let (fetch, send_fetch) = context.create_state(
      { epoch: 0, label: "idle", },
      update=(current, message, emit) => {
        match message {
          Load => {
            let epoch = current.epoch + 1
            @minimoon.with_cmd(
              { epoch, label: "loading", },
              @minimoon.request(
                "https://httpbingo.org/delay/2",
                emit.map(result => Finished(epoch, result)),
              ),
            )
          }
          Clear =>
            @minimoon.no_cmd({ epoch: current.epoch + 1, label: "idle", })
          Finished(epoch, result) =>
            if epoch != current.epoch {
              @minimoon.no_cmd(current)
            } else {
              @minimoon.no_cmd({
                ..current,
                label: match result {
                  Ok(response) =>
                    "loaded HTTP " + response.status_code.to_string()
                  Err(error) => "failed: " + error.message
                },
              })
            }
        }
      },
    )
    { count, change_count, fetch, send_fetch, }
  })
}

///|
pub fn panel(
  context : @minimoon.PageContext,
  deps : Deps,
) -> @minimoon.Val[@minimoon.Node] {
  context
  .bind(deps.count)
  .view2(context.select(deps.fetch, model => model.label), (count, status) => {
    @minimoon.div(
      class="mt-[16rpx] rounded-[16rpx] bg-white px-[32rpx] py-[28rpx] text-slate-800",
      data_section="shared-state",
      [
        @minimoon.p("Application shared count: " + count.to_string()),
        @minimoon.p("Application request: " + status),
        @minimoon.button(
          on_tap=(deps.change_count)(1),
          event_key="shared/inc",
          "Shared +1",
        ),
        @minimoon.button(
          on_tap=(deps.send_fetch)(Load),
          event_key="shared/load",
          "Shared public API request",
        ),
        @minimoon.button(
          on_tap=(deps.send_fetch)(Clear),
          event_key="shared/clear",
          "Clear and ignore old response",
        ),
      ],
    )
  })
}
