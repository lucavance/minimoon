///|
fn request_id(commands : String) -> String raise {
  guard @json.parse(commands) is Array(commands) else { fail("commands") }
  for command in commands {
    if command is Object(fields) &&
      fields.get("capability") == Some(Json::string("wx.request")) &&
      fields.get("request_id") is Some(String(id)) {
      return id
    }
  }
  fail("missing request")
}

///|
fn response(items : Array[String]) -> String {
  Json::object({ "statusCode": Json(200), "data": Json(items) }).stringify()
}

///|
fn http_page(
  latest : Ref[@query.QueryState[String, String]?],
) -> @minimoon.Page {
  @minimoon.page(
    id="query_http",
    route=@minimoon.route("pages/query/http"),
    title="HTTP query",
    capabilities=[@minimoon.Request],
    build=_ => {
      let (state, emit) = @query.create_infinite_query("first", (
        query,
        _cursor : Int32?,
        done,
      ) => {
        @http.get("https://example.test", query=[@minimoon.query("q", query)]).expect_json(
          done.map((result : Result[Array[String], Error]) => {
            result.map(items => { items, next_cursor: None, })
          }),
        )
      })
      state.view(current => {
        latest.val = Some(current)
        @minimoon.div([
          @minimoon.button(
            event_key="search",
            on_tap=emit(@query.SetQuery("second")),
            "Search",
          ),
          @minimoon.button(
            event_key="refresh",
            on_tap=emit(@query.Refresh),
            "Refresh",
          ),
          @minimoon.button(
            event_key="retry",
            on_tap=emit(@query.Retry),
            "Retry",
          ),
          @minimoon.text(current.items.to_array().join(",")),
        ])
      })
    },
  )
}

///|
test "HTTP query waits for mount, retains typed errors and cancels on page disposal" {
  let latest = Ref(None)
  let page = http_page(latest)
  ignore(page.initial_tree())
  assert_true(latest.val.unwrap().phase is @query.Loading)
  let runtime = page.create_runtime().unwrap()
  assert_true(!runtime.lifecycle("onLoad", "{}").contains("wx.request"))
  let first = request_id(runtime.mount())
  let second = request_id(runtime.dispatch("search", "{}"))
  assert_eq(runtime.resolve_effect(first, "success", response(["stale"])), "[]")
  ignore(
    runtime.resolve_effect(
      second, "success", "{\"statusCode\":503,\"data\":\"unavailable\"}",
    ),
  )
  assert_true(
    latest.val.unwrap().error
    is Some(@http.HttpError::BadStatus({ status_code: 503, .. })),
  )
  let retry = request_id(runtime.dispatch("retry", "{}"))
  ignore(runtime.resolve_effect(retry, "success", response(["current"])))
  assert_eq(latest.val.unwrap().items.to_array(), ["current"])
  let refresh = request_id(runtime.dispatch("refresh", "{}"))
  assert_true(runtime.dispose().contains("CancelEffect"))
  assert_eq(
    runtime.resolve_effect(refresh, "success", response(["late"])),
    "[]",
  )
  assert_eq(latest.val.unwrap().items.to_array(), ["current"])
}

///|
test "rejected dynamic query does not dispatch its initial HTTP command" {
  let page = @minimoon.page(
    id="query_rollback",
    route=@minimoon.route("pages/query/rollback"),
    title="Rollback",
    capabilities=[@minimoon.Request],
    build=_ => {
      let (visible, set) = @minimoon.create_variable(false)
      let query = visible.switch_by(
        (show, _) => {
          if !show {
            return @minimoon.Val::constant(@minimoon.text("hidden"))
          }
          let (state, _) = @query.create_infinite_query("", (
            _,
            _cursor : Int32?,
            done,
          ) => {
            @http.get("https://example.test").expect_json(
              done.map((result : Result[Array[String], Error]) => {
                result.map(items => { items, next_cursor: None, })
              }),
            )
          })
          state.view(_ => @minimoon.text("candidate"))
        },
        by=show => show.to_string(),
      )
      visible.view2(query, (show, child) => {
        let children = [
          @minimoon.button(event_key="show", on_tap=set(_ => true), "show"),
          child,
        ]
        if show {
          children.push(
            @minimoon.button(
              event_key="show",
              on_tap=@minimoon.none,
              "duplicate",
            ),
          )
        }
        @minimoon.div(children)
      })
    },
  )
  let runtime = page.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  let rejected = runtime.dispatch("show", "{}")
  assert_true(rejected.contains("invalid_view"))
  assert_true(!rejected.contains("wx.request"))
  assert_true(runtime.snapshot().contains("hidden"))
  ignore(runtime.dispose())
}
