///|
async fn http_probe(root : String, offline : Bool) -> Unit {
  let directory = join(root, "_build/http-live")
  if !@fs.exists(directory) {
    @fs.mkdir(directory, recursive=true)
  }
  let script = join(directory, "probe.cjs")
  @fs.write_file(
    script,
    @host_validation.http_probe_source(),
    create_mode=CreateOrTruncate,
  )
  let report = join(
    directory,
    if offline {
      "offline-report.json"
    } else {
      "report.json"
    },
  )
  let fingerprint = @verify.artifact_fingerprint(
    join(root, "examples/miniapp_draft_workbench"),
  )
  let ui_page = join(root, "ui/examples/showcase/dist/pages/forms/forms.js")
  let ui_fingerprint = @verify.artifact_fingerprint(
    join(root, "ui/examples/showcase"),
  )
  run(
    root,
    if offline {
      "offline generated-page HTTP probe"
    } else {
      "public API generated-page HTTP probe"
    },
    "bun",
    [
      script,
      join(
        root, "examples/miniapp_draft_workbench/dist/pages/platform/platform.js",
      ),
      report,
      if offline {
        "--offline"
      } else {
        "--live"
      },
      "",
      fingerprint,
      ui_page,
      ui_fingerprint,
    ],
  )
  if offline {
    run(root, "offline legacy array-valued echo compatibility", "bun", [
      script,
      join(
        root, "examples/miniapp_draft_workbench/dist/pages/platform/platform.js",
      ),
      join(directory, "offline-legacy-report.json"),
      "--offline",
      "--legacy-echo",
      fingerprint,
      ui_page,
      ui_fingerprint,
    ])
    for
      fault in [
        "--fault-echo", "--fault-network", "--fault-header", "--fault-method", "--fault-json",
        "--fault-form", "--fault-body",
      ] {
      let failed_report = join(directory, fault + ".json")
      let (code, _, _) = @process.collect_output(
        "bun",
        [
          script,
          join(
            root, "examples/miniapp_draft_workbench/dist/pages/platform/platform.js",
          ),
          failed_report,
          "--offline",
          fault,
          fingerprint,
          ui_page,
          ui_fingerprint,
        ],
        cwd=root,
      )
      guard code != 0 else { abort("HTTP probe accepted injected failure") }
      let result = read_json(root, "_build/http-live/" + fault + ".json")
      guard json_string(result, "status") == "failed" &&
        json_string(result, "error") != "" else {
        abort("HTTP probe did not record injected failure")
      }
    }
  }
}

///|
async fn http_live_suite(root : String) -> Unit {
  build_examples(root, "release")
  verify_examples(root, false)
  build_verify_ui_gallery(root, "release", false)
  http_probe(root, false)
}
