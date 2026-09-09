///|
fn onboarding_counter_source(markdown : String) -> String {
  let parts = markdown.split("<!-- minimoon:counter:start -->").collect()
  guard parts.length() == 2 else {
    abort("README must contain exactly one counter example")
  }
  let fenced = parts[1].trim().split("```moonbit\n").collect()
  guard fenced.length() >= 2 && fenced[0] == "" else {
    abort("README counter example must be a MoonBit fence")
  }
  let endings = fenced[1].split("\n```").collect()
  guard endings.length() >= 2 else {
    abort("README counter example has no closing fence")
  }
  "///|\n" + endings[0].to_owned() + "\n"
}

///|
async fn onboarding_gate(
  root : String,
  app : String,
  executable : String,
) -> Unit {
  // All edits are confined to the fresh generator-suite consumer.
  let home_path = "src/pages/home/page.mbt"
  let original = @fs.read_file(join(app, home_path)).text()
  let pieces = original.split("\"Minimoon\"").collect()
  guard pieces.length() == 2 else {
    abort("Starter initial name no longer matches the documented first edit")
  }
  let docs = @fs.read_file(join(root, "docs/guides/miniapp_quickstart.md")).text()
  for token in ["name: \"Minimoon\"", "name: \"My App\"", "Hello My App"] {
    guard docs.contains(token) else {
      abort("Quickstart is missing first-edit instruction: " + token)
    }
  }
  write_ui_consumer_file(app, home_path, pieces.join("\"My App\""))
  let first_edit_test = "src/pages/home/onboarding_test.mbt"
  write_ui_consumer_file(
    app,
    first_edit_test,
    (
      #|///|
      #|test "documented first edit preserves count and navigation" {
      #|  let runtime = program().create_runtime().unwrap()
      #|  let _ = runtime.lifecycle("onLoad", "{}")
      #|  let _ = runtime.lifecycle("onShow", "{}")
      #|  let _ = runtime.mount()
      #|  assert_true(runtime.snapshot().contains("Hello My App"))
      #|  assert_true(runtime.snapshot().contains("\"text\":\"0\""))
      #|  let _ = runtime.dispatch("home/increment", "{}")
      #|  assert_true(runtime.snapshot().contains("\"text\":\"1\""))
      #|  let command = runtime.dispatch("home/open-details", "{}")
      #|  assert_true(command.contains("/pages/details/details"))
      #|  let _ = runtime.dispose()
      #|}
    ),
  )
  write_ui_consumer_file(
    app, "src/readme_counter/moon.pkg", "import { \"lampclaw/minimoon\", }\nsupported_targets = \"js\"\n",
  )
  write_ui_consumer_file(
    app,
    "src/readme_counter/page.mbt",
    onboarding_counter_source(@fs.read_file(join(root, "README.mbt.md")).text()),
  )
  write_ui_consumer_file(
    app,
    "src/readme_counter/page_test.mbt",
    (
      #|///|
      #|test "README counter compiles and increments" {
      #|  let runtime = program().create_runtime().unwrap()
      #|  let _ = runtime.lifecycle("onLoad", "{}")
      #|  let _ = runtime.lifecycle("onShow", "{}")
      #|  let _ = runtime.mount()
      #|  assert_true(runtime.snapshot().contains("\"text\":\"0\""))
      #|  let _ = runtime.dispatch("increment", "{}")
      #|  assert_true(runtime.snapshot().contains("\"text\":\"1\""))
      #|  let _ = runtime.dispose()
      #|}
    ),
  )
  run(
    root,
    "Format generated onboarding examples",
    "moon",
    ["fmt", "src/pages/home", "src/readme_counter"],
    cwd=app,
  )
  run(
    root,
    "README counter and Starter first-edit tests",
    "moon",
    [
      "test", "src/readme_counter", "src/pages/home", "src/pages/details", "--target",
      "js", "--deny-warn",
    ],
    cwd=app,
  )
  run(root, "Quickstart first-edit build", executable, ["build", "."], cwd=app)
  run(
    root,
    "Quickstart first-edit candidate verification",
    executable,
    ["verify", ".", "--candidate"],
    cwd=app,
  )
  // Restore the original fixture before the existing scaffolding/budget probes.
  write_ui_consumer_file(app, home_path, original)
  @fs.remove(join(app, first_edit_test))
  run(
    root,
    "Restore unmodified Starter candidate",
    executable,
    ["verify", ".", "--candidate"],
    cwd=app,
  )
}
