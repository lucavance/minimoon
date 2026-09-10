///|
pub struct FetchModel {
  epoch : Int
  label : String
} derive(Eq)

///|
pub(all) enum FetchMsg {
  Load
  Clear
  Finished(Int, Result[@minimoon.RequestResult, @minimoon.HostError])
}

///|
pub(all) struct Draft {
  title : String
  note : String
} derive(Eq, ToJson, @json.FromJson)

///|
pub struct Deps {
  work : @minimoon.Shared[Workbench]
  send : @minimoon.Emit[WorkMsg]
  count : @minimoon.Shared[Int]
  change_count : @minimoon.Emit[Int]
  fetch : @minimoon.Shared[FetchModel]
  send_fetch : @minimoon.Emit[FetchMsg]
}

///|
pub fn program() -> @minimoon.App[Deps] {
  @minimoon.app(
    capabilities=[@minimoon.Request, @minimoon.GetStorage, @minimoon.SetStorage],
    build=context => {
      let (work, send) = context.create_state_with_init(
        init=emit => {
          (
            initial_workbench(),
            @minimoon.get_storage(
              storage_key,
              emit.map(result => Restored(1, result)),
            ),
          )
        },
        update=update_workbench,
      )
      let (count, change_count) = context.create_pure_state(0, update=(
        count,
        delta : Int,
      ) => count + delta)
      let (fetch, send_fetch) = context.create_state(
        initial_fetch(),
        update=update_fetch,
      )
      { work, send, count, change_count, fetch, send_fetch, }
    },
  )
}

///|
/// The same domain update runs under either an App or a page owner.
pub fn initial_fetch() -> FetchModel {
  { epoch: 0, label: "idle", }
}

///|
pub fn update_fetch(
  current : FetchModel,
  message : FetchMsg,
  emit : @minimoon.Emit[FetchMsg],
) -> (FetchModel, @minimoon.Cmd) {
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
    Clear => @minimoon.no_cmd({ epoch: current.epoch + 1, label: "idle", })
    Finished(epoch, result) =>
      if epoch != current.epoch {
        @minimoon.no_cmd(current)
      } else {
        @minimoon.no_cmd({
          ..current,
          label: match result {
            Ok(response) => "loaded HTTP " + response.status_code.to_string()
            Err(error) => "failed: " + error.message
          },
        })
      }
  }
}
