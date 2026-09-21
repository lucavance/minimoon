///|
async test "actual host templates enforce native Tab navigation boundaries" {
  let (code, stdout, stderr) = @toolchain.collect_output(
    "vp",
    @toolchain.bun_args([
      "--eval",
      @host_validation.tab_navigation_host_source(),
    ]),
  )
  assert_eq(code, 0, msg=stdout.text() + stderr.text())
}
