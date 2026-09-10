///|
priv struct Draft {
  title : String
} derive(ToJson, @json.FromJson)

///|
priv struct Echo {
  json : Draft
} derive(@json.FromJson)

///|
priv struct Model {
  title : String
  busy : Bool
  request_epoch : Int
  status : String
} derive(Eq)

///|
priv enum Msg {
  NameChanged(String)
  Submit
  Saved(Int, Result[Echo, Error])
  Reset
}

///|
fn initial_model(epoch : Int) -> Model {
  {
    title: "",
    busy: false,
    request_epoch: epoch,
    status: "Echo demo only — no data is persisted.",
  }
}

///|
fn validation_error(title : String) -> String {
  if title.trim().iter().count() < 3 {
    "Please enter at least three characters"
  } else {
    ""
  }
}

///|
fn update(
  model : Model,
  message : Msg,
  emit : @minimoon.Emit[Msg],
) -> (Model, @minimoon.Cmd) {
  match message {
    NameChanged(title) => {
      if model.busy {
        return @minimoon.no_cmd(model)
      }
      @minimoon.no_cmd({
        ..model,
        title,
        status: "Echo demo only — no data is persisted.",
      })
    }
    Submit => {
      if model.busy {
        return @minimoon.no_cmd(model)
      }
      if validation_error(model.title) != "" {
        return @minimoon.no_cmd({
          ..model,
          status: "Invalid draft — no request was sent.",
        })
      }
      let epoch = model.request_epoch + 1
      (
        {
          ..model,
          busy: true,
          request_epoch: epoch,
          status: "Sending echo request…",
        },
        @http.post("https://echo.apifox.com/post", timeout_ms=10000)
        .with_json(Draft::{ title: model.title.trim().to_owned(), })
        .expect_json(emit.map(result => Saved(epoch, result))),
      )
    }
    Saved(epoch, result) => {
      if !model.busy || epoch != model.request_epoch {
        return @minimoon.no_cmd(model)
      }
      let status = match result {
        Ok(response) =>
          "Echo title: " + response.json.title + " — not persisted."
        Err(error) => "Echo request failed: " + error.to_string()
      }
      @minimoon.no_cmd({ ..model, busy: false, status, })
    }
    Reset => @minimoon.no_cmd(initial_model(model.request_epoch + 1))
  }
}

///|
/// Build state once; submit observes the reducer's latest title even when native
/// input and submit events arrive in the same host batch. Reset invalidates old
/// replies without pretending to persist the echo response.
fn editor() -> @minimoon.Val[@minimoon.Node] {
  let (model, emit) = @minimoon.create_state(initial_model(0), update~)
  let state = model.map(model => {
    @ui.field_state(
      id="forms-field",
      label="Project name",
      description="At least three characters; sends a non-sensitive title to public echo.apifox.com",
      error=validation_error(model.title),
      required=true,
      disabled=model.busy,
    )
  })
  let options = model.map(model => {
    @ui.input_options(name="project_name", disabled=model.busy)
  })
  let field = @gallery.sample(
    "Field",
    @ui.text_field(
      state,
      model.map(model => model.title),
      emit.map(value => NameChanged(value)),
      options~,
    ),
  )
  @minimoon.Val::view2(model, field, (model, field) => {
    @ui.form(
      id="forms-submit",
      submit_key="forms/submit",
      reset_key="forms/reset",
      on_submit=emit.map(_ => Submit),
      on_reset=emit(Reset),
      [
        @ui.form_description(
          "Typed JSON echo round trip; this is not a persistent save.",
        ),
        field,
        @minimoon.button_children(
          id="forms-send",
          form_type=@minimoon.SubmitForm,
          disabled=model.busy,
          on_tap=@minimoon.none,
          if model.busy {
            "Sending…"
          } else {
            "Send echo"
          },
        ),
        @minimoon.button_children(
          id="forms-reset",
          form_type=@minimoon.ResetForm,
          on_tap=@minimoon.none,
          "Reset",
        ),
        @minimoon.div(id="forms-status", @ui.form_message(model.status)),
      ],
    )
  })
}
