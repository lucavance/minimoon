///|
enum EmbeddedExtraction {
  AllLiterals
  RawLiterals
  ExceptLiterals(Array[String])
  SelectedLiterals(Bool, Array[(String, Int)])
  Excluded
} derive(Debug)

///|
struct EmbeddedInventoryEntry {
  file : String
  declaration : String
  category : String
  extraction : EmbeddedExtraction
  reason : String
  ignored_literals : Array[(String, Int)]
} derive(Debug)

///|
fn embedded_entry(
  file : String,
  declaration : String,
  category : String,
  extraction : EmbeddedExtraction,
  reason? : String = "",
  ignored_literals? : Array[(String, Int)] = [],
) -> EmbeddedInventoryEntry {
  { file, declaration, category, extraction, reason, ignored_literals, }
}

///|
fn embedded_inventory(
  sources : Array[(String, String)],
) -> Array[EmbeddedInventoryEntry] {
  let entries : Array[EmbeddedInventoryEntry] = []
  fn add(file, name, category, extraction) {
    entries.push(embedded_entry(file, name, category, extraction))
  }
  fn exclude(file, name, reason) {
    entries.push(embedded_entry(file, name, "excluded", Excluded, reason~))
  }
  for
    entry in [
      ("src/authoring_app_driver.mbt", "capture_app_wake", "production"),
      ("src/authoring_shared_wake.mbt", "capture_shared_wake", "production"),
      (
        "src/renderer_miniapp/page_program_25_runtime_support.mbt", "capture_runtime_wake_v12",
        "production",
      ),
      (
        "examples/miniapp_conformance_app/src/pages/lab/page.mbt", "resume_probe_after",
        "example",
      ),
      (
        "src/renderer_miniapp/page_program_test.mbt", "install_runtime_wake_v12_for_test",
        "test",
      ),
      (
        "src/renderer_miniapp/page_program_test.mbt", "clear_runtime_wake_v12_for_test",
        "test",
      ),
    ] {
    add(entry.0, "extern:" + entry.1, entry.2, RawLiterals)
  }
  for
    entry in [
      ("application_bridge.mbt", "application_host_bridge", "production"),
      ("host_effects.mbt", "host_effect_invoker", "production"),
      ("protocol_bridge.mbt", "shared_protocol_bridge", "production"),
      (
        "validation_application.mbt", "validation_application_boot", "validation",
      ),
    ] {
    add(
      "src/internal_host_js/" + entry.0,
      "fn:" + entry.1,
      entry.2,
      RawLiterals,
    )
  }
  add(
    "src/internal_host_js/host_bridge.mbt",
    "fn:shared_host_bridge",
    "production",
    SelectedLiterals(true, [
      ("if (previousSharedWake", 1),
      (", invokeMinimoonEffect", 1),
    ]),
  )
  for name in ["host_smoke_source", "verify_preload_source"] {
    add(
      "src/internal_host_js/validation_sources.mbt",
      "fn:" + name,
      "validation",
      AllLiterals,
    )
  }
  for
    entry in [
      ("application_smoke.mbt", "application_host_smoke_source"),
      ("docs_validation.mbt", "docs_check_source"),
      ("http_probe.mbt", "http_probe_source"),
      ("validation_sources.mbt", "scheduler_host_smoke_source"),
      ("validation_sources.mbt", "dynamic_app_host_smoke_source"),
      ("validation_sources.mbt", "navigation_host_smoke_source"),
      ("validation_sources.mbt", "bridge_benchmark_source"),
    ] {
    add(
      "src/internal_host_validation/" + entry.0,
      "fn:" + entry.1,
      "validation",
      RawLiterals,
    )
  }
  add(
    "src/cmd/minimoon_check/ci_handoff.mbt",
    "fn:ci_handoff_check_source",
    "validation",
    RawLiterals,
  )
  add(
    "src/cmd/minimoon_check/generator.mbt",
    "fn:javascript_audit_source",
    "validation",
    RawLiterals,
  )
  add(
    "src/cmd/minimoon_check/temporary_wbtest.mbt",
    "test:supervisor cleans success failure crash and launch error without following symlinks",
    "test",
    RawLiterals,
  )
  add(
    "src/tooling_miniapp/artifacts.mbt",
    "fn:initial_tree_bridge",
    "production",
    AllLiterals,
  )
  add(
    "src/tooling_miniapp/artifacts.mbt",
    "fn:page_bridge",
    "production",
    ExceptLiterals(["id", "capabilities"]),
  )
  add(
    "src/tooling_miniapp/compilation.mbt",
    "fn:miniapp_text_encoder_prelude",
    "production",
    AllLiterals,
  )
  entries.push(
    embedded_entry(
      "src/tooling_miniapp/compilation.mbt",
      "fn:miniapp_compatible_javascript",
      "production",
      SelectedLiterals(false, [
        ("(globalThis.crypto&&", 1),
        ("__mmTextEncoder", 2),
      ]),
      ignored_literals=[("globalThis.crypto?.getRandomValues", 2)],
      reason="replacement literals only; old-pattern and postcondition strings are not emitted",
    ),
  )
  add(
    "src/tooling_miniapp/generator.mbt",
    "fn:generate",
    "production",
    SelectedLiterals(false, [
      ("require(\"./minimoon.app.js\")", 1),
      ("App({})", 1),
    ]),
  )
  add(
    "src/tooling_miniapp/generator_wbtest.mbt",
    "test:MiniApp TextEncoder fallback emits standard UTF-8 bytes",
    "test",
    SelectedLiterals(true, [("globalThis.TextEncoder = undefined", 1)]),
  )
  for
    entry in [
      ("src/cmd/minimoon/support.mbt", "fn:usage", "CLI usage text"),
      (
        "src/cmd/minimoon_check/api_wbtest.mbt", "test:optional API policy permits complete additive declaration blocks",
        "MoonBit interface fixture",
      ),
      (
        "src/cmd/minimoon_check/generator_wbtest.mbt", "test:registry package listing parser isolates archive members",
        "archive listing fixture",
      ),
      (
        "src/cmd/minimoon_check/static_quality_wbtest.mbt", "test:JS extern signature boundary rejects mutable and readonly arrays",
        "MoonBit declaration fixtures, not executable externs",
      ),
      (
        "src/cmd/minimoon_check/ui_distribution.mbt", "fn:ui_distribution_package_gate",
        "MoonBit consumer source",
      ),
      (
        "src/tooling_miniapp/component_theme.mbt", "fn:component_theme_css", "CSS",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "test:config diagnostics report duplicate keys and missing packages without touching dist",
        "JSON configuration fixture",
      ),
      (
        "src/tooling_minimoon_build/build.mbt", "fn:adapter_source", "exact mirror of the separately counted standalone Tailwind adapter",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "fn:write_fingerprint_fixture",
        "synthetic fingerprint files, not executable host implementation",
      ),
      ("ui/src/resources/attachment_rules.mbt", "fn:attachment_rules", "WXSS"),
      ("ui/src/resources/extra_rules.mbt", "fn:extra_rules", "WXSS"),
      ("ui/src/resources/resources.mbt", "fn:base_rules", "WXSS"),
      ("ui/src/resources/resources.mbt", "fn:foundation_rules", "WXSS"),
      ("ui/src/resources/resources.mbt", "fn:form_rules", "WXSS"),
    ] {
    exclude(entry.0, entry.1, entry.2)
  }
  embedded_fixture_inventory(entries)
  embedded_forwarding_inventory(entries)
  // These are precise declarations, not a blanket test-directory exclusion.
  // During development newly added metrics files may be absent from the
  // default tracked-only input; --include-untracked includes and audits them.
  for
    entry in [
      ("inventory.mbt", "fn:embedded_inventory"),
      ("inventory_fixtures.mbt", "fn:embedded_fixture_inventory"),
      ("embedded_candidates.mbt", "fn:embedded_script_candidate"),
      ("embedded_candidates.mbt", "fn:embedded_execution_candidate"),
    ] {
    let file = "src/cmd/minimoon_metrics/" + entry.0
    if sources.any(source => source.0 == file) {
      exclude(file, entry.1, "metrics classification metadata")
    }
  }
  embedded_own_test_inventory(entries, sources)
  entries
}
