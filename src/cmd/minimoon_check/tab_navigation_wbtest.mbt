///|
async test "actual host templates enforce native Tab navigation boundaries" {
  let (code, stdout, stderr) = @process.collect_output("bun", [
    "--eval",
    @host_validation.tab_navigation_host_source(),
  ])
  assert_eq(code, 0, msg=stdout.text() + stderr.text())
}
