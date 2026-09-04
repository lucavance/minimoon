///|
struct DisclosureSpec {
  id : String
  label : String
  panel : @minimoon.Node
  root_class : String
  trigger_class : String
  panel_class : String
}

///|
pub fn disclosure_spec(
  id~ : String,
  label~ : String,
  panel~ : @minimoon.Node,
  root_class? : String = "",
  trigger_class? : String = "",
  panel_class? : String = "",
) -> DisclosureSpec {
  guard id != "" else { abort("disclosure id must not be empty") }
  { id, label, panel, root_class, trigger_class, panel_class, }
}

///|
pub fn disclosure_controlled(
  spec : DisclosureSpec,
  expanded~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  expanded.map(is_expanded => {
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
            [spec.panel],
          )
        } else {
          @minimoon.nothing()
        },
      ],
    )
  })
}

///|
pub fn disclosure(
  spec : DisclosureSpec,
  initially_expanded? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (expanded, update_expanded) = @minimoon.create_variable(
    initially_expanded,
  )
  disclosure_controlled(
    spec,
    expanded~,
    on_change=update_expanded.map(value => _ => value),
  )
}
