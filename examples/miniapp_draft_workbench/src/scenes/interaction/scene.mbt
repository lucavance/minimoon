///|
/// Independent controls need independent values, not a duplicate runtime-lab model.
pub fn scene(context : @minimoon.PageContext) -> @minimoon.Val[@minimoon.Node] {
  let (name, rename) = @minimoon.create_variable("Minimoon")
  let (checked, check) = @minimoon.create_variable(["typed"])
  let (radio, choose_radio) = @minimoon.create_variable("moonbit")
  let (picker, choose_picker) = @minimoon.create_variable(0)
  let (slide, choose_slide) = @minimoon.create_variable(0)
  let name_node = name.view(name => {
    @minimoon.fragment([
      @minimoon.input(
        class="demo-input",
        value=name,
        placeholder="输入后切换 Tab，再回来",
        event_key="interaction/name",
        on_input=rename.map(value => _ => value),
      ),
      @minimoon.p("输入：" + name),
    ])
  })
  let choice_node = checked.view2(radio, (checked, radio) => {
    @minimoon.fragment([
      @minimoon.p("选择：" + checked.join(", ") + " · " + radio),
      @minimoon.checkbox_group(
        event_key="controls/checked",
        on_change=check.map(value => _ => value),
        [
          @minimoon.checkbox(
            value="typed",
            checked=checked.contains("typed"),
            "typed",
          ),
          @minimoon.checkbox(
            value="scoped",
            checked=checked.contains("scoped"),
            "scoped",
          ),
        ],
      ),
      @minimoon.radio_group(
        event_key="controls/radio",
        on_change=choose_radio.map(value => _ => value),
        [
          @minimoon.radio(
            value="moonbit",
            checked=radio == "moonbit",
            "MoonBit",
          ),
          @minimoon.radio(
            value="miniapp",
            checked=radio == "miniapp",
            "MiniApp",
          ),
        ],
      ),
    ])
  })
  let picker_node = picker.view(picker => {
    let options = ["MoonBit", "Skyline", "ArkUI"]
    @minimoon.picker_selector(
      id="control-picker",
      options~,
      selected=picker,
      event_key="controls/picker",
      on_change=choose_picker.map(value => _ => value),
      "picker: " + options[picker],
    )
  })
  let slide_node = slide.view(slide => {
    @minimoon.fragment([
      @minimoon.p("current swiper page: " + (slide + 1).to_string()),
      @minimoon.swiper(
        current=slide,
        circular=true,
        class="h-[240rpx]",
        event_key="controls/slide",
        on_change=choose_slide.map(value => _ => value),
        [
          @minimoon.swiper_item(
            item_id="first",
            @minimoon.div(class="h-[120rpx] bg-sky-50", "Swiper page 1"),
          ),
          @minimoon.swiper_item(
            item_id="second",
            @minimoon.div(class="h-[120rpx] bg-sky-50", "Swiper page 2"),
          ),
        ],
      ),
    ])
  })
  let first = @card.card(
    context,
    "primary",
    @minimoon.Val::constant(
      @card.props(
        id="primary-card",
        title="组件一",
        pulse_step=1,
        tone="border-sky-200 bg-sky-50",
      ),
    ),
  )
  let second = @card.card(
    context,
    "secondary",
    @minimoon.Val::constant(
      @card.props(
        id="secondary-card",
        title="组件二",
        pulse_step=2,
        tone="border-amber-200 bg-amber-50",
      ),
    ),
  )
  name_node.view6(choice_node, picker_node, slide_node, first, second, (
    name,
    choices,
    picker,
    slide,
    first,
    second,
  ) => {
    @minimoon.div(class="demo-stack", [
      @shell.card("原生控件", section="interaction-native", [
        @minimoon.p(
          "输入、选择与滑动分别更新，结果显示在控件旁。",
        ),
        name,
        choices,
        picker,
        slide,
      ]),
      @shell.card("局部组件", section="interaction-local", [
        @minimoon.p(
          "分别编辑卡片、打开计时：状态各自独立。移除与恢复请进入运行实验。",
        ),
        first,
        second,
      ]),
    ])
  })
}
