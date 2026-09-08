///|
pub fn program() -> @minimoon.Page {
  @gallery.page("foundation", "基础展示 / Foundation — 20 components", _ => {
    let (count, increment) = @minimoon.create_variable(0)
    @ui.stack([
      @gallery.display(
        "Alert",
        @ui.alert([
          @ui.alert_title("Ready to use"),
          @ui.alert_description("Typed MoonBit components on Skyline."),
        ]),
      ),
      @gallery.display(
        "Aspect Ratio",
        @ui.aspect_ratio(ratio=16.0 / 9.0, @ui.card("16:9 content")),
      ),
      @gallery.sample(
        "Avatar",
        @ui.avatar_with_fallback(src=@minimoon.Val::constant(""), @ui.kbd("MM")),
      ),
      @gallery.display("Badge", @ui.badge("Native")),
      @gallery.display(
        "Breadcrumb",
        @ui.breadcrumb(
          @ui.breadcrumb_list([
            @ui.breadcrumb_item("Components"),
            @ui.breadcrumb_separator(),
            @ui.breadcrumb_page("Foundation"),
          ]),
        ),
      ),
      @gallery.display(
        "Bubble",
        @ui.bubble_group([
          @ui.bubble(@ui.bubble_content("A touch-first message")),
          @ui.bubble(alignment=@ui.End, @ui.bubble_content("A native reply")),
        ]),
      ),
      @gallery.sample(
        "Button",
        count.map(value => {
          @ui.button(
            on_tap=increment(value => value + 1),
            event_key="foundation/count",
            "Count " + value.to_string(),
          )
        }),
      ),
      @gallery.display(
        "Button Group",
        @ui.button_group([
          @ui.button("Enabled"),
          @ui.button(disabled=true, "Disabled"),
          @ui.button(variant=@ui.Outline, "Outline"),
        ]),
      ),
      @gallery.display(
        "Card",
        @ui.card([
          @ui.card_header([
            @ui.card_title("A card"),
            @ui.card_description("Composed content slots"),
          ]),
          @ui.card_content("Content"),
          @ui.card_footer("Footer"),
        ]),
      ),
      @gallery.display(
        "Direction",
        @ui.direction(
          @theme.Rtl,
          @ui.button_group([@ui.button("First"), @ui.button("Second")]),
        ),
      ),
      @gallery.display(
        "Empty",
        @ui.empty([
          @ui.empty_header([
            @ui.empty_title("No entries"),
            @ui.empty_description("Create the first item."),
          ]),
          @ui.empty_content(@ui.button("Create")),
        ]),
      ),
      @gallery.display(
        "Item",
        @ui.item([
          @ui.item_media("◇"),
          @ui.item_content([
            @ui.item_title("Example item"),
            @ui.item_description("A reusable row"),
          ]),
          @ui.item_actions(@ui.button(variant=@ui.Ghost, "Open")),
        ]),
      ),
      @gallery.display("Kbd", @ui.kbd_group([@ui.kbd("⌘"), @ui.kbd("K")])),
      @gallery.sample(
        "Label",
        @ui.input_stateful(
          id="foundation-label",
          options=@ui.input_options(placeholder="Tap the associated label"),
        ).map(input => {
          @minimoon.div([
            @ui.label(for_id="foundation-label", required=true, "Name"),
            input,
          ])
        }),
      ),
      @gallery.display(
        "Marker",
        @ui.marker([@ui.marker_icon("●"), @ui.marker_content("Online")]),
      ),
      @gallery.display(
        "Message",
        @ui.message([
          @ui.message_avatar(@ui.avatar(@ui.avatar_fallback("A"))),
          @ui.message_content([
            @ui.message_header("Assistant"),
            @ui.typography_p("One page owns this conversation."),
            @ui.message_footer("Just now"),
          ]),
        ]),
      ),
      @gallery.display(
        "Separator",
        @minimoon.div([
          @ui.typography_small("Before"),
          @ui.separator(),
          @ui.typography_small("After"),
        ]),
      ),
      @gallery.display(
        "Skeleton",
        @minimoon.div([
          @ui.skeleton(width=160, height=20),
          @ui.skeleton(width=100, height=16),
        ]),
      ),
      @gallery.display("Spinner", @ui.spinner(label="Loading preview")),
      @gallery.display(
        "Typography",
        @minimoon.div([
          @ui.typography_h2("A readable heading"),
          @ui.typography_p(
            "Native text styles retain the Vega visual direction.",
          ),
          @ui.typography_blockquote("Composition remains explicit."),
          @ui.typography_inline_code("Val[Node]"),
        ]),
      ),
    ])
  })
}
