///|
/// One native input owns IME, paste and focus; visible slots do not invent key events.
pub struct OtpScope {
  value : String
  length : Int
  active_index : Int
  disabled : Bool
  invalid : Bool
} derive(Eq, Debug)

///|
pub fn input_otp_slot(
  value? : String = "",
  active? : Bool = false,
  id? : String = "",
) -> @minimoon.Node {
  ui_container(
    "input-otp-slot",
    [@minimoon.text(value)],
    id~,
    class=if active { "mmui-active" } else { "" },
  )
}

///|
pub fn input_otp_controlled(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  length? : Int = 6,
  disabled? : Bool = false,
  numeric? : Bool = true,
  separator_after? : Int = -1,
  invalid? : Bool = false,
  label? : String = "Verification code",
  accept? : (Char) -> Bool,
  render? : (OtpScope) -> @minimoon.Node,
  on_complete? : @minimoon.Emit[String],
) -> @minimoon.Val[@minimoon.Node] {
  guard length > 0 && length <= 64 else {
    abort("OTP length must be between 1 and 64")
  }
  let send = form_dispatch(value, (previous, text : String) => {
    if disabled {
      return @minimoon.none
    }
    let normalized = normalize_otp(text, length, numeric, accept)
    let complete = if normalized.iter().count() == length &&
      normalize_otp(previous, length, numeric, accept).iter().count() != length {
      on_complete.map(emit => emit(normalized)).unwrap_or(@minimoon.none)
    } else {
      @minimoon.none
    }
    @minimoon.batch([on_change(normalized), complete])
  })
  value.map(previous => {
    let value = normalize_otp(previous, length, numeric, accept)
    let slots : Array[@minimoon.Node] = []
    let chars = value.iter().collect()
    for index = 0; index < length; index = index + 1 {
      if index == separator_after && index > 0 {
        slots.push(input_otp_separator())
      }
      slots.push(
        input_otp_slot(
          value=if index < chars.length() {
            chars[index].to_string()
          } else {
            ""
          },
          active=index == chars.length(),
        ),
      )
    }
    ui_container(
      "input-otp",
      [
        match render {
          Some(render) =>
            render({
              value,
              length,
              active_index: chars.length(),
              disabled,
              invalid,
            })
          None => input_otp_group(slots)
        },
        @minimoon.input(
          id=id + "-input",
          event_key=id + "/input",
          value~,
          on_input=send,
          disabled~,
          maxlength=length,
          input_type=if numeric {
            @minimoon.NumberInput
          } else {
            @minimoon.TextInput
          },
          class="mmui-input-otp-native",
          semantics=@minimoon.semantics(
            role=@minimoon.TextboxRole,
            label~,
            disabled~,
            invalid~,
          ),
        ),
      ],
      id~,
    )
  })
}

///|
pub fn input_otp(
  id~ : String,
  initial_value? : String = "",
  length? : Int = 6,
  disabled? : Bool = false,
  numeric? : Bool = true,
  separator_after? : Int = -1,
  invalid? : Bool = false,
  label? : String = "Verification code",
  accept? : (Char) -> Bool,
  render? : (OtpScope) -> @minimoon.Node,
  on_complete? : @minimoon.Emit[String],
) -> @minimoon.Val[@minimoon.Node] {
  let (value, emit) = @minimoon.create_variable(initial_value)
  input_otp_controlled(
    id~,
    value~,
    on_change=emit.map(value => _ => value),
    length~,
    disabled~,
    numeric~,
    separator_after~,
    invalid~,
    label~,
    accept?,
    render?,
    on_complete?,
  )
}

///|
fn normalize_otp(
  value : String,
  length : Int,
  numeric : Bool,
  accept : ((Char) -> Bool)?,
) -> String {
  String::from_iter(
    value
    .iter()
    .filter(character => {
      (!numeric || (character >= '0' && character <= '9')) &&
      accept.map(predicate => predicate(character)).unwrap_or(true)
    })
    .take(length),
  )
}
