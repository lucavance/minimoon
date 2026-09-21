// Added beside the frozen consumer, without modifying its historical source.
///|
pub extend Echo with @json.FromJson::{from_json}

///|
pub fn status_method_compatibility(
  status : @minimoon.Status[Int],
) -> (Bool, Bool, String) {
  (status.equal(status), status.not_equal(status), status.tag())
}

///|
pub fn http_error_method_compatibility(error : @http.HttpError) -> String {
  error.to_string()
}

///|
test "historical trait methods remain callable by an external consumer" {
  let node = @minimoon.text("compatible")
  assert_true(node.equal(node))
  assert_eq(node.to_nodes().length(), 1)
  let rect : @minimoon.LayoutRect = {
    left: 1.0,
    top: 2.0,
    width: 3.0,
    height: 4.0,
  }
  assert_eq(rect.to_json(), ToJson::to_json(rect))
  let _ = rect.to_repr()
  let decoded : Echo = @json.from_json({ "url": "https://example.com" })
  assert_eq(decoded.url, "https://example.com")
}
