///|
type Path = @path.Path

///|
struct TemplateSource {
  name : String
  source_dir : String
  asset_dir : String
  files : Array[String]
}

///|
let starter_files : Array[String] = [
  "src/pages/home/page.mbt", "src/pages/home/page_test.mbt", "src/pages/home/moon.pkg",
  "src/pages/details/page.mbt", "src/pages/details/page_test.mbt", "src/pages/details/moon.pkg",
  "styles/tailwind.css",
]

///|
fn join(base : String, child : String) -> String {
  Path::join(base, child).to_string()
}

///|
async fn source_file(template : TemplateSource, file : String) -> String {
  let primary = join(template.source_dir, file)
  if @fs.exists(primary) {
    primary
  } else {
    join(template.asset_dir, file)
  }
}

///|
async fn main {
  let root = @env.current_dir().unwrap()
  let templates = [
    {
      name: "starter",
      source_dir: join(root, "templates/starter"),
      asset_dir: join(root, "templates/starter"),
      files: starter_files,
    },
  ]
  let builder = StringBuilder()
  builder.write_string(
    "///|\nlet embedded_template_files : Map[String, String] = {\n",
  )
  for template in templates {
    for file in template.files {
      let content = @fs.read_file(source_file(template, file)).text()
      builder.write_string(
        "  " +
        (template.name + ":" + file).escape() +
        ": " +
        content.escape() +
        ",\n",
      )
    }
  }
  builder.write_string("}\n")
  let output = join(root, "src/cmd/minimoon/templates.generated.mbt")
  @fs.write_file(
    output,
    builder.to_string(),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  let code = @process.run("moon", ["fmt", output], cwd=root)
  guard code == 0 else { abort("moon fmt failed for " + output) }
  println("Generated " + output)
}
