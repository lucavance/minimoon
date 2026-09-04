///|
pub enum FrozenMsg {
  Increment
}

///|
pub fn root_page() -> @minimoon.Page {
  @minimoon.elmish_page(
    id="api-compat-0-1",
    route=@minimoon.route("pages/compat/compat"),
    title="0.1 API compatibility",
    model=0,
    update=(model, message, _) =>
      match message {
        Increment => @minimoon.no_cmd(model + 1)
      },
    view=(model, emit) =>
      @minimoon.div(data_section="api-compat", [
        @minimoon.p(model.to_string()),
        @minimoon.button(
          on_tap=emit(Increment),
          event_key="compat/increment",
          "Increment",
        ),
      ]),
  )
}

///|
pub fn headless_tabs() -> @minimoon.Val[@minimoon.Node] {
  @headless.tabs(
    id="headless-compat",
    items=[
      @headless.tab_item(
        key="first",
        label="First",
        panel=@minimoon.p("Headless 0.1"),
      ),
    ],
  )
}

///|
pub fn styled_tabs() -> @minimoon.Val[@minimoon.Node] {
  @styles.tabs(
    id="styled-compat",
    items=[
      @styles.tab_item(
        key="first",
        label="First",
        panel=@minimoon.p("Styled 0.1"),
      ),
    ],
  )
}

///|
pub fn testing_snapshot() -> String {
  let runtime = @testing.mount(root_page())
  let _ = runtime.tap(@testing.by_event("compat/increment"))
  runtime.snapshot()
}
