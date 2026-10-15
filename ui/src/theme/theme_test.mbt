///|
test "Nova default and explicit Vega themes preserve tokens and custom overrides" {
  let light = @theme.theme()
  let dark = @theme.theme(mode=Dark, direction=Rtl)
  assert_true(light.class_name().contains("mmui-light mmui-ltr"))
  assert_true(light.class_name().contains("mmui-nova"))
  let vega = @theme.theme(preset=VegaV1)
  assert_true(vega.class_name().contains("mmui-vega-v1"))
  assert_eq(@theme.tokens(preset=VegaV1).radius, 10)
  assert_eq(@theme.tokens().radius, 10)
  assert_eq(@theme.tokens().foreground, "#0a0a0a")
  assert_eq(@theme.tokens(preset=VegaV1).foreground, "#171717")
  assert_true(dark.class_name().contains("mmui-dark mmui-rtl"))
  assert_true(light.style().contains("--mmui-background:#ffffff;"))
  assert_true(dark.style().contains("--mmui-background:#0a0a0a;"))
  assert_true(
    @theme.theme(tokens={ ..@theme.tokens(), radius: 4, })
    .style()
    .contains("--mmui-radius:4px;"),
  )
  assert_eq(@theme.tokens(mode=Dark).foreground, "#fafafa")
}
