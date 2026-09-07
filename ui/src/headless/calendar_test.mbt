///|
test "Gregorian calendar handles leap days and bounded arithmetic" {
  assert_eq(calendar_date(year=2024, month=2, day=31).iso(), "2024-02-29")
  assert_eq(calendar_date(year=1900, month=2, day=29).iso(), "1900-02-28")
  assert_eq(
    calendar_date(year=2000, month=2, day=29).add_days(1).iso(),
    "2000-03-01",
  )
  assert_eq(
    calendar_date(year=2024, month=1, day=31).add_months(1).iso(),
    "2024-02-29",
  )
  assert_eq(
    calendar_date(year=1, month=1, day=1).add_days(-1).iso(),
    "0001-01-01",
  )
  assert_eq(
    calendar_date(year=9999, month=12, day=31).add_days(1).iso(),
    "9999-12-31",
  )
  assert_eq(calendar_date(year=2026, month=9, day=7).weekday(), 1)
}

///|
test "calendar multiple and range normalize reverse selections" {
  let early = calendar_date(year=2024, month=2, day=1)
  let late = calendar_date(year=2024, month=2, day=29)
  assert_eq(
    DateSelection::Range(None, None).choose(late).choose(early),
    Range(Some(early), Some(late)),
  )
  assert_true(
    DateSelection::Range(Some(early), Some(late)).contains(early.add_days(8)),
  )
  assert_eq(
    DateSelection::Multiple([]).choose(early).choose(early),
    Multiple([]),
  )
}

///|
test "floating placement flips and clamps while resize preserves other panes" {
  let anchor : Bounds = { left: 280.0, top: 580.0, width: 32.0, height: 20.0, }
  let surface : Bounds = { left: 0.0, top: 0.0, width: 180.0, height: 100.0, }
  let viewport : Bounds = { left: 0.0, top: 0.0, width: 320.0, height: 640.0, }
  let result = place(anchor, surface, viewport, BottomStart)
  assert_eq(result.left, 140.0)
  assert_eq(result.top, 472.0)
  assert_eq(
    resize_pair([25.0, 35.0, 40.0], 0, 99.0, [10.0, 20.0, 10.0], [
      80.0, 80.0, 80.0,
    ]),
    [40.0, 20.0, 40.0],
  )
  assert_eq(page_count(0, 0), 1)
  assert_eq(page_count(21, 10), 3)
}
