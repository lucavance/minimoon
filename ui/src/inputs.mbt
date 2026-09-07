///|
pub struct InputOptions {
  disabled : Bool
  read_only : Bool
  invalid : Bool
  placeholder : String
  maxlength : Int
  input_type : @minimoon.InputType
  password : Bool
  focus : Bool
  name : String
  selection_start : Int?
  selection_end : Int?
} derive(Eq, Debug)

///|
pub fn input_options(
  disabled? : Bool = false,
  read_only? : Bool = false,
  invalid? : Bool = false,
  placeholder? : String = "",
  maxlength? : Int = 140,
  input_type? : @minimoon.InputType = @minimoon.TextInput,
  password? : Bool = false,
  focus? : Bool = false,
  name? : String = "",
  selection_start? : Int,
  selection_end? : Int,
) -> InputOptions {
  guard maxlength >= -1 else { abort("maxlength must be -1 or nonnegative") }
  {
    disabled,
    read_only,
    invalid,
    placeholder,
    maxlength,
    input_type,
    password,
    focus,
    name,
    selection_start,
    selection_end,
  }
}

///|
pub fn input_controlled(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  options? : InputOptions = input_options(),
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.InputBlurDetail],
) -> @minimoon.Val[@minimoon.Node] {
  let (focused, set_focused) = @minimoon.create_variable(false)
  @minimoon.Val::map2(value, focused, (text, focused) => {
    @minimoon.input(
      id~,
      event_key=id + "/input",
      class="mmui-input " +
        (if focused { "mmui-focused " } else { "" }) +
        (if options.read_only { "mmui-readonly " } else { "" }) +
        (if options.invalid { "mmui-invalid" } else { "" }),
      value=text,
      on_input=if options.disabled || options.read_only {
        @minimoon.Emit(_ => @minimoon.none)
      } else {
        on_change
      },
      input_type=options.input_type,
      maxlength=options.maxlength,
      password=options.password,
      placeholder=options.placeholder,
      name=options.name,
      disabled=options.disabled || options.read_only,
      selection_start?=options.selection_start,
      selection_end?=options.selection_end,
      focus=options.focus,
      on_confirm?,
      semantics?,
      on_focus=@minimoon.Emit(detail => {
        @minimoon.batch([
          set_focused(_ => true),
          on_focus.map(emit => emit(detail)).unwrap_or(@minimoon.none),
        ])
      }),
      on_blur=@minimoon.Emit(detail => {
        @minimoon.batch([
          set_focused(_ => false),
          on_blur.map(emit => emit(detail)).unwrap_or(@minimoon.none),
        ])
      }),
    )
  })
}

///|
pub fn input(
  id~ : String,
  initial_value? : String = "",
  options? : InputOptions = input_options(),
  on_confirm? : @minimoon.Emit[String],
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  input_controlled(
    id~,
    value~,
    on_change=update.map(value => _ => value),
    options~,
    on_confirm?,
  )
}

///|
pub fn textarea_controlled(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_change~ : @minimoon.Emit[String],
  options? : InputOptions = input_options(),
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.TextareaBlurDetail],
) -> @minimoon.Val[@minimoon.Node] {
  let (focused, set_focused) = @minimoon.create_variable(false)
  @minimoon.Val::map2(value, focused, (text, focused) => {
    @minimoon.textarea(
      id~,
      input_key=id + "/input",
      class="mmui-textarea " +
        (if focused { "mmui-focused " } else { "" }) +
        (if options.read_only { "mmui-readonly " } else { "" }) +
        (if options.invalid { "mmui-invalid" } else { "" }),
      value=text,
      on_input=if options.disabled || options.read_only {
        @minimoon.Emit(_ => @minimoon.none)
      } else {
        on_change
      },
      maxlength=options.maxlength,
      placeholder=options.placeholder,
      name=options.name,
      disabled=options.disabled || options.read_only,
      focus=options.focus,
      on_confirm?,
      semantics?,
      on_focus=@minimoon.Emit(detail => {
        @minimoon.batch([
          set_focused(_ => true),
          on_focus.map(emit => emit(detail)).unwrap_or(@minimoon.none),
        ])
      }),
      on_blur=@minimoon.Emit(detail => {
        @minimoon.batch([
          set_focused(_ => false),
          on_blur.map(emit => emit(detail)).unwrap_or(@minimoon.none),
        ])
      }),
    )
  })
}

///|
pub fn textarea(
  id~ : String,
  initial_value? : String = "",
  options? : InputOptions = input_options(),
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  textarea_controlled(
    id~,
    value~,
    on_change=update.map(value => _ => value),
    options~,
  )
}
