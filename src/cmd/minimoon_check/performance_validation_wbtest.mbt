///|
test "performance observations require every unique scenario and valid drain accounting" {
  let values : Array[Json] = []
  for nodes in [100, 500, 2000] {
    values.push(
      Json::object({
        "scenario": Json::string("page-update"),
        "nodes": Json::number(nodes.to_double()),
        "summaries": Json::array([
          Json::object({
            "mean": Json::number(1.0e12),
            "std_dev": Json::number(0),
            "runs": Json::number(10),
          }),
        ]),
      }),
    )
  }
  for messages in [100, 3000, 10000] {
    for pages in [1, 4] {
      values.push(
        Json::object({
          "scenario": Json::string("application-queue"),
          "messages": Json::number(messages.to_double()),
          "pages": Json::number(pages.to_double()),
          "samples": Json::number(10),
          "drains": Json::number(((messages + 2047) / 2048 * 10).to_double()),
          "enqueueUs": Json::number(1.0e12),
          "drainUs": Json::number(0),
          "projectionUs": Json::number(1),
        }),
      )
    }
  }
  validate_performance_observations(values)
  let rejects = fn(input : Array[Json]) -> Bool {
    try {
      validate_performance_observations(input)
      false
    } catch {
      _ => true
    }
  }
  assert_true(rejects([]))
  let duplicate = values.copy()
  duplicate[0] = duplicate[1]
  assert_true(rejects(duplicate))
  let invalid = values.copy()
  invalid[8] = Json::object({
    "scenario": Json::string("application-queue"),
    "messages": Json::number(10000),
    "pages": Json::number(4),
    "samples": Json::number(10),
    "drains": Json::number(49),
  })
  assert_true(rejects(invalid))
  for
    bad in [
      Json::null(),
      Json::string("1"),
      Json::number(-1),
      Json::number(@double.infinity),
    ] {
    assert_true(
      try {
        ignore(performance_number(Json::object({ "time": bad }), "time"))
        false
      } catch {
        _ => true
      },
    )
  }
}
