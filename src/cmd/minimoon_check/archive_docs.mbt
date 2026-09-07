///|
async fn archive_documentation_args(
  distribution : String,
  package_root : String,
) -> Array[String] {
  let script = join(distribution, "archive_docs_check.cjs")
  @fs.write_file(
    script,
    @host_validation.docs_check_source(),
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  [
    script,
    package_root,
    @versions.product_version(),
    @versions.app_contract_version().to_string(),
    @versions.runtime_api_version().to_string(),
    @versions.renderer_protocol_version().to_string(),
    "--archive-links",
  ]
}

///|
async fn archive_documentation_gate(
  root : String,
  distribution : String,
  package_root : String,
  label : String,
) -> Unit {
  run(
    root,
    "Unpacked " + label + " registry documentation links",
    "bun",
    archive_documentation_args(distribution, package_root),
    cwd=package_root,
  )
}

///|
async fn archive_documentation_self_test(
  root : String,
  distribution : String,
) -> Unit {
  let probe = join(distribution, "archive-docs-probe")
  @fs.mkdir(probe, permission=0o700)
  write_ui_consumer_file(probe, "guide.md", "# Included guide\n")
  write_ui_consumer_file(
    probe, "README.md", "[guide](guide.md)\n[online](https://github.com/lucavance/minimoon)\n",
  )
  archive_documentation_gate(root, distribution, probe, "positive-control")
  let args = archive_documentation_args(distribution, probe)
  write_ui_consumer_file(
    probe, "README.md", "[excluded UI guide](docs/migration.md)\n",
  )
  require_command_failure(
    "Reject documentation absent from registry archive", "bun", args, probe, "broken local Markdown link",
  )
  write_ui_consumer_file(distribution, "outside.md", "# Outside the archive\n")
  write_ui_consumer_file(probe, "README.md", "[escape](../outside.md)\n")
  require_command_failure(
    "Reject documentation links escaping registry archive", "bun", args, probe, "escapes archive",
  )
}
