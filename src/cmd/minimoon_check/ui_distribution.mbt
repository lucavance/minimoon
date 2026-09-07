///|
fn ui_registry_path_allowed(path : String) -> Bool {
  if [
      "moon.mod", "LICENSE", "THIRD_PARTY_NOTICES.md", "README.mbt.md", "README.md",
      "CHANGELOG.md",
    ].contains(path) {
    return true
  }
  for directory in ["src", "src/headless", "src/theme", "src/resources"] {
    let prefix = directory + "/"
    if path.has_prefix(prefix) {
      let filename = path[prefix.length():]
      if !filename.contains("/") &&
        registry_source_filename_allowed(filename.to_owned()) {
        return true
      }
    }
  }
  false
}

///|
async fn ui_package_version(root : String) -> String {
  for line in @fs.read_file(join(root, "ui/moon.mod")).text().split("\n") {
    let line = line.trim()
    if line.has_prefix("version =") {
      let value = @json.parse(line["version =".length():].trim()) catch {
        _ => abort("UI module version must be a JSON-compatible string")
      }
      if value is String(version) {
        return version
      }
    }
  }
  abort("UI module must declare a version")
}

///|
fn ui_consumer_config(features : Array[String]) -> Json {
  Json::object({
    "schemaVersion": Json::number(@versions.app_contract_version().to_double()),
    "name": Json::string("packaged_ui_consumer"),
    "pages": Json::array([
      Json::object({ "package": Json::string("src/pages/home") }),
    ]),
    "resources": Json::array([
      Json::object({
        "package": Json::string("lampclaw/minimoon_ui/resources"),
        "features": Json::array(features.map(Json::string)),
      }),
    ]),
  })
}

///|
async fn write_ui_consumer_file(
  root : String,
  path : String,
  source : String,
) -> Unit {
  let file = join(root, path)
  let parent = Path::dirname(file).to_string()
  if !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  @fs.write_file(file, source, create_mode=CreateOrTruncate, permission=0o644)
}

///|
async fn ui_distribution_package_gate(
  root : String,
  distribution : String,
  executable : String,
) -> Unit {
  let version = ui_package_version(root)
  let (code, stdout, stderr) = @process.collect_output(
    "moon",
    ["package", "--frozen", "--list"],
    cwd=join(root, "ui"),
  )
  let listing = stdout.text() + "\n" + stderr.text()
  guard code == 0 else { abort("UI registry packaging failed:\n" + listing) }
  let paths = registry_package_paths(listing)
  guard !paths.is_empty() else {
    abort("UI registry package path list is empty")
  }
  for path in paths {
    guard ui_registry_path_allowed(path) else {
      abort("UI registry package contains unapproved path: " + path)
    }
  }
  for
    required in [
      "moon.mod", "LICENSE", "THIRD_PARTY_NOTICES.md", "README.mbt.md", "README.md",
      "CHANGELOG.md", "src/pkg.generated.mbti", "src/resources/moon.pkg",
    ] {
    guard paths.contains(required) else {
      abort("UI registry package is missing " + required)
    }
  }
  let archive_name = "_build/publish/lampclaw-minimoon_ui-" + version + ".zip"
  let archive = if @fs.exists(join(root, archive_name)) {
    join(root, archive_name)
  } else {
    join(root, "ui/" + archive_name)
  }
  let size = @fs.read_file(archive).binary().length()
  let limit = (250 - 16) * 1024
  guard size <= limit else {
    abort(
      "UI registry archive exceeds 234 KiB operating budget: " +
      size.to_string(),
    )
  }
  println(
    "UI registry archive: " +
    size.to_string() +
    " / " +
    limit.to_string() +
    " operating bytes",
  )
  let package_root = join(distribution, "ui-package")
  let consumer = join(distribution, "ui-consumer")
  @fs.mkdir(package_root, permission=0o755, recursive=true)
  run(root, "Unpack independent UI registry candidate", "unzip", [
    "-q", archive, "-d", package_root,
  ])
  archive_documentation_gate(root, distribution, package_root, "UI")
  write_ui_consumer_file(
    consumer,
    "moon.mod",
    "name = \"test/packaged_ui\"\nsource = \"src\"\nimport {\n  \"lampclaw/minimoon@" +
    @versions.product_version() +
    "\",\n  \"lampclaw/minimoon_ui@" +
    version +
    "\",\n}\n",
  )
  write_ui_consumer_file(
    consumer, "src/pages/home/moon.pkg", "import {\n  \"lampclaw/minimoon\",\n  \"lampclaw/minimoon_ui\" @ui,\n  \"lampclaw/minimoon_ui/theme\",\n  \"lampclaw/minimoon_ui/headless\",\n}\n\nsupported_targets = \"js+native\"\n",
  )
  write_ui_consumer_file(
    consumer,
    "src/pages/home/page.mbt",
    (
      #|///|
      #|pub fn program() -> @minimoon.Page {
      #|  @minimoon.elmish_page(
      #|    id="packaged_ui", route=@minimoon.route("pages/home/home"), title="UI package",
      #|    model=0, update=(model, message, _) => @minimoon.no_cmd(model + message),
      #|    view=(model, emit) => @minimoon.div(
      #|      class=@theme.theme().class_name(), style=@theme.theme().style(), [
      #|        @ui.button(on_tap=emit(1), event_key="increment", "Count " + model.to_string()),
      #|        @minimoon.p(@headless.page_count(31, 10).to_string()),
      #|      ],
      #|    ),
      #|  )
      #|}
      #|
    ),
  )
  write_ui_consumer_file(
    consumer,
    "miniapp.minimoon.json",
    ui_consumer_config(["button"]).stringify(indent=2) + "\n",
  )
  write_ui_consumer_file(
    consumer, "styles/tailwind.css", "@import \"tailwindcss\";\n@source \"../src/**/*.mbt\";\n",
  )
  @fs.symlink(
    target=join(root, "node_modules"),
    join(consumer, "node_modules"),
    force_symlink=true,
  )
  run(
    root,
    "Bind independent UI registry consumer",
    "moon",
    ["work", "use", "ui-package", "ui-consumer"],
    cwd=distribution,
  )
  run(root, "Format UI registry consumer", "moon", ["fmt"], cwd=consumer)
  for target in ["js", "native"] {
    run(
      root,
      "Check packaged UI consumer (" + target + ")",
      "moon",
      // Select the consumer production package: published libraries omit tests,
      // so their repository-only blackbox imports must not become test targets.
      ["check", "src/pages/home", "--target", target, "--deny-warn"],
      cwd=consumer,
    )
  }
  run(
    root,
    "Build UI registry consumer with native resources",
    executable,
    ["build", consumer],
    cwd=consumer,
  )
  run(
    root,
    "Verify packaged UI consumer",
    executable,
    ["verify", consumer, "--candidate"],
    cwd=consumer,
  )
  let first = @verify.artifact_fingerprint(consumer)
  let manifest = read_json(consumer, "generated/manifest.json")
  guard json_field(manifest, "resources") is Array(descriptors) &&
    descriptors.length() == 1 else {
    abort("UI provider descriptor missing from manifest")
  }
  require_text(consumer, "dist/app.wxss", "mmui-button")
  write_ui_consumer_file(
    consumer,
    "miniapp.minimoon.json",
    ui_consumer_config(["__minimoon_unknown_feature__"]).stringify(indent=2) +
    "\n",
  )
  require_command_failure(
    "Reject unknown UI resource feature",
    executable,
    ["build", consumer],
    consumer,
    "resource provider",
  )
  guard @verify.artifact_fingerprint(consumer) == first else {
    abort("failed resource provider modified existing dist")
  }
  write_ui_consumer_file(
    consumer,
    "miniapp.minimoon.json",
    ui_consumer_config(["button"]).stringify(indent=2) + "\n",
  )
  run(
    root,
    "Rebuild deterministic UI registry resources",
    executable,
    ["build", consumer],
    cwd=consumer,
  )
  guard @verify.artifact_fingerprint(consumer) == first else {
    abort("UI provider generation is not deterministic")
  }
}
