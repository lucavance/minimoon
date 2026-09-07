///|
fn http_fields(command : Cmd) -> Map[String, Json] raise {
  match command.0 {
    @val.CmdHostEffect("wx.request", payload, _) =>
      match @json.parse(payload) {
        Object(fields) => fields
        _ => fail("request payload must be an object")
      }
    _ => fail("expected request effect")
  }
}

///|
test "HTTP encodes queries and all bodies once and snapshots mutable input" {
  let result : Ref[Result[RequestResult, HostError]?] = Ref(None)
  let resolve = test_send(result)
  let pairs = [
    query("q", "测试 +&="),
    query("tag", "one"),
    query("tag", "two"),
  ]
  let headers = { "X-Test": "before" }
  let payload = request(
    "https://example.test/get?old=yes",
    resolve,
    query=pairs,
    headers~,
  )
  headers["X-Test"] = "after"
  pairs.clear()
  let fields = http_fields(payload)
  assert_eq(
    fields["url"],
    Json::string(
      "https://example.test/get?old=yes&q=%E6%B5%8B%E8%AF%95%20%2B%26%3D&tag=one&tag=two",
    ),
  )
  assert_eq(
    fields["header"],
    Json::object({ "x-test": Json::string("before") }),
  )
  assert_eq(fields["method"], Json::string("GET"))
  assert_true(!fields.contains("data") && !fields.contains("timeout"))
  for
    entry in [
      (JsonBody(Json::null()), "null", "application/json"),
      (JsonBody(Json::string("hello")), "\"hello\"", "application/json"),
      (
        FormBody([("q", "测试 +&="), ("q", "two")]),
        "q=%E6%B5%8B%E8%AF%95%20%2B%26%3D&q=two",
        "application/x-www-form-urlencoded",
      ),
      (TextBody(""), "", "text/plain; charset=utf-8"),
      (TextBody("raw +&="), "raw +&=", "text/plain; charset=utf-8"),
    ] {
    let (body, expected, content_type) = entry
    let fields = http_fields(
      request(
        "https://example.test",
        resolve,
        http_method=Post,
        body~,
        timeout_ms=123,
      ),
    )
    assert_eq(fields["data"], Json::string(expected))
    assert_eq(fields["timeout"], (123).to_json())
    assert_eq(
      fields["header"],
      Json::object({ "content-type": Json::string(content_type) }),
    )
  }
  for verb in [Get, Post, Put, Delete, Head, Options] {
    let fields = http_fields(
      request("https://example.test/?", resolve, http_method=verb, query=[
        query("x", "y"),
      ]),
    )
    assert_eq(fields["method"], Json::string(verb.wire()))
    assert_eq(fields["url"], Json::string("https://example.test/?x=y"))
  }
  for
    entry in [
      ("https://example.test/path&", "https://example.test/path&?x=y"),
      ("https://example.test/?old=yes&", "https://example.test/?old=yes&x=y"),
      ("https://example.test:00443", "https://example.test:00443?x=y"),
      ("https://[::1]:443/", "https://[::1]:443/?x=y"),
    ] {
    let (url, expected) = entry
    assert_eq(
      http_fields(request(url, resolve, query=[query("x", "y")]))["url"],
      Json::string(expected),
    )
  }
  for
    entry in [
      (JsonBody(Json::null()), "Application/Problem+JSON; charset=UTF-8"),
      (FormBody([]), "Application/X-Www-Form-Urlencoded; charset=utf-8"),
      (TextBody("<xml/>"), "application/xml"),
    ] {
    let (body, content_type) = entry
    let fields = http_fields(
      request("https://example.test", resolve, http_method=Put, body~, headers={
        "Content-Type": content_type,
      }),
    )
    assert_eq(
      fields["header"],
      Json::object({ "content-type": Json::string(content_type) }),
    )
  }
  let json_fields = { "x": (1).to_json() }
  let cmd = request(
    "https://example.test",
    resolve,
    http_method=Post,
    body=JsonBody(Json::object(json_fields)),
  )
  json_fields["x"] = (2).to_json()
  assert_eq(http_fields(cmd)["data"], Json::string("{\"x\":1}"))
  assert_true(result.val is None)
}

///|
test "HTTP validation is deferred private and never invokes the host" {
  let result : Ref[Result[RequestResult, HostError]?] = Ref(None)
  let resolve = test_send(result)
  let commands = [
    request("http://example.test", resolve),
    request("/relative", resolve),
    request("https://user:secret@example.test", resolve),
    request("https://example.test/#secret", resolve),
    request("https:///", resolve),
    request("https://:443", resolve),
    request("https://example.test:secret", resolve),
    request("https://example.test:", resolve),
    request("https://example.test:65536", resolve),
    request("https://example.test:0", resolve),
    request("https://example.test:1:2", resolve),
    request("https://[::1", resolve),
    request("https://[not-a-host]", resolve),
    request("https://[::1]extra", resolve),
    request("https://[::1]:bad", resolve),
    request("https://bad[]", resolve),
    request("https://example.test\\secret", resolve),
    request("https://example.test/\nsecret", resolve),
    request("https://example.test", resolve, body=TextBody("secret")),
    request(
      "https://example.test",
      resolve,
      http_method=Head,
      body=JsonBody(Json::null()),
    ),
    request("https://example.test", resolve, timeout_ms=0),
    request("https://example.test", resolve, timeout_ms=-1),
    request("https://example.test", resolve, headers={
      "X-Test": "secret",
      "x-test": "secret",
    }),
    request("https://example.test", resolve, headers={ "Referer": "secret" }),
    request("https://example.test", resolve, headers={ "": "secret" }),
    request("https://example.test", resolve, headers={ "bad:name": "secret" }),
    request("https://example.test", resolve, headers={
      "test": "secret\r\nvalue",
    }),
    request(
      "https://example.test",
      resolve,
      http_method=Post,
      body=JsonBody(Json::null()),
      headers={ "Content-Type": "text/plain" },
    ),
    request(
      "https://example.test",
      resolve,
      http_method=Post,
      body=FormBody([]),
      headers={ "Content-Type": "application/json" },
    ),
  ]
  assert_true(result.val is None)
  for command in commands {
    result.val = None
    match command.0 {
      @val.CmdMessage(run) => {
        let _ = run()
      }
      _ => fail("invalid request must be a deferred local message")
    }
    match result.val {
      Some(Err(error)) => {
        assert_eq(error.kind, InvalidPayload)
        assert_eq(error.capability, Request)
        assert_eq(error.raw, Json::null())
        assert_true(!error.message.contains("secret"))
      }
      _ => fail("validation error was not delivered")
    }
  }
}

///|
test "HTTP transport outcomes preserve non-2xx status and response shapes" {
  let result : Ref[Result[RequestResult, HostError]?] = Ref(None)
  match request("https://example.test", test_send(result)).0 {
    @val.CmdHostEffect(_, _, resolve) => {
      for code in [200, 400, 401, 500] {
        let _ = resolve(
          @val.HostOk(
            "{\"statusCode\":" +
            code.to_string() +
            ",\"data\":\"\",\"header\":{\"x\":2},\"cookies\":[false,\"a=b\"]}",
          ),
        )
        match result.val {
          Some(Ok(response)) => {
            assert_eq(response.status_code, code)
            assert_eq(response.data, Json::string(""))
            assert_eq(response.headers["x"], "2")
            assert_eq(response.cookies, ["a=b"])
          }
          _ => fail("HTTP status is not a transport failure")
        }
      }
      for
        raw in [
          "not json", "[]", "{}", "{\"statusCode\":\"200\"}", "{\"statusCode\":1.5}",
        ] {
        let _ = resolve(@val.HostOk(raw))
        assert_true(result.val is Some(Err({ kind: InvalidPayload, .. })))
      }
      for
        entry in [
          ("failure", HostErrorKind::Failed),
          ("unavailable", Unavailable),
        ] {
        let (phase, kind) = entry
        let _ = resolve(@val.HostErr(phase, "network unavailable", "{}"))
        match result.val {
          Some(Err(error)) => assert_eq(error.kind, kind)
          _ => fail("host error was not delivered")
        }
      }
    }
    _ => fail("expected host effect")
  }
}
