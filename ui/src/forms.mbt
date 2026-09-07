///|
/// Controlled native controls adapted from RUI 0.1.1 (MIT). No validation engine.
pub(all) struct ChoiceOption {
  key : String
  label : String
  disabled : Bool
  group : String
} derive(Eq, Debug)

///|
pub fn choice_option(
  key~ : String,
  label~ : String,
  disabled? : Bool = false,
  group? : String = "",
) -> ChoiceOption {
  guard key != "" else { abort("choice key must not be empty") }
  { key, label, disabled, group, }
}

///|
fn validate_choices(options : Array[ChoiceOption]) -> Unit {
  let seen : Map[String, Bool] = Map([])
  for option in options {
    guard option.key != "" && !seen.contains(option.key) else {
      abort("choice keys must be unique and nonempty")
    }
    seen[option.key] = true
  }
}

///|
pub struct FieldState {
  id : String
  label : String
  description : String
  error : String
  required : Bool
  disabled : Bool
} derive(Eq, Debug)

///|
pub fn field_state(
  id~ : String,
  label~ : String,
  description? : String = "",
  error? : String = "",
  required? : Bool = false,
  disabled? : Bool = false,
) -> FieldState {
  guard id != "" else { abort("field id must not be empty") }
  { id, label, description, error, required, disabled, }
}

///|
pub fn FieldState::semantics(
  self : FieldState,
  role? : @minimoon.SemanticRole = @minimoon.TextboxRole,
) -> @minimoon.Semantics {
  @minimoon.semantics(
    role~,
    label=self.label,
    labelled_by=self.id + "-label",
    described_by=self.id +
      (if self.error != "" { "-error" } else { "-description" }),
    required=self.required,
    invalid=self.error != "",
    disabled=self.disabled,
  )
}

///|
pub fn[C : @minimoon.IsChildren] field(
  state : FieldState,
  orientation? : Orientation = Vertical,
  children : C,
) -> @minimoon.Node {
  ui_container(
    "field",
    [
      @minimoon.label(
        for_id=state.id,
        id=state.id + "-label",
        class="mmui-field-label",
        state.label + (if state.required { " *" } else { "" }),
      ),
      ui_container("field-content", children.to_nodes()),
      field_description(id=state.id + "-description", state.description),
      if state.error == "" {
        @minimoon.nothing()
      } else {
        field_error(id=state.id + "-error", state.error)
      },
    ],
    class=orientation_class(orientation),
  )
}

///|
pub fn[Input : Eq] field_with_input(
  state : @minimoon.Val[FieldState],
  input : @minimoon.Val[Input],
  render : (FieldState, Input) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  @minimoon.Val::map2(state, input, (field_state, value) => {
    field(field_state, render(field_state, value))
  })
}

///|
pub fn[C : @minimoon.IsChildren] field_label(
  for_id~ : String,
  children : C,
) -> @minimoon.Node {
  label(for_id~, children)
}

///|
pub fn[C : @minimoon.IsChildren] form(
  on_submit~ : @minimoon.Emit[Map[String, Json]],
  on_reset? : @minimoon.Cmd,
  values? : Map[String, Json] = Map([]),
  submit_key? : String = "",
  reset_key? : String = "",
  id? : String = "",
  children : C,
) -> @minimoon.Node {
  @minimoon.form(
    on_submit=@minimoon.Emit(native_values => {
      let combined = native_values.copy()
      for name, value in values {
        combined[name] = value
      }
      on_submit(combined)
    }),
    on_reset?,
    submit_key~,
    reset_key~,
    id~,
    class="mmui-form",
    children,
  )
}

///|
pub fn[C : @minimoon.IsChildren] form_field(
  state : FieldState,
  children : C,
) -> @minimoon.Node {
  field(state, children)
}

///|
pub fn[C : @minimoon.IsChildren] form_label(
  for_id~ : String,
  children : C,
) -> @minimoon.Node {
  label(for_id~, children)
}
