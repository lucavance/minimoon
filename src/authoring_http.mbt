///|
pub struct RequestResult {
  status_code : Int
  data : Json
  headers : Map[String, String]
  cookies : Array[String]
}

///|
fn headers(fields : Map[String, Json]) -> Map[String, String] {
  let output : Map[String, String] = Map([])
  match fields.get("header") {
    Some(Object(values)) =>
      for name, value in values {
        output[name] = match value {
          String(value) => value
          value => value.stringify()
        }
      }
    _ => ()
  }
  output
}

///|
fn cookies(fields : Map[String, Json]) -> Array[String] {
  match fields.get("cookies") {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(value) => Some(value)
          _ => None
        }
      })
    _ => []
  }
}

///|
fn decode_request(value : Json) -> Result[RequestResult, HostError] {
  let capability = Request
  match object_result(capability, value) {
    Err(error) => Err(error)
    Ok(fields) =>
      match fields.get("statusCode") {
        Some(Number(status, ..)) =>
          match host_int32(status) {
            Some(status_code) =>
              Ok({
                status_code,
                data: fields.get("data").unwrap_or(Json::null()),
                headers: headers(fields),
                cookies: cookies(fields),
              })
            None =>
              Err(
                invalid_payload(
                  capability, "wx.request result.statusCode must be an integer from 0 to 2147483647",
                  value,
                ),
              )
          }
        Some(_) =>
          Err(
            invalid_payload(
              capability, "wx.request result.statusCode must be an integer from 0 to 2147483647",
              value,
            ),
          )
        None =>
          Err(
            invalid_payload(
              capability, "wx.request result.statusCode is missing", value,
            ),
          )
      }
  }
}

///|
pub(all) enum HttpMethod {
  Get
  Post
  Put
  Delete
  Head
  Options
} derive(Debug, Eq)

///|
pub(all) enum RequestBody {
  JsonBody(Json)
  FormBody(Array[(String, String)])
  TextBody(String)
}

///|
fn HttpMethod::wire(self : HttpMethod) -> String {
  match self {
    Get => "GET"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Head => "HEAD"
    Options => "OPTIONS"
  }
}

///|
fn http_lower(value : String) -> String {
  value.iter().map(c => c.to_ascii_lowercase().to_string()).to_array().join("")
}

///|
fn http_port_valid(port : StringView) -> Bool {
  if port.is_empty() {
    return false
  }
  let mut value = 0
  for c in port {
    if c < '0' || c > '9' {
      return false
    }
    value = value * 10 + c.to_int() - 48
    if value > 65535 {
      return false
    }
  }
  value > 0
}

///|
fn http_url_valid(url : String) -> Bool {
  if !url.has_prefix("https://") || url.contains("#") {
    return false
  }
  for c in url {
    if c <= ' ' || c == '\u{7f}' || c == '\\' {
      return false
    }
  }
  let authority = url[8:]
    .split("/")
    .next()
    .unwrap()
    .split("?")
    .next()
    .unwrap()
    .to_owned()
  if authority == "" || authority.contains("@") {
    return false
  }
  // Require a host; leave DNS resolution and TLS verification to wx.request.
  if authority.has_prefix(":") || authority.has_suffix(":") {
    return false
  }
  if !authority.has_prefix("[") {
    let parts = authority.split(":").to_array()
    if parts.length() > 2 {
      return false
    }
    if parts.length() == 2 {
      if !http_port_valid(parts[1]) {
        return false
      }
    }
    if authority.contains("[") || authority.contains("]") {
      return false
    }
  } else {
    guard authority.split_once("]") is Some((host, suffix)) else {
      return false
    }
    if !host.contains(":") || host.contains(":::") {
      return false
    }
    for c in host[1:] {
      if !((c >= '0' && c <= '9') ||
        (c >= 'a' && c <= 'f') ||
        (c >= 'A' && c <= 'F') ||
        c == ':' ||
        c == '.') {
        return false
      }
    }
    if suffix != "" && (!suffix.has_prefix(":") || !http_port_valid(suffix[1:])) {
      return false
    }
  }
  for c in authority {
    if !((c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      "-.:[]".contains(c.to_string())) {
      return false
    }
  }
  true
}

///|
fn http_payload(
  url : String,
  verb : HttpMethod,
  query : Array[Query],
  headers : Map[String, String],
  body : RequestBody?,
  timeout_ms : Int?,
) -> Result[Json, String] {
  guard http_url_valid(url) else {
    return Err(
      "request requires an absolute HTTPS URL without credentials or fragment",
    )
  }
  if (verb == Get || verb == Head) && body is Some(_) {
    return Err("GET and HEAD requests cannot have a body")
  }
  if timeout_ms is Some(ms) && ms <= 0 {
    return Err("request timeout must be positive")
  }
  let normalized : Map[String, Json] = Map([])
  let names = headers.keys().to_array()
  names.sort()
  for name in names {
    let lower = http_lower(name)
    guard name != "" && lower != "referer" && !normalized.contains(lower) else {
      return Err("invalid, duplicate, or forbidden request header")
    }
    for c in name {
      guard (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        "!#$%&'*+-.^_`|~".contains(c.to_string()) else {
        return Err("invalid request header name")
      }
    }
    let value = headers[name]
    for c in value {
      if (c < ' ' && c != '\t') || c == '\u{7f}' {
        return Err("invalid request header value")
      }
    }
    normalized[lower] = Json::string(value)
  }
  let fields : Map[String, Json] = Map([])
  match body {
    Some(body) => {
      let (data, content_type) = match body {
        JsonBody(json) => (json.stringify(), "application/json")
        FormBody(pairs) =>
          (
            pairs
            .map(pair => percent_encode(pair.0) + "=" + percent_encode(pair.1))
            .join("&"),
            "application/x-www-form-urlencoded",
          )
        TextBody(text) => (text, "text/plain; charset=utf-8")
      }
      match normalized.get("content-type") {
        Some(String(value)) => {
          let media = http_lower(
            value.split(";").next().unwrap().trim().to_owned(),
          )
          let compatible = match body {
            JsonBody(_) =>
              media == "application/json" ||
              (
                media.has_prefix("application/") &&
                media.has_suffix("+json") &&
                media.length() > 17
              )
            FormBody(_) => media == "application/x-www-form-urlencoded"
            TextBody(_) => true
          }
          guard compatible else {
            return Err("request body conflicts with Content-Type")
          }
        }
        _ => normalized["content-type"] = Json::string(content_type)
      }
      fields["data"] = Json::string(data)
    }
    None => ()
  }
  let suffix = query
    .map(q => percent_encode(q.name) + "=" + percent_encode(q.value))
    .join("&")
  let separator = if url.contains("?") {
    if url.has_suffix("?") || url.has_suffix("&") {
      ""
    } else {
      "&"
    }
  } else {
    "?"
  }
  fields["url"] = Json::string(
    if suffix == "" {
      url
    } else {
      url + separator + suffix
    },
  )
  fields["method"] = Json::string(verb.wire())
  fields["header"] = Json::object(normalized)
  if timeout_ms is Some(ms) {
    fields["timeout"] = ms.to_json()
  }
  Ok(Json::object(fields))
}

///|
/// Encodes and snapshots arguments now; delivers validation errors only when run.
/// HTTP error status codes remain successful transport results.
pub fn request(
  url : String,
  resolve : Emit[Result[RequestResult, HostError]],
  http_method? : HttpMethod = Get,
  query? : Array[Query] = [],
  headers? : Map[String, String] = Map([]),
  body? : RequestBody,
  timeout_ms? : Int,
) -> Cmd {
  match http_payload(url, http_method, query, headers, body, timeout_ms) {
    Ok(payload) => host_effect(Request, payload, decode_request, resolve)
    Err(message) =>
      Cmd(
        @val.CmdMessage(() => {
          resolve(Err(invalid_payload(Request, message, Json::null()))).0
        }),
      )
  }
}
