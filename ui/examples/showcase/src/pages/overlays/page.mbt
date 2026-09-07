///|
pub fn program() -> @minimoon.Page {
  @gallery.page("overlays", "展开与浮层 / Overlays — 13 components", context => {
    let (actions, record_action) = @minimoon.create_variable(0)
    let (checked, set_checked) = @minimoon.create_variable(false)
    let content = actions.map(count => {
      @ui.typography_p("Completed actions: " + count.to_string())
    })
    let panels = @minimoon.Val::constant([
      @ui.panel(
        key="first",
        title="First",
        content=@ui.typography_p("First panel"),
      ),
      @ui.panel(
        key="second",
        title="Second",
        content=@ui.typography_p("Second panel"),
      ),
      @ui.panel(
        key="disabled",
        title="Disabled",
        content=@minimoon.nothing(),
        disabled=true,
      ),
    ])
    let items = checked.map(checked => {
      [
        @ui.menu_label(key="label", label="Actions"),
        @ui.menu_item(
          key="action",
          label="Record action",
          on_select=record_action(value => value + 1),
        ),
        @ui.menu_checkbox_item(
          key="flag",
          label="Checked preference",
          checked~,
          on_change=set_checked.map(value => _ => value),
        ),
        @ui.menu_separator(key="separator"),
        @ui.menu_submenu(key="more", label="More", items=[
          @ui.menu_item(
            key="nested",
            label="Nested action",
            on_select=record_action(value => value + 1),
          ),
        ]),
      ]
    })
    @ui.stack([
      @gallery.sample(
        "Accordion",
        @ui.accordion(id="overlay-accordion", items=panels, multiple=true),
      ),
      @gallery.sample(
        "Alert Dialog",
        @ui.alert_dialog(
          context,
          id="overlay-alert-dialog",
          title="Confirm action",
          trigger_label="Open confirmation",
          content~,
          on_confirm=record_action(value => value + 1),
        ),
      ),
      @gallery.sample(
        "Collapsible",
        @ui.collapsible(
          id="overlay-collapsible",
          title="Expand content",
          content~,
        ),
      ),
      @gallery.sample(
        "Dialog",
        @ui.stack([
          @ui.dialog(
            context,
            id="overlay-dialog",
            title="Dialog",
            trigger_label="Open dialog",
            content~,
          ),
          @ui.overlay_provider(context, id="overlay-rich-dialog", render=scope => {
            @minimoon.fragment([
              @ui.overlay_trigger(
                scope,
                @ui.typography_large("Rich dialog trigger"),
              ),
              @ui.overlay_content(scope, [
                @ui.overlay_header([
                  @ui.overlay_title(scope, "Custom dialog"),
                  @ui.overlay_description(
                    scope, "Rich slots and independently keyed actions",
                  ),
                ]),
                @ui.overlay_footer([
                  @ui.overlay_action(
                    scope,
                    "Apply and keep open",
                    key="keep",
                    close=false,
                    on_tap=record_action(value => value + 1),
                  ),
                  @ui.overlay_action(
                    scope,
                    "Apply and close",
                    key="save",
                    on_tap=record_action(value => value + 1),
                  ),
                ]),
              ]),
            ])
          }),
        ]),
      ),
      @gallery.sample(
        "Drawer",
        @ui.stack([
          @ui.drawer(
            context,
            id="overlay-drawer-bottom",
            title="Bottom drawer",
            trigger_label="Open bottom drawer",
            content~,
          ),
          @ui.drawer(
            context,
            id="overlay-drawer-left",
            title="Left drawer",
            trigger_label="Open left drawer",
            content~,
            side=@ui.Left,
          ),
          @ui.drawer(
            context,
            id="overlay-drawer-top",
            title="Top drawer",
            trigger_label="Open top drawer",
            content~,
            side=@ui.Top,
          ),
          @ui.drawer(
            context,
            id="overlay-drawer-right",
            title="Right drawer",
            trigger_label="Open right drawer",
            content~,
            side=@ui.Right,
          ),
        ]),
      ),
      @gallery.sample(
        "Dropdown Menu",
        @ui.dropdown_menu(
          context,
          id="overlay-dropdown",
          trigger_label="Open dropdown",
          items~,
        ),
      ),
      @gallery.sample(
        "Hover Card",
        @ui.overlay_provider(
          context,
          id="overlay-preview",
          kind=@ui.PreviewSurface,
          delay_ms=250,
          close_delay_ms=150,
          render=scope => {
            @minimoon.fragment([
              @ui.overlay_trigger(scope, "Tap for delayed preview"),
              @ui.overlay_content(scope, [
                @ui.overlay_arrow(),
                @ui.overlay_title(scope, "Touch preview"),
                @ui.overlay_description(
                  scope, "250ms open / 150ms close; hide cancels pending work",
                ),
              ]),
            ])
          },
        ),
      ),
      @gallery.sample(
        "Menubar",
        @ui.menubar(context, id="overlay-menubar", groups=[
          { key: "file", label: "File", items, },
          { key: "edit", label: "Edit", items, },
        ]),
      ),
      @gallery.sample(
        "Context Menu",
        @ui.context_menu(
          context,
          id="overlay-context",
          trigger_label="Long press or tap",
          items~,
        ),
      ),
      @gallery.sample(
        "Popover",
        @ui.popover(
          context,
          id="overlay-popover",
          title="Positioned popover",
          trigger_label="Open popover",
          content~,
        ),
      ),
      @gallery.sample(
        "Sheet",
        @ui.sheet(
          context,
          id="overlay-sheet",
          title="Side sheet",
          trigger_label="Open sheet",
          content~,
        ),
      ),
      @gallery.sample(
        "Tabs",
        @ui.tabs(id="overlay-tabs", items=panels, initial_selected="first"),
      ),
      @gallery.sample(
        "Tooltip",
        @ui.tooltip(
          context,
          id="overlay-tooltip",
          trigger_label="Show help",
          text="Touch-friendly help text",
        ),
      ),
    ])
  })
}
