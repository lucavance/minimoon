///|
pub fn scene() -> @minimoon.Val[@minimoon.Node] {
  let (reactive_count, increment_reactive_count) = @minimoon.create_pure_state(
    0,
    update=(current, _message : Unit) => current + 1,
  )
  let disclosure = @components.disclosure(
    @components.disclosure_spec(
      id="conformance-disclosure",
      label="展开说明 / Disclosure",
      panel=@minimoon.p("Disclosure panel content"),
    ),
  )
  let accordion = @components.accordion_single(
    id="conformance-accordion",
    label="手风琴 · 单开",
    collapsible=false,
    items=[
      @components.accordion_item(
        key="first",
        label="第一项 / Accordion first",
        panel=@minimoon.p("Accordion first panel"),
      ),
      @components.accordion_item(
        key="second",
        label="第二项 / Accordion second",
        panel=@minimoon.p("Accordion second panel"),
      ),
    ],
  )
  let accordion_multiple = @components.accordion_multiple(
    id="conformance-accordion-multiple",
    label="手风琴 · 多开",
    initial_open_keys=["first"],
    items=[
      @components.accordion_item(
        key="first",
        label="第一项 / Multiple first",
        panel=@minimoon.p("Multiple first panel"),
      ),
      @components.accordion_item(
        key="second",
        label="第二项 / Multiple second",
        panel=@minimoon.p("Multiple second panel"),
      ),
    ],
  )
  let reactive_accordion = @components.accordion_single_with_input(
    id="conformance-reactive-accordion",
    label="响应式子状态",
    input=reactive_count,
    items=[
      @components.accordion_item_with_input(
        key="counter",
        label="展开计数器",
        panel=count => {
          @minimoon.div([
            @minimoon.p("reactive counter:" + count.to_string()),
            @minimoon.button(
              on_tap=increment_reactive_count(()),
              event_key="conformance-reactive-counter/increment",
              "子计数 +1",
            ),
          ])
        },
      ),
    ],
  )
  let tabs = @components.tabs(
    id="conformance-tabs",
    label="Conformance tab sections",
    items=[
      @components.tab_item(
        key="overview",
        label="概览 / Overview tab",
        panel=@minimoon.p("Overview tab panel"),
      ),
      @components.tab_item(
        key="details",
        label="详情 / Details tab",
        panel=@minimoon.p("Details tab panel"),
      ),
    ],
  )
  let dialog = @components.dialog(
    @components.dialog_spec(
      id="conformance-dialog",
      title="Conformance dialog",
      description="点击内容按钮或遮罩均可关闭。",
      trigger_label="打开对话框",
      content=close => {
        @minimoon.button(
          on_tap=close,
          event_key="conformance-dialog/content-close",
          "关闭对话框",
        )
      },
    ),
  )
  let sheet = @components.sheet(
    @components.sheet_spec(
      id="conformance-sheet",
      title="Conformance sheet",
      trigger_label="打开底部面板",
      side=@components.Bottom,
      content=_ => @minimoon.p("Sheet panel content"),
    ),
  )
  let dropdown = @components.dropdown(
    @components.dropdown_spec(
      id="conformance-menu",
      trigger_label="打开菜单",
      placement=@components.TopStart,
      items=[
        @components.menu_label(key="preferences", label="Preferences"),
        @components.menu_checkbox_item(key="compact", label="紧凑显示"),
        @components.menu_radio_item(
          key="theme-light",
          label="浅色",
          group="theme",
          value="light",
        ),
        @components.menu_radio_item(
          key="theme-dark",
          label="深色",
          group="theme",
          value="dark",
        ),
        @components.menu_separator(key="menu-separator"),
        @components.menu_submenu(key="more", label="更多操作", items=[
          @components.menu_item(key="about", label="About Minimoon"),
        ]),
      ],
    ),
  )
  let content_navigation = @minimoon.Val::view8(
    disclosure,
    accordion,
    accordion_multiple,
    reactive_accordion,
    tabs,
    dialog,
    sheet,
    dropdown,
    (
      disclosure,
      accordion,
      accordion_multiple,
      reactive_accordion,
      tabs,
      dialog,
      sheet,
      dropdown,
    ) => {
      @minimoon.div(class="demo-stack", [
        @shell.card("展开与切换", section="interaction-disclosure", [
          disclosure, accordion, accordion_multiple, reactive_accordion, tabs,
        ]),
        @shell.card("弹层与菜单", section="interaction-overlays", [
          dialog, sheet, dropdown,
        ]),
      ])
    },
  )
  let (parent, change_parent) = @minimoon.create_variable(0)
  let parent_node = parent.view(parent => {
    @shell.card("响应式内容", section="reactive-parent", [
      @minimoon.p(
        "展开计数器并递增，再更新父层、折叠重开：子计数不变。",
      ),
      @minimoon.button(
        class="demo-action",
        event_key="composition/parent-update",
        on_tap=change_parent(value => value + 1),
        "更新父层",
      ),
      @minimoon.p("parent updates: " + parent.to_string()),
    ])
  })
  content_navigation.view2(parent_node, (content, parent) => {
    @minimoon.div(class="demo-stack", data_section="composed-controls", [
      parent, content,
    ])
  })
}
