///|
test "forms showcase validation responds to continuous input without losing focus" {
  let runtime = @testing.mount(@forms.program())
  assert_true(runtime.snapshot().contains("echo.apifox.com"))
  let form = runtime.within(@testing.by_id("forms-submit"))
  assert_eq(
    form.get(@testing.by_id("forms-field")).prop("name"),
    Some(Json::string("project_name")),
  )
  assert_true(runtime.query(@testing.by_id("forms-field-error")) is Some(_))
  let _ = runtime.focus(@testing.by_id("forms-field"), "", 200)
  for value in ["M", "Mo", "Moon"] {
    assert_false(
      runtime
      .input(@testing.by_id("forms-field"), value)
      .contains("RuntimeError"),
    )
    assert_eq(
      runtime.get(@testing.by_id("forms-field")).prop("value"),
      Some(Json::string(value)),
    )
    assert_true(
      runtime
      .get(@testing.by_id("forms-field"))
      .snapshot()
      .contains("mmui-focused"),
    )
  }
  assert_true(runtime.query(@testing.by_id("forms-field-error")) is None)
  assert_eq(
    runtime.get(@testing.by_id("forms-field")).prop("ariaInvalid"),
    Some(Json::boolean(false)),
  )
  let _ = runtime.tap(@testing.by_event_key("gallery/theme"))
  assert_eq(
    runtime.get(@testing.by_id("forms-field")).prop("value"),
    Some(Json::string("Moon")),
  )
  let _ = runtime.input(@testing.by_id("forms-field"), "")
  assert_true(runtime.query(@testing.by_id("forms-field-error")) is Some(_))
  let _ = runtime.blur_input(@testing.by_id("forms-field"), "")
  assert_false(
    runtime
    .get(@testing.by_id("forms-field"))
    .snapshot()
    .contains("mmui-focused"),
  )
  let _ = runtime.dispose()
}

///|
fn echo_runtime() -> @minimoon.PageRuntime {
  let runtime = @forms.program().create_runtime().unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.lifecycle("onShow", "{}")
  let _ = runtime.mount()
  runtime
}

///|
fn echo_request(commands : String) -> (String, Map[String, Json]) raise {
  guard @json.parse(commands) is Array(commands) else {
    fail("expected command array")
  }
  let requests = commands.filter_map(command => {
    if command is Object(fields) &&
      fields.get("type") == Some(Json::string("InvokeCapability")) &&
      fields.get("capability") == Some(Json::string("wx.request")) &&
      fields.get("request_id") is Some(String(id)) &&
      fields.get("payload") is Some(Object(payload)) {
      Some((id, payload))
    } else {
      None
    }
  })
  assert_eq(requests.length(), 1)
  requests[0]
}

///|
fn echo_submit_batch(runtime : @minimoon.PageRuntime, title : String) -> String {
  runtime.dispatch_batch(
    Json::array([
      Json::object({
        "key": Json::string("forms-field/input"),
        "payload": Json::object({
          "detail": Json::object({ "value": Json::string(title) }),
        }),
      }),
      Json::object({
        "key": Json::string("forms/submit"),
        "payload": Json::object({
          "detail": Json::object({ "value": Json::empty_object() }),
        }),
      }),
    ]).stringify(),
  )
}

///|
fn echo_reply(title : String, status? : Int = 200) -> String {
  Json::object({
    "statusCode": status.to_json(),
    "data": Json::object({
      "json": Json::object({ "title": Json::string(title) }),
    }),
  }).stringify()
}

///|
test "Forms invalid draft sends nothing and same-frame input submit uses the latest typed body" {
  let runtime = echo_runtime()
  let invalid = echo_submit_batch(runtime, "  ")
  assert_false(invalid.contains("RuntimeError"))
  assert_false(invalid.contains("wx.request"))
  assert_true(runtime.snapshot().contains("Invalid draft"))
  let (id, payload) = echo_request(
    echo_submit_batch(runtime, "  MoonBit title  "),
  )
  assert_eq(payload.get("method"), Some(Json::string("POST")))
  assert_eq(payload.get("timeout"), Some(Json::number(10000)))
  assert_eq(
    payload.get("url"),
    Some(Json::string("https://echo.apifox.com/post")),
  )
  guard payload.get("data") is Some(String(body)) else {
    fail("expected typed JSON body")
  }
  assert_eq(
    @json.parse(body),
    Json::object({ "title": Json::string("MoonBit title") }),
  )
  assert_true(runtime.snapshot().contains("Sending echo request"))
  let _ = runtime.dispatch(
    "forms-field/input", "{\"detail\":{\"value\":\"blocked while busy\"}}",
  )
  assert_false(runtime.snapshot().contains("blocked while busy"))
  let duplicate = runtime.dispatch(
    "forms/submit", "{\"detail\":{\"value\":{}}}",
  )
  assert_false(duplicate.contains("wx.request"))
  let _ = runtime.resolve_effect(
    id,
    "success",
    echo_reply("Server echoed title"),
  )
  assert_true(
    runtime
    .snapshot()
    .contains("Echo title: Server echoed title — not persisted."),
  )
  let _ = runtime.dispose()
}

///|
test "Forms validation counts Unicode scalars rather than UTF-16 code units" {
  let runtime = echo_runtime()
  let invalid = echo_submit_batch(runtime, "  🌙月  ")
  assert_false(invalid.contains("RuntimeError"))
  assert_false(invalid.contains("wx.request"))
  assert_true(runtime.snapshot().contains("Invalid draft"))
  let (_, payload) = echo_request(echo_submit_batch(runtime, "  🌙月光  "))
  guard payload.get("data") is Some(String(body)) else {
    fail("expected typed JSON body")
  }
  assert_eq(
    @json.parse(body),
    Json::object({ "title": Json::string("🌙月光") }),
  )
  assert_true(runtime.snapshot().contains("Sending echo request"))
  let _ = runtime.dispose()
}

///|
test "Forms request failure restores editing and typed decoding failures remain visible" {
  let runtime = echo_runtime()
  let (id, _) = echo_request(echo_submit_batch(runtime, "First title"))
  let _ = runtime.resolve_effect(
    id,
    "success",
    echo_reply("ignored", status=503),
  )
  assert_true(
    runtime.snapshot().contains("Echo request failed: HTTP status 503"),
  )
  let (id, _) = echo_request(echo_submit_batch(runtime, "Second title"))
  let _ = runtime.resolve_effect(
    id, "success", "{\"statusCode\":200,\"data\":{\"json\":{\"title\":42}}}",
  )
  assert_true(runtime.snapshot().contains("Echo request failed:"))
  assert_false(runtime.snapshot().contains("Echo title:"))
  let (id, _) = echo_request(echo_submit_batch(runtime, "Third title"))
  let _ = runtime.resolve_effect(id, "success", echo_reply("Recovered"))
  assert_true(
    runtime.snapshot().contains("Echo title: Recovered — not persisted."),
  )
  let _ = runtime.dispose()
}

///|
test "Forms reset invalidates late replies and page disposal cancels pending requests" {
  let runtime = echo_runtime()
  let (old_id, _) = echo_request(echo_submit_batch(runtime, "Old title"))
  let _ = runtime.dispatch("forms/reset", "{}")
  assert_true(runtime.snapshot().contains("Echo demo only"))
  let (new_id, _) = echo_request(echo_submit_batch(runtime, "New title"))
  let _ = runtime.resolve_effect(old_id, "success", echo_reply("Old response"))
  assert_true(runtime.snapshot().contains("Sending echo request"))
  assert_false(runtime.snapshot().contains("Echo title: Old response"))
  let _ = runtime.resolve_effect(new_id, "success", echo_reply("New response"))
  assert_true(
    runtime.snapshot().contains("Echo title: New response — not persisted."),
  )
  let (pending_id, _) = echo_request(
    echo_submit_batch(runtime, "Pending title"),
  )
  assert_true(runtime.dispose().contains("CancelEffect"))
  assert_eq(
    runtime.resolve_effect(pending_id, "success", echo_reply("Too late")),
    "[]",
  )
}
