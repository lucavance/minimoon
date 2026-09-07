///|
pub(all) enum CheckState {
  Unchecked
  Checked
  Indeterminate
} derive(Eq, Debug)

///|
pub fn checkbox_state_controlled(
  name? : String = "",
  id~ : String,
  state~ : @minimoon.Val[CheckState],
  on_change~ : @minimoon.Emit[CheckState],
  label? : String = "",
  disabled? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  state.map(state => {
    @minimoon.checkbox_group(
      name~,
      id~,
      class="mmui-checkbox" + (if invalid { " mmui-invalid" } else { "" }),
      event_key=id + "/change",
      on_change=@minimoon.Emit(values => {
        if disabled || read_only {
          @minimoon.none
        } else {
          on_change(if values.contains(id) { Checked } else { Unchecked })
        }
      }),
      [
        @minimoon.checkbox(
          value=id,
          checked=state == Checked,
          disabled=disabled || read_only,
          id=id + "-control",
          label,
        ),
        if state == Indeterminate {
          @minimoon.span(
            class="mmui-checkbox-mixed",
            semantics=@minimoon.semantics(label="Mixed selection"),
            "−",
          )
        } else {
          @minimoon.nothing()
        },
      ],
    )
  })
}

///|
pub fn checkbox_state(
  name? : String = "",
  id~ : String,
  initial? : CheckState = Unchecked,
  label? : String = "",
  disabled? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (state, update) = @minimoon.create_variable(initial)
  checkbox_state_controlled(
    name~,
    id~,
    state~,
    on_change=update.map(value => _ => value),
    label~,
    disabled~,
    read_only~,
    invalid~,
  )
}
