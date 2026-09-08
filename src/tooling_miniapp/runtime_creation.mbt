///|
/// Runtime ABI 12 never publishes an instance before route decoding succeeds.
fn runtime_creation_helpers() -> String {
  let source =
    #|///|
    #|fn minimoon_creation_error(message : String) -> String {
    #|  Json::object({ "ok": Json::boolean(false), "error": Json::object({ "code": Json::string("page_input_decode_failed"), "message": Json::string(message) }) }).stringify()
    #|}
    #|
    #|///|
    #|fn minimoon_decode_input(raw : String) -> Result[Map[String, String], @minimoon.DecodeError] {
    #|  let value = try @json.parse(raw) catch { _ => return Err(@minimoon.decode_error("page input must be a JSON object")) }
    #|  guard value is Object(fields) else { return Err(@minimoon.decode_error("page input must be a JSON object")) }
    #|  let input : Map[String, String] = Map([])
    #|  for key, value in fields {
    #|    guard value is String(text) else { return Err(@minimoon.decode_error("page input values must be strings: " + key)) }
    #|    input[key] = text
    #|  }
    #|  Ok(input)
    #|}
    #|
    #|///|
    #|fn minimoon_register_page(page_id : String, result : Result[@minimoon.PageRuntime, @minimoon.DecodeError]) -> String {
    #|  match result {
    #|    Err(error) => minimoon_creation_error(error.message())
    #|    Ok(runtime) => {
    #|      minimoon_next_instance_id.val += 1
    #|      let id = page_id + ":" + minimoon_next_instance_id.val.to_string()
    #|      minimoon_instances[id] = runtime
    #|      Json::object({ "ok": Json::boolean(true), "id": Json::string(id) }).stringify()
    #|    }
    #|  }
    #|}
  source + "\n\n"
}
