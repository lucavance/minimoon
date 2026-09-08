///|
pub fn program() -> @minimoon.Page {
  @gallery.page(
    "forms",
    "表单与选择 / Forms — 14 components + Form",
    context => {
      let options = @minimoon.Val::constant([
        @ui.choice_option(key="moonbit", label="MoonBit"),
        @ui.choice_option(key="skyline", label="Skyline"),
        @ui.choice_option(key="disabled", label="Disabled", disabled=true),
      ])
      let (otp_status, update_otp_status) = @minimoon.create_variable("")
      let otp = @ui.input_otp(
        id="forms-otp",
        on_complete=update_otp_status.map(code => _ => "OTP complete: " + code),
      )
      @ui.stack([
        @gallery.sample(
          "Checkbox",
          @ui.checkbox(id="forms-checkbox", label="Accept terms"),
        ),
        @gallery.sample(
          "Input",
          @ui.input_stateful(
            id="forms-input",
            options=@ui.input_options(placeholder="Type or paste text"),
          ),
        ),
        @gallery.sample(
          "Input Group",
          @ui.input_stateful(id="forms-group-input").map(input => {
            @ui.input_group([
              @ui.input_group_addon("https://"),
              @ui.input_group_control(input),
              @ui.input_group_text(".app"),
            ])
          }),
        ),
        @gallery.sample(
          "Input OTP",
          @minimoon.Val::view2(otp, otp_status, (otp, status) => {
            @minimoon.div([otp, @ui.typography_small(status)])
          }),
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
          @ui.textarea_stateful(
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
        @gallery.sample("Form", editor()),
      ])
    },
    capabilities=[@minimoon.Request],
  )
}
