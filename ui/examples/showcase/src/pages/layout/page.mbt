///|
pub fn program() -> @minimoon.Page {
  @gallery.page("layout", "布局与导航 / Layout — 6 components", context => {
    let (attachment_status, update_attachment) = @minimoon.create_variable(
      "Application owns attachment actions",
    )
    let panes = @minimoon.Val::constant([
      @ui.resizable_pane(
        key="left",
        content=@ui.card("Left pane: minimum 20%"),
        minimum=20.0,
        maximum=80.0,
      ),
      @ui.resizable_pane(
        key="right",
        content=@ui.card("Right pane: minimum 20%"),
        minimum=20.0,
        maximum=80.0,
      ),
    ])
    @ui.stack([
      @gallery.sample(
        "Attachment",
        attachment_status.map(status => {
          @ui.attachment_group(
            @ui.attachment([
              @ui.attachment_media(
                src="/assets/mmui/check-light.svg",
                alt="Example SVG attachment",
              ),
              @ui.attachment_content([
                @ui.attachment_title("sample.svg"),
                @ui.attachment_description(status),
              ]),
              @ui.attachment_actions([
                @ui.attachment_action(
                  label="Preview",
                  on_tap=update_attachment(_ => "Preview requested"),
                ),
                @ui.attachment_trigger(
                  label="Choose replacement",
                  on_tap=update_attachment(_ => "Selection requested"),
                ),
                @ui.attachment_trigger_link(
                  target=@minimoon.route("pages/foundation/foundation"),
                  "Open details",
                ),
              ]),
            ]),
          )
        }),
      ),
      @gallery.sample("Carousel", compound_carousel()),
      @gallery.sample("Navigation Menu", compound_navigation(context)),
      @gallery.sample(
        "Resizable",
        @ui.stack([
          @ui.resizable(
            context,
            id="layout-resizable",
            panes~,
            initial_sizes=[50.0, 50.0],
            style="height:180px;",
          ),
          @ui.resizable(
            context,
            id="layout-resizable-vertical",
            panes~,
            initial_sizes=[50.0, 50.0],
            orientation=@ui.Vertical,
            style="height:240px;",
          ),
          @ui.resizable(
            context,
            id="layout-resizable-rtl",
            panes~,
            initial_sizes=[50.0, 50.0],
            direction=@theme.Rtl,
            style="height:180px;",
          ),
        ]),
      ),
      @gallery.display(
        "Scroll Area",
        @ui.scroll_area(
          id="layout-scroll",
          height=180,
          [1, 2, 3, 4, 5, 6, 7, 8].map(index => {
            @ui.card("Scrollable item " + index.to_string())
          }),
        ),
      ),
      @gallery.sample("Sidebar", compound_sidebar(context)),
    ])
  })
}
