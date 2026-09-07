///|
fn test_touch_payload() -> Json {
  @json.parse(
    "{\"timeStamp\":15.25,\"touches\":[{\"identifier\":7,\"clientX\":-1.25,\"clientY\":2.5,\"pageX\":3.75,\"pageY\":104.125}],\"changedTouches\":[{\"identifier\":7,\"clientX\":-1.25,\"clientY\":2.5,\"pageX\":3.75,\"pageY\":104.125}]}",
  ) catch {
    _ => abort("invalid fixture")
  }
}

///|
test "touch decoders preserve fractional coordinates and reject malformed identities" {
  match detail_touch(test_touch_payload()) {
    Ok(detail) => {
      assert_eq(detail.timestamp, 15.25)
      assert_eq(detail.touches[0].identifier, 7)
      assert_eq(detail.touches[0].client_x, -1.25)
      assert_eq(detail.changed_touches[0].page_y, 104.125)
    }
    Err(_) => fail("valid touch payload rejected")
  }
  for
    invalid in [
      "{}", "{\"timeStamp\":-1,\"touches\":[],\"changedTouches\":[]}", "{\"timeStamp\":1,\"touches\":[{\"identifier\":1.5}],\"changedTouches\":[]}",
    ] {
    let value = @json.parse(invalid) catch { _ => abort("invalid fixture") }
    assert_true(detail_touch(value) is Err(_))
  }
  assert_true(
    detail_touch(
      Json::object({
        "timeStamp": Json::number(1.0),
        "touches": Json::array([]),
        "changedTouches": Json::array([]),
      }),
    )
    is Ok(_),
  )
  assert_true(
    detail_slider(root_decoder_payload({ "value": Json::number(-15.0) }))
    is Ok(-15),
  )
  assert_true(
    detail_slider(root_decoder_payload({ "value": Json::number(1.25) }))
    is Err(_),
  )
  assert_true(
    detail_image_load(
      root_decoder_payload({
        "width": Json::number(20.25),
        "height": Json::number(12.5),
      }),
    )
    is Ok(_),
  )
  assert_true(
    detail_image_load(
      root_decoder_payload({
        "width": Json::number(-1.0),
        "height": Json::number(12.5),
      }),
    )
    is Err(_),
  )
  assert_true(
    detail_image_error(
      root_decoder_payload({ "errMsg": Json::string("missing") }),
    )
    is Ok("missing"),
  )
}

///|
test "measurement decoding preserves ordering, missing nodes, and fractional rectangles" {
  let rect = @json.parse(
    "{\"id\":\"anchor-1\",\"left\":-1.25,\"top\":2.5,\"right\":8.75,\"bottom\":22.5,\"width\":10,\"height\":20}",
  ) catch {
    _ => abort("invalid fixture")
  }
  let payload = Json::object({ "nodes": Json::array([rect, Json::null()]) })
  match decode_measurements(["anchor-1", "missing"], payload) {
    Ok(values) => {
      assert_eq(values.length(), 2)
      assert_eq(values[1], None)
      match values[0] {
        Some(value) => assert_eq(value.left, -1.25)
        None => fail("missing measured rectangle")
      }
    }
    Err(_) => fail("valid rectangles rejected")
  }
  assert_true(decode_measurements(["wrong", "missing"], payload) is Err(_))
  assert_true(decode_measurements(["anchor-1"], payload) is Err(_))
  assert_true(
    decode_node_rect(Json::object({ "id": Json::string("anchor") })) is Err(_),
  )
  for id in ["", "#anchor", "a.b", "a b", "a:focus", "../node"] {
    assert_false(valid_measure_id(id))
  }
  assert_true(valid_measure_id("anchor_1-2"))
  assert_eq(MeasureNodes.name(), "minimoon.measureNodes")
}

///|
test "native UI controls normalize and dispatch typed events" {
  let definition = page(
    id="native_controls",
    route=route("pages/native/native"),
    title="Native",
    capabilities=[MeasureNodes],
    build=_ => {
      let (state, emit) = create_pure_state("initial", update=(
        _,
        value : String,
      ) => value)
      state.view(value => {
        div([
          text(value),
          button_children(
            on_tap=emit("button"),
            event_key="rich",
            form_type=SubmitForm,
            [image(src="/icon.svg", mode=AspectFit), text("Save")],
          ),
          label(for_id="field", "Field"),
          input(
            id="field",
            name="answer",
            value="",
            input_type=NumberInput,
            maxlength=6,
            password=false,
            selection_start=0,
            selection_end=2,
            on_input=emit,
            event_key="input",
          ),
          image(
            src="/avatar.png",
            mode=AspectFill,
            load_key="avatar-load",
            error_key="avatar-error",
            on_load=emit.map(detail => detail.width.to_string()),
            on_error=emit,
          ),
          form(
            on_submit=emit.map(fields => {
              fields.get("answer").unwrap_or(Json::null()).stringify()
            }),
            submit_key="submit",
            on_reset=emit("reset"),
            reset_key="reset",
            nothing(),
          ),
          slider(
            value=10,
            min=-10,
            max=20,
            on_change=emit.map(number => number.to_string()),
            on_changing=emit.map(number => number.to_string()),
            event_key="slide",
            changing_key="sliding",
          ),
          progress(
            percent=25,
            semantics=semantics(
              role=ProgressbarRole,
              value_now=25,
              value_min=0,
              value_max=100,
              busy=false,
            ),
          ),
          touch_view(
            catch_move=true,
            on_touch_start=emit.map(detail => {
              detail.touches[0].client_x.to_string()
            }),
            on_touch_move=emit.map(detail => detail.timestamp.to_string()),
            on_touch_end=emit.map(_ => "end"),
            on_touch_cancel=emit.map(_ => "cancel"),
            on_long_press=emit.map(_ => "long"),
            event_key="drag",
            "drag",
          ),
          button(
            on_tap=measure_nodes(["field"], emit.map(_ => "measured")),
            event_key="measure",
            "Measure",
          ),
        ])
      })
    },
  )
  let runtime = definition.create_runtime()
  let _ = runtime.mount()
  let snapshot = runtime.snapshot()
  for
    fragment in [
      "\"kind\":\"slider\"", "\"kind\":\"progress\"", "\"kind\":\"form\"", "\"kind\":\"label\"",
      "\"selectionStart\":0", "\"maxlength\":6", "\"catchMove\":true", "\"ariaValueNow\":25",
    ] {
    assert_true(snapshot.contains(fragment))
  }
  for
    entry in [
      ("rich", "{}", "button"),
      ("slide", "{\"detail\":{\"value\":-5}}", "-5"),
      ("sliding", "{\"detail\":{\"value\":8}}", "8"),
      ("submit", "{\"detail\":{\"value\":{\"answer\":42}}}", "42"),
      ("reset", "{}", "reset"),
      ("avatar-error", "{\"detail\":{\"errMsg\":\"missing\"}}", "missing"),
      ("drag/touchstart", test_touch_payload().stringify(), "-1.25"),
      ("drag/touchmove", test_touch_payload().stringify(), "15.25"),
      ("drag/touchend", test_touch_payload().stringify(), "end"),
      ("drag/touchcancel", test_touch_payload().stringify(), "cancel"),
      ("drag/longpress", test_touch_payload().stringify(), "long"),
    ] {
    let (key, payload, expected) = entry
    let commands = runtime.dispatch(key, payload)
    assert_false(commands.contains("event_decode_failed"))
    assert_true(runtime.snapshot().contains("\"text\":\"" + expected + "\""))
  }
  assert_true(
    runtime.dispatch("measure", "{}").contains("minimoon.measureNodes"),
  )
  assert_true(
    runtime.dispatch("drag/touchmove", "{}").contains("event_decode_failed"),
  )
  let _ = runtime.lifecycle("onUnload", "{}")
}
