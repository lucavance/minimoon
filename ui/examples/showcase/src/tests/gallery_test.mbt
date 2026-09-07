///|
test "six showcase pages mount, switch theme, hide/show and dispose independently" {
  let pages = [
    @foundation.program(),
    @overlays.program(),
    @forms.program(),
    @data.program(),
    @layout.program(),
    @feedback.program(),
  ]
  for page in pages {
    let runtime = @testing.mount(page)
    assert_true(runtime.snapshot().contains("mmui-light"))
    let _ = runtime.tap(@testing.by_event_key("gallery/theme"))
    assert_true(runtime.snapshot().contains("mmui-dark"))
    let _ = runtime.tap(@testing.by_event_key("gallery/direction"))
    assert_true(runtime.snapshot().contains("mmui-rtl"))
    let _ = runtime.lifecycle("onHide")
    let _ = runtime.lifecycle("onShow")
    assert_true(runtime.snapshot().contains("mmui-dark"))
    let _ = runtime.dispose()
  }
}

///|
test "showcase state survives theme changes but remains page-instance owned" {
  let first = @testing.mount(@foundation.program())
  let second = @testing.mount(@foundation.program())
  let _ = first.tap(@testing.by_event_key("foundation/count"))
  let _ = first.tap(@testing.by_event_key("gallery/theme"))
  assert_true(first.snapshot().contains("Count 1"))
  assert_true(second.snapshot().contains("Count 0"))
  let _ = first.dispose()
  let _ = second.dispose()
}

///|
test "gallery categories contain all 64 named components and Form" {
  let groups : Array[(@minimoon.Page, Array[String])] = [
    (
      @foundation.program(),
      [
        "Alert", "Aspect Ratio", "Avatar", "Badge", "Breadcrumb", "Bubble", "Button",
        "Button Group", "Card", "Direction", "Empty", "Item", "Kbd", "Label", "Marker",
        "Message", "Separator", "Skeleton", "Spinner", "Typography",
      ],
    ),
    (
      @overlays.program(),
      [
        "Accordion", "Alert Dialog", "Collapsible", "Dialog", "Drawer", "Dropdown Menu",
        "Hover Card", "Menubar", "Context Menu", "Popover", "Sheet", "Tabs", "Tooltip",
      ],
    ),
    (
      @forms.program(),
      [
        "Checkbox", "Field", "Input", "Input Group", "Input OTP", "Native Select",
        "Progress", "Radio Group", "Select", "Slider", "Switch", "Textarea", "Toggle",
        "Toggle Group", "Form",
      ],
    ),
    (
      @data.program(),
      [
        "Calendar", "Chart", "Combobox", "Command", "Data Table", "Date Picker",
        "Pagination", "Table",
      ],
    ),
    (
      @layout.program(),
      [
        "Attachment", "Carousel", "Navigation Menu", "Resizable", "Scroll Area",
        "Sidebar",
      ],
    ),
    (@feedback.program(), ["Message Scroller", "Sonner", "Toast"]),
  ]
  let mut count = 0
  for group in groups {
    let runtime = @testing.mount(group.0)
    for name in group.1 {
      let _ = runtime.get(@testing.by_section(name))
      count = count + 1
    }
    let _ = runtime.dispose()
  }
  assert_eq(count, 65)
}

///|
test "gallery navigation dispatches typed replacement routes" {
  let runtime = @testing.mount(@foundation.program())
  let commands = runtime.tap(@testing.by_event_key("gallery/nav/forms"))
  assert_true(commands.contains("RedirectTo"))
  assert_true(commands.contains("/pages/forms/forms"))
  let _ = runtime.dispose()
}
