///|
fn application_program(application : Json) -> String {
  moon_identifier(
    string(application, "program", fallback="program"),
    "application.program",
  )
}

///|
fn application_import(module_id : String, application : Json) -> String {
  "  " +
  package_import(module_id, string(application, "package")).escape() +
  " @application,\n"
}

///|
fn application_export_options() -> String {
  [
    "start", "lifecycle", "flush", "resolve_effect", "subscription", "dispose", "capabilities",
  ]
  .map(name => "        \"minimoon_application_" + name + "\",\n")
  .join("")
}

///|
fn application_runtime_source(
  pages : Array[Json],
  contracts : Array[Json],
  application : Json,
) -> String {
  let cases : Array[String] = []
  for index = 0; index < pages.length(); index = index + 1 {
    cases.push(
      "    " +
      string(contracts[index], "id").escape() +
      " => @page" +
      index.to_string() +
      "." +
      moon_identifier(
        string(pages[index], "program", fallback="program"),
        "pages[].program",
      ) +
      "(application.deps())\n",
    )
  }
  runtime_registry_source(
    "fn main { () }",
    "  let application = minimoon_application.val.unwrap_or_else(fn() { abort(\"application has not launched\") })\n" +
    "  let page = match page_id {\n" +
    cases.join("") +
    "    _ => abort(\"unknown runtime page id\")\n  }\n" +
    "  minimoon_register_page(page_id, application.create_page(page, input~, layout~))\n",
    "optional application root",
  ) +
  "\n///|\nlet minimoon_application_definition : @minimoon.App[@application.Deps] = @application." +
  application_program(application) +
  "()\n" +
  "\n///|\nlet minimoon_application : Ref[@minimoon.AppRuntime[@application.Deps]?] = Ref(None)\n" +
  "\n///|\npub fn minimoon_application_start(payload : String) -> String {\n" +
  "  if minimoon_application.val is None { minimoon_application.val = Some(minimoon_application_definition.create_runtime()) }\n" +
  "  minimoon_application.val.unwrap().lifecycle(\"onLaunch\", payload)\n}\n" +
  "\n///|\npub fn minimoon_application_capabilities() -> String {\n" +
  "  Json::array(minimoon_application_definition.capabilities().map(capability => Json::string(capability.name()))).stringify()\n}\n" +
  "\n///|\npub fn minimoon_application_lifecycle(hook : String, payload : String) -> String {\n" +
  "  match minimoon_application.val { Some(app) => app.lifecycle(hook, payload); None => \"[]\" }\n}\n" +
  "\n///|\npub fn minimoon_application_flush() -> String {\n" +
  "  match minimoon_application.val { Some(app) => app.flush(); None => \"[]\" }\n}\n" +
  "\n///|\npub fn minimoon_application_resolve_effect(id : String, phase : String, payload : String) -> String {\n" +
  "  match minimoon_application.val { Some(app) => app.resolve_effect(id, phase, payload); None => \"[]\" }\n}\n" +
  "\n///|\npub fn minimoon_application_subscription(key : String) -> String {\n" +
  "  match minimoon_application.val { Some(app) => app.subscription(key); None => \"[]\" }\n}\n" +
  "\n///|\npub fn minimoon_application_dispose() -> String {\n" +
  "  let current = minimoon_application.val\n  minimoon_application.val = None\n" +
  "  minimoon_instances.clear()\n" +
  "  match current { Some(app) => app.dispose(); None => \"[]\" }\n}\n"
}
