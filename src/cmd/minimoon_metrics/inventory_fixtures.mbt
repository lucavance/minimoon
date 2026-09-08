///|
fn embedded_fixture_inventory(entries : Array[EmbeddedInventoryEntry]) -> Unit {
  for
    entry in [
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "page bridge uses the application runtime and gates navigation",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "MiniApp compatibility transforms are complete and idempotent",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "MoonBit core optional chaining is normalized for MiniApp parsers",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "MoonBit UTF-8 encoding is compatible with MiniApp hosts without TextEncoder",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "Moon JavaScript bundle discovery accepts current debug and release layouts",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "Moon JavaScript bundle discovery follows relocated compiler output",
      ),
      (
        "src/tooling_miniapp/generator_wbtest.mbt", "Moon JavaScript bundle discovery rejects zero and multiple outputs",
      ),
      (
        "src/tooling_miniapp/resources_wbtest.mbt", "native resource providers compile from application dependencies and clean temporary packages",
      ),
      (
        "src/cmd/minimoon_check/static_quality_wbtest.mbt", "Moon source boundary rejects the deprecated StringBuilder constructor",
      ),
      (
        "src/internal_host_js/host_bridge_wbtest.mbt", "ABI v11 host captures, merges, and drains asynchronous runtime wakes",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "artifact fingerprints are independent of checkout location",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "artifact fingerprints change with protected content",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "host smoke follows the initial page lifecycle order and verifies disposal",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "local private project config is not fingerprinted",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "release styles templates checklist and recursive files are fingerprinted",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "resource SVG bytes and provider manifest descriptors bind the artifact fingerprint",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "resource verification rejects missing or unsafe declared assets",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "shared host and application runtime are fingerprinted",
      ),
      (
        "src/tooling_minimoon_verify/verify_wbtest.mbt", "v1 evidence never matches a v2 artifact fingerprint",
      ),
    ] {
    entries.push(
      embedded_entry(
        entry.0,
        "test:" + entry.1,
        "excluded",
        Excluded,
        reason="source assertion, synthetic file data, or MoonBit consumer fixture; not executable JavaScript implementation",
      ),
    )
  }
}

///|
fn embedded_own_test_inventory(
  entries : Array[EmbeddedInventoryEntry],
  sources : Array[(String, String)],
) -> Unit {
  for
    entry in [
      (
        "scanner_wbtest.mbt", "embedded scanner distinguishes actual externs strings and comments",
      ),
      (
        "scanner_wbtest.mbt", "embedded scanner preserves source spans and UTF8 payloads",
      ),
      (
        "scanner_wbtest.mbt", "embedded scanner handles escaped strings and interpolation",
      ),
      (
        "embedded_wbtest.mbt", "embedded inventory rejects unregistered raw quoted and extern source",
      ),
      (
        "embedded_wbtest.mbt", "embedded ledger counts unique source lines and excludes mirrored source",
      ),
      (
        "embedded_wbtest.mbt", "embedded inventory rejects stale ambiguous and overlapping selectors",
      ),
      (
        "embedded_wbtest.mbt", "embedded source metrics never expand escaped runtime lines",
      ),
      (
        "embedded_wbtest.mbt", "embedded selectors audit missed new scripts and exact expected matches",
      ),
      (
        "scanner_wbtest.mbt", "embedded scanner rejects ambiguous top level declarations and recognizes commented externs",
      ),
    ] {
    let file = "src/cmd/minimoon_metrics/" + entry.0
    if sources.any(source => source.0 == file) {
      entries.push(
        embedded_entry(
          file,
          "test:" + entry.1,
          "excluded",
          Excluded,
          reason="metrics scanner/inventory fixture",
        ),
      )
    }
  }
}
