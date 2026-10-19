///|
fn performance_number(value : Json, key : String) -> Double raise {
  guard value is Object(fields) &&
    fields.get(key) is Some(Number(number, ..)) &&
    number >= 0.0 &&
    number < @double.infinity else {
    raise Failure("invalid performance field: " + key)
  }
  number
}

///|
fn validate_performance_observations(values : Array[Json]) -> Unit raise {
  guard values.length() == 9 else {
    raise Failure("missing runtime performance scenarios")
  }
  let expected = [
    "page:100", "page:500", "page:2000", "queue:100:1", "queue:100:4", "queue:3000:1",
    "queue:3000:4", "queue:10000:1", "queue:10000:4",
  ]
  let seen : Array[String] = []
  for value in values {
    guard value is Object(fields) else {
      raise Failure("invalid performance observation")
    }
    let key = match fields.get("scenario") {
      Some(String("page-update")) => {
        let nodes = performance_number(value, "nodes")
        guard fields.get("summaries") is Some(Array([summary])) else {
          raise Failure("missing Page update benchmark summary")
        }
        ignore(performance_number(summary, "mean"))
        ignore(performance_number(summary, "std_dev"))
        guard performance_number(summary, "runs") > 0 else {
          raise Failure("empty benchmark")
        }
        "page:" + nodes.to_string()
      }
      Some(String("application-queue")) => {
        let messages = performance_number(value, "messages")
        let pages = performance_number(value, "pages")
        let samples = performance_number(value, "samples")
        let drains = performance_number(value, "drains")
        guard samples > 0 &&
          samples == samples.floor() &&
          drains == ((messages + 2047.0) / 2048.0).floor() * samples else {
          raise Failure("queue benchmark lost messages or drain observations")
        }
        for field in ["enqueueUs", "drainUs", "projectionUs"] {
          ignore(performance_number(value, field))
        }
        "queue:" + messages.to_string() + ":" + pages.to_string()
      }
      _ => raise Failure("unknown runtime performance scenario")
    }
    guard expected.contains(key) && !seen.contains(key) else {
      raise Failure("unexpected or duplicate performance scenario: " + key)
    }
    seen.push(key)
  }
}
