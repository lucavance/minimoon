///|
let supported_moon_floor = "0.1.20261012"

///|
let supported_moonc_floor = "0.10.15"

///|
let moon_floor_release = "0.10.15+943464bfa"

///|
let primary_moon_release = "0.10.16+b1a0e846e"

///|
// Moon 0.10.16 writes interfaces during check; the supported 0.10.15 does not
// accept --no-mbti. Probe the invoked tool instead of guessing from its version.
async fn moon_command_arguments(
  command : String,
  args : Array[String],
  cwd : String,
  env? : Map[String, String],
) -> Array[String] {
  guard command == "moon" && args.get(0) == Some("check") else { return args }
  let (code, output, _) = @toolchain.collect_output(
    command,
    ["check", "--help"],
    cwd~,
    extra_env?=env,
  )
  guard code == 0 else { abort("unable to inspect moon check capabilities") }
  if output.text().contains("--no-mbti") && !args.contains("--no-mbti") {
    [..args, "--no-mbti"]
  } else {
    args
  }
}

///|
fn moon_ci_installers_valid(workflow : String) -> Bool {
  let jobs : Map[String, String] = Map([])
  let mut job = ""
  let setting = "MOON_RELEASE: "
  for line in workflow.split("\n") {
    if line.has_prefix("  ") && !line.has_prefix("   ") && line.has_suffix(":") {
      let name = line.trim()
      job = name[0:name.length() - 1].to_owned()
    }
    if line.contains(setting) {
      let command = line.trim()
      if !command.has_prefix(setting) || jobs.contains(job) {
        return false
      }
      jobs[job] = command[setting.length():].to_owned()
    }
  }
  jobs.length() == 3 &&
  jobs.get("test") == Some(primary_moon_release) &&
  jobs.get("node-lts-compat") == Some(primary_moon_release) &&
  jobs.get("moon-floor-compat") == Some(moon_floor_release)
}

///|
async fn moon_floor_suite(root : String) -> Unit {
  let (code, output, _) = @toolchain.collect_output(
    "moon",
    ["version", "--all"],
    cwd=root,
  )
  guard code == 0 &&
    output
    .text()
    .split("\n")
    .any(line => line.has_prefix("moon " + supported_moon_floor + " ")) &&
    output
    .text()
    .split("\n")
    .any(line => line.has_prefix("moonc v" + moon_floor_release + " ")) else {
    abort(
      "toolchain-floor requires the exact reviewed MoonBit " +
      moon_floor_release,
    )
  }
  println(output.text())
  for target in ["native", "js"] {
    run(root, "Minimum MoonBit source check (" + target + ")", "moon", [
      "check", "--target", target, "--deny-warn",
    ])
    run(root, "Minimum MoonBit core tests (" + target + ")", "moon", [
      "test", "--target", target, "--deny-warn",
    ])
    run_ui_tests(root, target)
  }
  // Canonical checked-in interfaces belong to the primary compiler. The floor
  // validates frozen snapshots and compiles their extracted source consumers.
  api_suite(root, refresh=false)
}
