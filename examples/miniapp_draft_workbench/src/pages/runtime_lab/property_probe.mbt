///|
priv struct PropertyProbe {
  phase : Int32
  value : String
  checked : Bool
} derive(Eq)

///|
fn property_probe() -> @minimoon.Val[@minimoon.Node] {
  let (state, update) = @minimoon.create_variable(PropertyProbe::{
    phase: 0,
    value: "populated",
    checked: true,
  })
  state.view(state => {
    let phase = state.phase
    let populated = phase == 0 || phase == 3
    let options_present = phase != 2
    let input = @minimoon.keyed(
      "editor",
      @minimoon.input(
        id="property-probe-input",
        event_key="property-probe/input",
        value=state.value,
        disabled=populated,
        placeholder=if populated { "restored hint" } else { "" },
        name=if populated { "probe-name" } else { "" },
        maxlength?=if options_present {
          Some(if populated { 24 } else { 0 })
        } else {
          None
        },
        password?=if options_present { Some(populated) } else { None },
        selection_start?=if options_present { Some(0) } else { None },
        selection_end?=if options_present { Some(0) } else { None },
        on_input=@minimoon.Emit(value => {
          update(current => { ..current, value, })
        }),
      ),
    )
    let textarea = @minimoon.keyed(
      "textarea",
      @minimoon.textarea(
        id="property-probe-textarea",
        value=state.value,
        disabled=populated,
        on_input=@minimoon.Emit(value => {
          update(current => { ..current, value, })
        }),
      ),
    )
    let switch = @minimoon.keyed(
      "switch",
      @minimoon.switch(
        id="property-probe-switch",
        checked=state.checked,
        disabled=populated,
        on_change=@minimoon.Emit(checked => {
          update(current => { ..current, checked, })
        }),
      ),
    )
    let checkbox = @minimoon.keyed(
      "checkbox",
      @minimoon.checkbox_group(
        on_change=@minimoon.Emit(values => {
          update(current => { ..current, checked: values.contains("probe"), })
        }),
        [
          @minimoon.checkbox(
            id="property-probe-checkbox",
            value="probe",
            checked=state.checked,
            disabled=populated,
            "Probe",
          ),
        ],
      ),
    )
    @shell.card("属性重置与恢复", section="property-probe", [
      @minimoon.p(
        "phase " +
        phase.to_string() +
        ": populated → empty/false/zero → omitted → restored",
      ),
      @minimoon.button(
        id="property-probe-next",
        event_key="property-probe/next",
        on_tap=update(current => {
          let phase = (current.phase + 1) % 4
          {
            phase,
            value: if phase == 0 || phase == 3 {
              "restored"
            } else {
              ""
            },
            checked: phase == 0 || phase == 3,
          }
        }),
        "下一阶段 / Next phase",
      ),
      @minimoon.keyed_fragment(
        if phase % 2 == 0 {
          [input, textarea, switch, checkbox]
        } else {
          [checkbox, switch, textarea, input]
        },
      ),
      if phase == 2 {
        @minimoon.p(
          "此阶段可重新输入；选区等可选属性已移除。",
        )
      } else {
        @minimoon.nothing()
      },
      @minimoon.p("当前文本：" + state.value),
    ])
  })
}
