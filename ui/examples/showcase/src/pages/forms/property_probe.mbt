///|
fn property_probe() -> @minimoon.Val[@minimoon.Node] {
  let (phase, advance) = @minimoon.create_variable(0)
  let (value, edit) = @minimoon.create_variable("populated")
  let (checked, toggle) = @minimoon.create_variable(true)
  let checkbox = phase.switch_by(
    (phase, _) => {
      @ui.checkbox_controlled(
        id="ui-property-checkbox",
        checked~,
        on_change=toggle.map(value => _ => value),
        disabled=phase == 0 || phase == 3,
        label="Reset checkbox",
      )
    },
    by=value => value.to_string(),
  )
  let switch = phase.switch_by(
    (phase, _) => {
      @ui.switch_controlled(
        id="ui-property-switch",
        checked~,
        on_change=toggle.map(value => _ => value),
        disabled=phase == 0 || phase == 3,
        label="Reset switch",
      )
    },
    by=value => value.to_string(),
  )
  @minimoon.Val::view4(phase, value, checkbox, switch, (
    phase,
    value,
    checkbox,
    switch,
  ) => {
    let populated = phase == 0 || phase == 3
    let options = @ui.input_options(
      disabled=populated,
      read_only=phase == 1,
      password=populated,
      maxlength=if phase == 1 { 0 } else { 140 },
      placeholder=if populated { "restored hint" } else { "" },
      selection_start?=if phase == 2 { None } else { Some(0) },
      selection_end?=if phase == 2 { None } else { Some(0) },
    )
    let on_input = edit.map(value => _ => value)
    let input = @minimoon.keyed(
      "input",
      @ui.input(id="ui-property-input", value~, on_input~, options~),
    )
    let textarea = @minimoon.keyed(
      "textarea",
      @ui.textarea(id="ui-property-textarea", value~, on_input~, options~),
    )
    @minimoon.div(data_section="Property Reset", [
      @ui.typography_h2("Property Reset"),
      @ui.typography_p(
        "phase " +
        phase.to_string() +
        ": populated → empty/false/zero → omitted → restored",
      ),
      @ui.button(
        id="ui-property-next",
        event_key="forms/property-next",
        on_tap=@minimoon.batch([
          advance(value => (value + 1) % 4),
          edit(_ => if phase == 2 || phase == 3 { "restored" } else { "" }),
          toggle(_ => phase == 2 || phase == 3),
        ]),
        "Next property phase",
      ),
      @minimoon.keyed_fragment(
        if phase % 2 == 0 {
          [input, textarea]
        } else {
          [textarea, input]
        },
      ),
      checkbox,
      switch,
      if phase == 2 {
        @ui.typography_p(
          "Enabled: type, paste, delete; selection props are absent.",
        )
      } else {
        @minimoon.nothing()
      },
      @ui.typography_small("Value: " + value),
    ])
  })
}
