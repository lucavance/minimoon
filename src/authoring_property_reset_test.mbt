///|
priv struct PropertyResetState {
  phase : Int32
  text : String
  checked : Bool
} derive(Eq)

///|
fn reset_control_node(
  runtime : @minimoon.PageRuntime,
  id : String,
) -> Map[String, Json] {
  let snapshot = @json.parse(runtime.snapshot()) catch {
    _ => abort("invalid control snapshot")
  }
  guard keyed_lifetime_find(snapshot, id) is Some(Object(fields)) else {
    abort("missing reset control")
  }
  fields
}

///|
fn reset_control_props(
  runtime : @minimoon.PageRuntime,
  id : String,
) -> Map[String, Json] {
  guard reset_control_node(runtime, id)["props"] is Object(props) else {
    abort("missing control props")
  }
  props
}

///|
test "public keyed controls clear values and optional props with current event handlers" {
  let runtime = @minimoon.page(
      id="property_reset",
      route=@minimoon.route("pages/property_reset/property_reset"),
      title="Property reset",
      build=_ => {
        let (state, update) = @minimoon.create_variable(PropertyResetState::{
          phase: 0,
          text: "old",
          checked: true,
        })
        state.view(state => {
          let phase = state.phase
          let on_input = @minimoon.Emit(text => {
            update(current => {
              ..current,
              text: phase.to_string() + ":" + text,
            })
          })
          let input = @minimoon.keyed(
            "input",
            @minimoon.input(
              id="input",
              event_key="input",
              value=state.text,
              on_input~,
              disabled=phase == 0,
              maxlength?=if phase < 2 {
                Some(if phase == 0 { 12 } else { 0 })
              } else {
                None
              },
              password?=if phase < 2 { Some(phase == 0) } else { None },
              selection_start?=if phase < 2 { Some(0) } else { None },
              selection_end?=if phase < 2 { Some(0) } else { None },
              name=if phase == 0 { "old-name" } else { "" },
              placeholder=if phase == 0 { "old hint" } else { "" },
            ),
          )
          let textarea = @minimoon.keyed(
            "textarea",
            @minimoon.textarea(
              id="textarea",
              input_key="textarea",
              value=state.text,
              on_input~,
              disabled=phase == 0,
            ),
          )
          let switch = @minimoon.keyed(
            "switch",
            @minimoon.switch(
              id="switch",
              event_key="switch",
              checked=state.checked,
              disabled=phase == 0,
              on_change=@minimoon.Emit(checked => {
                update(current => { ..current, checked, })
              }),
            ),
          )
          let checkbox = @minimoon.keyed(
            "checkbox",
            @minimoon.checkbox_group(
              event_key="checks",
              on_change=@minimoon.Emit(values => {
                update(current => {
                  ..current,
                  checked: values.contains("accept"),
                })
              }),
              [
                @minimoon.checkbox(
                  id="checkbox",
                  value="accept",
                  checked=state.checked,
                  disabled=phase == 0,
                  ([] : Array[@minimoon.Node]),
                ),
              ],
            ),
          )
          @minimoon.div([
            @minimoon.button(
              event_key="reset",
              on_tap=update(current => {
                phase: current.phase + 1,
                text: "",
                checked: false,
              }),
              "Reset",
            ),
            @minimoon.keyed_fragment(
              if phase == 0 {
                [input, textarea, switch, checkbox]
              } else {
                [checkbox, switch, textarea, input]
              },
            ),
          ])
        })
      },
    )
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  defer {
    let _ = runtime.dispose()
  }
  let ids = ["input", "textarea", "switch", "checkbox"]
  let identities = ids.map(id => reset_control_node(runtime, id)["identity"])
  assert_eq(reset_control_props(runtime, "input")["value"], Json::string("old"))
  for id in ["switch", "checkbox"] {
    assert_eq(reset_control_props(runtime, id)["checked"], Json::boolean(true))
  }
  for phase in [1, 2] {
    let commands = runtime.dispatch("reset", "{}")
    assert_false(commands.contains("RuntimeError"))
    for index, id in ids {
      let node = reset_control_node(runtime, id)
      assert_eq(node["identity"], identities[index])
      assert_eq(
        reset_control_props(runtime, id)["disabled"],
        Json::boolean(false),
      )
    }
    for id in ["input", "textarea"] {
      assert_eq(reset_control_props(runtime, id)["value"], Json::string(""))
    }
    for id in ["switch", "checkbox"] {
      assert_eq(
        reset_control_props(runtime, id)["checked"],
        Json::boolean(false),
      )
    }
    let props = reset_control_props(runtime, "input")
    for name in ["name", "placeholder"] {
      assert_eq(props.get(name), None)
    }
    for name in ["maxlength", "selectionStart", "selectionEnd"] {
      assert_eq(
        props.get(name),
        if phase == 1 {
          Some(Json::number(0))
        } else {
          None
        },
      )
    }
    assert_eq(
      props.get("password"),
      if phase == 1 {
        Some(Json::boolean(false))
      } else {
        None
      },
    )
    for id in ["input", "textarea"] {
      let _ = runtime.dispatch(id, "{\"detail\":{\"value\":\"edited\"}}")
      assert_eq(
        reset_control_props(runtime, id)["value"],
        Json::string(phase.to_string() + ":edited"),
      )
    }
    let _ = runtime.dispatch("switch", "{\"detail\":{\"value\":true}}")
    assert_eq(
      reset_control_props(runtime, "switch")["checked"],
      Json::boolean(true),
    )
    let _ = runtime.dispatch("checks", "{\"detail\":{\"value\":[]}}")
    assert_eq(
      reset_control_props(runtime, "checkbox")["checked"],
      Json::boolean(false),
    )
  }
}
