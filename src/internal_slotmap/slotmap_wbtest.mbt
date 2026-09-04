///|
test "freed slots advance generation and reject stale identifiers" {
  let slots : SlotMap[String] = SlotMap()
  let stale = slots.allocate_with(_ => "old")
  assert_eq(slots.get(stale), Some("old"))
  slots.free(stale)
  assert_eq(slots.get(stale), None)

  let replacement = slots.allocate_with(_ => "new")
  assert_eq(replacement.idx, stale.idx)
  assert_true(replacement.gen != stale.gen)
  assert_eq(slots.get(stale), None)
  assert_eq(slots.get(replacement), Some("new"))

  let reset : SlotMap[String] = SlotMap()
  assert_eq(reset.get(replacement), None)
}
