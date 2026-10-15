///|
async fn nova_recipe_gate(root : String) -> Unit {
  let audit = read_json(root, "ui/docs/nova_recipe_map.json")
  guard json_string(audit, "commit") ==
    "7d5940fed9b1ba795c84582394024233997ec267" &&
    json_string(audit, "preset") == "Nova" &&
    json_string(audit, "host_status") == "pending" else {
    abort("Nova recipe audit pin or candidate status changed")
  }
  let resource_source = @fs.read_file(
    join(root, "ui/src/resources/resources.mbt"),
  ).text()
  let quoted = resource_source.split_once("fn base_rules").unwrap().0
    .to_owned()
    .split("\"")
    .collect()
  let expected : Set[String] = Set([])
  for index, value in quoted {
    let name = value.to_owned()
    if index % 2 == 1 && !["form", "theme", "markdown"].contains(name) {
      expected.add(name)
    }
  }
  guard expected.length() == 64 &&
    json_field(audit, "families") is Array(families) &&
    families.length() == 64 else {
    abort("Nova recipe audit must cover all 64 component families")
  }
  let seen : Set[String] = Set([])
  for family in families {
    let name = json_string(family, "family")
    guard expected.contains(name) && !seen.contains(name) else {
      abort("missing or duplicate Nova recipe family: " + name)
    }
    seen.add(name)
    guard json_string(family, "upstream_path") ==
      "rui/" + name.replace_all(old="-", new="_") + ".mbt" &&
      json_string(family, "upstream_sha256").length() == 64 &&
      json_string(family, "decision") != "" else {
      abort("Nova recipe provenance missing: " + name)
    }
    let recipe = json_field(family, "native_recipe")
    let path = json_string(recipe, "path")
    let selector = json_string(recipe, "selector")
    require_file(root, path)
    guard selector.has_prefix(".mmui-") &&
      @fs.read_file(join(root, path)).text().contains(selector) else {
      abort("Nova native recipe reference missing: " + name)
    }
    guard json_field(family, "local") is Array(references) &&
      !references.is_empty() else {
      abort("Nova implementation mapping missing: " + name)
    }
    for reference in references {
      require_file(root, json_string(reference, "path"))
    }
  }
  guard json_field(audit, "tests") is Array(tests) && !tests.is_empty() else {
    abort("Nova test references missing")
  }
  for item in tests {
    guard item is String(path) else { abort("invalid Nova test reference") }
    require_file(root, path)
  }
  println("Offline Nova recipe audit: all 64 native families mapped")
}
