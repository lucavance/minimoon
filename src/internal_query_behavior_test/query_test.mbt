///|
priv suberror Failure {
  Failure(Int32)
}

///|
priv struct Harness {
  runtime : @testing.TestRuntime
  requests : Array[
    (
      String,
      Int32?,
      @minimoon.Emit[Result[@query.QueryPage[String, Int32], Error]],
    ),
  ]
  state : Ref[@query.QueryState[String, String]?]
  action : Ref[@minimoon.Emit[@query.QueryAction[String]]?]
  command : Ref[@minimoon.Cmd]
}

///|
fn harness(reject~ : String = "!reject") -> Harness raise {
  let requests = []
  let state = Ref(None)
  let action = Ref(None)
  let command = Ref(@minimoon.none)
  let page = @minimoon.page(
    id="query_test",
    route=@minimoon.route("pages/query/test"),
    title="Query",
    build=_ => {
      let (visible, toggle) = @minimoon.create_variable(true)
      let child = visible.switch_by(
        (show, _) => {
          if !show {
            return @minimoon.Val::constant(@minimoon.text("Closed"))
          }
          let (value, emit) = @query.create_infinite_query("a", (
            query,
            cursor,
            done,
          ) => {
            requests.push((query, cursor, done))
            @minimoon.none
          })
          action.val = Some(emit)
          value.view(current => {
            state.val = Some(current)
            let children = [@minimoon.text(current.items.to_array().join(","))]
            if current.query == reject || current.items.contains(reject) {
              children.push(
                @minimoon.button(
                  on_tap=@minimoon.none,
                  event_key="duplicate",
                  "one",
                ),
              )
              children.push(
                @minimoon.button(
                  on_tap=@minimoon.none,
                  event_key="duplicate",
                  "two",
                ),
              )
            }
            @minimoon.div(id="result", children)
          })
        },
        by=show => show.to_string(),
      )
      child.view(child => {
        @minimoon.div([
          @minimoon.input(id="deliver", value="", on_input=_ => command.val),
          @minimoon.button(id="toggle", on_tap=toggle(show => !show), "Toggle"),
          child,
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  { runtime, requests, state, action, command, }
}

///|
fn Harness::run(self : Harness, command : @minimoon.Cmd) -> String {
  self.command.val = command
  self.runtime.input(@testing.by_id("deliver"), "")
}

///|
fn Harness::send(self : Harness, action : @query.QueryAction[String]) -> String {
  self.run(self.action.val.unwrap()(action))
}

///|
fn Harness::complete(
  self : Harness,
  index : Int32,
  items : Array[String],
  cursor : Int32?,
) -> String {
  self.run((self.requests[index].2)(Ok({ items, next_cursor: cursor, })))
}

///|
fn Harness::fail_request(self : Harness, index : Int32, code : Int32) -> String {
  self.run((self.requests[index].2)(Err(Failure(code))))
}

///|
fn Harness::current(self : Harness) -> @query.QueryState[String, String] {
  self.state.val.unwrap()
}

///|
test "initial load, page order, immutable snapshots and terminal cursor" {
  let h = harness()
  assert_eq(h.requests.length(), 1)
  assert_true(h.requests[0].1 is None)
  assert_true(h.current().phase is @query.Loading)
  assert_true(!h.current().has_loaded)
  ignore(h.send(@query.Refresh))
  ignore(h.send(@query.LoadMore))
  ignore(h.send(@query.Retry))
  ignore(h.send(@query.SetQuery("a")))
  assert_eq(h.requests.length(), 1)
  let supplied = ["a", "b"]
  let completion = (h.requests[0].2)(
    Ok({ items: supplied, next_cursor: Some(7), }),
  )
  supplied.clear()
  ignore(h.run(completion))
  let first = h.current()
  assert_eq(first.items.to_array(), ["a", "b"])
  assert_true(first.has_loaded && first.has_more && first.can_load_more)
  ignore(h.send(@query.LoadMore))
  ignore(h.send(@query.LoadMore))
  assert_eq(h.requests.length(), 2)
  assert_true(h.requests[1].1 is Some(7))
  assert_true(h.current().phase is @query.LoadingMore)
  ignore(h.complete(1, ["b", "c"], None))
  assert_eq(h.current().items.to_array(), ["a", "b", "b", "c"])
  assert_eq(first.items.to_array(), ["a", "b"])
  assert_true(!h.current().has_more && !h.current().can_load_more)
  ignore(h.send(@query.LoadMore))
  assert_eq(h.requests.length(), 2)
  ignore(h.runtime.dispose())
}

///|
test "query replacement rejects old and duplicate completions including failures" {
  let h = harness()
  ignore(h.send(@query.SetQuery("b")))
  assert_eq(h.requests[1].0, "b")
  assert_true(h.current().items.is_empty() && !h.current().has_loaded)
  ignore(h.complete(0, ["stale"], Some(1)))
  assert_true(h.current().phase is @query.Loading)
  ignore(h.complete(1, ["current"], None))
  let current = h.current()
  assert_eq(h.complete(1, ["duplicate"], None), "[]")
  assert_eq(h.fail_request(0, 1), "[]")
  assert_eq(h.fail_request(1, 2), "[]")
  assert_true(h.current() == current)
  ignore(h.send(@query.SetQuery("b")))
  assert_eq(h.requests.length(), 2)
  ignore(h.send(@query.SetQuery("c")))
  assert_true(h.current().items.is_empty())
  ignore(h.complete(2, [], None))
  assert_true(h.current().has_loaded && !h.current().has_more)
  ignore(h.runtime.dispose())
}

///|
test "refresh supersedes pagination, retains rows, blocks append after failure and resets cursor" {
  let h = harness()
  ignore(h.complete(0, ["old"], Some(1)))
  ignore(h.send(@query.LoadMore))
  ignore(h.send(@query.Refresh))
  ignore(h.send(@query.Refresh))
  assert_eq(h.requests.length(), 3)
  assert_true(h.requests[2].1 is None)
  assert_true(h.current().phase is @query.Refreshing)
  assert_eq(h.current().items.to_array(), ["old"])
  ignore(h.complete(1, ["old page"], Some(2)))
  ignore(h.fail_request(2, 503))
  assert_eq(h.current().items.to_array(), ["old"])
  assert_true(h.current().error is Some(Failure(503)))
  assert_true(h.current().has_more && !h.current().can_load_more)
  ignore(h.send(@query.LoadMore))
  assert_eq(h.requests.length(), 3)
  ignore(h.send(@query.Retry))
  assert_true(h.requests[3].1 is None)
  assert_true(h.current().error is None)
  ignore(h.complete(3, ["new"], Some(9)))
  assert_eq(h.current().items.to_array(), ["new"])
  ignore(h.send(@query.LoadMore))
  assert_true(h.requests[4].1 is Some(9))
  ignore(h.fail_request(4, 504))
  assert_true(h.current().can_load_more)
  ignore(h.send(@query.Retry))
  assert_true(h.requests[5].1 is Some(9))
  ignore(h.complete(5, [], Some(10)))
  assert_true(h.current().has_more)
  ignore(h.send(@query.LoadMore))
  assert_true(h.requests[6].1 is Some(10))
  ignore(h.complete(6, [], None))
  ignore(h.send(@query.Refresh))
  ignore(h.complete(7, [], None))
  assert_true(h.current().has_loaded && h.current().items.is_empty())
  ignore(h.runtime.dispose())
}

///|
test "initial errors preserve their type and retries render new errors" {
  let h = harness()
  ignore(h.fail_request(0, 401))
  let first = h.current()
  assert_true(!first.has_loaded && first.error is Some(Failure(401)))
  ignore(h.send(@query.Retry))
  ignore(h.send(@query.Retry))
  assert_eq(h.requests.length(), 2)
  assert_true(h.current().phase is @query.Loading)
  ignore(h.fail_request(1, 403))
  assert_true(h.current().error is Some(Failure(403)))
  assert_true(first != h.current())
  ignore(h.send(@query.Refresh))
  ignore(h.complete(2, ["ok"], None))
  assert_true(h.current().error is None)
  ignore(h.send(@query.Retry))
  assert_eq(h.requests.length(), 3)
  ignore(h.runtime.dispose())
}

///|
test "rollback does not consume completion or change the current query" {
  let h = harness()
  assert_true(h.complete(0, ["!reject"], None).contains("invalid_view"))
  ignore(h.complete(0, ["accepted"], Some(1)))
  assert_eq(h.current().items.to_array(), ["accepted"])
  assert_true(h.send(@query.SetQuery("!reject")).contains("invalid_view"))
  ignore(h.send(@query.LoadMore))
  assert_eq(h.requests.last().unwrap().0, "a")
  assert_true(h.requests.last().unwrap().1 is Some(1))
  ignore(h.complete(h.requests.length() - 1, ["next"], None))
  assert_eq(h.current().items.to_array(), ["accepted", "next"])
  ignore(h.runtime.dispose())
}

///|
test "removed component rejects old commands and completion after recreation" {
  let h = harness()
  let old_action = h.action.val.unwrap()
  ignore(h.runtime.tap(@testing.by_id("toggle")))
  assert_eq(h.complete(0, ["disposed"], None), "[]")
  assert_eq(h.run(old_action(@query.Refresh)), "[]")
  ignore(h.runtime.tap(@testing.by_id("toggle")))
  assert_eq(h.requests.length(), 2)
  assert_eq(h.complete(0, ["stale"], None), "[]")
  ignore(h.complete(1, ["new scope"], None))
  assert_eq(h.current().items.to_array(), ["new scope"])
  ignore(h.runtime.dispose())
}

///|
test "many pages preserve all rows and earlier snapshots across refresh failures" {
  let h = harness()
  ignore(h.complete(0, Array::makei(17, i => i.to_string()), Some(17)))
  let first = h.current()
  for page in 1..<9 {
    ignore(h.send(@query.LoadMore))
    assert_true(h.requests[page].1 == Some(page * 17))
    ignore(
      h.complete(
        page,
        Array::makei(17, i => (page * 17 + i).to_string()),
        if page == 8 {
          None
        } else {
          Some((page + 1) * 17)
        },
      ),
    )
  }
  let ready = h.current()
  assert_eq(ready.items.to_array(), Array::makei(153, i => i.to_string()))
  assert_eq(first.items.to_array(), Array::makei(17, i => i.to_string()))
  ignore(h.send(@query.Refresh))
  ignore(h.fail_request(9, 503))
  let failed = h.current()
  assert_eq(failed.items.to_array(), ready.items.to_array())
  assert_true(failed != ready)
  assert_true(failed == failed)
  ignore(h.runtime.dispose())
}
