///|
// These declarations own no executable JS literals: MoonBit source/manifests,
// source assertions, or orchestration forwarding an inventoried source function.
fn embedded_forwarding_inventory(
  entries : Array[EmbeddedInventoryEntry],
) -> Unit {
  for
    entry in [
      (
        "src/cmd/minimoon/add.mbt", "component_source", "MoonBit component template",
      ),
      (
        "src/cmd/minimoon/add.mbt", "miniapp_package_manifest", "MoonBit package manifest",
      ),
      ("src/cmd/minimoon/add.mbt", "page_test_source", "MoonBit test template"),
      (
        "src/cmd/minimoon/add.mbt", "run_add_component", "MoonBit source and package manifest",
      ),
      (
        "src/cmd/minimoon/init.mbt", "render_moon_mod", "MoonBit module manifest",
      ),
      (
        "src/cmd/minimoon_check/api.mbt", "api_interface_snapshot", "MoonBit interface tokens",
      ),
      (
        "src/cmd/minimoon_check/application.mbt", "application_host_smoke", "forwards application_host_smoke_source",
      ),
      (
        "src/cmd/minimoon_check/application.mbt", "application_type_gate", "MoonBit type-check consumer fixture",
      ),
      (
        "src/cmd/minimoon_check/archive_docs.mbt", "archive_documentation_args",
        "forwards docs_check_source",
      ),
      (
        "src/cmd/minimoon_check/ci_handoff.mbt", "ci_handoff_gate", "forwards ci_handoff_check_source",
      ),
      (
        "src/cmd/minimoon_check/docs.mbt", "docs_suite", "forwards docs_check_source; Markdown fixture",
      ),
      (
        "src/cmd/minimoon_check/fixtures.mbt", "dynamic_app_host_smoke", "forwards dynamic_app_host_smoke_source",
      ),
      (
        "src/cmd/minimoon_check/fixtures.mbt", "navigation_host_smoke", "forwards navigation_host_smoke_source",
      ),
      (
        "src/cmd/minimoon_check/fixtures.mbt", "scheduler_host_smoke", "forwards scheduler_host_smoke_source",
      ),
      (
        "src/cmd/minimoon_check/generator.mbt", "generator_suite", "CLI orchestration; filesystem and source assertions",
      ),
      (
        "src/cmd/minimoon_check/http.mbt", "http_probe", "forwards http_probe_source",
      ),
      (
        "src/cmd/minimoon_check/onboarding.mbt", "onboarding_gate", "MoonBit onboarding tests and package manifest, no executable JavaScript",
      ),
      (
        "src/cmd/minimoon_check/performance.mbt", "performance_reports", "forwards bridge_benchmark_source",
      ),
      (
        "src/cmd/minimoon_check/static_quality.mbt", "static_suite", "source assertions and adapter parity check",
      ),
      (
        "src/cmd/minimoon_check/ui_packaging.mbt", "prepare_ui_packaging_stage",
        "isolated Git and MoonBit workspace configuration",
      ),
      (
        "src/cmd/minimoon_check/ui_packaging.mbt", "package_staged_ui", "MoonBit package process, no embedded JavaScript",
      ),
      (
        "src/tooling_miniapp/application_compilation.mbt", "application_runtime_source",
        "MoonBit runtime source template",
      ),
      (
        "src/tooling_miniapp/artifacts.mbt", "write_page", "forwards page_bridge and renderer WXML",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "app_runtime_package_manifest", "MoonBit package manifest",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "app_runtime_package_source", "MoonBit runtime source template",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "compile_app_runtime", "forwards MoonBit compilation output",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "compile_page_contract", "MoonBit contract probe template",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "contract_package_manifest", "MoonBit package manifest",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "emit_host_bridge", "minifies supplied source; no own JS payload",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "runtime_package_source", "MoonBit runtime source template",
      ),
      (
        "src/tooling_miniapp/runtime_creation.mbt", "runtime_creation_helpers", "MoonBit runtime input and registration template",
      ),
      (
        "src/tooling_miniapp/compilation.mbt", "runtime_registry_source", "MoonBit runtime registry template",
      ),
      (
        "src/tooling_miniapp/resources.mbt", "compile_resource_bundle", "MoonBit resource probe template",
      ),
      (
        "src/tooling_minimoon_build/build.mbt", "generate_tailwind", "forwards standalone adapter mirror and CSS",
      ),
      (
        "src/tooling_minimoon_verify/verify_10_generated.mbt", "generated_checks",
        "forwards verify_preload_source and host_smoke_source",
      ),
    ] {
    entries.push(
      embedded_entry(
        entry.0,
        "fn:" + entry.1,
        "excluded",
        Excluded,
        reason=entry.2,
      ),
    )
  }
}
