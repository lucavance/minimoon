///|
test "Vega themes expose stable colors and direction without browser color syntax" {
  let light = @theme.theme()
  let dark = @theme.theme(mode=Dark, direction=Rtl)
  assert_true(light.class_name().contains("mmui-light mmui-ltr"))
  assert_true(dark.class_name().contains("mmui-dark mmui-rtl"))
  assert_true(light.style().contains("--mmui-background:#ffffff;"))
  assert_true(dark.style().contains("--mmui-background:#171717;"))
  assert_true(
    @theme.theme(tokens={ ..@theme.tokens(), radius: 4, })
    .style()
    .contains("--mmui-radius:4px;"),
  )
  assert_eq(@theme.tokens(mode=Dark).foreground, "#fafafa")
}
