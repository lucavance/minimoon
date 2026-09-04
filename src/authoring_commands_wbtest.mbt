///|
/// White-box helper for inspecting the opaque public command wrapper.
fn[A] test_send(target : Ref[A?]) -> (A) -> Cmd {
  value => {
    target.val = Some(value)
    none
  }
}

///|
fn root_decoder_payload(detail : Map[String, Json]) -> Json {
  Json::object({ "detail": Json::object(detail) })
}

///|
fn root_scroll_fields() -> Map[String, Json] {
  {
    "scrollLeft": Json::number(1.25, repr="1.25"),
    "scrollTop": Json::number(2.5, repr="2.5"),
    "scrollHeight": Json::number(300.75, repr="300.75"),
    "scrollWidth": Json::number(100.125, repr="100.125"),
    "deltaX": Json::number(-0.5, repr="-0.5"),
    "deltaY": Json::number(4.25, repr="4.25"),
  }
}

///|
test "root event decoders preserve scroll numbers and reject lossy values" {
  assert_true(
    detail_string(
      root_decoder_payload({ "value": Json::number(7.0, repr="7") }),
    )
    is Err(_),
  )
  assert_true(
    detail_index(
      root_decoder_payload({
        "value": Json::number(2147483647.0, repr="2147483647"),
      }),
    )
    is Ok(2147483647),
  )
  assert_true(
    detail_index(root_decoder_payload({ "value": Json::string("2147483647") }))
    is Ok(2147483647),
  )
  for
    value in [
      Json::number(-1.0, repr="-1"),
      Json::number(1.5, repr="1.5"),
      Json::number(2147483648.0, repr="2147483648"),
      Json::string("2147483648"),
    ] {
    assert_true(
      detail_index(root_decoder_payload({ "value": value })) is Err(_),
    )
  }
  assert_true(
    detail_current(
      root_decoder_payload({
        "current": Json::number(2147483647.0, repr="2147483647"),
      }),
    )
    is Ok(2147483647),
  )
  for
    value in [
      Json::number(1.5, repr="1.5"),
      Json::number(2147483648.0, repr="2147483648"),
      Json::string("1"),
    ] {
    assert_true(
      detail_current(root_decoder_payload({ "current": value })) is Err(_),
    )
  }
  match detail_scroll(root_decoder_payload(root_scroll_fields())) {
    Ok(detail) => {
      assert_eq(detail.scroll_left, 1.25)
      assert_eq(detail.scroll_top, 2.5)
      assert_eq(detail.scroll_height, 300.75)
      assert_eq(detail.scroll_width, 100.125)
      assert_eq(detail.delta_x, -0.5)
      assert_eq(detail.delta_y, 4.25)
    }
    Err(_) => fail("complete numeric scroll detail must decode")
  }
  for
    name in [
      "scrollLeft", "scrollTop", "scrollHeight", "scrollWidth", "deltaX", "deltaY",
    ] {
    let fields = root_scroll_fields()
    fields.remove(name)
    assert_true(detail_scroll(root_decoder_payload(fields)) is Err(_))
  }
  let wrong_scroll = root_scroll_fields()
  wrong_scroll["scrollTop"] = Json::string("2.5")
  assert_true(detail_scroll(root_decoder_payload(wrong_scroll)) is Err(_))
}

///|
test "root focus and textarea cursor decoders require exact Int32 values" {
  let focus = root_decoder_payload({
    "value": Json::string("moon"),
    "height": Json::number(2147483647.0, repr="2147483647"),
  })
  match detail_focus(focus) {
    Ok(detail) => {
      assert_eq(detail.value, "moon")
      assert_eq(detail.height, 2147483647)
    }
    Err(_) => fail("Int32Max focus height must decode")
  }
  let blur = root_decoder_payload({
    "value": Json::string("moon"),
    "cursor": Json::number(0.0, repr="0"),
  })
  match detail_textarea_blur(blur) {
    Ok(detail) => {
      assert_eq(detail.value, "moon")
      assert_eq(detail.cursor, 0)
    }
    Err(_) => fail("zero textarea cursor must decode")
  }
  for field in ["height", "cursor"] {
    for
      invalid in [
        Json::number(-1.0, repr="-1"),
        Json::number(1.5, repr="1.5"),
        Json::number(2147483648.0, repr="2147483648"),
        Json::string("1"),
      ] {
      let fields : Map[String, Json] = { "value": Json::string("moon") }
      fields[field] = invalid
      let payload = root_decoder_payload(fields)
      if field == "height" {
        assert_true(detail_focus(payload) is Err(_))
      } else {
        assert_true(detail_textarea_blur(payload) is Err(_))
      }
    }
    let missing = root_decoder_payload({ "value": Json::string("moon") })
    if field == "height" {
      assert_true(detail_focus(missing) is Err(_))
    } else {
      assert_true(detail_textarea_blur(missing) is Err(_))
    }
  }
}

///|
#cfg(target="js")
fn assert_internal_delay(command : @val.Cmd) -> Unit raise {
  match command {
    @val.CmdHostEffect(capability, payload, _) => {
      assert_eq(capability, "minimoon.timeout")
      assert_eq(payload, "{\"ms\":0}")
    }
    _ => fail("JavaScript delay must use the owned host timer")
  }
}

///|
#cfg(not(target="js"))
fn assert_internal_delay(command : @val.Cmd) -> Unit raise {
  assert_true(command is @val.CmdEffect(_))
}

///|
test "root command combinators preserve batches and delays" {
  let delayed = delay(none, 0)
  assert_internal_delay(delayed.0)
  match batch([none, delayed]).0 {
    @val.CmdBatch(commands) => assert_eq(commands.length(), 2)
    _ => fail("batch must preserve its child commands")
  }
  let (model, commands) = with_cmds("model", [none, delayed])
  assert_eq(model, "model")
  match commands.0 {
    @val.CmdBatch(commands) => {
      assert_eq(commands.length(), 2)
      assert_true(commands[0] is @val.CmdNone)
      assert_internal_delay(commands[1])
    }
    _ => fail("with_cmds must preserve its model and command batch")
  }
}

///|
test "top-level login command decodes success and normalizes host errors" {
  let received : Ref[Result[LoginResult, HostError]?] = Ref(None)
  match login(test_send(received)).0 {
    @val.CmdHostEffect(capability, payload, resolve) => {
      assert_eq(capability, "wx.login")
      assert_eq(payload, "{}")
      let _ = resolve(@val.HostOk("{\"code\":\"moon-code\"}"))
      match received.val {
        Some(Ok(result)) => assert_eq(result.code, "moon-code")
        _ => fail("login success was not emitted")
      }
      let _ = resolve(
        @val.HostErr("unavailable", "login unavailable", "{\"errCode\":7}"),
      )
      match received.val {
        Some(Err(error)) => {
          assert_eq(error.capability, Login)
          assert_eq(error.kind, Unavailable)
          assert_eq(error.message, "login unavailable")
          assert_eq(error.code, Some("7"))
        }
        _ => fail("login error was not emitted")
      }
    }
    _ => fail("login must produce a host effect")
  }
}

///|
test "top-level storage and request commands preserve typed payloads" {
  let storage : Ref[Result[StorageResult, HostError]?] = Ref(None)
  match get_storage("session", test_send(storage)).0 {
    @val.CmdHostEffect(capability, payload, _) => {
      assert_eq(capability, "wx.getStorage")
      assert_true(payload.contains("\"key\":\"session\""))
    }
    _ => fail("get_storage must produce a host effect")
  }
  let saved : Ref[Result[Unit, HostError]?] = Ref(None)
  match set_storage("session", Json::string("value"), test_send(saved)).0 {
    @val.CmdHostEffect(capability, payload, resolve) => {
      assert_eq(capability, "wx.setStorage")
      assert_true(payload.contains("\"key\":\"session\""))
      assert_true(payload.contains("\"value\""))
      let _ = resolve(@val.HostOk("{}"))
      assert_true(saved.val is Some(Ok(_)))
    }
    _ => fail("set_storage must produce a host effect")
  }
  let requested : Ref[Result[RequestResult, HostError]?] = Ref(None)
  match request("https://example.test/data", test_send(requested)).0 {
    @val.CmdHostEffect(capability, payload, _) => {
      assert_eq(capability, "wx.request")
      assert_true(payload.contains("https://example.test/data"))
    }
    _ => fail("request must produce a host effect")
  }
}

///|
test "top-level device commands expose every declared capability" {
  let unit_result : Ref[Result[Unit, HostError]?] = Ref(None)
  match show_toast("ready", test_send(unit_result)).0 {
    @val.CmdHostEffect(capability, payload, _) => {
      assert_eq(capability, "wx.showToast")
      assert_true(payload.contains("\"title\":\"ready\""))
    }
    _ => fail("show_toast must produce a host effect")
  }
  let location : Ref[Result[LocationResult, HostError]?] = Ref(None)
  match get_location(test_send(location)).0 {
    @val.CmdHostEffect(capability, _, _) =>
      assert_eq(capability, "wx.getLocation")
    _ => fail("get_location must produce a host effect")
  }
  let media : Ref[Result[ChooseMediaResult, HostError]?] = Ref(None)
  match choose_media(test_send(media)).0 {
    @val.CmdHostEffect(capability, _, _) =>
      assert_eq(capability, "wx.chooseMedia")
    _ => fail("choose_media must produce a host effect")
  }
  let payment = PaymentParams::new(
    time_stamp="1",
    nonce_str="nonce",
    package_value="prepay_id=1",
    sign_type="RSA",
    pay_sign="signature",
  )
  match request_payment(payment, test_send(unit_result)).0 {
    @val.CmdHostEffect(capability, payload, _) => {
      assert_eq(capability, "wx.requestPayment")
      assert_true(payload.contains("prepay_id=1"))
      assert_true(payload.contains("signature"))
    }
    _ => fail("request_payment must produce a host effect")
  }
}

///|
test "top-level navigation commands preserve route and fallback semantics" {
  let target = route("pages/details/details").with_query([query("from", "home")])
  match navigate_to(target).0 {
    @val.CmdNavigateTo(url) =>
      assert_eq(url, "/pages/details/details?from=home")
    _ => fail("navigate_to must produce navigation")
  }
  match redirect_to(target).0 {
    @val.CmdRedirectTo(url) =>
      assert_eq(url, "/pages/details/details?from=home")
    _ => fail("redirect_to must produce redirection")
  }
  match navigate_back(delta=2).0 {
    @val.CmdNavigateBack(delta) => assert_eq(delta, 2)
    _ => fail("navigate_back must preserve delta")
  }
  match navigate_back_or(fallback=target, delta=3).0 {
    @val.CmdNavigateBackOrRedirect(delta, fallback) => {
      assert_eq(delta, 3)
      assert_eq(fallback, "/pages/details/details?from=home")
    }
    _ => fail("navigate_back_or must preserve fallback")
  }
}

///|
test "root-owned routes validate and percent-encode ordered query values" {
  let target = route("pages/details/details").with_query([
    query("from", "counter value"),
    query("name", "月兔"),
    query("from", "again"),
  ])
  assert_eq(
    target.url(),
    "/pages/details/details?from=counter%20value&name=%E6%9C%88%E5%85%94&from=again",
  )
}

///|
test "root-owned host decoders reject malformed success payloads" {
  let received : Ref[Result[LocationResult, HostError]?] = Ref(None)
  match get_location(test_send(received)).0 {
    @val.CmdHostEffect(_, _, resolve) => {
      let _ = resolve(@val.HostOk("{\"latitude\":31.2}"))
      match received.val {
        Some(Err(error)) => assert_true(error.kind is InvalidPayload)
        _ => fail("missing longitude must be rejected")
      }
      let _ = resolve(@val.HostOk("not-json"))
      match received.val {
        Some(Err(error)) => assert_true(error.kind is InvalidPayload)
        _ => fail("invalid JSON must be rejected")
      }
    }
    _ => fail("get_location must produce a host effect")
  }
}

///|
test "root-owned request decoder preserves headers cookies and data" {
  let received : Ref[Result[RequestResult, HostError]?] = Ref(None)
  match request("https://example.test", test_send(received)).0 {
    @val.CmdHostEffect(_, _, resolve) => {
      let _ = resolve(
        @val.HostOk(
          "{\"statusCode\":201,\"data\":{\"ok\":true},\"header\":{\"x-id\":\"moon\",\"count\":2},\"cookies\":[\"a=1\",3,\"b=2\"]}",
        ),
      )
      match received.val {
        Some(Ok(result)) => {
          assert_eq(result.status_code, 201)
          assert_eq(result.headers.get("x-id"), Some("moon"))
          assert_eq(result.headers.get("count"), Some("2"))
          assert_eq(result.cookies, ["a=1", "b=2"])
          assert_eq(result.data.stringify(), "{\"ok\":true}")
        }
        _ => fail("request result must decode")
      }
      let _ = resolve(@val.HostOk("{\"data\":null}"))
      match received.val {
        Some(Err(error)) => assert_true(error.kind is InvalidPayload)
        _ => fail("missing statusCode must be rejected")
      }
      let _ = resolve(@val.HostOk("{\"statusCode\":2147483647,\"data\":null}"))
      match received.val {
        Some(Ok(result)) => assert_eq(result.status_code, 2147483647)
        _ => fail("Int32Max statusCode must decode")
      }
      for
        invalid in [
          "{\"statusCode\":-1}", "{\"statusCode\":200.5}", "{\"statusCode\":2147483648}",
          "{\"statusCode\":\"200\"}",
        ] {
        let _ = resolve(@val.HostOk(invalid))
        match received.val {
          Some(Err(error)) => assert_true(error.kind is InvalidPayload)
          _ => fail("invalid statusCode must be rejected")
        }
      }
    }
    _ => fail("request must produce a host effect")
  }
}

///|
test "root-owned location and media decoders preserve optional fields" {
  let location_result : Ref[Result[LocationResult, HostError]?] = Ref(None)
  match get_location(test_send(location_result)).0 {
    @val.CmdHostEffect(_, _, resolve) => {
      let _ = resolve(
        @val.HostOk(
          "{\"latitude\":31.2,\"longitude\":121.5,\"speed\":2.5,\"verticalAccuracy\":3}",
        ),
      )
      match location_result.val {
        Some(Ok(result)) => {
          assert_eq(result.latitude, 31.2)
          assert_eq(result.longitude, 121.5)
          assert_eq(result.speed, Some(2.5))
          assert_eq(result.vertical_accuracy, Some(3.0))
        }
        _ => fail("location result must decode")
      }
    }
    _ => fail("get_location must produce a host effect")
  }
  let media_result : Ref[Result[ChooseMediaResult, HostError]?] = Ref(None)
  match choose_media(test_send(media_result)).0 {
    @val.CmdHostEffect(_, _, resolve) => {
      let _ = resolve(
        @val.HostOk(
          "{\"type\":\"image\",\"tempFiles\":[{\"tempFilePath\":\"/tmp/moon.png\",\"size\":0,\"width\":40,\"height\":2147483647}]}",
        ),
      )
      match media_result.val {
        Some(Ok(result)) => {
          assert_eq(result.media_type, Some("image"))
          assert_eq(result.temp_files[0].temp_file_path, "/tmp/moon.png")
          assert_eq(result.temp_files[0].size, Some(0))
          assert_eq(result.temp_files[0].width, Some(40))
          assert_eq(result.temp_files[0].height, Some(2147483647))
        }
        _ => fail("media result must decode")
      }
      let _ = resolve(
        @val.HostOk(
          "{\"tempFiles\":[{\"tempFilePath\":\"/tmp/optional.png\"}]}",
        ),
      )
      match media_result.val {
        Some(Ok(result)) => {
          assert_eq(result.temp_files[0].size, None)
          assert_eq(result.temp_files[0].width, None)
          assert_eq(result.temp_files[0].height, None)
        }
        _ => fail("missing optional media dimensions must decode")
      }
      let _ = resolve(@val.HostOk("{\"tempFiles\":[{\"size\":12}]}"))
      match media_result.val {
        Some(Err(error)) => assert_true(error.kind is InvalidPayload)
        _ => fail("malformed media file must be rejected")
      }
      for
        invalid in [
          "{\"tempFiles\":[{\"tempFilePath\":\"/tmp/moon.png\",\"size\":-1}]}", "{\"tempFiles\":[{\"tempFilePath\":\"/tmp/moon.png\",\"size\":12.5}]}",
          "{\"tempFiles\":[{\"tempFilePath\":\"/tmp/moon.png\",\"width\":2147483648}]}",
          "{\"tempFiles\":[{\"tempFilePath\":\"/tmp/moon.png\",\"height\":\"40\"}]}",
        ] {
        let _ = resolve(@val.HostOk(invalid))
        match media_result.val {
          Some(Err(error)) => assert_true(error.kind is InvalidPayload)
          _ => fail("invalid media integer field must be rejected")
        }
      }
    }
    _ => fail("choose_media must produce a host effect")
  }
}
