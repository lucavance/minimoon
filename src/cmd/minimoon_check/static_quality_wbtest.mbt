///|
test "JS extern signature boundary rejects mutable and readonly arrays" {
  let mutable = moon_source_boundary_violations(
    "extern \"js\" fn unsafe(values : Array[String]) -> Unit = \"unsafe\"\n",
  )
  assert_eq(mutable.length(), 1)
  assert_true(mutable[0].contains("not Array[T]"))
  assert_eq(
    moon_source_boundary_violations(
      "extern \"js\" fn[T](values : Array[T]) -> Unit = \"unsafe\"\n",
    ).length(),
    1,
  )
  assert_eq(
    moon_source_boundary_violations(
      (
        #|pub extern "js" fn unsafe(
        #|  values : Array [String],
        #|) -> Unit = "unsafe"
        #|
      ),
    ).length(),
    1,
  )
  assert_eq(
    moon_source_boundary_violations(
      "pub(all) extern \"js\" fn unsafe(values : ReadOnlyArray[String]) -> Unit = \"unsafe\"\n",
    ).length(),
    1,
  )
  let readonly_violations = moon_source_boundary_violations(
    (
      #|extern "js" fn unsafe(
      #|  values : ReadOnlyArray[String],
      #|) -> Unit = "unsafe"
      #|
    ),
  )
  assert_eq(readonly_violations.length(), 1)
  assert_true(readonly_violations[0].contains("not ReadOnlyArray[T]"))
}

///|
test "JS extern signature boundary allows FixedArray and ignores function bodies" {
  assert_true(
    moon_source_boundary_violations(
      "extern \"js\" fn safe(values : FixedArray[String]) -> Unit = \"Array[body]\"\n",
    ).is_empty(),
  )
  assert_true(
    moon_source_boundary_violations(
      "pub extern \"js\" fn safe(values : FixedArray [String]) -> Unit = \"safe\"\n",
    ).is_empty(),
  )
  assert_true(
    moon_source_boundary_violations(
      "fn ordinary(values : Array[String]) -> Array[String] { values }\n",
    ).is_empty(),
  )
}

///|
test "Moon source boundary rejects the deprecated StringBuilder constructor" {
  let deprecated = "let builder = StringBuilder::" + "new()\n"
  let violations = moon_source_boundary_violations(deprecated)
  assert_eq(violations.length(), 1)
  assert_true(violations[0].contains("StringBuilder"))
}
