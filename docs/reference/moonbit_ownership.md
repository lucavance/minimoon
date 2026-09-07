# MoonBit Ownership

All maintainable framework, CLI, generator, verification, and test logic is
MoonBit-owned.

## Maintained Boundary

The only maintained standalone JavaScript file is:

```text
scripts/bridge/weapp_tailwindcss_adapter.mjs
```

It is limited to the JS-only `weapp-tailwindcss/postcss` and class escaping
APIs. The native build package embeds an exact copy and the static suite checks
parity and the 100-line ceiling. Published build and verification host sources
are maintained as MoonBit-owned strings in `internal_host_js`; repository-only
host, documentation, and performance harnesses live in
`internal_host_validation`. They are measured separately and written only as
generated or temporary scripts.

All other tracked JavaScript must be generated output below:

```text
examples/miniapp_conformance_app/dist/
```

The static suite rejects new JavaScript/TypeScript elsewhere. Generated output
is syntax and host-smoke checked rather than counted as maintained source.
The performance suite may create an ignored
`_build/perf/bridge_benchmark.cjs` transient harness from MoonBit source to
measure an exact generated release bridge; it is neither tracked nor maintained
JavaScript.

## Native Tooling

MoonBit owns:

- CLI argument parsing and path discovery
- embedded starter templates and drift checks
- App Contract v8, runtime ABI v10, and renderer protocol v8 compilation
- MoonBit JS process orchestration
- MiniApp project writing
- Tailwind process orchestration and cleanup
- artifact fingerprints and DevTools evidence
- bilingual code-analysis diagram extraction, manifests, and drift checks
- repository validation suites and ownership metrics

No shell, npm bin, VitePlus task runner, JS check harness, or fixture JS remains.
`package.json` only declares external Tailwind dependencies and aliases native
commands.

## Metrics

```bash
minimoon metrics
minimoon metrics --json
```

Metrics report MoonBit source, the standalone adapter, embedded production-host
JavaScript, embedded validation JavaScript, and tracked generated JavaScript
separately. Their sum is also reported as maintained JavaScript.
`.gitattributes` presentation does not affect the calculation. The active gate
protects the exact ownership boundary; it does not require padding MoonBit
lines or optimizing a ratio.

## Generated MoonBit

`templates.generated.mbt` and `.mbti` interfaces remain generated artifacts.
Template generation runs `moon fmt` before drift comparison. `moon info` must
leave committed public interfaces unchanged.
