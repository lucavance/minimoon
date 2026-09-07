///|
priv enum ComboboxIntent {
  Choose(String)
  Remove(String)
  SetQuery(String)
  SetOpen(Bool)
  Clear
}

///|
/// Decode gestures as intentions, then read controlled inputs at dispatch time.
/// A host batch may have decoded several gestures from the same rendered frame.
fn combobox_dispatch(
  context : UiContext,
  options : @minimoon.Val[Array[ChoiceOption]],
  state : @minimoon.Val[ComboboxState],
  on_change : @minimoon.Emit[ComboboxState],
  multiple~ : Bool,
  disabled~ : Bool,
  on_query_change? : @minimoon.Emit[String],
  on_values_change? : @minimoon.Emit[Array[String]],
  on_open_change? : @minimoon.Emit[Bool],
) -> @minimoon.Emit[ComboboxIntent] {
  let (_, emit) = @minimoon.create_state_with_input(
    input=@minimoon.Val::map2(options, state, (options, state) => {
      (options, state)
    }),
    init=(_, _) => @minimoon.no_cmd(()),
    update=(_, input, intent : ComboboxIntent, _) => {
      let (options, state) = input
      if disabled && !(intent is SetOpen(false)) {
        return @minimoon.no_cmd(())
      }
      let next = match intent {
        SetOpen(open) => { ..state, open, }
        SetQuery(query) => { ..state, query, }
        Clear => { ..state, values: [], query: "", }
        Remove(key) =>
          { ..state, values: state.values.filter(value => value != key), }
        Choose(key) => {
          guard state.open &&
            options.any(option => option.key == key && !option.disabled) else {
            return @minimoon.no_cmd(())
          }
          let values = if !multiple {
            [key]
          } else if state.values.contains(key) {
            state.values.filter(value => value != key)
          } else {
            let next = state.values.copy()
            next.push(key)
            next
          }
          { ..state, values, open: multiple, }
        }
      }
      (
        (),
        @minimoon.batch([
          on_change(next),
          if next.query != state.query {
            on_query_change
            .map(emit => emit(next.query))
            .unwrap_or(@minimoon.none)
          } else {
            @minimoon.none
          },
          if next.values != state.values {
            on_values_change
            .map(emit => emit(next.values))
            .unwrap_or(@minimoon.none)
          } else {
            @minimoon.none
          },
          if next.open != state.open {
            on_open_change
            .map(emit => emit(next.open))
            .unwrap_or(@minimoon.none)
          } else {
            @minimoon.none
          },
        ]),
      )
    },
    subscriptions=(_, _, emit) => context.page.on_hide(emit(SetOpen(false))),
  )
  emit
}
