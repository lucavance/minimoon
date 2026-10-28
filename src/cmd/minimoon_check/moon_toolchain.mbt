///|
// The current toolchain writes interfaces during check; keep read-only checks
// from changing the canonical checked-in interfaces.
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
