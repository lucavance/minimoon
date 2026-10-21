///|
test "API accepts builtin Int spelling but rejects changed integer widths" {
  let before = "pub fn f(Int, value? : Array[Int]) -> (Int, Int?)\n\npub struct S {\n  value : Int\n}\n"
  let after = before.replace_all(old="Int", new="Int32")
  assert_true(api_compatibility_violations(before, after, true).is_empty())
  for changed in ["UInt32", "Int64", "String"] {
    assert_false(
      api_compatibility_violations(
        before,
        before.replace_all(old="Int", new=changed),
        true,
      ).is_empty(),
    )
  }
}

///|
test "API alias comparison preserves user names bindings and literal values" {
  for
    before in [
      "pub fn f(@other.Int) -> Unit\n", "pub enum E { Int(Int) }\n", "pub struct Int { value : String }\npub fn f(Int) -> Unit\n",
      "pub enum E { First, Int }\n", "pub struct Box[Int] { value : Int }\n", "pub fn[Int] f(Int) -> Int\n",
      "pub const NAME : String = \"Int\"\n", "pub fn f(MyInt) -> Unit\n",
    ] {
    let after = before.replace_all(old="Int", new="Int32")
    assert_false(
      api_compatibility_violations(before, after, true).is_empty(),
      msg=before,
    )
  }
}
