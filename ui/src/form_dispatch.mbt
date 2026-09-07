///|
/// Event batches decode handlers before dispatching any command. Keep only the
/// semantic request in the handler and read reactive input at reducer time.
fn[Input : Eq, Message] form_dispatch(
  input : @minimoon.Val[Input],
  dispatch : (Input, Message) -> @minimoon.Cmd,
) -> @minimoon.Emit[Message] {
  let (_, emit) = @minimoon.create_state_with_input(
    input~,
    init=(_, _) => @minimoon.no_cmd(()),
    update=(_, input, message, _) => ((), dispatch(input, message)),
  )
  emit
}

///|
fn normalize_toggle_keys(
  options : Array[ChoiceOption],
  keys : Array[String],
  multiple : Bool,
) -> Array[String] {
  let normalized : Array[String] = []
  for key in keys {
    if !normalized.contains(key) &&
      options.any(option => option.key == key) &&
      (multiple || normalized.is_empty()) {
      normalized.push(key)
    }
  }
  normalized
}
