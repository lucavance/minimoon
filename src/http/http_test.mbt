///|
priv struct User {
  name : String
  count : Int
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
priv struct Users {
  users : Array[User]
} derive(@json.FromJson)

///|
fn[T] capture(
  result : Ref[Result[T, Error]?],
) -> @minimoon.Emit[Result[T, Error]] {
  value => {
    result.val = Some(value)
    @minimoon.none
  }
}

///|
fn runtime_for(
  command : @minimoon.Cmd,
  capabilities? : Array[@minimoon.Capability] = [@minimoon.Request],
) -> @minimoon.PageRuntime {
  let runtime = @minimoon.page(
      id="http_test",
      route=@minimoon.route("pages/http/test"),
      title="HTTP",
      capabilities~,
      build=_ => {
        @minimoon.Val::constant(
          @minimoon.button(on_tap=command, event_key="request", "Request"),
        )
      },
    )
    .create_runtime()
    .unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  runtime
}

///|
fn request_command(commands : String) -> (String, Map[String, Json]) raise {
  guard @json.parse(commands) is Array(commands) else {
    fail("host commands must be an array")
  }
  for command in commands {
    if command is Object(fields) &&
      fields.get("type") == Some(Json::string("InvokeCapability")) &&
      fields.get("capability") == Some(Json::string("wx.request")) &&
      fields.get("request_id") is Some(String(id)) &&
      fields.get("payload") is Some(Object(payload)) {
      return (id, payload)
    }
  }
  fail("expected one wx.request command")
}

///|
fn begin_request(
  runtime : @minimoon.PageRuntime,
) -> (String, Map[String, Json]) raise {
  request_command(runtime.dispatch("request", "{}"))
}

///|
fn response(status : Int, data : Json) -> String {
  Json::object({ "statusCode": status.to_json(), "data": data }).stringify()
}

///|
test "HTTP builders dispatch the four supported methods with empty bodies" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let resolve = capture(result)
  for
    entry in [
      (get("https://example.test").expect_json(resolve), "GET"),
      (delete("https://example.test").expect_json(resolve), "DELETE"),
      (post("https://example.test").expect_json(resolve), "POST"),
      (put("https://example.test").expect_json(resolve), "PUT"),
    ] {
    let (command, verb) = entry
    let runtime = runtime_for(command)
    let (id, payload) = begin_request(runtime)
    assert_eq(payload["method"], Json::string(verb))
    assert_eq(payload["url"], Json::string("https://example.test"))
    assert_eq(payload["header"], Json::empty_object())
    assert_true(!payload.contains("data"))
    assert_true(!payload.contains("timeout"))
    ignore(runtime.resolve_effect(id, "success", response(200, Json::null())))
    assert_true(result.val is Some(Ok(Null)))
    ignore(runtime.dispose())
  }
}

///|
test "HTTP constructors snapshot query and headers and preserve timeout options" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let query = [
    @minimoon.query("q", "测试 +&="),
    @minimoon.query("tag", "one"),
    @minimoon.query("tag", "two"),
  ]
  let headers = { "X-Test": "before" }
  let commands = [
    get("https://example.test/?old=yes", query~, headers~, timeout_ms=123).expect_json(
      capture(result),
    ),
    delete("https://example.test/?old=yes", query~, headers~, timeout_ms=123).expect_json(
      capture(result),
    ),
    post("https://example.test/?old=yes", query~, headers~, timeout_ms=123).expect_json(
      capture(result),
    ),
    put("https://example.test/?old=yes", query~, headers~, timeout_ms=123).expect_json(
      capture(result),
    ),
  ]
  let deferred = get(
    "https://example.test/?old=yes",
    query~,
    headers~,
    timeout_ms=123,
  )
  let deferred_body = post(
    "https://example.test/?old=yes",
    query~,
    headers~,
    timeout_ms=123,
  )
  query.clear()
  headers["X-Test"] = "after"
  commands.push(deferred.expect_json(capture(result)))
  commands.push(deferred_body.expect_json(capture(result)))
  assert_true(result.val is None)
  for command in commands {
    let runtime = runtime_for(command)
    let (_, payload) = begin_request(runtime)
    assert_eq(
      payload["url"],
      Json::string(
        "https://example.test/?old=yes&q=%E6%B5%8B%E8%AF%95%20%2B%26%3D&tag=one&tag=two",
      ),
    )
    assert_eq(
      payload["header"],
      Json::object({ "x-test": Json::string("before") }),
    )
    assert_eq(payload["timeout"], (123).to_json())
    ignore(runtime.dispose())
  }
}

///|
test "HTTP JSON and text bodies use root encoding and snapshot nested JSON" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let user : User = { name: "MoonBit", count: 2, }
  let nested = { "value": Json::string("before") }
  let values = [Json::object(nested)]
  let builder = post("https://example.test").with_json(Json::array(values))
  nested["value"] = Json::string("after")
  values.clear()
  for
    entry in [
      (builder, "[{\"value\":\"before\"}]", "application/json"),
      (
        post("https://example.test").with_json(user),
        ToJson::to_json(user).stringify(),
        "application/json",
      ),
      (
        put("https://example.test").with_json(Json::null()),
        "null",
        "application/json",
      ),
      (
        post("https://example.test").with_json("hello"),
        "\"hello\"",
        "application/json",
      ),
      (
        put("https://example.test").with_text("raw +&="),
        "raw +&=",
        "text/plain; charset=utf-8",
      ),
      (
        post("https://example.test").with_text(""),
        "",
        "text/plain; charset=utf-8",
      ),
      (
        post("https://example.test", headers={
          "Content-Type": "application/problem+json",
        }).with_json(Json::null()),
        "null",
        "application/problem+json",
      ),
      (
        put("https://example.test", headers={
          "Content-Type": "application/xml",
        }).with_text("<test/>"),
        "<test/>",
        "application/xml",
      ),
    ] {
    let (builder, body, content_type) = entry
    let runtime = runtime_for(builder.expect_json(capture(result)))
    let (_, payload) = begin_request(runtime)
    assert_eq(payload["data"], Json::string(body))
    assert_eq(
      payload["header"],
      Json::object({ "content-type": Json::string(content_type) }),
    )
    ignore(runtime.dispose())
  }
}

///|
test "HTTP expect_json decodes 2xx values and settles each root request once" {
  let result : Ref[Result[User, Error]?] = Ref(None)
  let deliveries = Ref(0)
  let runtime = runtime_for(
    get("https://example.test").expect_json(value => {
      deliveries.val += 1
      result.val = Some(value)
      @minimoon.none
    }),
  )
  let user : User = { name: "MoonBit", count: 7, }
  for status in [200, 201, 204, 299] {
    let (id, _) = begin_request(runtime)
    ignore(
      runtime.resolve_effect(
        id,
        "success",
        response(status, ToJson::to_json(user)),
      ),
    )
    assert_eq(result.val.unwrap().unwrap(), user)
    ignore(
      runtime.resolve_effect(id, "success", response(status, Json::null())),
    )
  }
  assert_eq(deliveries.val, 4)
  ignore(runtime.dispose())
}

///|
test "HTTP non-2xx status preserves the full response before typed decoding" {
  let result : Ref[Result[User, Error]?] = Ref(None)
  let runtime = runtime_for(
    get("https://example.test").expect_json(capture(result)),
  )
  for status in [0, 199, 300, 304, 400, 401, 500] {
    let (id, _) = begin_request(runtime)
    ignore(
      runtime.resolve_effect(
        id,
        "success",
        Json::object({
          "statusCode": status.to_json(),
          "data": Json::string("not a User"),
          "header": Json::object({ "retry-after": Json::string("3") }),
          "cookies": Json::array([Json::string("session=redacted")]),
        }).stringify(),
      ),
    )
    match result.val {
      Some(Err(HttpError::BadStatus(response))) => {
        assert_eq(response.status_code, status)
        assert_eq(response.data, Json::string("not a User"))
        assert_eq(response.headers["retry-after"], "3")
        assert_eq(response.cookies, ["session=redacted"])
      }
      _ => fail("non-2xx must be a public BadStatus with the raw response")
    }
  }
  ignore(runtime.dispose())
}

///|
test "HTTP typed decode errors retain the original JsonDecodeError path and type" {
  let result : Ref[Result[Users, Error]?] = Ref(None)
  let data = Json::object({
    "users": Json::array([
      Json::object({
        "name": Json::string("MoonBit"),
        "count": Json::string("wrong"),
      }),
    ]),
  })
  let expected : @json.JsonDecodeError? = try {
    let decoded : Users = @json.from_json(data)
    ignore(decoded.users.length())
    None
  } catch {
    error => Some(error)
  }
  let runtime = runtime_for(
    get("https://example.test").expect_json(capture(result)),
  )
  let (id, _) = begin_request(runtime)
  ignore(runtime.resolve_effect(id, "success", response(200, data)))
  match result.val {
    Some(Err(@json.JsonDecodeError(details))) => {
      assert_eq(@json.JsonDecodeError(details), expected.unwrap())
      assert_true(details.0.to_string().contains("users"))
      assert_true(details.0.to_string().contains("count"))
      assert_true(details.1.contains("Int"))
    }
    _ => fail("JSON decoding error must not be flattened into an HTTP error")
  }
  ignore(runtime.dispose())
}

///|
test "HTTP does not parse the host Json data string a second time" {
  let text_result : Ref[Result[String, Error]?] = Ref(None)
  let number_result : Ref[Result[Int, Error]?] = Ref(None)
  let text = runtime_for(
    get("https://example.test").expect_json(capture(text_result)),
  )
  let (id, _) = begin_request(text)
  ignore(text.resolve_effect(id, "success", response(200, Json::string("42"))))
  assert_eq(text_result.val.unwrap().unwrap(), "42")
  ignore(text.dispose())
  let number = runtime_for(
    get("https://example.test").expect_json(capture(number_result)),
  )
  let (id, _) = begin_request(number)
  ignore(
    number.resolve_effect(id, "success", response(200, Json::string("42"))),
  )
  assert_true(number_result.val is Some(Err(@json.JsonDecodeError(_))))
  ignore(number.dispose())
}

///|
test "HTTP transport errors retain the complete root HostError" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let runtime = runtime_for(
    get("https://example.test").expect_json(capture(result)),
  )
  let raw = Json::object({
    "error": Json::string("request:fail timeout"),
    "errMsg": Json::string("request:fail timeout"),
    "errCode": (600001).to_json(),
  })
  for
    entry in [
      ("failure", @minimoon.Failed),
      ("unavailable", @minimoon.Unavailable),
    ] {
    let (phase, kind) = entry
    let (id, _) = begin_request(runtime)
    ignore(runtime.resolve_effect(id, phase, raw.stringify()))
    match result.val {
      Some(Err(HttpError::RequestError(error))) => {
        assert_eq(error.capability, @minimoon.Request)
        assert_eq(error.kind, kind)
        assert_eq(error.message, "request:fail timeout")
        assert_eq(error.code, Some("600001"))
        assert_eq(error.raw, raw)
      }
      _ => fail("expected the wrapped transport error")
    }
  }
  ignore(runtime.dispose())
}

///|
test "HTTP invalid options are deferred and do not invoke the host" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let resolve = capture(result)
  for
    command in [
      get("http://example.test").expect_json(resolve),
      get("https://example.test", timeout_ms=0).expect_json(resolve),
      delete("https://example.test", headers={ "Referer": "secret" }).expect_json(
        resolve,
      ),
      post("https://example.test", headers={ "Content-Type": "text/plain" })
      .with_json(1)
      .expect_json(resolve),
    ] {
    result.val = None
    let runtime = runtime_for(command)
    assert_true(result.val is None)
    let commands = runtime.dispatch("request", "{}")
    assert_true(!commands.contains("InvokeCapability"))
    assert_true(
      result.val
      is Some(
        Err(HttpError::RequestError({ kind: @minimoon.InvalidPayload, .. }))
      ),
    )
    ignore(runtime.dispose())
  }
}

///|
test "HTTP malformed host response remains a root validation error" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let runtime = runtime_for(
    get("https://example.test").expect_json(capture(result)),
  )
  let (id, _) = begin_request(runtime)
  ignore(runtime.resolve_effect(id, "success", "{\"statusCode\":\"200\"}"))
  assert_true(
    result.val
    is Some(
      Err(HttpError::RequestError({ kind: @minimoon.InvalidPayload, .. }))
    ),
  )
  ignore(runtime.dispose())
}

///|
test "HTTP disposal cancels pending requests and drops late completions" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let runtime = runtime_for(
    get("https://example.test").expect_json(capture(result)),
  )
  let (id, _) = begin_request(runtime)
  assert_true(runtime.dispose().contains("CancelEffect"))
  assert_eq(
    runtime.resolve_effect(id, "success", response(200, Json::null())),
    "[]",
  )
  assert_true(result.val is None)
}

///|
test "HTTP capability availability is reported by the existing host boundary" {
  let result : Ref[Result[Json, Error]?] = Ref(None)
  let runtime = runtime_for(
    get("https://example.test").expect_json(capture(result)),
    capabilities=[],
  )
  let (id, _) = begin_request(runtime)
  ignore(runtime.resolve_effect(id, "unavailable", "{}"))
  assert_true(
    result.val
    is Some(Err(HttpError::RequestError({ kind: @minimoon.Unavailable, .. }))),
  )
  ignore(runtime.dispose())
}

///|
test "HTTP builders remain reusable without sharing response callbacks" {
  let first_result : Ref[Result[Int, Error]?] = Ref(None)
  let second_result : Ref[Result[Int, Error]?] = Ref(None)
  let builder = post("https://example.test").with_json(42)
  let first = runtime_for(builder.expect_json(capture(first_result)))
  let second = runtime_for(builder.expect_json(capture(second_result)))
  let (first_id, first_payload) = begin_request(first)
  let (second_id, second_payload) = begin_request(second)
  assert_eq(first_payload, second_payload)
  ignore(
    first.resolve_effect(first_id, "success", response(200, (1).to_json())),
  )
  assert_eq(first_result.val.unwrap().unwrap(), 1)
  assert_true(second_result.val is None)
  ignore(
    second.resolve_effect(second_id, "success", response(200, (2).to_json())),
  )
  assert_eq(second_result.val.unwrap().unwrap(), 2)
  assert_eq(first_result.val.unwrap().unwrap(), 1)
  ignore(first.dispose())
  ignore(second.dispose())
}

///|
fn shared_page(value : @minimoon.Shared[Int]) -> @minimoon.Page {
  @minimoon.page(
    id="http_shared",
    route=@minimoon.route("pages/http/shared"),
    title="Shared HTTP",
    build=context => {
      context
      .bind(value)
      .view(value => @minimoon.text("value:" + value.to_string()))
    },
  )
}

///|
test "HTTP typed commands inherit application ownership beyond page lifetime" {
  let app = @minimoon.app(capabilities=[@minimoon.Request], build=context => {
    context.create_state(0, update=(value, message : Int, emit) => {
      if message == -1 {
        (
          value,
          get("https://example.test").expect_json(result => {
            let decoded : Int = match result {
              Ok(value) => value
              Err(_) => -2
            }
            emit(decoded)
          }),
        )
      } else {
        @minimoon.no_cmd(message)
      }
    })
  }).create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let first = app.create_page(shared_page(app.deps().0)).unwrap()
  ignore(first.lifecycle("onLoad", "{}"))
  let (id, _) = request_command(app.dispatch((app.deps().1)(-1)))
  assert_true(!first.dispose().contains("CancelEffect"))
  ignore(app.resolve_effect(id, "success", response(200, (41).to_json())))
  let second = app.create_page(shared_page(app.deps().0)).unwrap()
  ignore(second.lifecycle("onLoad", "{}"))
  assert_true(second.snapshot().contains("value:41"))
  let (pending, _) = request_command(app.dispatch((app.deps().1)(-1)))
  assert_true(app.dispose().contains("CancelEffect"))
  assert_eq(
    app.resolve_effect(pending, "success", response(200, (99).to_json())),
    "[]",
  )
  ignore(second.dispose())
}
