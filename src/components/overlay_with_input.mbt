///|
struct DialogSpecWithInput[Input] {
  id : String
  title : String
  description : String
  trigger_label : String
  close_label : String
  content : (@minimoon.Cmd, Input) -> @minimoon.Node
  disabled : Bool
  close_on_overlay : Bool
  root_class : String
  trigger_class : String
  overlay_class : String
  surface_class : String
  title_class : String
  description_class : String
  close_class : String
}

///|
pub fn[Input] dialog_spec_with_input(
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : (@minimoon.Cmd, Input) -> @minimoon.Node,
  description? : String = "",
  close_label? : String = "Close",
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
  root_class? : String = "",
  trigger_class? : String = "",
  overlay_class? : String = "",
  surface_class? : String = "",
  title_class? : String = "",
  description_class? : String = "",
  close_class? : String = "",
) -> DialogSpecWithInput[Input] {
  guard id != "" else { abort("dialog id must not be empty") }
  guard title != "" else { abort("dialog title must not be empty") }
  guard trigger_label != "" else {
    abort("dialog trigger label must not be empty")
  }
  guard close_label != "" else { abort("dialog close label must not be empty") }
  {
    id,
    title,
    description,
    trigger_label,
    close_label,
    content,
    disabled,
    close_on_overlay,
    root_class,
    trigger_class,
    overlay_class,
    surface_class,
    title_class,
    description_class,
    close_class,
  }
}

///|
fn[Input] modal_layer_with_input(
  id : String,
  title : String,
  description : String,
  close_label : String,
  content : (@minimoon.Cmd, Input) -> @minimoon.Node,
  input : Input,
  close : @minimoon.Cmd,
  close_on_overlay : Bool,
  overlay_class : String,
  surface_class : String,
  title_class : String,
  description_class : String,
  close_class : String,
  section : String,
) -> @minimoon.Node {
  let title_id = id + "-title"
  let description_id = if description == "" { "" } else { id + "-description" }
  let overlay = if close_on_overlay {
    @minimoon.tap_view(
      on_tap=close,
      event_key=id + "/overlay/close",
      class=overlay_class,
      data_section=section + "-overlay",
      @minimoon.nothing(),
    )
  } else {
    @minimoon.div(
      class=overlay_class,
      data_section=section + "-overlay",
      @minimoon.nothing(),
    )
  }
  @minimoon.fragment([
    overlay,
    @minimoon.div(
      id=id + "-surface",
      class=surface_class,
      data_section=section + "-surface",
      semantics=@minimoon.semantics(
        role=@minimoon.DialogRole,
        modal=true,
        labelled_by=title_id,
        described_by=description_id,
      ),
      [
        @minimoon.h1(
          id=title_id,
          class=title_class,
          semantics=@minimoon.semantics(role=@minimoon.HeadingRole),
          title,
        ),
        if description == "" {
          @minimoon.nothing()
        } else {
          @minimoon.p(id=description_id, class=description_class, description)
        },
        content(close, input),
        @minimoon.button(
          on_tap=close,
          event_key=id + "/close",
          class=close_class,
          close_label,
        ),
      ],
    ),
  ])
}

///|
fn[Input : Eq] modal_controlled_with_input(
  spec : DialogSpecWithInput[Input],
  section : String,
  input~ : @minimoon.Val[Input],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  open.view2(input, (is_open, value) => {
    let surface_id = spec.id + "-surface"
    @minimoon.div(id=spec.id, class=spec.root_class, data_section=section, [
      @minimoon.button(
        on_tap=if spec.disabled { @minimoon.none } else { on_change(true) },
        event_key=spec.id + "/open",
        class=spec.trigger_class,
        disabled=spec.disabled,
        semantics=@minimoon.semantics(
          role=@minimoon.ButtonRole,
          expanded=is_open,
          disabled=spec.disabled,
          controls=surface_id,
          has_popup="dialog",
        ),
        spec.trigger_label,
      ),
      if is_open {
        modal_layer_with_input(
          spec.id,
          spec.title,
          spec.description,
          spec.close_label,
          spec.content,
          value,
          on_change(false),
          spec.close_on_overlay,
          spec.overlay_class,
          spec.surface_class,
          spec.title_class,
          spec.description_class,
          spec.close_class,
          section,
        )
      } else {
        @minimoon.nothing()
      },
    ])
  })
}

///|
pub fn[Input : Eq] dialog_controlled_with_input(
  spec : DialogSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  modal_controlled_with_input(spec, "dialog", input~, open~, on_change~)
}

///|
pub fn[Input : Eq] dialog_with_input(
  spec : DialogSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, update_open) = @minimoon.create_variable(initially_open)
  dialog_controlled_with_input(
    spec,
    input~,
    open~,
    on_change=update_open.map(value => _ => value),
  )
}

///|
struct SheetSpecWithInput[Input] {
  dialog : DialogSpecWithInput[Input]
}

///|
pub fn[Input] sheet_spec_with_input(
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  content~ : (@minimoon.Cmd, Input) -> @minimoon.Node,
  side? : SheetSide = Right,
  description? : String = "",
  close_label? : String = "Close",
  disabled? : Bool = false,
  close_on_overlay? : Bool = true,
  root_class? : String = "",
  trigger_class? : String = "",
  overlay_class? : String = "",
  surface_class? : String = "",
  title_class? : String = "",
  description_class? : String = "",
  close_class? : String = "",
) -> SheetSpecWithInput[Input] {
  let dialog = dialog_spec_with_input(
    id~,
    title~,
    trigger_label~,
    content~,
    description~,
    close_label~,
    disabled~,
    close_on_overlay~,
    root_class~,
    trigger_class~,
    overlay_class~,
    surface_class=joined_class(surface_class, side.class_name()),
    title_class~,
    description_class~,
    close_class~,
  )
  { dialog, }
}

///|
pub fn[Input : Eq] sheet_controlled_with_input(
  spec : SheetSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  open~ : @minimoon.Val[Bool],
  on_change~ : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  modal_controlled_with_input(spec.dialog, "sheet", input~, open~, on_change~)
}

///|
pub fn[Input : Eq] sheet_with_input(
  spec : SheetSpecWithInput[Input],
  input~ : @minimoon.Val[Input],
  initially_open? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (open, update_open) = @minimoon.create_variable(initially_open)
  sheet_controlled_with_input(
    spec,
    input~,
    open~,
    on_change=update_open.map(value => _ => value),
  )
}
