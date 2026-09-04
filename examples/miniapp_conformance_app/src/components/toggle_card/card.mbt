///|
pub struct Model {
  enabled : Bool
  note : String
  pulses : Int
} derive(Eq)

///|
pub struct Props {
  id : String
  title : String
  pulse_step : Int
  tone : String
} derive(Eq)

///|
pub(all) enum Msg {
  EnabledChanged(Bool)
  NoteChanged(String)
  Pulse
}

///|
pub fn initial_model() -> Model {
  { enabled: false, note: "render-scoped", pulses: 0, }
}

///|
pub fn props(
  id~ : String,
  title~ : String,
  pulse_step~ : Int,
  tone~ : String,
) -> Props {
  { id, title, pulse_step, tone, }
}

///|
pub fn update_model(model : Model, props : Props, msg : Msg) -> Model {
  match msg {
    EnabledChanged(enabled) => { ..model, enabled, }
    NoteChanged(note) => { ..model, note, }
    Pulse => { ..model, pulses: model.pulses + props.pulse_step, }
  }
}

///|
pub fn card(
  context : @minimoon.PageContext,
  scope_key : String,
  input : @minimoon.Val[Props],
) -> @minimoon.Val[@minimoon.Node] {
  let event_scope = "$component:toggle-card:cards:" + scope_key
  let (model, emit) = @minimoon.create_state_with_input(
    input~,
    init=(_, _) => @minimoon.no_cmd(initial_model()),
    update=(current, props, message, _) => {
      @minimoon.no_cmd(update_model(current, props, message))
    },
    subscriptions=(current, _props, emit) => {
      if current.enabled {
        context.every(
          key=event_scope + "/pulse",
          interval_ms=1000,
          command=emit(Pulse),
        )
      } else {
        @minimoon.Sub::none()
      }
    },
  )
  input.view2(model, (props, current) => {
    @minimoon.div(
      class="mt-[16rpx] rounded-[12rpx] border px-[20rpx] py-[16rpx] " +
        props.tone,
      data_section="component-card",
      [
        @minimoon.h1(class="text-[28rpx] font-semibold", props.title),
        @minimoon.switch(
          id=props.id + "-enabled",
          checked=current.enabled,
          on_change=emit.map(value => EnabledChanged(value)),
          event_key=event_scope + "/enabled",
        ),
        @minimoon.textarea(
          id=props.id + "-note",
          value=current.note,
          placeholder="component note",
          on_input=emit.map(value => NoteChanged(value)),
          input_key=event_scope + "/note",
        ),
        @minimoon.p("component pulses: " + current.pulses.to_string()),
      ],
    )
  })
}
