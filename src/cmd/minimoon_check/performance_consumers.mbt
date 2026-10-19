///|
async fn performance_command(
  root : String,
  command : String,
  args : Array[String],
) -> String {
  let (code, stdout, stderr) = @toolchain.collect_output(
    command,
    args,
    cwd=root,
  )
  guard code == 0 else { raise Failure(command + " failed: " + stderr.text()) }
  stdout.text().trim().to_owned()
}

///|
async fn performance_metadata(root : String) -> Json {
  Json::object({
    "schemaVersion": Json::number(1),
    "commit": Json::string(
      performance_command(root, "git", ["rev-parse", "HEAD"]),
    ),
    "workingTree": Json::string(
      performance_command(root, "git", ["status", "--porcelain"]),
    ),
    "moon": Json::string(
      performance_command(root, "moon", ["version", "--all"]),
    ),
    "vp": Json::string(performance_command(root, "vp", ["--version"])),
    "environment": @json.parse(
      performance_command(root, "vp", ["env", "current", "--json"]),
    ),
    "observationOnly": Json::boolean(true),
  })
}

///|
async fn write_performance_report(
  root : String,
  name : String,
  report : Json,
) -> Unit {
  write_ui_consumer_file(
    root,
    "_build/perf/" + name,
    report.stringify(indent=2) + "\n",
  )
}

///|
async fn consumer_sizes(app : String) -> Map[String, Int32] {
  let sizes = {
    "runtime": 0,
    "javascript": 0,
    "wxml": 0,
    "wxss": 0,
    "assets": 0,
  }
  let dist = join(app, "dist")
  @fs.walk(
    dist,
    (directory, names) => {
      for name in names {
        let file = join(directory, name)
        if @fs.kind(file, follow_symlink=false) == @fs.Regular {
          let size = @fs.read_file(file).binary().length()
          let category = if name.has_suffix(".js") {
            "javascript"
          } else if name.has_suffix(".wxml") {
            "wxml"
          } else if name.has_suffix(".wxss") {
            "wxss"
          } else if name.has_suffix(".json") {
            ""
          } else {
            "assets"
          }
          if category != "" {
            sizes[category] = sizes[category] + size
          }
          if file == join(dist, "minimoon.runtime.js") {
            sizes["runtime"] = size
          }
        }
      }
    },
    max_concurrency=1,
  )
  guard sizes["runtime"] > 0 &&
    sizes["javascript"] >= sizes["runtime"] &&
    sizes["wxml"] > 0 &&
    sizes["wxss"] > 0 else {
    raise Failure("performance consumer has missing or invalid artifacts")
  }
  sizes
}

///|
async fn performance_consumers(root : String, metadata : Json) -> Unit {
  let temp = check_temporary("minimoon-perf-consumers")
  defer cleanup_check_temporary(temp)
  let scenarios : Array[Json] = []
  let report = Json::object({
    "metadata": metadata,
    "status": Json::string("running"),
    "scenarios": Json::array(scenarios),
  })
  write_performance_report(root, "consumer_sizes.json", report)
  let previous : Ref[Map[String, Int32]?] = Ref(None)
  for variant in ["core", "basic-ui", "markdown"] {
    let consumer = join(temp, variant)
    let with_ui = variant != "core"
    let with_markdown = variant == "markdown"
    write_ui_consumer_file(
      consumer,
      "moon.mod",
      "name = \"test/performance_" +
      variant.replace_all(old="-", new="_") +
      "\"\nsource = \"src\"\nimport {\n" +
      "  \"lampclaw/minimoon@" +
      @versions.product_version() +
      "\",\n" +
      (if with_ui {
        "  \"lampclaw/minimoon_ui@" + ui_package_version(root) + "\",\n"
      } else {
        ""
      }) +
      "}\n",
    )
    write_ui_consumer_file(
      consumer,
      "src/pages/home/moon.pkg",
      "import {\n  \"lampclaw/minimoon\",\n" +
      (if with_ui {
        "  \"lampclaw/minimoon_ui\" @ui,\n  \"lampclaw/minimoon_ui/theme\",\n"
      } else {
        ""
      }) +
      (if with_markdown {
        "  \"lampclaw/minimoon_ui/markdown\",\n"
      } else {
        ""
      }) +
      "}\nsupported_targets = \"js+native\"\n",
    )
    let button = if with_ui { "@ui.button" } else { "@minimoon.button" }
    let theme = if with_ui {
      "class=@theme.theme().class_name(), style=@theme.theme().style(), "
    } else {
      ""
    }
    let markdown = if with_markdown {
      ", @markdown.markdown(\"# Baseline\\n\\n**Strong** and [link](https://example.com).\\n\\n- One\\n- Two\\n\\n`code`\", id=\"baseline\", on_link=@minimoon.Emit(_ => @minimoon.none))"
    } else {
      ""
    }
    write_ui_consumer_file(
      consumer,
      "src/pages/home/page.mbt",
      "///|\npub fn program() -> @minimoon.Page {\n  @minimoon.elmish_page(\n" +
      "    id=\"baseline\", route=@minimoon.route(\"pages/home/home\"), title=\"Baseline\",\n" +
      "    model=0, update=(model, message, _) => @minimoon.no_cmd(model + message),\n" +
      "    view=(model, emit) => @minimoon.div(" +
      theme +
      "[" +
      button +
      "(on_tap=emit(1), event_key=\"increment\", \"Count \" + model.to_string())" +
      markdown +
      "]),\n  )\n}\n",
    )
    let config = ui_consumer_config(
      if with_markdown {
        ["button", "markdown"]
      } else {
        ["button"]
      },
    )
    if config is Object(fields) {
      fields["name"] = Json::string("performance_baseline")
      if !with_ui {
        fields.remove("resources")
      }
    }
    write_ui_consumer_file(
      consumer,
      "miniapp.minimoon.json",
      config.stringify(indent=2),
    )
    write_ui_consumer_file(
      consumer, "styles/tailwind.css", "@import \"tailwindcss\" source(none);\n@source \"../src/**/*.mbt\";\n",
    )
    @fs.symlink(
      target=join(root, "node_modules"),
      join(consumer, "node_modules"),
    )
    run(
      root,
      "Bind performance consumer " + variant,
      "moon",
      ["work", "use", root, join(root, "ui"), consumer],
      cwd=temp,
    )
    run(
      root,
      "Format performance consumer " + variant,
      "moon",
      ["fmt"],
      cwd=consumer,
    )
    let config_path = join(consumer, "miniapp.minimoon.json")
    ignore(@build.build(root, config_path, "release"))
    let verified = @verify.verify(consumer, false)
    guard json_string(verified, "status") == "passed" else {
      raise Failure("performance consumer verification failed")
    }
    let fingerprint = @verify.artifact_fingerprint(consumer)
    let first = build_output_snapshot(consumer)
    let sizes = consumer_sizes(consumer)
    ignore(@build.build(root, config_path, "release"))
    ignore(@verify.verify(consumer, false))
    guard @verify.artifact_fingerprint(consumer) == fingerprint &&
      build_output_snapshot(consumer) == first &&
      consumer_sizes(consumer) == sizes else {
      raise Failure("performance consumer is not deterministic: " + variant)
    }
    let deltas : Map[String, Json] = Map([])
    let bytes : Map[String, Json] = Map([])
    for key, value in sizes {
      bytes[key] = Json::number(value.to_double())
      if previous.val is Some(before) {
        deltas[key] = Json::number((value - before[key]).to_double())
      }
    }
    scenarios.push(
      Json::object({
        "scenario": Json::string(variant),
        "fingerprint": Json::string(fingerprint),
        "bytes": Json::object(bytes),
        "deltaFromPrevious": Json::object(deltas),
      }),
    )
    previous.val = Some(sizes)
    write_performance_report(root, "consumer_sizes.json", report)
  }
  if report is Object(fields) {
    fields["status"] = Json::string("passed")
  }
  write_performance_report(root, "consumer_sizes.json", report)
  println(report.stringify(indent=2))
}
