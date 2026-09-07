///|
fn compound_carousel() -> @minimoon.Val[@minimoon.Node] {
  let items = @minimoon.Val::constant([
    @ui.panel(
      key="first",
      title="First",
      content=@ui.card("First slide — swipe vertically"),
    ),
    @ui.panel(
      key="second",
      title="Second",
      content=@ui.card("Second slide — custom controls"),
    ),
    @ui.panel(
      key="third",
      title="Third",
      content=@ui.card("Third slide — next wraps to first"),
    ),
  ])
  @ui.carousel_provider_with_input(
    id="layout-carousel",
    count=items.map(items => items.length()),
    input=items,
    circular=true,
    orientation=@ui.Vertical,
    render=(scope, items) => {
      @minimoon.fragment([
        @ui.typography_p(
          "Native vertical swiper · circular · compound content and controls",
        ),
        @ui.carousel_items(scope, items~, height="180px"),
        @minimoon.div(
          id="layout-carousel-status",
          "Slide " +
          (@ui.carousel_active_index(scope) + 1).to_string() +
          " / " +
          @ui.carousel_slide_count(scope).to_string(),
        ),
        @ui.button_group([
          @ui.carousel_previous(scope, [
            @minimoon.text("↑"),
            @minimoon.text("Previous slide"),
          ]),
          @ui.carousel_next(scope, [
            @minimoon.text("↓"),
            @minimoon.text("Next slide"),
          ]),
        ]),
      ])
    },
  )
}

///|
fn compound_navigation(
  context : @ui.UiContext,
) -> @minimoon.Val[@minimoon.Node] {
  @ui.navigation_menu_root(context, id="layout-navigation", render=scope => {
    @minimoon.fragment([
      @ui.typography_p(
        "Open either item: one measured viewport is shared outside this page's scroll area.",
      ),
      @ui.navigation_menu_viewport(
        scope,
        @ui.typography_small("Shared viewport footer · native Route links"),
      ),
      @ui.navigation_menu_list(scope, [
        @ui.navigation_menu_item(scope, value="explore", render=item => {
          @minimoon.fragment([
            @ui.navigation_menu_trigger(item, [
              @minimoon.text("⌄"),
              @minimoon.text("Explore"),
            ]),
            @ui.navigation_menu_indicator(item),
            @ui.navigation_menu_content(
              item,
              @ui.card([
                @ui.typography_h3("Explore components"),
                @ui.navigation_menu_link(
                  scope~,
                  target=@minimoon.route("pages/foundation/foundation"),
                  @minimoon.text("Foundation components"),
                ),
                @ui.navigation_menu_link(
                  scope~,
                  target=@minimoon.route("pages/forms/forms"),
                  @minimoon.text("Form controls"),
                ),
              ]),
            ),
          ])
        }),
        @ui.navigation_menu_item(scope, value="learn", render=item => {
          @minimoon.fragment([
            @ui.navigation_menu_trigger(item, @minimoon.text("Learn")),
            @ui.navigation_menu_indicator(item),
            @ui.navigation_menu_content(item, [
              @ui.typography_h3("Composition and feedback"),
              @ui.navigation_menu_link(
                scope~,
                target=@minimoon.route("pages/overlays/overlays"),
                @minimoon.text("Layered overlays"),
              ),
              @ui.navigation_menu_link(
                scope~,
                target=@minimoon.route("pages/feedback/feedback"),
                @minimoon.text("Messages and notifications"),
              ),
            ]),
          ])
        }),
        @ui.navigation_menu_item(scope, value="disabled", disabled=true, render=item => {
          @ui.navigation_menu_trigger(item, @minimoon.text("Disabled"))
        }),
      ]),
    ])
  })
}

///|
fn compound_sidebar(context : @ui.UiContext) -> @minimoon.Val[@minimoon.Node] {
  let (query, update_query) = @minimoon.create_variable("")
  @ui.sidebar_provider_with_input(
    context,
    id="layout-sidebar",
    input=query,
    default_width=200.0,
    render=(scope, query) => {
      @minimoon.div(style="width:100%;min-width:0;", [
        @ui.typography_p(
          "Desktop collapse and mobile drawer are independent. Drag the desktop rail; collapsed icons expose long-press / ? help.",
        ),
        @ui.button_group([
          @ui.sidebar_trigger(scope, @minimoon.text("Collapse / expand")),
          @ui.sidebar_trigger(
            scope,
            mobile=true,
            @minimoon.text("Open mobile drawer"),
          ),
        ]),
        @minimoon.div(
          id="layout-sidebar-status",
          "Collapsed: " +
          @ui.sidebar_is_collapsed(scope).to_string() +
          " · mobile: " +
          @ui.sidebar_is_mobile_open(scope).to_string() +
          " · width: " +
          @ui.sidebar_width(scope).to_string(),
        ),
        @minimoon.div(style="display:flex;min-width:0;height:320px;", [
          @ui.sidebar_surface(
            scope,
            variant=@ui.SidebarFloating,
            collapsible=@ui.SidebarIcon,
            render=surface => {
              @minimoon.fragment([
                @ui.sidebar_header([
                  @ui.typography_small("Workspace"),
                  @ui.sidebar_input(
                    id="layout-sidebar-query",
                    event_key="layout-sidebar/query",
                    value=query,
                    on_input=update_query.map(value => _ => value),
                    placeholder="Search the workspace",
                  ),
                ]),
                @ui.sidebar_content(
                  height="180px",
                  @ui.sidebar_group([
                    @ui.sidebar_group_label(
                      surface,
                      @minimoon.text("Components"),
                    ),
                    @ui.sidebar_group_content(
                      @ui.sidebar_menu([
                        @ui.sidebar_menu_item([
                          @ui.sidebar_menu_button_with_tooltip(
                            surface,
                            id="layout-sidebar-home",
                            tooltip="Foundation components",
                            target=@minimoon.route(
                              "pages/foundation/foundation",
                            ),
                            icon=@minimoon.text("F"),
                            is_active=true,
                            @minimoon.text("Foundation"),
                          ),
                          @ui.sidebar_menu_badge(surface, @minimoon.text("20")),
                          @ui.sidebar_menu_sub(
                            surface,
                            @ui.sidebar_menu_sub_item(
                              @ui.sidebar_menu_sub_button(
                                surface,
                                target=@minimoon.route("pages/forms/forms"),
                                @minimoon.text("Nested form controls"),
                              ),
                            ),
                          ),
                        ]),
                        @ui.sidebar_menu_item(
                          @ui.sidebar_menu_button_with_tooltip(
                            surface,
                            id="layout-sidebar-data",
                            tooltip="Data components",
                            target=@minimoon.route("pages/data/data"),
                            icon=@minimoon.text("D"),
                            @minimoon.text("Data"),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                @ui.sidebar_footer(
                  @ui.typography_small("Drag rail: 160–280px"),
                ),
                @ui.sidebar_rail(surface, min_width=160.0, max_width=280.0),
              ])
            },
          ),
          @ui.sidebar_inset([
            @ui.typography_small("Inset content"),
            @minimoon.text(
              if query == "" {
                "Search input stays controlled while collapsed or reopened."
              } else {
                "Query: " + query
              },
            ),
          ]),
        ]),
        @ui.sidebar_surface(
          scope,
          side=@ui.SidebarRight,
          mobile=true,
          aria_label="Mobile sidebar",
          render=surface => {
            @minimoon.fragment([
              @ui.sidebar_header(@ui.typography_h3("Mobile workspace")),
              @ui.sidebar_content(
                @ui.sidebar_menu([
                  @ui.sidebar_menu_button(
                    surface,
                    target=@minimoon.route("pages/forms/forms"),
                    event_key="layout-sidebar/mobile-forms",
                    @minimoon.text("Forms (navigate and close)"),
                  ),
                  @ui.sidebar_menu_button(
                    surface,
                    target=@minimoon.route("pages/data/data"),
                    @minimoon.text("Data"),
                  ),
                ]),
              ),
              @ui.sidebar_footer(
                @ui.button(
                  event_key="layout-sidebar/mobile-close",
                  on_tap=@ui.sidebar_close_mobile(scope),
                  "Close mobile sidebar",
                ),
              ),
            ])
          },
        ),
      ])
    },
  )
}
