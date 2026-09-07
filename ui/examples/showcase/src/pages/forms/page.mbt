///|
pub fn program() -> @minimoon.Page {
  @gallery.page("forms", "表单与选择 / Forms — 14 components + Form", context => {
    let options = @minimoon.Val::constant([
      @ui.choice_option(key="moonbit", label="MoonBit"),
      @ui.choice_option(key="skyline", label="Skyline"),
      @ui.choice_option(key="disabled", label="Disabled", disabled=true),
    ])
    let (submitted, update_submitted) = @minimoon.create_variable(
      "Not submitted",
    )
    let field = @ui.field_state(
      id="forms-field",
      label="Project name",
      description="Application-owned validation",
      error="Please supply a name",
      required=true,
    )
    @ui.stack([
      @gallery.sample(
        "Checkbox",
        @ui.checkbox(id="forms-checkbox", label="Accept terms"),
      ),
      @gallery.sample(
        "Field",
        @ui.input(id="forms-field").map(input => @ui.field(field, input)),
      ),
      @gallery.sample(
        "Input",
        @ui.input(
          id="forms-input",
          options=@ui.input_options(placeholder="Type or paste text"),
        ),
      ),
      @gallery.sample(
        "Input Group",
        @ui.input(id="forms-group-input").map(input => {
          @ui.input_group([
            @ui.input_group_addon("https://"),
            @ui.input_group_control(input),
            @ui.input_group_text(".app"),
          ])
        }),
      ),
      @gallery.sample(
        "Input OTP",
        @ui.input_otp(
          id="forms-otp",
          on_complete=update_submitted.map(code => _ => "OTP complete: " + code),
        ),
      ),
      @gallery.sample(
        "Native Select",
        @ui.native_select(
          id="forms-native-select",
          options~,
          initial_value="moonbit",
        ),
      ),
      @gallery.display(
        "Progress",
        @minimoon.div([
          @ui.progress_label("Migration progress"),
          @ui.progress(value=64.0),
          @ui.progress_value(value=64.0),
        ]),
      ),
      @gallery.sample(
        "Radio Group",
        @ui.radio_group(id="forms-radio", options~, initial_value="moonbit"),
      ),
      @gallery.sample(
        "Select",
        @ui.select(
          context,
          id="forms-select",
          options~,
          initial_value="skyline",
        ),
      ),
      @gallery.sample(
        "Slider",
        @ui.stack([
          @ui.slider(context, id="forms-slider", default_value=25),
          @ui.slider_values(context, id="forms-range", default_values=[20, 80]),
          @ui.slider_values(
            context,
            id="forms-vertical-range",
            default_values=[20, 80],
            orientation=@ui.Vertical,
          ),
          @ui.slider_values(
            context,
            id="forms-rtl-range",
            default_values=[20, 80],
            direction=@theme.Rtl,
          ),
        ]),
      ),
      @gallery.sample(
        "Switch",
        @ui.switch(id="forms-switch", label="Notifications"),
      ),
      @gallery.sample(
        "Textarea",
        @ui.textarea(
          id="forms-textarea",
          options=@ui.input_options(placeholder="Multiple lines"),
        ),
      ),
      @gallery.sample(
        "Toggle",
        @ui.toggle(
          id="forms-toggle",
          content=@gallery.constant(@ui.typography_large("B")),
        ),
      ),
      @gallery.sample(
        "Toggle Group",
        @ui.toggle_group(id="forms-toggles", options~, multiple=true),
      ),
      @gallery.sample(
        "Form",
        submitted.map(status => {
          @ui.form(
            id="forms-submit",
            on_submit=update_submitted.map(_ => _ => "Submitted"),
            [
              @ui.form_description(
                "The app supplies validation and submission state.",
              ),
              @minimoon.button_children(
                form_type=@minimoon.SubmitForm,
                on_tap=@minimoon.none,
                "Submit",
              ),
              @ui.form_message(status),
            ],
          )
        }),
      ),
    ])
  })
}
