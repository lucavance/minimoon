///|
fn valid_snake_name(name : String) -> Bool {
  if name == "" || name[0] < 'a' || name[0] > 'z' {
    return false
  }
  for ch in name {
    if !((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '_') {
      return false
    }
  }
  true
}

///|
fn page_package_id(page : Json) -> String {
  match page {
    Object(fields) =>
      match fields.get("package") {
        Some(String(value)) => basename(value)
        _ => ""
      }
    _ => ""
  }
}

///|
async fn write_formatted_moon(file : String, content : String) -> Unit {
  write_file(file, content)
  let code = @process.run("moon", ["fmt", file], cwd=dirname(file)) catch {
    error => fail("could not format generated MoonBit source: \{error}")
  }
  guard code == 0 else { fail("moon fmt failed for " + file) }
}

///|
fn page_source(name : String, route : String, title : String) -> String {
  "///|\n" +
  "fn app(_context : @minimoon.PageContext) -> @minimoon.Val[@minimoon.Node] {\n" +
  "  @minimoon.Val::constant(@minimoon.div([@minimoon.h1(" +
  title.escape() +
  ")]))\n" +
  "}\n\n" +
  "///|\n" +
  "pub fn program() -> @minimoon.Page {\n" +
  "  @minimoon.page(\n" +
  "    id=" +
  name.escape() +
  ",\n" +
  "    route=@minimoon.route(" +
  route.escape() +
  "),\n" +
  "    title=" +
  title.escape() +
  ",\n" +
  "    build=app,\n" +
  "  )\n" +
  "}\n"
}

///|
fn page_test_source(route : String) -> String {
  "///|\n" +
  "test \"generated page contract\" {\n" +
  "  inspect(program().route(), content=" +
  route.escape() +
  ")\n" +
  "}\n"
}

///|
fn miniapp_package_manifest() -> String {
  "import {\n  \"lampclaw/minimoon\",\n}\n\n" +
  "supported_targets = \"js\"\n\n" +
  "import {\n  \"moonbitlang/core/test\",\n} for \"test\"\n"
}

///|
async fn run_add_page(
  cwd : String,
  name : String,
  route_override : String?,
  title_override : String?,
  after : String?,
) -> Unit {
  guard valid_snake_name(name) else {
    fail("page name must be lowercase snake_case: " + name)
  }
  let config_path = resolve_config_path(cwd, None)
  let app_dir = dirname(config_path)
  let page_dir = join_path(app_dir, "src/pages/" + name)
  guard !@fs.exists(page_dir) else { fail("page already exists: " + page_dir) }
  let route = route_override.unwrap_or("pages/" + name + "/" + name)
  let title = title_override.unwrap_or(name)
  let config = @json.parse(@fs.read_file(config_path).text()) catch {
    error => fail("miniapp.minimoon.json is invalid: \{error}")
  }
  let fields = match config {
    Object(fields) => fields
    _ => fail("miniapp.minimoon.json must contain an object")
  }
  let pages = match fields.get("pages") {
    Some(Array(pages)) => pages
    _ => fail("miniapp.minimoon.json pages must be an array")
  }
  guard !pages.any(page => page_package_id(page) == name) else {
    fail("page is already present in miniapp.minimoon.json: " + name)
  }
  let entry = Json::object({ "package": Json::string("src/pages/" + name) })
  match after {
    Some(after) => {
      let found = Ref(-1)
      for index, page in pages {
        if page_package_id(page) == after {
          found.val = index
        }
      }
      guard found.val >= 0 else { fail("--after page was not found: " + after) }
      pages.insert(found.val + 1, entry)
    }
    None => pages.push(entry)
  }
  @fs.mkdir(page_dir, permission=0o755, recursive=true)
  let result = try {
    write_formatted_moon(
      join_path(page_dir, "page.mbt"),
      page_source(name, route, title),
    )
    write_formatted_moon(
      join_path(page_dir, "page_test.mbt"),
      page_test_source(route),
    )
    write_file(join_path(page_dir, "moon.pkg"), miniapp_package_manifest())
    write_file(config_path, Json::object(fields).stringify(indent=2) + "\n")
    None
  } catch {
    error => Some("\{error}")
  }
  match result {
    Some(error) => {
      if @fs.exists(page_dir) {
        @fs.rmdir(page_dir, recursive=true)
      }
      fail("could not add page; generated files were rolled back: " + error)
    }
    None => {
      println("Added page " + name + " at src/pages/" + name)
      println("Route: " + route)
    }
  }
}

///|
fn component_source(name : String) -> String {
  let _ = name
  "///|\n" +
  "pub struct Props {\n  label : String\n  event_key : String\n} derive(Eq)\n\n" +
  "///|\n" +
  "pub struct Model {\n  value : Int\n} derive(Eq)\n\n" +
  "///|\n" +
  "pub enum Msg {\n  Increment\n}\n\n" +
  "///|\n" +
  "pub fn props(label~ : String, event_key~ : String) -> Props {\n" +
  "  { label, event_key, }\n}\n\n" +
  "///|\n" +
  "pub fn update_model(model : Model, _message : Msg) -> Model {\n" +
  "  { value: model.value + 1, }\n}\n\n" +
  "///|\n" +
  "pub fn component(props : @minimoon.Val[Props]) -> @minimoon.Val[@minimoon.Node] {\n" +
  "  let (model, emit) = @minimoon.create_pure_state({ value: 0, }, update=(\n" +
  "    current,\n" +
  "    message,\n" +
  "  ) => update_model(current, message))\n" +
  "  props.view2(model, (props, current) => {\n" +
  "    @minimoon.button(\n" +
  "      on_tap=emit(Increment),\n" +
  "      event_key=props.event_key,\n" +
  "      props.label + \" \" + current.value.to_string(),\n" +
  "    )\n" +
  "  })\n" +
  "}\n"
}

///|
fn component_page_binding_source(name : String) -> String {
  "///|\n" +
  "pub fn " +
  name +
  "_component(props : @minimoon.Val[@" +
  name +
  ".Props]) -> @minimoon.Val[@minimoon.Node] {\n" +
  "  @" +
  name +
  ".component(props)\n" +
  "}\n"
}

///|
async fn run_add_component(
  cwd : String,
  name : String,
  page_id : String,
) -> Unit {
  guard valid_snake_name(name) else {
    fail("component name must be lowercase snake_case: " + name)
  }
  let config_path = resolve_config_path(cwd, None)
  let app_dir = dirname(config_path)
  let config = @json.parse(@fs.read_file(config_path).text())
  let pages = match config {
    Object(fields) =>
      match fields.get("pages") {
        Some(Array(value)) => value
        _ => []
      }
    _ => []
  }
  let page_package = Ref("")
  for page in pages {
    if page_package_id(page) == page_id {
      match page {
        Object(fields) =>
          match fields.get("package") {
            Some(String(value)) => page_package.val = value
            _ => ()
          }
        _ => ()
      }
    }
  }
  guard page_package.val != "" else {
    fail("page was not found in miniapp.minimoon.json: " + page_id)
  }
  let page_manifest = join_path(app_dir, page_package.val + "/moon.pkg")
  let page_binding = join_path(
    app_dir,
    page_package.val + "/" + name + ".component.mbt",
  )
  let component_dir = join_path(app_dir, "src/components/" + name)
  guard !@fs.exists(component_dir) else {
    fail("component already exists: " + name)
  }
  guard !@fs.exists(page_binding) else {
    fail("component page binding already exists: " + page_binding)
  }
  let moon_mod = @fs.read_file(join_path(app_dir, "moon.mod")).text()
  let module_id = Ref("")
  for line in moon_mod.split("\n") {
    let line = line.trim()
    if line.has_prefix("name =") {
      let parsed = @json.parse(line["name =".length():].trim()) catch {
        _ => Json::null()
      }
      match parsed {
        String(value) => module_id.val = value
        _ => ()
      }
    }
  }
  guard module_id.val != "" else {
    fail("moon.mod does not contain a module name")
  }
  let component_package = module_id.val + "/components/" + name
  let dependency = "  " + component_package.escape() + ",\n"
  let old_manifest = @fs.read_file(page_manifest).text()
  guard !old_manifest.contains(component_package.escape()) else {
    fail("component page import already exists: " + name)
  }
  guard old_manifest.has_prefix("import {\n") else {
    fail("page moon.pkg must begin with an import block")
  }
  let next_manifest = "import {\n" +
    dependency +
    old_manifest["import {\n".length():].to_owned()
  @fs.mkdir(component_dir, permission=0o755, recursive=true)
  let result = try {
    write_formatted_moon(
      join_path(component_dir, "component.mbt"),
      component_source(name),
    )
    write_formatted_moon(
      join_path(component_dir, "component_test.mbt"),
      "///|\ntest \"generated component public surface\" {\n" +
      "  let definition = @minimoon.page(\n" +
      "    id=\"component_test\",\n" +
      "    route=@minimoon.route(\"pages/component_test/component_test\"),\n" +
      "    title=\"Component Test\",\n" +
      "    build=_ => {\n" +
      "      component(\n" +
      "        @minimoon.Val::constant(\n" +
      "          props(label=\"Status\", event_key=\"status/increment\"),\n" +
      "        ),\n" +
      "      )\n" +
      "    },\n" +
      "  )\n" +
      "  let runtime = definition.create_runtime()\n" +
      "  let _ = runtime.mount()\n" +
      "  inspect(runtime.snapshot().contains(\"Status 0\"), content=\"true\")\n" +
      "  let _ = runtime.dispatch(\"status/increment\", \"{}\")\n" +
      "  inspect(runtime.snapshot().contains(\"Status 1\"), content=\"true\")\n" +
      "}\n",
    )
    write_file(join_path(component_dir, "moon.pkg"), miniapp_package_manifest())
    write_formatted_moon(page_binding, component_page_binding_source(name))
    write_file(page_manifest, next_manifest)
    None
  } catch {
    error => Some("\{error}")
  }
  match result {
    Some(error) => {
      if @fs.exists(component_dir) {
        @fs.rmdir(component_dir, recursive=true)
      }
      if @fs.exists(page_binding) {
        @fs.remove(page_binding)
      }
      write_file(page_manifest, old_manifest)
      fail("could not add component; changes were rolled back: " + error)
    }
    None => {
      println("Added component " + name + " at src/components/" + name)
      println("Use " + name + "_component(props) from the page Val graph")
    }
  }
}
