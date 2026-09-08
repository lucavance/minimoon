// Builder API adapted from moonbit-community/rabbita (eccae7507360aec8465469bafb7fb4da5b260a2a), Apache-2.0.
// Modified by Minimoon: delegate to owned wx.request commands, snapshot inputs,
// preserve host/status errors, and decode the host's existing Json value.

///|
priv struct RequestOptions {
  url : String
  http_method : @minimoon.HttpMethod
  query : Array[@minimoon.Query]
  headers : Map[String, String]
  timeout_ms : Int?
}

///|
/// An immutable request builder. Finish it with `expect_json` to obtain a Cmd.
struct Request(RequestOptions, @minimoon.RequestBody?)

///|
/// A POST or PUT builder, with an optional JSON or text body.
struct RequestWithBody(RequestOptions)

///|
/// HTTP policy errors preserve the complete raw request result or host error.
/// JSON decoding failures remain `@json.JsonDecodeError`, not `HttpError`.
pub(all) suberror HttpError {
  RequestError(@minimoon.HostError)
  BadStatus(@minimoon.RequestResult)
}

///|
pub impl Show for HttpError with fn output(self, buffer) {
  match self {
    RequestError(error) =>
      buffer.write_string("HTTP request failed: " + error.message)
    BadStatus(response) =>
      buffer.write_string("HTTP status " + response.status_code.to_string())
  }
}

///|
fn options(
  url : String,
  http_method : @minimoon.HttpMethod,
  query : Array[@minimoon.Query],
  headers : Map[String, String],
  timeout_ms : Int?,
) -> RequestOptions {
  {
    url,
    http_method,
    query: query.copy(),
    headers: headers.copy(),
    timeout_ms,
  }
}

///|
/// Construct a GET request and snapshot its query and headers.
/// URLs and request options follow the root `request` HTTPS validation rules.
pub fn get(
  url : String,
  query? : Array[@minimoon.Query] = [],
  headers? : Map[String, String] = Map([]),
  timeout_ms? : Int,
) -> Request {
  Request(options(url, Get, query, headers, timeout_ms), None)
}

///|
/// Construct a bodyless DELETE request, snapshotting its query and headers.
pub fn delete(
  url : String,
  query? : Array[@minimoon.Query] = [],
  headers? : Map[String, String] = Map([]),
  timeout_ms? : Int,
) -> Request {
  Request(options(url, Delete, query, headers, timeout_ms), None)
}

///|
/// Construct a POST request. A body is optional before `expect_json`.
pub fn post(
  url : String,
  query? : Array[@minimoon.Query] = [],
  headers? : Map[String, String] = Map([]),
  timeout_ms? : Int,
) -> RequestWithBody {
  RequestWithBody(options(url, Post, query, headers, timeout_ms))
}

///|
/// Construct a PUT request. A body is optional before `expect_json`.
pub fn put(
  url : String,
  query? : Array[@minimoon.Query] = [],
  headers? : Map[String, String] = Map([]),
  timeout_ms? : Int,
) -> RequestWithBody {
  RequestWithBody(options(url, Put, query, headers, timeout_ms))
}

///|
fn snapshot_json(value : Json) -> Json {
  match value {
    Array(values) => Json::array(values.map(snapshot_json))
    Object(fields) => {
      let copy : Map[String, Json] = Map([])
      for key, value in fields {
        copy[key] = snapshot_json(value)
      }
      Json::object(copy)
    }
    value => value
  }
}

///|
/// Encode and snapshot a JSON body now, including nested mutable JSON values.
pub fn[T : ToJson] RequestWithBody::with_json(
  self : RequestWithBody,
  value : T,
) -> Request {
  Request(self.0, Some(JsonBody(snapshot_json(value.to_json()))))
}

///|
/// Attach a text body; the root request supplies its default content type.
pub fn RequestWithBody::with_text(
  self : RequestWithBody,
  value : String,
) -> Request {
  Request(self.0, Some(TextBody(value)))
}

///|
/// Decode an already parsed host JSON value on a 2xx response. Non-2xx status
/// takes precedence over decoding. Validation and delivery remain deferred
/// to the root command's owner; do not discard the returned command.
pub fn[T : @json.FromJson] Request::expect_json(
  self : Request,
  resolve : @minimoon.Emit[Result[T, Error]],
) -> @minimoon.Cmd {
  let options = self.0
  @minimoon.request(
    options.url,
    result => {
      match result {
        Err(error) => resolve(Err(RequestError(error)))
        Ok(response) => {
          if response.status_code < 200 || response.status_code >= 300 {
            return resolve(Err(BadStatus(response)))
          }
          let decoded : Result[T, Error] = try
            @json.from_json(response.data)
          catch {
            error => Err(error)
          } noraise {
            value => Ok(value)
          }
          resolve(decoded)
        }
      }
    },
    http_method=options.http_method,
    query=options.query,
    headers=options.headers,
    body?=self.1,
    timeout_ms?=options.timeout_ms,
  )
}

///|
/// Finish a POST or PUT without a request body.
pub fn[T : @json.FromJson] RequestWithBody::expect_json(
  self : RequestWithBody,
  resolve : @minimoon.Emit[Result[T, Error]],
) -> @minimoon.Cmd {
  Request(self.0, None).expect_json(resolve)
}
