///|
async fn resolve_config_path(cwd : String, target : String?) -> String {
  let source = match target {
    Some(value) => resolve_from(cwd, value)
    None => join_path(cwd, "miniapp.minimoon.json")
  }
  if @fs.exists(source) {
    match @fs.kind(source) {
      Directory => {
        let config = join_path(source, "miniapp.minimoon.json")
        if !@fs.exists(config) {
          fail(
            "app directory does not contain miniapp.minimoon.json: " + source,
          )
        }
        config
      }
      Regular => source
      _ => fail("build target is not a file or directory: " + source)
    }
  } else {
    match target {
      Some(_) => fail("config path or app directory does not exist: " + source)
      None =>
        fail("miniapp.minimoon.json was not found in current directory: " + cwd)
    }
  }
}

///|
fn init_plan(local_root : String?, cwd : String, parsed : InitArgs) -> InitPlan {
  let template = template_for(parsed.template)
  let target_dir = resolve_from(cwd, parsed.target)
  let relative = relative_to(target_dir, cwd)
  let app_name = match parsed.name {
    Some(name) => name
    None => app_name_from_dir(cwd, parsed.target)
  }
  if !is_valid_app_name(app_name) {
    fail("app name must match /^[A-Za-z][A-Za-z0-9_]*$/: " + app_name)
  }
  {
    target_dir,
    relative_target_dir: relative,
    app_name,
    package_name: "lampclaw/" + app_name,
    local_root,
    template,
  }
}

///|
async fn ensure_empty_or_missing(target : String) -> Unit {
  if @fs.exists(target) {
    guard @fs.kind(target) is Directory else {
      fail("init target already exists and is not empty: " + target)
    }
    if @fs.readdir(target).length() > 0 {
      fail("init target already exists and is not empty: " + target)
    }
  }
}

///|
async fn write_file(file : String, content : String) -> Unit {
  let parent = dirname(file)
  if parent != "" && parent != "." && !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  @fs.write_file(file, content, create_mode=CreateOrTruncate, permission=0o644)
}

///|
fn read_template_files(
  template : Template,
  package_name : String,
) -> Array[ManifestFile] {
  let files : Array[ManifestFile] = []
  for relative_file in template.template_files {
    let mut content = embedded_template(template.name, relative_file)
    content = replace_all(content, template.package_name, package_name)
    files.push({ path: relative_file, content, })
  }
  files
}

///|
fn embedded_template(template : String, path : String) -> String {
  embedded_template_files
  .get(template + ":" + path)
  .unwrap_or_else(fn() {
    fail("embedded template file is missing: " + template + ":" + path)
  })
}

///|
async fn write_manifest_files(
  target_dir : String,
  files : Array[ManifestFile],
) -> Unit {
  for file in files {
    write_file(join_path(target_dir, file.path), file.content)
  }
}

///|
fn json_string(value : String) -> String {
  value.escape()
}

///|
fn render_moon_mod(package_name : String, description : String) -> String {
  let version = @versions.product_version()
  "name = " +
  json_string(package_name) +
  "\n\n" +
  "version = " +
  json_string(version) +
  "\n\n" +
  "import {\n" +
  "  \"lampclaw/minimoon@" +
  version +
  "\",\n" +
  "}\n\n" +
  "readme = \"README.md\"\n\n" +
  "repository = \"\"\n\n" +
  "license = \"Apache-2.0\"\n\n" +
  "keywords = [ \"elm-style\", \"miniapp\", \"minimoon\" ]\n\n" +
  "description = " +
  json_string(description) +
  "\n\n" +
  "preferred_target = \"js\"\n\n" +
  "source = \"src\"\n"
}

///|
fn render_moon_work(root : String, target_dir : String) -> String {
  let root_relative = relative_to(root, target_dir)
  let workspace_member = if root_relative == "" { "." } else { root_relative }
  "members = [\n" +
  "  \".\",\n" +
  "  " +
  json_string(workspace_member) +
  ",\n" +
  "]\n"
}

///|
fn render_app_config(plan : InitPlan) -> String {
  let packages = ["src/pages/home", "src/pages/details"]
  let pages = packages
    .map(package_path => {
      "    { \"package\": " + json_string(package_path) + " }"
    })
    .join(",\n")
  "{\n" +
  "  \"schemaVersion\": " +
  @versions.app_contract_version().to_string() +
  ",\n" +
  "  \"name\": " +
  json_string(plan.app_name) +
  ",\n" +
  "  \"pages\": [\n" +
  pages +
  "\n  ]\n" +
  "}\n"
}

///|
fn render_starter_readme(
  app_name : String,
  template : Template,
  local_workspace : Bool,
) -> String {
  let dependency_step = if local_workspace {
    "This development app is bound to a local Minimoon checkout by `moon.work`. Remove that file before distributing the app.\n\n" +
    "```bash\n" +
    "bun install\n" +
    "minimoon build .\n" +
    "moon check\n" +
    "moon test\n" +
    "```\n\n"
  } else {
    "This standalone app resolves `lampclaw/minimoon` from the MoonBit package registry and does not depend on a local source checkout.\n\n" +
    "```bash\n" +
    "moon update\n" +
    "bun install\n" +
    "minimoon build .\n" +
    "moon check\n" +
    "moon test\n" +
    "```\n\n"
  }
  "# " +
  app_name +
  "\n\n" +
  "Generated by `" +
  template.generated_by +
  "`.\n\n" +
  dependency_step +
  "Maintain `" +
  template.app_source +
  "`, the other `src/pages/*` packages, `miniapp.minimoon.json`, and `styles/tailwind.css`. `styles/app.wxss`, `generated/`, and `dist/` are build artifacts.\n\n" +
  "For a real WeChat AppID, copy `dist/project.private.config.example.json` to `dist/project.private.config.json` and edit only the local copy. Minimoon preserves that ignored file across builds and excludes it from release fingerprints.\n\n" +
  "This app targets WeChat MiniApp Skyline. Styles should start from TailwindCSS and pass through the Minimoon `weapp-tailwindcss` pipeline instead of handwritten semantic WXSS.\n"
}

///|
fn create_init_manifest(plan : InitPlan) -> InitManifest {
  let files = read_template_files(plan.template, plan.package_name)
  files.push({
    path: "miniapp.minimoon.json",
    content: render_app_config(plan),
  })
  files.push({
    path: "moon.mod",
    content: render_moon_mod(plan.package_name, plan.template.description),
  })
  match plan.local_root {
    Some(root) =>
      files.push({
        path: "moon.work",
        content: render_moon_work(root, plan.target_dir),
      })
    None => ()
  }
  files.push({
    path: "README.md",
    content: render_starter_readme(
      plan.app_name,
      plan.template,
      plan.local_root is Some(_),
    ),
  })
  files.push({
    path: "package.json",
    content: "{\n" +
    "  \"private\": true,\n" +
    "  \"engines\": {\n" +
    "    \"node\": \">=24.11.0\"\n" +
    "  },\n" +
    "  \"devDependencies\": {\n" +
    "    \"@tailwindcss/cli\": \"4.3.3\",\n" +
    "    \"postcss\": \"8.5.26\",\n" +
    "    \"tailwindcss\": \"4.3.3\",\n" +
    "    \"weapp-tailwindcss\": \"5.5.0\"\n" +
    "  },\n" +
    "  \"devEngines\": {\n" +
    "    \"packageManager\": {\n" +
    "      \"name\": \"bun\",\n" +
    "      \"version\": \"1.4.0\",\n" +
    "      \"onFail\": \"download\"\n" +
    "    }\n" +
    "  },\n" +
    "  \"overrides\": {\n" +
    "    \"postcss\": \"8.5.26\"\n" +
    "  }\n" +
    "}\n",
  })
  files.push({
    path: ".gitignore",
    content: "_build/\n" +
    ".mooncakes/\n" +
    ".minimoon-tmp/\n" +
    "node_modules/\n" +
    "dist/\n" +
    "generated/\n" +
    "styles/app.wxss\n" +
    "*.log\n" +
    ".env\n" +
    ".env.*\n",
  })
  {
    target_dir: plan.target_dir,
    relative_target_dir: plan.relative_target_dir,
    app_name: plan.app_name,
    template_name: plan.template.name,
    files,
  }
}

///|
async fn run_init(
  local_root : String?,
  cwd : String,
  args : Array[String],
  start : Int,
) -> Unit {
  let parsed = parse_init_args(args, start)
  if parsed.show_help {
    println(usage())
    return
  }
  let plan = init_plan(local_root, cwd, parsed)
  ensure_empty_or_missing(plan.target_dir)
  if !@fs.exists(plan.target_dir) {
    @fs.mkdir(plan.target_dir, permission=0o755, recursive=true)
  }
  let manifest = create_init_manifest(plan)
  write_manifest_files(plan.target_dir, manifest.files)
  println("minimoon init " + plan.relative_target_dir)
  println(
    "Created MiniApp app " + plan.app_name + " at " + plan.relative_target_dir,
  )
  println("Template: " + plan.template.name)
  println("Next: cd " + plan.relative_target_dir + " && bun install")
  println("Next: minimoon build " + plan.relative_target_dir)
  println("Note: styles/app.wxss, generated/, and dist/ are build artifacts.")
}

///|
