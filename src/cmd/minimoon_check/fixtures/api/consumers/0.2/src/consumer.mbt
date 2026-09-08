///|
using @minimoon {type Node, type Val, type Page}

///|
pub fn counter(label : String) -> Val[Node] {
  let (count, change) = @minimoon.create_variable(0)
  count.view(value => @minimoon.div([
    @minimoon.p(label + ": " + value.to_string()),
    @minimoon.button(on_tap=change(current => current + 1), "Increment"),
  ]))
}

///|
pub fn root_page() -> Page {
  @minimoon.page_with_input(
    id="consumer",
    route=@minimoon.route("pages/consumer/consumer"),
    title="0.2 candidate",
    preview_input=() => "Preview",
    decode_input=fields => match fields.get("label") {
      Some(label) => Ok(label)
      None => Err(@minimoon.decode_error("label is required"))
    },
    build=(_, label) => counter(label),
  )
}

///|
pub fn testing_snapshot() -> String raise {
  let runtime = @testing.mount(root_page(), input={ "label": "Actual" })
  defer ignore(runtime.dispose())
  let _ = runtime.tap(@testing.by_text("Increment"))
  runtime.quiesce()
  runtime.snapshot()
}

///|
pub struct Echo {
  url : String
} derive(@json.FromJson)

///|
pub fn load_json(receive : @minimoon.Emit[Result[Echo, Error]]) -> @minimoon.Cmd {
  @http.get("https://httpbingo.org/get").expect_json(receive)
}

///|
pub fn application_snapshot() -> String raise {
  let app = @testing.launch(@minimoon.app(build=context => {
    context.create_pure_state(0, update=(value, delta : Int) => value + delta)
  }))
  defer app.dispose()
  let page = app.mount(deps => @minimoon.page(
    id="shared-consumer",
    route=@minimoon.route("pages/shared/shared"),
    title="App consumer",
    build=context => context.bind(deps.0).view(count => @minimoon.button(
      on_tap=(deps.1)(1),
      count.to_string(),
    )),
  ))
  let _ = page.tap(@testing.by_text("0"))
  app.quiesce()
  page.snapshot()
}
