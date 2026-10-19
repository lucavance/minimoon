///|
test "query panel searches only on confirmation and exposes retry controls" {
  let calls : Array[(String, Int32?)] = []
  let failed = Ref(false)
  let page = @minimoon.page(
    id="query_panel",
    route=@minimoon.route("pages/query/panel"),
    title="Query",
    build=_ => {
      query_panel(
        (query, cursor, done) => {
          calls.push((query, cursor))
          if query == "失败" && !failed.val {
            failed.val = true
            done(Err(QueryDemoError))
          } else {
            done(
              Ok({
                items: if query == "空" {
                  []
                } else {
                  [query + "草稿"]
                },
                next_cursor: if cursor is None {
                  Some(1)
                } else {
                  None
                },
              }),
            )
          }
        },
        @minimoon.none,
      )
    },
  )
  let runtime = @testing.mount(page)
  assert_eq(calls.length(), 1)
  ignore(runtime.input(@testing.by_id("query-search"), "新"))
  assert_eq(calls.length(), 1)
  ignore(runtime.tap(@testing.by_id("query-submit")))
  assert_eq(calls[1].0, "新")
  ignore(runtime.tap(@testing.by_id("query-more")))
  assert_true(calls[2].1 is Some(1))
  assert_eq(
    runtime.get(@testing.by_id("query-more")).prop("disabled"),
    Some(Json::boolean(true)),
  )
  ignore(runtime.confirm(@testing.by_id("query-search"), "失败"))
  assert_true(runtime.query(@testing.by_id("query-retry")) is Some(_))
  ignore(runtime.tap(@testing.by_id("query-retry")))
  assert_true(runtime.query(@testing.by_id("query-retry")) is None)
  ignore(runtime.confirm(@testing.by_id("query-search"), "空"))
  assert_eq(
    runtime.get(@testing.by_id("query-status")).text_content(),
    "没有匹配的草稿",
  )
  ignore(runtime.dispose())
}
