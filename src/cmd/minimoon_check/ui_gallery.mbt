///|
let ui_gallery = "ui/examples/showcase"

///|
async fn run_ui_tests(
  root : String,
  target : String,
  coverage_target? : String,
) -> Unit {
  let args = [
    "test", "ui/src", "ui/src/headless", "ui/src/theme", "ui/src/resources", "ui/examples/showcase/src/tests",
    "--target", target, "--deny-warn",
  ]
  if coverage_target is Some(directory) {
    args.push("--enable-coverage")
    args.push("--target-dir")
    args.push(directory)
  }
  run(root, "Independent UI and showcase tests (" + target + ")", "moon", args)
}

///|
let ui_gallery_components : Array[Array[String]] = [
  [
    "Alert", "Aspect Ratio", "Avatar", "Badge", "Breadcrumb", "Bubble", "Button",
    "Button Group", "Card", "Direction", "Empty", "Item", "Kbd", "Label", "Marker",
    "Message", "Separator", "Skeleton", "Spinner", "Typography",
  ],
  [
    "Accordion", "Alert Dialog", "Collapsible", "Dialog", "Drawer", "Dropdown Menu",
    "Hover Card", "Menubar", "Context Menu", "Popover", "Sheet", "Tabs", "Tooltip",
  ],
  [
    "Checkbox", "Field", "Input", "Input Group", "Input OTP", "Native Select", "Progress",
    "Radio Group", "Select", "Slider", "Switch", "Textarea", "Toggle", "Toggle Group",
  ],
  [
    "Calendar", "Chart", "Combobox", "Command", "Data Table", "Date Picker", "Pagination",
    "Table",
  ],
  [
    "Attachment", "Carousel", "Navigation Menu", "Resizable", "Scroll Area", "Sidebar",
  ],
  ["Message Scroller", "Sonner", "Toast"],
]

///|
fn ui_tree_has_section(tree : Json, section : String) -> Bool {
  if json_field(tree, "props") is Object(props) &&
    props.get("section") == Some(Json::string(section)) {
    return true
  }
  if json_field(tree, "children") is Array(children) {
    return children.any(child => ui_tree_has_section(child, section))
  }
  false
}

///|
async fn ui_gallery_manifest_check(root : String) -> Unit {
  let manifest = read_json(root, ui_gallery + "/generated/manifest.json")
  guard json_field(manifest, "pages") is Array(pages) && pages.length() == 6 else {
    abort("UI showcase must contain the six component category pages")
  }
  for index, required in ui_gallery_components {
    let tree = json_field(pages[index], "initialTree")
    for component in required {
      guard ui_tree_has_section(tree, component) else {
        abort("UI showcase is missing component section: " + component)
      }
    }
  }
  guard ui_tree_has_section(json_field(pages[2], "initialTree"), "Form") else {
    abort("UI showcase is missing Form auxiliary capability")
  }
  guard json_field(manifest, "resources") is Array(providers) &&
    providers.length() == 1 else {
    abort("UI showcase must declare exactly one independent resource provider")
  }
  for mode in ["light", "dark"] {
    for icon in ["check", "chevron-down", "close"] {
      require_file(
        root,
        ui_gallery + "/dist/assets/mmui/" + icon + "-" + mode + ".svg",
      )
    }
  }
}

///|
async fn audit_ui_gallery_javascript(root : String, mode : String) -> Unit {
  let files = [
    "app.js", "minimoon.host.js", "minimoon.protocol.js", "minimoon.initial.js",
    "minimoon.runtime.js",
  ]
  for
    category in [
      "foundation", "overlays", "forms", "data", "layout", "feedback",
    ] {
    files.push("pages/" + category + "/" + category + ".js")
  }
  let args = ["-e", javascript_audit_source()]
  for file in files {
    args.push(ui_gallery + "/dist/" + file)
  }
  run(
    root,
    "UI showcase JavaScript compatibility (" + mode + ")",
    "bun",
    args,
    display_args=["-e", "<inline MiniApp syntax and host-global audit>"],
  )
}

///|
async fn build_verify_ui_gallery(
  root : String,
  mode : String,
  release : Bool,
) -> Unit {
  let app_root = join(root, ui_gallery)
  let _ = @build.build(root, join(app_root, "miniapp.minimoon.json"), mode)
  let report = @verify.verify(app_root, release)
  guard json_string(report, "status") == "passed" else {
    abort("UI showcase verification failed")
  }
  ui_gallery_manifest_check(root)
  audit_ui_gallery_javascript(root, mode)
  if !release {
    let summary = read_json(
      root,
      ui_gallery + "/generated/release_summary.json",
    )
    guard !json_bool(report, "release") && candidate_summary_is_public(summary) else {
      abort("UI showcase tracked candidate must not expose real-host evidence")
    }
    if mode == "release" {
      check_candidate_artifacts(root, ui_gallery, "minimoon_ui_showcase")
    }
  }
}

///|
async fn ui_gallery_codegen_gate(root : String) -> Unit {
  build_verify_ui_gallery(root, "release", false)
  let first = @verify.artifact_fingerprint(join(root, ui_gallery))
  build_verify_ui_gallery(root, "release", false)
  guard @verify.artifact_fingerprint(join(root, ui_gallery)) == first else {
    abort("UI showcase resource and host generation is not deterministic")
  }
}
