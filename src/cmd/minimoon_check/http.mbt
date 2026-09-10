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
    ],
  )
  if offline {
    for fault in ["--fault-echo", "--fault-network"] {
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
  http_probe(root, false)
}
