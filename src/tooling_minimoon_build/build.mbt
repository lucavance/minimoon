///|
type Path = @path.Path

///|
fn object(json : Json, label : String) -> Map[String, Json] {
  match json {
    Object(fields) => fields
    _ => abort(label + " must be an object")
  }
}

///|
fn field(json : Json, key : String) -> Json {
  object(json, key).get(key).unwrap_or_else(fn() { abort("missing " + key) })
}

///|
fn string(json : Json, key : String, fallback? : String = "") -> String {
  match object(json, key).get(key) {
    Some(String(value)) => value
    Some(Null) | None => fallback
    Some(_) => abort(key + " must be a string")
  }
}

///|
fn array(json : Json, key : String) -> Array[Json] {
  match field(json, key) {
    Array(items) => items
    _ => abort(key + " must be an array")
  }
}

///|
fn join(base : String, child : String) -> String {
  Path::join(base, child).to_string()
}

///|
async fn write(file : String, content : String) -> Unit {
  let parent = Path::dirname(file).to_string()
  if !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  @fs.write_file(file, content, create_mode=CreateOrTruncate, permission=0o644)
}

///|
async fn find_node_root(start : String) -> String {
  let mut current = start
  while true {
    if @fs.exists(join(current, "node_modules/.bin/tailwindcss")) &&
      @fs.exists(join(current, "node_modules/weapp-tailwindcss")) {
      return current
    }
    let parent = Path::dirname(current).to_string()
    if parent == current {
      raise Failure::Failure(
        "Tailwind dependencies were not found from " +
        start +
        ". Run `bun install` in the Minimoon app directory.",
      )
    }
    current = parent
  }
  raise Failure::Failure("Tailwind dependency search terminated unexpectedly")
}

///|
pub fn adapter_source() -> String {
  (
    #|import fs from "node:fs";
    #|import path from "node:path";
    #|import postcss from "postcss";
    #|import weappTailwindcssPostcssPlugin from "weapp-tailwindcss/postcss";
    #|import { escape as escapeWeappClass } from "weapp-tailwindcss/escape";
    #|
    #|const [rawCssFile, tailwindInput, sourceWxss, distDir, routesSource] = process.argv.slice(2);
    #|if (!rawCssFile || !tailwindInput || !sourceWxss || !distDir || !routesSource) {
    #|  throw new Error(
    #|    "usage: adapter <raw-css> <tailwind-input> <source-wxss> <dist-dir> <routes-json>",
    #|  );
    #|}
    #|
    #|function transformWxml(source) {
    #|  return source.replace(/class="([^"]*)"/g, (_match, value) => {
    #|    const classes = value.split(/\s+/).filter(Boolean).map(escapeWeappClass).join(" ");
    #|    return `class="${classes}"`;
    #|  });
    #|}
    #|
    #|const escapeContract = [
    #|  ["min-h-[100vh]", "min-h-_b100vh_B"],
    #|  ["hover:bg-red-500", "hover_cbg-red-500"],
    #|  ["w-1/2", "w-1_f2"],
    #|  ["text-[#fff]", "text-_b_hfff_B"],
    #|  ["-mt-[1.5px]", "-mt-_b1_d5px_B"],
    #|  ["2xl:flex", "_2xl_cflex"],
    #|  ["中", "u_x4e2d_"],
    #|];
    #|for (const [raw, expected] of escapeContract) {
    #|  if (escapeWeappClass(raw) !== expected) {
    #|    throw new Error(`weapp-tailwindcss class escape contract changed for ${raw}`);
    #|  }
    #|}
    #|
    #|const rawCss = fs.readFileSync(rawCssFile, "utf8");
    #|const result = await postcss([
    #|  weappTailwindcssPostcssPlugin({ version: 4, cssEntries: [tailwindInput] }),
    #|]).process(rawCss, { from: rawCssFile });
    #|const wxss = `${result.css.trim()}\n`;
    #|fs.mkdirSync(path.dirname(sourceWxss), { recursive: true });
    #|fs.writeFileSync(sourceWxss, wxss);
    #|fs.writeFileSync(path.join(distDir, "app.wxss"), wxss);
    #|
    #|for (const route of JSON.parse(routesSource)) {
    #|  const base = path.join(distDir, route);
    #|  const wxml = `${base}.wxml`;
    #|  if (fs.existsSync(wxml)) {
    #|    const transformed = transformWxml(fs.readFileSync(wxml, "utf8")).trimEnd();
    #|    fs.writeFileSync(wxml, `${transformed}\n`);
    #|  }
    #|}
  )
}

///|
async fn run_checked(
  command : String,
  args : Array[String],
  cwd : String,
  label : String,
) -> Unit {
  let (code, stdout, stderr) = @process.collect_output(command, args, cwd~) catch {
    err => raise Failure::Failure("failed to start \{label}: \{err}")
  }
  guard code == 0 else {
    let out = stdout.text().trim().to_owned()
    let error = stderr.text().trim().to_owned()
    raise Failure::Failure(
      label + " failed\nstdout: " + out + "\nstderr: " + error,
    )
  }
}

///|
pub async fn generate_tailwind(loaded : Json) -> Unit {
  let config_path = string(loaded, "configPath")
  let app_dir = Path::dirname(config_path).to_string()
  let temp_root = join(app_dir, ".minimoon-tmp")
  if @fs.exists(temp_root) {
    @fs.rmdir(temp_root, recursive=true)
  }
  let node_root = find_node_root(app_dir)
  let temp_dir = join(temp_root, "tailwind")
  @fs.mkdir(temp_dir, permission=0o700, recursive=true)
  defer (if @fs.exists(temp_root) { @fs.rmdir(temp_root, recursive=true) })
  let input = string(loaded, "tailwindInputAbs")
  let resolved_input = join(
    Path::dirname(input).to_string(),
    ".minimoon-tailwind-input.css",
  )
  let raw_css = join(temp_dir, "tailwind.css")
  let adapter = join(temp_dir, "weapp_tailwindcss_adapter.mjs")
  let tailwind_package = join(node_root, "node_modules/tailwindcss")
    .split("\\")
    .collect()
    .join("/")
  let source = @fs.read_file(input)
    .text()
    .split("@import \"tailwindcss\"")
    .collect()
    .join("@import \"" + tailwind_package + "\"")
    .split("@import 'tailwindcss'")
    .collect()
    .join("@import '" + tailwind_package + "'")
  @fs.write_file(
    resolved_input,
    source,
    create_mode=CreateNew,
    permission=0o600,
  )
  defer (if @fs.exists(resolved_input) { @fs.remove(resolved_input) })
  write(adapter, adapter_source())
  let routes = array(field(loaded, "appMetadata"), "pages").map(page => {
    field(page, "route")
  })
  let result = try {
    run_checked(
      join(node_root, "node_modules/.bin/tailwindcss"),
      ["-i", resolved_input, "-o", raw_css, "--cwd", node_root],
      node_root,
      "Tailwind generation",
    )
    run_checked(
      "bun",
      [
        adapter,
        raw_css,
        input,
        string(loaded, "sourceWxssAbs"),
        string(loaded, "distDirAbs"),
        Json::array(routes).stringify(),
      ],
      node_root,
      "weapp-tailwindcss conversion",
    )
    let theme = string(loaded, "componentTheme")
    let resources_css = string(loaded, "resourcesWxss")
    if theme != "" || resources_css != "" {
      let theme_css = if theme == "" {
        ""
      } else {
        @miniapp_tooling.component_theme_css(theme)
      }
      let source_wxss = string(loaded, "sourceWxssAbs")
      let dist_wxss = join(string(loaded, "distDirAbs"), "app.wxss")
      let generated_css = @fs.read_file(source_wxss).text()
      let themed_css = resources_css + theme_css + generated_css
      write(source_wxss, themed_css)
      write(dist_wxss, themed_css)
    }
    None
  } catch {
    err => Some("\{err}")
  }
  match result {
    Some(message) => raise Failure::Failure(message)
    None => ()
  }
}

///|
pub async fn build(
  root : String,
  config_path : String,
  mode : String,
) -> String {
  let config_file = if Path::is_absolute(config_path) {
    Path::normalize(config_path).to_string()
  } else {
    Path::join(root, config_path).normalize().to_string()
  }
  let prepared = @miniapp_tooling.prepare_build(config_file)
  let app_root = prepared.app_root()
  let base = join(app_root, "_build/minimoon-build")
  @fs.mkdir(base, permission=0o700, recursive=true) catch {
    error =>
      if !@fs.exists(base) || @fs.kind(base) != @fs.Directory {
        raise error
      }
  }
  let lock = @fs.open(
    join(base, "build.lock"),
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  defer lock.close()
  guard lock.try_lock(Exclusive) else {
    raise Failure("another Minimoon build is already running for " + app_root)
  }
  let transaction = new_build_transaction(base)
  let preserve_backup = Ref(false)
  errdefer (if !preserve_backup.val { cleanup_build_transaction(transaction) })
  let diagnostics_file = join(app_root, "generated/diagnostics.json")
  // Diagnostics describe this attempt independently of committed artifacts.
  // Clearing under the lock avoids stale errors and preserves repeated precise
  // compiler errors even when their serialized bytes are identical.
  if @fs.exists(diagnostics_file) {
    @fs.remove(diagnostics_file)
  }
  let outcome = try {
    let generated = @miniapp_tooling.generate_staged(
      prepared,
      mode,
      join(transaction, "next"),
    )
    generate_tailwind(generated)
    @miniapp_tooling.write_release_summary(generated, mode)
    // Recheck destination kinds after subprocesses finish, before any promotion.
    for entry in build_replacements(generated) {
      @miniapp_tooling.validate_output_path(
        app_root,
        Path::relative(entry.target, base=app_root).to_string(),
        entry.target == string(generated, "distDirFinalAbs"),
      )
    }
    promote_build_outputs(
      build_replacements(generated),
      join(transaction, "backup"),
    )
    Ok(generated)
  } catch {
    error => Err(error)
  }
  let generated = match outcome {
    Ok(generated) => generated
    Err(error) => {
      match error {
        BuildRecoveryError(_) => preserve_backup.val = true
        _ => ()
      }
      @miniapp_tooling.write_build_failure(config_file, "\{error}") catch {
        diagnostic_error =>
          println(
            "minimoon: could not write build diagnostic: \{diagnostic_error}",
          )
      }
      raise error
    }
  }
  cleanup_build_transaction(transaction)
  let dist = string(generated, "distDirFinalAbs")
  println(
    "MiniApp " +
    string(generated, "name", fallback="app") +
    " generated from App Contract v" +
    field(generated, "schemaVersion").stringify() +
    " in " +
    mode +
    " mode at " +
    Path::relative(dist, base=root).to_string(),
  )
  dist
}
