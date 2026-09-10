///|
async fn docs_suite(root : String) -> Unit {
  let temp = check_temporary("minimoon-docs-check")
  let script = join(temp, "docs_check.cjs")
  @fs.write_file(
    script,
    @host_validation.docs_check_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let bad_links = join(temp, "bad-links")
  @fs.mkdir(bad_links, permission=0o700)
  @fs.write_file(
    join(bad_links, "README.md"),
    "[missing](missing.md)\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  @fs.mkdir(join(bad_links, "ui"), permission=0o700)
  @fs.write_file(
    join(bad_links, "ui/README.mbt.md"),
    "[missing UI guide](docs/missing.md)\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  let args = [
    script,
    root,
    @versions.product_version(),
    @versions.app_contract_version().to_string(),
    @versions.runtime_api_version().to_string(),
    @versions.renderer_protocol_version().to_string(),
  ]
  let init_code = @process.run("git", ["init", "-q"], cwd=bad_links) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to initialize documentation check fixture: \{err}")
    }
  }
  guard init_code == 0 else {
    @fs.rmdir(temp, recursive=true)
    abort("failed to initialize documentation check fixture")
  }
  let (bad_code, bad_stdout, bad_stderr) = @process.collect_output(
    "bun",
    [
      script,
      bad_links,
      @versions.product_version(),
      @versions.app_contract_version().to_string(),
      @versions.runtime_api_version().to_string(),
      @versions.renderer_protocol_version().to_string(),
      "--links-only",
    ],
    cwd=bad_links,
  ) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to start documentation check self-test: \{err}")
    }
  }
  guard bad_code != 0 &&
    (bad_stdout.text() + bad_stderr.text()).contains(
      "README.md: broken local Markdown link",
    ) &&
    (bad_stdout.text() + bad_stderr.text()).contains(
      "ui/README.mbt.md: broken local Markdown link",
    ) else {
    @fs.rmdir(temp, recursive=true)
    abort("documentation check did not reject its broken-link fixture")
  }
  let (self_code, self_stdout, self_stderr) = @process.collect_output(
    "bun",
    [..args, "--self-test"],
    cwd=root,
  ) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to start documentation validator self-test: \{err}")
    }
  }
  guard self_code == 0 &&
    (self_stdout.text() + self_stderr.text()).contains(
      "documentation validator self-test passed",
    ) else {
    @fs.rmdir(temp, recursive=true)
    abort("documentation validator negative cases did not pass")
  }
  for fixture in ["examples/miniapp_draft_workbench", "ui/examples/showcase"] {
    let report = read_json(root, fixture + "/generated/verify_report.json")
    let actual = @verify.artifact_fingerprint(join(root, fixture))
    guard json_string(report, "artifactFingerprint") == actual else {
      @fs.rmdir(temp, recursive=true)
      abort(
        fixture + " documentation report does not match current artifact bytes",
      )
    }
  }
  println(
    "\n==> Documentation links, bilingual sources, diagrams, facts, and fixture reports",
  )
  println("$ bun " + args.join(" "))
  let (code, stdout, stderr) = @process.collect_output("bun", args, cwd=root) catch {
    err => {
      @fs.rmdir(temp, recursive=true)
      abort("failed to start documentation check: \{err}")
    }
  }
  let output = stdout.text() + stderr.text()
  @fs.rmdir(temp, recursive=true)
  guard code == 0 else {
    abort("documentation check failed:\n" + output.trim().to_owned())
  }
  println(output.trim())
}
