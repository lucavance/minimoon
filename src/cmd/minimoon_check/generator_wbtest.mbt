///|
test "registry package allowlist accepts only maintained publication roots" {
  for
    path in [
      "moon.mod", "docs/README.md", "docs/guides/miniapp_quickstart.md", "src/README.mbt.md",
      "src/authoring_core.mbt", "src/pkg.generated.mbti", "src/cmd/minimoon/moon.pkg",
      "src/components/styles/minimal_v1.mbt", "src/internal_host_js/host_bridge.mbt",
      "src/testing/testing.mbt",
    ] {
    assert_true(registry_package_path_allowed(path))
  }
}

///|
test "registry package allowlist rejects unreviewed roots and packages" {
  for
    path in [
      "AGENTS.md", "package.json", "new-root.md", "docs/project_status.md", "docs/reference/performance_baseline.md",
      "docs/reference/new_reference.md", "docs/code-analysis/README.md", "examples/app/dist/app.js",
      "scripts/new_adapter.mjs", "src/new_package/moon.pkg", "src/cmd/minimoon_check/main.mbt",
      "src/components/new_test.mbt", "src/runtime_core/new_wbtest.mbt", "src/testing/new_bench.mbt",
      "src/testing/fixture.json", "src/tooling_miniapp/nested/source.mbt",
    ] {
    assert_false(registry_package_path_allowed(path))
  }
}

///|
test "registry package listing parser isolates archive members" {
  let paths = registry_package_paths(
    (
      #|Running moon check ...
      #|Check passed
      #|moon.mod
      #|docs/README.md
      #|src/pkg.generated.mbti
      #|Package to /tmp/lampclaw-minimoon-0.1.0.zip
      #|
    ),
  )
  assert_eq(paths, ["moon.mod", "docs/README.md", "src/pkg.generated.mbti"])
}
