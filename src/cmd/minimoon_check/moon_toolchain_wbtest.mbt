///|
test "CI assigns exact MoonBit releases to primary and minimum jobs" {
  let command = "          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s -- "
  let workflow = "jobs:\n  test:\n" +
    command +
    primary_moon_release +
    "\n  node-lts-compat:\n" +
    command +
    primary_moon_release +
    "\n  moon-floor-compat:\n" +
    command +
    moon_floor_release +
    "\n"
  assert_true(moon_ci_installers_valid(workflow))
  assert_false(
    moon_ci_installers_valid(
      workflow.replace_all(old=primary_moon_release, new="latest"),
    ),
  )
  assert_false(
    moon_ci_installers_valid(
      workflow.replace_all(old=moon_floor_release, new=primary_moon_release),
    ),
  )
  assert_false(
    moon_ci_installers_valid(
      workflow.replace_all(old="moon-floor-compat:", new="unrelated:"),
    ),
  )
  assert_false(
    moon_ci_installers_valid(workflow + command + moon_floor_release + "\n"),
  )
}

///|
async test "source checks preserve interface bytes while moon info updates them" {
  let root = @env.current_dir().unwrap()
  let base = create_check_temporary(
    check_temporary_base(root, None),
    "moon-check",
  )
  defer cleanup_check_temporary(base)
  write_ui_consumer_file(
    base, "moon.mod", "name = \"test/moon_check\"\npreferred_target = \"js\"\n",
  )
  write_ui_consumer_file(
    base, "moon.pkg", "supported_targets = \"js+native\"\n",
  )
  write_ui_consumer_file(
    base, "value.mbt", "///|\npub fn value() -> Int { 1 }\n",
  )
  run(base, "Generate initial check fixture interface", "moon", ["info"])
  let path = join(base, "pkg.generated.mbti")
  let initial = @fs.read_file(path).text()
  write_ui_consumer_file(
    base, "value.mbt", "///|\npub fn value() -> String { \"changed\" }\n",
  )
  for target in ["native", "js"] {
    run(base, "Check without updating interface", "moon", [
      "check", "--target", target, "--deny-warn",
    ])
    assert_eq(@fs.read_file(path).text(), initial)
  }
  run(base, "Explicitly update changed interface", "moon", ["info"])
  assert_not_eq(@fs.read_file(path).text(), initial)
  assert_true(@fs.read_file(path).text().contains("pub fn value() -> String"))
}
