///|
priv struct ErasedProbe {
  label : String
  value : Int
}

///|
test "erased values round trip through their private typed boundary" {
  let erased = erase({ label: "minimoon", value: 7, })
  let restored : ErasedProbe = erased.into()
  assert_eq(restored.label, "minimoon")
  assert_eq(restored.value, 7)
}
