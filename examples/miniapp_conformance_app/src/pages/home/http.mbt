///|
fn http_cases() -> Array[String] {
  [
    "GET query", "POST JSON", "POST form", "PUT text", "DELETE", "HEAD", "OPTIONS",
    "HTTP 400", "HTTP 500", "Timeout",
  ]
}

///|
fn http_case(
  index : Int,
  base : String,
  resolve : @minimoon.Emit[Result[@minimoon.RequestResult, @minimoon.HostError]],
) -> @minimoon.Cmd {
  let headers = { "X-Minimoon-Test": "public-smoke" }
  match index {
    1 =>
      @minimoon.request(
        base + "/post",
        resolve,
        http_method=Post,
        headers~,
        body=JsonBody(
          Json::object({
            "message": Json::string("Minimoon 测试"),
            "count": (2).to_json(),
          }),
        ),
        timeout_ms=15000,
      )
    2 =>
      @minimoon.request(
        base + "/post",
        resolve,
        http_method=Post,
        headers~,
        body=FormBody([
          ("message", "测试 +&="),
          ("tag", "one"),
          ("tag", "two"),
        ]),
        timeout_ms=15000,
      )
    3 =>
      @minimoon.request(
        base + "/put",
        resolve,
        http_method=Put,
        headers~,
        body=TextBody("Minimoon 测试 +&="),
        timeout_ms=15000,
      )
    4 =>
      @minimoon.request(
        base + "/delete",
        resolve,
        http_method=Delete,
        query=[@minimoon.query("id", "synthetic")],
        headers~,
        timeout_ms=15000,
      )
    5 =>
      @minimoon.request(
        base + "/get",
        resolve,
        http_method=Head,
        headers~,
        timeout_ms=15000,
      )
    6 =>
      @minimoon.request(
        base + "/anything",
        resolve,
        http_method=Options,
        headers~,
        timeout_ms=15000,
      )
    7 =>
      @minimoon.request(
        base + "/status/400",
        resolve,
        headers~,
        timeout_ms=15000,
      )
    8 =>
      @minimoon.request(
        base + "/status/500",
        resolve,
        headers~,
        timeout_ms=15000,
      )
    9 => @minimoon.request(base + "/delay/3", resolve, headers~, timeout_ms=500)
    _ =>
      @minimoon.request(
        base + "/get?existing=yes",
        resolve,
        query=[
          @minimoon.query("message", "Minimoon 测试 +&="),
          @minimoon.query("tag", "one"),
          @minimoon.query("tag", "two"),
        ],
        headers~,
        timeout_ms=15000,
      )
  }
}

///|
// Display only synthetic echo fields, not IP addresses, cookies or all headers.
fn http_summary(response : @minimoon.RequestResult) -> String {
  let selected : Map[String, Json] = Map([])
  let echoed_headers : Map[String, Json] = Map([])
  match response.data {
    Object(fields) =>
      for key in ["method", "args", "json", "form", "data"] {
        if fields.get(key) is Some(value) {
          selected[key] = value
        }
      }
    value => selected["data"] = value
  }
  match response.data {
    Object(fields) =>
      match fields.get("headers") {
        Some(Object(headers)) =>
          for name, value in headers {
            if name == "Content-Type" ||
              name == "content-type" ||
              name == "X-Minimoon-Test" ||
              name == "x-minimoon-test" {
              echoed_headers[name] = value
            }
          }
        _ => ()
      }
    _ => ()
  }
  selected["request-headers"] = Json::object(echoed_headers)
  selected["response-content-type"] = Json::string(
    response.headers.get("content-type").unwrap_or(""),
  )
  Json::object(selected).stringify()
}
