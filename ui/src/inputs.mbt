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
/// Pure controlled input, following RUI's input/on_input authoring convention.
/// `focused` controls the focus style; `options.focus` requests native focus.
/// No state is allocated here, so this builder is safe inside a Val view.
pub fn input(
  id~ : String,
  value~ : String,
  on_input~ : @minimoon.Emit[String],
  options? : InputOptions = input_options(),
  focused? : Bool = false,
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.InputBlurDetail],
) -> @minimoon.Node {
  @minimoon.input(
    id~,
    event_key=id + "/input",
    class="mmui-input " +
      (if focused { "mmui-focused " } else { "" }) +
      (if options.read_only { "mmui-readonly " } else { "" }) +
      (if options.invalid { "mmui-invalid" } else { "" }),
    value~,
    on_input=if options.disabled || options.read_only {
      @minimoon.Emit(_ => @minimoon.none)
    } else {
      on_input
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
    on_focus?,
    on_blur?,
  )
}

///|
/// A convenience input that owns its value and focus for this component lifetime.
pub fn input_stateful(
  id~ : String,
  initial_value? : String = "",
  options? : InputOptions = input_options(),
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.InputBlurDetail],
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  input_with_focus(
    id~,
    value~,
    on_input=update.map(value => _ => value),
    options~,
    on_confirm?,
    semantics?,
    on_focus?,
    on_blur?,
  )
}

///|
/// Pure controlled textarea; native focus/blur details remain typed.
pub fn textarea(
  id~ : String,
  value~ : String,
  on_input~ : @minimoon.Emit[String],
  options? : InputOptions = input_options(),
  focused? : Bool = false,
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.TextareaBlurDetail],
) -> @minimoon.Node {
  @minimoon.textarea(
    id~,
    input_key=id + "/input",
    class="mmui-textarea " +
      (if focused { "mmui-focused " } else { "" }) +
      (if options.read_only { "mmui-readonly " } else { "" }) +
      (if options.invalid { "mmui-invalid" } else { "" }),
    value~,
    on_input=if options.disabled || options.read_only {
      @minimoon.Emit(_ => @minimoon.none)
    } else {
      on_input
    },
    maxlength=options.maxlength,
    placeholder=options.placeholder,
    name=options.name,
    disabled=options.disabled || options.read_only,
    focus=options.focus,
    on_confirm?,
    semantics?,
    on_focus?,
    on_blur?,
  )
}

///|
/// A convenience textarea that owns its value and native focus state.
pub fn textarea_stateful(
  id~ : String,
  initial_value? : String = "",
  options? : InputOptions = input_options(),
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.TextareaBlurDetail],
) -> @minimoon.Val[@minimoon.Node] {
  let (value, update) = @minimoon.create_variable(initial_value)
  textarea_with_focus(
    id~,
    value~,
    on_input=update.map(value => _ => value),
    options~,
    on_confirm?,
    semantics?,
    on_focus?,
    on_blur?,
  )
}

///|
fn[T] input_focus_event(
  focused : Bool,
  update : @minimoon.Emit[(Bool) -> Bool],
  callback : @minimoon.Emit[T]?,
) -> @minimoon.Emit[T] {
  @minimoon.Emit(detail => {
    @minimoon.batch([
      update(_ => focused),
      callback.map(emit => emit(detail)).unwrap_or(@minimoon.none),
    ])
  })
}

///|
fn input_with_focus(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_input~ : @minimoon.Emit[String],
  options~ : InputOptions,
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.InputBlurDetail],
) -> @minimoon.Val[@minimoon.Node] {
  let (focused, update_focus) = @minimoon.create_variable(false)
  @minimoon.Val::view2(value, focused, (value, focused) => {
    input(
      id~,
      value~,
      on_input~,
      options~,
      focused~,
      on_confirm?,
      semantics?,
      on_focus=input_focus_event(true, update_focus, on_focus),
      on_blur=input_focus_event(false, update_focus, on_blur),
    )
  })
}

///|
fn textarea_with_focus(
  id~ : String,
  value~ : @minimoon.Val[String],
  on_input~ : @minimoon.Emit[String],
  options~ : InputOptions,
  on_confirm? : @minimoon.Emit[String],
  semantics? : @minimoon.Semantics,
  on_focus? : @minimoon.Emit[@minimoon.FocusDetail],
  on_blur? : @minimoon.Emit[@minimoon.TextareaBlurDetail],
) -> @minimoon.Val[@minimoon.Node] {
  let (focused, update_focus) = @minimoon.create_variable(false)
  @minimoon.Val::view2(value, focused, (value, focused) => {
    textarea(
      id~,
      value~,
      on_input~,
      options~,
      focused~,
      on_confirm?,
      semantics?,
      on_focus=input_focus_event(true, update_focus, on_focus),
      on_blur=input_focus_event(false, update_focus, on_blur),
    )
  })
}
