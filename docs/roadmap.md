# Roadmap

## 0.1.0 first non-prerelease release

The complete current implementation is the `0.1.0` public baseline:

- Elm-style state machines, callable `Emit`, transactional `Val` composition,
  and page-owned effects and subscriptions;
- App Contract v7, runtime ABI v10, renderer protocol v7, CommonJS output, and
  Skyline Page Definition API registration;
- normalized tree testing plus optional headless and styled component
  packages;
- one two-page starter and one maintained four-page Conformance fixture;
- deterministic coverage, API, generator, host, performance, archive, and CI
  gates.

The public repository keeps only reproducible candidate state in
[`verify_report.json`](../examples/miniapp_conformance_app/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_conformance_app/generated/release_summary.json),
while fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_conformance_app/generated/devtools.evidence.json)
is local and Git-ignored. Local release verification does not publish its
timestamp, tool version, notes, or outcome in the repository.

## 0.1.1 starter maintenance

The `0.1.1` patch keeps the 0.1 public API and generated host protocols
unchanged while making a fresh `minimoon init` formatter-stable under the
supported MoonBit toolchain. It also expresses JavaScript runtime compatibility
as Node `>=24.11.0` rather than an exact local-version file. Generator and CI
gates enforce both properties.

## 0.1.x maintenance

1. Treat the exact gate-passing 0.1.0 archive as the immutable registry baseline.
2. Drive API additions from sustained application dogfooding rather than
   expanding the public surface speculatively.
3. Extend the Conformance fixture before adding another release fixture.
4. Revalidate generated-byte changes in the real WeChat host.

## Deferred

- ESM output; CommonJS remains the verified host boundary.
- Additional render targets.
- Backend-owned payment completion.
- Broad example expansion without independent verification value.
