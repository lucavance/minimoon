///|
struct DisclosureSpecWithInput[Input] {
  id : String
  label : String
  panel : (Input) -> @minimoon.Node
  root_class : String
  trigger_class : String
  panel_class : String
}

///|
pub fn[Input] disclosure_spec_with_input(
  id~ : String,
  label~ : String,
  panel~ : (Input) -> @minimoon.Node,
  root_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> DisclosureSpecWithInput[Input] {
  guard id != "" else { abort("disclosure id must not be empty") }
  { id, label, panel, root_class, trigger_class, panel_class, }
}

///|
pub fn[Input : Eq] disclosure_controlled_with_input(
  spec : DisclosureSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  expanded~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  expanded.view2(input, (is_expanded, value) => {
    let trigger_id = spec.id + "-trigger"
    let panel_id = spec.id + "-panel"
    @minimoon.div(
      id=spec.id,
      class=spec.root_class,
      data_section="disclosure",
      semantics=@minimoon.semantics(role=@minimoon.GroupRole),
      [
        @minimoon.button(
          id=trigger_id,
          class=spec.trigger_class,
          event_key=spec.id + "/toggle",
          on_tap=on_change(!is_expanded),
          semantics=@minimoon.semantics(
            role=@minimoon.ButtonRole,
            expanded=is_expanded,
            controls=panel_id,
          ),
          spec.label,
        ),
        if is_expanded {
          @minimoon.div(
            id=panel_id,
            class=spec.panel_class,
            data_section="disclosure-panel",
            semantics=@minimoon.semantics(
              role=@minimoon.RegionRole,
              labelled_by=trigger_id,
            ),
            [(spec.panel)(value)],
          )
        } else {
          @minimoon.nothing()
        },
      ],
    )
  })
}

///|
pub fn[Input : Eq] disclosure_with_input(
  spec : DisclosureSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  initially_expanded? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (expanded, update_expanded) = @minimoon.create_variable(
    initially_expanded,
  )
  disclosure_controlled_with_input(
    spec,
    input~,
    expanded~,
    on_change=update_expanded.map(value => _ => value),
  )
}
