///|
test "MiniApp dynamic classes match weapp-tailwindcss escaping" {
  assert_eq(escape_miniapp_class_token("min-h-[100vh]"), "min-h-_b100vh_B")
  assert_eq(escape_miniapp_class_token("hover:bg-red-500"), "hover_cbg-red-500")
  assert_eq(escape_miniapp_class_token("w-1/2"), "w-1_f2")
  assert_eq(escape_miniapp_class_token("text-[#fff]"), "text-_b_hfff_B")
  assert_eq(escape_miniapp_class_token("-mt-[1.5px]"), "-mt-_b1_d5px_B")
  assert_eq(escape_miniapp_class_token("sm:flex"), "sm_cflex")
  assert_eq(escape_miniapp_class_token("foo_bar"), "foo_bar")
  assert_eq(escape_miniapp_class_token("2xl:flex"), "_2xl_cflex")
  assert_eq(escape_miniapp_class_token("-1"), "_-1")
  assert_eq(escape_miniapp_class_token("中"), "u_x4e2d_")
}

///|
test "MiniApp class lists normalize host whitespace once" {
  assert_eq(
    escape_miniapp_class_name(" min-h-[100vh]\n  hover:bg-red-500\tfoo_bar "),
    "min-h-_b100vh_B hover_cbg-red-500 foo_bar",
  )
}
