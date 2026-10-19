///|
test "packaged query supports construction, observation and pagination" {
  let page = @minimoon.page(
    id="query_consumer",
    route=@minimoon.route("pages/query/index"),
    title="Query",
    build=_ => {
      let (state, emit) = @query.create_infinite_query("a", (
        query,
        cursor : Int32?,
        done,
      ) => {
        done(
          Ok({
            items: [query],
            next_cursor: if cursor is None {
              Some(1)
            } else {
              None
            },
          }),
        )
      })
      state.view(state => {
        @minimoon.div([
          @minimoon.p(state.items.to_array().join(",")),
          @minimoon.button(
            id="more",
            on_tap=emit(@query.LoadMore),
            disabled=!state.can_load_more,
            "More",
          ),
          @minimoon.button(id="refresh", on_tap=emit(@query.Refresh), "Refresh"),
          @minimoon.button(
            id="search",
            on_tap=emit(@query.SetQuery("b")),
            "Search",
          ),
          @minimoon.button(id="retry", on_tap=emit(@query.Retry), "Retry"),
        ])
      })
    },
  )
  let runtime = @testing.mount(page)
  assert_true(runtime.query(@testing.by_text("a")) is Some(_))
  ignore(runtime.tap(@testing.by_id("more")))
  assert_true(runtime.query(@testing.by_text("a,a")) is Some(_))
  ignore(runtime.tap(@testing.by_id("refresh")))
  assert_true(runtime.query(@testing.by_text("a")) is Some(_))
  ignore(runtime.tap(@testing.by_id("search")))
  assert_true(runtime.query(@testing.by_text("b")) is Some(_))
  ignore(runtime.tap(@testing.by_id("retry")))
  ignore(runtime.dispose())
}
