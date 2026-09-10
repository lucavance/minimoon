///|
test "business buffer and technical counter are independent App domains" {
  let app = program().create_runtime()
  defer ignore(app.dispose())
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let page = app
    .create_page(
      @minimoon.page(
        id="observer",
        route=@minimoon.route("pages/observer/observer"),
        title="observer",
        build=context => {
          context
          .bind(deps.count)
          .view2(context.bind(deps.work), (count, model) => {
            @minimoon.p(count.to_string() + " / " + model.buffer.draft.title)
          })
        },
      ),
    )
    .unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.mount())
  ignore(app.dispatch((deps.send)(Title("Typed draft"))))
  ignore(app.dispatch((deps.change_count)(2)))
  ignore(page.flush())
  assert_true(page.snapshot().contains("2 / Typed draft"))
}
