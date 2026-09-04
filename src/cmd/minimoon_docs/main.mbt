///|
type Path = @path.Path

///|
let renderer_version = "11.16.0"

///|
let diagram_scale = 3

///|
let documents : ReadOnlyArray[String] = [
  "README.md", "01-SYSTEM-ARCHITECTURE.md", "02-AUTHORING-MODEL.md", "03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md",
  "04-RENDERER-AND-DIFF.md", "05-RUNTIME-AND-HOST-SCHEDULER.md", "06-BUILD-VERIFY-AND-RELEASE.md",
  "07-SYMBOL-INDEX.md", "08-RISKS-TESTING-AND-PERFORMANCE.md",
]

///|
struct Diagram {
  document : String
  index : Int
  heading : String
  stem : String
  mermaid : String
  source : String
  svg : String
  png : String
}

///|
fn join(base : String, child : String) -> String {
  Path::join(base, child).normalize().to_string()
}

///|
async fn write(file : String, content : String) -> Unit {
  let parent = Path::dirname(file).to_string()
  if parent != "" && !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  @fs.write_file(file, content, create_mode=CreateOrTruncate, permission=0o644)
}

///|
fn document_stem(document : String) -> String {
  guard document.has_suffix(".md") else {
    abort("not a Markdown file: " + document)
  }
  document[0:document.length() - 3].to_owned()
}

///|
async fn extract_diagrams(root : String) -> Array[Diagram] {
  let docs = join(root, "docs/code-analysis")
  let output : Array[Diagram] = []
  for document in documents {
    let file = join(docs, document)
    guard @fs.exists(file) else {
      abort("missing code-analysis document: " + document)
    }
    let lines = @fs.read_file(file).text().split("\n")
    let mut heading = "Document overview / 文档总览"
    let mut inside = false
    let mut index = 0
    let source : Array[String] = []
    for line in lines {
      if !inside && line.has_prefix("## ") {
        heading = line[3:].to_owned()
      }
      if !inside && line == "```mermaid" {
        inside = true
        source.clear()
      } else if inside && line == "```" {
        inside = false
        index += 1
        let stem = document_stem(document) + "-" + index.to_string()
        output.push({
          document,
          index,
          heading,
          stem,
          mermaid: source.join("\n") + "\n",
          source: "source/" + stem + ".mmd",
          svg: "svg/" + stem + ".svg",
          png: "png/" + stem + ".png",
        })
      } else if inside {
        source.push(line.to_owned())
      }
    }
    guard !inside else {
      abort(document + " has an unterminated Mermaid block")
    }
  }
  guard output.length() == 21 else {
    abort(
      "expected exactly 21 Mermaid diagrams, found " +
      output.length().to_string(),
    )
  }
  output
}

///|
fn mmdc_invocation(arguments : Array[String]) -> (String, Array[String]) {
  match @env.get_env_var("MMDC_BIN") {
    Some(binary) if binary.trim() != "" => (binary, arguments)
    _ =>
      (
        "bunx",
        [
          "--package",
          "@mermaid-js/mermaid-cli@" + renderer_version,
          "mmdc",
          ..arguments,
        ],
      )
  }
}

///|
async fn run_mmdc(arguments : Array[String], root : String) -> Unit {
  let (command, args) = mmdc_invocation(arguments)
  let (code, stdout, stderr) = @process.collect_output(command, args, cwd=root) catch {
    error => abort("failed to start Mermaid CLI: \{error}")
  }
  guard code == 0 else {
    abort(
      "Mermaid CLI failed:\n" +
      stdout.text().trim().to_owned() +
      "\n" +
      stderr.text().trim().to_owned(),
    )
  }
}

///|
async fn require_renderer_version(root : String) -> Unit {
  let (command, args) = mmdc_invocation(["--version"])
  let (code, stdout, stderr) = @process.collect_output(command, args, cwd=root) catch {
    error => abort("failed to inspect Mermaid CLI: \{error}")
  }
  let output = (stdout.text() + stderr.text()).trim().to_owned()
  guard code == 0 && output.contains(renderer_version) else {
    abort(
      "Mermaid CLI " + renderer_version + " is required; received: " + output,
    )
  }
}

///|
fn sha256(data : Bytes) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(data))
}

///|
async fn file_sha256(file : String) -> String {
  sha256(@fs.read_file(file).binary())
}

///|
fn svg_view_box(svg : String, file : String) -> String {
  let marker = "viewBox=\""
  let start = svg
    .find(marker)
    .unwrap_or_else(fn() { abort("rendered SVG has no viewBox: " + file) }) +
    marker.length()
  let rest = svg[start:].to_owned()
  let stop = rest
    .find("\"")
    .unwrap_or_else(fn() {
      abort("rendered SVG has an invalid viewBox: " + file)
    })
  rest[0:stop].to_owned()
}

///|
fn png_u32(data : Bytes, offset : Int) -> Int {
  (data[offset].to_int() << 24) |
  (data[offset + 1].to_int() << 16) |
  (data[offset + 2].to_int() << 8) |
  data[offset + 3].to_int()
}

///|
fn png_dimensions(data : Bytes, file : String) -> (Int, Int) {
  guard data.length() >= 24 &&
    data[0] == 0x89 &&
    data[1] == 0x50 &&
    data[2] == 0x4e &&
    data[3] == 0x47 else {
    abort("rendered PNG is invalid: " + file)
  }
  (png_u32(data, 16), png_u32(data, 20))
}

///|
fn json_int(value : Int) -> Json {
  Json::number(value.to_double(), repr=value.to_string())
}

///|
async fn render_diagram(
  root : String,
  canonical_assets : String,
  output : String,
  diagram : Diagram,
) -> Json {
  let source_file = join(output, diagram.source)
  let svg_file = join(output, diagram.svg)
  let png_file = join(output, diagram.png)
  write(source_file, diagram.mermaid)
  let common = [
    "--input",
    source_file,
    "--configFile",
    join(canonical_assets, "mermaid-config.json"),
    "--puppeteerConfigFile",
    join(canonical_assets, "puppeteer-config.json"),
    "--cssFile",
    join(canonical_assets, "diagram-theme.css"),
    "--backgroundColor",
    "white",
    "--theme",
    "neutral",
    "--quiet",
  ]
  run_mmdc([..common, "--output", svg_file], root)
  run_mmdc(
    [
      ..common,
      "--output",
      png_file,
      "--scale",
      diagram_scale.to_string(),
      "--width",
      "4096",
    ],
    root,
  )
  let svg = @fs.read_file(svg_file).text()
  let png = @fs.read_file(png_file).binary()
  let (png_width, png_height) = png_dimensions(png, png_file)
  Json::object({
    "document": Json::string(diagram.document),
    "index": json_int(diagram.index),
    "heading": Json::string(diagram.heading),
    "source": Json::string(diagram.source),
    "sourceSha256": Json::string(file_sha256(source_file)),
    "svg": Json::string(diagram.svg),
    "svgSha256": Json::string(file_sha256(svg_file)),
    "viewBox": Json::string(svg_view_box(svg, svg_file)),
    "png": Json::string(diagram.png),
    "pngSha256": Json::string(sha256(png)),
    "pngWidth": json_int(png_width),
    "pngHeight": json_int(png_height),
    "scale": json_int(diagram_scale),
  })
}

///|
fn escape_table(value : String) -> String {
  value.replace_all(old="|", new="\\|").replace_all(old="\n", new=" ")
}

///|
fn asset_readme(diagrams : Array[Diagram]) -> String {
  let output = StringBuilder()
  output.write_string(
    "# 高清图表资源 / High-Resolution Diagram Assets\n\n" +
    "本目录包含 Minimoon 双语代码分析专题的 21 张图表。SVG 可无损缩放，PNG 以 3× 比例导出。\n\n" +
    "> **English:**\n>\n> This directory contains the 21 diagrams used by the bilingual Minimoon code-analysis suite. SVG is losslessly scalable; PNG is exported at 3×.\n\n" +
    "## 重新生成 / Regeneration\n\n" +
    "```bash\n" +
    "bun run docs:diagrams\n" +
    "bun run docs:diagrams:check\n" +
    "```\n\n" +
    "默认使用固定的 Mermaid CLI 11.16.0 和仓库内受控的无沙箱渲染配置；也可以通过 `MMDC_BIN` 和 `PUPPETEER_EXECUTABLE_PATH` 指定本地工具。\n\n" +
    "> **English:**\n>\n> The command defaults to pinned Mermaid CLI 11.16.0 and the repository's controlled no-sandbox rendering configuration. `MMDC_BIN` and `PUPPETEER_EXECUTABLE_PATH` may select local tools.\n\n" +
    "## 图表索引 / Diagram Index\n\n" +
    "清单按正文出现顺序列出每张图的可缩放版本、高清位图和可审查源文件。\n\n" +
    "> **English:**\n>\n> The inventory follows document order and links each diagram's scalable export, high-resolution bitmap, and reviewable source.\n\n" +
    "| 文档 / Document | # | 章节 / Section | SVG | PNG | Mermaid |\n" +
    "| --- | ---: | --- | --- | --- | --- |\n",
  )
  for diagram in diagrams {
    output.write_string(
      "| [" +
      diagram.document +
      "](../../" +
      diagram.document +
      ") | " +
      diagram.index.to_string() +
      " | " +
      escape_table(diagram.heading) +
      " | [SVG](" +
      diagram.svg +
      ") | [PNG 3×](" +
      diagram.png +
      ") | [Source](" +
      diagram.source +
      ") |\n",
    )
  }
  output.to_string()
}

///|
async fn prepare_output(output : String) -> Unit {
  if !@fs.exists(output) {
    @fs.mkdir(output, permission=0o755, recursive=true)
  }
  for child in ["source", "svg", "png"] {
    let directory = join(output, child)
    if @fs.exists(directory) {
      @fs.rmdir(directory, recursive=true)
    }
    @fs.mkdir(directory, permission=0o755, recursive=true)
  }
}

///|
async fn render(root : String, output : String) -> Array[Diagram] {
  let canonical_assets = join(root, "docs/code-analysis/assets/diagrams")
  require_renderer_version(root)
  let diagrams = extract_diagrams(root)
  prepare_output(output)
  let entries : Array[Json] = []
  for index = 0; index < diagrams.length(); index = index + 1 {
    let diagram = diagrams[index]
    println(
      "diagram " +
      (index + 1).to_string() +
      "/" +
      diagrams.length().to_string() +
      ": " +
      diagram.stem,
    )
    entries.push(render_diagram(root, canonical_assets, output, diagram))
  }
  write(
    join(output, "manifest.json"),
    Json::object({
      "schemaVersion": json_int(1),
      "renderer": Json::string("@mermaid-js/mermaid-cli"),
      "rendererVersion": Json::string(renderer_version),
      "scale": json_int(diagram_scale),
      "diagramCount": json_int(diagrams.length()),
      "diagrams": Json::array(entries),
    }).stringify(indent=2) +
    "\n",
  )
  write(join(output, "README.md"), asset_readme(diagrams))
  diagrams
}

///|
async fn compare_file(expected : String, actual : String) -> Unit {
  guard @fs.exists(expected) && @fs.exists(actual) else {
    abort("diagram drift check is missing a file: " + expected)
  }
  guard file_sha256(expected) == file_sha256(actual) else {
    abort("diagram output has drifted: " + expected)
  }
}

///|
async fn check(root : String, canonical : String) -> Unit {
  let temp = @fs.tmpdir(prefix="minimoon-code-analysis-diagrams")
  let generated = join(temp, "diagrams")
  let diagrams = render(root, generated) catch {
    error => {
      @fs.rmdir(temp, recursive=true)
      abort("diagram check failed: \{error}")
    }
  }
  for diagram in diagrams {
    for relative in [diagram.source, diagram.svg, diagram.png] {
      compare_file(join(canonical, relative), join(generated, relative))
    }
  }
  compare_file(
    join(canonical, "manifest.json"),
    join(generated, "manifest.json"),
  )
  compare_file(join(canonical, "README.md"), join(generated, "README.md"))
  @fs.rmdir(temp, recursive=true)
  println("21 code-analysis diagrams are stable")
}

///|
async fn main {
  let args = @env.args()
  let mode = if args.length() > 1 { args[1] } else { "render" }
  guard args.length() <= 2 else { abort("usage: minimoon_docs [render|check]") }
  let root = @env.current_dir().unwrap()
  guard @fs.exists(join(root, "moon.mod")) else {
    abort("run minimoon_docs from the Minimoon repository root")
  }
  let canonical = join(root, "docs/code-analysis/assets/diagrams")
  match mode {
    "render" => {
      ignore(render(root, canonical))
      println("rendered 21 code-analysis diagrams")
    }
    "check" => check(root, canonical)
    _ => abort("usage: minimoon_docs [render|check]")
  }
}
