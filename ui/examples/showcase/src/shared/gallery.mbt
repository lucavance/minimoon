///|
pub fn constant(node : @minimoon.Node) -> @minimoon.Val[@minimoon.Node] {
  @minimoon.Val::constant(node)
}

///|
pub fn sample(
  name : String,
  content : @minimoon.Val[@minimoon.Node],
) -> @minimoon.Val[@minimoon.Node] {
  content.map(node => {
    @minimoon.div(class="gallery-sample", data_section=name, [
      @ui.typography_h2(class="gallery-heading", name),
      @minimoon.div(class="gallery-preview", [node]),
    ])
  })
}

///|
pub fn display(
  name : String,
  node : @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  sample(name, constant(node))
}

///|
pub fn page(
  id : String,
  title : String,
  build : (@ui.UiContext) -> @minimoon.Val[@minimoon.Node],
  capabilities? : Array[@minimoon.Capability] = [],
) -> @minimoon.Page {
  @minimoon.page(
    id="ui_" + id,
    route=@minimoon.route("pages/" + id + "/" + id),
    title~,
    capabilities=[
      @minimoon.NavigateTo,
      @minimoon.RedirectTo,
      @minimoon.MeasureNodes,
      ..capabilities,
    ],
    build=page_context => {
      let (dark, toggle_dark) = @minimoon.create_variable(false)
      let (rtl, toggle_rtl) = @minimoon.create_variable(false)
      let theme = @minimoon.Val::map2(dark, rtl, (dark, rtl) => {
        @theme.theme(
          mode=if dark { @theme.Dark } else { @theme.Light },
          direction=if rtl { @theme.Rtl } else { @theme.Ltr },
        )
      })
      let navigation = @minimoon.div(class="gallery-nav", [
        @ui.button(
          on_tap=toggle_dark(value => !value),
          event_key="gallery/theme",
          "Light / Dark",
        ),
        @ui.button(
          on_tap=toggle_rtl(value => !value),
          event_key="gallery/direction",
          "LTR / RTL",
        ),
        @minimoon.div(
          class="gallery-nav",
          ["foundation", "overlays", "forms", "data", "layout", "feedback"].map(category => {
              @ui.button(
                on_tap=@minimoon.redirect_to(
                  @minimoon.route("pages/" + category + "/" + category),
                ),
                event_key="gallery/nav/" + category,
                variant=@ui.Outline,
                category,
              )
            },
          ),
        ),
      ])
      @ui.root(
        page_context,
        context => {
          build(context).map(content => {
            @minimoon.scroll_view(scroll_y=true, style="height:100vh;", [
              @minimoon.div(class="gallery-page", [
                @ui.typography_h1("Minimoon UI"),
                @ui.typography_lead(title),
                navigation,
                content,
              ]),
            ])
          })
        },
        theme~,
      )
    },
  )
}
