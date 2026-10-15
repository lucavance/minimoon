///|
test "RUI inventory rejects omissions duplicates unknown symbols and changed signatures" {
  let expected : Map[String, String] = {
    "root:button": "pub fn button() -> Node",
  }
  let entry : Json = {
    "package": "root",
    "symbol": "button",
    "signature": "pub fn button() -> Node",
  }
  assert_true(rui_inventory_violations(expected, [entry]).is_empty())
  assert_false(rui_inventory_violations(expected, []).is_empty())
  assert_false(rui_inventory_violations(expected, [entry, entry]).is_empty())
  assert_false(
    rui_inventory_violations(expected, [
      { "package": "root", "symbol": "button", "signature": "changed" },
    ]).is_empty(),
  )
  assert_false(
    rui_inventory_violations(expected, [
      { "package": "root", "symbol": "unknown", "signature": "changed" },
    ]).is_empty(),
  )
  assert_eq(
    rui_symbol("pub fn[A : Eq] Size::equal(A, A) -> Bool"),
    Some("Size::equal"),
  )
  assert_eq(rui_symbol("type Hidden"), Some("Hidden"))
}
