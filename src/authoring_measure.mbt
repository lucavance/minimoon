///|
/// A viewport-relative rectangle in logical pixels. A missing node yields None.
pub struct NodeRect {
  id : String
  left : Double
  top : Double
  right : Double
  bottom : Double
  width : Double
  height : Double
} derive(Eq, Debug)

///|
fn valid_measure_id(id : String) -> Bool {
  if id == "" {
    return false
  }
  for character in id.iter() {
    if !((character >= 'a' && character <= 'z') ||
      (character >= 'A' && character <= 'Z') ||
      (character >= '0' && character <= '9') ||
      character == '_' ||
      character == '-') {
      return false
    }
  }
  true
}

///|
fn decode_node_rect(value : Json) -> Result[NodeRect?, HostError] {
  if value is Null {
    return Ok(None)
  }
  let fields = match object_result(MeasureNodes, value) {
    Ok(fields) => fields
    Err(error) => return Err(error)
  }
  let id = match string_field(fields, "id") {
    Some(id) if valid_measure_id(id) => id
    _ =>
      return Err(
        invalid_payload(MeasureNodes, "measurement id is invalid", value),
      )
  }
  let numbers : Array[Double] = []
  for key in ["left", "top", "right", "bottom", "width", "height"] {
    match number_field(fields, key) {
      Some(number) if finite_number(number) => numbers.push(number)
      _ =>
        return Err(
          invalid_payload(
            MeasureNodes,
            "measurement coordinate is invalid: " + key,
            value,
          ),
        )
    }
  }
  if numbers[4] < 0.0 || numbers[5] < 0.0 {
    return Err(
      invalid_payload(
        MeasureNodes,
        "measurement dimensions are negative",
        value,
      ),
    )
  }
  Ok(
    Some({
      id,
      left: numbers[0],
      top: numbers[1],
      right: numbers[2],
      bottom: numbers[3],
      width: numbers[4],
      height: numbers[5],
    }),
  )
}

///|
fn decode_measurements(
  ids : Array[String],
  value : Json,
) -> Result[Array[NodeRect?], HostError] {
  let fields = match object_result(MeasureNodes, value) {
    Ok(fields) => fields
    Err(error) => return Err(error)
  }
  guard fields.get("nodes") is Some(Array(nodes)) &&
    nodes.length() == ids.length() else {
    return Err(
      invalid_payload(
        MeasureNodes,
        "measurement result must preserve the requested node count",
        value,
      ),
    )
  }
  let output : Array[NodeRect?] = []
  for index, node in nodes {
    match decode_node_rect(node) {
      Ok(rect) => {
        if rect is Some(rect) && rect.id != ids[index] {
          return Err(
            invalid_payload(
              MeasureNodes,
              "measurement result id does not match the request",
              value,
            ),
          )
        }
        output.push(rect)
      }
      Err(error) => return Err(error)
    }
  }
  Ok(output)
}

///|
/// Measure at most 128 page-local IDs after the pending render has been acknowledged.
/// IDs are identifiers, never CSS selectors. Declare `MeasureNodes` on the page.
pub fn measure_nodes(
  ids : Array[String],
  resolve : Emit[Result[Array[NodeRect?], HostError]],
) -> Cmd {
  guard ids.length() <= 128 else {
    abort("measure_nodes accepts at most 128 IDs")
  }
  let seen : Set[String] = Set([])
  let requested : Array[String] = []
  for id in ids {
    guard valid_measure_id(id) && !seen.contains(id) else {
      abort(
        "measure_nodes requires unique nonempty alphanumeric, underscore or hyphen IDs",
      )
    }
    seen.add(id)
    requested.push(id)
  }
  host_effect(
    MeasureNodes,
    Json::object({ "ids": Json::array(requested.map(Json::string)) }),
    value => decode_measurements(requested, value),
    resolve,
  )
}
