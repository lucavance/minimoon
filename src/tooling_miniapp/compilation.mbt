///|
fn runtime_package_source(
  page_import : String,
  program : String,
  print_contract : Bool,
) -> String {
  let call = "@page." + program + "()"
  let main = if print_contract {
    "fn main { println(" + call + ".contract()) }"
  } else {
    "fn main { () }"
  }
  runtime_registry_source(
    main,
    "  minimoon_next_instance_id.val = minimoon_next_instance_id.val + 1\n" +
    "  let program = " +
    call +
    "\n" +
    "  guard page_id == program.id() else { abort(\"runtime page id mismatch\") }\n" +
    "  let id = page_id + \":\" + minimoon_next_instance_id.val.to_string()\n" +
    "  minimoon_instances[id] = program.create_runtime()\n" +
    "  id\n",
    "page import: " + page_import,
  )
}

///|
fn runtime_registry_source(
  main : String,
  create_body : String,
  import_note : String,
) -> String {
  "///|\n" +
  "let minimoon_instances : Map[String, @minimoon.PageRuntime] = Map([])\n\n" +
  "///|\n" +
  "let minimoon_next_instance_id : Ref[Int] = Ref(0)\n\n" +
  "///|\n" +
  main +
  "\n\n" +
  "///|\n" +
  "pub fn minimoon_runtime_version() -> Int { @minimoon.runtime_api_version() }\n\n" +
  "///|\n" +
  "pub fn minimoon_runtime_state_abi_version() -> Int { " +
  @versions.runtime_api_version().to_string() +
  " }\n\n" +
  "///|\n" +
  "pub fn minimoon_runtime_create_app(page_id : String) -> String {\n" +
  create_body +
  "}\n\n" +
  runtime_proxy_function("mount", "instance.mount()", []) +
  runtime_proxy_function(
    "dispatch",
    "instance.dispatch(event_key, payload_json)",
    [("event_key", "String"), ("payload_json", "String")],
  ) +
  runtime_proxy_function(
    "dispatch_batch",
    "instance.dispatch_batch(events_json)",
    [("events_json", "String")],
  ) +
  runtime_proxy_function(
    "lifecycle",
    "instance.lifecycle(hook, payload_json)",
    [("hook", "String"), ("payload_json", "String")],
  ) +
  runtime_proxy_function(
    "resolve_effect",
    "instance.resolve_effect(request_id, phase, payload_json)",
    [("request_id", "String"), ("phase", "String"), ("payload_json", "String")],
  ) +
  runtime_proxy_function(
    "subscription",
    "instance.subscription(key, payload_json)",
    [("key", "String"), ("payload_json", "String")],
  ) +
  runtime_proxy_function("snapshot", "instance.snapshot()", []) +
  "///|\n" +
  "pub fn minimoon_runtime_dispose(instance_id : String) -> String {\n" +
  "  match minimoon_instances.get(instance_id) {\n" +
  "    Some(instance) => {\n" +
  "      let commands = instance.dispose()\n" +
  "      minimoon_instances.remove(instance_id)\n" +
  "      commands\n" +
  "    }\n" +
  "    None => \"[]\"\n" +
  "  }\n" +
  "}\n" +
  "\n// " +
  import_note +
  "\n"
}

///|
fn app_runtime_package_source(
  pages : Array[Json],
  contracts : Array[Json],
) -> String {
  let factories : Array[String] = []
  let imports : Array[String] = []
  for index = 0; index < pages.length(); index = index + 1 {
    let program = moon_identifier(
      string(pages[index], "program", fallback="program"),
      "pages[].program",
    )
    factories.push(
      "    " +
      string(contracts[index], "id").escape() +
      " => @page" +
      index.to_string() +
      "." +
      program +
      "().create_runtime()\n",
    )
    imports.push(string(pages[index], "package"))
  }
  runtime_registry_source(
    "fn main { () }",
    "  minimoon_next_instance_id.val = minimoon_next_instance_id.val + 1\n" +
    "  let runtime = match page_id {\n" +
    factories.join("") +
    "    _ => abort(\"unknown runtime page id: \" + page_id)\n" +
    "  }\n" +
    "  let id = page_id + \":\" + minimoon_next_instance_id.val.to_string()\n" +
    "  minimoon_instances[id] = runtime\n" +
    "  id\n",
    "application page imports: " + imports.join(", "),
  )
}

///|
fn runtime_proxy_function(
  name : String,
  body : String,
  args : Array[(String, String)],
) -> String {
  let parameters = ["instance_id : String"]
  for arg in args {
    parameters.push(arg.0 + " : " + arg.1)
  }
  "///|\n" +
  "pub fn minimoon_runtime_" +
  name +
  "(" +
  parameters.join(", ") +
  ") -> String {\n" +
  "  match minimoon_instances.get(instance_id) {\n" +
  "    Some(instance) => " +
  body +
  "\n" +
  "    None => \"[]\"\n" +
  "  }\n" +
  "}\n\n"
}

///|
fn app_runtime_package_manifest(
  module_id : String,
  pages : Array[Json],
) -> String {
  let imports = ["  \"lampclaw/minimoon\" @minimoon,\n"]
  for index = 0; index < pages.length(); index = index + 1 {
    let page_import = package_import(module_id, string(pages[index], "package"))
    imports.push(
      "  " + page_import.escape() + " @page" + index.to_string() + ",\n",
    )
  }
  "import {\n" + imports.join("") + "}\n\n" + runtime_link_options()
}

///|
fn runtime_link_options() -> String {
  "supported_targets = \"js\"\n\n" +
  "pkgtype(kind: \"executable\")\n\n" +
  "options(\n" +
  "  link: {\n" +
  "    \"js\": {\n" +
  "      \"format\": \"cjs\",\n" +
  "      \"exports\": [\n" +
  "        \"minimoon_runtime_version\",\n" +
  "        \"minimoon_runtime_state_abi_version\",\n" +
  "        \"minimoon_runtime_create_app\",\n" +
  "        \"minimoon_runtime_mount\",\n" +
  "        \"minimoon_runtime_dispatch\",\n" +
  "        \"minimoon_runtime_dispatch_batch\",\n" +
  "        \"minimoon_runtime_lifecycle\",\n" +
  "        \"minimoon_runtime_resolve_effect\",\n" +
  "        \"minimoon_runtime_subscription\",\n" +
  "        \"minimoon_runtime_snapshot\",\n" +
  "        \"minimoon_runtime_dispose\",\n" +
  "      ],\n" +
  "    },\n" +
  "  },\n" +
  ")\n"
}

///|
async fn emit_host_bridge(
  app_root : String,
  source : String,
  release : Bool,
) -> String {
  if !release {
    return source
  }
  let temp_root = join(app_root, ".minimoon-tmp/host-bridge")
  let source_file = join(temp_root, "minimoon.host.source.cjs")
  let output_file = join(temp_root, "minimoon.host.min.cjs")
  if @fs.exists(temp_root) {
    @fs.rmdir(temp_root, recursive=true)
  }
  write(source_file, source)
  let result = {
    errdefer (if @fs.exists(temp_root) { @fs.rmdir(temp_root, recursive=true) })
    let _ = run_checked(
      "bun",
      [
        "build", source_file, "--target", "browser", "--format", "cjs", "--minify-whitespace",
        "--minify-identifiers", "--minify-syntax", "--external=*", "--outfile", output_file,
      ],
      app_root,
      "release host bridge minification",
    )
    guard @fs.exists(output_file) else {
      raise Failure::Failure(
        "Minified host bridge was not produced: " + output_file,
      )
    }
    Some(miniapp_compatible_javascript(@fs.read_file(output_file).text()))
  }
  if @fs.exists(temp_root) {
    @fs.rmdir(temp_root, recursive=true)
  }
  result.unwrap()
}

///|
fn contract_package_manifest(page_import : String) -> String {
  "import {\n" +
  "  \"lampclaw/minimoon\" @minimoon,\n" +
  "  " +
  page_import.escape() +
  " @page,\n" +
  "}\n\n" +
  "supported_targets = \"js\"\n\n" +
  "pkgtype(kind: \"executable\")\n"
}

///|
async fn run_checked(
  command : String,
  args : Array[String],
  cwd : String,
  label : String,
) -> String {
  let (code, stdout, stderr) = @process.collect_output(command, args, cwd~) catch {
    err => raise Failure::Failure("failed to start " + label + ": \{err}")
  }
  let output = stdout.text() catch { _ => "" }
  guard code == 0 else {
    let error = stderr.text() catch { _ => "" }
    raise Failure::Failure(
      label + " failed\nstdout: " + output + "\nstderr: " + error,
    )
  }
  output
}

///|
async fn compile_page_contract(
  app_root : String,
  module_id : String,
  index : Int,
  page : Json,
) -> Json {
  let package_path = string(page, "package")
  guard package_path != "" else { abort("pages[].package must be a string") }
  let package_dir = join(app_root, package_path)
  guard @fs.exists(join(package_dir, "moon.pkg")) else {
    abort("page package does not contain moon.pkg: " + package_path)
  }
  let page_import = package_import(module_id, package_path)
  let program = moon_identifier(
    string(page, "program", fallback="program"),
    "pages[].program",
  )
  let temp_name = "minimoon_page_" + index.to_string()
  let temp_relative = "src/" + temp_name
  let temp_dir = join(app_root, temp_relative)
  let temp_root = join(app_root, ".minimoon-tmp")
  let target_dir = join(temp_root, "page-" + index.to_string())
  if @fs.exists(temp_dir) {
    @fs.rmdir(temp_dir, recursive=true)
  }
  if @fs.exists(target_dir) {
    @fs.rmdir(target_dir, recursive=true)
  }
  write(join(temp_dir, "moon.pkg"), contract_package_manifest(page_import))
  write(
    join(temp_dir, "main.mbt"),
    runtime_package_source(page_import, program, true),
  )
  let result = {
    errdefer {
      if @fs.exists(temp_dir) {
        @fs.rmdir(temp_dir, recursive=true)
      }
      if @fs.exists(temp_root) {
        @fs.rmdir(temp_root, recursive=true)
      }
    }
    let _ = run_checked(
      "moon",
      ["fmt", temp_relative + "/main.mbt"],
      app_root,
      "page contract source formatting for " + package_path,
    )
    let contract_text = run_checked(
      "moon",
      [
        "run", temp_relative, "--target", "js", "--target-dir", target_dir, "--deny-warn",
      ],
      app_root,
      "Page contract for " + package_path,
    )
    let contract = @json.parse(contract_text.trim()) catch {
      err => raise Failure::Failure("Page contract was not valid JSON: \{err}")
    }
    Some(contract)
  }
  if @fs.exists(temp_dir) {
    @fs.rmdir(temp_dir, recursive=true)
  }
  if @fs.exists(temp_root) {
    @fs.rmdir(temp_root, recursive=true)
  }
  result.unwrap()
}

///|
fn miniapp_text_encoder_prelude() -> String {
  "var __mmTextEncoder=globalThis.TextEncoder?new globalThis.TextEncoder:{encode:function(s){" +
  "for(var a=[],i=0,c,d;i<s.length;i++){c=s.charCodeAt(i);" +
  "if(c>=55296&&c<56320&&(d=s.charCodeAt(i+1))>=56320&&d<57344)" +
  "c=(c-55296)*1024+d-56320+65536,i++;" +
  "else if(c>=55296&&c<57344)c=65533;" +
  "c<128?a.push(c):c<2048?a.push(c>>6|192,c&63|128):" +
  "c<65536?a.push(c>>12|224,c>>6&63|128,c&63|128):" +
  "a.push(c>>18|240,c>>12&63|128,c>>6&63|128,c&63|128)}" +
  "return new Uint8Array(a)}};\n"
}

///|
fn miniapp_compatible_javascript(emitted : String) -> String {
  let crypto_compatible = emitted.replace_all(
    old="globalThis.crypto?.getRandomValues",
    new="(globalThis.crypto&&globalThis.crypto.getRandomValues)",
  )
  let compatible = if crypto_compatible.contains("new TextEncoder") {
    miniapp_text_encoder_prelude() +
    crypto_compatible
    .replace_all(old="new TextEncoder()", new="__mmTextEncoder")
    .replace_all(old="new TextEncoder", new="__mmTextEncoder")
  } else {
    crypto_compatible
  }
  guard !compatible.contains("globalThis.crypto?.getRandomValues") else {
    abort("MiniApp compatibility rule did not normalize crypto optional access")
  }
  guard !compatible.contains("new TextEncoder") else {
    abort("MiniApp compatibility rule did not normalize TextEncoder")
  }
  compatible
}

///|
async fn moon_javascript_bundle_candidates(
  target_dir : String,
  temp_name : String,
) -> Array[String] {
  let candidates : Array[String] = []
  if !@fs.exists(target_dir) {
    return candidates
  }
  let bundle_name = temp_name + ".js"
  @fs.walk(
    target_dir,
    (path, names) => {
      for name in names {
        let file = join(path, name)
        if name == bundle_name &&
          @fs.kind(file, follow_symlink=false) == @fs.Regular {
          candidates.push(file)
        }
      }
    },
    max_concurrency=1,
  )
  candidates.sort()
  candidates
}

///|
async fn locate_moon_javascript_bundle(
  target_dir : String,
  temp_name : String,
) -> String {
  let candidates = moon_javascript_bundle_candidates(target_dir, temp_name)
  match candidates {
    [bundle] => bundle
    [] =>
      raise Failure::Failure(
        "Application MoonBit runtime bundle was not produced: expected exactly one " +
        temp_name +
        ".js below " +
        target_dir,
      )
    _ => {
      let displayed : Array[String] = []
      for candidate in candidates {
        displayed.push(
          Path::relative(candidate, base=target_dir)
          .normalize()
          .to_string()
          .replace_all(old="\\", new="/"),
        )
      }
      raise Failure::Failure(
        "Application MoonBit runtime bundle was ambiguous: expected exactly one " +
        temp_name +
        ".js below " +
        target_dir +
        ", found " +
        displayed.join(", "),
      )
    }
  }
}

///|
async fn compile_app_runtime(
  app_root : String,
  module_id : String,
  pages : Array[Json],
  contracts : Array[Json],
  release : Bool,
) -> String {
  let temp_name = "minimoon_app_runtime"
  let temp_relative = "src/" + temp_name
  let temp_dir = join(app_root, temp_relative)
  let temp_root = join(app_root, ".minimoon-tmp")
  let target_dir = join(temp_root, "app-runtime")
  if @fs.exists(temp_dir) {
    @fs.rmdir(temp_dir, recursive=true)
  }
  if @fs.exists(target_dir) {
    @fs.rmdir(target_dir, recursive=true)
  }
  write(
    join(temp_dir, "moon.pkg"),
    app_runtime_package_manifest(module_id, pages),
  )
  write(
    join(temp_dir, "main.mbt"),
    app_runtime_package_source(pages, contracts),
  )
  let result = {
    errdefer {
      if @fs.exists(temp_dir) {
        @fs.rmdir(temp_dir, recursive=true)
      }
      if @fs.exists(temp_root) {
        @fs.rmdir(temp_root, recursive=true)
      }
    }
    let _ = run_checked(
      "moon",
      ["fmt", temp_relative + "/main.mbt"],
      app_root,
      "application runtime source formatting",
    )
    let build_args = if release {
      [
        "build", temp_relative, "--target", "js", "--target-dir", target_dir, "--release",
        "--strip", "--deny-warn",
      ]
    } else {
      [
        "build", temp_relative, "--target", "js", "--target-dir", target_dir, "--deny-warn",
      ]
    }
    let _ = run_checked(
      "moon", build_args, app_root, "application runtime bundle",
    )
    let bundle_file = locate_moon_javascript_bundle(target_dir, temp_name)
    let emitted_bundle = if release {
      let minified_file = join(target_dir, temp_name + ".min.js")
      let _ = run_checked(
        "bun",
        [
          "build", bundle_file, "--target", "browser", "--format", "cjs", "--minify-whitespace",
          "--minify-identifiers", "--minify-syntax", "--outfile", minified_file,
        ],
        app_root,
        "release application runtime minification",
      )
      guard @fs.exists(minified_file) else {
        raise Failure::Failure(
          "Minified application runtime bundle was not produced: " +
          minified_file,
        )
      }
      minified_file
    } else {
      bundle_file
    }
    Some(miniapp_compatible_javascript(@fs.read_file(emitted_bundle).text()))
  }
  if @fs.exists(temp_dir) {
    @fs.rmdir(temp_dir, recursive=true)
  }
  if @fs.exists(temp_root) {
    @fs.rmdir(temp_root, recursive=true)
  }
  result.unwrap()
}
